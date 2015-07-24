package = "paquito"
version = "master-1"

source = {
  url = "git://github.com/saucisson/paquito",
}

description = {
  summary     = "Paquito",
  detailed    = [[]],
  license     = "MIT/X11",
  maintainer  = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "ansicolors     >= 1",
  "c3             >= 0",
  "copas          >= 2",
  "coronest       >= 0",
  "i18n           >= 0",
  "layeredata     >= 0",
  "lua            >= 5.2",
  "lua_cliargs    >= 2.5",
  "lua-cjson      >= 2.1",
  "luafilesystem  >= 1",
  "lualogging     >= 1",
  "luasec         >= 0",
  "luasocket      >= 2",
  "lustache       >= 1",
  "yaml           >= 1",
}

build = {
  type    = "builtin",
  modules = {
    ["paquito"] = "src/paquito.lua",
  },
}
