#! /usr/bin/env lua5.2

local Cli           = require "cliargs"
Cli:set_name (_G.arg [0])
Cli:optarg ("project", "url or path", os.getenv "PWD", 1)
local arguments = Cli:parse (_G.arg)
if not arguments then
  os.exit (1)
end

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
end

-- 2. Load modules:
local modules = {}
do
  for _, modulename in ipairs (configuration.modules or {}) do
    modules [modulename] = require (modulename)
  end
end

-- 3. Initialize project:
local project
do
  local normalize = require "paquito.normalize"
  local check     = require "paquito.check"
  local projects  = {}
  for name, module in pairs (modules) do
    projects [#projects+1] = Project.new {
      name = name,
      data = normalize (module (configuration, arguments.project))
    }
  end
  local refines = {}
  for i = 1, #projects do
    refines [i] = projects [i]
  end
  project = Project.new {
    name = "*whole*",
    data = {
      __refines__ = refines,
    }
  }
  project = check (project)
end

print (Yaml.dump (Project.export (Project.flatten (project))))
