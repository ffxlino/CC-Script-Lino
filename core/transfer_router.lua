local transferRouter = {}

local function canTransfer(device)
  return device and device.capabilities and device.capabilities.itemTransfer
end

local function matchFilter(stack, filter)
  if not filter then
    return true
  end
  if filter.itemId and stack.name ~= filter.itemId then
    return false
  end
  if filter.minCount and (stack.count or 0) < filter.minCount then
    return false
  end
  return true
end

local function pickSlot(srcWrapped, filter)
  if type(srcWrapped.list) ~= "function" then
    return 1
  end
  local list = srcWrapped.list() or {}
  for slot, stack in pairs(list) do
    if stack and matchFilter(stack, filter) then
      return slot
    end
  end
  return nil
end

function transferRouter.new(settings, logger)
  return {
    settings = settings,
    logger = logger,
    queue = {},
  }
end

function transferRouter.enqueue(self, job)
  -- job: sourceId, targetId, itemName?, slot?, amount?, priority?, mode?
  job.priority = job.priority or 0
  job.mode = job.mode or self.settings.defaultTransferMode
  self.queue[#self.queue + 1] = job
end

function transferRouter.tick(self, devices)
  table.sort(self.queue, function(a, b)
    return (a.priority or 0) > (b.priority or 0)
  end)

  local budget = self.settings.transferOpsPerTick
  local processed = 0

  local i = 1
  while i <= #self.queue and processed < budget do
    local job = self.queue[i]
    local src = devices[job.sourceId]
    local dst = devices[job.targetId]
    local ok = false

    local mode = self.settings.transferModes[job.mode or self.settings.defaultTransferMode]
    local modeBudget = (mode and mode.opsPerTick) or budget
    if processed >= modeBudget then
      i = i + 1
      goto continue
    end

    if canTransfer(src) and canTransfer(dst) and src.wrapped and type(src.wrapped.pushItems) == "function" then
      local amount = math.max(1, math.min(job.amount or 64, job.maxPerOp or 64))
      local sourceSlot = job.slot or pickSlot(src.wrapped, job.filter)
      local pushed = 0
      if sourceSlot then
        local success, result = pcall(src.wrapped.pushItems, job.targetId, sourceSlot, amount)
        if success then
          pushed = result or 0
        end
      end
      ok = pushed > 0
      if ok and job.amount then
        job.amount = job.amount - pushed
        if job.amount <= 0 then
          ok = true
        else
          ok = false
        end
      end
    end

    if ok then
      table.remove(self.queue, i)
    else
      job.retries = (job.retries or 0) + 1
      if job.retries > 5 then
        if self.logger then
          self.logger:warn(("Transfer failed permanently %s -> %s"):format(job.sourceId, job.targetId))
        end
        table.remove(self.queue, i)
      else
        i = i + 1
      end
    end

    processed = processed + 1
    ::continue::
  end
end

return transferRouter
