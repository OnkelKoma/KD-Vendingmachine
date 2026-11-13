--[[
    Main client flow:
      target / key  ->  OpenMachine  ->  walk up + browse anim  ->  NUI
      NUI purchase  ->  press anim + server purchase  ->  NUI vend animation
      NUI take      ->  close NUI  ->  grab anim with product in hand
]]

VendingState = { open = false, busy = false }

local current   -- { entity, machine, coords, preset, pending, price }

local function buildPayload(machine, stock)
    local items = {}
    for i = 1, #machine.items do
        local item = machine.items[i]
        items[i] = {
            name   = item.name,
            label  = item.label,
            price  = item.price,
            kind   = item.kind or 'can',
            color  = item.color,
            accent = item.accent,
            image  = item.image,
            icon   = item.icon,
            stock  = stock and stock[item.name] or nil,
        }
    end

    return {
        id      = machine.id,
        brand   = machine.brand or machine.label,
        tagline = machine.tagline,
        layout  = machine.layout,
        theme   = machine.theme,
        sizes   = machine.sizes,
        items   = items,
    }
end

local function closeMachine(skipGrab)
    if not VendingState.open then return end
    VendingState.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    local c = current
    current = nil
    if not c then return end

    if c.pending and not skipGrab then
        VendingState.busy = true
        Anim.Grab(c.preset, c.pending)
        Bridge.Notify(_L('notify.purchased', c.pending.label, Config.UI.currency, c.price or c.pending.price), 'success')
        VendingState.busy = false
    else
        Anim.StopBrowse()
    end
end

--- Opens the vending UI for a machine entity. Safe to call from anywhere (target callbacks, exports...).
---@param entity number
function OpenMachine(entity)
    if VendingState.open or VendingState.busy then
        return Bridge.Notify(_L('notify.busy'), 'error')
    end
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    local machineId = Utils.ModelLookup[GetEntityModel(entity)]
    local machine = machineId and Config.Machines[machineId]
    if not machine then return end

    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end
    if Config.BlockInVehicle and IsPedInAnyVehicle(ped, false) then
        return Bridge.Notify(_L('notify.in_vehicle'), 'error')
    end

    VendingState.busy = true

    CreateThread(function()
        local coords = GetEntityCoords(entity)
        local res = Utils.Await('open', machineId, coords)

        if not res or not res.ok then
            VendingState.busy = false
            return Bridge.Notify(_L('reason.' .. ((res and res.reason) or 'failed')), 'error')
        end

        local preset = Config.Animations[machine.animation] or {}
        Anim.Align(entity, preset)
        Anim.StartBrowse(preset)

        current = { entity = entity, machine = machine, coords = coords, preset = preset }
        VendingState.busy = false
        VendingState.open = true

        SetNuiFocus(true, true)
        SendNUIMessage({
            action        = 'open',
            machine       = buildPayload(machine, res.stock),
            balance       = res.balance,
            payment       = Utils.GetPayment(machine),
            locale        = GetUILocale(),
            ui            = Config.UI,
            imageTemplate = Bridge.GetImageTemplate(),
        })

        -- watchdog: close if the player dies or is pushed away from the machine
        while VendingState.open and current do
            local p = PlayerPedId()
            if IsEntityDead(p) or #(GetEntityCoords(p) - coords) > 3.0 then
                closeMachine(true)
                break
            end
            Wait(500)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  NUI callbacks
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('purchase', function(data, cb)
    if not current or current.pending or VendingState.busy then
        return cb({ ok = false, reason = 'failed' })
    end

    VendingState.busy = true
    Anim.Press(current.preset)

    local res = Utils.Await('purchase', current.machine.id, current.coords, data.item, data.payment, data.size)
    VendingState.busy = false

    if res and res.ok and current then
        current.pending = Utils.GetItem(current.machine, data.item)
        current.price = res.price
    end

    cb(res or { ok = false, reason = 'failed' })
end)

RegisterNUICallback('take', function(_, cb)
    cb(1)
    closeMachine(false)
end)

RegisterNUICallback('close', function(_, cb)
    cb(1)
    -- walking away with a paid item still in the tray? grab it anyway, they paid for it
    closeMachine(false)
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Exports / lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

exports('OpenMachine', OpenMachine)
exports('IsOpen', function() return VendingState.open end)
exports('CloseMachine', function() closeMachine(false) end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if VendingState.open then SetNuiFocus(false, false) end
    Anim.Cleanup()
end)

CreateThread(function()
    Interaction.Init()
end)
