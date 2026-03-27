local craftPlanner = {}

local function aggregateNeeds(targets)
  local out = {}
  for _, t in ipairs(targets or {}) do
    local key = t.id
    out[key] = (out[key] or 0) + (t.count or 0)
  end
  return out
end

local function itemCount(itemsByKey, itemId)
  local sum = 0
  for _, entry in pairs(itemsByKey) do
    if entry.name == itemId then
      sum = sum + (entry.count or 0)
    end
  end
  return sum
end

function craftPlanner.new(recipeStore)
  return setmetatable({
    recipeStore = recipeStore,
    byOutput = {},
  }, { __index = craftPlanner })
end

local function pickRecipe(byOutput, itemId)
  local list = byOutput[itemId]
  if not list or #list == 0 then
    return nil
  end
  return list[1]
end

function craftPlanner.reindex(self)
  local byOutput = {}
  for _, recipe in ipairs(self.recipeStore:list()) do
    for _, out in ipairs((recipe.outputs and recipe.outputs.items) or {}) do
      byOutput[out.id] = byOutput[out.id] or {}
      byOutput[out.id][#byOutput[out.id] + 1] = recipe
    end
  end
  self.byOutput = byOutput
end

function craftPlanner.buildPlan(self, resourceIndex, targets)
  self:reindex()
  local needs = aggregateNeeds(targets)
  local deficits = {}
  local actions = {}
  local items = resourceIndex:getItems()

  local visiting = {}
  local function ensureItem(itemId, required)
    if visiting[itemId] then
      return
    end
    visiting[itemId] = true

    local have = itemCount(items, itemId)
    local missing = math.max(0, required - have)
    deficits[itemId] = deficits[itemId] or { required = 0, have = have, missing = 0 }
    deficits[itemId].required = math.max(deficits[itemId].required, required)
    deficits[itemId].have = have
    deficits[itemId].missing = math.max(0, deficits[itemId].required - have)

    if missing > 0 then
      local candidate = pickRecipe(self.byOutput, itemId)
      actions[#actions + 1] = { target = itemId, missing = missing, recipe = candidate and candidate.recipeId or nil }
      if candidate then
        local producedPerRun = 1
        for _, out in ipairs((candidate.outputs and candidate.outputs.items) or {}) do
          if out.id == itemId then
            producedPerRun = math.max(1, out.count or 1)
            break
          end
        end
        local runs = math.ceil(missing / producedPerRun)
        for _, inItem in ipairs((candidate.inputs and candidate.inputs.items) or {}) do
          ensureItem(inItem.id, (inItem.count or 0) * runs)
        end
      end
    end
    visiting[itemId] = nil
  end

  for itemId, required in pairs(needs) do
    ensureItem(itemId, required)
  end

  return {
    deficits = deficits,
    actions = actions,
  }
end

return craftPlanner
