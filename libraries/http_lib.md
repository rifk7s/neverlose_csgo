# HTTP Lib

> **Market:** [neverlose.cc/market/item?id=8wPcks](https://neverlose.cc/market/item?id=8wPcks) &nbsp;·&nbsp; **Source:** [Open](./sources/http_lib.lua)

A lightweight HTTP client built on top of the Steam HTTP API via FFI. Supports GET, POST, and generic requests with headers, params, raw body, and timeout handling.

## Import

```lua
local http_lib = require("neverlose/http_lib")
```

---

## Creating an Instance

```lua
local http = http_lib.new({
    task_interval = 0.3,   -- polling interval in seconds
    enable_debug  = true,  -- print requests to console
    timeout       = 10     -- request expiration time in seconds
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `task_interval` | `number` | `0.3` | How often (in seconds) pending requests are checked |
| `enable_debug` | `boolean` | `false` | Print debug info to console |
| `timeout` | `number` | `10` | Seconds before a request is considered timed out |

---

## Methods

| Method | Description |
|--------|-------------|
| `http:get(url, callback)` | Send a GET request |
| `http:post(url, params, callback)` | Send a POST request with a params table |
| `http:request(method, url, options, callback)` | Generic request — `method` is one of `"get"`, `"post"`, `"put"`, `"delete"`, `"patch"`, `"head"`, `"options"` |

### `options` table (for `http:request`)

| Key | Type | Description |
|-----|------|-------------|
| `headers` | `table` | Key-value pairs of request headers |
| `body` | `string` | Raw request body |
| `params` | `table` | URL/form parameters |
| `user_agent_info` | `string` | Override the User-Agent string |

---

## Callback Response Object

The callback receives a `data` object:

| Field / Method | Description |
|----------------|-------------|
| `data.status` | HTTP status code (`200`, `204`, `408`, `0`) |
| `data.body` | Response body as a string (may be `nil` on failure) |
| `data.headers` | Table-like accessor for response headers (e.g. `data.headers["Content-Type"]`) |
| `data:success()` | Returns `true` if `status == 200` |

---

## Example

```lua
local http_lib = require("neverlose/http_lib")

local http = http_lib.new({
    task_interval = 0.3,
    enable_debug  = true,
    timeout       = 10
})

http:get("http://ip-api.com/json/?fields=61439", function(data)
    if data:success() and data.body then
        print(data.body)
    end
end)
```
