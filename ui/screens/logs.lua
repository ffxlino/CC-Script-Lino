local screen = {}

function screen.render(termObj, state)
  termObj.write("Recent events\n")
  local messages = state.messages or {}
  local from = math.max(1, #messages - (state.pageSize or 15))
  for i = from, #messages do
    termObj.write(("* %s\n"):format(messages[i]))
  end
  if #messages == 0 then
    termObj.write("No events.\n")
  end
end

return screen
