local I18n = require "i18n"
local File = require "paquito.file"

return function (state)
  local result = coroutine.wrap (function ()
    local parser = coroutine.yield ()
    parser:command "load" {
      description = I18n "paquito:command:load",
    }
    local arguments = coroutine.yield ()
    if not arguments.load then
      return
    end
    state.data = File.decode (arguments.path .. "/paquito.conf")
    require "paquito.source.github" (state)
  end)
  result () -- initialize
  return result
end
