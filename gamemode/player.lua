local function CycleDeadSpectatorTarget(ply, direction)
    local spectatorTeam = ply.JFDeadSpectatorTeam
    if not spectatorTeam then return end

    local teammates = {}
    for _, target in player.Iterator() do
        if target ~= ply and target:Alive() and target:Team() == spectatorTeam then
            teammates[#teammates + 1] = target
        end
    end

    if #teammates == 0 then return end

    local currentTarget = ply:GetObserverTarget()
    local currentIndex
    for index, target in ipairs(teammates) do
        if target == currentTarget then
            currentIndex = index
            break
        end
    end

    local nextIndex = currentIndex and currentIndex + direction or (direction > 0 and 1 or #teammates)
    if nextIndex > #teammates then
        nextIndex = 1
    elseif nextIndex < 1 then
        nextIndex = #teammates
    end

    ply:Spectate(OBS_MODE_CHASE)
    ply:SpectateEntity(teammates[nextIndex])
end

function GM:PlayerDeathThink(ply)
    if ply.JFDeadSpectatorTeam then
        if ply:KeyPressed(IN_ATTACK) then
            CycleDeadSpectatorTarget(ply, 1)
        elseif ply:KeyPressed(IN_ATTACK2) then
            CycleDeadSpectatorTarget(ply, -1)
        end
    end

    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE then
        return false
    end

    if roundState == ROUND_OVER then
        return false
    end
end

function GM:PlayerDeath(ply, attacker, dmginfo)
    if ply.JFSpectator then return end

    local roundState = GetRoundState()
    local plyTeam = ply:Team()
    ply.JFRespawnAvailableAt = CurTime() + 4

    if roundState == ROUND_ACTIVE then
        if GAMEMODE.TeamLives[plyTeam] > 0 then
            GAMEMODE.TeamLives[plyTeam] = GAMEMODE.TeamLives[plyTeam] - 1
            ply.NextRespawnWave = true
        else
            ply.NextRespawnWave = nil
        end

        StartWinCheck()
    end

    local timerName = "JF_dead_spectator_" .. ply:UserID()
    timer.Remove(timerName)
    timer.Create(timerName, 4, 1, function()
        if not IsValid(ply) or ply:Alive() or ply.JFSpectator then return end

        ply.JFDeadSpectatorTeam = plyTeam
        ply:SetNWInt("jf_dead_spectator_team", plyTeam)
        ply:SetTeam(TEAM_SPECTATOR)
        ply:SetNoDraw(true)
        ply:SetMoveType(MOVETYPE_OBSERVER)

        local teammate
        for _, target in player.Iterator() do
            if target ~= ply and target:Alive() and target:Team() == plyTeam then
                teammate = target
                break
            end
        end

        if IsValid(teammate) then
            ply:Spectate(OBS_MODE_CHASE)
            ply:SpectateEntity(teammate)
        else
            ply:Spectate(OBS_MODE_ROAMING)
        end
    end)
end

hook.Add("PlayerCanSeePlayers", "JF_dead_spectator_team", function(viewer, target)
    local spectatorTeam = viewer.JFDeadSpectatorTeam
    if not spectatorTeam or viewer == target then return end

    return target:Team() == spectatorTeam
end)