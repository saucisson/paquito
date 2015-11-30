local Argparse = require "argparse"
local Coronest = require "coroutine.make"
local File     = require "paquito.file"
local I18n     = require "i18n"
local Lustache = require "lustache"
local Serpent  = require "serpent"

_G.coroutine = Coronest ()

do
  local Metatable = getmetatable ""
  Metatable.__mod = function (pattern, variables)
    return Lustache:render (pattern, variables)
  end
end

local function show (t)
  return Serpent.line (t, {
    comment  = false,
    compact  = false,
    fatal    = true,
    indent   = "  ",
    sortkeys = true,
    sparse   = false,
  })
end

local locale = (os.getenv "LANG" or "en")
             : match "[^%.]+"
             : gsub ("_", "-")

do
  I18n.load (require "paquito.i18n.en")
  local ok, translation = pcall (require, "paquito.i18n.{{{locale}}}" % {
    locale = locale,
  })
  if ok then
    I18n.load (translation)
  end
end

local parser   = Argparse () {
  name        = "paquito",
  description = I18n "paquito:description",
}
parser:require_command (true)
parser:option "-l" "--locale" {
  description = I18n "paquito:option:locale",
  default     = locale,
}
parser:mutex (
  parser:flag "-q" "--quiet" {
    description = I18n "paquito:flag:quiet",
  },
  parser:flag "-v" "--verbose" {
    description = I18n "paquito:flag:verbose",
  }
)
parser:option "-p" "--path" {
  description = I18n "paquito:option:path",
  default     = os.getenv "PWD",
}

local state = {
  configuration = File.decode (os.getenv "HOME" .. "/.paquito.conf")
               or {},
  data          = nil,
}

local modules = {
  require "paquito.command.default" (state),
  require "paquito.command.load"    (state),
--  require "paquito.command.build"   (),
--  require "paquito.command.install" (),
--  require "paquito.command.run"     (),
}

for i = 1, #modules do
  modules [i] (parser)
end

state.arguments = parser:parse (_G.arg)
print ("arguments", show (state.arguments))

print ("state", show (state))
for i = 1, #modules do
  modules [i] (state.arguments)
end
print ("state", show (state))
