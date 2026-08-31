# Gradient Text

> **Market:** [neverlose.cc/market/item?id=oaTQg7](https://neverlose.cc/market/item?id=oaTQg7) &nbsp;·&nbsp; **Source:** Closed

Library for creating per-character gradient-colored text strings and animated gradient text objects. Compatible with `render.text` on Neverlose.

> **Performance note:** If using gradient strings in a `render` callback, create them *outside* the callback so they are not rebuilt every frame.

## Import

```lua
local gradient = require("neverlose/gradient")
```

---

## API Reference

### Static Gradient

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `gradient.linear` | `clrs: table, value: number` | `color` | Interpolates across multiple colors; `value` is between `0.0` and `1.0` |
| `gradient.text` | `str: string, trim: boolean, clr: table` | `string` | Creates a gradient-colored string across multiple colors |

### Animated Gradient

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `gradient.text_animate` | `str: string, cycle_speed: number, clr: table` | `animated_text` | Creates an animated gradient text object |

#### Animated Text Object Methods

| Method | Description |
|--------|-------------|
| `:animate()` | Advances the animation — call every frame inside `events.render` |
| `:get_animated_text()` | Returns the current animated gradient string |
| `:gamma_correct(gamma)` | Applies gamma correction to the gradient |
| `:set_current_position(position)` | Sets animation position (between `-1` and `1`) |
| `:get_current_position()` | Returns current animation position |
| `:set_speed(speed)` | Sets cycle speed (seconds per full cycle; lower = faster) |
| `:get_speed()` | Returns current cycle speed |
| `:set_colors(colors)` | Updates the gradient color stops |
| `:set_text(text)` | Updates the source text |
| `:get_text()` | Returns the original (non-animated) text |

---

## Color Stop Format

Colors can be plain `color()` values or tables with explicit stop positions:

```lua
-- Evenly spaced (no stop positions)
{ color(0, 0, 255), color(255, 0, 0), color(0, 255, 0) }

-- Explicit stop positions (0.0 – 1.0)
{ {color(55, 177, 218), 0}, {color(0, 0, 255), 0.5}, {color(197, 75, 206), 1.0} }
```

---

## Example

```lua
local gradient = require("neverlose/gradient")

local font = render.load_font("Arial", 62, "ba")

-- Animated gradient
local animated = gradient.text_animate("Animated gradient text!", -3, {
    color(55, 177, 218),
    color(197, 75, 206)
})

-- Static gradient
local static_text = gradient.text("Gradient text!", false, {
    color(0, 0, 255),
    color(255, 0, 0),
    color(0, 255, 0)
})

-- Interpolated color at 50%
local mid_color = gradient.linear({
    color(0, 0, 255),
    color(255, 0, 0),
    color(0, 255, 0)
}, 0.5)

events.render:set(function(ctx)
    render.text(font, vector(23, 600), color(255, 0, 255), nil, animated:get_animated_text())
    render.text(font, vector(23, 700), color(255, 0, 255), nil, static_text)
    render.text(font, vector(23, 900), mid_color, nil, "gradient_clr")

    animated:animate()
end)
```
