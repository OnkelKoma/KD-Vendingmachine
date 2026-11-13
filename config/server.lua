--[[
    kd-vendingmachine · server configuration
    This file is NEVER sent to clients. Safe place for webhooks & security settings.
]]

ServerConfig = {}

--- Maximum distance (metres) between the player and the machine coordinates sent by the client.
--- Purchases further away than this are rejected and logged as suspicious.
ServerConfig.MaxDistance = 4.0

--- Discord webhook for purchase / exploit logs. Leave empty to disable.
ServerConfig.Webhook = ''

ServerConfig.Log = {
    purchases  = true,   -- log every purchase to the webhook
    suspicious = true,   -- log rejected requests (distance, invalid items, spam)
    console    = false,  -- also print purchases to the server console
}

--- Ace permission required for /restockvending  (add_ace group.admin kdvending.admin allow)
ServerConfig.AdminAce = 'kdvending.admin'
