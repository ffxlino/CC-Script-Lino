local adapter = {}

local function hasFn(p, name)
  return p and type(p[name]) == "function"
end

local function startsWith(value, prefix)
  return string.sub(value, 1, #prefix) == prefix
end

function adapter.detectCapabilities(wrapped)
  return {
    inventory = hasFn(wrapped, "list") or hasFn(wrapped, "size"),
    itemTransfer = hasFn(wrapped, "pushItems") or hasFn(wrapped, "pullItems"),
    fluids = hasFn(wrapped, "tanks") or hasFn(wrapped, "getTankInfo"),
    energy = hasFn(wrapped, "getEnergyStored") or hasFn(wrapped, "getMaxEnergyStored")
      or hasFn(wrapped, "getEnergy") or hasFn(wrapped, "getEnergyCapacity"),
    genericMeta = hasFn(wrapped, "getMetadata") or hasFn(wrapped, "getBlockData"),
    monitor = hasFn(wrapped, "setTextScale") and hasFn(wrapped, "getSize"),
    modem = hasFn(wrapped, "isWireless") and hasFn(wrapped, "open"),
  }
end

function adapter.classifyPeripheral(kind)
  kind = kind or "unknown"
  if kind == "monitor" then
    return "display"
  end
  if kind == "modem" then
    return "network"
  end
  if kind == "computer" or kind == "command" then
    return "computer"
  end
  if kind == "turtle" then
    return "turtle"
  end
  if startsWith(kind, "minecraft:") or startsWith(kind, "storagedrawers:") or startsWith(kind, "toms_storage:") then
    return "block"
  end
  return "machine"
end

function adapter.readMeta(kind, wrapped)
  local meta = {}
  if hasFn(wrapped, "getNameLocal") then
    local ok, value = pcall(wrapped.getNameLocal)
    if ok then
      meta.label = value
    end
  end
  if kind == "monitor" and hasFn(wrapped, "getSize") then
    local ok, w, h = pcall(wrapped.getSize)
    if ok then
      meta.monitor = { width = w, height = h }
    end
  end
  if kind == "modem" and hasFn(wrapped, "isWireless") then
    local ok, wireless = pcall(wrapped.isWireless)
    if ok then
      meta.modem = { wireless = wireless and true or false }
    end
  end
  return meta
end

return adapter
