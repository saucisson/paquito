#! /usr/bin/env lua5.2

local Cli           = require "cliargs"
Cli:set_name (_G.arg [0])
Cli:optarg ("project", "url or path", os.getenv "PWD", 1)
local arguments = Cli:parse (_G.arg)
if not arguments then
  os.exit (1)
end

_G.coroutine        = require "coroutine.make" ()
local Copas         = require "copas"
--local Colors        = require "ansicolors"
--local I18n          = require "i18n"
local Lfs           = require "lfs"
--local Logging       = require "logging"
local Lustache      = require "lustache"
local Yaml          = require "yaml"

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

local Configuration = require "layeredata.make" ()
local Project       = require "layeredata.make" ()

Copas.addthread (function ()
  -- # Read configuration files:
  local configuration
  do
    local configurations = {}
    for _, filename in ipairs {
      "/etc/paquito/configuration.yaml",
      os.getenv "HOME" .. "/.paquito/configuration.yaml",
      os.getenv "PWD"  .. "/.paquito/configuration.yaml",
    } do
      if Lfs.attributes (filename, "mode") == "file" then
        local yaml = assert (Yaml.loadpath (filename))
        configurations [#configurations+1] = Configuration.new {
          name = filename,
          data = yaml,
        }
      end
    end
    local refines = {}
    for i = 1, #configurations do
      refines [i] = configurations [i]
    end
    configuration = Configuration.new {
      name = "*whole*",
      data = {
        __refines__ = refines,
      }
    }
  end

  if not configuration.modules then
    configuration.modules = {}
  end
  if not configuration.modules.source then
    configuration.modules.source = {}
  end
  if not configuration.modules.build then
    configuration.modules.build = {}
  end
  if not configuration.modules.target then
    configuration.modules.target = {}
  end

  do
    local normalize = require "paquito.normalize"
    local check     = require "paquito.check"
    local projects  = {}
    for _, name in Configuration.ipairs (configuration.modules.source) do
      local module  = require (name)
      local data    = module (configuration, arguments.project)
      if data then
        local project = Project.new {
          name = name,
          data = normalize (data)
        }
        projects [#projects+1] = project
      end
    end
    local refines = {}
    for i = 1, #projects do
      refines [i] = projects [i]
    end
    local project = Project.new {
      name = "*whole*",
      data = {
        __refines__ = refines,
      }
    }
    project = check (project)
    print (Yaml.dump (Project.export (Project.flatten (project))))
  end
end)

Copas.loop ()
