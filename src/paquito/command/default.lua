local I18n = require "i18n"
local File = require "paquito.file"

return function ()
  local result = coroutine.wrap (function ()
    local parser = coroutine.yield ()
    parser:command "default" {
      description = I18n "paquito:command:default",
    }
    local arguments = coroutine.yield ()
    if not arguments.default then
      return
    end
    File.encode (arguments.path .. "/paquito.conf", {
      source = "<url to your project>",
    })
  end)
  result () -- initialize
  return result
end
