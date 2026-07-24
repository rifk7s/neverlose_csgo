<div align="center">

<img src="https://docs-csgo.neverlose.cc/~gitbook/image?url=https%3A%2F%2F3594665820-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252F37PG3extaxoGL9yvcP52%252Fuploads%252Fgit-blob-ad4a5f975f48e44b83ae58878e94dc0ee1652235%252Flogo.png%3Falt%3Dmedia&width=400&dpr=3&quality=100&sign=d8baa817&sv=2" alt="Neverlose" height="60" />

<br/>
<br/>

[![Platform](https://img.shields.io/badge/Platform-Neverlose%20CSGO-0a84ff?style=flat-square)](https://neverlose.cc)
[![Language](https://img.shields.io/badge/Language-Lua%20%28LuaJIT%202.1%29-7c3aed?style=flat-square&logo=lua&logoColor=white)](https://docs-csgo.neverlose.cc)
[![Docs](https://img.shields.io/badge/API%20Docs-docs--csgo.neverlose.cc-16a34a?style=flat-square)](https://docs-csgo.neverlose.cc)
[![Scripts](https://img.shields.io/badge/Scripts-7-orange?style=flat-square)](lua/)
[![Nade Packs](https://img.shields.io/badge/Nade%20Packs-9-red?style=flat-square)](nade_helper_locations/)

<br/>

A personal collection of Lua scripts, presets, and grenade location packs for **[Neverlose](https://neverlose.cc)** — the CSGO scripting platform powered by LuaJIT 2.1.

</div>

---

## Platform

<table>
<tr>
<td width="80" align="center" valign="middle">
<img src="https://docs-csgo.neverlose.cc/~gitbook/image?url=https%3A%2F%2F3594665820-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252F37PG3extaxoGL9yvcP52%252Ficon%252FgagqH1SZSihxzt0KJuvs%252Fneverlose_black.png%3Falt%3Dmedia%26token%3Dd25e919b-cb37-4a9e-84ac-6080f45827d5&width=32&dpr=1&quality=100&sign=688f41f1&sv=2" width="64" alt="NL" />
</td>
<td>

**Neverlose** is a unique CSGO software providing huge functionality and easy setup, with a fast and friendly support team. Scripts run on a full **LuaJIT 2.1** runtime, with access to a comprehensive built-in API covering rendering, entity access, ragebot overrides, FFI memory access, and more.

**Script location:** `<CS:GO Install>/nl/scripts/`

</td>
</tr>
</table>

### API Modules

<table>
<thead>
<tr>
<th>Module</th>
<th>Description</th>
<th>Docs</th>
</tr>
</thead>
<tbody>
<tr><td><code>ui</code></td><td>Menu elements — sidebar, switches, combos, sliders, buttons, labels, color pickers, tooltips</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/ui">ui →</a></td></tr>
<tr><td><code>render</code></td><td>Screen drawing — text, rectangles, gradients, textures, fonts, SVG images, screen size</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/render">render →</a></td></tr>
<tr><td><code>entity</code></td><td>Player entities — local player, enemy list, dormancy, health, velocity, eye position, player info</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/entity">entity →</a></td></tr>
<tr><td><code>events</code></td><td>Event hooks — <code>render</code>, <code>createmove</code>, <code>aim_fire</code>, <code>aim_ack</code>, <code>aim_miss</code>, <code>net_update_start</code>, <code>round_start</code>, <code>shutdown</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/events">events →</a></td></tr>
<tr><td><code>globals</code></td><td>Game state — <code>tickcount</code>, <code>curtime</code>, <code>tickinterval</code>, <code>frametime</code>, <code>is_in_game</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/globals">globals →</a></td></tr>
<tr><td><code>rage</code></td><td>Ragebot and antiaim API — overrides, target info, current threat</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/rage">rage →</a></td></tr>
<tr><td><code>plist</code></td><td>Per-player overrides — body aim, safepoint, min damage per target index</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/plist">plist →</a></td></tr>
<tr><td><code>utils</code></td><td>Utilities — <code>trace_line</code>, <code>execute_after</code>, net channel access, interfaces</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/utils">utils →</a></td></tr>
<tr><td><code>color</code></td><td>Color constructor: <code>color(r, g, b, a)</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/color">color →</a></td></tr>
<tr><td><code>vector</code></td><td>2D/3D vector math: <code>vector(x, y)</code> or <code>vector(x, y, z)</code>, <code>:length()</code>, <code>:normalized()</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/vector">vector →</a></td></tr>
<tr><td><code>cvar</code></td><td>Console variable read/write — e.g. <code>cl_updaterate</code>, <code>avg_latency</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/cvar">cvar →</a></td></tr>
<tr><td><code>common</code></td><td>Utility functions — <code>get_username</code>, string helpers</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/common">common →</a></td></tr>
<tr><td><code>network</code></td><td>HTTP GET/POST requests</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/network">network →</a></td></tr>
<tr><td><code>json</code></td><td>JSON <code>parse</code> and <code>stringify</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/json">json →</a></td></tr>
<tr><td><code>files</code></td><td>File I/O — read, write, list directories</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/files">files →</a></td></tr>
<tr><td><code>materials</code></td><td>Material creation and modification for model rendering</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/materials">materials →</a></td></tr>
<tr><td><code>panorama</code></td><td>Panorama JS evaluation — e.g. <code>SteamOverlayAPI.OpenExternalBrowserURL</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/panorama">panorama →</a></td></tr>
<tr><td><code>esp</code></td><td>ESP callbacks for custom player/entity overlays</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/esp">esp →</a></td></tr>
<tr><td><code>db</code></td><td>Player database — persistent per-player storage</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/db">db →</a></td></tr>
<tr><td><code>ffi</code></td><td><strong>LuaJIT FFI</strong> — call external C functions, read/write raw memory, define and cast structs via <code>ffi.cdef</code> / <code>ffi.cast</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/ffi">ffi →</a></td></tr>
<tr><td><code>bit</code></td><td><strong>BitOp</strong> — bitwise operations on numbers: <code>band</code>, <code>bor</code>, <code>bxor</code>, <code>bnot</code>, <code>lshift</code>, <code>rshift</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/bit">bit →</a></td></tr>
</tbody>
</table>

> **Full docs:** [docs-csgo.neverlose.cc](https://docs-csgo.neverlose.cc) &nbsp;·&nbsp; **Quick start:** [Quick Start Guide](https://docs-csgo.neverlose.cc/useful-information/quick-start) &nbsp;·&nbsp; **Examples:** [Script Examples](https://docs-csgo.neverlose.cc/useful-information/script-examples)

---

## Scripts (`lua/`)

### `nightsense.lua`

[![Type](https://img.shields.io/badge/Type-Resolver%20%2F%20Ragebot-dc2626?style=flat-square)](lua/nightsense.lua)
[![FFI](https://img.shields.io/badge/Uses-FFI-ea580c?style=flat-square)](https://docs-csgo.neverlose.cc/documentation/variables/ffi)
[![Size](https://img.shields.io/badge/Size-41%20KB-555?style=flat-square)](lua/nightsense.lua)

Advanced resolver support script for Neverlose ragebot. Reads animation state memory directly via FFI and feeds evidence-based plist overrides into the ragebot on each tick.

<table>
<tr>
<td valign="top" width="50%">

**Features**
- Resolver Support — evidence-based yaw correction overrides
- Anti-Defensive — detects defensive AA and forces body aim / safe points
- Lethal BAIM — forces body aim based on confidence + target HP
- Adaptive Safepoint — activates on low confidence, high choke, or LC instability
- Target Priority — scores targets by threat, visibility, lethality, and resolver confidence

</td>
<td valign="top" width="50%">

**Architecture**
- Animation state via FFI (`animation_state_t`, `animation_layer_t` at offset `0x9960` / `0x2990`)
- `shot_matrix` — per-SteamID shot memory, 1000 entry history, per-state accuracy
- LC states: `LC_NORMAL` `LC_SHIFTED` `LC_BROKEN` `LC_TELEPORT`
- Archetypes: `ARC_STATIC` `ARC_JITTER` `ARC_MICRO_JITTER` `ARC_DEFENSIVE` `ARC_RANDOM` `ARC_FREESTAND`
- `predictTargetMovement` — velocity history + trace for peek prediction
- Full `plist` cleanup on player death, round start, and shutdown

</td>
</tr>
</table>

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `plist` · `utils` · `color` · `vector` · `common` · `network` · `json` · `panorama` · `ffi`

---

### `ONETAP INTERFACES_7072605.lua`

[![Type](https://img.shields.io/badge/Type-HUD%20Overlay-2563eb?style=flat-square)](lua/ONETAP%20INTERFACES_7072605.lua)
[![Size](https://img.shields.io/badge/Size-523%20KB-555?style=flat-square)](lua/ONETAP%20INTERFACES_7072605.lua)

Custom Onetap-inspired HUD overlay rendering keybinds, spectator list, watermark, warnings, and hit markers on screen. SVG assets are loaded via `render.load_image` at startup for zero-overhead rendering.

<table>
<tr>
<td valign="top" width="50%">

**Features**
- Watermark — username, server address, ping via `cvar.cl_updaterate` + `avg_latency`
- Keybind list — toggle mode shows filled icon, hold mode shows `hold_icon` (keyboard SVG)
- Spectator list — names of players spectating you
- Velocity warning indicator
- Defensive tickbase warning indicator
- Hit markers — damage display with fading alpha and overlap deduplication

</td>
<td valign="top" width="50%">

**Display Modes**
- `Normale` — all elements visible
- `Customizable` — each element toggled individually via the menu

**Fixes**
- Ping calculation using `avg_latency[1]` minus half the updaterate interval
- Hit marker overlap — older text hidden when a newer nearby hit exists

</td>
</tr>
</table>

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `cvar` · `color` · `vector`

---

### `Arc_7075732.lua`

[![Type](https://img.shields.io/badge/Type-Visuals-2563eb?style=flat-square)](lua/Arc_7075732.lua)
[![Size](https://img.shields.io/badge/Size-294%20KB-555?style=flat-square)](lua/Arc_7075732.lua)

**APIs used:** `ui` · `render` · `entity` · `events` · `color` · `vector`

---

### `Chimera AlphaS_7076881.lua`

[![Type](https://img.shields.io/badge/Type-Multi--feature-2563eb?style=flat-square)](<lua/Chimera%20AlphaS_7076881.lua>)
[![FFI](https://img.shields.io/badge/Uses-FFI-ea580c?style=flat-square)](https://docs-csgo.neverlose.cc/documentation/variables/ffi)
[![Size](https://img.shields.io/badge/Size-423%20KB-555?style=flat-square)](<lua/Chimera%20AlphaS_7076881.lua>)

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `rage` · `color` · `vector` · `common` · `ffi`

---

### `Cloud Model Changer_7073630.lua`

[![Type](https://img.shields.io/badge/Type-Visuals-2563eb?style=flat-square)](<lua/Cloud%20Model%20Changer_7073630.lua>)
[![Size](https://img.shields.io/badge/Size-126%20KB-555?style=flat-square)](<lua/Cloud%20Model%20Changer_7073630.lua>)

Dynamically changes player and weapon models in-game.

**APIs used:** `ui` · `render` · `entity` · `events` · `materials` · `color`

---

### `Custom Weapon Sound_7076127.lua`

[![Type](https://img.shields.io/badge/Type-Audio-2563eb?style=flat-square)](<lua/Custom%20Weapon%20Sound_7076127.lua>)
[![Size](https://img.shields.io/badge/Size-27%20KB-555?style=flat-square)](<lua/Custom%20Weapon%20Sound_7076127.lua>)

Replaces weapon fire sounds with custom audio variants. Each weapon is keyed by item definition index and supports four sound profiles:

| Profile | Example path |
|---------|-------------|
| `CS2` | `weapons/awp/awp_01.wav` |
| `CS:Source` | `css/awp.wav` |
| `CS:GO (legacy)` | `legacy/awp.wav` |
| `CS:GO` | multi-sample array `[1]`, `[2]`, `[3]` |
| `Custom` | user-specified path |

Weapons covered: AWP, SCAR-20, G3SG1, Deagle, R8, and more.

**APIs used:** `ui` · `entity` · `events` · `common`

---

### `HitsoundFix_7074789.lua`

[![Type](https://img.shields.io/badge/Type-Audio%20Fix-2563eb?style=flat-square)](lua/HitsoundFix_7074789.lua)
[![FFI](https://img.shields.io/badge/Uses-FFI-ea580c?style=flat-square)](https://docs-csgo.neverlose.cc/documentation/variables/ffi)
[![Size](https://img.shields.io/badge/Size-6%20KB-555?style=flat-square)](lua/HitsoundFix_7074789.lua)

Raises the engine sound channel limit via FFI to prevent hitsounds from being dropped under rapid fire rates. Patches the limit value directly in memory at load.

**APIs used:** `events` · `ffi`

---

## Settings (`lua_setts/`)

Exported Neverlose config presets. Import via the Neverlose settings panel.

<table>
<thead>
<tr><th>File</th><th>Size</th><th>Description</th></tr>
</thead>
<tbody>
<tr><td><code>as.txt</code></td><td>21 KB</td><td>General config preset</td></tr>
<tr><td><code>chimera-preset.txt</code></td><td>14 KB</td><td>Chimera AlphaS config preset</td></tr>
<tr><td><code>jagoyaw.txt</code></td><td>13 KB</td><td>Yaw / antiaim config preset</td></tr>
</tbody>
</table>

---

## Grenade Locations (`nade_helper_locations/`)

JSON location packs for use with Neverlose's built-in nade helper. Each file contains named throw positions, view angles, grenade types, and throw instructions. Load via the Neverlose nade helper interface.

<table>
<thead>
<tr><th>File</th><th>Size</th><th>Coverage</th></tr>
</thead>
<tbody>
<tr><td><code>nadehelper_all_maps_primary.txt</code></td><td>3.5 MB</td><td>All maps — primary location pack</td></tr>
<tr><td><code>nadehelper_all_maps_secondary.txt</code></td><td>640 KB</td><td>All maps — secondary location pack</td></tr>
<tr><td><code>nadehelper_all_maps_3.txt</code></td><td>625 KB</td><td>27 maps — additional pack</td></tr>
<tr><td><code>nadehelper_all_maps_4.txt</code></td><td>1.4 MB</td><td>30 maps — includes <code>de_anubis</code>, <code>cs_militia</code>, <code>de_cache_old</code></td></tr>
<tr><td><code>nadehelper_mirage_locs.txt</code></td><td>42 KB</td><td><code>de_mirage</code> specific</td></tr>
<tr><td><code>nadehelper_mirage_locs_2.txt</code></td><td>112 KB</td><td><code>de_mirage</code> extended</td></tr>
<tr><td><code>nadehelper_vertigo_locs.txt</code></td><td>241 KB</td><td><code>de_vertigo</code> specific</td></tr>
<tr><td><code>cs_office_night_locations.txt</code></td><td>82 KB</td><td><code>cs_office</code> night variant</td></tr>
<tr><td><code>de_dust2_old_locations.txt</code></td><td>66 KB</td><td><code>de_dust2_old</code> legacy variant</td></tr>
</tbody>
</table>

---

## Notes

<table>
<tr>
<td width="32"><img src="https://img.shields.io/badge/-LuaJIT-7c3aed?style=flat-square&logo=lua&logoColor=white" alt="lua" /></td>
<td>Scripts use <strong>LuaJIT 2.1</strong> — the JIT compiler bundled with Neverlose. Standard Lua 5.1 syntax applies with JIT extensions.</td>
</tr>
<tr>
<td><img src="https://img.shields.io/badge/-FFI-ea580c?style=flat-square&logo=c&logoColor=white" alt="ffi" /></td>
<td><strong><a href="https://docs-csgo.neverlose.cc/documentation/variables/ffi">FFI</a></strong> is used for direct memory access — reading animation state structs, patching sound limits, casting pointers. Define structs with <code>ffi.cdef</code> and cast with <code>ffi.cast</code>.</td>
</tr>
<tr>
<td><img src="https://img.shields.io/badge/-BitOp-555?style=flat-square&logo=buffer&logoColor=white" alt="bit" /></td>
<td><strong><a href="https://docs-csgo.neverlose.cc/documentation/variables/bit">BitOp (<code>bit</code>)</a></strong> provides bitwise operations on numbers: <code>bit.band</code>, <code>bit.bor</code>, <code>bit.bxor</code>, <code>bit.bnot</code>, <code>bit.lshift</code>, <code>bit.rshift</code>.</td>
</tr>
<tr>
<td><img src="https://img.shields.io/badge/-Docs-16a34a?style=flat-square&logo=gitbook&logoColor=white" alt="docs" /></td>
<td>Arguments shown in <code>[square brackets]</code> in the Neverlose API docs are optional.</td>
</tr>
<tr>
<td><img src="https://img.shields.io/badge/-Note-dc2626?style=flat-square&logo=shieldsdotio&logoColor=white" alt="note" /></td>
<td>These scripts are for personal use on the Neverlose platform only.</td>
</tr>
</table>

---

## References

<div align="center">

<img src="https://docs-csgo.neverlose.cc/~gitbook/image?url=https%3A%2F%2F3594665820-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252F37PG3extaxoGL9yvcP52%252Ficon%252FgagqH1SZSihxzt0KJuvs%252Fneverlose_black.png%3Falt%3Dmedia%26token%3Dd25e919b-cb37-4a9e-84ac-6080f45827d5&width=32&dpr=1&quality=100&sign=688f41f1&sv=2" width="24" alt="NL" />

[Neverlose Documentation](https://docs-csgo.neverlose.cc) &nbsp;·&nbsp;
[Quick Start](https://docs-csgo.neverlose.cc/useful-information/quick-start) &nbsp;·&nbsp;
[Script Examples](https://docs-csgo.neverlose.cc/useful-information/script-examples) &nbsp;·&nbsp;
[Common Knowledge](https://docs-csgo.neverlose.cc/useful-information/common-knowledge) &nbsp;·&nbsp;
[Official Website](https://neverlose.cc)

</div>
