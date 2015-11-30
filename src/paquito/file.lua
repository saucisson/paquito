local Serpent = require "serpent"
local File    = {}

function File.decode (filename)
  local file, err = io.open (filename, "r")
  if not file then
    return nil, err
  end
  local contents = file:read "*all"
  file:close ()
  local ok, result = Serpent.load (contents)
  if not ok then
    return nil, result
  end
  return result
end

function File.encode (filename, t)
  local result = Serpent.dump (t, {
    comment  = false,
    compact  = false,
    fatal    = true,
    indent   = "  ",
    sortkeys = true,
    sparse   = false,
  })
  local file, err = io.open (filename, "w")
  if not file then
    error (err)
  end
  file:write (result .. "\n")
  file:close ()
end

return File
