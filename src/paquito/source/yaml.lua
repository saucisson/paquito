local Lfs  = require "lfs"
local Yaml = require "yaml"

return function (_, path)
  local filename = "{{{path}}}/paquito.yaml" % {
    path = path
  }
  if Lfs.attributes (filename, "mode") == "file" then
    return assert (Yaml.loadpath (filename))
  end
end
