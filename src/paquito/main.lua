--local Colors        = require "ansicolors"
--local I18n          = require "i18n"
local Lfs           = require "lfs"
--local Logging       = require "logging"
local Yaml          = require "yaml"
local Configuration = require "layeredata.make" ()
local Project       = require "layeredata.make" ()

local Main = {}

Main.__index   = Main
Main.normalize = require "paquito.normalize"
Main.check     = require "paquito.check"

function Main.new ()
  return setmetatable ({}, Main)
end

function Main.__call (main, arguments)
  -- # Read configuration files:
  do
    local configurations = {}
    configurations [1] = Configuration.new {
      name = "*default*",
      data = {
        project = {},
        modules = {
          source = {},
          build  = {},
          target = {},
        },
        targets = {},
      },
    }
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
    main.configuration = Configuration.new {
      name = "*whole*",
      data = {
        __refines__ = refines,
      }
    }
  end

  do
    main.project = Project.new {
      name = "*paquito.yaml*",
      data = assert (Yaml.loadpath ("{{{path}}}/paquito.yaml" % {
        path = arguments.project
      })),
    }
    local projects = {
      main.project,
    }
    for _, name in Configuration.ipairs (main.configuration.modules.source) do
      local module  = require (name)
      local data    = module (main)
      if data then
        projects [#projects+1] = Project.new {
          name = name,
          data = data,
        }
      end
    end
    local refines = {}
    for i = 1, #projects do
      refines [i] = projects [i]
    end
    main.project = Project.new {
      name = "*whole*",
      data = {
        __refines__ = refines,
      }
    }
    main:normalize ()
        :check ()
    print (Yaml.dump (Project.export (Project.flatten (main.project, { compact = true }))))
  end
end

return Main
