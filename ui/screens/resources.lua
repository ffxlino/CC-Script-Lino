local screen = {}

local function renderItems(termObj, items, page, pageSize)
  local sorted = {}
  for _, v in pairs(items or {}) do
    sorted[#sorted + 1] = v
  end
  table.sort(sorted, function(a, b) return (a.count or 0) > (b.count or 0) end)
  local startAt = (page - 1) * pageSize + 1
  local finishAt = math.min(#sorted, startAt + pageSize - 1)
  for i = startAt, finishAt do
    local it = sorted[i]
    termObj.write(("- %s x%d\n"):format(it.name, it.count))
  end
  if #sorted == 0 then
    termObj.write("No item data.\n")
  end
end

local function renderFluids(termObj, fluids, page, pageSize)
  local sorted = {}
  for _, v in pairs(fluids or {}) do
    sorted[#sorted + 1] = v
  end
  table.sort(sorted, function(a, b) return (a.amount or 0) > (b.amount or 0) end)
  local startAt = (page - 1) * pageSize + 1
  local finishAt = math.min(#sorted, startAt + pageSize - 1)
  for i = startAt, finishAt do
    local it = sorted[i]
    termObj.write(("- %s %dmb\n"):format(it.name, it.amount))
  end
  if #sorted == 0 then
    termObj.write("No fluid data.\n")
  end
end

function screen.render(termObj, state)
  termObj.write("Resources (items)\n")
  renderItems(termObj, state.items, state.page or 1, state.pageSize or 10)
  termObj.write("\nFluids\n")
  renderFluids(termObj, state.fluids, state.page or 1, state.pageSize or 10)
end

return screen
