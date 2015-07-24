return function (main)

  local function for_dependencies (t)
    for i = 1, #t do
      local dependency = t [i]
      if type (dependency) == "string" then
        assert (not t [dependency])
        t [dependency] = dependency
      end
      t [i] = nil
    end
    for key, dependency in pairs (t) do
      if type (dependency) == "string" then
        t [key] = {}
        for target in pairs (main.configuration.targets) do
          t [key] [target] = dependency
        end
      end
    end
    for key, _target in pairs (t) do
      for target, dependency in pairs (_target) do
        if type (dependency) == "string" then
          t [key] [target] = {}
          for version in pairs (main.configuration.targets [target]) do
            t [key] [target] [version] = dependency
          end
        end
      end
    end
    for key, _target in pairs (t) do
      for target, _version in pairs (_target) do
        for version, dependency in pairs (_version) do
          if type (dependency) == "string" then
            t [key] [target] [version] = {
              dependency,
            }
          end
        end
      end
    end
  end

  local for_commands = for_dependencies

  local function for_files (t)
    for i = 1, #t do
      local pattern = t [i]
      if type (pattern) == "string" then
        assert (not t [pattern])
        t [pattern] = pattern
      end
      t [i] = nil
    end
  end

  local function for_build (t)
    if not t.dependencies then
      t.dependencies = {}
    end
    for_dependencies (t.dependencies)
    if not t.commands then
      t.commands = {}
    end
    for_commands (t.commands)
  end

  local function for_runtime (t)
    if not t.dependencies then
      t.dependencies = {}
    end
    for_dependencies (t.dependencies)
  end

  local function for_package (t)
    if not t.build then
      t.build = {}
    end
    for_build (t.build)
    if not t.runtime then
      t.runtime = {}
    end
    for_runtime (t.runtime)
    if not t.files then
      t.files = {}
    end
    for_files (t.files)
  end

  if main.project.authors then
    if type (main.project.authors) == "string" then
      main.project.authors = {
        main.project.authors,
      }
    else
      assert (type (main.project.authors) == "table")
    end
  end
  if main.project.version then
    main.project.version = tostring (main.project.version)
  end
  if main.project.packages then
    for _, v in pairs (main.project.packages) do
      for_package (v)
    end
  end
  for_package (main.project)
  return main
end

--[[
build:
  dependencies:
    - dep1 -> target: version: - package
    dep: package
    dep: target: package
    dep: target: version: package
  commands:
    - com1 -> target: version: - command
runtime:
  dependencies:
    - dep1
packages:
  name:
    type: <type>
    files:
      target: source
    build:
    runtine:
--]]
