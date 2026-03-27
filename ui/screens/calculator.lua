local screen = {}

function screen.render(termObj, state)
  termObj.write("Craft calculator\n")
  local deficits = state.plan and state.plan.deficits or {}
  local count = 0
  for itemId, row in pairs(deficits) do
    count = count + 1
    termObj.write(("- %s have:%d need:%d miss:%d\n"):format(itemId, row.have, row.required, row.missing))
  end
  if count == 0 then
    termObj.write("No active plan.\n")
  end
end

return screen
