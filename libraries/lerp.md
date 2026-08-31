# Smooth Lerp

> **Market:** [neverlose.cc/market/item?id=tUW47M](https://neverlose.cc/market/item?id=tUW47M) &nbsp;·&nbsp; **Source:** [Open](./sources/lerp.lua)

A named lerp cache system. Create and update smooth linear interpolations by name — useful for UI animations tied to element state without managing state variables manually.

## Import

```lua
local lerp = require("neverlose/lerp")
```

---

## API Reference

| Function | Parameters | Description |
|----------|------------|-------------|
| `lerp.lerp` | `name: string, lerpTo: number, speed: number` | Creates or updates a named lerp toward `lerpTo` at the given speed. Returns the current lerped value |
| `lerp.get` | `name: string` | Returns the current lerped value without updating it |
| `lerp.reset` | `name: string` | Resets the lerp value to `0` immediately (no interpolation) |
| `lerp.delete` | `name: string` | Removes the lerp entry from the cache |

> **Note:** Speed is multiplied by `globals.frametime`, so higher values = faster convergence. A value of `6` is a reasonable default for most UI animations.

---

## Example

```lua
local lerp = require("neverlose/lerp")

local dt_ref = ui.find("Aimbot", "Ragebot", "Main", "Double Tap")

events.render:set(function()
    -- Slide text position based on DT toggle state
    if dt_ref:get() then
        lerp.lerp("text anim", 500, 6)
    else
        lerp.lerp("text anim", 0, 6)
    end

    render.text(4, vector(500 + lerp.get("text anim"), 600), color(255), "A O", "text moves very nice :)")
end)
```
