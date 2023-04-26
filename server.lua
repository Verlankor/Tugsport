local QBCore = exports['qb-core']:GetCoreObject()
local entityList = {}
local tugs = {}
local tugOwners = {}
local timeouts = {}

AddStateBagChangeHandler(false, false, function(bagName, key, value, source, replicated)
    local entityNet = tonumber(bagName:gsub('entity:', ''), 10)
    local entity = NetworkGetEntityFromNetworkId(entityNet)
    if entityList[entity] then
        local ent = Entity(entity)
        local curState = ent.state[key]

        if source ~= 0 then
            SetTimeout(0, function()
                print('[Tugsport] Removed Altered State Bag by Client: '..bagName, key, value)
                Entity(entity).state[key] = curState
            end)
        end
    end
end)

QBCore.Functions.CreateCallback('Tugsport:Begin', function(source, cb)
    if timeouts[source] then
        if timeouts[source] - os.time() <= 300 then
            TriggerClientEvent('QBCore:Notify', source, ('Come back in %s seconds'):format(math.abs(os.time() - timeouts[source])), 'error')
            cb(false)
            return
        end
    end
    if tugs[source] then return end
    math.randomseed(os.time())
    tugs[source] = {
        Helpers = {},
        Containers = 3,
        Delivery = math.random(#Config.EndPoints)
    }
    tugs[source].Vehicle = CreateVehicleServerSetter(`tug`, 'boat', vector4(-104.34, -2769.31, 0.45, 176.52))
    tugOwners[tugs[source].Vehicle] = source
    while not DoesEntityExist(tugs[source].Vehicle) do
        Wait(0)
    end
    Wait(500)
    entityList[tugs[source].Vehicle] = true
    Entity(tugs[source].Vehicle).state.groupID = source
    cb(NetworkGetNetworkIdFromEntity(tugs[source].Vehicle), tugs[source].Delivery)
end)

RegisterNetEvent('Tugsport:Event', function()
    local source = source
    if tugs[source] then
        local boat = GetEntityCoords(tugs[source].Vehicle)
        local direction = math.random(2) == 1 and 'left' or 'right'
        tugs[source].Event = true
        BoatEvent(boat, 'Tugsport:Event', NetworkGetNetworkIdFromEntity(tugs[source].Vehicle), direction)
        Citizen.SetTimeout(60000, function()
            if tugs[source] and tugs[source].Event then
                tugs[source].Event = nil
                tugs[source].Containers -= 1
                BoatEvent(boat, 'QBCore:Notify', 'The Cargo was lost! '..tugs[source].Containers..' remain')
                BoatEvent(boat, 'Tugsport:EndEvent', NetworkGetNetworkIdFromEntity(tugs[source].Vehicle))
            end
        end)
    end
end)

RegisterNetEvent('Tugsport:FinishEvent', function(groupID, win)
    local source = source
    local boat = GetEntityCoords(tugs[groupID].Vehicle)
    if #(GetEntityCoords(GetPlayerPed(source)) - boat) <= 40.0 and tugs[groupID].Event then
        tugs[groupID].Event = nil
        if win then
            BoatEvent(boat, 'QBCore:Notify', 'The Cargo was saved!')
            local found = false
            for k,v in pairs(tugs[groupID].Helpers) do
                if v == source then found = true end
                return
            end

            if not found then
                table.insert(tugs[groupID].Helpers, source)
            end
        else
            tugs[groupID].Containers -= 1
            BoatEvent(boat, 'QBCore:Notify', 'The Cargo was lost! '..tugs[groupID].Containers..' remain')
        end
        BoatEvent(boat, 'Tugsport:EndEvent', NetworkGetNetworkIdFromEntity(tugs[source].Vehicle))
    end
end)


QBCore.Functions.CreateCallback('Tugsport:Pay', function(source, cb)
    if not tugs[source] then
        cb(false)
        return
    end

    local boat = GetEntityCoords(tugs[source].Vehicle)
    if #(boat - Config.EndPoints[tugs[source].Delivery].xyz) >= 100.0 then  
        cb(false)
    end
    if #(GetEntityCoords(GetPlayerPed(source)) - boat) <= 100.0 then
        QBCore.Functions.GetPlayer(source).Functions.AddMoney('cash', Config.Pay)
        for k,v in pairs(tugs[source].Helpers) do
            QBCore.Functions.GetPlayer(v).Functions.AddMoney('cash', Config.Pay)
        end
        DeleteEntity(tugs[source].Vehicle)
        entityList[tugs[source].Vehicle] = nil
        tugs[source] = nil
        cb(true)
    end
end)

QBCore.Functions.CreateCallback('Tugsport:Quit', function(source, cb)
    timeouts[source] = os.time() + 300
    DeleteEntity(tugs[source].Vehicle)
    entityList[tugs[source].Vehicle] = nil
    tugs[source] = nil
    cb(true)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        for k,v in pairs(tugs) do
            DeleteEntity(v.Vehicle)
        end
    end
end)

function BoatEvent(boatCoords, event, ...)
    for k,v in pairs(GetPlayers()) do
        if #(GetEntityCoords(GetPlayerPed(v)) - boatCoords) <= 40.0 then
            TriggerClientEvent(event, v, ...)
        end
    end
end

AddEventHandler('entityRemoved', function(entity)
    if tugOwners[entity] then
        TriggerClientEvent('Tugsport:Despawn', tugOwners[entity])
        tugs[tugOwners[entity]] = nil
        tugOwners[entity] = nil
    end
end)