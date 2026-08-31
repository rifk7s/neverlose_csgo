# PUI — Perfect User Interface

> **Market:** [neverlose.cc/market/item?id=9bVTgG](https://neverlose.cc/market/item?id=9bVTgG) &nbsp;·&nbsp; **Source:** [Open](./sources/pui.lua)

A UI library that wraps Neverlose's native `ui` module with a cleaner API, config system, inline styling, dependency logic, gradient string macros, and more.

> **Documentation:** [hysteria-lua.gitbook.io/pui](https://hysteria-lua.gitbook.io/pui) &nbsp;·&nbsp; LLMs reference: [hysteria-lua.gitbook.io/pui/llms.txt](https://hysteria-lua.gitbook.io/pui/llms.txt) *(Neverlose section only)*
>
> **Example script:** [pastebin.com/zVmhARAK](https://pastebin.com/zVmhARAK)

## Import

```lua
local pui = require("neverlose/pui")
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Config system** | `pui.save` / `pui.load` — serialize and restore element values, including color pickers and multi-value elements |
| **Inline style** | `pui.string(s)` — format strings with gradient macros (`\b<...>`), color macros (`\a[...]`), icons (`\f<...>`), and link styling |
| **Gradient strings** | `pui.macros` — define named macros for reusable gradient/color sequences in strings |
| **`:depend(...)` system** | Conditionally show/hide or disable/enable elements based on the value of other elements |
| **Categories** | `pui.category(name, tab)` — create custom sidebar categories and tabs |
| **`pui.find`** | Extended `ui.find` that returns pui-wrapped elements with extra methods |
| **`pui.create`** | Group factory with shorthand syntax |
| **`pui.traverse`** | Recursively walk a table of pui elements |
| **`pui.translate`** | Register localization overrides for element names |

---

## Supported Element Types

| Type | Description |
|------|-------------|
| `switch` | Boolean toggle |
| `slider` | Numeric slider |
| `combo` | Single-select dropdown |
| `selectable` | Multi-select list |
| `button` | Clickable button |
| `list` / `listable` | Numeric/multi-value list selectors |
| `label` | Static text label |
| `hotkey` | Keybind element |
| `input` / `textbox` | Text input |
| `color_picker` | Color selector (supports multi-color) |
| `texture` / `image` | Texture/image element |
| `value` | Raw value element |

---

## Dependency System

Use `:depend(...)` to link element visibility or disabled state to another element's value:

```lua
local my_switch = group:switch("Enable Feature")
local my_slider = group:slider("Intensity", 0, 100, 50, 1, "%")

-- Show slider only when switch is on
my_slider:depend({ my_switch, true })
```

Supported condition types: `switch`, `combo`, `list`, `selectable`, `listable`, `slider`, or a custom function.

---

## Inline String Format

```lua
-- Gradient via macro
pui.macros["accent"] = color(55, 177, 218)
local s = pui.string("\b<accent>Hello\aDEFAULT World")

-- Icon embed
local s2 = pui.string("\f<settings> Settings")

-- Link styling
local s3 = pui.string("\vClick here\r")
```

---

## Config System

```lua
-- Save all elements in a group to a table
local saved = pui.save(config_table, "GroupName")

-- Load back
pui.load(config_table, saved, "GroupName")
```
