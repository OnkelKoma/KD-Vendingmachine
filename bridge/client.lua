--[[
    Client bridge: notifications & help text, independent of framework.
]]

Bridge = {}

local framework = Utils.GetFramework()

local function notifyProvider()
    if Config.Notify ~= 'auto' then return Config.Notify end
    if Utils.IsStarted('ox_lib') then return 'ox_lib' end
    if framework ~= 'standalone' then return 'framework' end
    return 'native'
end

local function nativeNotify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

---@param msg string
---@param kind? 'success'|'error'|'inform'
function Bridge.Notify(msg, kind)
    kind = kind or 'inform'
    local provider = notifyProvider()

    if provider == 'ox_lib' then
        TriggerEvent('ox_lib:notify', {
            title = _L('notify.title'),
            description = msg,
            type = kind,
            icon = 'cash-register',
        })
    elseif provider == 'framework' then
        if framework == 'qbox' then
            exports.qbx_core:Notify(msg, kind == 'inform' and 'primary' or kind)
        elseif framework == 'qbcore' then
            TriggerEvent('QBCore:Notify', msg, kind == 'inform' and 'primary' or kind)
        elseif framework == 'esx' then
            TriggerEvent('esx:showNotification', msg, kind == 'inform' and 'info' or kind)
        else
            nativeNotify(msg)
        end
    else
        nativeNotify(msg)
    end
end

RegisterNetEvent(GetCurrentResourceName() .. ':notify', Bridge.Notify)

--- Draws the native GTA help text for this frame.
---@param msg string
function Bridge.HelpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

function Bridge.ShowTextUI(msg)
    if not pcall(function() exports.ox_lib:showTextUI(msg, { position = 'left-center', icon = 'cash-register' }) end) then
        Utils.Debug('ox_lib textui unavailable')
    end
end

function Bridge.HideTextUI()
    pcall(function() exports.ox_lib:hideTextUI() end)
end

--- Resolves the image template used by the NUI for product images.
---@return string|nil
function Bridge.GetImageTemplate()
    local mode = Config.UI.images
    if mode == 'drawn' or not mode then return nil end
    if mode ~= 'inventory' then return mode end

    if Utils.IsStarted('ox_inventory') then return 'nui://ox_inventory/web/images/%s.png' end
    for _, inv in ipairs({ 'qb-inventory', 'ps-inventory', 'lj-inventory' }) do
        if Utils.IsStarted(inv) then return ('nui://%s/html/images/%%s.png'):format(inv) end
    end
    return nil
end
