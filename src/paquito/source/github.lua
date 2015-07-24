local Url   = require "socket.url"
local Https = require "ssl.https"
local Ltn12 = require "ltn12"
local Mime  = require "mime"
local Json  = require "cjson"

return function (configuration, url)
  local t = assert (Url.parse (url))
  local function request (path)
    local result = {}
    local _, status = Https.request {
      method  = "GET",
      url     = "https://api.github.com/" .. path,
      headers = {
        Accept        = "application/vnd.github.drax-preview+json",
        Authorization = "token " .. configuration.github_token,
      },
      sink    = Ltn12.sink.table (result),
    }
    assert (status == 200)
    return assert (Json.decode (table.concat (result)))
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
    result.maintainer = userinfo.name
    if userinfo.email and userinfo.email ~= "" then
      result.maintainer = result.maintainer .. " <{{{email}}}>" % {
        email = userinfo.email,
      }
    end
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
    for i = 1, #contributorsinfo do
      local info = request ("/users/{{{user}}}" % {
        user = contributorsinfo [i].login,
      })
      result.authors [#result.authors+1] = info.name
    end
    return result
  end
end
