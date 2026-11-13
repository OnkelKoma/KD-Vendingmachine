Locales = Locales or {}

local function lookup(lang, key)
    local t = Locales[lang]
    if not t then return nil end
    for part in key:gmatch('[^%.]+') do
        if type(t) ~= 'table' then return nil end
        t = t[part]
    end
    return t
end

--- Translate a key ('purchase.success' style paths are supported). Falls back to English.
---@param key string
---@return string
function _L(key, ...)
    local str = lookup(Config.Locale, key) or lookup('en', key) or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

--- Returns the UI string table for the current locale, merged on top of English.
---@return table<string, string>
function GetUILocale()
    local out = {}
    for k, v in pairs((Locales.en and Locales.en.ui) or {}) do out[k] = v end
    for k, v in pairs((Locales[Config.Locale] and Locales[Config.Locale].ui) or {}) do out[k] = v end
    return out
end
