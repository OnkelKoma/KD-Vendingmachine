--[[
    Spawns the extra machines from Config.Placements. They are local objects, so
    every client spawns its own copy and target / native interaction picks them up by model.
]]

local spawned = {}

local function spawnPlacement(placement)
    local machine = Config.Machines[placement.machine]
    if not machine then
        Utils.Warn('placement uses unknown machine "%s"', tostring(placement.machine))
        return
    end

    local model = joaat(placement.model or machine.models[1])
    if not IsModelInCdimage(model) then
        Utils.Warn('placement model for "%s" does not exist', placement.machine)
        return
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end

    local c = placement.coords
    local obj = CreateObjectNoOffset(model, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(obj, c.w or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(model)
    spawned[#spawned + 1] = obj
end

CreateThread(function()
    for i = 1, #Config.Placements do
        spawnPlacement(Config.Placements[i])
    end
    if #spawned > 0 then Utils.Debug(('spawned %d extra machine(s)'):format(#spawned)) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #spawned do
        if DoesEntityExist(spawned[i]) then DeleteEntity(spawned[i]) end
    end
end)
