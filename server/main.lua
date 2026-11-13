local RESOURCE = GetCurrentResourceName()
local lastPurchase = {}   -- [source] = GetGameTimer()

-- ─────────────────────────────────────────────────────────────────────────────
--  Logging
-- ─────────────────────────────────────────────────────────────────────────────

local function sendWebhook(title, color, fields)
    if ServerConfig.Webhook == '' then return end
    PerformHttpRequest(ServerConfig.Webhook, function() end, 'POST', json.encode({
        username = 'KD Vending',
        embeds = { {
            title = title,
            color = color,
            fields = fields,
            footer = { text = RESOURCE },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }), { ['Content-Type'] = 'application/json' })
end

local function playerField(src)
    return { name = 'Player', value = ('%s (`%s`) · id %d'):format(GetPlayerName(src) or '?', Bridge.GetIdentifier(src), src), inline = false }
end

local function logSuspicious(src, reason, detail)
    Utils.Warn('suspicious request from %s (%d): %s %s', GetPlayerName(src) or '?', src, reason, detail or '')
    if not ServerConfig.Log.suspicious then return end
    sendWebhook('Suspicious vending request', 15548997, {
        playerField(src),
        { name = 'Reason', value = reason, inline = true },
        { name = 'Detail', value = detail or '-', inline = true },
    })
end

local function logPurchase(src, machine, item, price, payment)
    if ServerConfig.Log.console then
        print(('[%s] %s bought %s for %s%d (%s) at %s'):format(RESOURCE, GetPlayerName(src) or src, item.name, Config.UI.currency, price, payment, machine.id))
    end
    if not ServerConfig.Log.purchases then return end
    sendWebhook('Vending purchase', 5763719, {
        playerField(src),
        { name = 'Machine', value = machine.label, inline = true },
        { name = 'Item', value = ('%s (`%s`)'):format(item.label, item.name), inline = true },
        { name = 'Price', value = ('%s%d · %s'):format(Config.UI.currency, price, payment), inline = true },
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Validation
-- ─────────────────────────────────────────────────────────────────────────────

---@return table|nil machine, string|nil reason
local function validateMachine(src, machineId, coords)
    local machine = type(machineId) == 'string' and Config.Machines[machineId]
    if not machine or type(coords) ~= 'vector3' then
        logSuspicious(src, 'invalid machine', tostring(machineId))
        return nil, 'invalid'
    end

    local ped = GetPlayerPed(src)
    if ped == 0 then return nil, 'failed' end

    local dist = #(GetEntityCoords(ped) - coords)
    if dist > ServerConfig.MaxDistance then
        logSuspicious(src, 'too far', ('%.1fm from %s'):format(dist, machineId))
        return nil, 'too_far'
    end

    if not Bridge.IsLoaded(src) then return nil, 'failed' end
    return machine
end

local function balances(src, machine)
    local payment = Utils.GetPayment(machine)
    return {
        cash = payment.cash and Bridge.GetMoney(src, 'cash') or nil,
        bank = payment.bank and Bridge.GetMoney(src, 'bank') or nil,
    }
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Callbacks
-- ─────────────────────────────────────────────────────────────────────────────

Utils.RegisterCallback('open', function(src, machineId, coords)
    local machine, reason = validateMachine(src, machineId, coords)
    if not machine then return { ok = false, reason = reason } end

    local key = Utils.MachineKey(machineId, coords)
    return {
        ok = true,
        balance = balances(src, machine),
        stock = Stock.GetAll(key, machine),
    }
end)

Utils.RegisterCallback('purchase', function(src, machineId, coords, itemName, payment, sizeIndex)
    local now = GetGameTimer()
    if lastPurchase[src] and now - lastPurchase[src] < Config.Cooldown then
        return { ok = false, reason = 'cooldown' }
    end

    local machine, reason = validateMachine(src, machineId, coords)
    if not machine then return { ok = false, reason = reason } end

    local item = type(itemName) == 'string' and Utils.GetItem(machine, itemName)
    if not item then
        logSuspicious(src, 'invalid item', ('%s @ %s'):format(tostring(itemName), machineId))
        return { ok = false, reason = 'invalid' }
    end

    if (payment ~= 'cash' and payment ~= 'bank') or not Utils.GetPayment(machine)[payment] then
        return { ok = false, reason = 'payment_method' }
    end

    local price = Utils.GetPrice(machine, item, sizeIndex)
    if not price then return { ok = false, reason = 'invalid' } end

    local key = Utils.MachineKey(machineId, coords)
    if Stock.Get(key, machine, item.name) < 1 then
        return { ok = false, reason = 'sold_out' }
    end

    if not Bridge.CanCarry(src, item.name, 1) then
        return { ok = false, reason = 'no_space' }
    end

    if Bridge.GetMoney(src, payment) < price or not Bridge.RemoveMoney(src, payment, price, ('vending-%s'):format(machineId)) then
        return { ok = false, reason = 'no_money' }
    end

    local metadata
    if item.metadata then
        metadata = {}
        for k, v in pairs(item.metadata) do metadata[k] = v end
    end
    if machine.sizes and metadata then
        metadata.size = machine.sizes[tonumber(sizeIndex) or 1].name
    end

    if not Bridge.AddItem(src, item.name, 1, metadata) then
        Bridge.AddMoney(src, payment, price, ('vending-refund-%s'):format(machineId))
        return { ok = false, reason = 'no_space' }
    end

    lastPurchase[src] = now
    Stock.Remove(key, machine, item.name, 1)
    logPurchase(src, machine, item, price, payment)

    -- Hook for other resources: AddEventHandler('kd-vendingmachine:purchased', function(src, data) end)
    TriggerEvent(RESOURCE .. ':purchased', src, {
        machine = machineId,
        item = item.name,
        price = price,
        payment = payment,
        coords = coords,
    })

    return {
        ok = true,
        price = price,
        balance = balances(src, machine),
        stock = Stock.GetAll(key, machine),
    }
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin / exports
-- ─────────────────────────────────────────────────────────────────────────────

RegisterCommand('restockvending', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, ServerConfig.AdminAce) then return end
    Stock.Restock()
    if src == 0 then
        print(('[%s] all vending machines restocked'):format(RESOURCE))
    else
        Bridge.Notify(src, 'All vending machines restocked', 'success')
    end
end, false)

exports('Restock', Stock.Restock)
exports('GetStock', function(machineId, coords)
    local machine = Config.Machines[machineId]
    if not machine then return nil end
    return Stock.GetAll(Utils.MachineKey(machineId, coords), machine)
end)

AddEventHandler('playerDropped', function()
    lastPurchase[source] = nil
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Startup checks
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    Wait(2000)   -- give inventories time to load their item lists
    local inv = Bridge.UsesOx and 'ox_inventory' or 'framework inventory'
    print(('^2[%s]^7 v%s loaded · framework: ^5%s^7 · inventory: ^5%s^7'):format(
        RESOURCE, GetResourceMetadata(RESOURCE, 'version', 0) or '?', Bridge.Framework, inv))

    local missing, checked = {}, {}
    for _, machine in pairs(Config.Machines) do
        for i = 1, #machine.items do
            local name = machine.items[i].name
            if not checked[name] then
                checked[name] = true
                if Bridge.ItemExists(name) == false then missing[#missing + 1] = name end
            end
        end
    end

    if #missing > 0 then
        table.sort(missing)
        Utils.Warn('these items do not exist in your inventory and cannot be sold: %s', table.concat(missing, ', '))
        Utils.Warn('add them using the files in /install (see README > Items)')
    end
end)
