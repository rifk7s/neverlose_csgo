<div align="center">

<img src="https://docs-csgo.neverlose.cc/~gitbook/image?url=https%3A%2F%2F3594665820-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252F37PG3extaxoGL9yvcP52%252Fuploads%252Fgit-blob-ad4a5f975f48e44b83ae58878e94dc0ee1652235%252Flogo.png%3Falt%3Dmedia&width=400&dpr=3&quality=100&sign=d8baa817&sv=2" alt="Neverlose" height="60" />

<br/>
<br/>

[![Platform](https://img.shields.io/badge/Platform-Neverlose%20CSGO-0a84ff?style=flat-square)](https://neverlose.cc)
[![Language](https://img.shields.io/badge/Language-Lua%20%28LuaJIT%202.1%29-7c3aed?style=flat-square&logo=lua&logoColor=white)](https://docs-csgo.neverlose.cc)
[![Docs](https://img.shields.io/badge/API%20Docs-docs--csgo.neverlose.cc-16a34a?style=flat-square)](https://docs-csgo.neverlose.cc)
![Scripts](https://img.shields.io/github/directory-file-count/rifk7s/neverlose_csgo/lua?type=file&label=Scripts&color=orange&style=flat-square)
![Nade Packs](https://img.shields.io/github/directory-file-count/rifk7s/neverlose_csgo/nade_helper_locations?type=file&label=Nade%20Packs&color=red&style=flat-square)

<br/>

A personal collection of Lua scripts, presets, and grenade location packs for **[Neverlose](https://neverlose.cc)**, the CSGO scripting platform powered by LuaJIT 2.1.

</div>

---

## Platform

<table width="100%">
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

<table width="100%">
<thead>
<tr>
<th>Module</th>
<th>Description</th>
<th>Docs</th>
</tr>
</thead>
<tbody>
<tr><td><code>ui</code></td><td>Menu elements: sidebar, switches, combos, sliders, buttons, labels, color pickers, tooltips</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/ui">ui &rarr;</a></td></tr>
<tr><td><code>render</code></td><td>Screen drawing: text, rectangles, gradients, textures, fonts, SVG images, screen size</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/render">render &rarr;</a></td></tr>
<tr><td><code>entity</code></td><td>Player entities: local player, enemy list, dormancy, health, velocity, eye position, player info</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/entity">entity &rarr;</a></td></tr>
<tr><td><code>events</code></td><td>Event hooks: <code>render</code>, <code>createmove</code>, <code>aim_fire</code>, <code>aim_ack</code>, <code>aim_miss</code>, <code>net_update_start</code>, <code>round_start</code>, <code>shutdown</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/events">events &rarr;</a></td></tr>
<tr><td><code>globals</code></td><td>Game state: <code>tickcount</code>, <code>curtime</code>, <code>tickinterval</code>, <code>frametime</code>, <code>is_in_game</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/globals">globals &rarr;</a></td></tr>
<tr><td><code>rage</code></td><td>Ragebot and antiaim API: overrides, target info, current threat</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/rage">rage &rarr;</a></td></tr>
<tr><td><code>plist</code></td><td>Per-player overrides: body aim, safepoint, min damage per target index</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/plist">plist &rarr;</a></td></tr>
<tr><td><code>utils</code></td><td>Utilities: <code>trace_line</code>, <code>execute_after</code>, net channel access, interfaces</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/utils">utils &rarr;</a></td></tr>
<tr><td><code>color</code></td><td>Color constructor: <code>color(r, g, b, a)</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/color">color &rarr;</a></td></tr>
<tr><td><code>vector</code></td><td>2D/3D vector math: <code>vector(x, y)</code> or <code>vector(x, y, z)</code>, <code>:length()</code>, <code>:normalized()</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/vector">vector &rarr;</a></td></tr>
<tr><td><code>cvar</code></td><td>Console variable read/write: e.g. <code>cl_updaterate</code>, <code>avg_latency</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/cvar">cvar &rarr;</a></td></tr>
<tr><td><code>common</code></td><td>Utility functions: <code>get_username</code>, string helpers</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/common">common &rarr;</a></td></tr>
<tr><td><code>network</code></td><td>HTTP GET/POST requests</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/network">network &rarr;</a></td></tr>
<tr><td><code>json</code></td><td>JSON <code>parse</code> and <code>stringify</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/json">json &rarr;</a></td></tr>
<tr><td><code>files</code></td><td>File I/O: read, write, list directories</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/files">files &rarr;</a></td></tr>
<tr><td><code>materials</code></td><td>Material creation and modification for model rendering</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/materials">materials &rarr;</a></td></tr>
<tr><td><code>panorama</code></td><td>Panorama JS evaluation: e.g. <code>SteamOverlayAPI.OpenExternalBrowserURL</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/panorama">panorama &rarr;</a></td></tr>
<tr><td><code>esp</code></td><td>ESP callbacks for custom player/entity overlays</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/esp">esp &rarr;</a></td></tr>
<tr><td><code>db</code></td><td>Player database: persistent per-player storage</td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/db">db &rarr;</a></td></tr>
<tr><td><code>ffi</code></td><td><strong>LuaJIT FFI</strong>: call external C functions, read/write raw memory, define and cast structs via <code>ffi.cdef</code> / <code>ffi.cast</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/ffi">ffi &rarr;</a></td></tr>
<tr><td><code>bit</code></td><td><strong>BitOp</strong>: bitwise operations on numbers: <code>band</code>, <code>bor</code>, <code>bxor</code>, <code>bnot</code>, <code>lshift</code>, <code>rshift</code></td><td><a href="https://docs-csgo.neverlose.cc/documentation/variables/bit">bit &rarr;</a></td></tr>
</tbody>
</table>

> **Full docs:** [docs-csgo.neverlose.cc](https://docs-csgo.neverlose.cc) &nbsp;&middot;&nbsp; **Quick start:** [Quick Start Guide](https://docs-csgo.neverlose.cc/useful-information/quick-start) &nbsp;&middot;&nbsp; **Examples:** [Script Examples](https://docs-csgo.neverlose.cc/useful-information/script-examples)

---

## Scripts (`lua/`)

### `nightsense.lua`

[![Type](https://img.shields.io/badge/Type-Resolver%20%2F%20Ragebot-dc2626?style=flat-square)](lua/nightsense.lua)
[![FFI](https://img.shields.io/badge/Uses-FFI-ea580c?style=flat-square)](https://docs-csgo.neverlose.cc/documentation/variables/ffi)
[![Size](https://img.shields.io/badge/Size-76%20KB-555?style=flat-square)](lua/nightsense.lua)

Advanced resolver support script for Neverlose ragebot. Reads animation state memory directly via FFI and feeds evidence-based overrides into the ragebot on each tick. Forked from ImSynZx's original with a full resolver core rewrite, prediction system, and new ring-buffer shot tracking.

<table width="100%">
<tr>
<td valign="top" width="50%">

**Features**
- Resolver Support: evidence-based yaw correction overrides
- Anti-Defensive: detects defensive AA and forces body aim / safe points
- Lethal BAIM: forces body aim based on confidence + target HP
- Adaptive Safepoint: activates on low confidence, high choke, or LC instability
- Target Priority: scores targets by threat, visibility, lethality, and resolver confidence
- Ideal Tick Detection: detects exploit usage (DT, HS, FD) on enemies
- IT Min-Damage Override: auto-halves min damage for auto-snipers against exploit users
- Exploit Visualization: ESP overlay for detected tickbase manipulation

</td>
<td valign="top" width="50%">

**Architecture**
- Animation state via FFI (`animation_state_t`, `animation_layer_t` at offset `0x9960` / `0x2990`)
- Ring buffer shot tracking (`SHOT_BUF_SIZE = 32`) replacing legacy 1000-entry `shot_matrix`
- Recency-weighted side rate (`RECENCY_DECAY = 0.85`) for per-side hit/miss analysis
- 10 pattern classifications: `PAT_STATIC` `PAT_MICRO_JIT` `PAT_JITTER` `PAT_DELAYED_JIT` `PAT_RANDOM_JIT` `PAT_FLICK` `PAT_FAKE_FLICK` `PAT_SPIN` `PAT_DEFENSIVE` `PAT_HYBRID`
- Circular yaw buffer (`YAW_BUF_SIZE = 12`) per player for pattern detection
- `table_pool` recycling system (100-table cap) to reduce GC pressure
- Full cleanup on player death, round start, and shutdown

</td>
</tr>
</table>

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `rage` · `plist` · `utils` · `color` · `vector` · `common` · `network` · `json` · `panorama` · `esp` · `ffi`

---

### `ideal_yaw.lua`

[![Type](https://img.shields.io/badge/Type-Anti--Aim-dc2626?style=flat-square)](lua/ideal_yaw.lua)
[![Size](https://img.shields.io/badge/Size-234%20KB-555?style=flat-square)](lua/ideal_yaw.lua)

Full-featured anti-aim and yaw configuration script. Includes builder-based AA presets, visual customization, ragebot extensions, and miscellaneous utilities. Originally by Kizaru.

<table width="100%">
<tr>
<td valign="top" width="50%">

**Anti-Aim**
- Mode: Builder, Center, Meta, Hybrid
- Tweaks: Legit AA on Use, Fast Ladder, No Fall Damage
- Edge Yaw + Manual Arrows
- Safe Head per condition
- Defensive AA with pitch, yaw, and disablers
- Animation Breaker + Freestand disablers

</td>
<td valign="top" width="50%">

**Ragebot + Visuals**
- Aimbot Logs, Hitchance Modification
- Automatic Teleport + Ideal Peek
- Widgets, Crosshair Indicators, GameSense UI
- 3D Hitmarker, Shot Marker, Damage Marker
- Custom Scope, Aspect Ratio, Viewmodel
- Clantag Spammer + Trashtalk

</td>
</tr>
</table>

**Misc:** Taskbar Notify on Round Start, Reveal Ideal Yaw Users, Unmute Muted Players, Console Color Modulation

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `rage` · `utils` · `color` · `vector` · `cvar` · `common` · `json` · `materials` · `ffi` · `bit`

---

### `Chimera AlphaS_7076881.lua`

[![Type](https://img.shields.io/badge/Type-Multi--feature-dc2626?style=flat-square)](<lua/Chimera%20AlphaS_7076881.lua>)
[![FFI](https://img.shields.io/badge/Uses-FFI-ea580c?style=flat-square)](https://docs-csgo.neverlose.cc/documentation/variables/ffi)
[![Size](https://img.shields.io/badge/Size-415%20KB-555?style=flat-square)](<lua/Chimera%20AlphaS_7076881.lua>)

Early access branch of Chimera.lua. Comprehensive multi-feature script covering ragebot enhancements, full anti-aim builder, visual indicators, and miscellaneous utilities. Features per-condition AA presets, dormant aimbot, AI peek simulation, and more.

<table width="100%">
<tr>
<td valign="top" width="33%">

**General**
- Noscope Mode: Hitchance, Distance, Weapons
- In Air Mode: Hitchance, Weapons
- Animation Fix Breaker: Landing Pitch, Force Falling, Move Lean, Leg Breaker, Sliding on Slow Walk
- Ideal Tick: Auto Peek, Double Tap, Freestanding, Jump Scout
- Magic Key (Only Head mode)
- Dormant Aimbot: Target Selection, Hit Chance, Min Damage, Timeout, Auto Scope, Auto Stop
- AI Peek: Simulation, Rate Limit, Weapons, Color

</td>
<td valign="top" width="33%">

**Anti-Aims**
- Presets: Classic Jitter, Delayed Jitter, Chester's Cider, Conditional
- Per-condition builder: Standing, Moving, Slowwalking, Crouching, In Air, In Air + Crouching, On Use
- Manual Yaw, Freestanding, Avoid Backstab
- Defensive AA: Pitch, Yaw, Disablers, Edge Manual Yaw
- Safe Head per stance
- Disable Fake Lag per weapon/state
- Automatic Teleport, Force Break LC
- Fluctuate Fake Lag, Aerobic Lag Exploit
- Leg Breaker, Extended Angles

</td>
<td valign="top" width="33%">

**Visuals + Misc**
- Better Scope Overlay
- Hit Marker: Screen, World, Damage
- 500$ Indicators (12+ states)
- DT Based Peek Assist Color
- Anti Aim Arrows + Crosshair Indicators
- Logs: Chimera, Console Panel
- Zeus Warning, Viewmodel Changer
- Ragdoll Animation, Keep Scope Transparency
- Clan Tag Spammer, Talk Shit
- Aspect Ratio, Quick Nade, Super Toss
- Config: Import/Export/Default

</td>
</tr>
</table>

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `rage` · `utils` · `color` · `vector` · `cvar` · `common` · `json` · `files` · `materials` · `panorama` · `esp` · `db` · `ffi` · `bit`

---

### `Arc_7075732.lua`

[![Type](https://img.shields.io/badge/Type-Visuals%20%2F%20Movement-2563eb?style=flat-square)](lua/Arc_7075732.lua)
[![Size](https://img.shields.io/badge/Size-287%20KB-555?style=flat-square)](lua/Arc_7075732.lua)

Feature-rich visuals and movement enhancement script. Provides functionality and performance improvements across movement mechanics, world rendering, and weapon visuals.

<table width="100%">
<tr>
<td valign="top" width="50%">

**Movement / Weapon**
- Avoid Collisions (gamesense replica)
- No Fall Damage (gamesense replica)
- Fast Ladder + Fast Walk
- Edge Quick Stop (works best with Peek Assist)
- Collision Air Duck (auto-duck to avoid collision)
- Super Toss + Quick Throw (gamesense replicas)
- Quick Interactions (Quick Plant / Quick Hostage Take)
- Automatic Grenade Release

</td>
<td valign="top" width="50%">

**World / Visuals**
- Weather Controller
- CS:S Viewmodel Animations
- Keep Scope Transparency (gamesense replica)
- Ambient / Weapon Texture (Chams) changer
- Disable Teammate/Ragdoll/Blood rendering
- Exploit Visualization
- Enhanced Game Focus: Tab to Game
- Enhanced Player Name Stealer
- Network Metrics (enhanced `net_graph`)
- Grenade Trajectory + Proximity Warning (gamesense replicas)
- Inaccuracy Overlay + Cheat Revealer
- Local player animation interpolation + animation breakers

</td>
</tr>
</table>

> **Note:** Weather Controller is not compatible with Force Game Interpolation and some other features, may cause crashes due to Source engine issues.

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `rage` · `utils` · `color` · `vector` · `cvar` · `common` · `json` · `materials` · `panorama` · `ffi` · `bit`

---

### `ONETAP INTERFACES_7072605.lua`

[![Type](https://img.shields.io/badge/Type-HUD%20Overlay-2563eb?style=flat-square)](lua/ONETAP%20INTERFACES_7072605.lua)
[![Size](https://img.shields.io/badge/Size-523%20KB-555?style=flat-square)](lua/ONETAP%20INTERFACES_7072605.lua)

Custom Onetap-inspired HUD overlay rendering keybinds, spectator list, watermark, warnings, and hit markers on screen. SVG assets are loaded via `render.load_image` at startup for zero-overhead rendering.

<table width="100%">
<tr>
<td valign="top" width="50%">

**Features**
- Watermark: username, server address, ping via `cvar.cl_updaterate` + `avg_latency`
- Keybind list: toggle mode shows filled icon, hold mode shows `hold_icon` (keyboard SVG)
- Spectator list: names of players spectating you
- Velocity warning indicator
- Defensive tickbase warning indicator
- Hit markers: damage display with fading alpha and overlap deduplication

</td>
<td valign="top" width="50%">

**Display Modes**
- `Normale`: all elements visible
- `Customizable`: each element toggled individually via the menu

**Fixes**
- Ping calculation using `avg_latency[1]` minus half the updaterate interval
- Hit marker overlap: older text hidden when a newer nearby hit exists

</td>
</tr>
</table>

**APIs used:** `ui` · `render` · `entity` · `events` · `globals` · `utils` · `color` · `vector` · `cvar` · `common`

---

### `Cloud Model Changer_7073630.lua`

[![Type](https://img.shields.io/badge/Type-Visuals-2563eb?style=flat-square)](<lua/Cloud%20Model%20Changer_7073630.lua>)
[![Size](https://img.shields.io/badge/Size-126%20KB-555?style=flat-square)](<lua/Cloud%20Model%20Changer_7073630.lua>)

Most advanced model changer on the market. Dynamically changes player and weapon models in-game with preset models, active crash protection, and a robust PowerShell-based downloader for reliable custom model retrieval.

<table width="100%">
<tr>
<td valign="top" width="50%">

**Features**
- Agent Changer (separate T + CT)
- Mask Changer
- Viewmodel Changer
- Attachment Hider
- Weapon Model Changer

</td>
<td valign="top" width="50%">

**Model System**
- Separate T + CT options
- Presets / Favorites / Custom lists
- Presets auto-download without game freezes
- Inbuilt crash prevention
- Masks will NOT flicker with custom models
- One-click reset for weapon models
- Fixed by Dc: .rifk

</td>
</tr>
</table>

**APIs used:** `ui` · `entity` · `events` · `utils` · `common` · `files` · `panorama` · `db` · `ffi`

---

### `Custom Weapon Sound_7076127.lua`

[![Type](https://img.shields.io/badge/Type-Audio-2563eb?style=flat-square)](<lua/Custom%20Weapon%20Sound_7076127.lua>)
[![Size](https://img.shields.io/badge/Size-27%20KB-555?style=flat-square)](<lua/Custom%20Weapon%20Sound_7076127.lua>)

Custom weapon sounds that replace the normal sounds with no overlap or delay. Supports preset sound packs and a per-weapon custom builder.

<table width="100%">
<tr>
<td valign="top" width="50%">

**Sound Profiles**

| Profile | Example path |
|---------|-------------|
| `CS2` | `weapons/awp/awp_01.wav` |
| `CS:Source` | `css/awp.wav` |
| `CS:GO (legacy)` | `legacy/awp.wav` |
| `CS:GO` | multi-sample array `[1]`, `[2]`, `[3]` |
| `Custom` | user-specified path |

</td>
<td valign="top" width="50%">

**Features**
- Preset Sounds: select a sound style (CS2, CS:GO-legacy, CS:Source) to apply for all weapons
- Custom Builder: advanced per-weapon sound builder with custom volume
- All preset sounds auto-download
- Only local sounds are changed
- Good for clips, no sounds need to be edited in
- Background shell download via `cmd.exe` pipeline (replaces legacy sync loop)

</td>
</tr>
</table>

**APIs used:** `ui` · `entity` · `events` · `utils` · `cvar` · `common` · `panorama` · `ffi`

---

### `Config Import_7076547.lua`

[![Type](https://img.shields.io/badge/Type-Utility-2563eb?style=flat-square)](<lua/Config%20Import_7076547.lua>)
[![Size](https://img.shields.io/badge/Size-8%20KB-555?style=flat-square)](<lua/Config%20Import_7076547.lua>)

Utility script to import and parse configuration strings (e.g., from clipboard or base64). Requires `.txt` config files to be placed in `nl/configs/` to function correctly.

**APIs used:** `ui` · `json` · `ffi` · `bit`

---

### `HitsoundFix_7074789.lua`

[![Type](https://img.shields.io/badge/Type-Audio%20Fix-2563eb?style=flat-square)](lua/HitsoundFix_7074789.lua)
[![FFI](https://img.shields.io/badge/Uses-FFI-ea580c?style=flat-square)](https://docs-csgo.neverlose.cc/documentation/variables/ffi)
[![Size](https://img.shields.io/badge/Size-6%20KB-555?style=flat-square)](lua/HitsoundFix_7074789.lua)

Raises the engine sound channel limit via FFI to prevent hitsounds from being dropped under rapid fire rates. Patches the limit value directly in memory at load. Volume slider supports up to 500%.

**APIs used:** `ui` · `entity` · `events` · `ffi`

---

## Configs (`configs/`)

Neverlose config presets for use with `Config Import_7076547.lua`. Place these files in `<CS:GO Install>/nl/configs/` and use the Config Import script to load them.

<table width="100%">
<thead>
<tr><th>File</th><th>Size</th><th>Description</th></tr>
</thead>
<tbody>
<tr><td><code>Kucjlota.txt</code></td><td>156 KB</td><td>Kucjlota config preset</td></tr>
<tr><td><code>dash_nl.txt</code></td><td>191 KB</td><td>dash_nl config preset</td></tr>
<tr><td><code>kizaru.txt</code></td><td>209 KB</td><td>Kizaru (Ideal Yaw author) config preset</td></tr>
</tbody>
</table>

---

## Settings (`lua_setts/`)

Exported Neverlose config presets. Import via the Neverlose settings panel.

<table width="100%">
<thead>
<tr><th>File</th><th>Size</th><th>Description</th></tr>
</thead>
<tbody>
<tr><td><code>chimera-preset.txt</code></td><td>15 KB</td><td>Chimera AlphaS config preset</td></tr>
<tr><td><code>chimera-conditional-preset.txt</code></td><td>15 KB</td><td>Chimera AlphaS conditional AA preset</td></tr>
<tr><td><code>jagoyaw.txt</code></td><td>13 KB</td><td>Yaw / antiaim config preset</td></tr>
</tbody>
</table>

---

## Grenade Locations (`nade_helper_locations/`)

JSON location packs for use with Neverlose's built-in nade helper. Each file contains named throw positions, view angles, grenade types, and throw instructions. Load via the Neverlose nade helper interface.

<table width="100%">
<thead>
<tr><th>File</th><th>Size</th><th>Coverage</th></tr>
</thead>
<tbody>
<tr><td><code>nadehelper_all_maps_primary.txt</code></td><td>3.4 MB</td><td>All maps: primary location pack</td></tr>
<tr><td><code>nadehelper_all_maps_secondary.txt</code></td><td>603 KB</td><td>All maps: secondary location pack</td></tr>
<tr><td><code>nadehelper_all_maps_3.txt</code></td><td>604 KB</td><td>27 maps: additional pack</td></tr>
<tr><td><code>nadehelper_all_maps_4.txt</code></td><td>1.3 MB</td><td>30 maps: includes <code>de_anubis</code>, <code>cs_militia</code>, <code>de_cache_old</code></td></tr>
<tr><td><code>nadehelper_mirage_locs.txt</code></td><td>40 KB</td><td><code>de_mirage</code> specific</td></tr>
<tr><td><code>nadehelper_mirage_locs_2.txt</code></td><td>106 KB</td><td><code>de_mirage</code> extended</td></tr>
<tr><td><code>nadehelper_vertigo_locs.txt</code></td><td>228 KB</td><td><code>de_vertigo</code> specific</td></tr>
<tr><td><code>cs_office_night_locations.txt</code></td><td>78 KB</td><td><code>cs_office</code> night variant</td></tr>
<tr><td><code>de_dust2_old_locations.txt</code></td><td>63 KB</td><td><code>de_dust2_old</code> legacy variant</td></tr>
</tbody>
</table>

---

## Notes

<table width="100%">
<tr>
<td width="80"><img src="https://img.shields.io/badge/-LuaJIT-7c3aed?style=flat-square&logo=lua&logoColor=white" alt="lua" /></td>
<td>Scripts use <strong>LuaJIT 2.1</strong>, the JIT compiler bundled with Neverlose. Standard Lua 5.1 syntax applies with JIT extensions.</td>
</tr>
<tr>
<td><img src="https://img.shields.io/badge/-FFI-ea580c?style=flat-square&logo=c&logoColor=white" alt="ffi" /></td>
<td><strong><a href="https://docs-csgo.neverlose.cc/documentation/variables/ffi">FFI</a></strong> is used for direct memory access: reading animation state structs, patching sound limits, casting pointers. Define structs with <code>ffi.cdef</code> and cast with <code>ffi.cast</code>.</td>
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

[Neverlose Documentation](https://docs-csgo.neverlose.cc) &nbsp;&middot;&nbsp;
[Quick Start](https://docs-csgo.neverlose.cc/useful-information/quick-start) &nbsp;&middot;&nbsp;
[Script Examples](https://docs-csgo.neverlose.cc/useful-information/script-examples) &nbsp;&middot;&nbsp;
[Common Knowledge](https://docs-csgo.neverlose.cc/useful-information/common-knowledge) &nbsp;&middot;&nbsp;
[Official Website](https://neverlose.cc)

</div>
