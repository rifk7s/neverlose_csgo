local menu = ui.create("Super Toss")
local enabled = menu:switch("Enabled", false)

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function calculate_throw_angle(target_angles, throw_velocity, throw_strength, player_velocity)
    target_angles.x = target_angles.x - 10 + math.abs(target_angles.x) / 9

    local forward_vector = vector():angles(target_angles)
    local adjusted_velocity = player_velocity * 1.25
    local velocity = math.clamp(throw_velocity * 0.9, 15, 750)
    local normalized_throw_strength = math.clamp(throw_strength, 0, 1)

    velocity = velocity * lerp(0.3, 1, normalized_throw_strength)

    local new_forward = forward_vector
    for _ = 1, 8 do
        new_forward = (
            forward_vector * (new_forward * velocity + adjusted_velocity):length()
            - adjusted_velocity
        ) / velocity
        new_forward:normalize()
    end

    local new_angles = new_forward:angles()
    if new_angles.x > -10 then
        new_angles.x = 0.9 * new_angles.x + 9
    else
        new_angles.x = 1.125 * new_angles.x + 11.25
    end

    return new_angles
end

local function super_toss_angles(cmd)
    local local_player = entity.get_local_player()
    if not local_player or not local_player:is_alive() then
        return
    end

    local weapon = local_player:get_player_weapon()
    if not weapon then
        return
    end

    local weapon_data = weapon:get_weapon_info()
    if not weapon_data then
        return
    end

    cmd.angles = calculate_throw_angle(
        cmd.angles,
        weapon_data.throw_velocity,
        weapon.m_flThrowStrength,
        cmd.velocity
    )
end

local function super_toss(cmd)
    local local_player = entity.get_local_player()
    if not local_player or not local_player:is_alive() then
        return
    end

    if not cmd.jitter_move then
        return
    end

    local weapon = local_player:get_player_weapon()
    if not weapon then
        return
    end

    local weapon_data = weapon:get_weapon_info()
    if not weapon_data or weapon_data.weapon_type ~= 9 then
        return
    end

    if weapon.m_fThrowTime < (globals.curtime - to_time(globals.clock_offset)) then
        return
    end

    cmd.in_speed = true

    local movement_simulation = local_player:simulate_movement()
    movement_simulation:think()

    cmd.view_angles = calculate_throw_angle(
        cmd.view_angles,
        weapon_data.throw_velocity,
        weapon.m_flThrowStrength,
        movement_simulation.velocity
    )
end

events.createmove:set(function(cmd)
    if enabled:get() then
        super_toss(cmd)
    end
end)

events.grenade_override_view:set(function(cmd)
    if enabled:get() then
        super_toss_angles(cmd)
    end
end)