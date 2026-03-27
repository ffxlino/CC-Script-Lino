local settings = dofile("config/settings.lua")
local fileStore = dofile("core/file_store.lua")
local recipeStoreMod = dofile("core/recipe_store.lua")

local store = recipeStoreMod.new(fileStore, settings)

local args = { ... }
local cmd = args[1]

local function usage()
  print("Usage:")
  print("  recipe_cli list")
  print("  recipe_cli add <recipe_file.lua>")
  print("  recipe_cli update <recipeId> <patch_file.lua>")
  print("  recipe_cli delete <recipeId>")
end

if not cmd then
  usage()
  return
end

if cmd == "list" then
  for _, recipe in ipairs(store:list()) do
    print(recipe.recipeId .. " [" .. recipe.machineType .. "]")
  end
  return
end

if cmd == "add" then
  local path = args[2]
  if not path then
    usage()
    return
  end
  local ok, data = pcall(dofile, path)
  if not ok then
    printError("Cannot load recipe file: " .. data)
    return
  end
  local success, err = store:create(data)
  if not success then
    printError("Add failed: " .. tostring(err))
    return
  end
  print("Recipe added.")
  return
end

if cmd == "delete" then
  local recipeId = args[2]
  if not recipeId then
    usage()
    return
  end
  local success, err = store:delete(recipeId)
  if not success then
    printError("Delete failed: " .. tostring(err))
    return
  end
  print("Recipe deleted.")
  return
end

if cmd == "update" then
  local recipeId = args[2]
  local patchPath = args[3]
  if not recipeId or not patchPath then
    usage()
    return
  end
  local ok, patchData = pcall(dofile, patchPath)
  if not ok then
    printError("Cannot load patch file: " .. patchData)
    return
  end
  local success, err = store:update(recipeId, patchData)
  if not success then
    printError("Update failed: " .. tostring(err))
    return
  end
  print("Recipe updated.")
  return
end

usage()
