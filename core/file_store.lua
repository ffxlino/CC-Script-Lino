local fileStore = {}

local function ensureDir(path)
  local parts = {}
  for part in string.gmatch(path, "[^/]+") do
    parts[#parts + 1] = part
  end
  if #parts <= 1 then
    return
  end

  local acc = ""
  for i = 1, #parts - 1 do
    acc = acc == "" and parts[i] or (acc .. "/" .. parts[i])
    if not fs.exists(acc) then
      fs.makeDir(acc)
    end
  end
end

function fileStore.writeJson(path, value)
  ensureDir(path)
  local h = fs.open(path, "w")
  if not h then
    return false, "unable to open file for write: " .. path
  end
  h.write(textutils.serializeJSON(value))
  h.close()
  return true
end

function fileStore.readJson(path, fallback)
  if not fs.exists(path) then
    return fallback
  end

  local h = fs.open(path, "r")
  if not h then
    return fallback
  end

  local raw = h.readAll()
  h.close()

  local ok, decoded = pcall(textutils.unserializeJSON, raw)
  if not ok or decoded == nil then
    return fallback
  end
  return decoded
end

function fileStore.writeLuaTable(path, value)
  ensureDir(path)
  local h = fs.open(path, "w")
  if not h then
    return false, "unable to open file for write: " .. path
  end
  h.write("return ")
  h.write(textutils.serialize(value))
  h.write("\n")
  h.close()
  return true
end

function fileStore.readLuaTable(path, fallback)
  if not fs.exists(path) then
    return fallback
  end
  local ok, result = pcall(dofile, path)
  if not ok or type(result) ~= "table" then
    return fallback
  end
  return result
end

return fileStore
