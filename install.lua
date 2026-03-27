-- One-command installer/updater for CC Automation Core.
-- Usage in ComputerCraft:
-- wget run <RAW_URL_TO_THIS_FILE>
--
-- Before using, set BASE_URL below to your raw file host directory.
-- Example: https://raw.githubusercontent.com/<user>/<repo>/<branch>/ccscript

local BASE_URL = "https://example.com/ccscript"

local FILES = {
  "startup.lua",
  "README.md",
  "config/settings.lua",
  "app/main.lua",
  "app/recipe_cli.lua",
  "core/logger.lua",
  "core/file_store.lua",
  "core/peripheral_registry.lua",
  "core/resource_index.lua",
  "core/recipe_store.lua",
  "core/craft_planner.lua",
  "core/transfer_router.lua",
  "core/energy_model.lua",
  "core/adapters/peripheral_adapter.lua",
  "ui/ui_state.lua",
  "ui/app_ui.lua",
  "ui/screens/network.lua",
  "ui/screens/resources.lua",
  "ui/screens/recipes.lua",
  "ui/screens/calculator.lua",
  "ui/screens/energy.lua",
  "ui/screens/logs.lua",
  "data/recipes.db.lua",
  "data/network_state.json",
}

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

local function fetch(url)
  local h = http.get(url)
  if not h then
    return nil, "http.get failed: " .. url
  end
  local body = h.readAll()
  h.close()
  if not body or body == "" then
    return nil, "empty response: " .. url
  end
  return body
end

if BASE_URL == "https://example.com/ccscript" then
  printError("Edit BASE_URL in install.lua before publish.")
  printError("It must point to a directory with raw project files.")
  return
end

print("Installing CC Automation Core...")
for _, relPath in ipairs(FILES) do
  local url = BASE_URL .. "/" .. relPath
  local body, err = fetch(url)
  if not body then
    printError(err)
    printError("Install stopped at: " .. relPath)
    return
  end
  ensureDir(relPath)
  local f = fs.open(relPath, "w")
  if not f then
    printError("Unable to write: " .. relPath)
    return
  end
  f.write(body)
  f.close()
  print("OK  " .. relPath)
end

print("Done. Rebooting...")
sleep(0.5)
os.reboot()
