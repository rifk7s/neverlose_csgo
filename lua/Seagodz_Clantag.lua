local clantag_old_time = 0

local clantag_anim = {
    "5",
    "s",
    "s3",
    "se",
    "se/\\",
    "sea",
    "sea9",
    "seag",
    "seag0",
    "seago",
    "seago<|",
    "seagod",
    "seagod2",
    "seagodz",
    "seagodz",
    "seagodz",
    "seagodz",
    "seagodz",
    "seagodz",
    "seagod2",
    "seagod",
    "seago<|",
    "seago",
    "seag0",
    "seag",
    "sea9",
    "sea",
    "se/\\",
    "se",
    "s3",
    "s",
    "5",
    "",
}

local time = globals.curtime
events.render:set(function()
    time = globals.curtime
    local speed = math.floor((time * 2.33) * 2)
    if old_time ~= speed and (globals.tickcount % 2) == 1 then
        common.set_clan_tag(clantag_anim[speed % #clantag_anim + 1])
        old_time = speed
    end
end)
