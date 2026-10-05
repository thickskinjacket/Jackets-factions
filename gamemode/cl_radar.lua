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
local radarManIcon = Material("hud/man2.png")

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

local function DrawRadarRoundTime(radarX, radarY, radarRadius, scale)
    local roundEnd = GetGlobalFloat("jf_round_end", 0)
    if roundEnd <= 0 then return end

    local remainingTime = math.max(0, roundEnd - CurTime())

    local totalSeconds = math.ceil(remainingTime)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local timeText = string.format("%d:%02d", minutes, seconds)
    local timerColor = color_white
    if remainingTime < 30 then
        local pulse = (math.sin(CurTime() * math.pi * 2) + 1) / 2
        timerColor = Color(255, Lerp(pulse, 255, 0), Lerp(pulse, 255, 0))
    end

    draw.TextShadow({
        text = timeText,
        font = "TLOU_Font_Ammo_Big",
        pos = {
            radarX,
            radarY - radarRadius - (5 * scale)
        },
        color = timerColor,
        xalign = TEXT_ALIGN_CENTER,
        yalign = TEXT_ALIGN_BOTTOM
    }, 1, 200)
end

local function DrawRadarTeamLives(ply, radarX, radarY, radarRadius, scale)
    local ownTeam = ply:Team()
    local enemyTeam = ownTeam == TEAM_FIREFLIES and TEAM_HUNTERS or TEAM_FIREFLIES
    local ownLives = GetGlobalInt("jf_teamlives_" .. ownTeam, 0)
    local enemyLives = GetGlobalInt("jf_teamlives_" .. enemyTeam, 0)
    local ownFont = ownLives > enemyLives and "jf_radar_lives_big" or "jf_radar_lives"
    local enemyFont = enemyLives > ownLives and "jf_radar_lives_big" or "jf_radar_lives"
    local colonFont = "jf_radar_lives"
    local ownText = tostring(ownLives)
    local enemyText = tostring(enemyLives)
    local gap = 3 * scale

    surface.SetFont(colonFont)
    local colonWidth, colonHeight = surface.GetTextSize(":")
    surface.SetFont(ownFont)
    local _, ownHeight = surface.GetTextSize(ownText)
    surface.SetFont(enemyFont)
    local _, enemyHeight = surface.GetTextSize(enemyText)
    local colonX = radarX
    local textY = radarY + radarRadius + (57 * scale) + math.max(colonHeight, ownHeight, enemyHeight) / 2

    draw.TextShadow({
        text = ownText,
        font = ownFont,
        pos = {colonX - (colonWidth / 2) - gap, textY},
        color = team.GetColor(ownTeam) or color_white,
        xalign = TEXT_ALIGN_RIGHT,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)

    draw.TextShadow({
        text = ":",
        font = colonFont,
        pos = {colonX, textY},
        color = color_white,
        xalign = TEXT_ALIGN_CENTER,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)

    draw.TextShadow({
        text = enemyText,
        font = enemyFont,
        pos = {colonX + (colonWidth / 2) + gap, textY},
        color = Color(166, 49, 49),
        xalign = TEXT_ALIGN_LEFT,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)
end

local function DrawRadarTeamPlayers(ply, radarX, radarY, radarRadius, scale)
    local ownTeam = ply:Team()
    local enemyTeam = ownTeam == TEAM_FIREFLIES and TEAM_HUNTERS or TEAM_FIREFLIES
    local ownPlayers = {}
    local enemyPlayers = {}

    for _, playerEntity in player.Iterator() do
        if not IsValid(playerEntity) then continue end

        if playerEntity:Team() == ownTeam then
            table.insert(ownPlayers, playerEntity)
        elseif playerEntity:Team() == enemyTeam then
            table.insert(enemyPlayers, playerEntity)
        end
    end

    local iconSize = 40 * scale
    local iconGap = -10 * scale
    local teamGap = 0 * scale
    local ownWidth = math.max(0, #ownPlayers * iconSize + (#ownPlayers - 1) * iconGap)
    local enemyWidth = math.max(0, #enemyPlayers * iconSize + (#enemyPlayers - 1) * iconGap)
    local totalWidth = ownWidth + teamGap + enemyWidth
    local startX = radarX - totalWidth / 2
    local iconY = radarY + radarRadius + (16 * scale)

    local function DrawTeamIcons(teamPlayers, startPosition, teamColor)
        surface.SetDrawColor(teamColor)
        surface.SetMaterial(radarManIcon)

        for index = 1, #teamPlayers do
            local playerAlpha = teamPlayers[index]:Alive() and 255 or 60
            local iconX = startPosition + (index - 1) * (iconSize + iconGap)
            surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, playerAlpha)
            surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
        end
    end

    DrawTeamIcons(ownPlayers, startX, team.GetColor(ownTeam) or color_white)
    DrawTeamIcons(enemyPlayers, startX + ownWidth + teamGap, Color(166, 49, 49))
    surface.SetDrawColor(color_white)
    surface.SetMaterial(radarCircleMaterial)
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
    DrawRadarRoundTime(radarX, radarY, radarRadius, scale)
    DrawRadarTeamLives(ply, radarX, radarY, radarRadius, scale)
    DrawRadarTeamPlayers(ply, radarX, radarY, radarRadius, scale)

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