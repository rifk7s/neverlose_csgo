---
name: Neverlose CSGO Lua API
description: Reference skill for writing Neverlose (NL) CSGO Lua scripts. Covers the full API including render, ui, entity, events, globals, rage, color, vector, and more. Use this when working on any Neverlose Lua script.
---

# Neverlose CSGO Lua API Reference

This skill provides context for authoring Lua scripts targeting the **Neverlose** CSGO cheat platform.

## Documentation Source

Full docs: https://docs-csgo.neverlose.cc

### Querying Docs Dynamically
You can query the documentation at runtime using the `ask` query parameter on any page URL:
```
GET https://docs-csgo.neverlose.cc/readme.md?ask=<url-encoded-question>
```
The response returns a direct answer with relevant excerpts and sources.

## Key API Modules

| Module | Docs URL | Description |
|--------|----------|-------------|
| `ui` | https://docs-csgo.neverlose.cc/documentation/variables/ui.md | Menu elements, sidebar, switches, combos, sliders |
| `render` | https://docs-csgo.neverlose.cc/documentation/variables/render.md | Drawing: text, rect, gradient, texture, load_font, load_image, screen_size |
| `entity` | https://docs-csgo.neverlose.cc/documentation/variables/entity.md | Player entities, local player, threats, spectators |
| `events` | https://docs-csgo.neverlose.cc/documentation/variables/events.md | Callbacks: render, createmove, aim_fire, etc. |
| `globals` | https://docs-csgo.neverlose.cc/documentation/variables/globals.md | tickcount, curtime, frametime, is_in_game, etc. |
| `rage` | https://docs-csgo.neverlose.cc/documentation/variables/rage.md | Ragebot & antiaim API |
| `color` | https://docs-csgo.neverlose.cc/documentation/variables/color.md | Color constructor: `color(r, g, b, a)` |
| `vector` | https://docs-csgo.neverlose.cc/documentation/variables/vector.md | 2D/3D vector: `vector(x, y)` or `vector(x, y, z)` |
| `common` | https://docs-csgo.neverlose.cc/documentation/variables/common.md | Utility functions |
| `utils` | https://docs-csgo.neverlose.cc/documentation/variables/utils.md | Interfaces, execute_after, net_channel |
| `cvar` | https://docs-csgo.neverlose.cc/documentation/variables/cvar.md | Console variables |
| `files` | https://docs-csgo.neverlose.cc/documentation/variables/files.md | File I/O |
| `json` | https://docs-csgo.neverlose.cc/documentation/variables/json.md | JSON parse/stringify |
| `bit` | https://docs-csgo.neverlose.cc/documentation/variables/bit.md | Bitwise operations |
| `materials` | https://docs-csgo.neverlose.cc/documentation/variables/materials.md | Material creation |
| `panorama` | https://docs-csgo.neverlose.cc/documentation/variables/panorama.md | Panorama JS eval |
| `esp` | https://docs-csgo.neverlose.cc/documentation/variables/esp.md | ESP callbacks |
| `network` | https://docs-csgo.neverlose.cc/documentation/variables/network.md | Network HTTP |
| `db` | https://docs-csgo.neverlose.cc/documentation/variables/db.md | Player database |

## Common Patterns

### Registering a Render Callback
```lua
events.render:set(function()
    -- drawing code here
end)
```

### Creating UI Elements
```lua
ui.sidebar("My Script", "icon_name")
local main = ui.create("Tab", "Group")
local my_switch = main:switch("Enable Feature")
local my_combo = main:combo("Mode", {"Option1", "Option2"})
local my_slider = main:slider("Amount", 0, 100, 50)
```

### Drawing on Screen
```lua
local screen = render.screen_size()
local font = render.load_font("Verdana", 16, "ad")

-- Solid rectangle
render.rect(pos_a, pos_b, color(0, 0, 0, 200))

-- Gradient rectangle
render.gradient(pos_a, pos_b, top_left, top_right, bottom_left, bottom_right)

-- Text (flags: 'c' = centered, 's' = left-aligned with shadow)
render.text(font, position, color(255), "c", "Hello World")
```

### Entity Checks
```lua
local lp = entity.get_local_player()
if not lp or not lp:is_alive() then return end
local velocity = lp.m_vecVelocity:length()
local flags = lp.m_fFlags
```

### Velocity Modifier
```lua
local modifier = lp.m_flVelocityModifier  -- 0.0 to 1.0, < 1 means slowed
```

### Defensive Detection (sim time rollback)
```lua
local sim_time = to_ticks(player.m_flSimulationTime)
-- If sim_diff < 0, player is in defensive (exploiting tickbase)
```

## Script File Location
Scripts are stored in: `<CS:GO Install>/nl/scripts/`

## Useful Examples
- https://docs-csgo.neverlose.cc/useful-information/script-examples.md
- https://docs-csgo.neverlose.cc/useful-information/quick-start.md
