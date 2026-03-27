local energyModel = {}

local function safeCall(fn)
  local ok, value = pcall(fn)
  if ok then
    return value
  end
  return nil
end

local function readStored(p)
  if type(p.getEnergyStored) == "function" then
    return safeCall(p.getEnergyStored)
  end
  if type(p.getEnergy) == "function" then
    return safeCall(p.getEnergy)
  end
  return nil
end

local function readCapacity(p)
  if type(p.getMaxEnergyStored) == "function" then
    return safeCall(p.getMaxEnergyStored)
  end
  if type(p.getEnergyCapacity) == "function" then
    return safeCall(p.getEnergyCapacity)
  end
  return nil
end

function energyModel.new()
  return {
    machineEnergy = {},
    totals = { stored = 0, capacity = 0 },
  }
end

function energyModel.rebuild(self, devices)
  local machineEnergy = {}
  local totals = { stored = 0, capacity = 0 }

  for _, dev in pairs(devices) do
    if dev.capabilities and dev.capabilities.energy and dev.wrapped then
      local stored = readStored(dev.wrapped) or 0
      local capacity = readCapacity(dev.wrapped) or 0
      local usage = 0
      if type(dev.wrapped.getEnergyUsage) == "function" then
        usage = safeCall(dev.wrapped.getEnergyUsage) or 0
      end
      local etaSec = nil
      if usage > 0 then
        etaSec = math.floor(stored / usage)
      end
      machineEnergy[dev.id] = {
        id = dev.id,
        type = dev.type,
        stored = stored,
        capacity = capacity,
        usagePerSec = usage,
        etaSec = etaSec,
      }
      totals.stored = totals.stored + stored
      totals.capacity = totals.capacity + capacity
    end
  end

  self.machineEnergy = machineEnergy
  self.totals = totals
  return machineEnergy, totals
end

return energyModel
