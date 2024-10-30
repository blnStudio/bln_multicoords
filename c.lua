local coords = {}
local isCollecting = false
local markers = {}
local isCopied = false
local isCopySoundPlayed = false

local function isPositionTooClose(newPos, existingPoints, minDistance)
    for _, point in ipairs(existingPoints) do
        local distance = #(vector3(newPos.x, newPos.y, newPos.z) - vector3(point.x, point.y, point.z))
        if distance < minDistance then
            return true
        end
    end
    return false
end

RegisterCommand('mcoords', function()
    isCollecting = true
    coords = {}
    markers = {}
    TriggerEvent('coords:showPrompt')
end, false)

RegisterNetEvent('coords:showPrompt')
AddEventHandler('coords:showPrompt', function()
    Citizen.CreateThread(function()
        while isCollecting do
            if isCopied then
                DrawText("~t6~Coords copied to your clipboard", 0.5, 0.95, 0.35, true)
                if not isCopySoundPlayed then
                    PlaySoundFrontend("INFO_HIDE", "Ledger_Sounds", true, 0)
                    isCopySoundPlayed = true
                end
            else
                DrawText("Press ~o~[ENTER]~q~ to add point, ~o~[BACKSPACE]~q~ to finish", 0.5, 0.95, 0.35, true)
                for _, marker in ipairs(markers) do
                    Citizen.InvokeNative(0x2A32FAA57B937173,
                        0x94FDAE17,
                        marker.x, marker.y, marker.z - 1,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.5, 0.5, 5.0,
                        255, 255, 0, 100,
                        false, true, 2, false, nil, nil, false
                    )
    
                    local rad = math.rad(marker.h)
                    local headingX = marker.x + (math.sin(rad) * -0.3) 
                    local headingY = marker.y + (math.cos(rad) * 0.3) 
                    Citizen.InvokeNative(0x2A32FAA57B937173,
                        0x94FDAE17,
                        headingX, headingY, marker.z - 1,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.2, 0.2, 1.0,
                        255, 0, 0, 100,
                        false, true, 2, false, nil, nil, false
                    )
                end
            end
            Citizen.Wait(0)
        end
    end)
end)

function DrawText(text, x, y, scale, center)
    SetTextScale(scale, scale)
    SetTextCentre(center)
    local str = CreateVarString(10, "LITERAL_STRING", text)
    DisplayText(str, x, y)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isCollecting then
            if IsControlJustPressed(0, 0xC7B5340A) then -- ENTER
                local playerPed = PlayerPedId()
                local pos = GetEntityCoords(playerPed)
                local heading = GetEntityHeading(playerPed)
                local newCoord = { x = pos.x, y = pos.y, z = pos.z, h = heading }
                if not isPositionTooClose(newCoord, markers, 1.0) then
                    table.insert(coords, newCoord)
                    table.insert(markers, newCoord)
                end
            end

            if IsControlJustPressed(0, 0x156F7119) then -- BACKSPACE
                if #coords > 0 then
                    SendNUIMessage({
                        type = 'copyCoords',
                        coords = coords
                    })
                end
                isCopied = true
                Wait(4000)
                isCopySoundPlayed = false
                isCopied = false
                isCollecting = false
                markers = {}
                coords = {}
            end
        end
    end
end)