# Base64 Library

> **Market:** [neverlose.cc/market/item?id=PjUYKJ](https://neverlose.cc/market/item?id=PjUYKJ) &nbsp;·&nbsp; **Source:** [Open](./sources/base64.lua)

Pure-Lua Base64 encoder/decoder supporting standard `base64` and URL-safe `base64url` alphabets, with optional custom alphabet support.

## Import

```lua
local base64 = require("neverlose/base64")
```

---

## API Reference

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `base64.encode` | `str: string` | `string` | Encodes a string to Base64 |
| `base64.decode` | `str: string` | `string` | Decodes a Base64 string back to raw bytes |

> **Tip:** Both functions accept an optional second argument to specify the alphabet: `"base64"` (default), `"base64url"`, or a custom 64/65-character alphabet string.

---

## Example

```lua
local base64 = require("neverlose/base64")

local encoded = base64.encode("hello world")
print(encoded)   --> aGVsbG8gd29ybGQ=

local decoded = base64.decode(encoded)
print(decoded)   --> hello world
```
