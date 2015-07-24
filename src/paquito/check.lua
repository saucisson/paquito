local Http  = require "copas.http"

return function (project)
  assert (type (project) == "table")
  for _, name in ipairs {
    "description",
    "name",
    "homepage",
    "license",
    "maintainer",
    "summary",
    "version",
  } do
    assert (project [name])
    assert (type (project [name]) == "string")
  end
  for _, name in ipairs {
    "name",
    "homepage",
    "license",
    "maintainer",
    "version",
  } do
    assert (project [name] ~= "")
  end
  assert (type (project.authors) == "table")
  for _, author in ipairs (project.authors) do
    assert (type (author) == "string")
    assert (author ~= "")
  end
  if project.homepage then
    local _, status = Http.request (project.homepage)
    assert (status >= 200 and status < 400)
  end
  return project
end
