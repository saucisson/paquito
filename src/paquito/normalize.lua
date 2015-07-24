return function (main)

  local function for_dependencies (t)
    local removed = {}
    for key, dependency in pairs (t) do
      if type (key) ~= "number" then
        t [#t+1] = dependency
        if type (dependency) == "table" and not dependency.default then
          dependency.default = key
        end
        removed [#removed+1] = key
      end
    end
    for i = 1, #removed do
      t [removed [i]] = nil
    end
    for i = 1, #t do
      local dependency = t [i]
      if type (dependency) == "string" then
        t [i] = {
          default = t [i].default
        }
        for target in pairs (main.configuration.targets) do
          t [i] [target] = dependency
        end
      end
    end
    for i = 1, #t do
      for target in pairs (main.configuration.targets) do
        t [i] [target] = t [i] [target]
                      or t [i].default
      end
    end
    for i = 1, #t do
      for target, dependency in pairs (t [i]) do
        if target ~= "default" and type (dependency) == "string" then
          t [i] [target] = {
            default = t [i].default
          }
          for version in pairs (main.configuration.targets [target]) do
            t [i] [target] [version] = dependency
          end
        elseif target ~= "default" and type (dependency) == "table" then
          dependency.default = t [i].default
        end
      end
    end
    for i = 1, #t do
      for target in pairs (t [i]) do
        if target ~= "default" then
          for version in pairs (main.configuration.targets [target]) do
            t [i] [target] [version] = t [i] [target] [version]
                                    or t [i].default
          end
        end
      end
    end
    for i = 1, #t do
      t [i].default = nil
      for _, _version in pairs (t [i]) do
        _version.default = nil
      end
    end
    for i = 1, #t do
      for target, _version in pairs (t [i]) do
        if target ~= "default" then
          for version, dependency in pairs (_version) do
            if version ~= "default" and type (dependency) == "string" then
              t [i] [target] [version] = {
                dependency,
              }
            end
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
    dep1: target:
          default: dep1
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
