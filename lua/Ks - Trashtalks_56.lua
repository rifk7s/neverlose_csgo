-- Custom Killsay Phrases
local phrases = {
    "1",
    "MOTHER ALIVE?",
    "WHERE SHOOTING DOG",
    "DONT TALKING DOG KING IS HERE",
    "dont NN",
    "what do you think? you are a legendary? you thinking wrong",
    "BOSS MODE ONLINE",
    "THINK YOU CAN DEFEAT KING ? YOUR TIME IS NOW",
    "IS MY LUA BAD? U JUST HAVENT MONEY",
    "WANT YAW IDEAL? LINK IN DESCRIPT",
    "want godmode ? write me in telegram",
    "BARAD CALLED ME , WANT ACCESS TO SAPPHIRE ?",

    "WHY PEEK LIKE NOOB ? EXPLAIN ME",
    "YOU SHOOT WALL OR ME ? NOT CLEAR",
    "WHATS THAT MOVE BRO EXPLAIN ME",
    "YOU RUNNING WHERE ? I AM EVERYWHERE",
    "WANT SAPPHIRE? WRITE FUADZ SEND SAPPHIRE",
}

-- UI Elements: Killsay
local group = ui.create("Miscellaneous", "Main", "Other")
local killsay_enabled = group:switch("Killsay")
local killsay_mode = group:combo("Killsay chat mode", { "All chat", "Team chat" })
group:button("Test Killsay", function()
    local random_phrase = phrases[math.random(1, #phrases)]
    local chat_cmd = killsay_mode:get() == 1 and "say_team" or "say"
    utils.console_exec(string.format('%s "%s"', chat_cmd, random_phrase))
end)

-- Killsay Event Callback
events.player_death(function(e)
    if not killsay_enabled:get() then
        return
    end

    local local_player = entity.get_local_player()
    if not local_player then
        return
    end

    local attacker = entity.get(e.attacker, true)
    local victim = entity.get(e.userid, true)

    if attacker == local_player and victim and victim ~= local_player and victim:is_enemy() then
        local random_phrase = phrases[math.random(1, #phrases)]
        local chat_cmd = killsay_mode:get() == 1 and "say_team" or "say"
        utils.console_exec(string.format('%s "%s"', chat_cmd, random_phrase))
    end
end)
