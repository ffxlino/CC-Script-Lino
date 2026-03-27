local settings = dofile("config/settings.lua")
local loggerMod = dofile("core/logger.lua")
local fileStore = dofile("core/file_store.lua")
local registryMod = dofile("core/peripheral_registry.lua")
local resourceIndexMod = dofile("core/resource_index.lua")
local recipeStoreMod = dofile("core/recipe_store.lua")
local craftPlannerMod = dofile("core/craft_planner.lua")
local transferRouterMod = dofile("core/transfer_router.lua")
local energyModelMod = dofile("core/energy_model.lua")
local uiStateMod = dofile("ui/ui_state.lua")
local appUiMod = dofile("ui/app_ui.lua")

local app = {}

function app.run()
  local logger = loggerMod.new(settings.eventsLogPath)
  local registry = registryMod.new(logger)
  local resourceIndex = resourceIndexMod.new(fileStore, settings, logger)
  local store = recipeStoreMod.new(fileStore, settings)
  local planner = craftPlannerMod.new(store)
  local router = transferRouterMod.new(settings, logger)
  local energy = energyModelMod.new()
  local uiState = uiStateMod.new()
  local ui = appUiMod.new(settings)

  logger:info("Application started")
  uiState:pushMessage("CC Automation started")

  local nextScanAt = os.clock()
  local nextSnapshotAt = os.clock()
  local viewModel = {
    devices = {},
    items = {},
    fluids = {},
    recipes = store:list(),
    plan = { deficits = {}, actions = {} },
    machineEnergy = {},
    energyTotals = { stored = 0, capacity = 0 },
    networkSummary = {},
  }

  while true do
    local now = os.clock()
    if now >= nextScanAt then
      local devices = registry:scan()
      local items, fluids = resourceIndex:rebuild(devices)
      local machineEnergy, totals = energy:rebuild(devices)

      viewModel.devices = devices
      viewModel.items = items
      viewModel.fluids = fluids
      viewModel.recipes = store:list()
      viewModel.machineEnergy = machineEnergy
      viewModel.energyTotals = totals
      viewModel.networkSummary = registry:networkSummary()

      router:tick(devices)
      viewModel.plan = planner:buildPlan(resourceIndex, uiState.plannerTargets or {})

      uiState:pushMessage(("Scan rev=%d devices=%d"):format(registry.revision, #peripheral.getNames()))
      nextScanAt = now + settings.scanIntervalSec
    end

    if now >= nextSnapshotAt then
      resourceIndex:snapshot()
      nextSnapshotAt = now + settings.snapshotIntervalSec
    end

    ui:render(uiState, viewModel)

    local event = { os.pullEvent() }
    local handled, command = ui:handleEvent(uiState, event)
    if handled and command == "quit" then
      logger:info("Application stopped by user")
      break
    end
  end
end

return app
