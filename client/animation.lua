--[[
    Player animations: walk up to the machine, press buttons while browsing,
    confirm the purchase and physically grab the product with a hand prop.
]]

Anim = {}

local browsing    -- currently looping browse anim { dict, clip }
local handProp    -- entity currently attached to the player's hand

local function loadDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    if not DoesAnimDictExist(dict) then
        Utils.Warn('anim dict "%s" does not exist', dict)
        return false
    end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then return false end
        Wait(0)
    end
    return true
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then
        Utils.Warn('prop model "%s" is not in the game files', tostring(model))
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return nil end
        Wait(0)
    end
    return hash
end

local function resolveProp(item)
    local prop = item and item.prop
    if type(prop) == 'string' then return Config.Props[prop] end
    if type(prop) == 'table' then return prop end
    return nil
end

local function attachProp(ped, prop)
    local hash = loadModel(prop.model)
    if not hash then return nil end

    local coords = GetEntityCoords(ped)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, Config.NetworkedProps, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityCollision(obj, false, false)

    local pos, rot = prop.pos or vec3(0, 0, 0), prop.rot or vec3(0, 0, 0)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, prop.bone or 28422),
        pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
    return obj
end

local function deleteHandProp()
    if handProp and DoesEntityExist(handProp) then
        DetachEntity(handProp, true, false)
        DeleteEntity(handProp)
    end
    handProp = nil
end

--- Walks the player in front of the machine and turns them to face it.
---@param entity number
---@param preset table
function Anim.Align(entity, preset)
    if not Config.AlignPlayer or not DoesEntityExist(entity) then return end

    local ped = PlayerPedId()
    local offset = preset.align or vec3(0.0, -0.78, 0.0)
    local target = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    local heading = GetEntityHeading(entity)

    if #(GetEntityCoords(ped).xy - target.xy) > 0.15 then
        TaskGoStraightToCoord(ped, target.x, target.y, target.z, 1.0, 4000, heading, 0.05)
        local timeout = GetGameTimer() + 4000
        while GetGameTimer() < timeout do
            Wait(50)
            if #(GetEntityCoords(ped).xy - target.xy) < 0.2 then break end
        end
    end

    TaskAchieveHeading(ped, heading, 600)
    local timeout = GetGameTimer() + 700
    while GetGameTimer() < timeout and math.abs(((GetEntityHeading(ped) - heading + 180) % 360) - 180) > 8.0 do
        Wait(0)
    end
    SetEntityHeading(ped, heading)
end

--- Starts the looping "pressing buttons" animation shown while the UI is open.
---@param preset table
function Anim.StartBrowse(preset)
    local a = preset.browse
    if not a or not loadDict(a.dict) then return end
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    TaskPlayAnim(ped, a.dict, a.clip, 3.0, 3.0, -1, a.flag or 49, 0.0, false, false, false)
    browsing = a
end

function Anim.StopBrowse()
    if not browsing then return end
    StopAnimTask(PlayerPedId(), browsing.dict, browsing.clip, 2.0)
    browsing = nil
end

--- Plays the "confirm" button press. Non-blocking.
---@param preset table
function Anim.Press(preset)
    local a = preset.press
    if not a or not loadDict(a.dict) then return end
    local ped = PlayerPedId()
    TaskPlayAnim(ped, a.dict, a.clip, 6.0, 3.0, -1, a.flag or 48, 0.0, false, false, false)

    -- go back to browsing once the press is done, the player is still standing at the machine
    CreateThread(function()
        Wait(math.floor(GetAnimDuration(a.dict, a.clip) * 1000))
        if browsing and IsEntityPlayingAnim(ped, a.dict, a.clip, 3) then
            TaskPlayAnim(ped, browsing.dict, browsing.clip, 3.0, 3.0, -1, browsing.flag or 49, 0.0, false, false, false)
        end
    end)
end

--- Reaches into the tray / cup bay and takes the product. Blocking.
---@param preset table
---@param item table
function Anim.Grab(preset, item)
    Anim.StopBrowse()
    local a = preset.grab
    local ped = PlayerPedId()
    if not a or not loadDict(a.dict) then return end

    TaskPlayAnim(ped, a.dict, a.clip, 6.0, -6.0, -1, a.flag or 0, 0.0, false, false, false)

    local start = GetGameTimer() + 1000
    while not IsEntityPlayingAnim(ped, a.dict, a.clip, 3) and GetGameTimer() < start do Wait(0) end

    local prop = resolveProp(item)
    local deadline = GetGameTimer() + math.floor(GetAnimDuration(a.dict, a.clip) * 1000) + 500

    while GetGameTimer() < deadline and IsEntityPlayingAnim(ped, a.dict, a.clip, 3) do
        local phase = GetEntityAnimCurrentTime(ped, a.dict, a.clip)
        if prop and not handProp and phase >= (a.propAt or 0.4) then
            handProp = attachProp(ped, prop)
        end
        if phase >= (a.stopAt or 0.98) then break end
        Wait(0)
    end

    if prop and not handProp then handProp = attachProp(ped, prop) end

    Wait(a.hold or 800)
    deleteHandProp()
    StopAnimTask(ped, a.dict, a.clip, 2.0)
    RemoveAnimDict(a.dict)
end

--- Hard reset, used when the resource stops or something goes wrong.
function Anim.Cleanup()
    deleteHandProp()
    if browsing then Anim.StopBrowse() end
end
