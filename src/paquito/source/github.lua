local Http  = require "paquito.http"
local Url   = require "socket.url"
local Mime  = require "mime"
local Json  = require "cjson"

return function (main)
  if not main.project.source then
    return
  end
  local function request (path)
    local result = Http.request {
      method  = "GET",
      url     = "https://api.github.com/" .. path,
      headers = {
        Accept        = "application/vnd.github.drax-preview+json",
        Authorization = "token " .. main.configuration.github_token,
      },
    }
    assert (#result > 0)
    return Json.decode (table.concat (result))
  end
  local t = assert (Url.parse (main.project.source))
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
