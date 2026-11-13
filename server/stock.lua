--[[
    In-memory stock per physical machine. Machines are created lazily the first time
    somebody opens them and refill completely after Config.Stock.restockMinutes.
]]

Stock = {}

local machines = {}   -- [key] = { items = { [name] = count }, restocked = os.time() }

local function maxStock(item)
    return item.stock or Config.Stock.default
end

local function fill(machine)
    local items = {}
    for i = 1, #machine.items do
        local item = machine.items[i]
        items[item.name] = maxStock(item)
    end
    return { items = items, restocked = os.time() }
end

---@param key string
---@param machine table
---@return table
local function get(key, machine)
    local entry = machines[key]
    local interval = (Config.Stock.restockMinutes or 0) * 60

    if not entry or (interval > 0 and os.time() - entry.restocked >= interval) then
        entry = fill(machine)
        machines[key] = entry
    end
    return entry
end

--- Returns { [itemName] = count } or nil when stock is disabled.
---@param key string
---@param machine table
---@return table<string, number>|nil
function Stock.GetAll(key, machine)
    if not Config.Stock.enabled then return nil end
    return get(key, machine).items
end

---@param key string
---@param machine table
---@param itemName string
---@return number  math.huge when stock is disabled
function Stock.Get(key, machine, itemName)
    if not Config.Stock.enabled then return math.huge end
    return get(key, machine).items[itemName] or 0
end

---@param key string
---@param machine table
---@param itemName string
---@param amount number
function Stock.Remove(key, machine, itemName, amount)
    if not Config.Stock.enabled then return end
    local entry = get(key, machine)
    entry.items[itemName] = math.max(0, (entry.items[itemName] or 0) - amount)
end

--- Refills every machine (or one machine if `key` is given).
---@param key? string
function Stock.Restock(key)
    if key then
        machines[key] = nil
    else
        machines = {}
    end
end
