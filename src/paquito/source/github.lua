local Https = require "ssl.https"
local Json  = require "dkjson"
local Ltn12 = require "ltn12"
local Mime  = require "mime"
local Url   = require "socket.url"

local function execute (command)
  local handle = io.popen (command)
  local result = handle:read "*a"
  handle:close ()
  return result
end

return function (state)
  local data          = state.data
  local configuration = state.configuration
  if not data
  or not data.source then
    return
  end
  local function request (path)
    local received  = {}
    local _, status = Https.request {
      method  = "GET",
      url     = "https://api.github.com" .. path,
      headers = {
        Accept        = "application/vnd.github.drax-preview+json",
        Authorization = "token " .. configuration.github_token,
      },
      sink = Ltn12.sink.table (received),
    }
    if status >= 200 and status < 400 then
      assert (#received > 0)
      return Json.decode (table.concat (received))
    end
  end
  local t = assert (Url.parse (data.source))
  if t.host and t.host:match "github%.com" then
    local path = {}
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
    data.maintainer = data.maintainer
                   or "{{{name}}} <{{{email}}}>" % {
                        name  = userinfo.name,
                        email = userinfo.email
                             or "no email",
                      }
    data.name        = data.name
                    or projectinfo.name
    data.version     = data.version
                    or execute ([[cd {{{path}}} && git describe --all]] % {
                         path = state.arguments.path
                       }):match "%S+"
    data.summary     = data.summary
                    or projectinfo.description
    data.description = data.description
                    or readmeinfo.content and Mime.unb64 (readmeinfo.content)
    data.license     = data.license
                    or projectinfo.license and projectinfo.license.name
    data.homepage    = type (projectinfo.homepage) == "string"
                   and projectinfo.homepage
                    or "https://github.com/{{{user}}}/{{{project}}}" % {
                         user    = t.path [1],
                         project = t.path [2],
                       }
    if not data.authors then
      data.authors = {}
      local infos  = {}
      for i = 1, #contributorsinfo do
        infos [i] = request ("/users/{{{user}}}" % {
          user = contributorsinfo [i].login,
        })
      end
      for i = 1, #infos do
        local info = infos [i]
        if type (info.name) == "string" then
          data.authors [#data.authors+1] = "{{{name}}} <{{{email}}}>" % {
            name  = info.name,
            email = info.email
                 or "no email",
          }
        end
      end
    end
  end
end
