local settings = {
  scanIntervalSec = 2.0,
  uiRefreshSec = 0.25,
  snapshotIntervalSec = 5.0,
  transferOpsPerTick = 8,
  transferModes = {
    burst = { opsPerTick = 24 },
    balanced = { opsPerTick = 8 },
    safe = { opsPerTick = 2 },
  },
  defaultTransferMode = "balanced",
  recipesPath = "data/recipes.db.lua",
  networkSnapshotPath = "data/network_state.json",
  eventsLogPath = "logs/events.log",
  monitorPreferredScale = 0.5,
  uiMinWidth = 30,
  uiMinHeight = 12,
}

return settings
