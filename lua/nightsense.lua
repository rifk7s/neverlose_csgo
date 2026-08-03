--[[
    NightSense (Custom Fork)
    ====================================================================
    Note: This isn't the original NightSense anymore. I took the original
    script and heavily modified it to my own preferences.

    Original Author: ImSynZx
    GitLab: https://gitlab.com/ntduckien1/neverlose-support
    GitHub: https://github.com/ImSynZx/Neverlose-Lua
    Azura:  https://azura.uno/market?id=c7cfdb4e-5b00-41f0-833a-e6b25262152b&type=script
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

-- Load lagrecord exactly like Arc does (SIGNED flag = use signed backtrack records)
local lagrecord = require("neverlose/lagrecord")
lagrecord = lagrecord ^ lagrecord.SIGNED

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
ui.color = color

local function register_event(event_name, cb)
    if events[event_name] and type(events[event_name].set) == "function" then
        events[event_name]:set(cb)
    end
end


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

local is_mindam_active = false
local active_mindam_target_name = nil
local active_target_hp = 100
local active_mindam_val = 0
local mindam_hold_time = 0
local mindam_hold_val = -1

local icon_zap      = ui.get_icon("bolt")          or ""

local ui_pred       = ui.create("Ragebobs", icon_zap .. "  Prediction")
local sw_it_detect  = ui_pred:switch(icon_zap     .. "  Ideal Tick Detection",  false)
sw_it_detect:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Detects enemies exploiting tickbase bursts to ideal-tick open-peek you. Required for features below.")
local sw_it_esp     = ui_pred:switch(icon_logo    .. "  Visualize Exploits",     false)
local gear_it_esp   = sw_it_esp:create()
local cp_it_esp     = gear_it_esp:color_picker("Color", color(255, 60, 60, 200))
local sl_it_thick   = gear_it_esp:slider("Thickness", 1, 100, 35)
sw_it_esp:tooltip("\aA4E61EFF[Stable]\aFFFFFFFF Displays a 3D box at the location of the last valid history record when the enemy is attempting to invalidate backtrack records (Lag Peek / Defensive).\n\n\a88CCFFFF[Note]\aFFFFFFFF To show the 'IT +Nt' text label, you must enable the \aFFFF7FFFRagebobs IT\aFFFFFFFF element in the Neverlose \a88CCFFFFVisuals > Players > Enemies > Interactive ESP Preview\aFFFFFFFF menu (click \a88CCFFFFManage Elements\aFFFFFFFF).\n\n\aFFFF44FFThis feature requires heavy processing. Enabling this may greatly affect your FPS.\aFFFFFFFF")
local sw_it_mindam  = ui_pred:switch(icon_bullseye .. "  Auto Min-Dmg on IT",   false)
sw_it_mindam:tooltip("\aFF3333FF[Auto-Sniper Only]\aFFFFFFFF Only applies when holding a \a88CCFFFFSCAR-20\aFFFFFFFF or \aFFB84DFFG3SG1\aFFFFFFFF. Lowers min damage when an ideal-ticking enemy is the current threat, allowing NL to fire earlier in the open-peek window.")

local ui_vis        = ui.create("Ragebobs", icon_logo .. "  Visuals & Indicators")
local cb_mindam_ind = ui_vis:switch("Center Indicator", false)
cb_mindam_ind:tooltip("\a88CCFFFF[Visuals]\aFFFFFFFF Displays a comprehensive crosshair indicator showing your active weapon, current target, minimum damage, and exploit status.")
local gear_ind      = cb_mindam_ind:create()
local sw_mindam_glow = gear_ind:switch("Indicator Glow", true)
local cp_mindam_accent = gear_ind:color_picker("Indicator Color", color(150, 200, 255, 255))
local sw_mindam_exploit = gear_ind:switch("Show Exploit Name", true)
sw_mindam_exploit:tooltip("\a88CCFFFF[Visuals]\aFFFFFFFF Toggles the colored exploit name at the top of the indicator block.")
local sw_mindam_exploit_state = gear_ind:switch("Show Exploit State", true)
sw_mindam_exploit_state:tooltip("\a88CCFFFF[Visuals]\aFFFFFFFF Toggles the exploit status (DT, HS, FD, RELOADING) at the bottom of the indicator block.")

local user_name = common.get_username() or "Player"
local lbl_welcome = ui_info:label("Welcome back, \aA4E61EFF" .. user_name)
local lbl_dev = ui_info:label(icon_user .. "  Developer: \a7FFF7FFF.rifk  \aC8C8C8FFat \aB266FFFF" .. icon_discord)
local lbl_ver = ui_info:label(icon_fork .. "  Version: \aFFFF7FFF7.0.0 (BetaTest Version)")
local lbl_tip = ui_info:label(icon_info .. "  \aAAAAAAFFTip: Hover features to read their tooltips")


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
    local ok, x, y, z = pcall(function()
        local o = ent:get_origin()
        return o.x, o.y, o.z
    end)
    if ok and x then return x, y, z end
    return 0, 0, 0
end

local function SafeGetHP(ent)
    if not ent then return 100 end
    local ok, hp = pcall(function() return ent.m_iHealth end)
    return (ok and hp and hp > 0) and hp or 100
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
    if buf.count == 0 then return 50.0 end
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
    if buf.count == 0 then return 50.0 end
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
    local n   = buf.count
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
        local px, py, pz = p.ox, p.oy, p.oz
        local dist = math_sqrt((ex - px)^2 + (ey - py)^2 + (ez - pz)^2)
        if dist > 64 and speed > 15 then
            det.lc_broken = true
        end
        
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
    
    local head_pos = ent:get_eye_position()
    local lp_pos = lp:get_eye_position()
    if not head_pos or not lp_pos then return end
    
    local dir = (head_pos - lp_pos):normalized()
    local left_dir = vector(-dir.y, dir.x, 0)
    local right_dir = vector(dir.y, -dir.x, 0)
    
    local test_offsets = { 0, 18, 36 }
    local height_offsets = { 0, -25, -45 }
    
    local left_exposure = 0
    local right_exposure = 0
    local left_wall_thickness = 0
    local right_wall_thickness = 0
    
    local total_traces = 0
    
    for _, height in ipairs(height_offsets) do
        local enemy_center = head_pos + vector(0, 0, height)
        
        for _, offset in ipairs(test_offsets) do
            local left_pt = enemy_center + left_dir * offset
            local right_pt = enemy_center + right_dir * offset
            
            local tr_l = utils.trace_line(lp_pos, left_pt, lp)
            local tr_r = utils.trace_line(lp_pos, right_pt, lp)
            
            left_exposure = left_exposure + tr_l.fraction
            right_exposure = right_exposure + tr_r.fraction
            
            if tr_l.fraction < 1.0 then
                local back_tr_l = utils.trace_line(left_pt, lp_pos, ent)
                left_wall_thickness = left_wall_thickness + (1.0 - back_tr_l.fraction)
            end
            if tr_r.fraction < 1.0 then
                local back_tr_r = utils.trace_line(right_pt, lp_pos, ent)
                right_wall_thickness = right_wall_thickness + (1.0 - back_tr_r.fraction)
            end
            
            total_traces = total_traces + 1
        end
    end
    
    local avg_left_exp = left_exposure / total_traces
    local avg_right_exp = right_exposure / total_traces
    
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
    p.markov_matrix[prev][current_side] = p.markov_matrix[prev][current_side] + 1
end

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
    local ok_sim, sim_time  = pcall(function() return ent.m_flSimulationTime end)

    if not ok_ey or not eye_yaw then return end

    feet_yaw  = (ok_fy  and feet_yaw)  or 0
    speed     = (ok_sp  and speed)     or 0
    on_ground = (ok_gd  and on_ground) or true
    duck      = (ok_dk  and duck)      or 0
    sim_time  = (ok_sim and sim_time)  or 0
    
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

    local layers = SafeGetAnimLayers(ent)

    updateAdvancedFreestand(p, ent)
    updateDesyncModel(p, ent)
    
    profilerUpdate(p, eye_yaw, p.original_feet_yaw, speed, duck, sim_time)
    defensiveUpdate(p, sim_time, speed, p.original_feet_yaw, p.prev_feet_yaw)
    
    updateMarkovTransitions(p, p.resolved_side)
    updateJitterCycle(p, p.resolved_side)
    updateThreatIntel(p, ent)
    
    p.prev_feet_yaw = p.original_feet_yaw
    predictTargetMovement(p, ent)
end

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
                    
                    -- Weight: FOV 50%, Dist 30%, HP 20%
                    local final_score = (fov_score * 0.50) + (dist_score * 0.30) + (hp_score * 0.20)
                    
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

EnemyRecords  = {}
PredictionData = {}   -- ideal-tick state per entity index

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
        PredictionData[id] = { is_it = false, tick_lead = 0, predicted_origin = nil, name = "" }
    end

    local pd      = PredictionData[id]
    pd.is_it      = is_it
    pd.tick_lead  = is_it and tick_lead or 0

    if is_it then
        -- Try simulate_movement first
        local foot_orig = nil  -- ground-level, for 3D box projection
        local eye_orig  = nil  -- eye-level, for visibility pre-check
        local ok_sim2, sim2 = pcall(function() return ent:simulate_movement() end)
        if ok_sim2 and sim2 then
            local ok_res, res = pcall(function() return sim2:think(tick_lead) end)
            if ok_res and res and res.origin then
                foot_orig = res.origin
                local view_z = res.view_offset or 64
                eye_orig  = vector(res.origin.x, res.origin.y, res.origin.z + view_z)
            end
        end
        -- Fallback to current positions if sim failed
        if not foot_orig then
            local ok_o, o = pcall(function() return ent:get_origin() end)
            if ok_o and o then foot_orig = o end
        end
        if not eye_orig then
            local ok_e, e = pcall(function() return ent:get_eye_position() end)
            if ok_e and e then eye_orig = e end
        end
        pd.predicted_foot   = foot_orig
        pd.predicted_origin = eye_orig
        local ok_name, ename = pcall(function() return ent:get_name() end)
        pd.name = (ok_name and ename) and ename or ""
    else
        pd.predicted_foot   = nil
        pd.predicted_origin = nil
        pd.name             = ""
    end
end

register_event("net_update_start", function()
    local resolver_on = sw_resolver:get()
    local it_on       = sw_it_detect:get()
    if not resolver_on and not it_on then return end

    local lp      = entity.get_local_player()
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
                    if resolver_on then
                        if not EnemyRecords[id] then
                            EnemyRecords[id] = newSlot(id)
                        end
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

register_event("pre_render", function()
    if not sw_resolver:get() then return end

    local lp      = entity.get_local_player()
    local enemies = entity.get_players(true, false)
    if not enemies then return end

    for i = 1, #enemies do
        local ent = enemies[i]
        if ent ~= lp then
            local ok_id, id = pcall(function() return ent:get_index() end)
            if ok_id then
                local p = EnemyRecords[id]
                if p then
                    pcall(function()
                        local ok_a, a = pcall(function() return ent:is_alive()   end)
                        local ok_d, d = pcall(function() return ent:is_dormant() end)
                        if (ok_a and a) and not (ok_d and d) then
                            local anim = SafeGetAnimState(ent)
                            if anim then
                                local ok_ey, eye_yaw = pcall(function() return anim.m_flEyeYaw end)
                            end
                        end
                    end)
                end
            end
        end
    end
end)

local it_font = render.load_font("Verdana", 11, "bo")
local ind_font = render.load_font("Verdana", 11, "bda")

-- ============================================================
-- Arc Visualize Exploits (Exact 1:1 Decompiled Copy)
-- ============================================================

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
    else
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
        return
    end
end

local function v939(v932)
    if not sw_it_esp:get() or not sw_it_detect:get() then return end
    local v933 = entity.get_local_player()
    if v933 == nil or lagrecord == nil then
        return
    else
        entity.get_players(true, false, function(v934)
            local bbox = v934:get_bbox()
            if bbox == nil or bbox.pos1 == nil then
                return
            else
                local v935 = lagrecord.get_snapshot(v934)
                if v935 == nil then
                    return
                else
                    local l_no_entry_0 = v935.command.no_entry
                    if l_no_entry_0.y > 0 then
                        local v937 = true
                        if v933.m_hObserverTarget == v934 and v933.m_iObserverMode == 5 then
                            v937 = false
                        end
                        if v937 then
                            local l_origin_0 = v935.origin
                            v931(v932, v934:get_origin(), l_origin_0.volume, cp_it_esp:get(), (sl_it_thick:get() * 0.01) * 0.35 * (l_no_entry_0.x / l_no_entry_0.y))
                        end
                    end
                    return
                end
            end
        end)
        return
    end
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

register_event("createmove", function()
    it_esp_set_active(sw_it_esp:get() and sw_it_detect:get())
end)

local it_esp_element = esp.enemy:new_text("Ragebobs IT", "IT +12t", function(ent)
    if not sw_it_esp:get() or not sw_it_detect:get() then return nil end
    
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

local auto_anim_x = nil
local auto_anim_a = 0
local scout_anim_x = nil
local scout_anim_a = 0
local awp_anim_x = nil
local awp_anim_a = 0
local other_anim_x = nil
local other_anim_a = 0

register_event("render", function()
    if cb_mindam_ind:get() and it_font then
        local ss = render.screen_size()
        local c = cp_mindam_accent:get()
        
        local lp = entity.get_local_player()
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
        
        render.text(1, vector(10, 500), color(255, 255, 255, 255), nil, "DEBUG WPN: " .. (wpn_name or "none"):upper() .. " | AUTO: " .. tostring(is_autosniper) .. " | SCOUT: " .. tostring(is_scout) .. " | AWP: " .. tostring(is_awp) .. " | OTHER: " .. tostring(is_other))
        
        auto_anim_a = math.floor(auto_anim_a + ((is_autosniper and 255 or 0) - auto_anim_a) * globals.frametime * 12)
        scout_anim_a = math.floor(scout_anim_a + ((is_scout and 255 or 0) - scout_anim_a) * globals.frametime * 12)
        awp_anim_a = math.floor(awp_anim_a + ((is_awp and 255 or 0) - awp_anim_a) * globals.frametime * 12)
        other_anim_a = math.floor(other_anim_a + ((is_other and 255 or 0) - other_anim_a) * globals.frametime * 12)
        
        -- Color variables
        local c = cp_mindam_accent:get()
        
        -- Exploit State Logic
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
        local charge_val = 0
        if rage and rage.exploit then
            local ok, f = pcall(function() return rage.exploit:get() end)
            if ok and f then charge_val = f end
        end
        local is_reloading = false
        if lp and lp:is_alive() then
            local wpn = lp:get_player_weapon()
            if wpn then
                -- FFI memory read for weapon animation state (bulletproof)
                local ok_l, layers = pcall(SafeGetAnimLayers, lp)
                if ok_l and layers then
                    local l1 = layers[1]
                    -- Layer 1 is weapon action (reload, draw, silencer).
                    -- Draw animations are ~1.0s (Rate ~1.0). Rechambering is ~1.2-1.4s (Rate ~0.7-0.8).
                    -- Real reloads are > 2.0s (Rate < 0.6).
                    -- Therefore, if playback rate is < 0.6, it is mathematically guaranteed to be a reload, NOT drawing!
                    if l1.m_flWeight > 0.1 and l1.m_flPlaybackRate > 0 and l1.m_flPlaybackRate < 0.6 then
                        is_reloading = true
                    end
                end
                
                -- Fallback for Shotguns (their reload rate is fast per shell, but the engine reliably sets m_bInReload for them)
                if not is_reloading then
                    local ok_inr, in_reload = pcall(function() return wpn:get_prop("m_bInReload") end)
                    if ok_inr and (in_reload == true or in_reload == 1) then
                        is_reloading = true
                    end
                end
                
                -- Ultimate fallback: if clip is 0 and it's a firearm, you are forced into reload state
                if not is_reloading then
                    local ok_clip, clip = pcall(function() return wpn:get_prop("m_iClip1") end)
                    if ok_clip and clip == 0 then
                        -- Exclude knives and grenades
                        if wpn_name ~= "knife" and wpn_name ~= "hegrenade" and wpn_name ~= "molotov" and wpn_name ~= "incgrenade" and wpn_name ~= "smokegrenade" and wpn_name ~= "flashbang" and wpn_name ~= "decoy" and wpn_name ~= "taser" then
                            is_reloading = true
                        end
                    end
                end
            end
        end
        
        local function draw_exploit_state(center_x, y_offset, anim_a)
            if not sw_mindam_exploit_state:get() then return y_offset end
            
            local exploits = {}
            
            -- If DT is recharging, that takes absolute priority (prevents false reload triggers from tickbase animation freezes)
            if dt_on and charge_val ~= 1 then
                exploits[#exploits+1] = {text="RECHARGING", color=color(255, 150, 50, anim_a)}
            elseif is_reloading then
                exploits[#exploits+1] = {text="RELOADING", color=color(255, 100, 100, anim_a)}
            else
                if dt_on and charge_val == 1 then
                    exploits[#exploits+1] = {text="DOUBLETAP", color=color(50, 255, 50, anim_a)}
                end
                if hs_on then
                    exploits[#exploits+1] = {text="HS READY", color=color(50, 255, 50, anim_a)}
                end
                if fd_on then
                    exploits[#exploits+1] = {text="FD ACTIVE", color=color(255, 200, 50, anim_a)}
                end
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
        
        -- RENDERING AUTOSNIPER BLOCK
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
        
        -- RENDERING SCOUT BLOCK
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
        
        -- RENDERING AWP BLOCK
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
        
        -- RENDERING OTHER WEAPON BLOCK
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

local function getShotMatrixAccuracy(steamid, state)
    local data = shot_matrix[steamid]
    if not data then return 0.50, 0 end
    local stats = data.stats[state]
    if not stats or stats.shots == 0 then return 0.50, 0 end
    return stats.accuracy, stats.shots
end

local function predictTargetMovement(p, ent)
    local lp = entity_get_local_player()
    if not lp then return end
    
    local ox, oy, oz = SafeGetOrigin(ent)
    local vx, vy, vz = 0, 0, 0
    local vel = ent.m_vecVelocity
    if vel then
        vx, vy, vz = vel.x, vel.y, vel.z
    end
    
    table_insert(p.history, {
        pos = { x = ox, y = oy, z = oz },
        vel = { x = vx, y = vy, z = vz }
    })
    if #p.history > 16 then
        table_remove(p.history, 1)
    end
    
    if #p.history < 2 then
        p.is_accelerating = false
        p.predicted_peek_visible = false
        return
    end
    
    local cur = p.history[#p.history]
    local prev = p.history[#p.history - 1]
    
    local cur_vel_len = math_sqrt(cur.vel.x^2 + cur.vel.y^2)
    local prev_vel_len = math_sqrt(prev.vel.x^2 + prev.vel.y^2)
    p.is_accelerating = (cur_vel_len - prev_vel_len) > 25.0
    
    local lp_pos = lp:get_eye_position()
    if not lp_pos then return end
    
    local ti = p.tick_interval or 0.015625
    local time_step = 6 * ti
    
    local pred_x = cur.pos.x + cur.vel.x * time_step
    local pred_y = cur.pos.y + cur.vel.y * time_step
    local pred_z = cur.pos.z + cur.vel.z * time_step + 64
    
    local frac, trace_ent = utils_trace_line(lp_pos, vector(pred_x, pred_y, pred_z), lp)
    p.predicted_peek_visible = (frac > 0.97)
end

register_event("aim_fire", function(e)
    if not e then return end
    local p = EnemyRecords[e.target]
    if not p then return end
    
    aimbot_data[e.id] = {
        target   = e.target,
        hitgroup = e.hitgroup,
        state = getTargetState(p),
        choke = p.choke or 0,
        resolver_confidence = p.resolver_confidence or 0.50,
        defensive_confidence = p.defensive_confidence or 0.0,
        lc_state = p.lc_broken and "broken" or "valid",
        archetype = p.archetype or 0
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
    
    p.resolver_confidence = (p.resolver_confidence or 0.50)
    p.resolver_confidence = p.resolver_confidence + confidence_gain
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

register_event("createmove", function(cmd)
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

    local lp = entity.get_local_player()
    if not lp then return end
    local ok_lp_alive, lp_alive = pcall(function() return lp:is_alive() end)
    if not ok_lp_alive or not lp_alive then return end

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
    
    local wpn_is_auto = false
    local target_md = -1
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
        is_mindam_active = false
        active_mindam_target_name = nil
        active_target_hp = 100
        active_mindam_val = 0
        return
    end

    local ok_bid, bid = pcall(function() return best:get_index() end)
    if not ok_bid then return end

    local p  = EnemyRecords[bid]
    if not p then
        if last_baim   ~= nil then if native_baim   then native_baim:override()   end; last_baim   = nil end
        if last_safe   ~= nil then if native_safe   then native_safe:override()   end; last_safe   = nil end
        if last_mindam ~= -1  then if native_mindam then native_mindam:override() end; last_mindam = -1  end
        return
    end

    local hp = SafeGetHP(best)

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

    local target_md = -1
    local ok_vis, vis = pcall(function() return best:is_visible() end)
    if sw_lethal:get() and ok_vis and vis and hp < 50 then
        target_md = math_min(hp + 1, 100)
        if native_dt then
            local ok_dt, dt_on = pcall(function() return native_dt:get() end)
            if ok_dt and dt_on then
                local ok_md, base_md = pcall(function() return native_mindam:get() end)
                if ok_md and base_md then
                    target_md = math_max(1, math_floor(base_md * 0.6))
                end
            end
        end
        active_mindam_val = target_md
        is_mindam_active = true
    elseif p.consecutive_resolver_misses >= 1 then
        local ok_md, base_md = pcall(function() return native_mindam:get() end)
        if ok_md and base_md then
            local factor = math_max(0.4, 1.0 - (p.consecutive_resolver_misses * 0.15))
            target_md = math_max(1, math_floor(base_md * factor))
            active_mindam_val = target_md
            is_mindam_active = true
        end
    end

    
    -- IT min-damage override: when idealtick detected on this target, halve min damage
    if p.is_idealtick and sw_it_mindam:get() then
        local hp = SafeGetHP(best)
        local base_md = native_mindam and native_mindam:get() or 100
        target_md = math.min(math.floor(base_md * 0.5), hp + 1)
        active_mindam_val = target_md
        is_mindam_active = true
    elseif sw_resolver:get() and (p.resolver_confidence or 0.50) < 0.50 then
        local hp = SafeGetHP(best)
        local base_md = native_mindam and native_mindam:get() or 100
        local reduction_factor = math.max(0.4, (p.resolver_confidence or 0.50) * 1.5)
        target_md = math.min(math.floor(base_md * reduction_factor), hp + 1)
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

register_event("round_start", function()
    EnemyRecords   = {}
    aimbot_data    = {}
    PredictionData = {}
    it_any_active  = false
    last_baim      = nil
    last_safe      = nil
    last_mindam    = -1
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
end)