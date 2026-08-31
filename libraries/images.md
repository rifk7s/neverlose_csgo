# Images

> **Market:** [neverlose.cc/market/item?id=okhlzn](https://neverlose.cc/market/item?id=okhlzn) &nbsp;·&nbsp; **Source:** [Open](./sources/images.lua)

Utility library for loading and rendering in-game weapon icons. Parses and caches PNG/JPG textures from the game files for use in your custom UI.

## Import

```lua
local images = require("neverlose/images")
```

---

## API Reference

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `images.get_weapon_icon` | `weapon_name: string` | `icon` or `nil` | Loads and returns the icon object for the given weapon name. Returns `nil` if not found |

### Icon Object Methods

| Method | Parameters | Description |
|--------|------------|-------------|
| `icon:draw` | `x, y [, width, height, r, g, b, a]` | Draws the icon at screen position `(x, y)`. Width, height, and tint color are optional |

> **Note:** Weapon names use their internal CS:GO identifier (e.g. `"ssg08"`, `"ak47"`, `"awp"`).

---

## Example

```lua
local images = require("neverlose/images")

events.render:set(function()
    local icon = images.get_weapon_icon("ssg08")

    if icon ~= nil then
        icon:draw(5, 5)
    end
end)
```
