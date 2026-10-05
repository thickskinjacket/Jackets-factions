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