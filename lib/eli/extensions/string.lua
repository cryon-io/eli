---#DES string.trim
---
---@param s string
---@return string
local function _trim(s)
    if type(s) ~= 'string' then return s end
    return s:match "^()%s*$" and "" or s:match "^%s*(.*%S)"
end

---#DES string.split
---
---@param s string
---@param sep string
---@param trim boolean
---@return string[]
local function _split(s, sep, trim)
    if type(s) ~= 'string' then return s end
    if sep == nil then
        sep = "%s"
    end
    local _result = {}
    for str in string.gmatch(s, "([^" .. sep .. "]+)") do
        if trim then
            str = _trim(str)
        end
        table.insert(_result, str)
    end
    return _result
end

---#DES string.join
---
---@param separator string
---@vararg string
---@return string
local function _join(separator, ...)
    local _result = ""
    if type(separator) ~= "string" then
        separator = ""
    end
    for _, v in ipairs(table.pack(...)) do
        if #_result == 0 then
            _result = v
        else
            _result = _result .. separator .. v
        end
    end
    return _result
end

---#DES string.join_strings
---
---joins only strings, ignoring other values
---@param separator string
---@vararg string
---@return string
local function _join_strings(separator, ...)
    local _tmp = {}
    for _, v in ipairs(table.pack(...)) do
        if type(v) == "string" then
            table.insert(_tmp, v)
        end
    end
    return _join(separator, table.unpack(_tmp))
end

local function _globalize()
    string.split = _split
    string.join = _join
    string.join_strings = _join_strings
    string.trim = _trim
end

return {
    globalize = _globalize,
    split = _split,
    join = _join,
    join_strings = _join_strings,
    trim = _trim
}
