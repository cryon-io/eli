-- conforms to semver 2.0
local generate_safe_functions = require"eli.util".generate_safe_functions

---#DES 'ver.parse'
---
---Parses version string and returns table with major, minor, path, prerelease 
---and metadata values
---@param ver string
---@return table
local function _parse_semver(ver)
    if type(ver) ~= "string" then
        return nil
    end
    local _metadata = ver:match(".+%+(.+)")
    if (_metadata ~= nil) then
        ver = ver:sub(1, #ver - #_metadata - 1)
    end
    local _prerelease = ver:match(".+-([^%+]+)")
    if (_prerelease ~= nil) then
        ver = ver:sub(1, #ver - #_prerelease - 1)
    end

    local _major = tonumber(ver:match("[^%.]+"))
    local _minor = tonumber(ver:match("[^%.]+.([^%.]+)"))
    local _patch = tonumber(ver:match("[^%.]+.[^%.]+.([^-]+)"))

    return {
        major = _major,
        minor = _minor,
        patch = _patch,
        prerelease = _prerelease,
        metadata = _metadata
    }
end

---#DES 'ver._compare_prerelase'
---@param p1 string
---@param p2 string
---@return integer
local function _compare_prerelase(p1, p2)
    if p1 == nil and p2 == nil then
        return 0
    elseif p1 == nil and p2 ~= nil then
        return 1
    elseif p2 == nil and p1 ~= nil then
        return -1
    end

    local _p1parts = {}
    for p in string.gmatch(p1, "[^%.]+") do
        table.insert(_p1parts, p)
    end

    local _p2parts = {}
    for p in string.gmatch(p2, "[^%.]+") do
        table.insert(_p2parts, p)
    end

    local _range = #_p1parts > #_p2parts and #_p2parts or #_p1parts

    for i = 1, _range do
        local _subp1 = _p1parts[i]
        local _subp2 = _p2parts[i]

        local _p1Number = tonumber(_subp1)
        local _p2Number = tonumber(_subp2)

        if _p1Number and _p2Number then
            if _p1Number ~= _p2Number then
                return _p1Number > _p2Number and 1 or -1
            end
        elseif _p1Number and not _p2Number then
            return -1
        elseif not _p1Number and _p2Number then
            return 1
        else -- string comparison
            local _srange = #_subp1 > #_subp2 and #_subp2 or #_subp1
            for j = 1, _srange do
                if _subp1:sub(j, j) ~= _subp2:sub(j, j) then
                    return _subp1:sub(j, j) > _subp2:sub(j, j) and 1 or -1
                end
            end
            if #_subp1 ~= #_subp2 then
                return _srange == #_subp1 and -1 or 1
            end
        end
    end
    if #_p1parts == #_p2parts then
        return 0
    end
    return _range == #_p1parts and -1 or 1
end

---#DES 'ver.compare'
---
---If the semver v1 is newer than v2, returns 1. If the semver v2 is newer than v1,
---returns -1. If v1 equals v2, returns 0;
---@param v1 string
---@param v2 string
---@return integer
local function _compare_version(v1, v2)
    if type(v1) == "number" and type(v2) == "number" then
        if v1 > v2 then
            return 1
        elseif v1 < v2 then
            return -1
        end
    end

    local _v1
    if type(v1) == "string" then
        _v1 = _parse_semver(v1)
    end
    local _v2
    if type(v2) == "string" then
        _v2 = _parse_semver(v2)
    end
    assert(type(_v1) == "table", "Invalid v1 version!")
    assert(type(_v2) == "table", "Invalid v2 version!")

    if _v1.major ~= _v2.major then
        return _v1.major > _v2.major and 1 or -1
    end

    if _v1.minor ~= _v2.minor then
        return _v1.minor > _v2.minor and 1 or -1
    end

    if _v1.patch ~= _v2.patch then
        return _v1.patch > _v2.patch and 1 or -1
    end

    return _compare_prerelase(_v1.prerelease, _v2.prerelease)
end

---#DES 'ver.parse_semver'
---@deprecated
---Parses version string and returns table with major, minor, path, prerelease 
---and metadata values
---@param ver string
---@return table
local function _parse_semver_old(...) _parse_semver(...) end

---#DES 'ver.compare_version'
---@deprecated
---If the semver v1 is newer than v2, returns 1. If the semver v2 is newer than v1,
---returns -1. If v1 equals v2, returns 0;
---@param v1 string
---@param v2 string
---@return integer
local function _compare_version_old(...) _compare_version(...) end

return generate_safe_functions({
    -- deprecated
    parse_semver = _parse_semver_old,
    compare_version = _compare_version_old,
    -- new
    parse = _parse_semver,
    compare = _compare_version
})