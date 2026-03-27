local recipeStore = {}

local function indexById(recipes)
  local out = {}
  for i, r in ipairs(recipes) do
    out[r.recipeId] = i
  end
  return out
end

local function validate(recipe)
  if type(recipe) ~= "table" then
    return false, "recipe must be table"
  end
  if type(recipe.recipeId) ~= "string" or recipe.recipeId == "" then
    return false, "recipeId is required"
  end
  if type(recipe.machineType) ~= "string" or recipe.machineType == "" then
    return false, "machineType is required"
  end
  recipe.inputs = recipe.inputs or { items = {}, fluids = {} }
  recipe.outputs = recipe.outputs or { items = {}, fluids = {} }
  recipe.tags = recipe.tags or {}
  recipe.duration = recipe.duration or 0
  recipe.channels = recipe.channels or {}
  return true
end

function recipeStore.new(fileStore, settings)
  local raw = fileStore.readLuaTable(settings.recipesPath, { schemaVersion = 1, recipes = {} })
  raw.recipes = raw.recipes or {}
  return {
    fileStore = fileStore,
    settings = settings,
    db = raw,
    idIndex = indexById(raw.recipes),
  }
end

function recipeStore.persist(self)
  return self.fileStore.writeLuaTable(self.settings.recipesPath, self.db)
end

function recipeStore.list(self)
  return self.db.recipes
end

function recipeStore.get(self, recipeId)
  local idx = self.idIndex[recipeId]
  if not idx then
    return nil
  end
  return self.db.recipes[idx]
end

function recipeStore.create(self, recipe)
  local ok, err = validate(recipe)
  if not ok then
    return false, err
  end
  if self.idIndex[recipe.recipeId] then
    return false, "duplicate recipeId"
  end
  self.db.recipes[#self.db.recipes + 1] = recipe
  self.idIndex = indexById(self.db.recipes)
  return self:persist()
end

function recipeStore.update(self, recipeId, patch)
  local idx = self.idIndex[recipeId]
  if not idx then
    return false, "recipe not found"
  end
  local current = self.db.recipes[idx]
  for k, v in pairs(patch) do
    current[k] = v
  end
  local ok, err = validate(current)
  if not ok then
    return false, err
  end
  if current.recipeId ~= recipeId and self.idIndex[current.recipeId] then
    return false, "new recipeId already exists"
  end
  self.idIndex = indexById(self.db.recipes)
  return self:persist()
end

function recipeStore.delete(self, recipeId)
  local idx = self.idIndex[recipeId]
  if not idx then
    return false, "recipe not found"
  end
  table.remove(self.db.recipes, idx)
  self.idIndex = indexById(self.db.recipes)
  return self:persist()
end

function recipeStore.search(self, query)
  query = string.lower(query or "")
  local out = {}
  for _, recipe in ipairs(self.db.recipes) do
    local hitId = string.find(string.lower(recipe.recipeId), query, 1, true) ~= nil
    local hitMachine = string.find(string.lower(recipe.machineType), query, 1, true) ~= nil
    local hitTag = false
    for _, tag in ipairs(recipe.tags or {}) do
      if string.find(string.lower(tag), query, 1, true) then
        hitTag = true
        break
      end
    end
    if hitId or hitMachine or hitTag then
      out[#out + 1] = recipe
    end
  end
  return out
end

return recipeStore
