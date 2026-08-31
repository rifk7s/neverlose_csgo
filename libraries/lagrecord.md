# lagrecord.lua

> **Author / Source:** [github.com/tickcount/lagrecord-csgo.lua](https://github.com/tickcount/lagrecord-csgo.lua) &nbsp;·&nbsp; *(not from Neverlose Market)*

A lagrecord library for Neverlose CS:GO that tracks per-player simulation state, origin history, tickbase, and defensive detection. Originally a private project that was open-sourced.

> **Require path:** `require 'neverlose/lagrecord'`

---

## Known Limitations

| # | Issue |
|---|-------|
| 1 | Library is ~2 years old — some techniques/implementations may be outdated |
| 2 | `get_dead_time` is mostly wrong and needs a proper implementation ([reference](https://www.unknowncheats.me/forum/counterstrike-global-offensive/359885-fldeadtime-int.html)) |
| 3 | May preserve records that are already invalid (e.g. post-dormant) |

---

## Import

```lua
local lagrecord = require 'neverlose/lagrecord'

-- Optional: apply SIGNED flag
local lagrecord do
    lagrecord = require 'neverlose/lagrecord'
    lagrecord = lagrecord ^ lagrecord.SIGNED
end
```

---

## API Reference

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `lagrecord.get_snapshot` | `entity` or `entity_index` | `snapshot, record` | Returns the latest snapshot for a player (see structure below) |
| `lagrecord.get_record` | `entity [, index]` | `record` | Returns a specific raw record by index (default: `1` = newest) |
| `lagrecord.get_all` | `entity` | `table` | Returns all stored records for a player |
| `lagrecord.get_player_data` | `entity` | `table` | Returns the internal player data table |
| `lagrecord.get_server_time` | `[as_ticks: boolean]` | `number` | Returns the predicted server time (or tick count if `as_ticks = true`) |
| `lagrecord.set_update_callback` | `fn: function` | — | Registers a callback fired before each player update. Return `true` to force-write entries for that player (e.g. local player) |
| `lagrecord.unset_update_callback` | `fn: function` | — | Unregisters a previously registered update callback |

---

## Snapshot Structure (`get_snapshot`)

```
snapshot = {
    id,                       -- record index
    tick,                     -- server tick this record was written at
    updated_this_frame,       -- bool: was this player updated this frame?

    origin = {
        angles,               -- player eye angles at this record
        volume,               -- { m_vecMins, m_vecMaxs }
        current,              -- current origin (vector)
        previous,             -- previous origin (vector)
        change                -- distsqr between current and previous origin
    },

    simulation_time = {
        animated,             -- last animated simulation time
        current,              -- simulation time of this record
        previous,             -- simulation time of previous record
        change                -- delta between current and previous sim time
    },

    command = {
        elapsed,              -- ticks elapsed since last record (clamped 0–72)
        choke,                -- choked ticks (clamped 0–72)
        cycle,                -- ticks between server updates
        shifting,             -- ticks shifted forward (doubletap)
        no_entry              -- vector: x = shifted_forwards, y = max_shifted
    }
}
```

---

## Defensive Detection (Standalone Snippet)

If you only need to check if the local player is under a defensive effect without the full library:

```lua
local max_tickbase = 0

local function on_createmove(cmd)
    local me = entity.get_local_player()
    local tickbase = me.m_nTickBase

    if math.abs(tickbase - max_tickbase) > 64 then
        max_tickbase = 0
    end

    local defensive_ticks_left = 0

    if tickbase > max_tickbase then
        max_tickbase = tickbase
    elseif max_tickbase > tickbase then
        defensive_ticks_left = math.min(14, math.max(0, max_tickbase - tickbase - 1))
    end

    print_dev(defensive_ticks_left)
end

events.createmove(on_createmove)
```

---

## Example

```lua
local lagrecord = require 'lagrecord'

lagrecord.set_update_callback(function(player)
    if player == entity.get_local_player() then
        return true  -- force-write entries for local player
    end
end)

events.createmove(function()
    local me = entity.get_local_player()
    local snapshot = lagrecord.get_snapshot(me)

    if snapshot == nil then return end

    local shifting   = snapshot.command.shifting
    local defensive  = snapshot.command.no_entry

    print_dev(string.format(
        'records: %d | shifting: %d | defensive: [current: %d / max: %d]',
        #lagrecord.get_all(me),
        shifting,
        defensive.x, defensive.y
    ))
end)
```

---

## License

This library is licensed under the **GNU General Public License v3.0**.  
Copyright (C) 2022 Salvatore (tickcount)

For full license terms, please see the [original repository](https://github.com/tickcount/lagrecord-csgo.lua/blob/main/LICENSE).
