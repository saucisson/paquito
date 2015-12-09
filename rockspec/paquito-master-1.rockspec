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
  "argparse       >= 0",
  "coronest       >= 0",
  "dkjson         >= 2",
  "i18n           >= 0",
  "lua            >= 5.1",
  "luafilesystem  >= 1",
  "luasec         >= 0",
  "luasocket      >= 2",
  "lustache       >= 1",
  "Serpent        >= 0",
}

build = {
  type    = "builtin",
  modules = {
    ["paquito"] = "src/paquito.lua",
  },
}
