local uiState = {}

function uiState.new()
  return setmetatable({
    tabs = { "network", "resources", "recipes", "calculator", "energy", "logs" },
    selectedTab = 1,
    page = 1,
    recipeQuery = "",
    plannerTargets = {},
    messages = {},
  }, { __index = uiState })
end

function uiState.pushMessage(self, message)
  self.messages[#self.messages + 1] = message
  if #self.messages > 200 then
    table.remove(self.messages, 1)
  end
end

function uiState.currentTabName(self)
  return self.tabs[self.selectedTab]
end

return uiState
