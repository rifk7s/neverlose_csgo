local pui = require("neverlose/pui")
local menu = {
    Hit = {},
}

-- 武器定义索引 → 菜单名称映射
local weapon_to_menu = {
    -- Pistols
    [61] = "Pistols",  -- USP-S
    [4]  = "Pistols",  -- Glock-18
    [3]  = "Pistols",  -- Five-SeveN
    [30] = "Pistols",  -- Tec-9
    [2]  = "Pistols",  -- Dual Berettas
    [32] = "Pistols",  -- P2000
    [36] = "Pistols",  -- P250
    [63] = "Pistols",  -- CZ75-Auto
    -- Deagle
    [1]  = "Desert Eagle",
    -- R8
    [64] = "R8 Revolver",
    -- SSG-08
    [40] = "SSG-08",
    -- AWP
    [9]  = "AWP",
    -- AK-47
    [7]  = "AK-47",
    -- M4A4 / M4A1-S
    [16] = "M4A1/M4A4",
    [60] = "M4A1/M4A4",
    -- AUG / SG 553
    [39] = "AUG/SG 553",
    [8]  = "AUG/SG 553",
    -- AutoSnipers
    [11] = "AutoSnipers",
    [38] = "AutoSnipers",
    -- Shotguns
    [25] = "Shotguns",
    [27] = "Shotguns",
    [29] = "Shotguns",
    [35] = "Shotguns",
    -- SMGs
    [17] = "SMGs",
    [19] = "SMGs",
    [23] = "SMGs",
    [24] = "SMGs",
    [26] = "SMGs",
    [33] = "SMGs",
    -- Rifles (Famas, Galil 等杂项步枪)
    [10] = "Rifles",
    [13] = "Rifles",
    -- Snipers (Scout 等杂项狙击)
    [34] = "Snipers",
    -- Machineguns
    [14] = "Machineguns",
    [28] = "Machineguns",
    -- Taser
    [31] = "Taser",
}

-- 获取当前手上武器
local function get_active_weapon()
    local local_player = entity.get_local_player()
    if local_player == nil then
        return nil
    end
    return local_player:get_player_weapon()
end

-- 获取当前武器在菜单中的名称，未匹配返回 "Global"
local function get_weapon_menu_name()
    local wep = get_active_weapon()
    if wep == nil then
        return "Global"
    end
    return weapon_to_menu[wep:get_weapon_index()] or "Global"
end

-- 获取当前武器对应的 "Min. Damage" 配置值 (Pistols 取 "Hit Chance")
local function get_config_for_current_weapon()
    local menu_name = get_weapon_menu_name()
    local ok, hit = pcall(ui.find, "Aimbot", "Ragebot", "Selection", menu_name, "Min. Damage")
    if not ok or hit == nil then
        return nil
    end
    return hit:get()
end

-- 平滑插值：a 平滑过渡到 b，s 控制速度（越大越快）
local function lerp(a, b, s)
    local frame_time = globals.frametime
    if frame_time == 0 then return a end
    local c = a + (b - a) * frame_time * (s or 8)
    return math.abs(b - c) < 0.005 and b or c
end

-- 显隐过渡：should_be_active 为 true 时从 0 渐变到 1，false 时从 1 渐变到 0
local function condition(current_val, should_be_active, speed)
    local frame_time = globals.frametime
    if frame_time == 0 then return current_val end
    local new_val = current_val + (frame_time * math.abs(speed) * (should_be_active and 1 or -1))
    return math.max(0, math.min(1, new_val))
end

menu.main_l = pui.create("main", "\n", 1)
menu.main_r = pui.create("main", "\n\n", 2)
menu.list = menu.main_l:list("", "伤害指示器")

menu.Hit = {
    enabled = menu.main_r:switch("伤害指示器", false),
    combobox = menu.main_r:combo("字体", { "默认", "小字", "控制台", "加粗" }),
}

local function visibility_callback()
    local enabled = menu.Hit.enabled:get()
    menu.Hit.combobox:set_visible(enabled)
end
visibility_callback()
menu.Hit.enabled:set_callback(visibility_callback)

-- 动画状态
local anim = {dmg = 0, progress = 0}

local function DrawHitNumber()
    if not menu.Hit.enabled:get() then return end
    -- 更新动画状态
    local target_dmg = get_config_for_current_weapon() or 0
    local is_visible = menu.Hit.enabled:get()
    anim.progress = condition(anim.progress, is_visible, 8)
    anim.dmg = lerp(anim.dmg, target_dmg, 16)

    if anim.progress <= 0.005 then return end

    -- 计算文字（和原版逻辑一致：0→"A", >100→"+xx"）
    local dmg_val = math.floor(anim.dmg + 0.5)
    local dmg_text = dmg_val == 0 and "A" or dmg_val > 100 and ("+" .. (dmg_val - 100)) or tostring(dmg_val)

    local x, y = render.screen_size().x / 2, render.screen_size().y / 2
    local font_type = menu.Hit.combobox:get()
    local font = 0
    local offset_x, offset_y = 3, 0

    if font_type == "默认" then
        font = 0
    elseif font_type == "小字" then
        font = 2
        offset_x, offset_y = 1, 1
    elseif font_type == "控制台" then
        font = 1
    elseif font_type == "加粗" then
        font = 3
        offset_x = 0
    end

    local size = render.measure_text(font, nil, dmg_text)
    local pos = vector(x + offset_x, y - size.y + offset_y)

    -- alpha 随 progress 变化，带 ovr_alpha 风格（可后续接 override 检测）
    local final_alpha = math.floor((96 + 159 * 1) * anim.progress)
    render.text(font, pos, color(255, 255, 255, final_alpha), nil, dmg_text)
end

events.render:set(DrawHitNumber)
