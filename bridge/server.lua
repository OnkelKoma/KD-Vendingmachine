--[[
    Server bridge: money, items and player data for QBox, QBCore, ESX and standalone (ox_inventory).
    Every function returns plain values so server/main.lua never has to care about the framework.
]]

Bridge = {}

local framework = Utils.GetFramework()
local useOx = Utils.UsesOxInventory()
local QBCore, ESX

if framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()
elseif framework == 'standalone' and not useOx then
    Utils.Warn('no framework and no ox_inventory found - purchases are disabled. See README > Requirements.')
end

Bridge.Framework = framework
Bridge.UsesOx = useOx

local function getPlayer(src)
    if framework == 'qbox' then
        return exports.qbx_core:GetPlayer(src)
    elseif framework == 'qbcore' then
        return QBCore.Functions.GetPlayer(src)
    elseif framework == 'esx' then
        return ESX.GetPlayerFromId(src)
    end
    return useOx and src or nil
end

--- ESX calls cash 'money'
local function esxAccount(account)
    return account == 'cash' and 'money' or account
end

---@param src number
---@return boolean
function Bridge.IsLoaded(src)
    return getPlayer(src) ~= nil
end

---@param src number
---@return string
function Bridge.GetIdentifier(src)
    local player = getPlayer(src)
    if not player then return 'unknown' end
    if framework == 'qbox' or framework == 'qbcore' then
        return player.PlayerData.citizenid
    elseif framework == 'esx' then
        return player.identifier
    end
    return GetPlayerIdentifierByType(src, 'license') or 'unknown'
end

---@param src number
---@param account 'cash'|'bank'
---@return number
function Bridge.GetMoney(src, account)
    local player = getPlayer(src)
    if not player then return 0 end

    if framework == 'qbox' or framework == 'qbcore' then
        return player.PlayerData.money[account] or 0
    elseif framework == 'esx' then
        local acc = player.getAccount(esxAccount(account))
        return acc and acc.money or 0
    elseif useOx and account == 'cash' then
        return exports.ox_inventory:GetItemCount(src, 'money') or 0
    end
    return 0
end

---@param src number
---@param account 'cash'|'bank'
---@param amount number
---@param reason string
---@return boolean
function Bridge.RemoveMoney(src, account, amount, reason)
    local player = getPlayer(src)
    if not player or amount < 0 then return false end
    if amount == 0 then return true end

    if framework == 'qbox' or framework == 'qbcore' then
        return player.Functions.RemoveMoney(account, amount, reason) == true
    elseif framework == 'esx' then
        if Bridge.GetMoney(src, account) < amount then return false end
        player.removeAccountMoney(esxAccount(account), amount, reason)
        return true
    elseif useOx and account == 'cash' then
        return exports.ox_inventory:RemoveItem(src, 'money', amount) == true
    end
    return false
end

---@param src number
---@param account 'cash'|'bank'
---@param amount number
---@param reason string
function Bridge.AddMoney(src, account, amount, reason)
    local player = getPlayer(src)
    if not player or amount <= 0 then return end

    if framework == 'qbox' or framework == 'qbcore' then
        player.Functions.AddMoney(account, amount, reason)
    elseif framework == 'esx' then
        player.addAccountMoney(esxAccount(account), amount, reason)
    elseif useOx and account == 'cash' then
        exports.ox_inventory:AddItem(src, 'money', amount)
    end
end

---@param src number
---@param item string
---@param count number
---@return boolean
function Bridge.CanCarry(src, item, count)
    if useOx then
        return exports.ox_inventory:CanCarryItem(src, item, count) == true
    end

    local player = getPlayer(src)
    if not player then return false end

    if framework == 'qbox' or framework == 'qbcore' then
        if Utils.IsStarted('qb-inventory') then
            local ok, result = pcall(function() return exports['qb-inventory']:CanAddItem(src, item, count) end)
            if ok then return result ~= false end
        end
        return true
    elseif framework == 'esx' then
        if player.canCarryItem then return player.canCarryItem(item, count) end
        return true
    end
    return false
end

---@param src number
---@param item string
---@param count number
---@param metadata? table
---@return boolean
function Bridge.AddItem(src, item, count, metadata)
    if useOx then
        local success = exports.ox_inventory:AddItem(src, item, count, metadata)
        return success == true or (type(success) == 'table')
    end

    local player = getPlayer(src)
    if not player then return false end

    if framework == 'qbox' or framework == 'qbcore' then
        local added = player.Functions.AddItem(item, count, false, metadata)
        if added and QBCore then
            local shared = QBCore.Shared.Items[item]
            TriggerClientEvent('qb-inventory:client:ItemBox', src, shared, 'add', count)
            TriggerClientEvent('inventory:client:ItemBox', src, shared, 'add', count)
        end
        return added == true
    elseif framework == 'esx' then
        player.addInventoryItem(item, count)
        return true
    end
    return false
end

--- Used at startup to warn about items that don't exist in the inventory.
---@param item string
---@return boolean|nil  nil = unable to check
function Bridge.ItemExists(item)
    if useOx then
        return exports.ox_inventory:Items(item) ~= nil
    elseif framework == 'qbcore' then
        return QBCore.Shared.Items[item] ~= nil
    elseif framework == 'esx' and ESX.Items then
        return ESX.Items[item] ~= nil
    end
    return nil
end

---@param src number
---@param msg string
---@param kind? string
function Bridge.Notify(src, msg, kind)
    TriggerClientEvent(GetCurrentResourceName() .. ':notify', src, msg, kind)
end
