events.player_death:set(function(e)
    local me = entity.get_local_player()
    if not me then
        return
    end

    local attacker = entity.get(e.attacker, true)
    if attacker ~= me then
        return
    end

    if e.headshot then
        utils.console_exec('say #cumshotted')
    end
end)