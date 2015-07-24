#! /usr/bin/env luajit

local Cli           = require "cliargs"
Cli:set_name (_G.arg [0])
Cli:optarg ("project", "url or path", os.getenv "PWD", 1)
local arguments = Cli:parse (_G.arg)
if not arguments then
  os.exit (1)
end

_G.coroutine        = require "coroutine.make" ()
local Copas         = require "copas"
local Lustache      = require "lustache"
local Yaml          = require "yaml"
local Main          = require "paquito.main"

Yaml.configure {
  load_nulls_as_nil = true,
  sort_table_keys   = true,
}

do
  local metatable = getmetatable ""
  metatable.__mod = function (pattern, variables)
    return Lustache:render (pattern, variables)
  end
  -- http://lua-users.org/wiki/StringTrim
  function _G.string.trim (s)
    return s:match "^()%s*$" and "" or s:match "^%s*(.*%S)"
  end
end

Copas.addthread (function ()
  local main = Main.new ()
  main (arguments)
end)

Copas.loop ()
