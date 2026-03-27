# CC Automation Core

## Start

- Place files into your ComputerCraft computer filesystem.
- Run `startup` (auto-runs on boot).

## Server deploy (one command)

1. Upload this folder to a Git repo (or any raw HTTP host).
2. Edit `install.lua` and set `BASE_URL` to the raw URL of your `ccscript` directory.
3. On the in-game CC computer (server world), run one command:
   - `wget run <RAW_URL_TO_INSTALL_LUA>`
4. Installer downloads all files, writes `startup.lua`, and reboots.
5. After reboot script starts automatically.

Example shape of URL:

- `https://raw.githubusercontent.com/<user>/<repo>/<branch>/ccscript/install.lua`

Important:

- ComputerCraft `http` must be enabled on the server.
- On updates, run the same `wget run .../install.lua` command again.

## Controls

- `1..6` switch tabs.
- `n` / `p` next/previous page.
- mouse wheel also changes page.
- `q` quit.
- monitor touch switches tab by horizontal position.

## Adapter layer

- Peripheral normalization is handled by `core/adapters/peripheral_adapter.lua`.
- The registry now classifies devices as `computer`, `turtle`, `network`, `display`, `machine`.
- Network summary tracks wired/wireless modems and active CC nodes.

## Monitor auto-layout

- UI auto-picks monitor text scale based on available size.
- Works with small monitor grids (for example `3x5`, `4x4`) in compact mode.
- Minimum layout requirements are configurable in `config/settings.lua` via `uiMinWidth` and `uiMinHeight`.
- If monitor is small, UI automatically switches to compact mode.

## Saved expansion draft

- Future adapter/extensions draft is stored in `docs/EXPANSION_DRAFT.md`.

## Recipe CRUD

- `app/recipe_cli.lua list`
- `app/recipe_cli.lua add <recipe_file.lua>`
- `app/recipe_cli.lua delete <recipeId>`

Recipe file format:

```lua
return {
  recipeId = "example:plate_iron",
  machineType = "gregtech:bender",
  inputs = {
    items = { { id = "minecraft:iron_ingot", count = 1 } },
    fluids = {},
  },
  outputs = {
    items = { { id = "gregtech:iron_plate", count = 1 } },
    fluids = {},
  },
  duration = 100,
  channels = { euPerTick = 8 },
  tags = { "plate", "iron" },
}
```
