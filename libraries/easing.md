# Easing

> **Market:** [neverlose.cc/market/item?id=evmwYc](https://neverlose.cc/market/item?id=evmwYc)

A comprehensive easing functions library. All functions follow the classic Robert Penner easing signature and can be used for smooth animation of any numeric value.

## Import

```lua
local easing = require("neverlose/easing")
```

---

## Parameters

All easing functions share the same four parameters:

| Parameter | Name | Description |
|-----------|------|-------------|
| `t` | time | Current elapsed time — should go from `0` to `d` |
| `b` | begin | Starting value of the property |
| `c` | change | Total change in value (`end - begin`) |
| `d` | duration | Total duration |

---

## Functions

| Family | In | Out | In-Out | Out-In |
|--------|----|-----|--------|--------|
| **Linear** | `easing.linear(t, b, c, d)` | — | — | — |
| **Quadratic** | `easing.quad_in` | `easing.quad_out` | `easing.quad_in_out` | `easing.quad_out_in` |
| **Cubic** | `easing.cubic_in` | `easing.cubic_out` | `easing.cubic_in_out` | `easing.cubic_out_in` |
| **Quartic** | `easing.quart_in` | `easing.quart_out` | `easing.quart_in_out` | `easing.quart_out_in` |
| **Quintic** | `easing.quint_in` | `easing.quint_out` | `easing.quint_in_out` | `easing.quint_out_in` |
| **Sine** | `easing.sine_in` | `easing.sine_out` | `easing.sine_in_out` | `easing.sine_out_in` |
| **Exponential** | `easing.expo_in` | `easing.expo_out` | `easing.expo_in_out` | `easing.expo_out_in` |
| **Circular** | `easing.circ_in` | `easing.circ_out` | `easing.circ_in_out` | `easing.circ_out_in` |
| **Elastic** | `easing.elastic_in` | `easing.elastic_out` | `easing.elastic_in_out` | `easing.elastic_out_in` |
| **Back** | `easing.back_in` | `easing.back_out` | `easing.back_in_out` | `easing.back_out_in` |
| **Bounce** | `easing.bounce_in` | `easing.bounce_out` | `easing.bounce_in_out` | `easing.bounce_out_in` |

---

## Example

```lua
local easing = require("neverlose/easing")

local begin    = 0
local endl     = 1
local change   = endl - begin
local duration = 1

print_raw(easing.bounce_out_in(0,               begin, change, duration))  --> 0
print_raw(easing.bounce_out_in(duration / 4,    begin, change, duration))  --> 0.3828125
print_raw(easing.bounce_out_in(duration / 2,    begin, change, duration))  --> 0.5
print_raw(easing.bounce_out_in(duration / 3/4,  begin, change, duration))  --> 0.10503472222222
print_raw(easing.bounce_out_in(duration,        begin, change, duration))  --> 1
```
