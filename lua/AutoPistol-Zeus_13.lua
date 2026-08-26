-- ============================================================
-- CS:GO / Neverlose - Ultra Fast Auto Pistol
-- Author: Lemon.cc
-- ============================================================

-- 创建 UI 控件 (在脚本面板中生成控制开关)
local ui_group = ui.create("Auto Pistol", "Settings")

-- 在 UI 面板顶部添加作者署名
ui_group:label("=====================")
ui_group:label("  Author: Lemon.cc   ")
ui_group:label("=====================")

local ui_enable = ui_group:switch("Enable Auto Pistol", true)
local ui_detect_knife = ui_group:switch("Detect Knife", true)
local ui_detect_zeus = ui_group:switch("Detect Zeus", true)
local ui_distance = ui_group:slider("Trigger Distance", 100, 1000, 500)

local TRIGGER_COOLDOWN = 0.15

-- 危险武器 ID 映射表
local DANGEROUS_WEAPONS = {
    -- Zeus
    [31] = true,

    -- Knives
    [42] = true,  -- CT Knife
    [59] = true,  -- T Knife
    [500] = true, -- Bayonet
    [505] = true, -- Flip
    [506] = true, -- Gut
    [507] = true, -- Karambit
    [508] = true, -- M9 Bayonet
    [509] = true, -- Huntsman
    [512] = true, -- Falchion
    [514] = true, -- Bowie
    [515] = true, -- Butterfly
    [516] = true, -- Shadow Daggers
    [519] = true, -- Ursus
    [520] = true, -- Navaja
    [522] = true, -- Stiletto
    [523] = true  -- Talon
}

local last_trigger_time = 0

-- 距离计算
local function is_in_range_sq(a, b, max_dist)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return (dx * dx + dy * dy + dz * dz) <= (max_dist * max_dist)
end

-- 切手枪逻辑
local function switch_to_pistol(enemy_name, weapon_id)
    local current_time = globals.realtime or 0

    if current_time - last_trigger_time < TRIGGER_COOLDOWN then
        return
    end

    last_trigger_time = current_time

    -- 执行切手枪
    utils.console_exec("slot2")
    
    print(string.format("[Lemon.cc] DANGER DETECTED! Target: %s | Weapon ID: %d -> Executing slot2", enemy_name or "Enemy", weapon_id))
end

-- 主检测逻辑
local function check_all_enemies()
    -- 读取 UI 开关状态，如果未启用则直接跳过
    if not ui_enable:get() then
        return
    end

    local me = entity.get_local_player()
    if me == nil or not me:is_alive() then
        return
    end

    local my_pos = me:get_origin()
    if my_pos == nil then
        return
    end

    local players = entity.get_players(true)
    if players == nil then
        return
    end

    local current_dist = ui_distance:get()
    local detect_knife = ui_detect_knife:get()
    local detect_zeus = ui_detect_zeus:get()

    -- 极速全员扫描
    for i = 1, #players do
        local enemy = players[i]
        if enemy ~= nil and enemy:is_alive() then
            local enemy_pos = enemy:get_origin()
            
            if enemy_pos ~= nil and is_in_range_sq(my_pos, enemy_pos, current_dist) then
                local weapon = enemy:get_player_weapon()
                if weapon ~= nil then
                    local weapon_id = weapon:get_weapon_index()
                    
                    if weapon_id ~= nil and DANGEROUS_WEAPONS[weapon_id] then
                        local is_zeus_item = (weapon_id == 31)
                        if (is_zeus_item and detect_zeus) or (not is_zeus_item and detect_knife) then
                            switch_to_pistol(enemy:get_name(), weapon_id)
                            return
                        end
                    end
                end
            end
        end
    end
end

-- 注册事件
events.createmove:set(check_all_enemies)

print("---------------------------------------")
print("[AUTO PISTOL] UI Menu Integrated Successfully")
print("[AUTO PISTOL] Author: Lemon.cc")
print("---------------------------------------")