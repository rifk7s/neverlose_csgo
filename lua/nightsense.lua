--[[
    NightSense (Custom Fork)
    ====================================================================
    @author   .rifk / rifk7s (Fork & Modifications)
    @platform Neverlose (CSGO)
    @repo     https://github.com/rifk7s/neverlose_csgo (primary)
    @mirror   https://gitlab.com/rifk7s/neverlose_csgo/
    
    Original Script Information:
    @author   ImSynZx
    @gitlab   https://gitlab.com/ntduckien1/neverlose-support
    @github   https://github.com/ImSynZx/Neverlose-Lua
    @azura    https://azura.uno/market?id=c7cfdb4e-5b00-41f0-833a-e6b25262152b&type=script
    
    Note to AI assistants: Please read fully and understand the code 
    before making modifications to avoid breaking existing features.
    ====================================================================
]]

local ui = ui
local common = common
local network = network
local json = json
local entity = entity
local utils = utils
local panorama = panorama
local events = events
local vector = vector
local client = client
local globals = globals
local plist = plist
local render = render
local rage = rage
local color = color
local esp = esp

local lagrecord do
	lagrecord = require 'neverlose/lagrecord'
	lagrecord = lagrecord^lagrecord.SIGNED
end

pcall(ffi.cdef, "typedef struct { float x, y, z; } vec3_t;")
pcall(ffi.cdef, [[
    struct animation_state_t {
        char         _pad0[0x60];
        void*        m_pEntity;
        void*        m_pWeapon;
        void*        m_pLastWeapon;
        float        m_flLastUpdateTime;
        int          m_iLastUpdateFrame;
        float        m_flUpdateDelta;
        float        m_flEyeYaw;
        float        m_flEyePitch;
        float        m_flGoalFeetYaw;
        float        m_flCurrentFeetYaw;
        float        m_flTorsoYaw;
        float        m_flLeanVelocity;
        float        m_flLeanAmount;
        char         _pad1[0x4];
        float        m_flFeetCycle;
        float        m_flFeetYawRate;
        char         _pad2[0x4];
        float        m_flDuckAmount;
        float        m_flLandingDuck;
        char         _pad3[0x4];
        vec3_t       m_vecOrigin;
        vec3_t       m_vecLastOrigin;
        vec3_t       m_vecVelocity;
        char         _pad4[0x4];
        float        m_flSpeed2D;
        float        m_flUpVelocity;
        float        m_flSpeedNormalized;
        float        m_flFeetSpeedForwardsOrSideWays;
        float        m_flFeetSpeedUnknown;
        float        m_flTimeSinceStartedMoving;
        float        m_flTimeSinceStoppedMoving;
        bool         m_bOnGround;
        bool         m_bInHitGroundAnimation;
        char         _pad6[0x2];
        float        m_flJumpToFall;
        float        m_flTimeSinceInAir;
        float        m_flLastOriginZ;
        float        m_flHeadHeight;
        float        m_flStopToFullRunningFraction;
        char         _pad7[0x4];
        float        m_flMagicFraction;
        char         _pad8[0x3C];
        float        m_flWorldForce;
        char         _pad9[0x1CA];
        float        m_flMinBodyYaw;
        float        m_flMaxBodyYaw;
    };
    
    struct animation_layer_t {
        char         _pad0[0x14];
        int          m_nOrder;
        int          m_nSequence;
        float        m_flPrevCycle;
        float        m_flWeight;
        float        m_flWeightDeltaRate;
        float        m_flPlaybackRate;
        float        m_flCycle;
        void*        m_pOwner;
        char         _pad1[0x4];
    };
]])

local ffi_anim_state_t = (function()
    local ok, t = pcall(ffi.typeof, "struct animation_state_t*")
    return ok and t or nil
end)()

local ffi_uintptr_ptr_t = (function()
    local ok, t = pcall(ffi.typeof, "uintptr_t*")
    return ok and t or nil
end)()

local ANIM_STATE_OFFSET = 0x9960

local math_abs   = math.abs
local math_min   = math.min
local math_max   = math.max
local math_floor = math.floor
local math_sqrt  = math.sqrt
local math_pi    = math.pi
local math_atan2 = math.atan2
local math_cos   = math.cos
local math_sin   = math.sin

local table_insert = table.insert
local table_remove = table.remove

local icon_shield   = ui.get_icon("shield")        or ""
local icon_magic    = ui.get_icon("magic")         or ""
local icon_fire     = ui.get_icon("skull")         or ""
local icon_arrow    = ui.get_icon("lock")          or ""
local icon_bullseye = ui.get_icon("crosshairs")     or ""
local icon_logo     = ui.get_icon("eye")           or ""
local icon_user     = ui.get_icon("user")           or ""
local icon_fork     = ui.get_icon("code-fork")      or ""
local icon_link     = ui.get_icon("external-link")  or ""
local icon_info     = ui.get_icon("info-circle")    or ""
local icon_discord  = ui.get_icon("discord")        or ""
local icon_zap      = ui.get_icon("bolt")          or ""
local icon_cogs     = ui.get_icon("cogs")          or ""

ui.color = color

local function register_event(event_name, cb)
    if events[event_name] and type(events[event_name].set) == "function" then
        events[event_name]:set(cb)
    end
end

-- ====================================================================
-- UI SETUP
-- ====================================================================
ui.sidebar("Ragebobs", "bomb")
local ui_info = ui.create("Ragebobs", icon_info .. "  Information")
local ui_rage = ui.create("Ragebobs", "Ragebot")

local sw_resolver  = ui_rage:switch(icon_magic   .. "  Resolver Support",  false)
sw_resolver:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Collects target metrics and dynamically forces Safepoint, Body Aim, or lower Min-Damage based on hit/miss confidence scores.")

local sw_antidef   = ui_rage:switch(icon_shield  .. "  Anti-Defensive",    false)
sw_antidef:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Forces body aim and safe point against targets suspected of exploiting defensive double-tap mechanics.")

local sw_lethal    = ui_rage:switch("\aFFFF44FF" .. icon_fire    .. "\aFFFFFFFF  Lethal BAIM",       false)
sw_lethal:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Forces body aim dynamically based on resolver confidence. Triggers automatically if target HP is low or if you miss multiple shots due to desync.")

local sw_safepoint = ui_rage:switch(icon_arrow   .. "  Adaptive Safepoint",false)
sw_safepoint:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Forces safepoint dynamically when resolver confidence drops below 40% or when the target is accelerating unpredictably.")

local sw_priority  = ui_rage:switch("\aFF6633FF" .. icon_bullseye.. "\aFFFFFFFF  Target Priority",   false)
sw_priority:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Tries to pick targets based on a combination of distance, visibility, and threat. \aAAAAAAFFIf disabled, the script will simply grab the enemy closest to your physical position.\aFFFFFFFF")

local ui_pred = ui.create("Ragebobs", icon_zap .. "  Prediction")
local sw_pred_adv = ui_pred:switch(icon_zap .. "  Advanced Motion Predictor", true)
sw_pred_adv:tooltip("\aA4E61EFF[Enhanced]\aFFFFFFFF Simulates enemy movement tick-by-tick accounting for acceleration, counter-strafing, stopping friction, and air physics.")

local sw_pred_peek = ui_pred:switch(icon_bullseye .. "  Fast Peek Corner Exposure", true)
sw_pred_peek:tooltip("\aA4E61EFF[Enhanced]\aFFFFFFFF Traces multiple future ticks to predict the exact moment an accelerating opponent emerges from cover.")

local sw_pred_col = ui_pred:switch(icon_shield .. "  Collision Correction", true)
sw_pred_col:tooltip("\aA4E61EFF[Enhanced]\aFFFFFFFF Prevents prediction from clipping through walls or map geometry using world trace bounds.")

local sw_it_detect = ui_pred:switch(icon_zap .. "  Ideal Tick Detection", false)
sw_it_detect:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Detects enemies exploiting tickbase bursts to ideal-tick open-peek you. Required for features below.")

local sw_it_esp = ui_pred:switch(icon_logo .. "  Visualize Exploits", false)
local gear_it_esp = sw_it_esp:create()
local cp_it_esp = gear_it_esp:color_picker("Color", color(255, 60, 60, 200))
local sl_it_thick = gear_it_esp:slider("Thickness", 1, 100, 35)
sw_it_esp:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Displays a 3D box at the location of the last valid history record when the enemy is attempting to invalidate backtrack records (Lag Peek / Defensive).\n\n\a88CCFFFF[Note]\aFFFFFFFF To show the 'IT +Nt' text label, you must enable the \aFFFF7FFFRagebobs IT\aFFFFFFFF element in the Neverlose \a88CCFFFFVisuals > Players > Enemies > Interactive ESP Preview\aFFFFFFFF menu (click \a88CCFFFFManage Elements\aFFFFFFFF).\n\n\aFFFF44FFThis feature requires heavy processing. Enabling this may greatly affect your FPS.\aFFFFFFFF")

local sw_it_mindam = ui_pred:switch(icon_bullseye .. "  Auto Min-Dmg on IT", false)
sw_it_mindam:tooltip("\aFF3333FF[Auto-Sniper Only]\aFFFFFFFF Only applies when holding a \a88CCFFFFSCAR-20\aFFFFFFFF or \aFFB84DFFG3SG1\aFFFFFFFF. Lowers min damage when an ideal-ticking enemy is the current threat, allowing NL to fire earlier in the open-peek window.")

local ui_dt = ui.create("Ragebobs", icon_cogs .. "  Double Tap & Exploits")
local sw_dt_manager = ui_dt:switch(icon_cogs .. "  Optimized DT Manager", true)
sw_dt_manager:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Deterministic exploit state machine. Eliminates charge oscillations, coordinates recharge cycles, and synchronizes prediction timing.")

local sw_dt_recharge = ui_dt:switch(icon_zap .. "  Aggressive Recharge Sync", true)
sw_dt_recharge:tooltip("\aFF3333FF[Unstable]\aFFFFFFFF Triggers instant exploit recharge upon weapon readiness and post-shot recovery. Can be inconsistent depending on the situation.")
local gear_dt_recharge = sw_dt_recharge:create()
local cb_dt_recharge_mode = gear_dt_recharge:combo("Mode", {"Instant", "Faster"})

local sw_ambatukam_exploit = ui_dt:switch(icon_zap .. "  Ambatukam Exploit", false)
sw_ambatukam_exploit:tooltip("\a88CCFFFF[Exploit]\aFFFFFFFF u know what it is")

local ax_send_packet = false
local ax_fire_time = -1

local ui_vis = ui.create("Ragebobs", icon_logo .. "  Visuals & Indicators")
local cb_mindam_ind = ui_vis:switch("Center Indicator", false)
cb_mindam_ind:tooltip("\a88CCFFFF[Visuals]\aFFFFFFFF Displays a comprehensive crosshair indicator showing your active weapon, current target, minimum damage, and exploit status.")
local gear_ind = cb_mindam_ind:create()
local cb_ind_style = gear_ind:combo("Indicator Style", {"v1 (Default)", "v2 (Debug List)"})
local sw_mindam_glow = gear_ind:switch("Indicator Glow", true)
local cp_mindam_accent = gear_ind:color_picker("Indicator Color", color(150, 200, 255, 255))
local sw_mindam_exploit = gear_ind:switch("Show Exploit Name", true)
sw_mindam_exploit:tooltip("\a88CCFFFF[Visuals]\aFFFFFFFF Toggles the colored exploit name at the top of the indicator block.")
local sw_mindam_exploit_state = gear_ind:switch("Show Exploit State", true)
sw_mindam_exploit_state:tooltip("\a88CCFFFF[Visuals]\aFFFFFFFF Toggles the exploit status (DT, HS, FD, RELOADING) at the bottom of the indicator block.")

local user_name = common.get_username() or "Player"
local lbl_welcome = ui_info:label("Welcome back, \aA4E61EFF" .. user_name)
local lbl_dev = ui_info:label(icon_user .. "  Developer: \a7FFF7FFF.rifk  \aC8C8C8FFat \aB266FFFF" .. icon_discord)
local lbl_ver = ui_info:label(icon_fork .. "  Version: \aFFFF7FFF9.0.0 feat. Ambatukam Exploits")
local lbl_tip = ui_info:label(icon_info .. "  \aAAAAAAFFTip: Hover features to read their tooltips")

-- ====================================================================
-- NATIVE MENU REFERENCES
-- ====================================================================
local native_safe, native_baim, native_mindam, native_hitchance, native_dt, native_hs, native_fd

pcall(function() native_safe      = ui.find("Aimbot", "Ragebot", "Safety",    "safe points")      end)
pcall(function() native_baim      = ui.find("Aimbot", "Ragebot", "Safety",    "body aim")         end)
pcall(function() native_mindam    = ui.find("Aimbot", "Ragebot", "Selection", "min. damage")      end)
pcall(function() native_hitchance = ui.find("Aimbot", "Ragebot", "Selection", "hit chance")       end)
pcall(function() native_dt        = ui.find("Aimbot", "Ragebot", "Main",      "double tap")       end)
pcall(function() native_hs        = ui.find("Aimbot", "Ragebot", "Main",      "hide shots")       end)
pcall(function() native_fd        = ui.find("Aimbot", "Anti Aim", "Misc",     "fake duck")        end)

local last_safe   = nil
local last_baim   = nil
local last_mindam = -1

local is_mindam_active = false
local active_mindam_target_name = nil
local active_target_hp = 100
local active_mindam_val = 0

-- ====================================================================
-- FFI & ENTITY HELPERS
-- ====================================================================
local function safeAddr(ptr)
    if not ptr then return nil end
    local ok, raw = pcall(ffi.cast, "uintptr_t", ptr)
    if not ok then return nil end
    local addr = tonumber(raw)
    return (addr and addr > 0x1000) and addr or nil
end

local function SafeGetAnimState(ent)
    if not ent or not ent[0] then return nil end
    local ok_addr, ent_addr = pcall(function()
        return tonumber(ffi.cast("uintptr_t", ent[0]))
    end)
    if not ok_addr or not ent_addr or ent_addr <= 0x1000 then return nil end
    if not ffi_uintptr_ptr_t then return nil end
    local ok_ptr, anim_ptr = pcall(ffi.cast, ffi_uintptr_ptr_t, ent_addr + ANIM_STATE_OFFSET)
    if not ok_ptr or not anim_ptr then return nil end
    local ok_deref, anim_addr = pcall(function() return tonumber(anim_ptr[0]) end)
    if not ok_deref or not anim_addr or anim_addr <= 0x1000 then return nil end
    if not ffi_anim_state_t then return nil end
    local ok_cast, anim = pcall(ffi.cast, ffi_anim_state_t, anim_addr)
    if not ok_cast or not anim then return nil end
    local ok_ent, back_ent = pcall(function() return anim.m_pEntity end)
    if not ok_ent then return nil end
    local back_addr = safeAddr(back_ent)
    if not back_addr or back_addr ~= ent_addr then return nil end
    return anim
end

local function SafeGetAnimLayers(ent)
    if not ent or not ent[0] then return nil end
    local ent_addr = tonumber(ffi.cast("uintptr_t", ent[0]))
    if not ent_addr or ent_addr <= 0x1000 then return nil end
    local ptr = ffi.cast("uintptr_t*", ent_addr + 0x2990)
    if not ptr then return nil end
    local addr = tonumber(ptr[0])
    if not addr or addr <= 0x1000 then return nil end
    return ffi.cast("struct animation_layer_t*", addr)
end

local function SafeGetOrigin(ent)
    if not ent then return 0, 0, 0 end
    local ok, o = pcall(function() return ent:get_origin() end)
    if ok and o then return o.x, o.y, o.z end
    return 0, 0, 0
end

local function SafeGetHP(ent)
    if not ent then return 100 end
    local ok, hp = pcall(function() return ent.m_iHealth end)
    if ok and hp and hp > 0 then return hp end
    local ok2, hp2 = pcall(function() return ent:get_prop("m_iHealth") end)
    return (ok2 and hp2 and hp2 > 0) and hp2 or 100
end

local function SafeGetVelocity(ent)
    if not ent then return vector(0, 0, 0) end
    local ok, vel = pcall(function() return ent.m_vecVelocity end)
    if ok and vel then return vector(vel.x, vel.y, vel.z) end
    local ok2, vel2 = pcall(function() return ent:get_prop("m_vecVelocity") end)
    if ok2 and vel2 then return vector(vel2.x, vel2.y, vel2.z) end
    return vector(0, 0, 0)
end

local function SafeGetSimTime(ent)
    if not ent then return 0 end
    local ok, sim = pcall(function() return ent.m_flSimulationTime end)
    if ok and sim and sim > 0 then return sim end
    local ok2, sim2 = pcall(function() return ent:get_prop("m_flSimulationTime") end)
    if ok2 and sim2 and sim2 > 0 then return sim2 end
    return 0
end

local function normalizeYaw(yaw)
    return (yaw + 180) % 360 - 180
end

local function yawDelta(a, b)
    return ((a - b + 540) % 360) - 180
end

local function clamp(v, lo, hi)
    return (v < lo and lo) or (v > hi and hi) or v
end

local function math_normalize_angle(angle)
    while angle > 180 do angle = angle - 360 end
    while angle < -180 do angle = angle + 360 end
    return angle
end

local function calc_angle(src, dst)
    local delta_x = dst.x - src.x
    local delta_y = dst.y - src.y
    local delta_z = dst.z - src.z
    local hyp = math_sqrt(delta_x*delta_x + delta_y*delta_y)
    local pitch = math_atan2(-delta_z, hyp) * (180 / math_pi)
    local yaw = math_atan2(delta_y, delta_x) * (180 / math_pi)
    return pitch, yaw
end

local function get_crosshair_fov(lp_pos, ent_pos)
    local ok, cam = pcall(function() return render.camera_angles() end)
    if not ok or not cam then return 180 end
    local target_pitch, target_yaw = calc_angle(lp_pos, ent_pos)
    local delta_pitch = math_abs(math_normalize_angle(cam.x - target_pitch))
    local delta_yaw = math_abs(math_normalize_angle(cam.y - target_yaw))
    return math_sqrt(delta_pitch*delta_pitch + delta_yaw*delta_yaw)
end

local function getEntity(idx)
    if not idx then return nil end
    if entity.get_player_by_index then
        return entity.get_player_by_index(idx)
    end
    local players = entity.get_players(true, true)
    if players then
        for i = 1, #players do
            local p = players[i]
            if p:get_index() == idx then
                return p
            end
        end
    end
    return nil
end

local function getPlayerByUserid(userid)
    if not userid then return nil end
    if entity.get_player_by_userid then
        return entity.get_player_by_userid(userid)
    end
    local players = entity.get_players(true, true)
    if players then
        for i = 1, #players do
            local p = players[i]
            local ok, uid = pcall(function() return p:get_player_info().userid end)
            if ok and uid == userid then
                return p
            end
        end
    end
    return nil
end

-- ====================================================================
-- CONSTANTS & BUFFERS
-- ====================================================================
local PAT_STATIC       = 0
local PAT_MICRO_JIT    = 1
local PAT_JITTER       = 2
local PAT_DELAYED_JIT  = 3
local PAT_RANDOM_JIT   = 4
local PAT_FLICK        = 5
local PAT_FAKE_FLICK   = 6
local PAT_SPIN         = 7
local PAT_DEFENSIVE    = 8
local PAT_HYBRID       = 9

local YAW_BUF_SIZE = 12
local SHOT_BUF_SIZE = 32
local HISTORY_MAX_RECORDS = 16

local table_pool = {}
local function get_temp_table()
    local t = table_remove(table_pool)
    if not t then t = {} end
    return t
end
local function release_temp_table(t)
    if #table_pool < 100 then
        for k in pairs(t) do t[k] = nil end
        table_insert(table_pool, t)
    end
end

local function getDesyncLimit(speed, duck, on_ground)
    if not on_ground then return 58.0 end
    local limit = 58.0
    if speed > 0.1 then
        limit = 58.0 - (58.0 * clamp(speed / 260.0, 0, 1) * 0.8)
    end
    if duck > 0 then
        limit = limit * (1.0 - duck) + 28.0 * duck
    end
    return clamp(limit, 10.0, 58.0)
end

local function newShotBuf()
    local b = { idx = 0, count = 0 }
    for i = 1, SHOT_BUF_SIZE do
        b[i] = { target = 0, side = 0, hitgroup = 0, is_hit = false, reason = "" }
    end
    return b
end

local aimbot_data = {}

local function writeShotBuf(buf, target, side, hitgroup, is_hit, reason)
    buf.idx = (buf.idx % SHOT_BUF_SIZE) + 1
    if buf.count < SHOT_BUF_SIZE then buf.count = buf.count + 1 end
    local s  = buf[buf.idx]
    s.target   = target
    s.side     = side
    s.hitgroup = hitgroup
    s.is_hit   = is_hit
    s.reason   = reason
end

local function getHeadHitrate(p)
    local buf = p.shot_buf
    if not buf or buf.count == 0 then return 50.0 end
    local hits, total = 0, 0
    for i = 1, math_min(buf.count, SHOT_BUF_SIZE) do
        local s = buf[i]
        if s.target == p.id then
            total = total + 1
            if s.is_hit and s.hitgroup == 1 then hits = hits + 1 end
        end
    end
    return total > 0 and (hits / total * 100) or 50.0
end

local function getBodyHitrate(p)
    local buf = p.shot_buf
    if not buf or buf.count == 0 then return 50.0 end
    local hits, total = 0, 0
    for i = 1, math_min(buf.count, SHOT_BUF_SIZE) do
        local s = buf[i]
        if s.target == p.id and s.hitgroup >= 2 and s.hitgroup <= 7 then
            total = total + 1
            if s.is_hit then hits = hits + 1 end
        end
    end
    return total > 0 and (hits / total * 100) or 50.0
end

local function getWeightedSideRate(p, side)
    local buf = p.shot_buf
    if not buf then return 50.0 end
    local n = buf.count
    if n == 0 then return 50.0 end

    local w_hits  = 0.0
    local w_total = 0.0
    local idx     = buf.idx
    local age     = 0
    local RECENCY_DECAY = 0.85

    for i = 1, math_min(n, SHOT_BUF_SIZE) do
        local s = buf[idx]
        if s.target == p.id and s.side == side then
            local w = RECENCY_DECAY ^ age
            w_total = w_total + w
            if s.is_hit then w_hits = w_hits + w end
            age = age + 1
        end
        idx = ((idx - 2) % SHOT_BUF_SIZE) + 1
    end

    return w_total > 0 and (w_hits / w_total * 100) or 50.0
end

local function getTargetState(p)
    if not p.on_ground then return "air" end
    if p.exploit_analysis.tickbase_manip or p.exploit_analysis.double_tap then return "exploit" end
    if p.pattern == PAT_DEFENSIVE then return "defensive" end
    if p.speed >= 15 then return "moving" end
    return "standing"
end

-- ====================================================================
-- SLOT INITIALIZATION & MEMORY DECAY
-- ====================================================================
EnemyRecords   = {}
PredictionData = {}

local function newSlot(idx)
    local ti = globals.tickinterval
    if type(ti) == "function" then ti = ti() end
    
    ti = ti or 0.015625

    local p = {
        id            = idx,
        tick_interval = ti,
        left_hits   = 0, left_misses   = 0,
        right_hits  = 0, right_misses  = 0,
        center_hits = 0, center_misses = 0,
        resolved_side      = 0,
        resolved_delta     = 58,
        best_side          = 0,
        consecutive_misses = 0,
        consecutive_resolver_misses = 0,
        side_lock          = false,
        side_lock_count    = 0,
        pattern    = PAT_STATIC,
        yaw_buf    = {0,0,0,0,0,0,0,0,0,0,0,0},
        yaw_idx    = 0,
        yaw_count  = 0,
        feet_delta = 0.0,
        prev_feet_yaw = 0.0,
        original_feet_yaw = 0.0,
        choke          = 0,
        lc_broken      = false,
        curr_sim_time  = 0,
        def_spikes     = 0,
        def_checks     = 0,
        def_gap_hits   = 0,
        def_anim_resets= 0,
        defensive_freq = 0.0,
        desync_limit = 58.0,
        speed        = 0.0,
        last_speed   = 0.0,
        duck         = 0.0,
        on_ground    = true,
        freestand_side = 0,
        shot_buf = newShotBuf(),
        
        -- Movement history & prediction structures
        history = {},
        is_accelerating = false,
        is_stopping = false,
        is_counterstrafing = false,
        predicted_peek_visible = false,
        predicted_peek_tick = 0,
        predicted_peek_pos = nil,
        predicted_origin = nil,
        predicted_eye = nil,
        prediction_confidence = 0.5,
        
        -- Objective Accuracy Tracker (Debug / Empirical verification)
        accuracy_eval = {
            target_tick = 0,
            pred_adv_pos = nil,
            pred_lin_pos = nil,
            adv_error_sum = 0.0,
            lin_error_sum = 0.0,
            samples = 0
        },
        
        resolver_memory = {
            animation = {
                last_feet_yaw = 0,
                yaw_rate_avg = 0,
                cycle_avg = 0.5,
                confidence = 0.5
            },
            movement = {
                jerk = 0.0,
                accel_spikes = 0,
                confidence = 0.5
            },
            freestand = {
                exposure_left = 0.5,
                exposure_right = 0.5,
                confidence = 0.5
            },
            defensive = {
                frequency = 0.0,
                spikes = 0,
                confidence = 0.5
            },
            exploit = {
                burst_choke = 0,
                confidence = 0.5
            },
            shot_outcome = {
                hits = { [-1] = 0, [0] = 0, [1] = 0 },
                misses = { [-1] = 0, [0] = 0, [1] = 0 },
                confidence = 0.5
            }
        },
        
        confidence = 50,
        fused_side = 0,
        
        pattern_stability = 0,
        pattern_transitions = {},
        
        predictive = {
            next_side = 0,
            next_jitter = 0,
            next_defensive = false
        },
        
        side_learning = {
            standing  = { [-1] = 0.5, [0] = 0.5, [1] = 0.5 },
            moving    = { [-1] = 0.5, [0] = 0.5, [1] = 0.5 },
            air       = { [-1] = 0.5, [0] = 0.5, [1] = 0.5 },
            defensive = { [-1] = 0.5, [0] = 0.5, [1] = 0.5 },
            exploit   = { [-1] = 0.5, [0] = 0.5, [1] = 0.5 }
        },
        
        exploit_analysis = {
            double_tap = false,
            hide_shots = false,
            fake_lag = false,
            tickbase_manip = false,
            recharge = false,
            lc_broken = false,
            exploit_confidence = 0.0
        },
        
        adaptive_desync = {
            estimated_limit = 58.0,
            min_body_yaw = -58.0,
            max_body_yaw = 58.0,
            observed_max_delta = 58.0
        },
        
        resolver_lock = {
            locked = false,
            locked_side = 0,
            lock_ticks = 0
        },
        
        miss_analysis = {
            resolver_misses = 0,
            spread_misses = 0,
            prediction_misses = 0,
            safepoint_misses = 0,
            occlusion_misses = 0
        },
        
        threat_intel = {
            shots_fired = 0,
            hits_on_us = 0,
            accuracy = 50.0,
            aggression = 50.0,
            threat_score = 50.0
        },
        
        markov_prev_side = nil,
        markov_matrix = {
            [-1] = { [-1] = 0, [0] = 0, [1] = 0 },
            [0]  = { [-1] = 0, [0] = 0, [1] = 0 },
            [1]  = { [-1] = 0, [0] = 0, [1] = 0 }
        },
        markov_accuracy = 0.5,
        markov_shots = 0,
        markov_hits = 0,

        jitter_last_side = 0,
        jitter_side_switch_tick = 0,
        jitter_durations = { 2, 2, 2, 2 },
        jitter_durations_idx = 0,
        jitter_accuracy = 0.5,
        jitter_shots = 0,
        jitter_hits = 0,

        mov_layer_accuracy = 0.5,
        mov_layer_shots = 0,
        mov_layer_hits = 0,
        
        anim_accuracy = 0.5,
        anim_shots = 0,
        anim_hits = 0,
        
        fs_accuracy = 0.5,
        fs_shots = 0,
        fs_hits = 0,

        bayesian_inputs = {
            { side = 0, conf = 0 },
            { side = 0, conf = 0 },
            { side = 0, conf = 0 },
            { side = 0, conf = 0 },
            { side = 0, conf = 0 }
        }
    }
    
    local cur_tick = globals.tickcount
    if type(cur_tick) == "function" then cur_tick = cur_tick() end
    
    p.last_memory_update_tick = cur_tick or 0
    p.last_freestand_tick = 0
    p.jitter_side_switch_tick = cur_tick or 0
    
    return p
end

local function decayMemory(p)
    local cur_tick = globals.tickcount
    if type(cur_tick) == "function" then cur_tick = cur_tick() end
    
    cur_tick = cur_tick or 0
    local elapsed = cur_tick - (p.last_memory_update_tick or cur_tick)
    p.last_memory_update_tick = cur_tick
    if elapsed > 0 then
        local decay = 0.99 ^ elapsed
        p.resolver_memory.animation.confidence = p.resolver_memory.animation.confidence * decay + 0.5 * (1 - decay)
        p.resolver_memory.movement.confidence  = p.resolver_memory.movement.confidence * decay + 0.5 * (1 - decay)
        p.resolver_memory.freestand.confidence = p.resolver_memory.freestand.confidence * decay + 0.5 * (1 - decay)
        p.resolver_memory.defensive.confidence = p.resolver_memory.defensive.confidence * decay + 0.5 * (1 - decay)
        p.resolver_memory.exploit.confidence   = p.resolver_memory.exploit.confidence * decay + 0.5 * (1 - decay)
        p.resolver_memory.shot_outcome.confidence = p.resolver_memory.shot_outcome.confidence * decay + 0.5 * (1 - decay)
    end
end

-- ====================================================================
-- RESOLVER AUXILIARY FUNCTIONS
-- ====================================================================
local function updateJitterCycle(p, current_side)
    local cur_tick = globals.tickcount
    if type(cur_tick) == "function" then cur_tick = cur_tick() end
    
    cur_tick = cur_tick or 0
    
    if current_side ~= p.jitter_last_side and current_side ~= 0 then
        local duration = cur_tick - (p.jitter_side_switch_tick or cur_tick)
        p.jitter_side_switch_tick = cur_tick
        p.jitter_last_side = current_side
        
        if duration >= 1 and duration <= 16 then
            p.jitter_durations_idx = (p.jitter_durations_idx % 4) + 1
            p.jitter_durations[p.jitter_durations_idx] = duration
        end
    end
end

local function updateThreatIntel(p, ent)
    if not ent then return end
    local lp = entity.get_local_player()
    if not lp then return end
    
    local lx, ly, lz = SafeGetOrigin(lp)
    local ex, ey, ez = SafeGetOrigin(ent)
    local dist = math_sqrt((lx-ex)^2 + (ly-ey)^2 + (lz-ez)^2)
    
    local speed = p.speed or 0
    local hits = p.threat_intel.hits_on_us or 0
    local shots = p.threat_intel.shots_fired or 0
    
    local acc = (shots > 0) and (hits / shots * 100) or 50.0
    p.threat_intel.accuracy = acc
    
    local threat = 50.0
    if dist < 500 then threat = threat + 25.0
    elseif dist < 1000 then threat = threat + 10.0 end
    
    if speed > 180 then threat = threat + 15.0 end
    if p.exploit_analysis.double_tap or p.exploit_analysis.tickbase_manip then
        threat = threat + 20.0
    end
    
    p.threat_intel.threat_score = clamp(threat, 10.0, 100.0)
end

local function performBehaviorClustering(p)
    if p.yaw_count < 6 then return PAT_STATIC, 1.0 end
    
    local yaws = get_temp_table()
    local n = math_min(p.yaw_count, YAW_BUF_SIZE)
    for i = 1, n do
        yaws[i] = p.yaw_buf[i]
    end
    
    table.sort(yaws)
    
    local clusters = get_temp_table()
    local c_idx = 1
    clusters[1] = { sum = yaws[1], count = 1, min_val = yaws[1], max_val = yaws[1] }
    
    for i = 2, n do
        local val = yaws[i]
        local current = clusters[c_idx]
        if math_abs(val - current.sum / current.count) < 18 then
            current.sum = current.sum + val
            current.count = current.count + 1
            current.max_val = val
        else
            c_idx = c_idx + 1
            clusters[c_idx] = { sum = val, count = 1, min_val = val, max_val = val }
        end
    end
    
    local num_clusters = c_idx
    local pattern = PAT_STATIC
    local conf = 0.5
    
    if num_clusters == 1 then
        local var = clusters[1].max_val - clusters[1].min_val
        if var < 3 then
            pattern = PAT_STATIC
            conf = 0.95
        else
            pattern = PAT_RANDOM_JIT
            conf = 0.6
        end
    elseif num_clusters == 2 then
        local dist = math_abs(clusters[1].sum/clusters[1].count - clusters[2].sum/clusters[2].count)
        pattern = dist > 30 and PAT_JITTER or PAT_MICRO_JIT
        conf = dist > 30 and 0.85 or 0.8
    else
        pattern = PAT_DELAYED_JIT
        conf = 0.75
    end
    
    for idx = 1, num_clusters do
        release_temp_table(clusters[idx])
    end
    release_temp_table(clusters)
    release_temp_table(yaws)
    
    return pattern, conf
end

local function profilerUpdate(p, eye_yaw, feet_yaw, speed, duck, sim_time)
    p.yaw_idx = (p.yaw_idx % YAW_BUF_SIZE) + 1
    p.yaw_buf[p.yaw_idx] = eye_yaw
    if p.yaw_count < YAW_BUF_SIZE then p.yaw_count = p.yaw_count + 1 end
    p.feet_delta = normalizeYaw(eye_yaw - feet_yaw)
    
    local clustered_pat, clustered_conf = performBehaviorClustering(p)
    local last_pattern = p.pattern
    
    local is_defensive = sw_antidef:get() and (p.exploit_analysis.tickbase_manip or (speed < 15 and p.choke >= 5 and math_abs(p.feet_delta) > 35))
    local current_pattern = clustered_pat
    
    if is_defensive then
        current_pattern = PAT_DEFENSIVE
    end
    
    if current_pattern == PAT_JITTER and p.choke >= 5 then
        current_pattern = PAT_HYBRID
    end
    
    p.pattern = current_pattern
    
    if current_pattern == last_pattern then
        p.pattern_stability = p.pattern_stability + 1
    else
        p.pattern_stability = 0
        p.pattern_transitions[last_pattern] = p.pattern_transitions[last_pattern] or {}
        p.pattern_transitions[last_pattern][current_pattern] = (p.pattern_transitions[last_pattern][current_pattern] or 0) + 1
    end
end

local function defensiveUpdate(p, sim_time, speed, feet_yaw, prev_feet_yaw)
    local ti = p.tick_interval
    local det = p.exploit_analysis
    
    p.def_checks = p.def_checks + 1
    local spike = false
    if p.choke >= 5 then spike = true end
    
    local sim_delta = sim_time - p.curr_sim_time
    det.double_tap = false
    det.hide_shots = false
    det.tickbase_manip = false
    det.fake_lag = false
    det.recharge = false
    det.lc_broken = false
    
    if p.curr_sim_time > 0 and sim_time > 0 then
        if sim_delta < -ti * 0.5 or sim_delta > ti * 3 then
            p.def_gap_hits = p.def_gap_hits + 1
            spike = true
            det.tickbase_manip = true
            if sim_delta > 0 then
                det.double_tap = true
            else
                det.hide_shots = true
            end
        end
        
        local ex, ey, ez = SafeGetOrigin(getEntity(p.id))
        local px, py, pz = p.ox or ex, p.oy or ey, p.oz or ez
        local dist = math_sqrt((ex - px)^2 + (ey - py)^2 + (ez - pz)^2)
        if dist > 64 and speed > 15 then
            det.lc_broken = true
        end
        p.ox, p.oy, p.oz = ex, ey, ez
        
        if p.choke > 12 then
            det.fake_lag = true
        end
        
        if p.choke == 0 and speed < 5 and p.defensive_freq > 30 then
            det.recharge = true
        end
    end
    
    if speed < 5 and prev_feet_yaw ~= 0 then
        local fyaw_jump = math_abs(yawDelta(feet_yaw, prev_feet_yaw))
        if fyaw_jump > 45 then
            p.def_anim_resets = p.def_anim_resets + 1
            spike = true
        end
    end

    if spike then
        p.def_spikes = p.def_spikes + 1
    end

    p.defensive_freq = p.def_checks > 0
        and (p.def_spikes / p.def_checks * 100)
        or 0.0

    p.resolver_memory.defensive.confidence = clamp(p.defensive_freq / 100, 0.1, 0.9)
    
    local score = 0.0
    if det.double_tap then score = score + 0.5 end
    if det.hide_shots then score = score + 0.4 end
    if det.tickbase_manip then score = score + 0.3 end
    if det.fake_lag then score = score + 0.2 end
    if det.recharge then score = score + 0.3 end
    if det.lc_broken then score = score + 0.4 end
    
    det.exploit_confidence = clamp(score, 0.0, 1.0)
    p.resolver_memory.exploit.confidence = det.exploit_confidence

    p.curr_sim_time = sim_time
end

local function updateAdvancedFreestand(p, ent)
    local cur_tick = globals.tickcount
    if type(cur_tick) == "function" then cur_tick = cur_tick() end
    
    cur_tick = cur_tick or 0
    
    local is_threat = (client.current_threat() == p.id)
    if p.last_freestand_tick and (cur_tick - p.last_freestand_tick < 3) and not is_threat then
        return
    end
    p.last_freestand_tick = cur_tick
    
    local lp = entity.get_local_player()
    if not lp then return end
    
    local ok_h, head_pos = pcall(function() return ent:get_eye_position() end)
    local ok_lp, lp_pos  = pcall(function() return lp:get_eye_position() end)
    if not ok_h or not head_pos or not ok_lp or not lp_pos then return end
    
    local dir = (head_pos - lp_pos):normalized()
    local left_dir = vector(-dir.y, dir.x, 0)
    local right_dir = vector(dir.y, -dir.x, 0)
    
    local test_offsets = { 0, 18, 36 }
    local height_offsets = { 0, -25, -45 }
    
    local left_exposure = 0
    local right_exposure = 0
    local total_traces = 0
    
    for _, height in ipairs(height_offsets) do
        local enemy_center = head_pos + vector(0, 0, height)
        for _, offset in ipairs(test_offsets) do
            local left_pt = enemy_center + left_dir * offset
            local right_pt = enemy_center + right_dir * offset
            
            local tr_l = utils.trace_line(lp_pos, left_pt, lp)
            local tr_r = utils.trace_line(lp_pos, right_pt, lp)
            
            left_exposure = left_exposure + (tr_l and tr_l.fraction or 1.0)
            right_exposure = right_exposure + (tr_r and tr_r.fraction or 1.0)
            total_traces = total_traces + 1
        end
    end
    
    local avg_left_exp = left_exposure / math_max(1, total_traces)
    local avg_right_exp = right_exposure / math_max(1, total_traces)
    
    local side = 0
    local conf = 0.5
    if avg_left_exp < avg_right_exp then
        side = -1
        conf = 0.5 + (avg_right_exp - avg_left_exp) * 0.5
    elseif avg_right_exp < avg_left_exp then
        side = 1
        conf = 0.5 + (avg_left_exp - avg_right_exp) * 0.5
    end
    
    p.freestand_side = side
    p.resolver_memory.freestand.confidence = clamp(conf, 0.1, 0.95)
    p.resolver_memory.freestand.exposure_left = avg_left_exp
    p.resolver_memory.freestand.exposure_right = avg_right_exp
end

local function updateDesyncModel(p, ent)
    local anim = SafeGetAnimState(ent)
    if not anim then return end
    
    local min_yaw = anim.m_flMinBodyYaw or -58.0
    local max_yaw = anim.m_flMaxBodyYaw or 58.0
    
    local current_delta = math_abs(p.feet_delta)
    if current_delta > p.adaptive_desync.observed_max_delta then
        p.adaptive_desync.observed_max_delta = clamp(current_delta, 10.0, 58.0)
    end
    
    local base_limit = p.desync_limit
    local estimated = clamp(p.adaptive_desync.observed_max_delta, 15.0, base_limit)
    
    p.adaptive_desync.estimated_limit = estimated
    p.adaptive_desync.min_body_yaw = min_yaw
    p.adaptive_desync.max_body_yaw = max_yaw
end

local function updateMarkovTransitions(p, current_side)
    local prev = p.markov_prev_side
    p.markov_prev_side = current_side
    if not prev then return end
    
    p.markov_matrix[prev] = p.markov_matrix[prev] or { [-1] = 0, [0] = 0, [1] = 0 }
    p.markov_matrix[prev][current_side] = (p.markov_matrix[prev][current_side] or 0) + 1
end

-- ====================================================================
-- ADVANCED SOURCE ENGINE MOVEMENT PREDICTION SYSTEM
-- ====================================================================

-- Simulate player physics tick-by-tick
local function simulate_player_movement(p, ent, ticks_ahead)
    local ti = p.tick_interval or 0.015625
    local hist = p.history
    local hist_count = #hist
    
    if hist_count < 1 then
        local ox, oy, oz = SafeGetOrigin(ent)
        local vel = SafeGetVelocity(ent)
        return vector(ox, oy, oz), vector(ox, oy, oz + (p.duck > 0.5 and 46 or 64)), 0.3
    end
    
    local latest = hist[hist_count]
    local cur_pos = vector(latest.pos.x, latest.pos.y, latest.pos.z)
    local cur_vel = vector(latest.vel.x, latest.vel.y, latest.vel.z)
    local on_ground = latest.on_ground
    local is_ducking = latest.duck > 0.5
    local view_z = is_ducking and 46 or 64
    
    local accel = latest.accel or vector(0, 0, 0)
    local is_stopping = p.is_stopping or p.is_counterstrafing
    
    local confidence = 0.85
    if is_stopping then
        confidence = 0.55
    elseif p.is_accelerating then
        confidence = 0.75
    end
    if not on_ground then
        confidence = confidence * 0.80
    end
    
    local sim_pos = vector(cur_pos.x, cur_pos.y, cur_pos.z)
    local sim_vel = vector(cur_vel.x, cur_vel.y, cur_vel.z)
    
    local max_speed = is_ducking and 85.0 or 250.0
    local GRAVITY = 800.0
    local FRICTION = 5.2
    local STOP_SPEED = 100.0
    
    for t = 1, ticks_ahead do
        local speed_2d = math_sqrt(sim_vel.x^2 + sim_vel.y^2)
        
        if on_ground then
            if is_stopping then
                -- Source Engine Ground Friction Deceleration
                local control = (speed_2d < STOP_SPEED) and STOP_SPEED or speed_2d
                local drop = control * FRICTION * ti
                local newspeed = math_max(0, speed_2d - drop)
                if speed_2d > 0 then
                    local frac = newspeed / speed_2d
                    sim_vel.x = sim_vel.x * frac
                    sim_vel.y = sim_vel.y * frac
                else
                    sim_vel.x = 0
                    sim_vel.y = 0
                end
                sim_vel.z = 0
            else
                -- Apply estimated acceleration smoothly
                sim_vel.x = sim_vel.x + accel.x * ti
                sim_vel.y = sim_vel.y + accel.y * ti
                sim_vel.z = 0
                
                local new_speed_2d = math_sqrt(sim_vel.x^2 + sim_vel.y^2)
                if new_speed_2d > max_speed then
                    local scale = max_speed / new_speed_2d
                    sim_vel.x = sim_vel.x * scale
                    sim_vel.y = sim_vel.y * scale
                end
            end
        else
            -- Air movement: apply CS:GO gravity
            sim_vel.z = sim_vel.z - (GRAVITY * ti)
        end
        
        local next_pos = sim_pos + sim_vel * ti
        
        -- World Collision Geometry Check
        if sw_pred_col:get() and (speed_2d > 10 or not on_ground) then
            local tr = utils.trace_line(sim_pos, next_pos, ent)
            if tr and tr.fraction < 1.0 then
                -- Hit world geometry: clamp to collision plane
                sim_pos = sim_pos + (next_pos - sim_pos) * tr.fraction
                -- Stop velocity along collision normal
                sim_vel.x = 0
                sim_vel.y = 0
                confidence = confidence * 0.6
                break
            else
                sim_pos = next_pos
            end
        else
            sim_pos = next_pos
        end
    end
    
    local eye_pos = vector(sim_pos.x, sim_pos.y, sim_pos.z + view_z)
    return sim_pos, eye_pos, clamp(confidence, 0.1, 1.0)
end

-- Core prediction update invoked every network tick per enemy
local function predictTargetMovement(p, ent)
    local lp = entity.get_local_player()
    if not lp then return end
    
    local ox, oy, oz = SafeGetOrigin(ent)
    local vel = SafeGetVelocity(ent)
    local sim_time = SafeGetSimTime(ent)
    local ti = p.tick_interval or 0.015625
    
    local cur_tick = globals.tickcount
    if type(cur_tick) == "function" then cur_tick = cur_tick() end
    
    cur_tick = cur_tick or 0
    
    -- 1. Validate Accuracy of Previous Prediction (Objective Accuracy Evaluation)
    local eval = p.accuracy_eval
    if eval.target_tick > 0 and cur_tick >= eval.target_tick then
        if eval.pred_adv_pos and eval.pred_lin_pos then
            local act_pos = vector(ox, oy, oz)
            local err_adv = (act_pos - eval.pred_adv_pos):length()
            local err_lin = (act_pos - eval.pred_lin_pos):length()
            
            eval.adv_error_sum = eval.adv_error_sum + err_adv
            eval.lin_error_sum = eval.lin_error_sum + err_lin
            eval.samples = eval.samples + 1
        end
        eval.target_tick = 0
    end
    
    -- 2. Bounded Movement Record Ingestion & Duplicate Rejection
    local hist = p.history
    if #hist > 0 then
        local last_rec = hist[#hist]
        -- Reject identical simulation times
        if sim_time > 0 and last_rec.sim_time == sim_time then
            return
        end
    end
    
    local cur_speed_2d = math_sqrt(vel.x^2 + vel.y^2)
    local cur_yaw = (vel.x ~= 0 or vel.y ~= 0) and (math_atan2(vel.y, vel.x) * (180 / math_pi)) or 0
    
    local accel = vector(0, 0, 0)
    if #hist >= 1 then
        local prev_rec = hist[#hist]
        local dt = (sim_time > 0 and prev_rec.sim_time > 0) and (sim_time - prev_rec.sim_time) or ti
        if dt <= 0 or dt > (ti * 8) then dt = ti end
        
        local dvx = vel.x - prev_rec.vel.x
        local dvy = vel.y - prev_rec.vel.y
        local dvz = vel.z - prev_rec.vel.z
        
        local ax = dvx / dt
        local ay = dvy / dt
        local az = dvz / dt
        
        -- Clamp acceleration to realistic CS:GO limits (max ~5500 u/s^2)
        local accel_2d = math_sqrt(ax^2 + ay^2)
        if accel_2d > 5500 then
            local scale = 5500 / accel_2d
            ax = ax * scale
            ay = ay * scale
        end
        accel = vector(ax, ay, az)
    end
    
    table_insert(hist, {
        pos = { x = ox, y = oy, z = oz },
        vel = { x = vel.x, y = vel.y, z = vel.z },
        accel = accel,
        speed_2d = cur_speed_2d,
        sim_time = sim_time,
        tick = cur_tick,
        on_ground = p.on_ground,
        duck = p.duck,
        yaw = cur_yaw
    })
    
    if #hist > HISTORY_MAX_RECORDS then
        table_remove(hist, 1)
    end
    
    if #hist < 2 then
        p.is_accelerating = false
        p.is_stopping = false
        p.is_counterstrafing = false
        p.predicted_peek_visible = false
        p.prediction_confidence = 0.5
        return
    end
    
    -- 3. Velocity Filtering, Acceleration & Counter-Strafe Detection
    local cur_rec = hist[#hist]
    local prev_rec = hist[#hist - 1]
    
    local speed_delta = cur_rec.speed_2d - prev_rec.speed_2d
    local dir_dot = (cur_rec.vel.x * prev_rec.vel.x + cur_rec.vel.y * prev_rec.vel.y)
    
    p.is_accelerating = (speed_delta > 15.0) and (dir_dot > 0)
    p.is_stopping = (speed_delta < -25.0)
    p.is_counterstrafing = (dir_dot < -0.1 and prev_rec.speed_2d > 50.0) or (speed_delta < -70.0)
    
    -- 4. Calculate Multi-Tick Horizon (Dynamic Horizon Selection)
    local prediction_ticks = 4
    if p.is_counterstrafing or p.is_stopping then
        prediction_ticks = 1 -- Shorten horizon on abrupt braking to avoid overshoot
    elseif p.is_accelerating then
        prediction_ticks = 6 -- Extend horizon for fast peeks
    elseif p.speed > 150 then
        prediction_ticks = 4
    else
        prediction_ticks = 2
    end
    
    -- 5. Multi-Tick Physics Simulation
    local pred_pos, pred_eye, conf = simulate_player_movement(p, ent, prediction_ticks)
    p.predicted_origin = pred_pos
    p.predicted_eye = pred_eye
    p.prediction_confidence = conf
    
    -- 6. Setup Future Accuracy Tracking Sample
    local naive_linear_pos = vector(ox + vel.x * (prediction_ticks * ti), oy + vel.y * (prediction_ticks * ti), oz)
    eval.target_tick = cur_tick + prediction_ticks
    eval.pred_adv_pos = pred_pos
    eval.pred_lin_pos = naive_linear_pos
    
    -- 7. Fast Peek Corner Exposure Detector
    p.predicted_peek_visible = false
    p.predicted_peek_tick = 0
    p.predicted_peek_pos = nil
    
    if sw_pred_peek:get() and cur_rec.speed_2d > 40 then
        local lp_pos = lp:get_eye_position()
        if lp_pos then
            for step = 1, 10 do
                local peek_pos, peek_eye = simulate_player_movement(p, ent, step)
                local tr = utils.trace_line(lp_pos, peek_eye, lp)
                if tr and tr.fraction > 0.97 then
                    p.predicted_peek_visible = true
                    p.predicted_peek_tick = step
                    p.predicted_peek_pos = peek_pos
                    break
                end
            end
        end
    end
end

-- ====================================================================
-- PLAYER UPDATE PIPELINE
-- ====================================================================
local function updatePlayer(p, ent)
    local ok_alive, alive = pcall(function() return ent:is_alive()   end)
    if not ok_alive or not alive then return end
    local ok_dorm,  dorm  = pcall(function() return ent:is_dormant() end)
    if not ok_dorm  or dorm  then return end

    local anim = SafeGetAnimState(ent)
    if not anim then return end

    local ok_ey,  eye_yaw   = pcall(function() return anim.m_flEyeYaw      end)
    local ok_fy,  feet_yaw  = pcall(function() return anim.m_flGoalFeetYaw end)
    local ok_sp,  speed     = pcall(function() return anim.m_flSpeed2D     end)
    local ok_gd,  on_ground = pcall(function() return anim.m_bOnGround     end)
    local ok_dk,  duck      = pcall(function() return anim.m_flDuckAmount  end)
    local sim_time          = SafeGetSimTime(ent)

    if not ok_ey or not eye_yaw then return end

    feet_yaw  = (ok_fy  and feet_yaw)  or 0
    speed     = (ok_sp  and speed)     or 0
    on_ground = (ok_gd  and on_ground) or true
    duck      = (ok_dk  and duck)      or 0
    
    local new_tick = (sim_time > p.curr_sim_time)
    if new_tick then
        p.original_feet_yaw = feet_yaw
        p.last_speed = p.speed
    end

    if p.original_feet_yaw == 0.0 then
        p.original_feet_yaw = feet_yaw
    end
    
    if p.curr_sim_time > 0 and sim_time > 0 then
        local ti = p.tick_interval
        local dt = sim_time - p.curr_sim_time
        p.choke = dt > 0 and clamp(math_floor(dt / ti + 0.5) - 1, 0, 16) or 0
        p.lc_broken = (dt > ti * 2) and (speed > 15)
    end
    
    p.speed      = speed
    p.duck       = duck
    p.on_ground  = on_ground
    p.desync_limit = getDesyncLimit(speed, duck, on_ground)

    decayMemory(p)
    updateAdvancedFreestand(p, ent)
    updateDesyncModel(p, ent)
    
    profilerUpdate(p, eye_yaw, p.original_feet_yaw, speed, duck, sim_time)
    defensiveUpdate(p, sim_time, speed, p.original_feet_yaw, p.prev_feet_yaw)
    
    updateMarkovTransitions(p, p.resolved_side)
    updateJitterCycle(p, p.resolved_side)
    updateThreatIntel(p, ent)
    
    p.prev_feet_yaw = p.original_feet_yaw
    
    if sw_pred_adv:get() then
        pcall(predictTargetMovement, p, ent)
    end
end

-- ====================================================================
-- DOUBLE TAP & EXPLOIT STATE CONTROLLER
-- ====================================================================
local DT_STATE_DISABLED   = 0
local DT_STATE_CHARGING   = 1
local DT_STATE_READY      = 2
local DT_STATE_FIRING     = 3
local DT_STATE_RECHARGING = 4

local dt_controller = {
    state = DT_STATE_DISABLED,
    last_charge = 0.0,
    last_fire_tick = 0,
    last_weapon_idx = -1,
    is_eligible_weapon = true,
    recharge_forced = false,
    recharge_tick = 0
}

local function is_weapon_dt_eligible(wpn_name)
    if not wpn_name or wpn_name == "none" then return false end
    local ln = wpn_name:lower():gsub(" ", ""):gsub("-", "")
    if ln:find("knife") or ln:find("grenade") or ln:find("flash") or ln:find("molotov") or ln:find("decoy") or ln:find("taser") then
        return false
    end
    return true
end

local function update_double_tap_state(lp)
    if not sw_dt_manager:get() then return end
    if not lp or not lp:is_alive() then
        dt_controller.state = DT_STATE_DISABLED
        dt_controller.recharge_forced = false
        return
    end
    
    local dt_enabled = false
    if native_dt then
        local ok, val = pcall(function() return native_dt:get() end)
        if ok and val then dt_enabled = true end
    end
    
    if not dt_enabled then
        dt_controller.state = DT_STATE_DISABLED
        dt_controller.recharge_forced = false
        return
    end
    
    local wpn = lp:get_player_weapon()
    if not wpn then
        dt_controller.state = DT_STATE_DISABLED
        dt_controller.recharge_forced = false
        return
    end
    
    local ok_widx, widx = pcall(function() return wpn:get_index() end)
    if ok_widx and widx ~= dt_controller.last_weapon_idx then
        dt_controller.last_weapon_idx = widx
        dt_controller.state = DT_STATE_CHARGING
        dt_controller.recharge_forced = false
    end
    
    local ok_name, wpn_name = pcall(function() return wpn:get_classname() end)
    dt_controller.is_eligible_weapon = ok_name and is_weapon_dt_eligible(wpn_name) or false
    if not dt_controller.is_eligible_weapon then
        dt_controller.state = DT_STATE_DISABLED
        dt_controller.recharge_forced = false
        return
    end
    
    local charge = 0.0
    if rage and rage.exploit then
        local ok, f = pcall(function() return rage.exploit:get() end)
        if ok and f then charge = f end
    end
    dt_controller.last_charge = charge
    
    local cur_tick = globals.tickcount
    if type(cur_tick) == "function" then cur_tick = cur_tick() end
    
    cur_tick = cur_tick or 0
    
    -- State transitions
    if cur_tick - dt_controller.last_fire_tick < 3 then
        dt_controller.state = DT_STATE_FIRING
    elseif charge < 0.99 then
        dt_controller.state = (cur_tick - dt_controller.last_fire_tick < 20) and DT_STATE_RECHARGING or DT_STATE_CHARGING
        -- Optimize recharge cycle if permitted
        if sw_dt_recharge:get() and charge < 0.95 then
            local mode = cb_dt_recharge_mode:get()
            if mode == 1 or mode == "Instant" then
                if not dt_controller.recharge_forced then
                    pcall(function()
                        if rage.exploit.force_charge then
                            rage.exploit:force_charge()
                        elseif rage.exploit.charge then
                            rage.exploit:charge()
                        end
                    end)
                    dt_controller.recharge_forced = true
                end
            else
                if not dt_controller.recharge_forced or (cur_tick - dt_controller.recharge_tick > 64) then
                    pcall(function()
                        if rage.exploit.force_charge then
                            rage.exploit:force_charge()
                        elseif rage.exploit.charge then
                            rage.exploit:charge()
                        end
                    end)
                    dt_controller.recharge_forced = true
                    dt_controller.recharge_tick = cur_tick
                end
            end
        end
    else
        dt_controller.state = DT_STATE_READY
        dt_controller.recharge_forced = false
    end
end

-- ====================================================================
-- RAGEBOT OVERRIDE EVALUATION
-- ====================================================================
local function shouldForceBAIM(p, hp)
    if not sw_lethal:get() then return false end
    if not p then return false end

    local conf = p.resolver_confidence or 0.50
    local cm   = p.consecutive_resolver_misses or 0

    local is_lethal = hp <= 35 or (hp <= 65 and cm >= 1)
    if is_lethal and p.lc_broken then return true end

    if conf < 0.45 and cm >= 1 then return true end
    if cm >= 2 then return true end
    
    if p.defensive_freq > 20 and p.predicted_peek_visible then return true end

    return false
end

local function shouldPreferSafe(p)
    if not sw_safepoint:get() then return false end
    if not p then return false end

    local conf = p.resolver_confidence or 0.50
    local cm   = p.consecutive_resolver_misses or 0

    if conf < 0.40 then return true end
    if cm >= 2 then return true end
    if p.is_accelerating and conf < 0.60 then return true end
    if p.defensive_freq > 30 then return true end

    return false
end

local function getBestTarget(enemies)
    local lp = entity.get_local_player()
    if not lp then return nil end
    local ok_lp, lp_eye = pcall(function() return lp:get_eye_position() end)
    if not ok_lp or not lp_eye then return nil end
    
    local lx, ly, lz = SafeGetOrigin(lp)
    local best_ent, best_score = nil, -math.huge

    for i = 1, #enemies do
        local e = enemies[i]
        local ok_a, a = pcall(function() return e:is_alive()   end)
        local ok_d, d = pcall(function() return e:is_dormant() end)
        
        if ok_a and a and ok_d and not d then
            if sw_priority:get() then
                local ex, ey, ez = SafeGetOrigin(e)
                local ok_e, e_eye = pcall(function() return e:get_eye_position() end)
                local hp = SafeGetHP(e)
                
                if ok_e and e_eye then
                    local dist = math_sqrt((lx-ex)^2 + (ly-ey)^2 + (lz-ez)^2)
                    local dist_score = math.max(0, 100 - (dist / 20.0))
                    local fov = get_crosshair_fov(lp_eye, e_eye)
                    local fov_score = math.max(0, 100 - fov)
                    local hp_score = math.max(0, 100 - hp)
                    
                    local final_score = (fov_score * 0.50) + (dist_score * 0.30) + (hp_score * 0.20)
                    
                    local eid = e:get_index()
                    local prec = EnemyRecords[eid]
                    if prec and prec.predicted_peek_visible then
                        final_score = final_score + 25.0
                    end
                    
                    if final_score > best_score then
                        best_score = final_score
                        best_ent = e
                    end
                end
            else
                local ok_o, e_o = pcall(function() return e:get_origin() end)
                local ok_l, l_o = pcall(function() return lp:get_origin() end)
                if ok_o and e_o and ok_l and l_o then
                    local dist = l_o:dist(e_o)
                    local score = -dist
                    if score > best_score then
                        best_score = score
                        best_ent = e
                    end
                end
            end
        end
    end

    return best_ent
end

-- ====================================================================
-- IDEAL TICK DETECTION & VISUAL EXPLOITS (ARC COMPATIBLE)
-- ====================================================================
local it_status_name  = ""
local it_status_ticks = 0
local it_any_active   = false

local function updateIdealTickDetect(id, ent)
    local ok_sim, sim_t = pcall(function() return ent:get_simulation_time() end)
    if not ok_sim or not sim_t then return end
    
    local cur = sim_t.current
    local old = sim_t.old
    if not cur or not old then return end

    local ti = globals.tickinterval
    if type(ti) == "function" then ti = ti() end
    
    ti = ti or 0.015625

    local delta     = cur - old
    local tick_lead = math_floor(delta / ti + 0.5) - 1
    local is_it     = (tick_lead >= 2) and (tick_lead <= 16)

    if not PredictionData[id] then
        PredictionData[id] = { is_it = false, tick_lead = 0, predicted_origin = nil, name = "", last_it = 0 }
    end

    local pd      = PredictionData[id]
    local rt = globals.realtime
    if type(rt) == "function" then rt = rt() end
    

    if is_it then
        pd.is_it      = true
        pd.tick_lead  = tick_lead
        pd.last_it    = rt
        
        local foot_orig = nil
        local eye_orig  = nil
        local ok_sim2, sim2 = pcall(function() return ent:simulate_movement() end)
        if ok_sim2 and sim2 then
            local ok_res, res = pcall(function() return sim2:think(tick_lead) end)
            if ok_res and res and res.origin then
                foot_orig = res.origin
                local view_z = res.view_offset or 64
                eye_orig  = vector(res.origin.x, res.origin.y, res.origin.z + view_z)
            end
        end
        if not foot_orig then
            local ox, oy, oz = SafeGetOrigin(ent)
            foot_orig = vector(ox, oy, oz)
        end
        if not eye_orig then
            local ok_e, e = pcall(function() return ent:get_eye_position() end)
            eye_orig = (ok_e and e) and e or vector(foot_orig.x, foot_orig.y, foot_orig.z + 64)
        end
        pd.predicted_foot   = foot_orig
        pd.predicted_origin = eye_orig
        local ok_name, ename = pcall(function() return ent:get_name() end)
        pd.name = (ok_name and ename) and ename or ""
    elseif rt - (pd.last_it or 0) > 0.5 then
        pd.is_it            = false
        pd.tick_lead        = 0
        pd.predicted_foot   = nil
        pd.predicted_origin = nil
        pd.name             = ""
    end
end

local v919 = {
    [1] = { [1] = 0, [2] = 1 }, 
    [2] = { [1] = 1, [2] = 2 }, 
    [3] = { [1] = 2, [2] = 3 }, 
    [4] = { [1] = 3, [2] = 0 }, 
    [5] = { [1] = 5, [2] = 6 }, 
    [6] = { [1] = 6, [2] = 7 }, 
    [7] = { [1] = 1, [2] = 4 }, 
    [8] = { [1] = 4, [2] = 8 }, 
    [9] = { [1] = 0, [2] = 4 }, 
    [10] = { [1] = 1, [2] = 5 }, 
    [11] = { [1] = 2, [2] = 6 }, 
    [12] = { [1] = 3, [2] = 7 }, 
    [13] = { [1] = 5, [2] = 8 }, 
    [14] = { [1] = 7, [2] = 8 }, 
    [15] = { [1] = 3, [2] = 4 }
}

local function v931(v920, v921, v922, v923, v924)
    if v920 == nil or v921 == nil or v922 == nil then
        return
    end
    if not v923 then v923 = color() end
    if not v924 then v924 = 0.15 end
    local v925 = {
        [1] = v922[1] + v921, 
        [2] = v922[2] + v921
    }
    local v926 = {
        vector(v925[1].x, v925[1].y, v925[1].z), 
        vector(v925[1].x, v925[2].y, v925[1].z), 
        vector(v925[2].x, v925[2].y, v925[1].z), 
        vector(v925[2].x, v925[1].y, v925[1].z), 
        vector(v925[1].x, v925[1].y, v925[2].z), 
        vector(v925[1].x, v925[2].y, v925[2].z), 
        vector(v925[2].x, v925[2].y, v925[2].z), 
        vector(v925[2].x, v925[1].y, v925[2].z)
    }
    for _, v928 in ipairs(v919) do
        if v926[v928[1]] ~= nil and v926[v928[2]] ~= nil then
            local v929 = v926[v928[1]]
            local v930 = v926[v928[2]]
            if v929:length2dsqr() > 0 and v930:length2dsqr() > 0 then
                v920:render(v929, v930, v924, "lgw", v923)
            end
        end
    end
end

local function v939(v932)
    if not sw_it_esp:get() or not sw_it_detect:get() then return end
    local v933 = entity.get_local_player()
    if v933 == nil or lagrecord == nil then
        return
    end
    entity.get_players(true, false, function(v934)
        local bbox = v934:get_bbox()
        if bbox == nil or bbox.pos1 == nil then
            return
        end
        local v935 = lagrecord.get_snapshot(v934)
        if v935 == nil then
            return
        end
        local l_no_entry_0 = v935.command.no_entry
        if l_no_entry_0 and l_no_entry_0.y > 0 then
            local v937 = true
            if v933.m_hObserverTarget == v934 and v933.m_iObserverMode == 5 then
                v937 = false
            end
            if v937 then
                local l_origin_0 = v935.origin
                v931(v932, v934:get_origin(), l_origin_0.volume, cp_it_esp:get(), (sl_it_thick:get() * 0.01) * 0.35 * (l_no_entry_0.x / l_no_entry_0.y))
            end
        end
    end)
end

local function v941(v940)
    return v940:is_enemy()
end

local it_glow_active = false
local function it_esp_set_active(enabled)
    if it_glow_active == enabled then return end
    it_glow_active = enabled
    if enabled then
        events.render_glow:set(v939)
        if lagrecord then pcall(lagrecord.set_update_callback, v941) end
    else
        events.render_glow:unset(v939)
        if lagrecord then pcall(lagrecord.unset_update_callback, v941) end
    end
end

local it_esp_element = esp.enemy:new_text("Ragebobs IT", "IT +12t", function(ent)
    if not sw_it_detect:get() then return nil end
    local lp = entity.get_local_player()
    if not lp then return nil end
    if lp.m_hObserverTarget == ent and lp.m_iObserverMode == 5 then return nil end

    local pd = PredictionData[ent:get_index()]
    if pd and pd.is_it then
        return "IT +" .. pd.tick_lead .. "t"
    end
    return nil
end)
it_esp_element:create()

-- ====================================================================
-- HUD & CROSSHAIR INDICATORS
-- ====================================================================
local it_font = render.load_font("Verdana", 11, "bo")
local ind_font = render.load_font("Verdana", 11, "bda")
local v2_value_cache = {}

local auto_anim_x = nil
local auto_anim_a = 0
local scout_anim_x = nil
local scout_anim_a = 0
local awp_anim_x = nil
local awp_anim_a = 0
local other_anim_x = nil
local other_anim_a = 0

local function get_aa_condition(lp)
    if not lp then return "nil" end
    local vel = lp.m_vecVelocity:length2dsqr()
    if lp.m_fFlags and bit.band(lp.m_fFlags, 1) == 0 then return "in air" end
    if lp.m_bIsScoped then return "scoped" end
    if lp.in_duck then return "crouching" end
    if vel > 5 then return "moving" else return "standing" end
end

local function get_lowest_ping()
    -- Use net_channel like OT INTERFACES for accurate latency
    local ok_net, net = pcall(function() return utils.net_channel() end)
    if ok_net and net and net.avg_latency then
        local ok_lat, latency = pcall(function() return net.avg_latency[1] end)
        if ok_lat and type(latency) == "number" then
            local ok_ur, updaterate = pcall(function() return cvar.cl_updaterate:float() end)
            if ok_ur and updaterate and updaterate > 0.001 then
                latency = latency - (0.5 / updaterate)
            end
            return tostring(math.max(0, math.floor(latency * 1000)))
        end
    end
    -- Fallback: scan players for m_iPing
    local min_ping = 999
    local players = entity.get_players(true)
    if players then
        for i=1, #players do
            local p = players[i]
            local ok, ping = pcall(function() return p:get_resource("m_iPing") end)
            if ok and type(ping) == "number" and ping > 0 and ping < min_ping then min_ping = ping end
        end
    end
    return min_ping == 999 and "0" or tostring(min_ping)
end

local v2_font = render.load_font("Verdana", 12, "ado")

register_event("render", function()
    if cb_mindam_ind:get() and it_font then
        local ss = render.screen_size()
        local c = cp_mindam_accent:get()
        
        local lp = entity.get_local_player()
        if cb_ind_style and cb_ind_style:get() == "v2 (Debug List)" then
            local active_target = entity.get_threat()
            -- Key EnemyRecords by integer index (NOT the entity object)
            local tgt_idx = active_target and (pcall(function() return active_target:get_index() end) and active_target:get_index() or nil) or nil
            local target_record = tgt_idx and EnemyRecords[tgt_idx] or nil

            -- Get target name directly from entity (not gated by sw_resolver)
            local tgt_display_name = active_mindam_target_name
            if not tgt_display_name and active_target then
                local ok_n, n = pcall(function() return active_target:get_name() end)
                if ok_n and n and n ~= "" then tgt_display_name = n end
            end
            
            local wpn_name = "none"
            if lp and lp:is_alive() then
                local wpn = lp:get_player_weapon()
                if wpn then
                    local ok_c, c_name = pcall(function() return wpn:get_classname() end)
                    if ok_c and c_name then wpn_name = c_name end
                end
            end
            local is_lethal = (active_mindam_target_name and (active_target_hp <= (active_mindam_val or 100)))
            local exploit_str = dt_controller.state ~= 0 and "DOUBLETAP" or "OFF"

            local elapsed = (ax_fire_time and ax_fire_time >= 0) and (globals.realtime - ax_fire_time) or math.huge
            local fired = elapsed <= 0.6
            
            local has_tgt = active_target ~= nil
            
            local roll = 0
            if has_tgt then
                local ok, ang = pcall(function() return active_target:get_prop("m_angEyeAngles") end)
                if ok and ang and type(ang.z) == "number" then roll = ang.z end
            end
            
            local f_roll = math.abs(roll) > 5.0
            local f_roll_side = f_roll and (roll > 0 and "Right" or "Left") or "nil"
            
            local c_ticks = target_record and target_record.choke or 0
            local res_side = target_record and target_record.resolved_side or 0
            
            local f_left = res_side == 1
            local f_right = res_side == -1
            local f_back = res_side == 0 and has_tgt
            local f_free = target_record and target_record.pattern == 0 or false
            
            local tbl_1 = target_record and tostring(target_record) or tostring(EnemyRecords)
            
            local tbl_2 = (target_record and target_record.miss_analysis) and tostring(target_record.miss_analysis) or tostring(dt_controller)
            
            -- Pull PredictionData for active target
            local tgt_id = active_target and active_target:get_index() or nil
            local pd_tgt = tgt_id and PredictionData[tgt_id] or nil

            -- ── Resolved side ─────────────────────────────────────────────
            -- Prefer target_record resolver data, fall back to raw entity choke/simtime
            local res_side_str = "center"
            if target_record then
                local rs = target_record.resolved_side or 0
                if rs == 1 then res_side_str = "left"
                elseif rs == -1 then res_side_str = "right"
                else res_side_str = "center" end
            elseif not active_target then
                res_side_str = "none"
            end

            -- ── Pattern name ───────────────────────────────────────────────
            local PAT_NAMES = {"static","micro_jit","jitter","delayed_jit","random_jit","flick","fake_flick","spin","defensive","hybrid"}
            local pat_str
            if target_record then
                pat_str = PAT_NAMES[(target_record.pattern or 0) + 1] or "static"
            else
                pat_str = active_target and "static" or "none"
            end

            -- ── Exploit analysis ───────────────────────────────────────────
            local ea = target_record and target_record.exploit_analysis or {}
            local exploit_flags = {}
            if ea.double_tap     then exploit_flags[#exploit_flags+1] = "DT" end
            if ea.hide_shots     then exploit_flags[#exploit_flags+1] = "HS" end
            if ea.fake_lag       then exploit_flags[#exploit_flags+1] = "FL" end
            if ea.tickbase_manip then exploit_flags[#exploit_flags+1] = "TB" end
            local exploit_flags_str = #exploit_flags > 0 and table.concat(exploit_flags, "+") or "none"

            -- ── Miss breakdown ─────────────────────────────────────────────
            local ma = target_record and target_record.miss_analysis or {}
            local miss_str = string.format("r:%d sp:%d pr:%d oc:%d",
                ma.resolver_misses or 0, ma.spread_misses or 0,
                ma.prediction_misses or 0, ma.occlusion_misses or 0)

            -- ── Resolver confidence ────────────────────────────────────────
            local conf_str = target_record
                and string.format("%d%%", math.floor(target_record.confidence or 50))
                or (active_target and "50%" or "0%")  -- default 50 when target exists but no record

            -- ── Resolver lock ──────────────────────────────────────────────
            local rl = target_record and target_record.resolver_lock or {}
            local lock_str = rl.locked
                and ("locked:" .. (rl.locked_side == 1 and "L" or rl.locked_side == -1 and "R" or "C"))
                or "free"

            -- ── Freestand side ─────────────────────────────────────────────
            -- Fall back to rage.antiaim freestand detection if no record
            local fs_side_str = "none"
            if target_record then
                local fs = target_record.freestand_side or 0
                if fs == 1 then fs_side_str = "left"
                elseif fs == -1 then fs_side_str = "right"
                else fs_side_str = "center" end
            elseif active_target then
                -- Try rage.antiaim freestand target as proxy
                local ok_t, t  = pcall(function() return rage.antiaim:get_target()       end)
                local ok_i, ti = pcall(function() return rage.antiaim:get_target(true)   end)
                if ok_t and ok_i and t and ti then
                    local diff = math.abs(((t - ti + 540) % 360) - 180)
                    fs_side_str = diff > 5 and "active" or "center"
                else
                    fs_side_str = "center"
                end
            end

            -- ── Choke ticks ────────────────────────────────────────────────
            -- target_record.choke OR derive from simtime delta
            local choke_val = 0
            if target_record then
                choke_val = target_record.choke or 0
            elseif active_target then
                local ok_s, sim = pcall(function() return active_target.m_flSimulationTime end)
                if ok_s and sim and sim > 0 then
                    local ti = globals.tickinterval or 0.015625
                    local expected_sim = globals.curtime or 0
                    local raw_delta = expected_sim - sim
                    if raw_delta > 0 then
                        choke_val = math.max(0, math.floor(raw_delta / ti + 0.5) - 1)
                    end
                end
            end
            local choke_str = string.format("%dt", choke_val)

            -- ── Prediction / IT ────────────────────────────────────────────
            local it_phase_str, it_lead_str, it_source_str
            if pd_tgt and pd_tgt.is_it then
                it_phase_str  = "armed"
                it_lead_str   = tostring(pd_tgt.tick_lead) .. "t"
                it_source_str = "ideal_tick"
            elseif target_record and target_record.predicted_peek_visible then
                it_phase_str  = "peek"
                it_lead_str   = tostring(target_record.predicted_peek_tick or 0) .. "t"
                it_source_str = "extrapolate"
            else
                it_phase_str  = "none"
                it_lead_str   = "0t"
                it_source_str = "none"
            end

            -- Real prediction confidence
            local pred_conf_str = target_record
                and string.format("%d%%", math.floor((target_record.prediction_confidence or 0.5) * 100))
                or (active_target and "50%" or "0%")

            -- ── Target speed (direct entity read) ─────────────────────────
            local tgt_speed_str = "0"
            if active_target then
                local ok_v, v = pcall(function() return active_target.m_vecVelocity end)
                if ok_v and v then
                    tgt_speed_str = string.format("%.0f", math.sqrt(v.x*v.x + v.y*v.y))
                end
            end

            -- ── Roll detection ─────────────────────────────────────────────
            local roll_val = roll ~= 0
                and string.format("%.1f %s", math.abs(roll), roll > 0 and "R" or "L")
                or "0"

            -- ── DT controller state name ───────────────────────────────────
            local DT_STATE_NAMES = {"off","ready","fired","recharge"}
            local dt_state_name = DT_STATE_NAMES[math.max(1, (dt_controller.state or 0) + 1)] or "off"

            -- ── Consecutive misses ─────────────────────────────────────────
            local consec_str = tostring(target_record and target_record.consecutive_misses or 0)

            local vars = {
                -- Target info
                {"target",          tgt_display_name or "none"},
                {"target_speed",    tgt_speed_str .. " u/s"},
                {"target_hp",       tostring(active_target_hp)},
                {"no_choke",        fired and "FIRED" or "idle",
                                    fired and color(80, 255, 100, 255) or color(160, 160, 160, 255)},
                {"anti_aim_cond",   get_aa_condition(lp)},
                {""},
                -- Resolver
                {"resolved_side",   res_side_str},
                {"resolver_conf",   conf_str},
                {"resolver_lock",   lock_str},
                {"pattern",         pat_str},
                {"consec_misses",   consec_str},
                {"miss_detail",     miss_str},
                {""},
                -- Exploit analysis
                {"exploits_active", exploit_flags_str},
                {"dt_state",        dt_state_name},
                {"dangerous",       tostring(target_record and target_record.is_dangerous or false)},
                {"choke_ticks",     choke_str},
                {"teleporting",     tostring(c_ticks > 14)},
                {""},
                -- Anti-aim read
                {"desync_side",     res_side_str},
                {"roll_angle",      roll_val},
                {"freestand_side",  fs_side_str},
                {""},
                -- Prediction / IT
                {"pred_source",     it_source_str},
                {"pred_confidence", pred_conf_str},
                {"it_phase",        it_phase_str},
                {"it_lead",         it_lead_str},
                {"prediction_miss", tostring(ma.prediction_misses or 0)},
                {"occlusion_miss",  tostring(ma.occlusion_misses or 0)},
                {""},
                -- Own AA
                {"lp_aa_cond",      get_aa_condition(lp)},
                {"lowest_ping",     get_lowest_ping() .. "ms"},
            }
            
            local text_x = ss.x * 0.70
            local text_y = ss.y * 0.40
            local cur_rt = globals.realtime
            
            for i=1, #vars do
                if vars[i][1] == "" then
                    text_y = text_y + 12
                else
                    local key = vars[i][1]
                    local val = vars[i][2]
                    
                    if not v2_value_cache[key] then
                        v2_value_cache[key] = {v = val, t = cur_rt}
                    elseif v2_value_cache[key].v ~= val then
                        v2_value_cache[key].v = val
                        v2_value_cache[key].t = cur_rt
                    end
                    
                    local time_since = cur_rt - v2_value_cache[key].t
                    local rgb = 255
                    local a = 255
                    
                    if time_since > 0.1 then
                        local fade = math.min(1.0, (time_since - 0.1) / 1.0)
                        rgb = 255 - (105 * fade) -- fades down to 150
                        a = 255 - (105 * fade)   -- fades down to 150
                    end
                    
                    local line_text = key .. ": " .. val
                    local line_color = vars[i][3] or color(math.floor(rgb), math.floor(rgb), math.floor(rgb), math.floor(a))
                    render.text(1, vector(text_x, text_y), line_color, nil, line_text)
                    text_y = text_y + 12
                end
            end
            
            return
        end
        local is_scoped = false
        local wpn_name = "none"
        
        if lp and lp:is_alive() then
            is_scoped = lp.m_bIsScoped
            local wpn = lp:get_player_weapon()
            if wpn then
                local ok_c, c_name = pcall(function() return wpn:get_classname() end)
                if ok_c and c_name then
                    wpn_name = c_name
                end
            end
        end
        
        local is_autosniper = false
        local is_scout = false
        local is_awp = false
        local is_other = false
        if wpn_name ~= "none" then
            local ln = wpn_name:lower():gsub(" ", ""):gsub("-", "")
            if ln:find("scar") or ln:find("g3sg1") then
                is_autosniper = true
            elseif ln:find("ssg08") then
                is_scout = true
            elseif ln:find("awp") then
                is_awp = true
            else
                is_other = true
            end
        end
        
        auto_anim_a = math_floor(auto_anim_a + ((is_autosniper and 255 or 0) - auto_anim_a) * globals.frametime * 12)
        scout_anim_a = math_floor(scout_anim_a + ((is_scout and 255 or 0) - scout_anim_a) * globals.frametime * 12)
        awp_anim_a = math_floor(awp_anim_a + ((is_awp and 255 or 0) - awp_anim_a) * globals.frametime * 12)
        other_anim_a = math_floor(other_anim_a + ((is_other and 255 or 0) - other_anim_a) * globals.frametime * 12)
        
        -- Exploit State Calculation
        local hs_on = false
        if native_hs then
            local ok, val = pcall(function() return native_hs:get() end)
            if ok and val then hs_on = true end
        end
        local fd_on = false
        if native_fd then
            local ok, val = pcall(function() return native_fd:get() end)
            if ok and val then fd_on = true end
        end
        local dt_on = false
        if native_dt then
            local ok, val = pcall(function() return native_dt:get() end)
            if ok and val then dt_on = true end
        end
        local charge_val = dt_controller.last_charge
        
        local is_reloading = false
        if lp and lp:is_alive() then
            local wpn = lp:get_player_weapon()
            if wpn then
                local ok_l, layers = pcall(SafeGetAnimLayers, lp)
                if ok_l and layers then
                    local l1 = layers[1]
                    if l1.m_flWeight > 0.1 and l1.m_flPlaybackRate > 0 and l1.m_flPlaybackRate < 0.6 then
                        is_reloading = true
                    end
                end
                if not is_reloading then
                    local ok_inr, in_reload = pcall(function() return wpn:get_prop("m_bInReload") end)
                    if ok_inr and (in_reload == true or in_reload == 1) then
                        is_reloading = true
                    end
                end
                if not is_reloading then
                    local ok_clip, clip = pcall(function() return wpn:get_prop("m_iClip1") end)
                    if ok_clip and clip == 0 and is_weapon_dt_eligible(wpn_name) then
                        is_reloading = true
                    end
                end
            end
        end
        
        local function draw_exploit_state(center_x, y_offset, anim_a)
            if not sw_mindam_exploit_state:get() then return y_offset end
            
            if sw_ambatukam_exploit:get() then
                local elapsed = (ax_fire_time >= 0) and (globals.realtime - ax_fire_time) or math.huge
                local fired = elapsed <= 0.6
                local text_no_choke = "no_choke: " .. (fired and "FIRED" or "idle")
                local nc_size = render.measure_text(1, nil, text_no_choke)
                local nc_color = fired and color(80, 255, 100, anim_a) or color(160, 160, 160, anim_a)
                render.text(1, vector(center_x - (nc_size.x / 2), y_offset), nc_color, nil, text_no_choke)
                y_offset = y_offset + 12
            end

            local exploits = {}
            
            if fd_on then
                exploits[#exploits+1] = {text="FD ACTIVE", color=color(255, 200, 50, anim_a)}
            end
            if hs_on then
                exploits[#exploits+1] = {text="HS READY", color=color(50, 255, 50, anim_a)}
            end
            
            if dt_on and dt_controller.state ~= 0 then
                if fd_on then
                    exploits[#exploits+1] = {text="HOLDING", color=color(255, 150, 50, anim_a)}
                elseif charge_val < 0.99 then
                    exploits[#exploits+1] = {text="RECHARGING", color=color(255, 150, 50, anim_a)}
                else
                    exploits[#exploits+1] = {text="DOUBLETAP", color=color(50, 255, 50, anim_a)}
                end
                
                if not fd_on and sw_dt_recharge:get() then
                    local mode = cb_dt_recharge_mode:get()
                    if mode == 1 or mode == "Instant" then
                        exploits[#exploits+1] = {text="INSTANT", color=color(50, 255, 255, anim_a)}
                    else
                        exploits[#exploits+1] = {text="FASTER", color=color(50, 255, 255, anim_a)}
                    end
                end
            end
            
            if sw_ambatukam_exploit:get() then
                exploits[#exploits+1] = {text="AX", color=color(200, 100, 255, anim_a)}
            end
            
            if is_reloading then
                exploits[#exploits+1] = {text="RELOADING", color=color(255, 100, 100, anim_a)}
            end
            
            if #exploits == 0 then
                local text_exp = "exploit: OFF"
                local exp_size = render.measure_text(1, nil, text_exp)
                render.text(1, vector(center_x - (exp_size.x / 2), y_offset), color(150, 150, 150, anim_a), nil, text_exp)
                return y_offset + 12
            else
                for i = 1, #exploits do
                    local exp = exploits[i]
                    local prefix = (i == 1) and "exploit: " or "         "
                    local text_exp = prefix .. exp.text
                    local exp_size = render.measure_text(1, nil, text_exp)
                    render.text(1, vector(center_x - (exp_size.x / 2), y_offset), exp.color, nil, text_exp)
                    y_offset = y_offset + 12
                end
                return y_offset
            end
        end
        
        -- AUTOSNIPER BLOCK
        if auto_anim_a >= 1 then
            local text_main = "suprise+"
            local text_size = render.measure_text(ind_font, nil, text_main)
            local target_x = is_scoped and (ss.x / 2 + 15) or (ss.x / 2 - text_size.x / 2)
            if not auto_anim_x then auto_anim_x = target_x end
            auto_anim_x = auto_anim_x + (target_x - auto_anim_x) * globals.frametime * 15
            
            local y_offset = ss.y / 2 + 30
            local start_x = auto_anim_x
            local center_x = start_x + (text_size.x / 2)
            
            if sw_mindam_glow:get() then
                render.shadow(vector(start_x, y_offset + 7), vector(start_x + text_size.x, y_offset + 7), color(c.r, c.g, c.b, auto_anim_a), 80, 0)
            end
            if sw_mindam_exploit:get() then
                render.text(ind_font, vector(start_x, y_offset), color(c.r, c.g, c.b, auto_anim_a), nil, text_main)
                y_offset = y_offset + 12
            end
            
            local text_wpn = "wpn: " .. wpn_name
            local wpn_size = render.measure_text(1, nil, text_wpn)
            render.text(1, vector(center_x - (wpn_size.x / 2), y_offset), color(255, 255, 255, auto_anim_a), nil, text_wpn)
            
            y_offset = y_offset + 12
            local text_target = "target: " .. (active_mindam_target_name and active_mindam_target_name or "none")
            local tgt_size = render.measure_text(1, nil, text_target)
            render.text(1, vector(center_x - (tgt_size.x / 2), y_offset), color(255, 255, 255, auto_anim_a), nil, text_target)
            
            y_offset = y_offset + 12
            local text_md = "min_dmg: " .. (is_mindam_active and tostring(active_mindam_val) or "idle")
            local md_size = render.measure_text(1, nil, text_md)
            render.text(1, vector(center_x - (md_size.x / 2), y_offset), color(255, 255, 255, auto_anim_a), nil, text_md)
            
            y_offset = y_offset + 12
            y_offset = draw_exploit_state(center_x, y_offset, auto_anim_a)
        end
        
        -- SCOUT BLOCK
        if scout_anim_a >= 1 then
            local text_main = "idealtickers+"
            local text_size = render.measure_text(ind_font, nil, text_main)
            local target_x = is_scoped and (ss.x / 2 + 15) or (ss.x / 2 - text_size.x / 2)
            if not scout_anim_x then scout_anim_x = target_x end
            scout_anim_x = scout_anim_x + (target_x - scout_anim_x) * globals.frametime * 15
            
            local y_offset = ss.y / 2 + 30
            local start_x = scout_anim_x
            local center_x = start_x + (text_size.x / 2)
            
            if sw_mindam_glow:get() then
                render.shadow(vector(start_x, y_offset + 7), vector(start_x + text_size.x, y_offset + 7), color(c.r, c.g, c.b, scout_anim_a), 80, 0)
            end
            if sw_mindam_exploit:get() then
                render.text(ind_font, vector(start_x, y_offset), color(c.r, c.g, c.b, scout_anim_a), nil, text_main)
                y_offset = y_offset + 12
            end
            
            local text_wpn = "wpn: " .. wpn_name
            local wpn_size = render.measure_text(1, nil, text_wpn)
            render.text(1, vector(center_x - (wpn_size.x / 2), y_offset), color(255, 255, 255, scout_anim_a), nil, text_wpn)
            
            y_offset = y_offset + 12
            local tgt_name = active_mindam_target_name or "none"
            local text_target = "target: " .. tgt_name
            local tgt_size = render.measure_text(1, nil, text_target)
            render.text(1, vector(center_x - (tgt_size.x / 2), y_offset), color(255, 255, 255, scout_anim_a), nil, text_target)
            
            y_offset = y_offset + 12
            local is_lethal = (active_mindam_target_name and active_target_hp <= 75)
            local text_lethal = "lethal: " .. (is_lethal and "YES" or "NO")
            local lethal_color = is_lethal and color(255, 50, 50, scout_anim_a) or color(255, 255, 255, scout_anim_a)
            local lethal_size = render.measure_text(1, nil, text_lethal)
            render.text(1, vector(center_x - (lethal_size.x / 2), y_offset), lethal_color, nil, text_lethal)
            
            y_offset = y_offset + 12
            y_offset = draw_exploit_state(center_x, y_offset, scout_anim_a)
        end
        
        -- AWP BLOCK
        if awp_anim_a >= 1 then
            local text_main = "heavymachines+"
            local text_size = render.measure_text(ind_font, nil, text_main)
            local target_x = is_scoped and (ss.x / 2 + 15) or (ss.x / 2 - text_size.x / 2)
            if not awp_anim_x then awp_anim_x = target_x end
            awp_anim_x = awp_anim_x + (target_x - awp_anim_x) * globals.frametime * 15
            
            local y_offset = ss.y / 2 + 30
            local start_x = awp_anim_x
            local center_x = start_x + (text_size.x / 2)
            
            if sw_mindam_glow:get() then
                render.shadow(vector(start_x, y_offset + 7), vector(start_x + text_size.x, y_offset + 7), color(c.r, c.g, c.b, awp_anim_a), 80, 0)
            end
            if sw_mindam_exploit:get() then
                render.text(ind_font, vector(start_x, y_offset), color(c.r, c.g, c.b, awp_anim_a), nil, text_main)
                y_offset = y_offset + 12
            end
            
            local text_wpn = "wpn: " .. wpn_name
            local wpn_size = render.measure_text(1, nil, text_wpn)
            render.text(1, vector(center_x - (wpn_size.x / 2), y_offset), color(255, 255, 255, awp_anim_a), nil, text_wpn)
            
            y_offset = y_offset + 12
            local tgt_name = active_mindam_target_name or "none"
            local text_target = "target: " .. tgt_name
            local tgt_size = render.measure_text(1, nil, text_target)
            render.text(1, vector(center_x - (tgt_size.x / 2), y_offset), color(255, 255, 255, awp_anim_a), nil, text_target)
            
            y_offset = y_offset + 12
            local is_lethal = (active_mindam_target_name and active_target_hp <= 115)
            local text_lethal = "lethal: " .. (is_lethal and "YES" or "NO")
            local lethal_color = is_lethal and color(255, 50, 50, awp_anim_a) or color(255, 255, 255, awp_anim_a)
            local lethal_size = render.measure_text(1, nil, text_lethal)
            render.text(1, vector(center_x - (lethal_size.x / 2), y_offset), lethal_color, nil, text_lethal)
            
            y_offset = y_offset + 12
            y_offset = draw_exploit_state(center_x, y_offset, awp_anim_a)
        end
        
        -- OTHER WEAPONS BLOCK
        if other_anim_a >= 1 then
            local text_main = "unaffected+"
            local text_size = render.measure_text(ind_font, nil, text_main)
            local target_x = is_scoped and (ss.x / 2 + 15) or (ss.x / 2 - text_size.x / 2)
            if not other_anim_x then other_anim_x = target_x end
            other_anim_x = other_anim_x + (target_x - other_anim_x) * globals.frametime * 15
            
            local y_offset = ss.y / 2 + 30
            local start_x = other_anim_x
            local center_x = start_x + (text_size.x / 2)
            
            if sw_mindam_glow:get() then
                render.shadow(vector(start_x, y_offset + 7), vector(start_x + text_size.x, y_offset + 7), color(c.r, c.g, c.b, other_anim_a), 80, 0)
            end
            if sw_mindam_exploit:get() then
                render.text(ind_font, vector(start_x, y_offset), color(c.r, c.g, c.b, other_anim_a), nil, text_main)
                y_offset = y_offset + 12
            end
            
            local text_wpn = "wpn: " .. wpn_name
            local wpn_size = render.measure_text(1, nil, text_wpn)
            render.text(1, vector(center_x - (wpn_size.x / 2), y_offset), color(255, 255, 255, other_anim_a), nil, text_wpn)
            
            y_offset = y_offset + 12
            local tgt_name = active_mindam_target_name or "none"
            local text_target = "target: " .. tgt_name
            local tgt_size = render.measure_text(1, nil, text_target)
            render.text(1, vector(center_x - (tgt_size.x / 2), y_offset), color(255, 255, 255, other_anim_a), nil, text_target)
            
            y_offset = y_offset + 12
            local is_lethal = (active_mindam_target_name and active_target_hp <= 100)
            local text_lethal = "lethal: " .. (is_lethal and "YES" or "NO")
            local lethal_color = is_lethal and color(255, 50, 50, other_anim_a) or color(255, 255, 255, other_anim_a)
            local lethal_size = render.measure_text(1, nil, text_lethal)
            render.text(1, vector(center_x - (lethal_size.x / 2), y_offset), lethal_color, nil, text_lethal)
            
            y_offset = y_offset + 12
            y_offset = draw_exploit_state(center_x, y_offset, other_anim_a)
        end
    end
end)

-- ====================================================================
-- SHOT STATISTICS & MATRIX
-- ====================================================================
local shot_matrix = {}

local function recordShot(steamid, state, choke, resolver_confidence, defensive_confidence, lc_state, archetype, hitgroup, result)
    if not shot_matrix[steamid] then
        shot_matrix[steamid] = {
            history = {},
            stats = {
                standing = { shots = 0, hits = 0, misses = 0, accuracy = 0.0 },
                moving = { shots = 0, hits = 0, misses = 0, accuracy = 0.0 },
                air = { shots = 0, hits = 0, misses = 0, accuracy = 0.0 },
                exploit = { shots = 0, hits = 0, misses = 0, accuracy = 0.0 }
            }
        }
    end
    
    local entry = {
        state = state,
        choke = choke,
        resolver_confidence = resolver_confidence,
        defensive_confidence = defensive_confidence,
        lc_state = lc_state,
        archetype = archetype,
        hitgroup = hitgroup,
        result = result
    }
    
    local data = shot_matrix[steamid]
    table_insert(data.history, entry)
    if #data.history > 1000 then
        table_remove(data.history, 1)
    end
    
    local stats = data.stats[state]
    if stats then
        stats.shots = stats.shots + 1
        if result == "hit" then
            stats.hits = stats.hits + 1
        else
            stats.misses = stats.misses + 1
        end
        stats.accuracy = stats.hits / stats.shots
    end
end

-- ====================================================================
-- EVENT HANDLERS
-- ====================================================================
register_event("net_update_start", function()
    local resolver_on = sw_resolver:get()
    local it_on       = sw_it_detect:get()
    local pred_on     = sw_pred_adv:get()
    if not resolver_on and not it_on and not pred_on then return end

    local lp = entity.get_local_player()
    if not lp then return end
    local enemies = entity.get_players(true, false)
    if not enemies then return end

    it_any_active = false

    for i = 1, #enemies do
        local ent = enemies[i]
        if ent ~= lp then
            local ok_id, id = pcall(function() return ent:get_index() end)
            if ok_id and id then
                local ok_a, a = pcall(function() return ent:is_alive()   end)
                local ok_d, d = pcall(function() return ent:is_dormant() end)

                if (ok_a and a) and not (ok_d and d) then
                    if not EnemyRecords[id] then
                        EnemyRecords[id] = newSlot(id)
                    end
                    
                    if resolver_on or pred_on then
                        pcall(updatePlayer, EnemyRecords[id], ent)
                    end
                    
                    if it_on then
                        pcall(updateIdealTickDetect, id, ent)
                        local pd = PredictionData[id]
                        if pd and pd.is_it then
                            it_any_active   = true
                            it_status_name  = pd.name
                            it_status_ticks = pd.tick_lead
                        end
                    end
                else
                    EnemyRecords[id]  = nil
                    PredictionData[id] = nil
                end
            end
        end
    end
end)

register_event("aim_fire", function(e)
    if not e then return end
    
    if sw_ambatukam_exploit:get() then
        ax_send_packet = true
        ax_fire_time = globals.realtime
    end
    
    local cur_tick = globals.tickcount
    if type(cur_tick) == "function" then cur_tick = cur_tick() end
    
    dt_controller.last_fire_tick = cur_tick or 0
    
    local p = EnemyRecords[e.target]
    if not p then return end
    
    aimbot_data[e.id] = {
        target   = e.target,
        hitgroup = e.hitgroup,
        state = getTargetState(p),
        choke = p.choke or 0,
        resolver_confidence = p.resolver_confidence or 0.50,
        defensive_confidence = p.resolver_memory.defensive.confidence or 0.0,
        lc_state = p.lc_broken and "broken" or "valid",
        archetype = p.pattern or 0
    }
end)

register_event("aim_ack", function(e)
    if not e then return end
    local shot = aimbot_data[e.id]
    if not shot then return end
    aimbot_data[e.id] = nil

    local p = EnemyRecords[shot.target]
    if not p then return end

    p.consecutive_misses = 0
    p.consecutive_resolver_misses = 0
    
    local confidence_gain = 0.15
    if shot.state == "moving" then confidence_gain = 0.25 end
    if shot.hitgroup == 1 then confidence_gain = 0.35 end
    
    p.resolver_confidence = (p.resolver_confidence or 0.50) + confidence_gain
    if p.resolver_confidence > 1.0 then p.resolver_confidence = 1.0 end
    
    recordShot(shot.target, shot.state, shot.choke, shot.resolver_confidence, shot.defensive_confidence, shot.lc_state, shot.archetype, shot.hitgroup, "hit")
    writeShotBuf(p.shot_buf, shot.target, 0, e.hitgroup, true, "")
end)

register_event("aim_miss", function(e)
    if not e then return end
    local shot = aimbot_data[e.id]
    if not shot then return end
    aimbot_data[e.id] = nil

    local p = EnemyRecords[shot.target]
    if not p then return end

    local reason = (type(e.reason) == "string") and e.reason:lower() or "unknown"
    p.consecutive_misses = (p.consecutive_misses or 0) + 1
    
    if reason == "resolver" or reason == "correction" then
        p.miss_analysis.resolver_misses = p.miss_analysis.resolver_misses + 1
        p.consecutive_resolver_misses = (p.consecutive_resolver_misses or 0) + 1
        
        p.resolver_confidence = (p.resolver_confidence or 0.50) - 0.20
        if p.resolver_confidence < 0.1 then p.resolver_confidence = 0.1 end
        
        recordShot(shot.target, shot.state, shot.choke, shot.resolver_confidence, shot.defensive_confidence, shot.lc_state, shot.archetype, shot.hitgroup, "miss")
    elseif reason == "spread" then
        p.miss_analysis.spread_misses = p.miss_analysis.spread_misses + 1
    elseif reason == "prediction" or reason == "prediction error" then
        p.miss_analysis.prediction_misses = p.miss_analysis.prediction_misses + 1
    elseif reason == "occlusion" or reason == "wall" then
        p.miss_analysis.occlusion_misses = p.miss_analysis.occlusion_misses + 1
    end
    
    writeShotBuf(p.shot_buf, shot.target, 0, shot.hitgroup, false, reason)
end)

register_event("player_hurt", function(e)
    if not e then return end
    local lp = entity.get_local_player()
    if not lp then return end
    local lp_idx = lp:get_index()
    
    local victim_ent = getPlayerByUserid(e.userid)
    local attacker_ent = getPlayerByUserid(e.attacker)
    
    if victim_ent and victim_ent:get_index() == lp_idx and attacker_ent then
        local attacker_idx = attacker_ent:get_index()
        local p = EnemyRecords[attacker_idx]
        if p then
            p.threat_intel.hits_on_us = p.threat_intel.hits_on_us + 1
        end
    end
end)

register_event("weapon_fire", function(e)
    if not e then return end
    local shooter_ent = getPlayerByUserid(e.userid)
    if shooter_ent then
        local shooter_idx = shooter_ent:get_index()
        local p = EnemyRecords[shooter_idx]
        if p then
            p.threat_intel.shots_fired = p.threat_intel.shots_fired + 1
        end
    end
end)

-- Unified Centralized Createmove Handler (Eliminates callback overwrite conflicts)
register_event("createmove", function(cmd)
    if sw_ambatukam_exploit:get() and ax_send_packet then
        cmd.no_choke = true
        ax_send_packet = false
    end

    -- 1. Exploit Visual Glow Activation
    it_esp_set_active(sw_it_esp:get() and sw_it_detect:get())

    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then
        if last_baim   ~= nil then if native_baim   then native_baim:override()   end; last_baim   = nil  end
        if last_safe   ~= nil then if native_safe   then native_safe:override()   end; last_safe   = nil  end
        if last_mindam ~= -1  then if native_mindam then native_mindam:override() end; last_mindam = -1   end
        is_mindam_active = false
        active_mindam_target_name = nil
        active_target_hp = 100
        active_mindam_val = 0
        return
    end

    -- 2. Update Double Tap & Exploit State Controller
    update_double_tap_state(lp)

    -- 3. Ragebot & Resolver Overrides
    if not sw_resolver:get() then
        if last_baim   ~= nil then if native_baim   then native_baim:override()   end; last_baim   = nil  end
        if last_safe   ~= nil then if native_safe   then native_safe:override()   end; last_safe   = nil  end
        if last_mindam ~= -1  then if native_mindam then native_mindam:override() end; last_mindam = -1   end
        is_mindam_active = false
        active_mindam_target_name = nil
        active_target_hp = 100
        active_mindam_val = 0
        return
    end

    local enemies = entity.get_players(true, false)
    if not enemies or #enemies == 0 then
        if last_baim   ~= nil then if native_baim   then native_baim:override()   end; last_baim   = nil end
        if last_safe   ~= nil then if native_safe   then native_safe:override()   end; last_safe   = nil end
        if last_mindam ~= -1  then if native_mindam then native_mindam:override() end; last_mindam = -1  end
        is_mindam_active = false
        active_mindam_target_name = nil
        active_target_hp = 100
        active_mindam_val = 0
        return
    end

    local best = getBestTarget(enemies)
    
    is_mindam_active = false
    active_mindam_target_name = nil
    active_target_hp = 100
    active_mindam_val = 0
    
    if best then
        local ok, name = pcall(function() return best:get_name() end)
        if ok and name then
            active_mindam_target_name = name:lower()
        end
        active_target_hp = SafeGetHP(best)
    end
    
    if not best then
        if last_baim   ~= nil then if native_baim   then native_baim:override()   end; last_baim   = nil end
        if last_safe   ~= nil then if native_safe   then native_safe:override()   end; last_safe   = nil end
        if last_mindam ~= -1  then if native_mindam then native_mindam:override() end; last_mindam = -1  end
        return
    end

    local ok_bid, bid = pcall(function() return best:get_index() end)
    if not ok_bid then return end

    local p = EnemyRecords[bid]
    if not p then
        if last_baim   ~= nil then if native_baim   then native_baim:override()   end; last_baim   = nil end
        if last_safe   ~= nil then if native_safe   then native_safe:override()   end; last_safe   = nil end
        if last_mindam ~= -1  then if native_mindam then native_mindam:override() end; last_mindam = -1  end
        return
    end

    local hp = SafeGetHP(best)

    -- BAIM Override
    local want_baim = shouldForceBAIM(p, hp)
    if want_baim then
        if last_baim ~= "force" then
            if native_baim then native_baim:override("force") end
            last_baim = "force"
        end
    else
        if last_baim ~= nil then
            if native_baim then native_baim:override() end
            last_baim = nil
        end
    end

    -- Safepoint Override
    local want_safe = shouldPreferSafe(p)
    if want_safe then
        local mode = (p.consecutive_resolver_misses >= 2) and "force" or "prefer"
        if last_safe ~= mode then
            if native_safe then native_safe:override(mode) end
            last_safe = mode
        end
    else
        if last_safe ~= nil then
            if native_safe then native_safe:override() end
            last_safe = nil
        end
    end

    -- Minimum Damage Override with DT & Fast Peek Awareness
    local target_md = -1
    local ok_vis, vis = pcall(function() return best:is_visible() end)
    
    if sw_lethal:get() and ok_vis and vis and hp < 50 then
        target_md = math_min(hp + 1, 100)
        if dt_controller.state == DT_STATE_READY then
            local ok_md, base_md = pcall(function() return native_mindam:get() end)
            if ok_md and base_md then
                target_md = math_max(1, math_floor(base_md * 0.6))
            end
        end
        active_mindam_val = target_md
        is_mindam_active = true
    elseif p.predicted_peek_visible and sw_it_mindam:get() then
        -- Fast Peek open-angle engagement: lower damage slightly so ragebot triggers on emergence
        local ok_md, base_md = pcall(function() return native_mindam:get() end)
        if ok_md and base_md then
            target_md = math_min(math_max(1, math_floor(base_md * 0.7)), hp + 1)
            active_mindam_val = target_md
            is_mindam_active = true
        end
    elseif p.consecutive_resolver_misses >= 1 then
        local ok_md, base_md = pcall(function() return native_mindam:get() end)
        if ok_md and base_md then
            local factor = math_max(0.4, 1.0 - (p.consecutive_resolver_misses * 0.15))
            target_md = math_max(1, math_floor(base_md * factor))
            active_mindam_val = target_md
            is_mindam_active = true
        end
    end

    local is_it = false
    if not p.md_last_trigger then p.md_last_trigger = 0 end
    
    local ok_sim, sim_t = pcall(function() return best:get_simulation_time() end)
    if ok_sim and sim_t and sim_t.current and sim_t.old then
        local delta = sim_t.current - sim_t.old
        local ti = globals.tickinterval
    if type(ti) == "function" then ti = ti() end
        
        local tick_lead = math_floor(delta / (ti or 0.015625) + 0.5) - 1
        if tick_lead >= 2 and tick_lead <= 16 then
            local rt = globals.realtime
    if type(rt) == "function" then rt = rt() end
            p.md_last_trigger = type(rt) == "function" and rt() or rt
        end
    end
    
    local cur_t = globals.realtime
    if type(cur_t) == "function" then cur_t = cur_t() end
    
    is_it = (cur_t - p.md_last_trigger) < 0.5

    local is_auto = false
    local wpn = lp and lp:get_player_weapon()
    if wpn then
        local ok_w, w_name = pcall(function() return wpn:get_classname() end)
        if ok_w and w_name then
            local ln = w_name:lower()
            if ln:find("scar") or ln:find("g3sg1") then
                is_auto = true
            end
        end
    end

    if is_it and sw_it_mindam:get() and is_auto then
        local base_md = (native_mindam and native_mindam:get()) or 100
        
        -- Fully dynamic IT min-damage scaling based on HP and confidence
        local hp_factor = (hp / 100) * 0.6
        local dynamic_factor = math_max(0.30, math_min(0.5, math_min(hp_factor, (p.resolver_confidence or 0.50))))
        
        target_md = math_min(math_floor(base_md * dynamic_factor), hp + 1)
        active_mindam_val = target_md
        is_mindam_active = true
    elseif sw_resolver:get() and (p.resolver_confidence or 0.50) < 0.50 then
        local base_md = (native_mindam and native_mindam:get()) or 100
        local reduction_factor = math_max(0.4, (p.resolver_confidence or 0.50) * 1.5)
        target_md = math_min(math_floor(base_md * reduction_factor), hp + 1)
        active_mindam_val = target_md
        is_mindam_active = true
    end

    if target_md ~= -1 then
        if last_mindam ~= target_md then
            if native_mindam then native_mindam:override(target_md) end
            last_mindam = target_md
        end
    else
        if last_mindam ~= -1 then
            if native_mindam then native_mindam:override() end
            last_mindam = -1
        end
    end
end)

-- ====================================================================
-- CLEANUP & RESET
-- ====================================================================
register_event("round_start", function()
    EnemyRecords   = {}
    aimbot_data    = {}
    PredictionData = {}
    it_any_active  = false
    last_baim      = nil
    last_safe      = nil
    last_mindam    = -1
    dt_controller.state = DT_STATE_DISABLED
    dt_controller.last_charge = 0.0
    dt_controller.last_fire_tick = 0
    dt_controller.last_weapon_idx = -1
    dt_controller.recharge_forced = false
    
    if native_baim   then pcall(function() native_baim:override()   end) end
    if native_safe   then pcall(function() native_safe:override()   end) end
    if native_mindam then pcall(function() native_mindam:override() end) end
end)

register_event("shutdown", function()
    if native_baim      then pcall(function() native_baim:override()      end) end
    if native_safe      then pcall(function() native_safe:override()      end) end
    if native_mindam    then pcall(function() native_mindam:override()    end) end
    if native_hitchance then pcall(function() native_hitchance:override() end) end
    
    EnemyRecords   = {}
    aimbot_data    = {}
    PredictionData = {}
    it_any_active  = false
    it_esp_set_active(false)
end)
