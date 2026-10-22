local MIN_POINT_DISTANCE = 1.0
local IDLE_WAIT_MS = 500

local MARKER_NATIVE = 0x2A32FAA57B937173
local MARKER_TYPE = 0x94FDAE17

local Control = {
    ENTER = 0xC7B5340A,
    BACKSPACE = 0x156F7119,
}

local state = {
    coords = {},
    markers = {},
    isCollecting = false,
    isResultOpen = false,
}

local closeCoordsCard
local startCollection
local tryAddPoint
local finishCollection

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

startCollection = function()
    closeCoordsCard()
    state.isCollecting = true
    state.coords = {}
    state.markers = {}
end

finishCollection = function()
    state.isCollecting = false

    if #state.coords == 0 then
        state.markers = {}
        return
    end

    local text = buildCoordsClipboardString(
        state.coords,
        normalizeCopyFormat(Config.CopyFormat),
        Config.CopyDecimals
    )

    state.coords = {}
    state.markers = {}
    openResultCard(text)
end

local function collectAgain()
    closeCoordsCard()
    startCollection()
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

RegisterCommand('mcoords', function()
    startCollection()
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
            drawText('Press ~o~[ENTER]~q~ to add point, ~o~[BACKSPACE]~q~ to finish', 0.5, 0.95, 0.35)
            drawMarkers()

            if IsControlJustPressed(0, Control.ENTER) then
                addPointFromPlayer()
            end

            if IsControlJustPressed(0, Control.BACKSPACE) then
                finishCollection()
            end

            Wait(0)
        else
            Wait(IDLE_WAIT_MS)
        end
    end
end)
