# Timer Library

> **Market:** [neverlose.cc/market/item?id=xKbyaI](https://neverlose.cc/market/item?id=xKbyaI) &nbsp;·&nbsp; **Source:** Closed

A managed timer system for scheduling recurring or one-shot callbacks. Timers are automatically ticked by the library — no manual event hooks needed.

## Import

```lua
local timer = require("neverlose/timer")
```

---

## Creating a Timer

```lua
local example = timer.create(update_time, [force_call], callback [, ...])
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `update_time` | `number` | ✓ | Interval in milliseconds between each callback invocation |
| `force_call` | `boolean` | — | If `true`, fires the callback immediately on creation |
| `callback` | `function` | ✓ | Function to call on each tick |
| `...` | any | — | Additional arguments passed to the callback |

---

## Timer Object Methods

| Method | Description |
|--------|-------------|
| `example:set_update_time(update_time [, reset_old_time])` | Changes the interval. If `reset_old_time = true`, resets the internal clock so the first call waits the full new interval |
| `example:force_call([delay])` | Fires the callback immediately, or after an optional `delay` in milliseconds |
| `example:start()` | Starts a previously stopped timer (newly created timers start automatically) |
| `example:stop()` | Pauses the timer without destroying it |
| `example:delete()` | Clears the timer reference and frees it for GC. **Call this before setting the timer to `nil`** or when your script unloads, otherwise the timer will keep running in the background |

> **Important:** Always call `:delete()` in your `events.shutdown` handler or before reassigning the variable. Timers that are not deleted will continue to run even after the variable goes out of scope.

---

## Example

```lua
local timer = require("neverlose/timer")

-- Fire every 1000ms
local my_timer = timer.create(1000, function()
    print("tick!")
end)

-- Change interval to 500ms and reset clock
my_timer:set_update_time(500, true)

-- Stop and restart
my_timer:stop()
my_timer:start()

-- Clean up on script unload
events.shutdown:set(function()
    my_timer:delete()
end)
```
