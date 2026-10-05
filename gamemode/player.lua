function GM:PlayerDeathThink(ply)
    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE then
        return false
    end

    if roundState == ROUND_OVER then
        return false
    end
end

function GM:PlayerDeath(ply, attacker, dmginfo)
    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE then
        local plyTeam = ply:Team()

        if GAMEMODE.TeamLives[plyTeam] > 0 then
            GAMEMODE.TeamLives[plyTeam] = GAMEMODE.TeamLives[plyTeam] - 1
            ply.NextRespawnWave = true
        else
            ply.NextRespawnWave = nil
        end

        StartWinCheck()
    end
end