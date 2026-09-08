--[[
    RIFKY CHEAT REVEALER
    Detects other players via voice_listener library and renders cheat icons.
    Allows self-flagging to LARP as any cheat with custom anti-flicker rendering logic.
]]

local ok, voice_listener = pcall(require, "neverlose/voice_listener")
if not ok then
    error("voice_listener module not available: " .. tostring(voice_listener))
end

--[[
    ICON MAP
    Maps predefined cheat identities to their localized texture paths.
]]

-- stylua: ignore
local CHEATS = {
    -- { combo label, multicolored/unicolored filename, nadoryha filename }
    { "Neverlose (NL2)", "nl2", "nl" },
    { "Neverlose (NL1)", "nl1", "nl" },
    { "Gamesense (GS)", "gs", "gs" },
    { "Onetap (OT)", "ot", "ot" },
    { "Fatality (FT)", "ft", "ft" },
    { "Ev0lve (EV)", "ev", "ev" },
    { "Nixware (NW)", "nw", "nw" },
    { "Pandora (PD)", "pd", "pd" },
    { "Plaguecheat (PL)", "pl", "pl" },
    { "Rifk7 (R7)", "r7", "r7" },
    { "Airflow (AF)", "af", "af" },
    { "Unknown (WH)", "wh", "wh" },
}
local STYLES = { "multicolored", "unicolored", "nadoryha" }

local function get_self_icon(cheat_idx, style_idx)
    local cheat = CHEATS[1]
    if type(cheat_idx) == "number" and CHEATS[cheat_idx] then
        cheat = CHEATS[cheat_idx]
    elseif type(cheat_idx) == "string" then
        for _, c in ipairs(CHEATS) do
            if c[1] == cheat_idx then
                cheat = c
                break
            end
        end
    end

    local style_str = "multicolored"
    if type(style_idx) == "number" and STYLES[style_idx] then
        style_str = STYLES[style_idx]
    elseif type(style_idx) == "string" then
        style_str = style_idx:lower()
    end

    local filename = (style_str == "nadoryha") and cheat[3] or cheat[2]
    return ("file://{images}/icons/revealer/%s/%s.png"):format(style_str, filename)
end

--[[
    STATE
    Holds cached icon states to prevent redundant render updates.
]]

local detected_players = {}
local enabled = false
local ui_ref = {}
local active_self_icon = nil
local pending_self_icon = nil

--[[
    HELPERS
    Utility functions for determining detection scope and resolving texture paths.
]]

local function should_detect(player, scope)
    if player == nil then
        return false
    end
    -- scope can be string or index
    if scope == 2 or scope == "Enemies" then
        return player:is_enemy()
    elseif scope == 3 or scope == "Teammates" then
        return not player:is_enemy()
    end
    return true
end

local function clear_detected()
    entity.get_players(false, true, function(player)
        local xuid = player:get_xuid()
        if detected_players[xuid] then
            player:set_icon()
            detected_players[xuid] = nil
        end
    end)
end

local function get_styled_other_icon(vl_icon_url, style_idx)
    if not vl_icon_url then
        return nil
    end

    -- Option 1 is "Default (Voice Listener)"
    if style_idx == 1 or style_idx == "Default (Voice Listener)" then
        return vl_icon_url
    end

    -- Map style_idx to the style string (2=Multicolored, 3=Unicolored, 4=Nadoryha)
    local style_str = "multicolored"
    if style_idx == 2 or style_idx == "Multicolored" then
        style_str = "multicolored"
    elseif style_idx == 3 or style_idx == "Unicolored" then
        style_str = "unicolored"
    elseif style_idx == 4 or style_idx == "Nadoryha" then
        style_str = "nadoryha"
    end

    local base = vl_icon_url:match("([^/]+)%.png$")
    if not base then
        return vl_icon_url
    end

    local map = {
        nl = "Neverlose (NL2)",
        neverlose = "Neverlose (NL2)",
        gs = "Gamesense (GS)",
        gamesense = "Gamesense (GS)",
        ot = "Onetap (OT)",
        onetap = "Onetap (OT)",
        ft = "Fatality (FT)",
        fatality = "Fatality (FT)",
        ev = "Ev0lve (EV)",
        evolve = "Ev0lve (EV)",
        nw = "Nixware (NW)",
        nixware = "Nixware (NW)",
        pd = "Pandora (PD)",
        pandora = "Pandora (PD)",
        pl = "Plaguecheat (PL)",
        plaguecheat = "Plaguecheat (PL)",
        r7 = "Rifk7 (R7)",
        rifk7 = "Rifk7 (R7)",
        af = "Airflow (AF)",
        airflow = "Airflow (AF)",
    }

    local mapped = map[base:lower()]
    if mapped then
        return get_self_icon(mapped, style_str)
    end
    return vl_icon_url
end

--[[
    SELF-ICON RENDER
    Hooks into events.render to continuously assert the local player's cheat icon.
    Executes after createmove to prevent other Lua scripts from overriding the icon.
]]

local function on_render()
    local me = entity.get_local_player()
    if not me then
        -- Clear state on map change or disconnect so CS:GO is forced to redraw the icons
        active_self_icon = nil
        pending_self_icon = nil
        for k in pairs(detected_players) do
            detected_players[k] = nil
        end
        return
    end

    if not ui_ref.show_self:get() then
        me:set_icon()
        active_self_icon = nil
        pending_self_icon = nil
        return
    end

    local want = get_self_icon(ui_ref.my_icon:get(), ui_ref.icon_style:get())

    if want == active_self_icon then
        -- Same icon: keep asserting every frame (beats CHEATSPOOFER clears)
        me:set_icon(want)
    elseif pending_self_icon == want then
        -- Phase 2: slot was cleared last frame, now load the new texture
        me:set_icon(want)
        active_self_icon = want
        pending_self_icon = nil
    else
        -- Phase 1: icon changed -- clear slot this frame, set on next frame
        me:set_icon()
        active_self_icon = nil
        pending_self_icon = want
    end
end

--[[
    OTHER PLAYERS UPDATE
    Scans networked entities during net_update_end and applies the corresponding cheat icon.
]]

local function on_net_update()
    local scope = ui_ref.scope:get()
    local me = entity.get_local_player()
    local current = {}

    entity.get_players(false, true, function(player)
        if player == me then
            return
        end

        local xuid = player:get_xuid()
        current[xuid] = player

        if should_detect(player, scope) then
            local software = voice_listener.get_software(player)
            local icon_url = nil

            local other_style = ui_ref.other_icon_style:get()

            local fallback_style_str = "nadoryha"
            if other_style == 2 or other_style == "Multicolored" then
                fallback_style_str = "multicolored"
            elseif other_style == 3 or other_style == "Unicolored" then
                fallback_style_str = "unicolored"
            elseif other_style == 4 or other_style == "Nadoryha" then
                fallback_style_str = "nadoryha"
            end

            if software then
                -- Player is detected, get base icon and restyle it
                local vl_icon = voice_listener.get_icon(software.signature)
                icon_url = get_styled_other_icon(vl_icon, other_style)
                    or get_self_icon("Unknown (WH)", fallback_style_str)
            else
                -- Not detected, use fallback wh.png in the selected style
                icon_url = get_self_icon("Unknown (WH)", fallback_style_str)
            end

            local prev = detected_players[xuid]
            if not prev or prev ~= icon_url then
                detected_players[xuid] = icon_url
                player:set_icon(icon_url)
            end
        else
            -- Outside scope -> clear
            if detected_players[xuid] then
                detected_players[xuid] = nil
                player:set_icon()
            end
        end
    end)

    for xuid in pairs(detected_players) do
        if not current[xuid] then
            detected_players[xuid] = nil
        end
    end
end

--[[
    TOGGLE STATE
    Handles event subscriptions and state cleanup when enabling or disabling the feature.
]]

local function set_enabled(state)
    if state == enabled then
        return
    end
    if state then
        events.render:set(on_render)
        events.net_update_end:set(on_net_update)
    else
        events.render:unset(on_render)
        events.net_update_end:unset(on_net_update)
        active_self_icon = nil
        pending_self_icon = nil
        local me = entity.get_local_player()
        if me then
            me:set_icon()
        end
        clear_detected()
    end
    enabled = state
end

--[[
    SHUTDOWN
    Clears all rendered icons and unhooks events when the script is unloaded.
]]

events.shutdown:set(function()
    if enabled then
        events.render:unset(on_render)
        events.net_update_end:unset(on_net_update)
        active_self_icon = nil
        pending_self_icon = nil
        local me = entity.get_local_player()
        if me then
            me:set_icon()
        end
        clear_detected()
        enabled = false
    end
end)

--[[
    UI
    Initializes the sidebar tab, groups, and interactive menu elements.
]]

local tab = ui.sidebar()
if tab ~= "Cheat Revealer" then
    ui.sidebar("Cheat Revealer")
end

local group = ui.create("Cheat Revealer", "Main")

local ui_enabled = group:switch("Enabled", false)
ui_ref.scope = group:combo("Detect", { "Both", "Enemies", "Teammates" })
ui_ref.show_self = group:switch("Show my flag", true)

local cheat_names = {}
for i, c in ipairs(CHEATS) do
    cheat_names[i] = c[1]
end
ui_ref.my_icon = group:combo("My Identity", cheat_names)
ui_ref.icon_style = group:combo("My Icon Style", { "Multicolored", "Unicolored", "Nadoryha" })
ui_ref.other_icon_style =
    group:combo("Others Icon Style", { "Default (Voice Listener)", "Multicolored", "Unicolored", "Nadoryha" })

ui_enabled:set_callback(function()
    set_enabled(ui_enabled:get())
end, true)