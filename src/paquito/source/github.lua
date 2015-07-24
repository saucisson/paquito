local Copas = require "copas"
local Http  = require "copas.http"
local Url   = require "socket.url"
local Ltn12 = require "ltn12"
local Mime  = require "mime"
local Json  = require "cjson"

return function (configuration, url)
  local t = assert (Url.parse (url))
  local function request (path)
    local hidden = {}
    local result = {}
    Copas.addthread (function ()
      local received  = {}
      local _, status = Http.request {
        method  = "GET",
        url     = "https://api.github.com/" .. path,
        headers = {
          Accept        = "application/vnd.github.drax-preview+json",
          Authorization = "token " .. configuration.github_token,
        },
        sink    = Ltn12.sink.table (received),
      }
      local index
      if status == 200 then
        index = Json.decode (table.concat (received))
      else
        index = {}
      end
      setmetatable (result, {
        __index = index,
        __len   = function  () return #index         end,
        __pairs = function  () return  pairs (index) end,
        __ipairs = function () return ipairs (index) end,
      })
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
  if t.host and t.host:match "github%.com" then
    local result = {}
    local path   = {}
    for part in t.path:gmatch "[^/]+" do
      local w = part:find "%.git$"
      if w then
        part = part:sub (1, w-1)
      end
      path [#path+1] = part
    end
    t.path = path
    assert (#t.path >= 2)
    local userinfo    = request ("/users/{{{user}}}" % {
      user = t.path [1],
    })
    local projectinfo = request ("/repos/{{{user}}}/{{{project}}}" % {
      user    = t.path [1],
      project = t.path [2],
    })
    local readmeinfo = request ("/repos/{{{user}}}/{{{project}}}/readme" % {
      user    = t.path [1],
      project = t.path [2],
    })
    local contributorsinfo = request ("/repos/{{{user}}}/{{{project}}}/contributors" % {
      user    = t.path [1],
      project = t.path [2],
    })
    result.maintainer = userinfo.name
    if userinfo.email and userinfo.email ~= "" then
      result.maintainer = result.maintainer .. " <{{{email}}}>" % {
        email = userinfo.email,
      }
    end
    result.name        = projectinfo.name
    result.version     = "master"
    result.summary     = projectinfo.description
    result.description = readmeinfo.content and Mime.unb64 (readmeinfo.content)
    result.license     = projectinfo.license and projectinfo.license.name
    result.homepage    = type (projectinfo.homepage) == "string"
                     and projectinfo.homepage
                      or "https://github.com/{{{user}}}/{{{project}}}" % {
                           user    = t.path [1],
                           project = t.path [2],
                         }
    result.authors     = {}
    local infos        = {}
    for i = 1, #contributorsinfo do
      infos [i] = request ("/users/{{{user}}}" % {
        user = contributorsinfo [i].login,
      })
    end
    for i = 1, #infos do
      local info = infos [i]
      if type (info.name) == "string" then
        result.authors [#result.authors+1] = info.name
      end
      if info.email and type (info.email) == "string" and info.email ~= "" then
        result.authors [#result.authors] = result.authors [#result.authors] .. " <{{{email}}}>" % {
          email = info.email,
        }
      end
    end
    return result
  end
end
