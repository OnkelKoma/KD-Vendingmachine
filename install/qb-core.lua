--[[
    kd-vendingmachine · QBCore items
    Paste into qb-core/shared/items.lua (inside QBShared.Items = { ... }).
    Skip any item you already have (QBCore ships with 'coffee', 'sandwich' and 'lighter').
    Images: put <itemname>.png into qb-inventory/html/images/

    To make them consumable, add them to qb-smallresources/config.lua:
        Config.Consumables.drink = { ['ecola'] = math.random(35, 54), ... }
        Config.Consumables.eat   = { ['egochaser'] = math.random(35, 54), ... }
]]

-- Drinks
ecola           = { name = 'ecola',           label = 'eCola',           weight = 350, type = 'item', image = 'ecola.png',           unique = false, useable = true, shouldClose = true, description = 'Deliciously infectious.' },
ecola_light     = { name = 'ecola_light',     label = 'eCola Light',     weight = 350, type = 'item', image = 'ecola_light.png',     unique = false, useable = true, shouldClose = true, description = 'All the infection, none of the sugar.' },
ecola_cherry    = { name = 'ecola_cherry',    label = 'eCola Cherry',    weight = 350, type = 'item', image = 'ecola_cherry.png',    unique = false, useable = true, shouldClose = true, description = 'Cherry flavoured eCola.' },
sprunk          = { name = 'sprunk',          label = 'Sprunk',          weight = 350, type = 'item', image = 'sprunk.png',          unique = false, useable = true, shouldClose = true, description = 'The essence of life.' },
sprunk_light    = { name = 'sprunk_light',    label = 'Sprunk Light',    weight = 350, type = 'item', image = 'sprunk_light.png',    unique = false, useable = true, shouldClose = true, description = 'Sprunk, but light.' },
sprunk_xtreme   = { name = 'sprunk_xtreme',   label = 'Sprunk Xtreme',   weight = 350, type = 'item', image = 'sprunk_xtreme.png',   unique = false, useable = true, shouldClose = true, description = 'Extra everything.' },
orangotang      = { name = 'orangotang',      label = 'Orang-O-Tang',    weight = 350, type = 'item', image = 'orangotang.png',      unique = false, useable = true, shouldClose = true, description = 'Orange soda.' },
junk_energy     = { name = 'junk_energy',     label = 'Junk Energy',     weight = 350, type = 'item', image = 'junk_energy.png',     unique = false, useable = true, shouldClose = true, description = 'The quick fix.' },
water           = { name = 'water',           label = 'Water',           weight = 500, type = 'item', image = 'water.png',           unique = false, useable = true, shouldClose = true, description = 'Bottled water.' },
water_sparkling = { name = 'water_sparkling', label = 'Sparkling Water', weight = 500, type = 'item', image = 'water_sparkling.png', unique = false, useable = true, shouldClose = true, description = 'Bubbly.' },
water_lemon     = { name = 'water_lemon',     label = 'Lemon Water',     weight = 500, type = 'item', image = 'water_lemon.png',     unique = false, useable = true, shouldClose = true, description = 'A hint of lemon.' },
sports_drink    = { name = 'sports_drink',    label = 'Electrolyte+',    weight = 500, type = 'item', image = 'sports_drink.png',    unique = false, useable = true, shouldClose = true, description = 'Replaces what you sweat out.' },

-- Coffee
coffee          = { name = 'coffee',          label = 'Black Coffee',    weight = 300, type = 'item', image = 'coffee.png',          unique = false, useable = true, shouldClose = true, description = 'Hot and black.' },
espresso        = { name = 'espresso',        label = 'Espresso',        weight = 150, type = 'item', image = 'espresso.png',        unique = false, useable = true, shouldClose = true, description = 'Small but mighty.' },
cappuccino      = { name = 'cappuccino',      label = 'Cappuccino',      weight = 300, type = 'item', image = 'cappuccino.png',      unique = false, useable = true, shouldClose = true, description = 'Frothy.' },
latte           = { name = 'latte',           label = 'Caffè Latte',     weight = 300, type = 'item', image = 'latte.png',           unique = false, useable = true, shouldClose = true, description = 'Milky.' },
hot_choco       = { name = 'hot_choco',       label = 'Hot Chocolate',   weight = 300, type = 'item', image = 'hot_choco.png',       unique = false, useable = true, shouldClose = true, description = 'Sweet and warm.' },
tea             = { name = 'tea',             label = 'Green Tea',       weight = 300, type = 'item', image = 'tea.png',             unique = false, useable = true, shouldClose = true, description = 'Calming.' },

-- Snacks
egochaser       = { name = 'egochaser',       label = 'EgoChaser',       weight = 80,  type = 'item', image = 'egochaser.png',       unique = false, useable = true, shouldClose = true, description = 'Energy bar.' },
meteorite       = { name = 'meteorite',       label = 'Meteorite',       weight = 80,  type = 'item', image = 'meteorite.png',       unique = false, useable = true, shouldClose = true, description = 'Chocolate bar.' },
psqs            = { name = 'psqs',            label = "P's & Q's",       weight = 60,  type = 'item', image = 'psqs.png',            unique = false, useable = true, shouldClose = true, description = 'Candy.' },
sweet_nothings  = { name = 'sweet_nothings',  label = 'Sweet Nothings',  weight = 60,  type = 'item', image = 'sweet_nothings.png',  unique = false, useable = true, shouldClose = true, description = 'Candy.' },
phat_chips      = { name = 'phat_chips',      label = 'Phat Chips',      weight = 120, type = 'item', image = 'phat_chips.png',      unique = false, useable = true, shouldClose = true, description = 'Salted chips.' },
phat_chips_bbq  = { name = 'phat_chips_bbq',  label = 'Phat Chips BBQ',  weight = 120, type = 'item', image = 'phat_chips_bbq.png',  unique = false, useable = true, shouldClose = true, description = 'BBQ chips.' },
big_cheese      = { name = 'big_cheese',      label = 'Big Cheese',      weight = 120, type = 'item', image = 'big_cheese.png',      unique = false, useable = true, shouldClose = true, description = 'Cheese puffs.' },
sandwich        = { name = 'sandwich',        label = 'Club Sandwich',   weight = 250, type = 'item', image = 'sandwich.png',        unique = false, useable = true, shouldClose = true, description = 'Vending machine sandwich. Brave.' },

-- Tobacco
redwood         = { name = 'redwood',         label = 'Redwood Cigarettes',      weight = 40, type = 'item', image = 'redwood.png',      unique = false, useable = false, shouldClose = true, description = 'Pack of 20.' },
redwood_gold    = { name = 'redwood_gold',    label = 'Redwood Gold Cigarettes', weight = 40, type = 'item', image = 'redwood_gold.png', unique = false, useable = false, shouldClose = true, description = 'Pack of 20.' },
debonaire       = { name = 'debonaire',       label = 'Debonaire Cigarettes',    weight = 40, type = 'item', image = 'debonaire.png',    unique = false, useable = false, shouldClose = true, description = 'Pack of 20.' },
cardiaque       = { name = 'cardiaque',       label = 'Cardiaque Cigarettes',    weight = 40, type = 'item', image = 'cardiaque.png',    unique = false, useable = false, shouldClose = true, description = 'Pack of 20.' },
lighter         = { name = 'lighter',         label = 'Lighter',                 weight = 30, type = 'item', image = 'lighter.png',      unique = false, useable = false, shouldClose = true, description = 'Click.' },
