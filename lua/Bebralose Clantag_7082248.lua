-- Bebralose Synced Clantag (Gamesense Animation Style)

local clantag_anim = {
    "bebralose         ",
    "ebralose          ",
    "bralose           ",
    "ralose            ",
    "alose             ",
    "lose              ",
    "ose               ",
    "se                ",
    "e                 ",
    "                  ",
    "                 b",
    "                be",
    "               beb",
    "              bebr",
    "             bebra",
    "            bebral",
    "           bebralo",
    "          bebralos",
    "         bebralose",
    "        bebralose ",
    "       bebralose  ",
    "      bebralose   ",
    "     bebralose    ",
    "    bebralose     ",
    "   bebralose      ",
    "  bebralose       ",
    " bebralose        "
}

local old_frame = -1

events.render:set(function()
    local curtime = globals.curtime
    if type(curtime) == "function" then curtime = curtime() end
    
    -- Sync math: math.floor(curtime * multiplier) ensures all players loading this 
    -- script will have the exact same frame at the exact same time.
    -- 3.3 is the classic faster gamesense speed.
    local current_frame = math.floor(curtime * 3.3) % #clantag_anim + 1
    
    if current_frame ~= old_frame then
        common.set_clan_tag(clantag_anim[current_frame])
        old_frame = current_frame
    end
end)