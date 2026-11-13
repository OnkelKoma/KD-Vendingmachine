Utils = {}

local RESOURCE = GetCurrentResourceName()
local IS_SERVER = IsDuplicityVersion()

-- ─────────────────────────────────────────────────────────────────────────────
--  Logging
-- ─────────────────────────────────────────────────────────────────────────────

function Utils.Debug(...)
    if not Config.Debug then return end
    local args = { ... }
    for i = 1, #args do args[i] = tostring(args[i]) end
    print(('^5[%s]^7 %s'):format(RESOURCE, table.concat(args, ' ')))
end

function Utils.Warn(msg, ...)
    print(('^3[%s] WARNING:^7 %s'):format(RESOURCE, msg:format(...)))
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Resource / framework detection
-- ─────────────────────────────────────────────────────────────────────────────

---@param name string
---@return boolean
function Utils.IsStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

---@return 'qbox'|'qbcore'|'esx'|'standalone'
function Utils.GetFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if Utils.IsStarted('qbx_core') then return 'qbox' end
    if Utils.IsStarted('qb-core') then return 'qbcore' end
    if Utils.IsStarted('es_extended') then return 'esx' end
    return 'standalone'
end

---@return boolean
function Utils.UsesOxInventory()
    if Config.Inventory == 'ox_inventory' then return true end
    if Config.Inventory == 'framework' then return false end
    return Utils.IsStarted('ox_inventory')
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Machines
-- ─────────────────────────────────────────────────────────────────────────────

--- model hash -> machine id
Utils.ModelLookup = {}

for id, machine in pairs(Config.Machines) do
    machine.id = id
    machine.hashes = {}
    for i = 1, #machine.models do
        local hash = joaat(machine.models[i])
        machine.hashes[i] = hash
        if Utils.ModelLookup[hash] then
            Utils.Warn('model %s is used by both "%s" and "%s"', machine.models[i], Utils.ModelLookup[hash], id)
        end
        Utils.ModelLookup[hash] = id
    end
    for i = 1, #machine.items do
        machine.items[i].index = i
    end
    if not Config.Animations[machine.animation] then
        Utils.Warn('machine "%s" uses unknown animation preset "%s"', id, tostring(machine.animation))
    end
end

---@param machine table
---@param name string
---@return table|nil
function Utils.GetItem(machine, name)
    for i = 1, #machine.items do
        if machine.items[i].name == name then return machine.items[i] end
    end
end

---@param machine table
---@return table<string, boolean>
function Utils.GetPayment(machine)
    return machine.payment or Config.Payment
end

--- Price including cup size multiplier (coffee). Always rounded to whole currency units.
---@param machine table
---@param item table
---@param sizeIndex? number
---@return number|nil
function Utils.GetPrice(machine, item, sizeIndex)
    local mult = 1.0
    if machine.sizes then
        local size = machine.sizes[tonumber(sizeIndex) or 1]
        if not size then return nil end
        mult = size.multiplier or 1.0
    end
    return math.floor(item.price * mult + 0.5)
end

--- Unique, deterministic key for a physical machine. Map props never move, so
--- rounding to one decimal is enough to tell side-by-side machines apart.
---@param id string
---@param coords vector3
---@return string
function Utils.MachineKey(id, coords)
    return ('%s:%.1f:%.1f:%.1f'):format(id, coords.x, coords.y, coords.z)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Tiny RPC layer (no ox_lib dependency)
-- ─────────────────────────────────────────────────────────────────────────────

local REQ = RESOURCE .. ':rpc:req'
local RES = RESOURCE .. ':rpc:res'

if IS_SERVER then
    local handlers = {}

    ---@param name string
    ---@param fn fun(source: number, ...): table
    function Utils.RegisterCallback(name, fn)
        handlers[name] = fn
    end

    RegisterNetEvent(REQ, function(name, id, ...)
        local src = source
        local handler = handlers[name]
        if type(id) ~= 'number' or not handler then return end

        local ok, result = pcall(handler, src, ...)
        if not ok then
            print(('^1[%s] callback "%s" errored:^7 %s'):format(RESOURCE, name, result))
            result = { ok = false, reason = 'failed' }
        end
        TriggerClientEvent(RES, src, id, result)
    end)
else
    local pending, nextId = {}, 0

    RegisterNetEvent(RES, function(id, result)
        local p = pending[id]
        if not p then return end
        pending[id] = nil
        p:resolve(result)
    end)

    --- Calls a server callback and yields until it answers (or times out).
    ---@param name string
    ---@return table
    function Utils.Await(name, ...)
        nextId = nextId + 1
        local id = nextId
        local p = promise.new()
        pending[id] = p

        SetTimeout(10000, function()
            if pending[id] then
                pending[id] = nil
                p:resolve({ ok = false, reason = 'timeout' })
            end
        end)

        TriggerServerEvent(REQ, name, id, ...)
        return Citizen.Await(p)
    end
end
