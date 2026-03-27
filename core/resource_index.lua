local resourceIndex = {}

local function itemKey(item)
  if not item then
    return "unknown"
  end
  local nbt = item.nbt or ""
  return (item.name or "unknown") .. "|" .. tostring(nbt)
end

local function fluidKey(fluid)
  if not fluid then
    return "unknown_fluid"
  end
  local tags = fluid.tags and textutils.serialize(fluid.tags) or ""
  return (fluid.name or fluid.id or "unknown_fluid") .. "|" .. tags
end

local function safeCall(fn, ...)
  local ok, value = pcall(fn, ...)
  if ok then
    return value
  end
  return nil
end

function resourceIndex.new(fileStore, settings, logger)
  return {
    fileStore = fileStore,
    settings = settings,
    logger = logger,
    items = {},
    fluids = {},
    lastUpdated = 0,
  }
end

function resourceIndex.rebuild(self, devices)
  local items = {}
  local fluids = {}

  for _, dev in pairs(devices) do
    local p = dev.wrapped
    if p and dev.capabilities.inventory and type(p.list) == "function" then
      local slots = safeCall(p.list) or {}
      for _, stack in pairs(slots) do
        local key = itemKey(stack)
        local entry = items[key] or {
          key = key,
          name = stack.name or "unknown",
          count = 0,
          perDevice = {},
        }
        entry.count = entry.count + (stack.count or 0)
        entry.perDevice[dev.id] = (entry.perDevice[dev.id] or 0) + (stack.count or 0)
        items[key] = entry
      end
    end

    if p and dev.capabilities.fluids then
      local tanks = nil
      if type(p.tanks) == "function" then
        tanks = safeCall(p.tanks)
      elseif type(p.getTankInfo) == "function" then
        tanks = safeCall(p.getTankInfo)
      end
      tanks = tanks or {}
      for _, tank in pairs(tanks) do
        local fluid = tank
        if tank.name == nil and type(tank.fluid) == "table" then
          fluid = tank.fluid
          fluid.amount = tank.amount or fluid.amount
        end
        if fluid and (fluid.name or fluid.id) then
          local key = fluidKey(fluid)
          local entry = fluids[key] or {
            key = key,
            name = fluid.name or fluid.id,
            amount = 0,
            perDevice = {},
          }
          entry.amount = entry.amount + (fluid.amount or 0)
          entry.perDevice[dev.id] = (entry.perDevice[dev.id] or 0) + (fluid.amount or 0)
          fluids[key] = entry
        end
      end
    end
  end

  self.items = items
  self.fluids = fluids
  self.lastUpdated = os.epoch("utc")
  return items, fluids
end

function resourceIndex.snapshot(self)
  local payload = {
    lastUpdated = self.lastUpdated,
    items = self.items,
    fluids = self.fluids,
  }
  return self.fileStore.writeJson(self.settings.networkSnapshotPath, payload)
end

function resourceIndex.getItems(self)
  return self.items
end

function resourceIndex.getFluids(self)
  return self.fluids
end

return resourceIndex
