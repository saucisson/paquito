local Copas = require "copas"
local Http  = require "copas.http"
local Ltn12 = require "ltn12"

local function request (t)
  local hidden = {}
  local result = {}
  Copas.addthread (function ()
    if type (t) == "string" then
      t = {
        method  = "GET",
        url     = t,
      }
    end
    local received  = {}
    t.sink = Ltn12.sink.table (received)
    local _, status = Http.request (t)
    if status >= 200 and status < 400 then
      for k, v in pairs (received) do
        result [k] = v
      end
    end
    setmetatable (result, nil)
    Copas.wakeup (hidden.co)
  end)
  return setmetatable (result, {
    __index = function (_, key)
        hidden.co = coroutine.running ()
        Copas.sleep (-math.huge)
        return result [key]
      end,
    __len   = function ()
      hidden.co = coroutine.running ()
      Copas.sleep (-math.huge)
      return #result
    end,
    __pairs = function ()
      hidden.co = coroutine.running ()
      Copas.sleep (-math.huge)
      return pairs (result)
    end,
    __ipairs = function ()
      hidden.co = coroutine.running ()
      Copas.sleep (-math.huge)
      return ipairs (result)
    end,
  })
end

return {
  request = request,
}
