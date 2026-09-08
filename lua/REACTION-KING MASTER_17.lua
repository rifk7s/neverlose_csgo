--[[
    REACTION-KING MASTER - AI Peek Script
    reverse engineered and rewritten by .rifk (discord)

    Features:
    - AI-driven peek simulation (finds optimal peek angles from 3 directions)
    - Jump Scout logic (automatic jump sniping with SSG-08 / scoped rifles)
    - Reaction MASTER mode (pre-movement peek with Double Tap override)
    - Auto retreat to cover after peek
    - Bullet damage simulation for hitbox viability checks
--]]

-- #region constants

-- Neverlose entity flag: player is standing on ground
local FL_ONGROUND = bit.lshift(1, 0) -- = 1

-- Neverlose hitbox IDs (used with entity:get_hitbox_position)
local HITBOX_HEAD = 0
local HITBOX_NECK = 1
local HITBOX_PELVIS = 2
local HITBOX_STOMACH = 3
local HITBOX_CHEST = 5
local HITBOX_ARM_R = 7
local HITBOX_ARM_L = 8
local HITBOX_LEG_R = 9
local HITBOX_LEG_L = 10
local HITBOX_FOOT_L = 15
local HITBOX_FOOT_R = 17

--[[
    Maps hitbox ID -> armor penetration zone index
    Zone 1=Head, 2=Chest, 3=Stomach, 4=Leg/Foot, 5=Leg/Foot, 6=Arm, 7=Arm
]]
local hitbox_to_armor_zone = {
    [HITBOX_HEAD] = 1,
    [HITBOX_CHEST] = 2,
    [HITBOX_STOMACH] = 3,
    [HITBOX_ARM_R] = 6,
    [HITBOX_ARM_L] = 7,
    [HITBOX_LEG_R] = 6,
    [HITBOX_LEG_L] = 7,
    [HITBOX_FOOT_R] = 4,
    [HITBOX_FOOT_L] = 5,
}

-- Maps weapon item definition index -> weapon class string
local weapon_class_by_index = {
    [1] = "Desert Eagle",
    [2] = "Pistol",
    [3] = "Pistol",
    [4] = "Pistol",
    [7] = "Rifle",
    [8] = "Rifle",
    [9] = "AWP",
    [10] = "Rifle",
    [11] = "Autoscoutr",
    [13] = "Rifle",
    [14] = "Machine Gun",
    [16] = "Rifle",
    [17] = "SMG",
    [19] = "SMG",
    [23] = "SMG",
    [24] = "SMG",
    [25] = "Shotgun",
    [26] = "SMG",
    [27] = "Shotgun",
    [28] = "Machine Gun",
    [29] = "Shotgun",
    [30] = "Pistol",
    [31] = "Zeus x27",
    [32] = "Pistol",
    [33] = "SMG",
    [34] = "SMG",
    [35] = "Shotgun",
    [36] = "Pistol",
    [38] = "Autoscoutr",
    [39] = "Rifle",
    [40] = "SSG 08",
    [43] = "Nades",
    [44] = "Nades",
    [45] = "Nades",
    [46] = "Nades",
    [47] = "Nades",
    [48] = "Nades",
    [60] = "Rifle",
    [61] = "Pistol",
    [63] = "Pistol",
    [64] = "R8 Revolver",
}
-- #endregion

-- #region globals

-- Script context table (returned at end)
local script_ctx = {}
-- #endregion

-- #region menu setup

local PADDING_CHAR = "\226\128\138" -- invisible unicode space for icon padding

-- Helper: repeat padding char n times
local function pad(n)
    return string.rep(PADDING_CHAR, n)
end

--[[
    Helper: build a formatted label with an icon
    icon_name: NL icon name, label: display text, pad_left/pad_right: padding counts
]]
local function make_icon_label(icon_name, label, pad_left, pad_right)
    return pad(pad_left) .. "\a{Link Active}" .. ui.get_icon(icon_name) .. pad(pad_right) .. "\aDEFAULT" .. label
end

--[[
    Helper: ensure a selectable/listable element always has a value selected
    elem: the UI element, default_value: fallback if empty
]]
local function enforce_selection(elem, default_value)
    local current = elem:get()
    if #current == 0 then
        if default_value == nil then
            local elem_type = elem:type()
            local elem_list = elem:list()
            if elem_type == "selectable" then
                default_value = elem_list
            elseif elem_type == "listable" then
                default_value = {}
                for i = 1, #elem_list do
                    default_value[i] = i
                end
            end
        end
        current = default_value
        elem:set(default_value)
    end
    elem:set_callback(function()
        local new_val = elem:get()
        if #new_val > 0 then
            current = new_val
        else
            elem:set(current)
        end
    end)
end

-- Helper: returns the weapon class name for a given item definition index
get_weapon_type_from_index = function(item_def_index)
    return weapon_class_by_index[item_def_index] or "Other"
end

-- Create the AI Peek tab group
local ai_peek_group = ui.create("AI Peek", 1)

-- Main settings table
local settings = {
    enabled = ai_peek_group:switch(make_icon_label("microchip-ai", "Reaction King", 1, 6)),
}

-- Create sub-group under the enabled switch
local sub_group = settings.enabled:create()

settings.hitboxes = sub_group
    :listable("Scanning Hitboxes", { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" })
    :tooltip("Hitboxes to scan for damage")

settings.weapon_filter = sub_group
    :selectable("Weapon Filter", {
        "Autoscoutr",
        "R8 Revolver",
        "SSG 08",
        "AWP",
        "Zeus x27",
        "Pistol",
        "Desert Eagle",
        "SMG",
        "Shotgun",
        "Rifle",
        "Machine Gun",
    })
    :tooltip("Filter which weapons the AI peek should work with")

settings.simulation_time =
    sub_group:slider("Simulation Time", 25, 35, 28, 0.01, "s"):tooltip("Time to simulate the peek")

settings.rate_limit = sub_group:slider("Rate Limit", 0, 30, 2, 0.01, "s"):tooltip("Rate limit for peek updates")

settings.hit_chance = sub_group
    :slider("Hit Chance", 0, 100, 0, nil, function(v)
        return v == 0 and "Def." or v .. "%"
    end)
    :tooltip("Minimum hit chance to consider a hitbox valid.")

settings.unsafety =
    sub_group:switch("Unsafety"):tooltip("Allows to use 100% multipoint and body aim, but may cause misses.")

settings.predict_key = sub_group:switch("Reaction MASTER"):tooltip("AKA PR")

settings.predict_delay = sub_group:slider("Predict Delay", 1, 150, 1, nil, "v"):tooltip("Delay to predict peek")

settings.developer_mode =
    sub_group:switch("Developer Mode"):tooltip("Allows to change peek range and retreat distance, useful for testing.")

settings.range = sub_group:slider("Range", 15, 25, 20, nil, "t"):tooltip("Range to scan for enemies")

settings.retreat = sub_group:slider("Retreat", 15, 30, 25, nil, "u"):tooltip("Distance to retreat after peek")

settings.jump_scout = sub_group:switch("Jump Scout"):tooltip("Enable automatic jump sniping")

settings.force_jump_scout =
    sub_group:switch("Jump Scout LLC"):tooltip("Force jump scout mode - always use normal peek logic without retreat")

settings.block_movement_type = sub_group
    :slider("Quick Stop type", 1, 2, 1, nil, function(v)
        return v == 1 and "Type 1" or "Type 2"
    end)
    :tooltip("1 for slow movement, 2 for stop movement")

settings.jump_scan_range =
    sub_group:slider("Jump Scan Range", 10, 50, 25, nil, "u"):tooltip("Range to scan for jump scout opportunities")

settings.jump_height_check =
    sub_group:slider("Min Jump Height", 20, 128, 30, nil, "u"):tooltip("Minimum height required for jump scout")

settings.jump_timing =
    sub_group:slider("Jump Timing", 1, 9, 3, 0.1, "s"):tooltip("Timing window for jump scout execution")

settings.jump_prefire = sub_group:switch("Jump Prefire"):tooltip("Fire before landing for better timing")

-- Visibility callbacks
settings.developer_mode:set_callback(function(elem)
    local enabled = elem:get()
    settings.range:visibility(enabled)
    settings.retreat:visibility(enabled)
end, true)

settings.jump_scout:set_callback(function(elem)
    local enabled = elem:get()
    settings.force_jump_scout:visibility(enabled)
    settings.jump_scan_range:visibility(enabled)
    settings.jump_height_check:visibility(enabled)
    settings.jump_timing:visibility(enabled)
    settings.jump_prefire:visibility(enabled)
    settings.block_movement_type:visibility(enabled)
end, true)

settings.predict_key:set_callback(function(elem)
    settings.predict_delay:visibility(elem:get())
end, true)

-- Enforce that hitbox/weapon filter always have a selection
enforce_selection(settings.hitboxes)
enforce_selection(settings.weapon_filter)

-- Expose menu to script context
script_ctx.menu = {
    main = {
        reaction = settings,
    },
}
-- #endregion

-- #region nl ui references (built-in nl ragebot elements found via ui.find)

local ui_refs = {
    rage = {
        main = {
            dormant_aimbot = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),
            hide_shots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
            hide_shots_options = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"),
            double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
            double_tap_lag_opts = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
            peek_assist = {
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist"),
                { ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Style") },
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Auto Stop"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Retreat Mode"),
            },
        },
        accuracy = {
            -- Auto Stop -> Options (used to override "In Air" / "Move between Shots")
            auto_stop_opts = ui.find("Aimbot", "Ragebot", "Accuracy", "Auto Stop", "Options"),
        },
        selection = {
            hit_chance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
            min_damage = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
        },
    },
    misc = {
        air_strafe = ui.find("Miscellaneous", "Main", "Movement", "Air Strafe"),
    },
}

-- Per-weapon UI refs for overrides (Multipoint scales, body aim, safe points)
local weapon_ui_refs = {}

local function build_weapon_ui_refs(weapon_name)
    return {
        selection = {
            head_scale = ui.find("Aimbot", "Ragebot", "Selection", weapon_name, "Multipoint", "Head Scale"),
            body_scale = ui.find("Aimbot", "Ragebot", "Selection", weapon_name, "Multipoint", "Body Scale"),
            min_damage = ui.find("Aimbot", "Ragebot", "Selection", weapon_name, "Min. Damage"),
            hit_chance = ui.find("Aimbot", "Ragebot", "Selection", weapon_name, "Hit Chance"),
        },
        safety = {
            body_aim = ui.find("Aimbot", "Ragebot", "Safety", weapon_name, "Body Aim"),
            safe_points = ui.find("Aimbot", "Ragebot", "Safety", weapon_name, "Safe Points"),
            ensure_hitbox_safety = ui.find("Aimbot", "Ragebot", "Safety", weapon_name, "Ensure Hitbox Safety"),
        },
    }
end

weapon_ui_refs["SSG-08"] = build_weapon_ui_refs("SSG-08")
weapon_ui_refs["Deagle"] = build_weapon_ui_refs("Desert Eagle")
weapon_ui_refs["Pistols"] = build_weapon_ui_refs("Pistols")
-- #endregion

-- #region state variables

local peek_ctx = nil -- current peek simulation context (origin, target, etc.)
local rate_limit_timer = 0 -- countdown for rate limiting peek searches
local retreat_pos = nil -- computed retreat position vector
local jump_scout_state = nil -- jump scout phase state table
local peek_timer = 0 -- curtime reference for peek timing
local is_active = false -- whether jump scout is currently running
local can_hit = false -- whether a valid hitbox was found this frame
local retry_timer = 0 -- curtime reference for DT charge retry
local is_charging_dt = false -- whether we are waiting for DT to charge
local has_retreated = false -- whether we already applied the initial jump/retreat
local active_time = 0 -- curtime when current action started
-- #endregion

-- #region helpers: settings getters

local menu = script_ctx.menu.main.reaction

local function get_simulation_time()
    return menu.simulation_time:get() * 0.01
end
local function get_rate_limit()
    return menu.rate_limit:get() * 0.01
end
local function get_min_damage()
    return ui_refs.rage.selection.min_damage:get()
end
local function get_peek_range()
    return menu.developer_mode:get() and menu.range:get() or 20
end
local function get_retreat_distance()
    return menu.developer_mode:get() and menu.retreat:get() or 25
end
local function is_jump_scout_enabled()
    return menu.jump_scout:get()
end
local function is_force_jump_scout()
    return menu.force_jump_scout:get()
end
local function get_jump_scan_range()
    return menu.jump_scan_range:get()
end
local function get_jump_height_check()
    return menu.jump_height_check:get()
end
local function get_jump_timing()
    return menu.jump_timing:get() * 0.1
end
local function is_jump_prefire()
    return menu.jump_prefire:get()
end
local function get_block_movement_type()
    return menu.block_movement_type:get()
end
-- #endregion

-- #region helpers: utility

-- Returns the 2D speed of the local player (units/sec)
local function get_local_speed()
    local lp = entity.get_local_player()
    if lp == nil then
        return 0
    end
    local vel = lp.m_vecVelocity
    return math.sqrt(vel.x ^ 2 + vel.y ^ 2)
end

-- Returns true if entity handle is still valid (not garbage collected)
local function is_entity_valid(ent)
    if ent == nil then
        return false
    end
    local ok, idx = pcall(function()
        return ent[0]
    end)
    return ok and idx ~= nil
end

-- Returns true if peek_ctx still references a valid target entity
local function is_peek_target_valid(pctx)
    return is_entity_valid(pctx.target)
end

--[[
    Returns true if the player is not pressing movement keys (ready to peek)
    In Reaction MASTER / Force Jump Scout mode, always returns true
]]
local function can_start_peek(cmd)
    if menu.predict_key:get() or menu.force_jump_scout:get() then
        return true
    end
    return not cmd.in_forward and not cmd.in_back and not cmd.in_moveleft and not cmd.in_moveright
end

-- Returns true if the local player can fire their weapon right now
local function can_fire(lp, weapon, weapon_info)
    if lp == nil or weapon == nil then
        return false
    end
    if weapon_info.max_clip1 == 0 or weapon.m_iClip1 == 0 then
        return false
    end
    if globals.curtime < lp.m_flNextAttack then
        return false
    end
    if globals.curtime < weapon.m_flNextPrimaryAttack then
        return false
    end
    if ui_refs.rage.main.double_tap:get() and not rage.exploit:get() == 1 then
        return false
    end
    -- R8 Revolver has an additional postpone-fire timer
    if weapon:get_weapon_index() == 64 then
        local postpone = weapon.m_flPostponeFireReadyTime
        if postpone and globals.curtime < postpone then
            return false
        end
    end
    return true
end

-- Returns the weapon slot key name for per-weapon ui_refs (e.g. "Deagle", "SSG-08", "Pistols")
local function get_weapon_slot_name(weapon, weapon_info)
    local idx = weapon:get_weapon_index()
    local wtype = weapon_info.weapon_type
    if idx == 1 then
        return "Deagle"
    end
    if idx == 64 then
        return "Revolver"
    end
    if idx == 40 then
        return "SSG-08"
    end
    if wtype == 1 then
        return "Pistols"
    end
    return nil
end

-- Returns true if the player's weapon is in the allowed weapon filter
local function is_weapon_allowed(weapon)
    if weapon == nil then
        return false
    end
    local idx = weapon:get_weapon_index()
    local wtype = get_weapon_type_from_index(idx)
    for _, allowed in pairs(menu.weapon_filter:get()) do
        if allowed == wtype then
            return true
        end
    end
    return false
end

-- Returns the hitbox damage multiplier for a given armor zone index
local function get_armor_zone_multiplier(zone)
    if zone == 1 then
        return 4
    end -- HEAD: 4x damage
    if zone == 3 then
        return 1.25
    end -- STOMACH: 1.25x
    if zone == 6 or zone == 7 then
        return 0.75
    end -- ARMS: 0.75x
    return 1 -- all other zones
end

-- Applies armor damage reduction to base damage for a given target and zone
local function apply_armor_reduction(target, damage, zone, armor_ratio)
    damage = damage * get_armor_zone_multiplier(zone)
    if target.m_ArmorValue > 0 then
        -- Head zone: armor only reduces if target has helmet
        if zone == 1 then
            if target.m_bHasHelmet then
                damage = damage * (armor_ratio * 0.5)
            end
        else
            damage = damage * (armor_ratio * 0.5)
        end
    end
    return damage
end

-- Calculates estimated damage from from_pos to hitbox_pos on target using weapon_info
local function calculate_damage(from_pos, hitbox_pos, target, zone, weapon_info)
    local dist = (hitbox_pos - from_pos):length()
    local damage = weapon_info.damage
    local armor_ratio = weapon_info.armor_ratio
    local max_range = weapon_info.range
    local range_modifier = weapon_info.range_modifier
    local effective_dist = math.min(max_range, dist)
    damage = damage * math.pow(range_modifier, effective_dist * 0.002)
    return apply_armor_reduction(target, damage, zone, armor_ratio)
end

--[[
    Returns a list of hitbox positions on target that deal >= min_dmg
    hitbox_list: array of hitbox IDs to check
]]
local function get_valid_hitbox_positions(hitbox_list, lp, weapon, target, min_dmg)
    local results = {}
    local eye_pos = lp:get_eye_position()
    local weapon_info = weapon:get_weapon_info()
    local health = target.m_iHealth
    for i = 1, #hitbox_list do
        local hitbox_id = hitbox_list[i]
        local zone = hitbox_to_armor_zone[hitbox_id] or 0
        local hitbox_pos = target:get_hitbox_position(hitbox_id)
        local dmg = calculate_damage(eye_pos, hitbox_pos, target, zone, weapon_info)
        -- Valid if damage >= min_dmg OR damage >= target health (kill shot)
        if dmg >= min_dmg or dmg >= health then
            table.insert(results, {
                index = i,
                pos = hitbox_pos,
            })
        end
    end
    return results
end

-- Returns the list of hitbox IDs currently enabled in the Scanning Hitboxes setting
local function get_active_hitboxes()
    local result = {}
    if menu.hitboxes:get("Head") then
        table.insert(result, HITBOX_HEAD)
    end
    if menu.hitboxes:get("Chest") then
        table.insert(result, HITBOX_CHEST)
    end
    if menu.hitboxes:get("Stomach") then
        table.insert(result, HITBOX_STOMACH)
    end
    if menu.hitboxes:get("Arms") then
        table.insert(result, HITBOX_ARM_R)
        table.insert(result, HITBOX_ARM_L)
    end
    if menu.hitboxes:get("Legs") then
        table.insert(result, HITBOX_LEG_R)
        table.insert(result, HITBOX_LEG_L)
    end
    if menu.hitboxes:get("Feet") then
        table.insert(result, HITBOX_FOOT_R)
        table.insert(result, HITBOX_FOOT_L)
    end
    return result
end

-- Traces a bullet and returns (damage, trace_result) filtering for enemies only
local function trace_bullet_to_enemy(shooter, from_pos, to_pos)
    local dmg, trace = utils.trace_bullet(shooter, from_pos, to_pos, function(ent)
        return ent ~= shooter and ent:is_enemy()
    end)
    return dmg, trace
end

-- Returns true if any hitbox in valid_hitboxes can be hit for min_dmg
local function can_hit_target(lp, target, from_pos, valid_hitboxes, min_dmg)
    local health = target.m_iHealth
    for i = 1, #valid_hitboxes do
        local entry = valid_hitboxes[i]
        local dmg, _ = trace_bullet_to_enemy(lp, from_pos, entry.pos)
        if dmg >= min_dmg or dmg >= health then
            return true
        end
    end
    return false
end

--[[
    Simulates one movement step for a player (used for peek position scanning)
    Returns a simulated player state
]]
local function simulate_player_step(lp)
    return lp:simulate_movement(nil, vector(), 1)
end

--[[
    Runs one tick of simulated movement at a given yaw angle, checks if target is hittable
    Returns (simulated_state, can_hit_bool) or (nil, false) if player left ground
]]
local function simulate_angle_step(cmd, lp, target, sim_state, yaw, valid_hitboxes, min_dmg)
    cmd.view_angles.y = yaw
    sim_state:think(1)
    -- Only proceed if simulation player is on the ground (FL_ONGROUND)
    if bit.band(sim_state.flags, FL_ONGROUND) == 0 then
        return nil, false
    end
    local sim_eye_pos = sim_state.origin + vector(0, 0, sim_state.view_offset)
    local hit = can_hit_target(lp, target, sim_eye_pos, valid_hitboxes, min_dmg)
    if hit then
        sim_state:think(1) -- advance one more tick to give margin
    end
    return sim_state, hit
end

-- Creates a new peek context table from a simulated player state and target
local function create_peek_ctx(sim_state, target)
    return {
        teleport = 0,
        simtime = 0,
        retreat = -1,
        ctx = sim_state, -- simulated player position/state
        target = target, -- entity handle
    }
end
-- #endregion

-- #region helpers: dt / override management

--[[
    Overrides Double Tap off if player is moving fast enough (reaction master mode)
    Returns true if DT was disabled
]]
local function should_disable_dt()
    if (menu.predict_key:get() or menu.force_jump_scout:get()) and get_local_speed() > menu.predict_delay:get() then
        ui_refs.rage.main.double_tap:override(false)
        return true
    end
    return false
end

-- Restores Double Tap override to default (called via execute_after)
local function restore_dt()
    if menu.predict_key:get() then
        ui_refs.rage.main.double_tap:override()
    end
end

-- Resets all peek state variables to their initial/idle values
local function reset_peek_state()
    peek_ctx = nil
    rate_limit_timer = 0
    retreat_pos = nil
    jump_scout_state = nil
    peek_timer = 0
    is_active = false
    can_hit = false
    retry_timer = 0
    is_charging_dt = false
    has_retreated = false
end

-- Removes all NL ragebot overrides applied by this script
local function reset_overrides()
    ui_refs.rage.main.double_tap:override()
    ui_refs.rage.main.peek_assist[4]:override()
    for _, wref in pairs(weapon_ui_refs) do
        wref.selection.head_scale:override()
        wref.selection.body_scale:override()
        wref.selection.hit_chance:override()
        wref.safety.body_aim:override()
        wref.safety.safe_points:override()
        wref.safety.ensure_hitbox_safety:override()
    end
end

-- Applies ragebot overrides for peeking (max multipoint, 100% scales if Unsafety on)
local function apply_peek_overrides()
    local min_hc = menu.hit_chance:get()
    local unsafety = menu.unsafety:get()
    ui_refs.rage.main.peek_assist[4]:override("On Shot")
    for _, wref in pairs(weapon_ui_refs) do
        if min_hc ~= 0 then
            wref.selection.hit_chance:override(min_hc)
        end
        if unsafety then
            wref.selection.head_scale:override(100)
            wref.selection.body_scale:override(100)
            wref.safety.body_aim:override("Default")
            wref.safety.safe_points:override("Default")
            wref.safety.ensure_hitbox_safety:override({})
        end
    end
end
-- #endregion

-- #region helpers: movement

--[[
    Moves the player toward target_pos by setting cmd move fields
    Returns (reached, dist_sq) where reached = true if within 5 units
]]
local function move_toward(cmd, lp, target_pos)
    local delta = target_pos - lp:get_origin()
    local dist_sq = delta:length2dsqr()
    if dist_sq < 25 then
        -- Close enough: brake by reversing velocity direction
        local vel = lp.m_vecVelocity
        local speed = vel:length()
        cmd.move_yaw = vel:angles().y
        cmd.forwardmove = -speed
        cmd.sidemove = 0
        return true, dist_sq
    else
        -- Move toward target
        cmd.move_yaw = delta:angles().y
        cmd.forwardmove = 450
        cmd.sidemove = 0
        return false, dist_sq
    end
end

--[[
    Clears directional movement inputs (prevents player self-steering during peek)
    In Reaction MASTER / Force Jump Scout: only clears duck/speed
]]
local function override_movement_inputs(cmd)
    cmd.in_duck = false
    cmd.in_speed = false
    if not menu.predict_key:get() and not menu.force_jump_scout:get() then
        cmd.in_forward = true
        cmd.in_back = false
        cmd.in_moveleft = false
        cmd.in_moveright = false
    end
end
-- #endregion

-- #region jump scout

-- Returns true if jump-sniping from a raised position on target is feasible
local function check_jump_shot_position(lp, target, _eye_pos)
    if not is_jump_scout_enabled() then
        return false
    end
    local lp_origin = lp:get_origin()
    -- Must be within jump scan range
    if (target:get_origin() - lp_origin):length() > get_jump_scan_range() * 50 then
        return false
    end
    -- Project a raised trace point (simulating jump peak height)
    local jump_height = get_jump_height_check()
    local raised_pos = lp_origin + vector(0, 0, jump_height) + vector(0, 0, lp:get_eye_position().z - lp_origin.z)
    local dmg, trace = trace_bullet_to_enemy(lp, raised_pos, target:get_hitbox_position(HITBOX_HEAD))
    return dmg > 0 and not trace.hit_sky
end

-- Returns true if jump scout conditions are met for the given player and weapon
local function can_jump_scout(lp, weapon)
    if not is_jump_scout_enabled() then
        return false
    end
    if not is_weapon_allowed(weapon) then
        return false
    end
    if is_force_jump_scout() then
        return true
    end
    -- Only auto-scout with SSG-08 (index 40)
    if weapon:get_weapon_index() ~= 40 then
        return false
    end
    local threat = entity.get_threat()
    if threat == nil or threat:is_dormant() then
        return false
    end
    -- If we already have LOS to head, no need to jump
    local eye_pos = lp:get_eye_position()
    local dmg, _ = trace_bullet_to_enemy(lp, eye_pos, threat:get_hitbox_position(HITBOX_HEAD))
    if dmg > 0 then
        return false
    end
    return check_jump_shot_position(lp, threat, eye_pos)
end

--[[
    Main jump scout logic (handles both Force and normal modes)
    Returns true if jump scout is handling this tick (suppress normal peek logic)
]]
local function run_jump_scout_logic(cmd, lp, weapon)
    local threat = entity.get_threat()
    if threat == nil then
        return false
    end

    local curtime = globals.curtime

    if is_force_jump_scout() and can_start_peek(cmd) then
        -- FORCE JUMP SCOUT MODE
        if not is_active then
            is_active = true
            active_time = curtime
            peek_timer = curtime + 1
            can_hit = false
            has_retreated = false
            jump_scout_state = {
                peek_completed = false,
                peek_phase = true,
                target = threat,
                start_pos = lp:get_origin(),
            }
        end

        local time_since_peek = curtime - peek_timer
        local timing = get_jump_timing()
        local min_dmg = get_min_damage()
        local active_hitboxes = get_active_hitboxes()
        local flags = lp.m_fFlags
        local on_ground = bit.band(flags, FL_ONGROUND) ~= 0

        -- Phase 1: move to the peek position found by find_peek_position
        if
            jump_scout_state
            and jump_scout_state.peek_phase
            and not jump_scout_state.peek_completed
            and peek_ctx
            and peek_ctx.ctx
        then
            local peek_origin = peek_ctx.ctx.origin
            if (peek_origin - lp:get_origin()):length() < 10 then
                -- Arrived at peek spot
                jump_scout_state.peek_completed = true
                peek_timer = curtime
            else
                -- Still moving to peek spot
                move_toward(cmd, lp, peek_origin)
                override_movement_inputs(cmd)
                -- In-air override: disable DT, allow jump, block charge
                if should_disable_dt() then
                    ui_refs.rage.accuracy.auto_stop_opts:override({ "In Air", "Move between Shots" })
                    cmd.in_jump = true
                    rage.exploit:allow_charge(false)
                    utils.execute_after(0.6, function()
                        ui_refs.rage.accuracy.auto_stop_opts:override()
                        rage.exploit:allow_charge(true)
                        ui_refs.rage.main.double_tap:override()
                    end)
                end
                return true
            end
        end

        -- Phase 2: aim and fire during jump timing window
        if jump_scout_state and jump_scout_state.peek_completed then
            if time_since_peek < timing then
                local head_pos = threat:get_hitbox_position(HITBOX_HEAD)
                local eye_pos = lp:get_eye_position()
                cmd.view_angles = (head_pos - eye_pos):angles()
                local fire_now = is_jump_prefire() and time_since_peek > 0.1 or timing * 0.6 < time_since_peek
                if fire_now then
                    if peek_ctx ~= nil and is_peek_target_valid(peek_ctx) then
                        local valid_hb =
                            get_valid_hitbox_positions(active_hitboxes, lp, weapon, peek_ctx.target, min_dmg)
                        can_hit = can_hit_target(lp, threat, eye_pos, valid_hb, min_dmg)
                    end
                    if can_hit then
                        apply_peek_overrides()
                    end
                end
                return true
            elseif on_ground then
                -- Landed, reset state
                reset_peek_state()
                ui_refs.rage.main.double_tap:override()
                return false
            end
        end

        return true
    else
        -- NORMAL JUMP SCOUT MODE
        if not is_active then
            is_active = true
            active_time = curtime
            peek_timer = curtime + 0.1
            can_hit = false
            has_retreated = false
            jump_scout_state = {
                target = threat,
                start_pos = lp:get_origin(),
            }
        end

        local time_active = curtime - active_time
        local time_since_peek = curtime - peek_timer
        local timing = get_jump_timing()
        local min_dmg = get_min_damage()
        local active_hitboxes = get_active_hitboxes()
        local flags = lp.m_fFlags
        local on_ground = bit.band(flags, FL_ONGROUND) ~= 0

        -- Brief stop phase: block movement for a tick to let player decelerate
        if time_active < 0.1 then
            cmd.block_movement = get_block_movement_type()
            return true
        end

        -- Jump phase: jump and override auto-stop options
        if time_since_peek < 0.1 then
            ui_refs.rage.accuracy.auto_stop_opts:override({ "In Air", "Move between Shots" })
            utils.execute_after(0.5, function()
                ui_refs.rage.accuracy.auto_stop_opts:override()
            end)
            cmd.in_jump = true
            cmd.in_duck = false
            if not has_retreated then
                ui_refs.rage.main.double_tap:override(false)
                utils.execute_after(0.5, function()
                    ui_refs.rage.main.double_tap:override()
                end)
                has_retreated = true
            end
            return true
        end

        -- Aim and fire phase (during jump timing window)
        if time_since_peek < timing then
            local head_pos = threat:get_hitbox_position(HITBOX_HEAD)
            local eye_pos = lp:get_eye_position()
            cmd.view_angles = (head_pos - eye_pos):angles()
            -- Manage exploit charge: block while in air, allow on landing
            if not on_ground then
                rage.exploit:allow_charge(false)
            else
                rage.exploit:allow_charge(true)
            end
            local fire_now = is_jump_prefire() and time_since_peek > 0.1 or timing * 0.6 < time_since_peek
            if fire_now then
                if peek_ctx ~= nil and is_peek_target_valid(peek_ctx) then
                    local valid_hb = get_valid_hitbox_positions(active_hitboxes, lp, weapon, peek_ctx.target, min_dmg)
                    can_hit = can_hit_target(lp, threat, eye_pos, valid_hb, min_dmg)
                end
                if can_hit then
                    apply_peek_overrides()
                end
            end
            return true
        end

        -- Landing phase
        if on_ground then
            if not can_hit then
                -- Missed: try charging DT and retry
                if not is_charging_dt then
                    is_charging_dt = true
                    retry_timer = curtime
                    ui_refs.rage.main.double_tap:override()
                    rage.exploit:allow_charge(true)
                    return true
                else
                    -- Give DT 0.2s to charge, then retry
                    if curtime - retry_timer > 0.2 then
                        is_charging_dt = false
                        is_active = false
                        jump_scout_state = nil
                        has_retreated = false
                        if can_jump_scout(lp, weapon) then
                            return run_jump_scout_logic(cmd, lp, weapon)
                        end
                    end
                    return true
                end
            else
                -- Hit confirmed, reset
                reset_peek_state()
                ui_refs.rage.main.double_tap:override()
                return false
            end
        end

        -- Still in the air outside timing window
        return true
    end
end
-- #endregion

-- #region peek position finder

--[[
    Simulates movement from the current position in 3 directions (left, right, back)
    to find the closest position from which the threat can be hit.
    Sets global peek_ctx if a valid position is found.
    Returns true if peek_ctx is active (either newly found or previously found).
]]
local function find_peek_position(cmd, lp, weapon)
    local rate_limit = get_rate_limit()
    local min_dmg = get_min_damage()
    local hitbox_list = get_active_hitboxes()

    -- If we already have a valid peek position, tick its simulation timer
    if peek_ctx ~= nil and is_peek_target_valid(peek_ctx) then
        local target = peek_ctx.target
        local health = target.m_iHealth
        -- Apply overkill adjustment: if min_dmg >= 100 HP, adjust for target health
        if min_dmg >= 100 then
            min_dmg = min_dmg + health - 100
        end
        local valid_hb = get_valid_hitbox_positions(hitbox_list, lp, weapon, target, min_dmg)
        local sim_eye = peek_ctx.ctx.origin + vector(0, 0, peek_ctx.ctx.view_offset)
        local _, hit = peek_ctx.ctx, can_hit_target(lp, target, sim_eye, valid_hb, min_dmg)
        if hit then
            peek_ctx.simtime = 0
        end
        peek_ctx.simtime = peek_ctx.simtime + globals.frametime
        return true
    end

    -- Rate limiting: don't search every frame
    if rate_limit > 0 then
        if rate_limit_timer > 0 then
            rate_limit_timer = rate_limit_timer - globals.frametime
            return false
        else
            rate_limit_timer = rate_limit
        end
    end

    if not can_start_peek(cmd) then
        return false
    end

    -- Must be on ground to start a peek search
    local flags = lp.m_fFlags
    if bit.band(flags, FL_ONGROUND) == 0 then
        return false
    end

    -- Speed check: don't start peek if moving too fast
    -- (stricter threshold in Reaction MASTER / Force Jump Scout mode)
    local speed_limit = (menu.predict_key:get() or menu.force_jump_scout:get()) and 62500 or 6400
    if speed_limit < lp.m_vecVelocity:length2dsqr() then
        return false
    end

    local threat = entity.get_threat()
    if threat == nil or threat:is_dormant() then
        return false
    end

    local health = threat.m_iHealth
    if min_dmg >= 100 then
        min_dmg = min_dmg + health - 100
    end

    local valid_hb = get_valid_hitbox_positions(hitbox_list, lp, weapon, threat, min_dmg)

    -- Already have direct LOS? No need to peek
    if can_hit_target(lp, threat, lp:get_eye_position(), valid_hb, min_dmg) then
        return false
    end

    -- Compute 3 candidate yaw angles relative to threat direction
    local lp_origin = lp:get_origin()
    local to_threat_yaw = (threat:get_origin() - lp_origin):angles().y + 180
    local left_yaw = to_threat_yaw - 90
    local right_yaw = to_threat_yaw + 90
    local back_yaw = to_threat_yaw + 180

    -- Save and modify cmd temporarily for simulation
    local saved_angles = cmd.view_angles:clone()
    local saved_in_jump = cmd.in_jump
    local saved_fwd = cmd.forwardmove
    local saved_side = cmd.sidemove
    local saved_duck = cmd.in_duck
    local saved_speed = cmd.in_speed

    cmd.forwardmove = 450
    cmd.sidemove = 0
    cmd.in_duck = false
    cmd.in_jump = false
    cmd.in_speed = false

    -- Create independent simulation states for each direction
    local sim_left = simulate_player_step(lp)
    local sim_right = simulate_player_step(lp)
    local sim_back = simulate_player_step(lp)

    -- Track per-direction tick count (-1 = direction has gone off-ground, stop)
    local left_tick = 0
    local right_tick = 0
    local back_tick = 0

    for tick = 1, get_peek_range() do
        -- Try left direction
        if left_tick ~= -1 then
            left_tick = tick
            local result, hit = simulate_angle_step(cmd, lp, threat, sim_left, left_yaw, valid_hb, min_dmg)
            if result == nil then
                left_tick = -1
            elseif hit then
                peek_ctx = create_peek_ctx(result, threat)
                break
            end
        end
        -- Try right direction
        if right_tick ~= -1 then
            right_tick = tick
            local result, hit = simulate_angle_step(cmd, lp, threat, sim_right, right_yaw, valid_hb, min_dmg)
            if result == nil then
                right_tick = -1
            elseif hit then
                peek_ctx = create_peek_ctx(result, threat)
                break
            end
        end
        -- Try back direction
        if back_tick ~= -1 then
            back_tick = tick
            local result, hit = simulate_angle_step(cmd, lp, threat, sim_back, back_yaw, valid_hb, min_dmg)
            if result == nil then
                back_tick = -1
            elseif hit then
                peek_ctx = create_peek_ctx(result, threat)
                break
            end
        end
    end

    -- Restore cmd to original state
    cmd.view_angles.y = saved_angles.y
    cmd.forwardmove = saved_fwd
    cmd.sidemove = saved_side
    cmd.in_duck = saved_duck
    cmd.in_jump = saved_in_jump
    cmd.in_speed = saved_speed

    return peek_ctx ~= nil
end
-- #endregion

-- #region createmove main logic

-- Called each tick when the script is enabled and a valid weapon is held
local function on_createmove_main(cmd, lp, weapon, weapon_info)
    local fire_ready = can_fire(lp, weapon, weapon_info)

    if is_force_jump_scout() and is_jump_scout_enabled() then
        -- FORCE JUMP SCOUT
        local found_position = find_peek_position(cmd, lp, weapon)

        -- If exploit is charged, fire_ready and jump scout is handling: let it run
        if peek_ctx ~= nil and fire_ready and rage.exploit:get() == 1 and run_jump_scout_logic(cmd, lp, weapon) then
            return
        end

        if peek_ctx == nil then
            return
        end

        -- Stop moving toward peek if simulation time exceeded
        if get_simulation_time() < peek_ctx.simtime then
            found_position = false
        end
        -- AWP / Scoped: only fire if scoped (weapon_type 5 = sniper)
        if weapon_info.weapon_type == 5 and not lp.m_bIsScoped then
            found_position = false
        end

        if found_position then
            -- Move toward peek position, apply overrides, optionally override DT
            move_toward(cmd, lp, peek_ctx.ctx.origin)
            override_movement_inputs(cmd)
            apply_peek_overrides()
            if should_disable_dt() then
                utils.execute_after(0.5, restore_dt)
            end
            if move_toward(cmd, lp, peek_ctx.ctx.origin) then
                -- Reached: clean up
                reset_peek_state()
                reset_overrides()
            end
        else
            if fire_ready then
                reset_peek_state()
                reset_overrides()
            end
        end
    elseif can_jump_scout(lp, weapon) and rage.exploit:get() == 1 and run_jump_scout_logic(cmd, lp, weapon) then
        -- NORMAL JUMP SCOUT
        return
    else
        -- NORMAL AI PEEK
        local found_position = find_peek_position(cmd, lp, weapon)

        if peek_ctx == nil then
            return
        end

        if get_simulation_time() < peek_ctx.simtime then
            found_position = false
        end
        if weapon_info.weapon_type == 5 and not lp.m_bIsScoped then
            found_position = false
        end

        if peek_ctx.retreat <= 0 and found_position then
            -- PEEK PHASE: move to peek position
            -- Compute retreat position (behind peek spot) if not yet done
            if retreat_pos == nil then
                local origin = lp:get_origin()
                local dir_to_peek = peek_ctx.ctx.origin - origin
                dir_to_peek:normalize()
                local retreat_tgt = peek_ctx.ctx.origin - dir_to_peek * get_retreat_distance()
                retreat_pos = utils.trace_hull(
                    origin,
                    retreat_tgt,
                    peek_ctx.ctx.obb_mins,
                    peek_ctx.ctx.obb_maxs,
                    lp,
                    33636363,
                    0
                ).end_pos
            end

            local reached = move_toward(cmd, lp, peek_ctx.ctx.origin)
            override_movement_inputs(cmd)
            apply_peek_overrides()
            if should_disable_dt() then
                utils.execute_after(0.5, restore_dt)
            end

            peek_ctx.retreat = 0
            if reached then
                peek_ctx.retreat = 1
            end
        elseif not fire_ready then
            reset_peek_state()
        elseif peek_ctx.ctx == nil or peek_ctx.retreat == -1 then
            return -- not yet ready
        else
            -- RETREAT PHASE: move back to cover
            peek_ctx.retreat = peek_ctx.retreat + 1

            if menu.predict_key:get() or menu.force_jump_scout:get() then
                -- Reaction MASTER: aim at target while retreating
                if peek_ctx.target and not peek_ctx.target:is_dormant() then
                    cmd.view_angles = (peek_ctx.target:get_hitbox_position(HITBOX_HEAD) - lp:get_eye_position()):angles()
                end
                override_movement_inputs(cmd)
                apply_peek_overrides()
                if peek_ctx.retreat > 30 then
                    reset_peek_state()
                    reset_overrides()
                end
            else
                -- Normal retreat: move back to retreat_pos
                local reached = move_toward(cmd, lp, retreat_pos)
                local lp_origin = lp:get_origin()
                local vel = lp.m_vecVelocity
                local angle_diff = (retreat_pos - lp_origin):angles() - vel:angles()
                override_movement_inputs(cmd)
                apply_peek_overrides()
                -- Teleport (force_teleport) if moving fast toward retreat pos
                if lp.m_vecVelocity:length2dsqr() > 1600 and math.abs(angle_diff.y) < 20 then
                    rage.exploit:force_teleport()
                    ui_refs.rage.main.double_tap:override(false)
                end
                if fire_ready and reached then
                    reset_peek_state()
                    reset_overrides()
                end
            end
        end
    end
end
-- #endregion

-- #region event callbacks

-- createmove: main entry point each tick
local function on_createmove(cmd)
    if not menu.enabled:get() then
        reset_peek_state()
        reset_overrides()
        return
    end
    local lp = entity.get_local_player()
    if lp == nil then
        return
    end
    local weapon = lp:get_player_weapon()
    if weapon == nil then
        return
    end
    local weapon_info = weapon:get_weapon_info()
    if weapon_info == nil then
        return
    end
    if not is_weapon_allowed(weapon) then
        reset_overrides()
        return
    end
    on_createmove_main(cmd, lp, weapon, weapon_info)
end

-- aim_fire: called when the ragebot fires a shot – reset peek so we don't re-peek
local function on_aim_fire()
    if peek_ctx ~= nil then
        reset_peek_state()
    end
end

-- render: draws HUD indicators for jump scout status
local function on_render()
    if not menu.enabled:get() then
        return
    end
    if entity.get_local_player() == nil then
        return
    end

    local screen = render.screen_size()
    local cx = screen.x / 2
    local cy = screen.y / 2 + 500

    -- Reaction MASTER active indicator
    if menu.predict_key:get() then
        render.text(1, vector(cx, cy), color(255, 255, 255, 255), "c", "REACTION MASTER LLC")
    end

    -- Jump Scout status indicator
    if is_jump_scout_enabled() then
        local status_text = ""
        local status_color = color(255, 255, 255, 255)

        if is_force_jump_scout() then
            if is_active then
                if jump_scout_state and jump_scout_state.peek_phase and not jump_scout_state.peek_completed then
                    status_text = "FORCE JUMP SCOUT - PEEKING"
                    status_color = color(100, 255, 255, 255)
                elseif jump_scout_state and jump_scout_state.peek_completed then
                    status_text = "FORCE JUMP SCOUT - JUMPING"
                    status_color = color(255, 100, 255, 255)
                else
                    status_text = "FORCE JUMP SCOUT - ACTIVE"
                    status_color = color(255, 0, 255, 255)
                end
            else
                status_text = "FORCE JUMP SCOUT MODE"
                status_color = color(255, 0, 255, 255)
            end
        elseif is_active then
            status_text = "JUMP SCOUTING ACTIVE"
            status_color = color(255, 100, 100, 255)
        elseif is_charging_dt then
            status_text = "CHARGING DT FOR RETRY"
            status_color = color(255, 255, 100, 255)
        else
            local lp = entity.get_local_player()
            if lp and can_jump_scout(lp, lp:get_player_weapon()) then
                status_text = "JUMP SCOUT READY"
                status_color = color(100, 255, 100, 255)
            else
                status_text = "JUMP SCOUT ENABLED"
                status_color = color(200, 200, 100, 255)
            end
        end

        -- (status_text / status_color are set but render call omitted in original)
        -- render.text(1, vector(cx, cy + 20), status_color, "c", status_text);
    end
end

-- Register/unregister callbacks when the master switch changes
menu.enabled:set_callback(function(elem)
    local enabled = elem:get()
    if not enabled then
        reset_peek_state()
        reset_overrides()
    end
    events.aim_fire(on_aim_fire, enabled)
    events.createmove(on_createmove, enabled)
    events.render(on_render, enabled)
end, true)

return script_ctx
-- #endregion
