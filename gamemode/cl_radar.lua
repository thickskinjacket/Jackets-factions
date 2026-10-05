local radarConfig = {
    margin = {
        x = 64,
        y = 64
    },
    radius = 128,
    range = 1000,
    blipRadius = 6
}

local radarCircleCache = {}
local radarBlipCache = {}
local radarCircleMaterial = Material("vgui/white")
local radarHealthIcon = Material("hud/small-health.png")

local function DrawRadarBlip(x, y, color, scale, isDowned)
    if isDowned then
        local iconSize = radarConfig.blipRadius * 2.5 * scale
        local pulse = (math.sin(CurTime() * 6) + 1) / 2
        local iconColor = Color(
            Lerp(pulse, 255, color.r),
            Lerp(pulse, 255, color.g),
            Lerp(pulse, 255, color.b),
            color.a or 255
        )
        surface.SetDrawColor(iconColor)
        surface.SetMaterial(radarHealthIcon)
        surface.DrawTexturedRect(x - (iconSize / 2), y - (iconSize / 2), iconSize, iconSize)
        return
    end

    surface.SetDrawColor(color)
    surface.SetMaterial(radarCircleMaterial)
    surface.DrawPoly(draw.JCircle(x, y, radarConfig.blipRadius * scale, radarBlipCache))
end

hook.Add("HUDPaint", "garrysfactions_radar", function()
    local scale = ScrH() / 1080

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    -- Draw radar background
    local radarRadius = radarConfig.radius * scale
    local radarX = radarConfig.margin.x * scale + radarRadius
    local radarY =  radarConfig.margin.y * scale + radarRadius
    local radarOrigin = ply:GetPos()
    local playerRagdoll = ply:GetNWEntity("downed_ragdoll")
    if ply:GetNWBool("downed") and IsValid(playerRagdoll) then
        radarOrigin = playerRagdoll:GetPos()
    end

    surface.SetDrawColor(0, 0, 0, 128)
    surface.SetMaterial(radarCircleMaterial)
    surface.DrawPoly(draw.JCircle(radarX, radarY, radarRadius, radarCircleCache))

    local playerColor = team.GetColor(ply:Team()) or color_white
    DrawRadarBlip(radarX, radarY, playerColor, scale, false)

    local yaw = math.rad(ply:EyeAngles().y)
    local sinYaw = math.sin(yaw)
    local cosYaw = math.cos(yaw)

    for _, teammate in ipairs(player.GetAll()) do
        if teammate == ply or not IsValid(teammate) or not teammate:Alive() or teammate:Team() ~= ply:Team() then
            continue
        end

        local teammatePosition = teammate:GetPos()
        local teammateRagdoll = teammate:GetNWEntity("downed_ragdoll")
        if teammate:GetNWBool("downed") and IsValid(teammateRagdoll) then
            teammatePosition = teammateRagdoll:GetPos()
        end

        local offset = teammatePosition - radarOrigin
        local localX = (offset.y * cosYaw) - (offset.x * sinYaw)
        local localY = -((offset.x * cosYaw) + (offset.y * sinYaw))
        local blipX = radarX - (localX / radarConfig.range) * radarRadius
        local blipY = radarY + (localY / radarConfig.range) * radarRadius

        local distance = math.sqrt((blipX - radarX) ^ 2 + (blipY - radarY) ^ 2)
        if distance > radarRadius - (radarConfig.blipRadius * scale) then
            local directionX = (blipX - radarX) / distance
            local directionY = (blipY - radarY) / distance
            blipX = radarX + directionX * (radarRadius - (radarConfig.blipRadius * scale))
            blipY = radarY + directionY * (radarRadius - (radarConfig.blipRadius * scale))
        end

        DrawRadarBlip(blipX, blipY, playerColor, scale, teammate:GetNWBool("downed"))
    end
end)
