local networkScreen = dofile("ui/screens/network.lua")
local resourcesScreen = dofile("ui/screens/resources.lua")
local recipesScreen = dofile("ui/screens/recipes.lua")
local calculatorScreen = dofile("ui/screens/calculator.lua")
local energyScreen = dofile("ui/screens/energy.lua")
local logsScreen = dofile("ui/screens/logs.lua")

local appUi = {}

local function chooseMonitorScale(monitor, minWidth, minHeight)
  local scales = { 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 }
  local selected = 0.5
  for _, scale in ipairs(scales) do
    local okSet = pcall(monitor.setTextScale, scale)
    if okSet then
      local okSize, w, h = pcall(monitor.getSize)
      if okSize and w >= minWidth and h >= minHeight then
        selected = scale
      else
        break
      end
    end
  end
  pcall(monitor.setTextScale, selected)
  return selected
end

local function pickOutput(settings)
  local monitor = peripheral.find("monitor")
  if monitor then
    local minWidth = settings.uiMinWidth or 30
    local minHeight = settings.uiMinHeight or 12
    local scale = chooseMonitorScale(monitor, minWidth, minHeight)
    return monitor, true, scale
  end
  return term, false, 1
end

local function shortName(value)
  local map = {
    network = "NET",
    resources = "RES",
    recipes = "RCP",
    calculator = "CALC",
    energy = "PWR",
    logs = "LOG",
  }
  return map[value] or string.sub(string.upper(value), 1, 3)
end

local function drawLine(out, width, line)
  if #line > width then
    out.write(string.sub(line, 1, math.max(1, width - 1)) .. "~")
    return
  end
  out.write(line)
end

local function drawTabs(out, tabs, selected, width, compact)
  out.write("Tabs:")
  for i, tab in ipairs(tabs) do
    local label = compact and shortName(tab) or tab
    if i == selected then
      out.write("[" .. label .. "]")
    else
      out.write(" " .. label .. " ")
    end
  end
  out.write("\n")
  if compact then
    drawLine(out, width, ("Pg:%d  1-6 tabs  n/p  q"):format(selected))
  else
    drawLine(out, width, ("Page:%d  Keys:[1-6] tabs [n/p] page [q] quit"):format(selected))
  end
  out.write("\n\n")
end

function appUi.new(settings)
  local output, isMonitor, scale = pickOutput(settings)
  return {
    out = output,
    isMonitor = isMonitor,
    scale = scale,
    settings = settings,
  }
end

function appUi.render(self, uiState, viewModel)
  local width, height = self.out.getSize()
  local compact = width < 42 or height < 16
  local bodyHeight = math.max(4, height - 4)
  local pageSize = math.max(4, bodyHeight - 2)

  self.out.clear()
  self.out.setCursorPos(1, 1)
  drawTabs(self.out, uiState.tabs, uiState.selectedTab, width, compact)

  local tab = uiState:currentTabName()
  local state = {
    devices = viewModel.devices,
    items = viewModel.items,
    fluids = viewModel.fluids,
    recipes = viewModel.recipes,
    plan = viewModel.plan,
    energyTotals = viewModel.energyTotals,
    machineEnergy = viewModel.machineEnergy,
    messages = uiState.messages,
    page = uiState.page,
    networkSummary = viewModel.networkSummary,
    pageSize = pageSize,
    compact = compact,
    viewportWidth = width,
    viewportHeight = height,
  }

  if tab == "network" then
    networkScreen.render(self.out, state)
  elseif tab == "resources" then
    resourcesScreen.render(self.out, state)
  elseif tab == "recipes" then
    recipesScreen.render(self.out, state)
  elseif tab == "calculator" then
    calculatorScreen.render(self.out, state)
  elseif tab == "energy" then
    energyScreen.render(self.out, state)
  elseif tab == "logs" then
    logsScreen.render(self.out, state)
  end
end

function appUi.handleEvent(self, uiState, event)
  local name = event[1]
  if name == "key" then
    local key = event[2]
    if key >= keys.one and key <= keys.six then
      uiState.selectedTab = (key - keys.one) + 1
      return true, nil
    end
    if key == keys.n then
      uiState.page = uiState.page + 1
      return true, nil
    end
    if key == keys.p then
      uiState.page = math.max(1, uiState.page - 1)
      return true, nil
    end
    if key == keys.q then
      return true, "quit"
    end
  elseif name == "mouse_scroll" then
    local dir = event[2]
    if dir == 1 then
      uiState.page = uiState.page + 1
    else
      uiState.page = math.max(1, uiState.page - 1)
    end
    return true, nil
  elseif name == "monitor_touch" or name == "mouse_click" then
    local x = event[3]
    local width = select(1, self.out.getSize())
    local bucketSize = math.max(1, math.floor(width / #uiState.tabs))
    local bucket = math.floor((x - 1) / bucketSize) + 1
    if bucket > #uiState.tabs then
      bucket = #uiState.tabs
    end
    if bucket >= 1 and bucket <= #uiState.tabs then
      uiState.selectedTab = bucket
      return true, nil
    end
  end
  return false, nil
end

return appUi
