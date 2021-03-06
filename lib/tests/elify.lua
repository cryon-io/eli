local _test = TEST or require "u-test"
local _eliUtil = require"eli.util"

_test["is_elified"] = function()
    _test.assert(require"eli.elify".is_elified() == true)
end

_test["cli"] = function()
    _test.assert(cli == require("eli.cli"))
end

_test["env"] = function()
    _test.assert(env == require("eli.env"))
end

_test["fs"] = function()
    _test.assert(fs == require("eli.fs"))
end

_test["hash"] = function()
    _test.assert(hash == require("eli.hash"))
end

_test["net"] = function()
    _test.assert(net == require("eli.net"))
end

_test["proc"] = function()
    _test.assert(proc == require("eli.proc"))
end

_test["util"] = function()
    _test.assert(util == require("eli.util"))
end

_test["ver"] = function()
    _test.assert(ver == require("eli.ver"))
end

_test["zip"] = function()
    _test.assert(zip == require("eli.zip"))
end

_test["os"] = function()
    local _eliOs = require("eli.os")
    _test.assert(os ~= _eliOs)
    for k, v in pairs(_eliOs) do
        _test.assert(os[k] == v)
    end
end

_test["type"] = function()
    _test.assert(type("string") == "string")
    _test.assert(type(true) == "boolean")
    _test.assert(type(nil) == "nil")
    _test.assert(type(0) == "number")
    _test.assert(type({}) == "table")
    local _t = { __type = "test" }
    setmetatable(_t, _t)
    _test.assert(type(_t) == "test")
end

_test["get_overriden_values"] = function()
    local _overriden = require"eli.elify".get_overriden_values()
    _test.assert(_overriden.os == require"os")
    _test.assert(_overriden.type ~= type)
end

_test["extensions.string"] = function()
    local _esx = require("eli.extensions.string")
    for k, v in pairs(_esx) do
        if k ~= "globalize" then
            _test.assert(string[k] == v)
        end
    end
end

_test["extensions.table"] = function()
    local _etx = require("eli.extensions.table")
    for k, v in pairs(_etx) do
        if k ~= "globalize" then
            _test.assert(table[k] == v)
        end
    end
end

if not TEST then
    _test.summary()
end
