local radarConfig = {
    margin = {
        x = 64,
        y = 64
    },
    radius = 128,
    range = 1000,
    blipRadius = 7
}

local radarCircleCache = {}
local radarBlipCache = {}
local radarCircleMaterial = Material("vgui/white")
local radarHealthIcon = Material("hud/small-health.png")
local radarPlayerIcon = Material("hud/up-arrow2.png")

local radarEnemyMarkers = {}
local radarEnemyTrackDuration = 2
local radarEnemyFadeDuration = 1.5
local radarPingDuration = 0.5

local function UpdateRadarMarker(shooter, position, timestamp)
    for _, marker in ipairs(radarEnemyMarkers) do
        if marker.shooter == shooter then
            marker.position = position
            marker.pingedAt = timestamp
            marker.firedAt = timestamp
            return
        end
    end

    table.insert(radarEnemyMarkers, {
        shooter = shooter,
        position = position,
        firedAt = timestamp,
        pingedAt = timestamp
    })
end

net.Receive("JF_SendRadarPosition", function()
    UpdateRadarMarker(net.ReadEntity(), net.ReadVector(), CurTime())
end)

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

local function DrawRadarPlayerBlip(x, y, scale)
    local iconWidth = radarConfig.blipRadius * 2.5 * scale
    local iconHeight = radarConfig.blipRadius * 3.5 * scale

    surface.SetDrawColor(Color(225, 255, 255))
    surface.SetMaterial(radarPlayerIcon)
    surface.DrawTexturedRect(x - (iconWidth / 2), y - (iconHeight / 2), iconWidth, iconHeight)
end

local function GetRadarPlayerPosition(playerEntity)
    local playerPosition = playerEntity:GetPos()
    local playerRagdoll = playerEntity:GetNWEntity("downed_ragdoll")
    if playerEntity:GetNWBool("downed") and IsValid(playerRagdoll) then
        return playerRagdoll:GetPos()
    end

    return playerPosition
end

local function GetRadarBlipPosition(position, radarOrigin, radarX, radarY, radarRadius, scale, sinYaw, cosYaw)
    local offset = position - radarOrigin
    local localX = (offset.y * cosYaw) - (offset.x * sinYaw)
    local localY = -((offset.x * cosYaw) + (offset.y * sinYaw))
    local blipX = radarX - (localX / radarConfig.range) * radarRadius
    local blipY = radarY + (localY / radarConfig.range) * radarRadius
    local distance = math.sqrt((blipX - radarX) ^ 2 + (blipY - radarY) ^ 2)
    local maxDistance = radarRadius - (radarConfig.blipRadius * scale)

    if distance > maxDistance and distance > 0 then
        local directionX = (blipX - radarX) / distance
        local directionY = (blipY - radarY) / distance
        blipX = radarX + directionX * maxDistance
        blipY = radarY + directionY * maxDistance
    end

    return blipX, blipY
end

local function GetRadarFireMarker(shooter)
    for _, marker in ipairs(radarEnemyMarkers) do
        if marker.shooter == shooter then
            return marker
        end
    end
end

hook.Add("HUDPaint", "garrysfactions_radar", function()
    local scale = ScrH() / 1080

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    -- Draw radar background
    local radarRadius = radarConfig.radius * scale
    local radarX = radarConfig.margin.x * scale + radarRadius
    local radarY =  radarConfig.margin.y * scale + radarRadius
    local radarOrigin = GetRadarPlayerPosition(ply)

    surface.SetDrawColor(0, 0, 0, 128)
    surface.SetMaterial(radarCircleMaterial)
    surface.DrawPoly(draw.JCircle(radarX, radarY, radarRadius, radarCircleCache))

    local playerColor = team.GetColor(ply:Team()) or color_white
    DrawRadarPlayerBlip(radarX, radarY, scale)

    local yaw = math.rad(ply:EyeAngles().y)
    local sinYaw = math.sin(yaw)
    local cosYaw = math.cos(yaw)

    local now = CurTime()
    for index = #radarEnemyMarkers, 1, -1 do
        local marker = radarEnemyMarkers[index]
        local age = now - marker.firedAt
        local isTeammate = IsValid(marker.shooter) and marker.shooter:Team() == ply:Team()
        local markerLifetime = isTeammate and radarPingDuration or radarEnemyTrackDuration + radarEnemyFadeDuration
        if age >= markerLifetime then
            table.remove(radarEnemyMarkers, index)
            continue
        end

        local markerPosition = marker.position
        if not isTeammate and age < radarEnemyTrackDuration + radarEnemyFadeDuration and IsValid(marker.shooter) then
            markerPosition = GetRadarPlayerPosition(marker.shooter)
        end

        local blipX, blipY = GetRadarBlipPosition(
            markerPosition,
            radarOrigin,
            radarX,
            radarY,
            radarRadius,
            scale,
            sinYaw,
            cosYaw
        )
        local pingAge = now - marker.pingedAt
        local pingProgress = math.min(pingAge / radarPingDuration, 1)
        local pingScale = 1 + (1 - pingProgress) * 0.75
        local markerAlpha = 255
        if not isTeammate and age >= radarEnemyTrackDuration then
            markerAlpha = 255 * (1 - (age - radarEnemyTrackDuration) / radarEnemyFadeDuration)
        end

        if not isTeammate then
            DrawRadarBlip(blipX, blipY, Color(255, 64, 64, markerAlpha), scale * pingScale)
        end
    end

    for _, teammate in player.Iterator() do
        if teammate == ply or not IsValid(teammate) or not teammate:Alive() or teammate:Team() ~= ply:Team() then
            continue
        end

        local blipX, blipY = GetRadarBlipPosition(
            GetRadarPlayerPosition(teammate),
            radarOrigin,
            radarX,
            radarY,
            radarRadius,
            scale,
            sinYaw,
            cosYaw
        )

        local teammateScale = scale
        local fireMarker = GetRadarFireMarker(teammate)
        if fireMarker then
            local pingAge = now - fireMarker.pingedAt
            if pingAge < radarPingDuration then
                teammateScale = scale * (1 + (1 - pingAge / radarPingDuration) * 0.75)
            end
        end

        DrawRadarBlip(blipX, blipY, playerColor, teammateScale, teammate:GetNWBool("downed"))
    end
end)