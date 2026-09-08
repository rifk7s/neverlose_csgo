-- My Own Features that i like and added to NL

--[[
    MOLOTOV PARTICLES FIX

    Loops every 3 seconds to update Molotov particle materials based on the UI toggle.
    Hides the Molotov's black smoke and renders the flames as wireframe.
]]

local particle_materials = {
    "particle/particle_flares/particle_flare_gray",
    "particle/smoke1/smoke1_nearcull2",
    "particle/vistasmokev1/vistasmokev1_nearcull",
    "particle/smoke1/smoke1_nearcull",
    "particle/vistasmokev1/vistasmokev1_nearcull_nodepth",
    "particle/vistasmokev1/vistasmokev1_nearcull_fog",
    "particle/vistasmokev1/vistasmokev4_nearcull",
    "particle/smoke1/smoke1_nearcull3",
    "particle/fire_burning_character/fire_env_fire_depthblend_oriented",
    "particle/fire_burning_character/fire_burning_character",
    "particle/fire_explosion_1/fire_explosion_1_oriented",
    "particle/fire_explosion_1/fire_explosion_1_bright",
    "particle/fire_burning_character/fire_burning_character_depthblend",
    "particle/fire_burning_character/fire_env_fire_depthblend",
}

local vis_group = ui.create("Visuals", "Other")
local molotov_checkbox = vis_group:switch("Molotov Particles Fix")

local function set_molotov_materials()
    local enabled = molotov_checkbox:get()
    for _, v in pairs(particle_materials) do
        local mats = materials.get_materials(v)
        if mats then
            local is_fire = v:match("fire") ~= nil
            for _, mat in pairs(mats) do
                if enabled then
                    if not is_fire then
                        mat:var_flag(2, true)
                    else
                        mat:var_flag(2, false)
                        mat:var_flag(28, true)
                    end
                else
                    -- Restore default material state when disabled
                    if not is_fire then
                        mat:var_flag(2, false)
                    else
                        mat:var_flag(2, false)
                        mat:var_flag(28, false)
                    end
                end
            end
        end
    end
    utils.execute_after(3, set_molotov_materials)
end

set_molotov_materials()

--[[
    RIFKY ANIMATION FIX
    
    Interpolates leg pose parameters over time to fix client-side animation stuttering:
    - 3 (SPEED): Controls the blend between idle and moving states, fixing how the model transitions from standing to running.
    - 6 (JUMP_FALL): Controls in-air animations, smoothing the transition between the upward jump force and falling back down.
    - 7 (MOVE_YAW): Aligns the legs with the actual movement direction, stopping the model from moonwalking or crossing its feet.
]]

local anim_group = ui.create("AA", "Other")
local anim_checkbox = anim_group:switch("Rifky Animation Fix")
local nl_leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement")

local pose_params = { 3, 6, 7 }
local current_values = {}
local target_values = {}
local smooth_factor = 0.05 -- 0.01 to 0.1 recommended

-- Initialize random values
for i = 1, #pose_params do
    current_values[i] = math.random()
    target_values[i] = math.random()
end

events.createmove:set(function()
    if anim_checkbox:get() then
        for i = 1, #pose_params do
            if math.random() < 0.01 then -- Small chance to update target
                target_values[i] = math.random()
            end
        end
    end
end)

events.post_update_clientside_animation:set(function(player)
    if anim_checkbox:get() then
        local local_player = entity.get_local_player()
        if not local_player or player ~= local_player then
            return
        end

        for i, pose_index in ipairs(pose_params) do
            -- Smooth interpolation
            current_values[i] = current_values[i] + (target_values[i] - current_values[i]) * smooth_factor

            -- Set pose parameter (m_flPoseParameter)
            local_player.m_flPoseParameter[pose_index] = current_values[i]
        end
    end
end)

--[[
    ZETSU ANIMATIONS
    
    Uses FFI to directly modify the local player's ccsgoplayeranimstate_zetsu (anim state) and zetsu_anim_layer_t (overlays).
    Contains multiple sub-features that hook into pre_render and post_update_clientside_animation:
    
    1. FLOW (In-Air) - Modifies pose parameter 6 (JUMP_FALL) and Layer 6:
       - Quadrobic: Syncs jump_fall to time_since_in_air.
       - Static / Trap / Swag / Jitter: Forces jump_fall to static values or random bounds to glitch the mid-air pose.
       - Walking: Overrides Layer 6 (Movement) weight and cycle to simulate walking while in the air.
    
    2. GROUND (Legs) - Modifies pose parameters 0 (STRAFE_YAW), 7 (MOVE_YAW), 10 (MOVE_BLEND_RUN) and others:
       - Static / Static invert: Locks move_yaw and strafe_yaw to 1 or -1.
       - Trap / Swag / Jitter: Randomizes multiple parameters (including SPEED and STAND) for erratic leg sliding.
       - Freeze: Sets MOVE_BLEND_RUN (10) to 0, completely freezing the running animation loop.
       - Bugged: Randomizes almost every movement blend parameter (0,1,2,3,4,5,7,8,9,10) simultaneously.
    
    3. LEAN - Modifies Layer 12 (Lean overlay):
       - Jitter: Randomizes the lean weight while moving.
       - Zero / Big: Forces the lean weight to 0 (no lean) or 1 (max lean) when velocity > 10.
    
    4. ADDITIVE (Extra Tweaks) - Selectable overlays and parameters:
       - 2021 animfix: Locks pose 11 (BODY_YAW) to 0.5.
       - Zero pitch: Locks pose 12 (BODY_PITCH) to 0.5 upon landing.
       - Animation smooth: Forces Layer 3 weight to 1 and cycles it to fix model stuttering.
       - Autopeek fix: Suppresses Layer 7 (Strafe) weight to 0 while autopeeking to prevent leg sliding.
       - Flashed: Overrides Layer 0 (Aim Matrix) sequence to 227 (blind animation).
       - Model scale: Attempts to shrink the player via m_flModelScale and FFI bone cache invalidation, but this is buggy and does not work due to Neverlose limitations.
]]

local ffi = require("ffi")
pcall(
    ffi.cdef,
    [[
    struct zetsu_anim_layer_t {
        char pad0[0x18];
        unsigned int sequence;
        float prev_cycle;
        float weight;
        float weight_delta_rate;
        float playback_rate;
        float cycle;
        void* owner;
        char pad1[0x4];
    };
    struct ccsgoplayeranimstate_zetsu {
        char pad0[0x18];
        float anim_update_timer;
        char pad1[0xC];
        float started_moving_time;
        float last_move_time;
        char pad2[0x10];
        float last_lby_time;
        char pad3[0x8];
        float run_amount;
        char pad4[0x10];
        void* entity;
        void* active_weapon;
        void* last_active_weapon;
        float last_client_side_animation_update_time;
        int last_client_side_animation_update_framecount;
        float eye_timer;
        float eye_angles_y;
        float eye_angles_x;
        float goal_feet_yaw;
        float current_feet_yaw;
        float torso_yaw;
        float last_move_yaw;
        float lean_amount;
        char pad5[0x4];
        float feet_cycle;
        float feet_yaw_rate;
        char pad6[0x4];
        float duck_amount;
        float landing_duck_amount;
        char pad7[0x4];
        float current_origin[3];
        float last_origin[3];
        float velocity_x;
        float velocity_y;
        char pad8[0x4];
        float unknown_float1;
        char pad9[0x8];
        float unknown_float2;
        float unknown_float3;
        float unknown;
        float m_velocity;
        float jump_fall_velocity;
        float clamped_velocity;
        float feet_speed_forwards_or_sideways;
        float feet_speed_unknown_forwards_or_sideways;
        float last_time_started_moving;
        float last_time_stopped_moving;
        bool on_ground;
        bool hit_in_ground_animation;
        char pad10[0x4];
        float time_since_in_air;
        float last_origin_z;
        float head_from_ground_distance_standing;
        float stop_to_full_running_fraction;
        char pad11[0x4];
        float magic_fraction;
        char pad12[0x3C];
        float world_force;
        char pad13[0x1CA];
        float min_yaw;
        float max_yaw;
    };
]]
)

local function get_anim_overlay(player, layer)
    if not player or not player[0] then
        return nil
    end
    local ptr = ffi.cast("char*", player[0])
    local anim_overlays = ffi.cast("struct zetsu_anim_layer_t**", ptr + 10640)[0]
    return anim_overlays[layer]
end

local function get_animstate(player)
    if not player or not player[0] then
        return nil
    end
    local ptr = ffi.cast("char*", player[0])
    return ffi.cast("struct ccsgoplayeranimstate_zetsu**", ptr + 0x9960)[0]
end

local zetsu_group = ui.create("AA", "Other")
local zetsu_master = zetsu_group:switch("Zetsu Animations")
local zetsu_anims = zetsu_group:selectable("Animations", "Flow", "Ground", "Lean", "Additive")
local zetsu_flow = zetsu_group:combo("Animations / Flow", "Quadrobic", "Static", "Jitter", "Trap", "Swag", "Walking")
local zetsu_ground = zetsu_group:combo(
    "Animations / Ground",
    "Static",
    "Static invert",
    "Jitter",
    "Trap",
    "Swag",
    "Freeze",
    "Freeze & Static",
    "Freeze & Static invert",
    "Bugged"
)
local zetsu_lean = zetsu_group:combo("Animations / Lean", "Zero", "Big", "Jitter")
local zetsu_additive = zetsu_group:selectable(
    "Animations / Additive",
    "2021 animfix",
    "Model scale",
    "Autopeek fix",
    "Animation smooth",
    "Flashed",
    "Zero pitch"
)

local function update_zetsu_visibility()
    local enabled = zetsu_master:get()
    zetsu_anims:visibility(enabled)
    zetsu_flow:visibility(enabled and zetsu_anims:get("Flow"))
    zetsu_ground:visibility(enabled and zetsu_anims:get("Ground"))
    zetsu_lean:visibility(enabled and zetsu_anims:get("Lean"))
    zetsu_additive:visibility(enabled and zetsu_anims:get("Additive"))
end

zetsu_master:set_callback(update_zetsu_visibility)
zetsu_anims:set_callback(update_zetsu_visibility)
update_zetsu_visibility()

local function random_float(min, max)
    return min + math.random() * (max - min)
end

-- post_update_clientside_animation: only pose params (Flow, Ground, Lean, 2021animfix, Zero pitch)
-- These must be set here because they affect the anim state machine.
events.post_update_clientside_animation:set(function(player)
    if not zetsu_master:get() then
        return
    end
    local me = entity.get_local_player()
    if not me or player ~= me or not me:is_alive() then
        return
    end

    local state = get_animstate(me)
    if not state or state == ffi.NULL then
        return
    end

    -- Flow (In Air)
    if zetsu_anims:get("Flow") and not state.on_ground then
        local flow = zetsu_flow:get()
        if flow == "Quadrobic" then
            me.m_flPoseParameter[6] = state.time_since_in_air
        elseif flow == "Static" then
            me.m_flPoseParameter[6] = 1
        elseif flow == "Trap" then
            me.m_flPoseParameter[6] = random_float(0.5, 2.0)
        elseif flow == "Swag" then
            me.m_flPoseParameter[6] = random_float(math.random(), random_float(state.time_since_in_air, 1))
        elseif flow == "Jitter" then
            me.m_flPoseParameter[6] = random_float(0.5, 1.0)
        elseif flow == "Walking" then
            local overlay = get_anim_overlay(me, 6)
            if overlay then
                overlay.weight = 1
                overlay.cycle = globals.realtime * 0.5 % 1
            end
        end
    end

    -- Ground
    if zetsu_anims:get("Ground") and state.on_ground then
        local ground = zetsu_ground:get()
        if ground == "Static" then
            me.m_flPoseParameter[0] = 1
            me.m_flPoseParameter[7] = 1
        elseif ground == "Static invert" then
            me.m_flPoseParameter[0] = -1.0
            me.m_flPoseParameter[7] = -1.0
        elseif ground == "Trap" then
            me.m_flPoseParameter[0] = random_float(0.5, 2.0)
            me.m_flPoseParameter[7] = random_float(0.5, 2.0)
        elseif ground == "Swag" then
            local val1 = random_float(0, 5)
            local val2 = random_float(0, 1)
            if val1 <= val2 then
                me.m_flPoseParameter[0] = math.random(math.floor(val1), math.floor(val2))
                me.m_flPoseParameter[7] = math.random(math.floor(val1), math.floor(val2))
            end
        elseif ground == "Jitter" then
            me.m_flPoseParameter[7] = random_float(0, 1)
            me.m_flPoseParameter[0] = random_float(random_float(0, 1), random_float(0, 1))
            me.m_flPoseParameter[1] = random_float(0, 1)
            me.m_flPoseParameter[3] = random_float(0, 1)
            me.m_flPoseParameter[4] = random_float(0, 1)
            me.m_flPoseParameter[5] = random_float(0, 1)
            me.m_flPoseParameter[8] = random_float(0, 1)
        elseif ground == "Freeze" then
            me.m_flPoseParameter[10] = 0
        elseif ground == "Freeze & Static" then
            me.m_flPoseParameter[0] = 1
            me.m_flPoseParameter[10] = 0
        elseif ground == "Freeze & Static invert" then
            me.m_flPoseParameter[0] = 0.5
            me.m_flPoseParameter[10] = 0
        elseif ground == "Bugged" then
            for _, i in ipairs({ 7, 0, 1, 2, 3, 4, 5, 8, 9, 10 }) do
                me.m_flPoseParameter[i] = random_float(0, 1)
            end
        end
    end

    -- Lean
    if zetsu_anims:get("Lean") then
        local lean = zetsu_lean:get()
        local overlay = get_anim_overlay(me, 12)
        if overlay then
            if lean == "Jitter" then
                overlay.weight = random_float(0.3, 1)
                overlay.cycle = globals.realtime * 0.5 % 1
            elseif state.m_velocity >= 10 then
                if lean == "Zero" then
                    overlay.weight = 0
                    overlay.cycle = globals.realtime * 0.5 % 1
                elseif lean == "Big" then
                    overlay.weight = 1
                    overlay.cycle = globals.realtime * 0.5 % 1
                end
            end
        end
    end

    -- Additive (pose param only subset)
    if zetsu_anims:get("Additive") then
        if zetsu_additive:get("2021 animfix") then
            me.m_flPoseParameter[11] = 0.5
        end

        if
            zetsu_additive:get("Zero pitch")
            and state.hit_in_ground_animation
            and state.magic_fraction == 1
            and state.on_ground
        then
            me.m_flPoseParameter[12] = 0.5
        end
    end
end)

-- pre_render: overlay-based additive effects (Animation smooth, Autopeek fix, Flashed)
-- MUST run in pre_render, not post_update_clientside_animation.
-- post_update_clientside_animation runs during engine anim update and values get
-- overwritten before drawing. pre_render is after all anim updates, values stick.
local zetsu_peek_assist = ui.find("Aimbot", "Ragebot", "Main", "Peek Assist")
events.pre_render:set(function()
    if not zetsu_master:get() then
        return
    end
    if not zetsu_anims:get("Additive") then
        return
    end
    local me = entity.get_local_player()
    if not me or not me:is_alive() then
        return
    end

    if zetsu_additive:get("Animation smooth") then
        -- Overlay 3 = move animation layer; setting weight=1 and cycling it
        -- smooths out the motion blur / stuttering on the local player model
        local overlay = get_anim_overlay(me, 3)
        if overlay then
            overlay.weight = 1
            overlay.cycle = globals.realtime * 0.5 % 1
        end
    end

    if zetsu_additive:get("Autopeek fix") then
        -- Only suppress overlay 7 when peek-assist is actively being used (hotkey held),
        -- not just when it is enabled in the menu. This matches the original Zetsu logic:
        --    lua.reference.rage.binds.quickpeek[1]:get_hotkey()
        local leg_move = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement")
        local peek_active = zetsu_peek_assist and zetsu_peek_assist:get()
        local leg_not_slide = not leg_move or (leg_move:get() ~= "Always slide")
        if peek_active and leg_not_slide then
            local overlay = get_anim_overlay(me, 7)
            if overlay then
                overlay.weight = 0
            end
        end
    end

    if zetsu_additive:get("Flashed") then
        local overlay = get_anim_overlay(me, 0)
        if overlay then
            overlay.sequence = 227
        end
    end
end)

local ffi = require("ffi")
ffi.cdef([[
    typedef void*(__thiscall* c_entity_list_get_client_entity_t)(void*, int);
]])
local i_client_entity_list = ffi.cast("void***", utils.create_interface("client.dll", "VClientEntityList003"))
local get_client_entity = ffi.cast("c_entity_list_get_client_entity_t", i_client_entity_list[0][3])

local function apply_model_scale()
    if not zetsu_master:get() then
        return
    end
    local me = entity.get_local_player()
    if not me or not me:is_alive() then
        return
    end

    if zetsu_anims:get("Additive") and zetsu_additive:get("Model scale") then
        local my_ptr = get_client_entity(i_client_entity_list, me:get_index())
        if my_ptr ~= nil then
            local offset_m_flModelScale = utils.get_netvar_offset("DT_BaseAnimating", "m_flModelScale")
            local offset_m_ScaleType = utils.get_netvar_offset("DT_BaseAnimating", "m_ScaleType")
            if offset_m_ScaleType > 0 and offset_m_flModelScale > 0 then
                -- Try native Neverlose API first (this might trigger bone cache invalidation internally)
                pcall(function()
                    me.m_flModelScale = 0.5
                end)
                pcall(function()
                    me.m_ScaleType = 1
                end)

                -- Also apply via FFI just in case
                local int_ptr = ffi.cast("int*", ffi.cast("uintptr_t", my_ptr) + offset_m_ScaleType)
                int_ptr[0] = 1
                local float_ptr = ffi.cast("float*", ffi.cast("uintptr_t", my_ptr) + offset_m_flModelScale)
                float_ptr[0] = 0.5

                -- Force InvalidateBoneCache by resetting m_iMostRecentModelBoneCounter
                local bone_counter = ffi.cast("unsigned int*", ffi.cast("uintptr_t", my_ptr) + 0x2690)
                bone_counter[0] = 0
                local last_bone_setup_time = ffi.cast("float*", ffi.cast("uintptr_t", my_ptr) + 0x2924)
                last_bone_setup_time[0] = -1.0
            end
        end
    else
        local my_ptr = get_client_entity(i_client_entity_list, me:get_index())
        if my_ptr ~= nil then
            local offset_m_flModelScale = utils.get_netvar_offset("DT_BaseAnimating", "m_flModelScale")
            local offset_m_ScaleType = utils.get_netvar_offset("DT_BaseAnimating", "m_ScaleType")
            if offset_m_ScaleType > 0 and offset_m_flModelScale > 0 then
                local int_ptr = ffi.cast("int*", ffi.cast("uintptr_t", my_ptr) + offset_m_ScaleType)
                int_ptr[0] = 0
                local float_ptr = ffi.cast("float*", ffi.cast("uintptr_t", my_ptr) + offset_m_flModelScale)
                float_ptr[0] = 1.0
            end
        end
    end
end

events.pre_render:set(apply_model_scale)
events.createmove:set(apply_model_scale)
events.net_update_end:set(apply_model_scale)
pcall(function()
    events.post_update_clientside_animation:set(apply_model_scale)
end)
pcall(function()
    events.render:set(apply_model_scale)
end)
pcall(function()
    events.override_view:set(apply_model_scale)
end)
pcall(function()
    events.paint:set(apply_model_scale)
end)

--[[
    AUTO GRENADE RELEASE
    
    Uses the cheat's grenade_prediction event to automatically throw HEs and Molotovs based on predicted damage:
    - Grenade Prediction: Listens for "Frag" or "Molly" trajectories and caches the ctx.damage value.
    - CreateMove Logic: Verifies the active weapon matches the allowed UI types (HE or Molotov/Incendiary).
    - Throw Logic: When predicted damage exceeds the UI slider threshold:
      - 'On Pin Pulled' Mode: Only releases the attack button (cmd.in_attack = false) if the user has manually pulled the pin.
      - Auto Mode: Forces the attack button down (cmd.in_attack = true) to pull the pin, then releases it on subsequent ticks.
]]

local gr_group = ui.create("Visuals", "Other")
local auto_release = gr_group:switch("Auto Grenade Release")
local auto_release_gear = auto_release:create()
local auto_release_pin = auto_release_gear:switch("On Pin Pulled")
local auto_release_dmg = auto_release_gear:slider("Min. Damage", 1, 60, 20)
local auto_release_types = auto_release_gear:selectable("Allowed", "High Explosive", "Molotov")

local predicted_damage = 0

events.grenade_prediction:set(function(ctx)
    if not auto_release:get() then
        return
    end
    if ctx.type == "Frag" or ctx.type == "Molly" then
        predicted_damage = ctx.damage
    else
        predicted_damage = 0
    end
end)

events.createmove:set(function(cmd)
    if not auto_release:get() then
        return
    end

    local me = entity.get_local_player()
    if not me or not me:is_alive() then
        return
    end

    local wpn = me:get_player_weapon()
    if not wpn then
        return
    end

    local classname = wpn:get_classname()
    local is_allowed = false

    if classname == "CHEGrenade" and auto_release_types:get("High Explosive") then
        is_allowed = true
    elseif
        (classname == "CMolotovGrenade" or classname == "CIncendiaryGrenade") and auto_release_types:get("Molotov")
    then
        is_allowed = true
    end

    if not is_allowed then
        return
    end

    if predicted_damage >= auto_release_dmg:get() then
        if auto_release_pin:get() then
            if cmd.in_attack and wpn.m_bPinPulled then
                cmd.in_attack = false
            end
        else
            if cmd.in_attack and wpn.m_bPinPulled then
                cmd.in_attack = false
            end
            if not wpn.m_bPinPulled then
                cmd.in_attack = true
            end
        end
    end
end)

--[[
    SCOREBOARD EQUIPMENT

    Injects custom Panorama UI JavaScript to render weapon and utility icons directly onto the CS:GO scoreboard:
    - Panorama Injection: Uses panorama.loadstring to hook into the "CSGOHud" context and access the ScoreboardContainer.
    - JavaScript Rendering: Dynamically creates and sorts <ItemImage> XML tags based on a predefined weapon priority list (e.g., primary weapons sort before grenades).
    - Lua Data Collection: Hooks net_update_end to scan player entities round-robin style for their active weapon and inventory.
    - Data Bridge: Converts the Lua entity data into a JSON-compatible array and passes it to the JS method, filtering by Team/Local UI settings.
]]

do
    local string_format = string.format
    local table_concat = table.concat
    local table_remove = table.remove
    local ScoreboardManager = {}
    local Utils = {}
    local PlayerDataManager = {}
    local UI_Elements = {}
    -- sidebar removed
    UI_Elements.group_ref = gr_group
    UI_Elements.enabled = UI_Elements.group_ref:switch("Scoreboard Equipment")
    UI_Elements.sb_gear = UI_Elements.enabled:create()
    UI_Elements.color_label = UI_Elements.sb_gear:label("Icon Color")
    UI_Elements.enabled_cp = UI_Elements.color_label:color_picker(color(255, 140))
    UI_Elements.team_only = UI_Elements.sb_gear:switch("Team Equipment", true)
    UI_Elements.local_player = UI_Elements.sb_gear:switch("Local Equipment", true)
    UI_Elements.scale = UI_Elements.sb_gear:slider("Scale", 10, 100, 50)
    local UI_State = {
        local_player = false,
        team_only = false,
        scale = 50,
        enabled = false,
    }
    local UI_Callbacks = {
        enabled = function()
            -- upvalues: UI_State (ref), UI_Elements (ref)
            UI_State.enabled = UI_Elements.enabled:get()
        end,
        team_only = function()
            -- upvalues: UI_State (ref), UI_Elements (ref)
            UI_State.team_only = UI_Elements.team_only:get()
        end,
        local_player = function()
            -- upvalues: UI_State (ref), UI_Elements (ref)
            UI_State.local_player = UI_Elements.local_player:get()
        end,
        scale = function()
            -- upvalues: UI_State (ref), UI_Elements (ref), ScoreboardManager (ref)
            UI_State.scale = UI_Elements.scale:get()
            ScoreboardManager.m_times_recalled = 0
        end,
    }
    for key, element in pairs(UI_Elements) do
        if key ~= "group_ref" and key ~= "enabled_cp" and key ~= "sb_gear" and key ~= "color_label" then
            element:set_callback(UI_Callbacks[key], true)
        end
    end
    ScoreboardManager = {
        prev_update = 0,
        _init = function(self)
            self.methods = self.exec([[
            _scoreboardWeapons = function () {
    
                this.getContainer = function() {
                    var contextPanel = $.GetContextPanel();
                    var csgoHud = contextPanel.FindChild("Hud");
                    return ScoreboardContainer = csgoHud.FindChild("ScoreboardContainer");
                }
    
                this.weapon_priority = {
                    armor_helmet: 397,
                    armor: 398,
                    defuser: 399,
                    flashbang: 400,
                    hegrenade: 401,
                    smokegrenade: 402,
                    molotov: 403,
                    decoy: 404,
                    incgrenade: 405,
                    frag_grenade: 406,
                    c4: 498,
                    taser: 499,
                    deagle: 500,
                    elite: 501,
                    fiveseven: 502,
                    glock: 503,
                    tec9: 504,
                    hkp2000: 505,
                    p250: 506,
                    usp_silencer: 507,
                    cz75a: 508,
                    revolver: 509,
                    ak47: 600,
                    aug: 601,
                    awp: 602,
                    famas: 603,
                    g3sg1: 604,
                    galilar: 604,
                    m249: 605,
                    m4a1: 606,
                    mac10: 607,
                    p90: 608,
                    mp5sd: 609,
                    ump45: 610,
                    xm1014: 611,
                    bizon: 612,
                    mag7: 613,
                    negev: 614,
                    sawedoff: 615,
                    mp7: 616,
                    mp9: 617,
                    nova: 618,
                    scar20: 619,
                    sg556: 620,
                    ssg08: 621,
                    m4a1: 622
                }
    
                this.getXuid = function (entityIndex) { return entityIndex ? GameStateAPI.GetPlayerXuidStringFromEntIndex(entityIndex) : -1 }
            
                this.declaredChilds = []
    
                this.latest_array = []
                this.updatePlayer = function (playerArray, teamCheck, show_local, color, alpha, scale) {

                    const objHash = JSON.stringify(playerArray)
                    if (this.latest_array == objHash)
                        return

                    this.latest_array = objHash

                    if(playerArray == undefined)
                        playerArray = []

                    // entityIndex, weaponArray, activeWeapon
                
                    if(scale != undefined) 
                        scale = scale.toString() + "%"

                    var playerArrayV2 = []
                    const localXUID = GameStateAPI.GetLocalPlayerXuid()
                    const localTeam = GameStateAPI.GetAssociatedTeamNumber(localXUID)
    
                    for(var i in playerArray) {
                        var tempXuid = getXuid(playerArray[i].index)

                        if(tempXuid != -1 || tempXuid != 0) {

                            var tempWeaponArray = []

                            for(var j in playerArray[i].weapons) {
                                tempWeaponArray[Number(j) - 1] = playerArray[i].weapons[j]
                            }

                            playerArrayV2[tempXuid] = {weapons: tempWeaponArray, active: playerArray[i].active}
                        }
                    }
    
                    getContainer().FindChildrenWithClassTraverse("spectator-hidden").forEach(function (playerElement) {
            
                        if (playerElement["id"] !== "id-sb-name__nameicons") return false
            
                        var steamID = 0
                        playerElement.GetParent().Children().forEach(function (localElement) {
                            if (localElement["paneltype"] == "Label") {
                                steamID = localElement.GetParent().GetParent()["m_xuid"];
                                return;
                            }
                        });
    
    
                        if (playerArrayV2.length == 0 || ( (steamID != localXUID && teamCheck && GameStateAPI.GetAssociatedTeamNumber(steamID) == localTeam) || ((show_local && steamID == localXUID)) )) {
                            playerElement.Children().forEach((childElement) => {
                                if(childElement.id.startsWith("nvl_"))
                                    childElement.DeleteAsync(.0)
                            })
                            return false;
                        }
    
                        var weaponArray, activeWeapon
    
                        if(playerArrayV2[steamID]) {
                            weaponArray = playerArrayV2[steamID].weapons
                            activeWeapon = playerArrayV2[steamID].active
                        } else { return false }
            
                        if (!declaredChilds[steamID]) declaredChilds[steamID] = []
            
                        for (var i in declaredChilds[steamID]) {
                            var declaredFindChild = playerElement.FindChild("nvl_" + declaredChilds[steamID][i])
                            if (!declaredFindChild) continue
            
                            var currentExists = false
                            for (var j in weaponArray) {
                                if (declaredChilds[steamID][i] == weaponArray[j]) {
                                    currentExists = true
                                    break;
                                }
                            }
                            if (!currentExists) {
                                declaredFindChild.DeleteAsync(.0)
                            }
                        }
    
                        function resort() {
    
                            var tempChilds = []
                            playerElement.Children().forEach((childElement) => {
                                if(childElement.id.startsWith("nvl_"))
                                    tempChilds.push(childElement)
                            })
    
                            let newArray = tempChilds.sort((a, b) => this.weapon_priority[b.id.replace("nvl_", "")] - this.weapon_priority[a.id.replace("nvl_", "")])
                            for(var i in newArray) {
                                let j = parseInt(i)
                                if(newArray[j + 1])  playerElement.MoveChildBefore(newArray[j+1], newArray[j]) 
                            }
                        }
    
                        for (var weapon of weaponArray) {
            
                            if(weapon == "no") continue;
                            var alphaWeapon = weapon == activeWeapon ? Math.max(Math.min(1, alpha), 0.01) : Math.max(Math.min(1, alpha - 0.5), 0.01)
                            var newElement = playerElement.FindChild("nvl_" + weapon)


                            if (declaredChilds[steamID].indexOf(weapon) == -1) declaredChilds[steamID].push(weapon)
            
            
                            if (!newElement) {
                                playerElement.BCreateChildren(`<ItemImage id="nvl_${weapon}" registerforreadyevents="true" readyfordisplay="false" src="file://{images}/icons/equipment/${weapon}.svg" scaling="stretch-to-fit-preserve-aspect" style="transition-property: opacity; transition-duration: 0.1s; transition-timing-function: ease-in-out; margin-left: 2px; margin-right: 2px;ui-scale: ${scale}; vertical-align: middle; opacity: 0.001;wash-color: #${color};"/>`);
                                newElement = playerElement.FindChild("nvl_" + weapon)
                                newElement.style.opacity = alphaWeapon
                            } else {
                                newElement.style.opacity = alphaWeapon
                                newElement.style.washColor = "#" + color
                                newElement.style["ui-scale"] = scale
                            }
                        }
    
                        resort()
                    })
                }
            
                return this;
            }
            return _scoreboardWeapons()
        ]])
        end,
        updatePlayer = function(self, playerArray, forceUpdate)
            -- upvalues: Utils (ref), UI_State (ref), UI_Elements (ref)
            local realtime = globals.realtime
            if not forceUpdate and realtime < self.prev_update then
                return
            else
                local jsPlayerArray = Utils:convert_to_js(playerArray)
                local teamCheck = not UI_State.team_only
                local showLocal = not UI_State.local_player
                local scale = UI_State.scale
                local colorPickerValue = UI_Elements.enabled_cp:get()
                local hexColor = Utils.rgb_to_hex(colorPickerValue)
                local alpha = colorPickerValue.a / 255
                self.methods.updatePlayer(jsPlayerArray, teamCheck, showLocal, hexColor, alpha, scale)
                self.prev_update = realtime + 0.1
                return
            end
        end,
        exec = function(jsCode)
            return panorama.loadstring(jsCode, "CSGOHud")()
        end,
    }

    Utils = {
        _init = function(_) end,
        rgb_to_hex = function(colorObj)
            return colorObj:to_hex():sub(1, 6)
        end,
        contains = function(tbl, val)
            if tbl == nil or val == nil then
                return false
            else
                for k, v in pairs(tbl) do
                    if v == val then
                        return k
                    end
                end
                return false
            end
        end,
        convert_to_js = function(_, playerDataArr)
            -- upvalues: ScoreboardManager (ref)
            local jsArr = {}
            if playerDataArr == nil then
                return {}
            else
                for i = 1, #playerDataArr do
                    local jsPlayer = {}
                    local playerData = playerDataArr[i]
                    jsPlayer.weapons = {}
                    for j = 1, #playerData.weapons do
                        local weaponName = playerData.weapons[j]
                        if ScoreboardManager.methods.weapon_priority[weaponName] ~= nil then
                            table.insert(jsPlayer.weapons, weaponName)
                        end
                    end
                    jsPlayer.active = playerData.active
                    jsPlayer.index = playerData.index
                    table.insert(jsArr, jsPlayer)
                end
                return jsArr
            end
        end,
    }
    PlayerDataManager = {
        _array = {},
        _create = function(self, playerIdx)
            if playerIdx == nil then
                return false
            elseif self._array[playerIdx] ~= nil then
                return false
            else
                self._array[playerIdx] = {
                    active = "no",
                    weapons = {},
                }
                return true
            end
        end,
        add = function(self, playerIdx, weaponName)
            -- upvalues: Utils (ref)
            if weaponName == nil then
                return self._array[playerIdx]
            else
                if not self._array[playerIdx] then
                    self:_create(playerIdx)
                end
                if not Utils.contains(self._array[playerIdx].weapons, weaponName) then
                    self._array[playerIdx].weapons[#self._array[playerIdx].weapons + 1] = weaponName
                end
                return self._array[playerIdx]
            end
        end,
        set = function(self, playerIdx, weaponArr)
            if weaponArr == nil then
                return false
            else
                if not self._array[playerIdx] then
                    self:_create(playerIdx)
                end
                self._array[playerIdx].weapons = weaponArr
                return self._array[playerIdx]
            end
        end,
        get = function(self, playerIdx)
            if not self._array[playerIdx] then
                self:_create(playerIdx)
            end
            return self._array[playerIdx]
        end,
        active = function(self, playerIdx, activeWeapon)
            if not self._array[playerIdx] then
                self:_create(playerIdx)
            end
            self:add(playerIdx, activeWeapon)
            self._array[playerIdx].active = activeWeapon
            return self._array[playerIdx]
        end,
        remove = function(self, playerIdx, weaponName)
            -- upvalues: Utils (ref), table_remove (ref)
            if weaponName == nil then
                return self._array[playerIdx]
            else
                if not self._array[playerIdx] then
                    self:_create(playerIdx)
                end
                local idx = Utils.contains(self._array[playerIdx].weapons, weaponName)
                if idx then
                    table_remove(self._array[playerIdx].weapons, idx)
                end
                return self._array[playerIdx]
            end
        end,
        reset = function(self, playerIdx, _)
            if not self._array[playerIdx] then
                self:_create(playerIdx)
            end
            self._array[playerIdx] = {
                active = "no",
                weapons = {},
            }
            return self._array[playerIdx]
        end,
    }
    local EventHandlers = {
        item_equip = function(e)
            -- upvalues: UI_State (ref), PlayerDataManager (ref)
            if not UI_State.enabled then
                return
            else
                local entityPtr = entity.get(e.userid, true)
                if entityPtr == nil then
                    return
                else
                    local entIndex = entityPtr:get_index()
                    local itemName = e.item
                    if e.defindex == 64 then
                        itemName = "revolver"
                    end
                    PlayerDataManager:active(entIndex, itemName)
                    return
                end
            end
        end,
        item_remove = function(e)
            -- upvalues: UI_State (ref), PlayerDataManager (ref)
            if not UI_State.enabled then
                return
            else
                local entityPtr = entity.get(e.userid, true)
                if entityPtr == nil then
                    return
                else
                    local entIndex = entityPtr:get_index()
                    local itemName = e.item
                    if e.defindex == 64 then
                        itemName = "revolver"
                    end
                    PlayerDataManager:remove(entIndex, itemName)
                    return
                end
            end
        end,
        player_death = function(e)
            -- upvalues: UI_State (ref), PlayerDataManager (ref)
            if not UI_State.enabled then
                return
            else
                local entityPtr = entity.get(e.userid, true)
                if entityPtr == nil then
                    return
                else
                    local entIndex = entityPtr:get_index()
                    PlayerDataManager:reset(entIndex)
                    return
                end
            end
        end,
        item_purchase = function(e)
            -- upvalues: UI_State (ref), PlayerDataManager (ref)
            if not UI_State.enabled then
                return
            else
                local entityPtr = entity.get(e.userid, true)
                if entityPtr == nil then
                    return
                else
                    local entIndex = entityPtr:get_index()
                    local itemName = e.weapon:gsub("weapon_", "")
                    if itemName == "item_kevlar" then
                        itemName = "armor"
                    elseif itemName == "item_assaultsuit" then
                        itemName = "armor_helmet"
                    end
                    PlayerDataManager:add(entIndex, itemName)
                    return
                end
            end
        end,
        item_pickup = function(e)
            -- upvalues: UI_State (ref), PlayerDataManager (ref)
            if not UI_State.enabled then
                return
            else
                local entityPtr = entity.get(e.userid, true)
                if entityPtr == nil then
                    return
                else
                    local entIndex = entityPtr:get_index()
                    local itemName = e.item
                    if e.defindex == 64 then
                        itemName = "revolver"
                    end
                    PlayerDataManager:add(entIndex, itemName)
                    return
                end
            end
        end,
    }
    local EntityGetter = {
        get = function(playerEnt)
            -- upvalues: PlayerDataManager (ref)
            if playerEnt == nil then
                return
            else
                local entIndex = playerEnt:get_index()
                if playerEnt.m_iHealth < 1 then
                    return PlayerDataManager:reset(entIndex)
                else
                    local activeWeaponEnt = playerEnt:get_player_weapon()
                    if activeWeaponEnt == nil then
                        return PlayerDataManager:reset(entIndex)
                    else
                        local activeWeapon = playerEnt:get_player_weapon(true)
                        local v85 = {}
                        for _, weaponEnt in ipairs(activeWeapon) do
                            local weapon = weaponEnt:get_weapon_info()
                            local v89 = weapon.weapon_name:gsub("weapon_", "")
                            if weapon.is_revolver then
                                v89 = "revolver"
                            end
                            table.insert(v85, v89)
                        end
                        local playerResource = playerEnt:get_resource()
                        local l_m_bHasHelmet_0 = playerResource.m_bHasHelmet
                        local v92 = playerResource.m_iArmor > 0
                        local l_m_bHasDefuser_0 = playerResource.m_bHasDefuser
                        if l_m_bHasHelmet_0 then
                            table.insert(v85, "armor_helmet")
                        end
                        if v92 and not l_m_bHasHelmet_0 then
                            table.insert(v85, "armor")
                        end
                        if l_m_bHasDefuser_0 then
                            table.insert(v85, "defuser")
                        end
                        local weaponInfo = activeWeaponEnt:get_weapon_info()
                        local v95 = weaponInfo.weapon_name:gsub("weapon_", "")
                        if weaponInfo.is_revolver then
                            v95 = "revolver"
                        end
                        return {
                            index = entIndex,
                            weapons = v85,
                            active = v95,
                        }
                    end
                end
            end
        end,
    }
    ScoreboardManager:_init()
    Utils:_init()
    local inGame = false
    events.net_update_end:set(function(_)
        -- upvalues: inGame (ref), UI_State (ref), PlayerDataManager (ref), ScoreboardManager (ref), EntityGetter (ref)
        local l_is_in_game_0 = globals.is_in_game
        if not inGame and (not UI_State.enabled or not l_is_in_game_0) then
            inGame = true
            PlayerDataManager._array = {}
            ScoreboardManager.methods.updatePlayer({}, true)
            return
        elseif not UI_State.enabled or not l_is_in_game_0 then
            return
        else
            inGame = false
            local players = entity.get_players(false, false)
            local playerData = EntityGetter.get(players[globals.tickcount % #players + 1])
            if playerData and playerData.index ~= nil then
                PlayerDataManager:set(playerData.index, playerData.weapons)
                PlayerDataManager:active(playerData.index, playerData.active)
            end
            local playerArray = {}
            local arrIdx = 1
            for p = 0, 64 do
                local pData = PlayerDataManager:get(p)
                playerArray[arrIdx] = {
                    index = p,
                    weapons = pData.weapons,
                    active = pData.active,
                }
                arrIdx = arrIdx + 1
            end
            ScoreboardManager:updatePlayer(playerArray)
            return
        end
    end)
    for eventName, handler in pairs(EventHandlers) do
        events[eventName]:set(handler)
    end
    events.shutdown:set(function()
        -- upvalues: ScoreboardManager (ref)
        ScoreboardManager.methods.updatePlayer({}, true)
    end)
end