--[[
    Interaction layer. Registers every machine model with ox_target / qb-target,
    or falls back to ox_lib text UI / native GTA help text with a proximity scan.
]]

Interaction = {}

local mode
local registered = {}

local function resolveMode()
    if Config.Interaction ~= 'auto' then return Config.Interaction end
    if Utils.IsStarted('ox_target') then return 'ox_target' end
    if Utils.IsStarted('qb-target') then return 'qb-target' end
    if Utils.IsStarted('ox_lib') then return 'textui' end
    return 'native'
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Target systems
-- ─────────────────────────────────────────────────────────────────────────────

local function registerOxTarget()
    for id, machine in pairs(Config.Machines) do
        local name = ('kd_vending_%s'):format(id)
        exports.ox_target:addModel(machine.models, {
            {
                name = name,
                icon = machine.icon or 'fa-solid fa-cash-register',
                label = _L('target.use', machine.label),
                distance = Config.InteractDistance,
                canInteract = function() return not VendingState.open and not VendingState.busy end,
                onSelect = function(data) OpenMachine(data.entity) end,
            },
        })
        registered[#registered + 1] = { models = machine.models, name = name }
    end
end

local function registerQbTarget()
    for _, machine in pairs(Config.Machines) do
        local label = _L('target.use', machine.label)
        exports['qb-target']:AddTargetModel(machine.models, {
            options = {
                {
                    icon = machine.icon or 'fa-solid fa-cash-register',
                    label = label,
                    canInteract = function() return not VendingState.open and not VendingState.busy end,
                    action = function(entity) OpenMachine(entity) end,
                },
            },
            distance = Config.InteractDistance,
        })
        registered[#registered + 1] = { models = machine.models, name = label }
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Proximity fallback (text UI / native help text)
-- ─────────────────────────────────────────────────────────────────────────────

local allHashes = {}
for hash in pairs(Utils.ModelLookup) do allHashes[#allHashes + 1] = hash end

local function findClosestMachine(coords)
    local closest, closestDist
    for i = 1, #allHashes do
        local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.InteractDistance + 0.6, allHashes[i], false, false, false)
        if obj ~= 0 then
            local dist = #(coords - GetEntityCoords(obj))
            if not closestDist or dist < closestDist then
                closest, closestDist = obj, dist
            end
        end
    end
    return closest, closestDist
end

local function startProximity()
    local nearby, shownFor

    -- slow scan
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local obj, dist = findClosestMachine(GetEntityCoords(ped))
            nearby = (obj and dist <= Config.InteractDistance + 0.6) and obj or nil
            Wait(nearby and 250 or 750)
        end
    end)

    -- fast input loop, only while near a machine
    CreateThread(function()
        while true do
            local sleep = 500
            local canUse = nearby and DoesEntityExist(nearby) and not VendingState.open and not VendingState.busy
                and not (Config.BlockInVehicle and IsPedInAnyVehicle(PlayerPedId(), false))

            if canUse then
                sleep = 0
                local machine = Config.Machines[Utils.ModelLookup[GetEntityModel(nearby)]]
                if mode == 'textui' then
                    if shownFor ~= nearby then
                        Bridge.ShowTextUI(_L('help.textui', machine.label))
                        shownFor = nearby
                    end
                else
                    Bridge.HelpText(_L('help.use', machine.label))
                end

                if IsControlJustReleased(0, Config.NativeKey) then
                    if mode == 'textui' then Bridge.HideTextUI() shownFor = nil end
                    OpenMachine(nearby)
                end
            elseif shownFor then
                Bridge.HideTextUI()
                shownFor = nil
            end

            Wait(sleep)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────

function Interaction.Init()
    mode = resolveMode()
    if mode == 'ox_target' then
        registerOxTarget()
    elseif mode == 'qb-target' then
        registerQbTarget()
    else
        startProximity()
    end
    Utils.Debug('interaction mode:', mode)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #registered do
        local r = registered[i]
        if mode == 'ox_target' then
            pcall(function() exports.ox_target:removeModel(r.models, r.name) end)
        elseif mode == 'qb-target' then
            pcall(function() exports['qb-target']:RemoveTargetModel(r.models, r.name) end)
        end
    end
    if mode == 'textui' then Bridge.HideTextUI() end
end)
