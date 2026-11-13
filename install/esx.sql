-- kd-vendingmachine · ESX items
-- Run against your ESX database. Existing items are left untouched (INSERT IGNORE).
-- Using ox_inventory with ESX? Use install/ox_inventory.lua instead.

INSERT IGNORE INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    -- Drinks
    ('ecola',           'eCola',                   1, 0, 1),
    ('ecola_light',     'eCola Light',             1, 0, 1),
    ('ecola_cherry',    'eCola Cherry',            1, 0, 1),
    ('sprunk',          'Sprunk',                  1, 0, 1),
    ('sprunk_light',    'Sprunk Light',            1, 0, 1),
    ('sprunk_xtreme',   'Sprunk Xtreme',           1, 0, 1),
    ('orangotang',      'Orang-O-Tang',            1, 0, 1),
    ('junk_energy',     'Junk Energy',             1, 0, 1),
    ('water',           'Water',                   1, 0, 1),
    ('water_sparkling', 'Sparkling Water',         1, 0, 1),
    ('water_lemon',     'Lemon Water',             1, 0, 1),
    ('sports_drink',    'Electrolyte+',            1, 0, 1),
    -- Coffee
    ('coffee',          'Black Coffee',            1, 0, 1),
    ('espresso',        'Espresso',                1, 0, 1),
    ('cappuccino',      'Cappuccino',              1, 0, 1),
    ('latte',           'Caffè Latte',             1, 0, 1),
    ('hot_choco',       'Hot Chocolate',           1, 0, 1),
    ('tea',             'Green Tea',               1, 0, 1),
    -- Snacks
    ('egochaser',       'EgoChaser',               1, 0, 1),
    ('meteorite',       'Meteorite',               1, 0, 1),
    ('psqs',            'P''s & Q''s',             1, 0, 1),
    ('sweet_nothings',  'Sweet Nothings',          1, 0, 1),
    ('phat_chips',      'Phat Chips',              1, 0, 1),
    ('phat_chips_bbq',  'Phat Chips BBQ',          1, 0, 1),
    ('big_cheese',      'Big Cheese',              1, 0, 1),
    ('sandwich',        'Club Sandwich',           1, 0, 1),
    -- Tobacco
    ('redwood',         'Redwood Cigarettes',      1, 0, 1),
    ('redwood_gold',    'Redwood Gold Cigarettes', 1, 0, 1),
    ('debonaire',       'Debonaire Cigarettes',    1, 0, 1),
    ('cardiaque',       'Cardiaque Cigarettes',    1, 0, 1),
    ('lighter',         'Lighter',                 1, 0, 1);
