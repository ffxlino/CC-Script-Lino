local registry = {}
local adapter = dofile("core/adapters/peripheral_adapter.lua")

function registry.new(logger)
  return {
    logger = logger,
    devices = {},
    revision = 0,
  }
end

function registry.scan(self)
  local nextDevices = {}
  local names = peripheral.getNames()

  for _, name in ipairs(names) do
    local p = peripheral.wrap(name)
    if p then
      local kind = peripheral.getType(name) or "unknown"
      local caps = adapter.detectCapabilities(p)
      local meta = adapter.readMeta(kind, p)
      nextDevices[name] = {
        id = name,
        type = kind,
        class = adapter.classifyPeripheral(kind),
        capabilities = caps,
        label = meta.label,
        meta = {
          methods = peripheral.getMethods(name) or {},
          adapter = meta,
        },
        wrapped = p,
      }
    end
  end

  self.devices = nextDevices
  self.revision = self.revision + 1
  if self.logger then
    self.logger:info(("Scan complete, %d devices"):format(#names))
  end
  return self.devices
end

function registry.all(self)
  return self.devices
end

function registry.byCapability(self, capName)
  local result = {}
  for _, dev in pairs(self.devices) do
    if dev.capabilities and dev.capabilities[capName] then
      result[#result + 1] = dev
    end
  end
  return result
end

function registry.networkSummary(self)
  local summary = {
    wiredModems = 0,
    wirelessModems = 0,
    turtles = 0,
    computers = 0,
    monitors = 0,
  }
  for _, dev in pairs(self.devices) do
    if dev.type == "modem" then
      local isWireless = dev.meta and dev.meta.adapter and dev.meta.adapter.modem and dev.meta.adapter.modem.wireless
      if isWireless then
        summary.wirelessModems = summary.wirelessModems + 1
      else
        summary.wiredModems = summary.wiredModems + 1
      end
    elseif dev.type == "turtle" then
      summary.turtles = summary.turtles + 1
    elseif dev.type == "computer" or dev.class == "computer" then
      summary.computers = summary.computers + 1
    elseif dev.type == "monitor" then
      summary.monitors = summary.monitors + 1
    end
  end
  return summary
end

return registry
