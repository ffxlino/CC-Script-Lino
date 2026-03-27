local screen = {}

function screen.render(termObj, state)
  local net = state.networkSummary or {}
  termObj.write(("Net C:%d T:%d M:%d Md:%d/%d\n")
    :format(net.computers or 0, net.turtles or 0, net.monitors or 0, net.wiredModems or 0, net.wirelessModems or 0))
  termObj.write("Connected devices:\n")
  local count = 0
  local limit = state.pageSize or 12
  for id, dev in pairs(state.devices or {}) do
    count = count + 1
    if count > limit then
      termObj.write("...more omitted\n")
      break
    end
    local flags = {}
    if dev.capabilities.inventory then flags[#flags + 1] = "INV" end
    if dev.capabilities.fluids then flags[#flags + 1] = "FLD" end
    if dev.capabilities.energy then flags[#flags + 1] = "ENG" end
    if dev.capabilities.modem then flags[#flags + 1] = "NET" end
    if dev.capabilities.monitor then flags[#flags + 1] = "MON" end
    local class = dev.class and ("{" .. dev.class .. "}") or ""
    termObj.write(("- %s [%s]%s %s\n"):format(id, dev.type, class, table.concat(flags, ",")))
  end
  if count == 0 then
    termObj.write("No peripherals found.\n")
  end
end

return screen
