local MIN_POINT_DISTANCE = 1.0
local IDLE_WAIT_MS = 500

local MARKER_NATIVE = 0x2A32FAA57B937173
local MARKER_TYPE = 0x94FDAE17

local Control = {
    ENTER = 0xC7B5340A,
    BACKSPACE = 0x156F7119,
    MOUSE_LEFT = 0x07CE1E61,
    MOVE_LR = 0xA987235F,
    MOVE_FORWARD = 0x8FD015D8,
    MOVE_BACK = 0xD27782E3,
    MOVE_UP = 0x6319DB71,
    MOVE_DOWN = 0x05CA7C52,
    SPRINT = 0x8FFC75D6,
}

local state = {
    coords = {},
    markers = {},
    isCollecting = false,
    isResultOpen = false,
    mode = nil,
    lastMode = 'walk',
    isFlyMode = false,
}

local closeCoordsCard
local startCollection
local tryAddPoint
local finishCollection

local function setFlyMode(enabled)
    local ped = PlayerPedId()
    state.isFlyMode = enabled
    FreezeEntityPosition(ped, enabled)
    SetEntityCollision(ped, not enabled, not enabled)
end

local function isPositionTooClose(newPos, points)
    local newVec = vector3(newPos.x, newPos.y, newPos.z)
    for i = 1, #points do
        local point = points[i]
        if #(newVec - vector3(point.x, point.y, point.z)) < MIN_POINT_DISTANCE then
            return true
        end
    end
    return false
end

local function normalizeCopyFormat(format)
    if type(format) ~= 'string' then
        return 'v4'
    end
    local f = string.lower(format)
    if f == 'v2' or f == 'v3' or f == 'v4' then
        return f
    end
    return 'v4'
end

local function formatCoordNumber(value, decimals)
    if decimals == nil then
        return tostring(value)
    end
    return string.format('%.' .. decimals .. 'f', value)
end

local function formatCoordPoint(point, copyFormat, decimals)
    local x = formatCoordNumber(point.x, decimals)
    local y = formatCoordNumber(point.y, decimals)
    local z = formatCoordNumber(point.z, decimals)
    local h = formatCoordNumber(point.h, decimals)

    if copyFormat == 'v2' then
        return string.format('vector2(%s, %s)', x, y)
    end
    if copyFormat == 'v3' then
        return string.format('vector3(%s, %s, %s)', x, y, z)
    end
    return string.format('vector4(%s, %s, %s, %s)', x, y, z, h)
end

local function buildCoordsClipboardString(coordsList, copyFormat, decimals)
    local lines = {}
    for i = 1, #coordsList do
        lines[i] = '    ' .. formatCoordPoint(coordsList[i], copyFormat, decimals) .. ','
    end
    return '{\n' .. table.concat(lines, '\n') .. '\n}'
end

closeCoordsCard = function()
    if not state.isResultOpen then
        return
    end
    state.isResultOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hideResult' })
end

local function openResultCard(text)
    state.isResultOpen = true
    SendNUIMessage({ type = 'showResult', text = text })
    SetNuiFocus(true, true)
end

startCollection = function(mode)
    closeCoordsCard()
    state.mode = mode
    state.lastMode = mode
    state.isCollecting = true
    state.coords = {}
    state.markers = {}
    setFlyMode(false)
end

finishCollection = function()
    state.isCollecting = false
    setFlyMode(false)

    if #state.coords == 0 then
        state.markers = {}
        state.mode = nil
        return
    end

    local text = buildCoordsClipboardString(
        state.coords,
        normalizeCopyFormat(Config.CopyFormat),
        Config.CopyDecimals
    )

    state.coords = {}
    state.markers = {}
    state.mode = nil
    openResultCard(text)
end

local function collectAgain()
    local mode = state.lastMode or 'walk'
    closeCoordsCard()
    startCollection(mode)
end

local function drawText(text, x, y, scale)
    SetTextScale(scale, scale)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 200)
    SetTextFontForCurrentCommand(25)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), x, y)
end

local function drawGroundMarker(x, y, z, scaleX, scaleY, scaleZ, r, g, b)
    Citizen.InvokeNative(
        MARKER_NATIVE,
        MARKER_TYPE,
        x, y, z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        scaleX, scaleY, scaleZ,
        r, g, b, 100,
        false, true, 2, false, nil, nil, false
    )
end

local function drawMarkers()
    local markers = state.markers
    for i = 1, #markers do
        local marker = markers[i]
        drawGroundMarker(marker.x, marker.y, marker.z - 1.0, 0.5, 0.5, 5.0, 255, 255, 0)

        local rad = math.rad(marker.h)
        drawGroundMarker(
            marker.x + (math.sin(rad) * -0.3),
            marker.y + (math.cos(rad) * 0.3),
            marker.z - 1.0,
            0.2, 0.2, 1.0,
            255, 0, 0
        )
    end
end

local function drawCollectionPrompt()
    if state.mode == 'aim' then
        drawText('Aim with camera, ~o~[MOUSE LEFT]~q~ add, ~o~[BACKSPACE]~q~ finish, ~o~[/mcoordsfly]~q~ toggle fly', 0.5, 0.95, 0.35)
        drawText('+', 0.5, 0.5, 0.3)
        return
    end
    drawText('Press ~o~[ENTER]~q~ to add point, ~o~[BACKSPACE]~q~ to finish', 0.5, 0.95, 0.35)
end

local function rotationToDirection(rot)
    local radX = math.rad(rot.x)
    local radZ = math.rad(rot.z)
    local num = math.abs(math.cos(radX))
    return vector3(-math.sin(radZ) * num, math.cos(radZ) * num, math.sin(radX))
end

local function getCameraHitCoord()
    if not StartShapeTestRay or not GetShapeTestResult then
        return nil
    end

    local ped = PlayerPedId()
    local camCoord = GetGameplayCamCoord()
    local camDir = rotationToDirection(GetGameplayCamRot(2))
    local destination = camCoord + (camDir * 1000.0)

    local rayHandle = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        destination.x, destination.y, destination.z,
        511, ped, 7
    )

    local result, hit, endCoords = GetShapeTestResult(rayHandle)
    for _ = 1, 10 do
        if result ~= 1 then
            break
        end
        Wait(0)
        result, hit, endCoords = GetShapeTestResult(rayHandle)
    end

    if result == 2 and hit == 1 then
        return vector3(endCoords.x, endCoords.y, endCoords.z)
    end
    return nil
end

local function movePlayerFlyMode(speed)
    local ped = PlayerPedId()
    local camDir = rotationToDirection(GetGameplayCamRot(2))
    local camRight = vector3(-camDir.y, camDir.x, 0.0)
    local pos = GetEntityCoords(ped)

    local moveForward = GetControlNormal(0, Control.MOVE_FORWARD) - GetControlNormal(0, Control.MOVE_BACK)
    local moveRight = GetControlNormal(0, Control.MOVE_LR)
    local moveUp = GetControlNormal(0, Control.MOVE_UP) - GetControlNormal(0, Control.MOVE_DOWN)

    local nextPos = vector3(
        pos.x + (camDir.x * moveForward * speed) + (camRight.x * moveRight * speed),
        pos.y + (camDir.y * moveForward * speed) + (camRight.y * moveRight * speed),
        pos.z + (camDir.z * moveForward * speed) + (moveUp * speed)
    )

    SetEntityCoordsNoOffset(ped, nextPos.x, nextPos.y, nextPos.z, false, false, false)
end

tryAddPoint = function(newCoord)
    if isPositionTooClose(newCoord, state.markers) then
        return
    end
    state.coords[#state.coords + 1] = newCoord
    state.markers[#state.markers + 1] = newCoord
end

local function addPointFromPlayer()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    tryAddPoint({ x = pos.x, y = pos.y, z = pos.z, h = GetEntityHeading(ped) })
end

local function addPointFromAim()
    local hitCoord = getCameraHitCoord()
    if not hitCoord then
        return
    end
    tryAddPoint({
        x = hitCoord.x,
        y = hitCoord.y,
        z = hitCoord.z,
        h = GetGameplayCamRot(2).z,
    })
end

local function handleCollectionInput()
    if state.mode == 'aim' then
        if state.isFlyMode then
            local speed = IsControlPressed(0, Control.SPRINT) and 1.2 or 0.45
            movePlayerFlyMode(speed)
        end

        DisableControlAction(0, Control.MOUSE_LEFT, true)
        if IsDisabledControlJustPressed(0, Control.MOUSE_LEFT) then
            addPointFromAim()
        end
        return
    end

    if IsControlJustPressed(0, Control.ENTER) then
        addPointFromPlayer()
    end
end

RegisterCommand('mcoords', function()
    startCollection('walk')
end, false)

RegisterCommand('mcoordsaim', function()
    startCollection('aim')
end, false)

RegisterCommand('mcoordsfly', function()
    if state.isCollecting and state.mode == 'aim' then
        setFlyMode(not state.isFlyMode)
    end
end, false)

RegisterNUICallback('closeCoordsCard', function(_, cb)
    closeCoordsCard()
    cb('ok')
end)

RegisterNUICallback('collectAgain', function(_, cb)
    collectAgain()
    cb('ok')
end)

CreateThread(function()
    while true do
        if state.isCollecting then
            drawCollectionPrompt()
            drawMarkers()
            handleCollectionInput()

            if IsControlJustPressed(0, Control.BACKSPACE) then
                finishCollection()
            end

            Wait(0)
        else
            Wait(IDLE_WAIT_MS)
        end
    end
end)
