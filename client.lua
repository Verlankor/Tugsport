local QBCore = exports['qb-core']:GetCoreObject()
local onJob = false

local leftSide = {x = -4.0, y = -9.25, z = 1.0}
local rightSide = {x = 4.0, y = -9.25, z = 1.0}
local trouble = 'none'
local gameActive = false
local deliverPeds = {}
local jobBlip

CreateThread(function()
    local startBlip = AddBlipForCoord(Config.StartingPoint)
    SetBlipScale(startBlip, 0.8)
    SetBlipAsShortRange(startBlip, true)
    SetBlipSprite(startBlip, 356)
    SetBlipColour(startBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Tugsportation')
    EndTextCommandSetBlipName(startBlip)


    RequestModel('s_m_m_dockwork_01')
    while not HasModelLoaded('s_m_m_dockwork_01') do
        Wait(0)
    end
    local dockPed = CreatePed(0, 's_m_m_dockwork_01', Config.StartingPoint, false, false)
    TaskStartScenarioInPlace(dockPed, 'WORLD_HUMAN_GUARD_STAND', 0, true)
    FreezeEntityPosition(dockPed, true)
    SetEntityInvincible(dockPed, true)
    SetBlockingOfNonTemporaryEvents(dockPed, true)


    for k,v in pairs(Config.EndPoints) do
        local ped = CreatePed(0, 's_m_m_dockwork_01', v, false, false)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GUARD_STAND', 0, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    label = 'Get Paid',
                    icon = 'fa-solid fa-anchor',
                    action = function()
                        QBCore.Functions.TriggerCallback('Tugsport:Pay', function(success)
                            if success then onJob = false end
                            if jobBlip then jobBlip = RemoveBlip(jobBlip) end
                        end)
                    end,
                    canInteract = function()
                        local pedID = k
                        return onJob
                    end
                }
            },
            distance = 2.0
        })
        table.insert(deliverPeds, v)
    end

    exports['qb-target']:AddTargetEntity(dockPed, {
        options = {
            {
                label = 'Start Transport Tugging',
                icon = 'fa-solid fa-anchor',
                action = function()
                    TugStart()
                end,
                canInteract = function()
                    return not onJob
                end
            },
            {
                label = 'Quit Tug',
                icon = 'fa-solid fa-anchor',
                action = function()
                    QBCore.Functions.TriggerCallback('Tugsport:Quit', function(success)
                        if success then onJob = false end
                        if jobBlip then jobBlip = RemoveBlip(jobBlip) end
                    end)
                end,
                canInteract = function()
                    return onJob
                end
            },
        },
        distance = 2.0
    })
end)

RegisterNUICallback('GameFinish', function(data, cb)
    if not gameActive then 
        cb(true)
        return 
    end
    gameActive = false
    SetNuiFocus(false, false)
    StopAnimTask(PlayerPedId(), 'random@mugging4', 'struggle_loop_b_thief', 1.0)
    TriggerServerEvent('Tugsport:FinishEvent', data.group, data.win)
    cb(true)
end)

RegisterNetEvent('Tugsport:Event', function(netID, direction)
    local ourTug = NetworkGetEntityFromNetworkId(netID)
    local actionable = direction == 'left' and leftSide or rightSide
    local directionToTurn = direction == 'left' and -10 or 10
    QBCore.Functions.Notify(('Cargo has fallen off the boat on the %s side, retrieve it!'):format(direction))
    gameActive = true
    exports['qb-target']:AddTargetEntity(ourTug, {
        options = {
            {
                label = 'PULL IT OUT',
                icon = 'fa-solid fa-anchor',
                action = function()
                    RequestAnimDict('random@mugging4')
                    while not HasAnimDictLoaded('random@mugging4') do
                        Wait(0)
                    end
                    TaskTurnPedToFaceCoord(PlayerPedId(), GetOffsetFromEntityInWorldCoords(ourTug, actionable.x + directionToTurn, actionable.y, actionable.z), 1000)
                    Wait(1000)
                    TaskPlayAnim(PlayerPedId(), 'random@mugging4', 'struggle_loop_b_thief' ,1.0, 1.0, -1, 31, 0, false, false, false)
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        type = 'StartGame',
                        groupID = Entity(ourTug).state.groupID
                    })
                end,
                canInteract = function()
                    local actionable = direction == 'left' and leftSide or rightSide
                    local pos = GetEntityCoords(PlayerPedId())
                    local tugPos =GetOffsetFromEntityInWorldCoords(ourTug, actionable.x, actionable.y, actionable.z)
                    return #(pos - tugPos) <= 3.0 and direction ~= 'none'
                end
            },
        },
        distance = 2.0
    })

    CreateThread(function()
        while gameActive do
            Wait(0)
            DrawMarker(20, GetOffsetFromEntityInWorldCoords(ourTug, actionable.x, actionable.y, actionable.z + 1.0), 0.0, 0.0 ,0.0 ,0.0 ,180.0 ,0.0, 0.5, 0.5, 0.5, 255, 255, 255, 255, true, 2, true, nil, nil, true)
        end
    end)
end)

RegisterNetEvent('Tugsport:EndEvent', function(netID)
    local ourTug = NetworkGetEntityFromNetworkId(netID)
    exports['qb-target']:RemoveTargetEntity(ourTug)
    gameActive = false
end)

RegisterNetEvent('Tugsport:Despawn', function()
    onJob = false
    if jobBlip then jobBlip = RemoveBlip(jobBlip) end
end)

function TugStart()
    QBCore.Functions.TriggerCallback('Tugsport:Begin', function(netId, delvieryPoint)
        if netId == false then return end
        onJob = true
        while not NetworkDoesEntityExistWithNetworkId(netId) do
            Wait(0)
        end
        local ourTug = NetworkGetEntityFromNetworkId(netId)


        jobBlip = AddBlipForCoord(Config.EndPoints[delvieryPoint].xyz)
        SetBlipSprite(jobBlip, 356)
        SetBlipColour(jobBlip, 2)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Tug Delivery')
        EndTextCommandSetBlipName(jobBlip)

        local actionable = leftSide
        local directionToTurn = -10
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(ourTug))

        CreateThread(function()
            local waitTicks = math.random(90, 180)
            while onJob do
                Wait(1000)
                waitTicks -= 1
                if waitTicks <= 0 and GetEntitySpeed(ourTug) >= 2.0 then
                    TriggerServerEvent('Tugsport:Event')
                    waitTicks = math.random(180, 300)
                end
            end
        end)
    end)
end

