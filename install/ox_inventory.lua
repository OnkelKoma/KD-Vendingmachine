--[[
    kd-vendingmachine · ox_inventory items
    Paste into ox_inventory/data/items.lua (inside the return { ... } table).
    Skip any item you already have (ox_inventory ships with 'water' by default).
    Images: put <itemname>.png into ox_inventory/web/images/
]]

-- ── Drinks ──────────────────────────────────────────────────────────────────
['ecola'] = {
    label = 'eCola', weight = 350, stack = true, close = true,
    description = 'Deliciously infectious.',
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ecola_can`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500, notification = 'You quenched your thirst with an eCola' },
},
['ecola_light'] = {
    label = 'eCola Light', weight = 350, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ecola_can`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['ecola_cherry'] = {
    label = 'eCola Cherry', weight = 350, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ecola_can`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['sprunk'] = {
    label = 'Sprunk', weight = 350, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['sprunk_light'] = {
    label = 'Sprunk Light', weight = 350, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['sprunk_xtreme'] = {
    label = 'Sprunk Xtreme', weight = 350, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['orangotang'] = {
    label = 'Orang-O-Tang', weight = 350, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['junk_energy'] = {
    label = 'Junk Energy', weight = 350, stack = true, close = true,
    client = { status = { thirst = 150000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500 },
},
['water'] = {
    label = 'Water', weight = 500, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500, cancel = true },
},
['water_sparkling'] = {
    label = 'Sparkling Water', weight = 500, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500 },
},
['water_lemon'] = {
    label = 'Lemon Water', weight = 500, stack = true, close = true,
    client = { status = { thirst = 200000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500 },
},
['sports_drink'] = {
    label = 'Electrolyte+', weight = 500, stack = true, close = true,
    client = { status = { thirst = 250000 }, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500 },
},

-- ── Coffee ──────────────────────────────────────────────────────────────────
['coffee']     = { label = 'Black Coffee',  weight = 300, stack = true, close = true, client = { status = { thirst = 150000 }, anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }, usetime = 3000 } },
['espresso']   = { label = 'Espresso',      weight = 150, stack = true, close = true, client = { status = { thirst = 80000 },  anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }, usetime = 2000 } },
['cappuccino'] = { label = 'Cappuccino',    weight = 300, stack = true, close = true, client = { status = { thirst = 150000 }, anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }, usetime = 3000 } },
['latte']      = { label = 'Caffè Latte',   weight = 300, stack = true, close = true, client = { status = { thirst = 150000 }, anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }, usetime = 3000 } },
['hot_choco']  = { label = 'Hot Chocolate', weight = 300, stack = true, close = true, client = { status = { thirst = 150000, hunger = 50000 }, anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }, usetime = 3000 } },
['tea']        = { label = 'Green Tea',     weight = 300, stack = true, close = true, client = { status = { thirst = 150000 }, anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }, usetime = 3000 } },

-- ── Snacks ──────────────────────────────────────────────────────────────────
['egochaser']      = { label = 'EgoChaser',      weight = 80,  stack = true, close = true, client = { status = { hunger = 150000 }, anim = 'eating', prop = 'burger', usetime = 2500 } },
['meteorite']      = { label = 'Meteorite',      weight = 80,  stack = true, close = true, client = { status = { hunger = 150000 }, anim = 'eating', prop = 'burger', usetime = 2500 } },
['psqs']           = { label = "P's & Q's",      weight = 60,  stack = true, close = true, client = { status = { hunger = 80000 },  anim = 'eating', prop = 'burger', usetime = 2000 } },
['sweet_nothings'] = { label = 'Sweet Nothings', weight = 60,  stack = true, close = true, client = { status = { hunger = 80000 },  anim = 'eating', prop = 'burger', usetime = 2000 } },
['phat_chips']     = { label = 'Phat Chips',     weight = 120, stack = true, close = true, client = { status = { hunger = 180000 }, anim = 'eating', prop = 'burger', usetime = 3000 } },
['phat_chips_bbq'] = { label = 'Phat Chips BBQ', weight = 120, stack = true, close = true, client = { status = { hunger = 180000 }, anim = 'eating', prop = 'burger', usetime = 3000 } },
['big_cheese']     = { label = 'Big Cheese',     weight = 120, stack = true, close = true, client = { status = { hunger = 180000 }, anim = 'eating', prop = 'burger', usetime = 3000 } },
['sandwich']       = { label = 'Club Sandwich',  weight = 250, stack = true, close = true, client = { status = { hunger = 300000 }, anim = 'eating', prop = 'burger', usetime = 3500 } },

-- ── Tobacco ─────────────────────────────────────────────────────────────────
['redwood']      = { label = 'Redwood Cigarettes',      weight = 40, stack = true, close = true, description = 'Pack of 20.' },
['redwood_gold'] = { label = 'Redwood Gold Cigarettes', weight = 40, stack = true, close = true, description = 'Pack of 20.' },
['debonaire']    = { label = 'Debonaire Cigarettes',    weight = 40, stack = true, close = true, description = 'Pack of 20.' },
['cardiaque']    = { label = 'Cardiaque Cigarettes',    weight = 40, stack = true, close = true, description = 'Pack of 20.' },
['lighter']      = { label = 'Lighter',                 weight = 30, stack = true, close = true },
