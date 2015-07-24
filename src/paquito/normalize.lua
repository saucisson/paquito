return function (project)
  if not project then
    return
  end
  assert (type (project) == "table")
  if project.authors then
    if type (project.authors) == "string" then
      project.authors = {
        project.authors,
      }
    else
      assert (type (project.authors) == "table")
    end
  end
  if project.version then
    project.version = tostring (project.version)
  end
  return project
end
