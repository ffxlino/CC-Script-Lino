local ok, mainOrErr = pcall(dofile, "app/main.lua")
if not ok then
  printError("Failed to load app/main.lua")
  printError(mainOrErr)
  return
end

if type(mainOrErr) ~= "table" or type(mainOrErr.run) ~= "function" then
  printError("app/main.lua must return table with run()")
  return
end

local success, err = pcall(mainOrErr.run)
if not success then
  printError("Fatal error in main loop:")
  printError(err)
end
