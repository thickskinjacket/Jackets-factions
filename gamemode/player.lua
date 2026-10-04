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
        local firefliesAlive = false
        local huntersAlive = false

        for _, p in player.Iterator() do
            if IsValid(p) and p:Alive() then
                if p:Team() == TEAM_FIREFLIES then
                    firefliesAlive = true
                elseif p:Team() == TEAM_HUNTERS then
                    huntersAlive = true
                end
            end
        end

        if not firefliesAlive or not huntersAlive then
            EndRound()
        end
    end
end