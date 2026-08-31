# Smoothy Library

> **Market:** [neverlose.cc/market/item?id=Z07zlX](https://neverlose.cc/market/item?id=Z07zlX) &nbsp;·&nbsp; **Source:** [Open](./sources/smoothy.lua) &nbsp;·&nbsp; **README:** [github.com/tickcount/smoothy.lua](https://raw.githubusercontent.com/tickcount/smoothy.lua/refs/heads/main/README.md)

A frametime-aware easing library for smooth value interpolation. Supports `number`, `boolean`, `table`, `vector`, and `color` types, with optional custom easing functions and global speed scaling.

## Import

```lua
local smoothy = require("neverlose/smoothy")
```

---

## API Reference

### `smoothy.new(default, easing_fn)`

Creates a new smoothy object that holds and interpolates a value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `default` | `number \| boolean \| table \| vector \| color` | Initial value |
| `easing_fn` | `function` *(optional)* | Custom easing function `(t, b, c, d) -> number`. Defaults to linear |

**Returns:** A smoothy object.

#### Smoothy Object — `:update(duration, value [, easing [, ignore_adj_speed]])`

| Parameter | Type | Description |
|-----------|------|-------------|
| `duration` | `number` | Transition duration in seconds (default `0.15`) |
| `value` | *(any)* | Target value — must match the type of the initial value |
| `easing` | `function` *(optional)* | Override easing for this call only |
| `ignore_adj_speed` | `boolean` *(optional)* | If `true`, ignores global speed adjustment |

**Returns:** The current interpolated value.

> The object is also callable: `smoothy_obj(duration, value)` is equivalent to `smoothy_obj:update(duration, value)`.

---

### `smoothy.new_interp(initial_value)`

Creates a tick-rate-based interpolator for smoother sub-tick value transitions.

| Parameter | Type | Description |
|-----------|------|-------------|
| `initial_value` | `number` | Starting value (default `0`) |

**Returns:** An interpolator object. Call it as `interp(new_value [, mul])` where `mul` scales the tickinterval (default `1`).

---

### `smoothy.set_speed(new_speed)`

Global speed multiplier affecting all smoothy objects (unless `ignore_adj_speed` is set).

| Argument | Behavior |
|----------|----------|
| `number >= 0` | Sets the global speed multiplier |
| `nil` | Resets (removes) the speed multiplier |
| `true` | Returns the current speed multiplier without changing it |

---

## Supported Types

| Type | Notes |
|------|-------|
| `number` | Direct interpolation; snaps at `±0.001` delta |
| `boolean` | Treated as `0` / `1` internally |
| `table` | Recursively interpolates all numeric fields |
| `vector` | Interpolates `x`, `y`, `z` components |
| `color` *(imcolor)* | Interpolates `r`, `g`, `b`, `a` components |

---

## Example

```lua
local smoothy = require("neverlose/smoothy")
local easing  = require("neverlose/easing")

-- Smooth a number with custom easing
local alpha = smoothy.new(0, easing.quad_out)

events.render:set(function()
    local target = some_condition and 255 or 0
    local current = alpha(0.2, target)  -- 200ms transition

    render.rectangle(100, 100, 200, 50, 255, 255, 255, current)
end)

-- Smooth a color
local bg_color = smoothy.new(color(30, 30, 30, 200))

events.render:set(function()
    local target = is_active and color(55, 177, 218, 255) or color(30, 30, 30, 200)
    local c = bg_color(0.15, target)

    render.rectangle(0, 0, 300, 50, c.r, c.g, c.b, c.a)
end)
```

---

## License

This library is licensed under the **GNU General Public License v3.0**.  
Copyright (C) 2022 Salvatore (tickcount)

For full license terms, please see the [original repository](https://github.com/tickcount/smoothy.lua/blob/main/LICENSE).
