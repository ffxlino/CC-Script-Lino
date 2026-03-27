local screen = {}

function screen.render(termObj, state)
  local totals = state.energyTotals or {}
  termObj.write(("Total: %d/%d\n"):format(totals.stored or 0, totals.capacity or 0))
  local shown = 0
  local limit = state.pageSize or 12
  for id, row in pairs(state.machineEnergy or {}) do
    shown = shown + 1
    local eta = row.etaSec and tostring(row.etaSec) .. "s" or "n/a"
    termObj.write(("- %s %d/%d usage:%d ETA:%s\n"):format(id, row.stored, row.capacity, row.usagePerSec or 0, eta))
    if shown >= limit then
      termObj.write("...more omitted\n")
      break
    end
  end
  if shown == 0 then
    termObj.write("No energy peripherals detected.\n")
  end
end

return screen
