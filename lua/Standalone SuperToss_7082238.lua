local menu = ui.create("Super Toss")
local enabled = menu:switch("Enabled", false)

local clamp, abs = math.clamp, math.abs

local function interp(a, b, t)
    return a + (b - a) * t
end

local function apply_pitch(x)
    return x > -10 and x * 0.9 + 9 or x * 1.125 + 11.25
end

local function compute(a, v, s, vel)
    a.x = a.x - 10 + abs(a.x) / 9
    local fwd = vector():angles(a)
    local pvel = vel * 1.25
    local tv = clamp(v * 0.9, 15, 750) * interp(0.3, 1.0, clamp(s, 0, 1))
    local dir = fwd
    for _ = 1, 8 do
        dir = (fwd * (dir * tv + pvel):length() - pvel) / tv
        dir:normalize()
    end
    local ang = dir:angles()
    ang.x = apply_pitch(ang.x)
    return ang
end

local function override_view(e)
    local globals = globals
    local entity = entity

    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end

    local w = lp:get_player_weapon()
    if not w then return end

    local wi = w:get_weapon_info()
    if not wi then return end

    e.angles = compute(e.angles, wi.throw_velocity, w.m_flThrowStrength, e.velocity)
end

local function toss_control(cmd)
    local globals = globals
    local entity = entity

    if not cmd.jitter_move then return end

    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end

    local w = lp:get_player_weapon()
    if not w then return end

    local wi = w:get_weapon_info()
    if not wi or wi.weapon_type ~= 9 then return end

    local curtime = globals.curtime
    local to_time_func = to_time or (common and common.to_time) or function(t) return t * globals.tickinterval end
    local clock_offset = globals.clock_offset or 0

    if w.m_fThrowTime < (curtime - to_time_func(clock_offset)) then
        return
    end

    cmd.in_speed = true

    local ctx = lp:simulate_movement()
    ctx:think()

    cmd.view_angles = compute(cmd.view_angles, wi.throw_velocity, w.m_flThrowStrength, ctx.velocity)
end

events.createmove:set(function(cmd)
    if enabled:get() then
        toss_control(cmd)
    end
end)

events.grenade_override_view:set(function(e)
    if enabled:get() then
        override_view(e)
    end
end)
