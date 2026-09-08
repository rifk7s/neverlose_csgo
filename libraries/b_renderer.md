# Better Renderer

> **Market:** [neverlose.cc/market/item?id=kKc6nj](https://neverlose.cc/market/item?id=kKc6nj) &nbsp;·&nbsp; **Source:** Closed

A drop-in renderer wrapper that mirrors Skeet-style renderer API on top of Neverlose's native renderer, adding radius support, centered/aligned text, and texture rendering with rounded corners.

## Import

```lua
local b_renderer = require("neverlose/b_renderer")
```

---

## API Reference

### Text

| Function | Description |
|----------|-------------|
| `renderer.text(x, y, r, g, b, a, flags, max_width, ...)` | Draw text at `(x, y)` with the given color, alignment flags, and optional max width |
| `renderer.measure_text(flags, ...)` | Returns the `width, height` of the given text with the specified flags |

#### Text Flags

| Flag | Meaning |
|------|---------|
| `"c"` | Center horizontally |
| `"+"` | Right-align |
| `"-"` | Left-align |
| `"b"` | Bold |
| `"c+"` | Center + right |
| `"c-"` | Center + left |
| `"+c"` | Right + center |
| `"-c"` | Left + center |
| `"bc"` | Bold + centered |
| `""` / `nil` | Default (left-aligned) |

---

### Shapes

| Function | Description |
|----------|-------------|
| `renderer.rectangle(x, y, w, h, r, g, b, a, rad)` | Filled rectangle; `rad` = corner radius |
| `renderer.line(xa, ya, xb, yb, r, g, b, a)` | Line from `(xa, ya)` to `(xb, yb)` |
| `renderer.gradient(x, y, w, h, r1, g1, b1, a1, r2, g2, b2, a2, ltr)` | Gradient rect; `ltr = true` for left-to-right, `false` for top-to-bottom |
| `renderer.circle(x, y, r, g, b, a, radius, start_degrees, percentage)` | Filled arc/circle |
| `renderer.circle_outline(x, y, r, g, b, a, radius, start_degrees, percentage, thickness)` | Outlined arc/circle |

---

### Misc

| Function | Description |
|----------|-------------|
| `renderer.world_to_screen(x, y, z)` | Converts world coordinates to screen `x, y`; returns `nil` if off-screen |
| `renderer.texture(id, x, y, w, h, r, g, b, a, mode, rad)` | Draw a texture with optional tint color, blend mode, and corner radius |
