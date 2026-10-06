local function GetSpectatePlayer(entity)
    if IsValid(entity) and entity:IsPlayer() then
        return entity
    end

    if IsValid(entity) then
        local owner = entity:GetNWEntity("owner")
        if IsValid(owner) and owner:IsPlayer() then
            return owner
        end
    end
end

local function GetSpectateEntity(ply)
    local ragdoll = ply:GetNWEntity("downed_ragdoll")
    if ply:GetNWBool("downed") and IsValid(ragdoll) then
        return ragdoll
    end

    return ply
end

local function GetSpectateTarget(ply, currentTarget, indexOffset)
    local players = player.GetAll()
    local startIndex = 0
    indexOffset = indexOffset or 1
    currentTarget = GetSpectatePlayer(currentTarget)

    for index, target in ipairs(players) do
        if target == currentTarget then
            startIndex = index
            break
        end
    end

    for offset = 1, #players do
        local targetIndex = (startIndex + (offset * indexOffset) - 1) % #players + 1
        local target = players[targetIndex]

        if target ~= ply and target:Team() == ply:Team()
            and (target:Alive() or target:GetNWBool("downed")) then
            return target
        end
    end
end

function GM:PlayerDeathThink(ply)
    if ply:Team() ~= TEAM_SPECTATOR and ply:GetObserverMode() ~= OBS_MODE_NONE then
        local target = ply:GetObserverTarget()
        local targetPlayer = GetSpectatePlayer(target)

        if not IsValid(targetPlayer) or targetPlayer:Team() ~= ply:Team()
            or (not targetPlayer:Alive() and not targetPlayer:GetNWBool("downed")) then
            target = GetSpectateTarget(ply, target)

            if target then
                ply:SpectateEntity(GetSpectateEntity(target))
            else
                ply:SetObserverMode(OBS_MODE_FIXED)
            end
        elseif ply:KeyPressed(IN_ATTACK) or ply:KeyPressed(IN_ATTACK2) then
            local indexOffset = ply:KeyPressed(IN_ATTACK2) and -1 or 1
            local nextTarget = GetSpectateTarget(ply, target, indexOffset)

            if nextTarget then
                ply:SpectateEntity(GetSpectateEntity(nextTarget))
            end
        end
    end

    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE or roundState == ROUND_OVER then
        return false
    end
end

function GM:PlayerDeath(ply, attacker, dmginfo)
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

    timer.Simple(4, function()
        if not IsValid(ply) or ply:Alive() then return end

        self:Spectate(ply)

        local target = GetSpectateTarget(ply)
        if target then
            ply:SpectateEntity(GetSpectateEntity(target))
        else
            ply:SetObserverMode(OBS_MODE_FIXED)
        end
    end)
end