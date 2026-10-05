util.AddNetworkString("JF_MarkEnemy")

local MARK_DURATION = 5

local function RevealPositionOnBulletFire(ent, data)
    if not IsValid(ent) or not ent:IsPlayer() or not ent:Alive() then return end

    net.Start("JF_SendRadarPosition")
        net.WriteEntity(ent)
        net.WriteVector(ent:GetPos())
    net.Broadcast()
end
hook.Add("PostEntityFireBullets", "JF_enemy_fire_reveal", RevealPositionOnBulletFire)

local function RevealPositionOnRunning(ply, movedata)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if not movedata:KeyDown(IN_SPEED) or ply:GetVelocity():Length2D() < 100 then return end

    local now = CurTime()
    if ply.jfNextRunningRadarPing and ply.jfNextRunningRadarPing > now then return end

    ply.jfNextRunningRadarPing = now + .3

    net.Start("JF_SendRadarPosition")
        net.WriteEntity(ply)
        net.WriteVector(ply:GetPos())
    net.Broadcast()
end
hook.Add("PlayerTick", "JF_enemy_running_ping", RevealPositionOnRunning)

hook.Add("PlayerTick", "JF_mark_enemy", function(ply, movedata)
    if not IsValid(ply) or not ply:Alive() then return end

    local pressingUse = movedata:KeyDown(IN_USE)
    if not pressingUse or ply.JFMarkUseDown then
        ply.JFMarkUseDown = pressingUse
        return
    end

    ply.JFMarkUseDown = true

    local target = ply:GetEyeTrace().Entity
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return end
    if target:Team() == ply:Team() then return end

    local now = CurTime()
    if target.JFMarkedUntil and target.JFMarkedUntil > now then return end

    target.JFMarkedUntil = now + MARK_DURATION

    net.Start("JF_MarkEnemy")
        net.WriteEntity(target)
        net.WriteVector(target:GetPos())
    local recipients = team.GetPlayers(ply:Team())
    for _, spectator in ipairs(team.GetPlayers(TEAM_SPECTATOR)) do
        table.insert(recipients, spectator)
    end
    net.Send(recipients)

    ply:AddParts(PART_REWARDS.MARK)
end)