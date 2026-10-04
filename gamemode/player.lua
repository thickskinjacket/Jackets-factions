function GM:PlayerSpawn(ply)
    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE or roundState == ROUND_OVER then
        return
    end

    self.BaseClass.PlayerSpawn(self, ply)
end

function GM:PlayerDeathThink(ply)
    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE or roundState == ROUND_OVER then
        return false
    end
end

function GM:PlayerDeath(ply, attacker, dmginfo)
    local roundState = GetRoundState()

    if roundState == ROUND_ACTIVE then
        local aliveCount = 0

        for _, p in player.Iterator() do
            if IsValid(p) and p:Alive() then
                aliveCount = aliveCount + 1
            end
        end

        if aliveCount <= 1 then
            EndRound()
        end
    end
end