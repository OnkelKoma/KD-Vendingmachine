--[[
    ██╗  ██╗██████╗       ██╗   ██╗███████╗███╗   ██╗██████╗ ██╗███╗   ██╗ ██████╗
    ██║ ██╔╝██╔══██╗      ██║   ██║██╔════╝████╗  ██║██╔══██╗██║████╗  ██║██╔════╝
    █████╔╝ ██║  ██║█████╗██║   ██║█████╗  ██╔██╗ ██║██║  ██║██║██╔██╗ ██║██║  ███╗
    ██╔═██╗ ██║  ██║╚════╝╚██╗ ██╔╝██╔══╝  ██║╚██╗██║██║  ██║██║██║╚██╗██║██║   ██║
    ██║  ██╗██████╔╝       ╚████╔╝ ███████╗██║ ╚████║██████╔╝██║██║ ╚████║╚██████╔╝
    ╚═╝  ╚═╝╚═════╝         ╚═══╝  ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝

    kd-vendingmachine · shared configuration
    Everything in this file is sent to clients. Put secrets (webhooks etc.) in config/server.lua.
]]

Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  General
-- ─────────────────────────────────────────────────────────────────────────────

Config.Debug  = false   -- prints extra info to the F8 / server console
Config.Locale = 'en'    -- 'en' | 'da'  (see /locales)

--- Framework used for money & player data.
--- 'auto' picks the first one that is running: qbx_core -> qb-core -> es_extended -> standalone
--- 'standalone' requires ox_inventory (money is the 'money' item, card payments are disabled).
---@type 'auto'|'qbox'|'qbcore'|'esx'|'standalone'
Config.Framework = 'auto'

--- Inventory used for items.
--- 'auto' uses ox_inventory if it is running, otherwise the framework's own inventory functions.
---@type 'auto'|'ox_inventory'|'framework'
Config.Inventory = 'auto'

--- How players interact with machines.
--- 'auto' picks: ox_target -> qb-target -> ox_lib text UI -> native GTA help text
---@type 'auto'|'ox_target'|'qb-target'|'textui'|'native'
Config.Interaction = 'auto'

--- Notification provider.
---@type 'auto'|'ox_lib'|'framework'|'native'
Config.Notify = 'auto'

Config.InteractDistance = 1.6    -- metres; how close the player must be to use a machine
Config.NativeKey        = 38     -- control used for 'native' / 'textui' interaction (38 = E)

-- ─────────────────────────────────────────────────────────────────────────────
--  Behaviour
-- ─────────────────────────────────────────────────────────────────────────────

Config.AlignPlayer     = true    -- walk the player up to the machine before the UI opens
Config.NetworkedProps  = true    -- other players can see the can / snack in your hand
Config.BlockInVehicle  = true
Config.Cooldown        = 1500    -- ms between purchases per player (server enforced)

--- Default payment methods. Can be overridden per machine with `payment = { ... }`.
Config.Payment = {
    cash = true,
    bank = true,    -- shown as a contactless card reader
}

--- Stock system. Stock is tracked per physical machine (by coordinates) and kept in memory.
Config.Stock = {
    enabled        = true,
    default        = 12,   -- default stock per slot (override per item with `stock = n`)
    restockMinutes = 30,   -- machines refill completely after this many minutes since the last restock
}

-- ─────────────────────────────────────────────────────────────────────────────
--  Interface
-- ─────────────────────────────────────────────────────────────────────────────

Config.UI = {
    currency    = '$',
    sound       = true,
    volume      = 0.35,     -- 0.0 - 1.0
    showBalance = true,     -- show cash / bank balance next to the payment modules
    autoTake    = 8000,     -- ms; product is taken automatically if the player doesn't click the tray (0 = never)

    --- Product images inside the machine.
    ---  'drawn'     -> stylised CSS products (cans, bottles, bars, cups...) coloured per item. Works with zero setup.
    ---  'inventory' -> your inventory's item images (ox_inventory / qb-inventory / ps-inventory / lj-inventory)
    ---  any string containing %s -> custom template, e.g. 'nui://my-images/%s.png'
    --- A per-item `image = 'url'` always wins.
    images = 'drawn',
}

-- ─────────────────────────────────────────────────────────────────────────────
--  Animations
--  Each machine references one of these presets with `animation = 'name'`.
--   align   : where the player stands, as an offset from the machine (machines face -Y)
--   browse  : looped while the UI is open (the "pressing buttons" idle)
--   press   : played once when the purchase is confirmed
--   grab    : played when the product is taken; `propAt` is the anim phase (0-1) at which
--             the product appears in the hand, `hold` is how long (ms) it stays after the anim
-- ─────────────────────────────────────────────────────────────────────────────

Config.Animations = {
    tray_low = {    -- soda / water / snack machines: product drops into a low tray
        align  = vec3(0.0, -0.78, 0.0),
        browse = { dict = 'anim@heists@keypad@', clip = 'idle_a', flag = 49 },
        press  = { dict = 'anim@heists@keypad@', clip = 'exit',   flag = 48 },
        grab   = { dict = 'pickup_object',       clip = 'pickup_low', flag = 0, propAt = 0.36, stopAt = 0.92, hold = 900 },
    },

    cup_bay = {     -- coffee: cup is taken from a bay at chest height
        align  = vec3(0.0, -0.72, 0.0),
        browse = { dict = 'anim@heists@keypad@', clip = 'idle_a', flag = 49 },
        press  = { dict = 'anim@heists@keypad@', clip = 'exit',   flag = 48 },
        grab   = { dict = 'mp_common',           clip = 'givetake1_a', flag = 48, propAt = 0.45, stopAt = 0.95, hold = 1100 },
    },

    knob_pull = {   -- retro cigarette machine: pull a knob, take the pack from the tray
        align  = vec3(0.0, -0.76, 0.0),
        browse = { dict = 'anim@heists@keypad@', clip = 'idle_a', flag = 49 },
        press  = { dict = 'anim@heists@keypad@', clip = 'exit',   flag = 48 },
        grab   = { dict = 'pickup_object',       clip = 'pickup_low', flag = 0, propAt = 0.36, stopAt = 0.92, hold = 900 },
    },
}

--- Hand props. Items reference these with `prop = 'name'` (or pass a full table).
--- Bone 28422 = PH_R_Hand (right hand prop bone).
Config.Props = {
    can    = { model = 'prop_ld_can_01',      bone = 28422, pos = vec3(0.0, 0.0, 0.0),   rot = vec3(0.0, 0.0, 0.0) },
    ecola  = { model = 'prop_ecola_can',      bone = 28422, pos = vec3(0.0, 0.0, 0.0),   rot = vec3(0.0, 0.0, 0.0) },
    bottle = { model = 'prop_ld_flow_bottle', bone = 28422, pos = vec3(0.0, 0.0, -0.05), rot = vec3(0.0, 0.0, 0.0) },
    bar    = { model = 'prop_choc_ego',       bone = 28422, pos = vec3(0.0, 0.0, 0.0),   rot = vec3(0.0, 0.0, 0.0) },
    candy  = { model = 'prop_candy_pqs',      bone = 28422, pos = vec3(0.0, 0.0, 0.0),   rot = vec3(0.0, 0.0, 0.0) },
    chips  = { model = 'ng_proc_food_chips01a', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
    cup    = { model = 'p_amb_coffeecup_01',  bone = 28422, pos = vec3(0.0, 0.0, 0.0),   rot = vec3(0.0, 0.0, 0.0) },
    pack   = { model = 'prop_cigar_pack_01',  bone = 28422, pos = vec3(0.0, 0.0, 0.0),   rot = vec3(0.0, 0.0, 0.0) },
}

-- ─────────────────────────────────────────────────────────────────────────────
--  Machines
--
--   label     : name used in target / notifications
--   brand     : name printed on the machine UI
--   tagline   : small slogan on the UI
--   layout    : 'soda' | 'glass' | 'coffee' | 'retro'   (UI template)
--   theme     : 'ecola' | 'sprunk' | 'raine' | 'snack' | 'coffee' | 'redwood' (colour scheme / branding)
--   models    : every prop model that should open this machine
--   animation : key from Config.Animations
--   icon      : Font Awesome icon for ox_target / qb-target
--   payment   : (optional) override Config.Payment
--
--   items[]   :
--     name    : inventory item name (must exist in your inventory!)
--     label   : display name
--     price   : price per unit
--     kind    : drawn product shape: 'can' | 'bottle' | 'bar' | 'bag' | 'candy' | 'cup' | 'pack'
--     color   : primary product colour   accent : secondary colour
--     prop    : key from Config.Props (hand prop for the grab animation)
--     stock   : (optional) override Config.Stock.default
--     image   : (optional) image url, overrides Config.UI.images
--     metadata: (optional, ox_inventory) metadata table given with the item
-- ─────────────────────────────────────────────────────────────────────────────

Config.Machines = {
    ecola = {
        label     = 'eCola Machine',
        brand     = 'eCola',
        tagline   = 'Deliciously Infectious!',
        layout    = 'soda',
        theme     = 'ecola',
        models    = { 'prop_vend_soda_01' },
        animation = 'tray_low',
        icon      = 'fa-solid fa-bottle-water',
        items = {
            { name = 'ecola',       label = 'eCola',          price = 4, kind = 'can',    color = '#c4161c', accent = '#ffffff', prop = 'ecola' },
            { name = 'ecola_light', label = 'eCola Light',    price = 4, kind = 'can',    color = '#d9d9d9', accent = '#c4161c', prop = 'ecola' },
            { name = 'ecola_cherry',label = 'eCola Cherry',   price = 5, kind = 'can',    color = '#6d0f2a', accent = '#ff4d6d', prop = 'ecola' },
            { name = 'orangotang',  label = 'Orang-O-Tang',   price = 4, kind = 'can',    color = '#ff7a00', accent = '#3b1d00', prop = 'can' },
            { name = 'junk_energy', label = 'Junk Energy',    price = 6, kind = 'can',    color = '#1b1b1b', accent = '#b6ff00', prop = 'can' },
            { name = 'water',       label = 'Raine Water',    price = 3, kind = 'bottle', color = '#7cc6f2', accent = '#ffffff', prop = 'bottle' },
        },
    },

    sprunk = {
        label     = 'Sprunk Machine',
        brand     = 'Sprunk',
        tagline   = 'The Essence of Life',
        layout    = 'soda',
        theme     = 'sprunk',
        models    = { 'prop_vend_soda_02' },
        animation = 'tray_low',
        icon      = 'fa-solid fa-bottle-water',
        items = {
            { name = 'sprunk',       label = 'Sprunk',         price = 4, kind = 'can',    color = '#2fb344', accent = '#e9ff5c', prop = 'can' },
            { name = 'sprunk_light', label = 'Sprunk Light',   price = 4, kind = 'can',    color = '#c9f2b0', accent = '#1e7a2f', prop = 'can' },
            { name = 'sprunk_xtreme',label = 'Sprunk Xtreme',  price = 5, kind = 'can',    color = '#0c3b16', accent = '#7dff3a', prop = 'can' },
            { name = 'orangotang',   label = 'Orang-O-Tang',   price = 4, kind = 'can',    color = '#ff7a00', accent = '#3b1d00', prop = 'can' },
            { name = 'junk_energy',  label = 'Junk Energy',    price = 6, kind = 'can',    color = '#1b1b1b', accent = '#b6ff00', prop = 'can' },
            { name = 'water',        label = 'Raine Water',    price = 3, kind = 'bottle', color = '#7cc6f2', accent = '#ffffff', prop = 'bottle' },
        },
    },

    raine = {
        label     = 'Raine Water Machine',
        brand     = 'Raine',
        tagline   = 'Bottled at the source. Probably.',
        layout    = 'soda',
        theme     = 'raine',
        models    = { 'prop_vend_water_01' },
        animation = 'tray_low',
        icon      = 'fa-solid fa-droplet',
        items = {
            { name = 'water',          label = 'Still Water',     price = 3, kind = 'bottle', color = '#8fd3fe', accent = '#ffffff', prop = 'bottle' },
            { name = 'water_sparkling',label = 'Sparkling Water', price = 3, kind = 'bottle', color = '#b7e9ff', accent = '#2b7bb9', prop = 'bottle' },
            { name = 'water_lemon',    label = 'Lemon Water',     price = 4, kind = 'bottle', color = '#f6f1a0', accent = '#2b7bb9', prop = 'bottle' },
            { name = 'sports_drink',   label = 'Electrolyte+',    price = 5, kind = 'bottle', color = '#40a9ff', accent = '#ffffff', prop = 'bottle' },
        },
    },

    snacks = {
        label     = 'Snack Machine',
        brand     = 'SnackStop',
        tagline   = 'Fuel for the streets',
        layout    = 'glass',
        theme     = 'snack',
        models    = { 'prop_vend_snak_01', 'prop_vend_snak_01_tu' },
        animation = 'tray_low',
        icon      = 'fa-solid fa-cookie-bite',
        items = {
            { name = 'egochaser',     label = 'EgoChaser',      price = 3, kind = 'bar',   color = '#f2c200', accent = '#3a1f00', prop = 'bar' },
            { name = 'meteorite',     label = 'Meteorite',      price = 3, kind = 'bar',   color = '#3b1f6b', accent = '#ffcf33', prop = 'bar' },
            { name = 'psqs',          label = "P's & Q's",      price = 2, kind = 'candy', color = '#ff4fa3', accent = '#ffffff', prop = 'candy' },
            { name = 'sweet_nothings',label = 'Sweet Nothings', price = 2, kind = 'candy', color = '#7a5cff', accent = '#ffe066', prop = 'candy' },
            { name = 'phat_chips',    label = 'Phat Chips',     price = 4, kind = 'bag',   color = '#e63946', accent = '#ffd166', prop = 'chips' },
            { name = 'phat_chips_bbq',label = 'Phat Chips BBQ', price = 4, kind = 'bag',   color = '#6a2c0b', accent = '#ff9f1c', prop = 'chips' },
            { name = 'big_cheese',    label = 'Big Cheese',     price = 4, kind = 'bag',   color = '#ffb703', accent = '#023047', prop = 'chips' },
            { name = 'sandwich',      label = 'Club Sandwich',  price = 7, kind = 'bar',   color = '#e9d8a6', accent = '#386641', prop = 'bar', stock = 6 },
        },
    },

    coffee = {
        label     = 'Coffee Machine',
        brand     = 'Bean Machine',
        tagline   = 'Freshly ground · Served hot',
        layout    = 'coffee',
        theme     = 'coffee',
        models    = { 'prop_vend_coffe_01' },
        animation = 'cup_bay',
        icon      = 'fa-solid fa-mug-hot',
        --- Cup sizes multiply the base price (server validated)
        sizes = {
            { label = 'S', name = 'Small',  multiplier = 1.0 },
            { label = 'M', name = 'Medium', multiplier = 1.25 },
            { label = 'L', name = 'Large',  multiplier = 1.5 },
        },
        items = {
            { name = 'coffee',     label = 'Black Coffee', price = 3, kind = 'cup', color = '#3b2416', accent = '#f5e6d3', prop = 'cup', icon = '☕' },
            { name = 'espresso',   label = 'Espresso',     price = 3, kind = 'cup', color = '#24150c', accent = '#c58b4c', prop = 'cup', icon = '◉' },
            { name = 'cappuccino', label = 'Cappuccino',   price = 4, kind = 'cup', color = '#a47148', accent = '#fff3e0', prop = 'cup', icon = '☁' },
            { name = 'latte',      label = 'Caffè Latte',  price = 4, kind = 'cup', color = '#c69c72', accent = '#fffaf0', prop = 'cup', icon = '❖' },
            { name = 'hot_choco',  label = 'Hot Chocolate',price = 4, kind = 'cup', color = '#5a3220', accent = '#ffd6a5', prop = 'cup', icon = '✦' },
            { name = 'tea',        label = 'Green Tea',    price = 3, kind = 'cup', color = '#6b8f3a', accent = '#f1ffe0', prop = 'cup', icon = '❦' },
        },
    },

    cigarettes = {
        label     = 'Cigarette Machine',
        brand     = 'Redwood',
        tagline   = 'Smoke like a real man',
        layout    = 'retro',
        theme     = 'redwood',
        models    = { 'prop_vend_fags_01' },
        animation = 'knob_pull',
        icon      = 'fa-solid fa-smoking',
        payment   = { cash = true, bank = false },   -- old machine, coins only
        items = {
            { name = 'redwood',     label = 'Redwood',      price = 9,  kind = 'pack', color = '#b3001b', accent = '#ffffff', prop = 'pack' },
            { name = 'redwood_gold',label = 'Redwood Gold', price = 11, kind = 'pack', color = '#c9a227', accent = '#2b1a00', prop = 'pack' },
            { name = 'debonaire',   label = 'Debonaire',    price = 10, kind = 'pack', color = '#13315c', accent = '#e0e1dd', prop = 'pack' },
            { name = 'cardiaque',   label = 'Cardiaque',    price = 10, kind = 'pack', color = '#1b4332', accent = '#d8f3dc', prop = 'pack' },
            { name = 'lighter',     label = 'Lighter',      price = 2,  kind = 'pack', color = '#f77f00', accent = '#003049', prop = 'pack' },
        },
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
--  Extra placements
--  Spawn additional machine props anywhere on the map. They work exactly like
--  the map's own machines. `machine` is a key from Config.Machines; `model` is
--  optional and defaults to the first model of that machine.
-- ─────────────────────────────────────────────────────────────────────────────

Config.Placements = {
    -- { machine = 'coffee', coords = vec4(-1199.61, -884.82, 12.81, 124.0) },
    -- { machine = 'snacks', coords = vec4(441.32, -979.64, 29.69, 180.0), model = 'prop_vend_snak_01_tu' },
}
