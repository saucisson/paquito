local Http  = require "socket.http"
local Https = require "ssl.https"

return {
  request = function (x, ...)
    if type (x) == "string" then
      if x:match "^http://" then
        return Http.request (x, ...)
      elseif x:match "https://" then
        return Https.request (x, ...)
      end
    elseif type (x) == "table" then
      if x.url:match "^http://" then
        return Http.request (x, ...)
      elseif x.url:match "https://" then
        return Https.request (x, ...)
      end
    end
    return Http.request (x, ...)
  end
}
