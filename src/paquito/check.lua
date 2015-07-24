local Http  = require "copas.http"

return function (main)
  assert (type (main.project) == "table")
  for _, name in ipairs {
    "description",
    "name",
    "homepage",
    "license",
    "maintainer",
    "summary",
    "version",
  } do
    assert (main.project [name])
    assert (type (main.project [name]) == "string")
  end
  for _, name in ipairs {
    "name",
    "homepage",
    "license",
    "maintainer",
    "version",
  } do
    assert (main.project [name] ~= "")
  end
  assert (type (main.project.authors) == "table")
  for _, author in ipairs (main.project.authors) do
    assert (type (author) == "string")
    assert (author ~= "")
  end
  if main.project.homepage then
    local _, status = Http.request (main.project.homepage)
    assert (status >= 200 and status < 400)
  end
  if main.project.source then
    local _, status = Http.request (main.project.homepage)
    assert (status >= 200 and status < 400)
  end
  return main
end
