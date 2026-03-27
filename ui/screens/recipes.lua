local screen = {}

function screen.render(termObj, state)
  termObj.write("Recipes\n")
  local recipes = state.recipes or {}
  local shown = 0
  local limit = state.pageSize or 12
  for _, recipe in ipairs(recipes) do
    shown = shown + 1
    termObj.write(("- %s [%s]\n"):format(recipe.recipeId, recipe.machineType))
    if shown >= limit then
      termObj.write("...more omitted\n")
      break
    end
  end
  if shown == 0 then
    termObj.write("No recipes loaded.\n")
  end
  termObj.write("\nCLI:\n")
  termObj.write("recipes add|update|delete via app/recipe_cli.lua\n")
end

return screen
