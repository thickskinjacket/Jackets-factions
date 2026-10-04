function GM:PlayerDeathThink(ply)
    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE then
        if ply.NextRespawnTime and CurTime() >= ply.NextRespawnTime then
            ply:Spawn()
            ply.NextRespawnTime = nil

            local plyTeam = ply:Team()
            SetGlobalInt("jf_teamlives_" .. plyTeam, GAMEMODE.TeamLives[plyTeam])

            return true
        end

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
            ply.NextRespawnTime = CurTime() + GetConVar("jf_respawn_time"):GetInt()
        else
            ply.NextRespawnTime = nil
        end

        StartWinCheck()
    end
end