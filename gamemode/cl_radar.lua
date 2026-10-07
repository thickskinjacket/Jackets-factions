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
local radarLootBoxIcon = Material("hud/lootbox2.png")

local radarEnemyMarkers = {}
local radarEnemyTrackDuration = 2
local radarEnemyFadeDuration = 1.5
local radarMarkDuration = 5
local radarMarkFadeDuration = 1
local radarPingDuration = 0.5
local radarEnemyColor = Color(255, 64, 64)

local function GetActiveMark(shooter, timestamp)
    for _, marker in ipairs(radarEnemyMarkers) do
        if marker.kind == "mark"
            and marker.shooter == shooter
            and timestamp - marker.firedAt < radarMarkDuration then
            return marker
        end
    end

    return nil
end

function JF_IsEnemyMarked(shooter)
    return GetActiveMark(shooter, CurTime()) ~= nil
end

function JF_GetEnemyMarkAlpha(shooter)
    local mark = GetActiveMark(shooter, CurTime())
    if not mark then return 0 end

    local age = CurTime() - mark.firedAt
    local fadeStart = radarMarkDuration - radarMarkFadeDuration
    if age < fadeStart then return 255 end

    return 255 * (1 - (age - fadeStart) / radarMarkFadeDuration)
end

local function UpdateRadarMarker(shooter, position, timestamp)
    local activeMark = GetActiveMark(shooter, timestamp)
    if activeMark then
        activeMark.pingedAt = timestamp
        return
    end

    for _, marker in ipairs(radarEnemyMarkers) do
        if marker.kind == "fire" and marker.shooter == shooter then
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
        pingedAt = timestamp,
        kind = "fire"
    })
end

net.Receive("JF_SendRadarPosition", function()
    UpdateRadarMarker(net.ReadEntity(), net.ReadVector(), CurTime())
end)

net.Receive("JF_MarkEnemy", function()
    local enemy = net.ReadEntity()
    local position = net.ReadVector()
    local timestamp = CurTime()

    table.insert(radarEnemyMarkers, {
        shooter = enemy,
        position = position,
        firedAt = timestamp,
        pingedAt = nil,
        kind = "mark"
    })
end)

local function DrawRadarBlip(x, y, color, scale, isDowned, isPlayerIcon, facingAngle)
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

    if isPlayerIcon then
        local iconWidth = radarConfig.blipRadius * 1.7 * scale
        local iconHeight = radarConfig.blipRadius * 2.3 * scale

        surface.SetDrawColor(color)
        surface.SetMaterial(radarPlayerIcon)
        surface.DrawTexturedRectRotated(x, y, iconWidth, iconHeight, facingAngle or 0)
        return
    end

    surface.SetDrawColor(color)
    surface.SetMaterial(radarCircleMaterial)
    surface.DrawPoly(draw.JCircle(x, y, radarConfig.blipRadius * scale, radarBlipCache))
end

local function DrawRadarPlayerBlip(x, y, scale)
    local iconWidth = radarConfig.blipRadius * 2.2 * scale
    local iconHeight = radarConfig.blipRadius * 3.2 * scale

    surface.SetDrawColor(Color(225, 255, 255))
    surface.SetMaterial(radarPlayerIcon)
    surface.DrawTexturedRect(x - (iconWidth / 2), y - (iconHeight / 2), iconWidth, iconHeight)
end

local function DrawSpectatorUI(ply, radarX, radarY, scale)
    local rectangleWidth = 600 * scale
    local rectangleHeight = 250 * scale
    local rectangleX = radarX - radarConfig.radius
    local rectangleY = radarY / 2 - (24 * scale)

    surface.SetDrawColor(0, 0, 0, 128)
    surface.DrawRect(rectangleX, rectangleY, rectangleWidth, rectangleHeight)

    local textX = rectangleX + rectangleWidth / 2
    draw.TextShadow({
        text = "Spectating",
        font = "TLOU_Font_Ammo_Big",
        pos = {textX, rectangleY + (32 * scale)},
        color = color_white,
        xalign = TEXT_ALIGN_CENTER,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)

    local target = ply:GetObserverTarget()
    if IsValid(target) and not target:IsPlayer() then
        target = target:GetNWEntity("owner")
    end

    if IsValid(target) and target:IsPlayer() then
        draw.TextShadow({
            text = target:Nick(),
            font = "jf_radar_lives",
            pos = {textX, rectangleY + (64 * scale)},
            color = team.GetColor(ply:Team()) or color_white,
            xalign = TEXT_ALIGN_CENTER,
            yalign = TEXT_ALIGN_CENTER
        }, 1, 200)
    end

    local separatorY = rectangleY + (88 * scale)
    surface.SetDrawColor(255, 255, 255, 160)
    surface.DrawRect(
        rectangleX + (32 * scale),
        separatorY,
        rectangleWidth - (64 * scale),
        math.max(1, scale)
    )

    local controlsY = rectangleY + (108 * scale)
    local controlGap = 24 * scale
    surface.SetFont("textFont")
    local nextTextWidth = surface.GetTextSize("LMB Next Player")
    local previousTextWidth = surface.GetTextSize("RMB Previous Player")
    local controlsWidth = nextTextWidth + controlGap + previousTextWidth
    local controlsX = textX - controlsWidth / 2

    draw.TextShadow({
        text = "LMB Next Player",
        font = "textFont",
        pos = {controlsX, controlsY},
        color = color_white,
        xalign = TEXT_ALIGN_LEFT,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)
    draw.TextShadow({
        text = "RMB Previous Player",
        font = "textFont",
        pos = {controlsX + nextTextWidth + controlGap, controlsY},
        color = color_white,
        xalign = TEXT_ALIGN_LEFT,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)

    local nextWaveIn = math.max(0, GetGlobalFloat("jf_next_respawn_wave", 0) - CurTime())
    local nextWaveSeconds = math.ceil(nextWaveIn)
    draw.TextShadow({
        text = "Next spawn wave in " .. nextWaveSeconds .. "...",
        font = "textFont",
        pos = {textX, rectangleY + (178 * scale)},
        color = color_white,
        xalign = TEXT_ALIGN_CENTER,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)

    local bottomControlGap = 16 * scale
    surface.SetFont("textFont")
    local storeTextWidth = surface.GetTextSize("[X] Store")
    local loadoutTextWidth = surface.GetTextSize("[X] Loadout")
    local bottomControlsWidth = storeTextWidth + bottomControlGap + loadoutTextWidth
    local bottomControlsX = textX - bottomControlsWidth / 2
    local bottomControlsY = rectangleY + (216 * scale)

    draw.TextShadow({
        text = "[X] Store",
        font = "textFont",
        pos = {bottomControlsX, bottomControlsY},
        color = color_white,
        xalign = TEXT_ALIGN_LEFT,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)
    draw.TextShadow({
        text = "[X] Loadout",
        font = "textFont",
        pos = {bottomControlsX + storeTextWidth + bottomControlGap, bottomControlsY},
        color = color_white,
        xalign = TEXT_ALIGN_LEFT,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)
end

local function DrawRadarLootBoxBlip(x, y, scale)
    local iconSize = 4 * 2.5 * scale

    surface.SetDrawColor(color_white)
    surface.SetMaterial(radarLootBoxIcon)
    surface.DrawTexturedRect(x - (iconSize / 2), y - (iconSize / 2), iconSize, iconSize)
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
    local isSpectator = ply:Team() == TEAM_SPECTATOR
    local ownTeam = isSpectator and TEAM_FIREFLIES or ply:Team()
    local enemyTeam = ownTeam == TEAM_FIREFLIES and TEAM_HUNTERS or TEAM_FIREFLIES
    local ownLives = GetGlobalInt("jf_teamlives_" .. ownTeam, 0)
    local enemyLives = GetGlobalInt("jf_teamlives_" .. enemyTeam, 0)
    local ownFont = ownLives > enemyLives and "jf_radar_lives_big" or "jf_radar_lives"
    local enemyFont = enemyLives > ownLives and "jf_radar_lives_big" or "jf_radar_lives"
    local colonFont = "jf_radar_lives"
    local ownText = string.format("%02d", ownLives)
    local enemyText = string.format("%02d", enemyLives)
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
        color = team.GetColor(enemyTeam) or color_white,
        xalign = TEXT_ALIGN_LEFT,
        yalign = TEXT_ALIGN_CENTER
    }, 1, 200)
end

local function DrawRadarTeamPlayers(ply, radarX, radarY, radarRadius, scale)
    local isSpectator = ply:Team() == TEAM_SPECTATOR
    local ownTeam = isSpectator and TEAM_FIREFLIES or ply:Team()
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

    local function sortPlayersByUserID(first, second)
        return first:UserID() < second:UserID()
    end

    table.sort(ownPlayers, sortPlayersByUserID)
    table.sort(enemyPlayers, sortPlayersByUserID)

    local iconSize = 40 * scale
    local iconGap = -15 * scale
    local iconY = radarY + radarRadius + (16 * scale)
    local ownStartX = radarX - iconSize
    local enemyStartX = radarX

    local function DrawTeamIcons(teamPlayers, startPosition, teamColor, direction)
        surface.SetDrawColor(teamColor)
        surface.SetMaterial(radarManIcon)

        for index = 1, #teamPlayers do
            local playerAlpha = teamPlayers[index]:Alive() and 255 or 60
            local iconX = startPosition + (index - 1) * (iconSize + iconGap) * direction
            surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, playerAlpha)
            surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
        end
    end

    DrawTeamIcons(ownPlayers, ownStartX, team.GetColor(ownTeam) or color_white, -1)
    DrawTeamIcons(enemyPlayers, enemyStartX, team.GetColor(enemyTeam) or color_white, 1)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(radarCircleMaterial)
end

hook.Add("HUDPaint", "jacketsfactions_radar", function()
    local scale = ScrH() / 1080

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local isSpectator = ply:Team() == TEAM_SPECTATOR
    local isSpectating = ply:GetObserverMode() ~= OBS_MODE_NONE
    local radarRadius = radarConfig.radius * scale
    local radarX = radarConfig.margin.x * scale + radarRadius
    local radarY =  radarConfig.margin.y * scale + radarRadius

    if not isSpectator and not ply:Alive() then
        if not isSpectating then return end

        DrawSpectatorUI(ply, radarX, radarY, scale)
        DrawRadarRoundTime(radarX, radarY, radarRadius, scale)
        DrawRadarTeamLives(ply, radarX, radarY, radarRadius, scale)
        DrawRadarTeamPlayers(ply, radarX, radarY, radarRadius, scale)
        return
    end

    -- Draw radar background
    local radarOrigin = isSpectator and EyePos() or GetRadarPlayerPosition(ply)

    surface.SetDrawColor(0, 0, 0, 128)
    surface.SetMaterial(radarCircleMaterial)
    surface.DrawPoly(draw.JCircle(radarX, radarY, radarRadius, radarCircleCache))
    DrawRadarRoundTime(radarX, radarY, radarRadius, scale)
    DrawRadarTeamLives(ply, radarX, radarY, radarRadius, scale)
    DrawRadarTeamPlayers(ply, radarX, radarY, radarRadius, scale)

    local playerColor = team.GetColor(ply:Team()) or color_white
    if not isSpectator then
        DrawRadarPlayerBlip(radarX, radarY, scale)
    end

    local playerYaw = ply:EyeAngles().y
    local yaw = math.rad(playerYaw)
    local sinYaw = math.sin(yaw)
    local cosYaw = math.cos(yaw)

    local now = CurTime()
    for index = #radarEnemyMarkers, 1, -1 do
        local marker = radarEnemyMarkers[index]
        local age = now - marker.firedAt
        if marker.kind == "fire" and GetActiveMark(marker.shooter, now) then
            continue
        end

        local isTeammate = IsValid(marker.shooter) and marker.shooter:Team() == ply:Team()
        local markerLifetime = marker.kind == "mark"
            and radarMarkDuration
            or (isTeammate and radarPingDuration or radarEnemyTrackDuration + radarEnemyFadeDuration)
        if age >= markerLifetime then
            table.remove(radarEnemyMarkers, index)
            continue
        end

        local markerPosition = marker.position
        if not isTeammate
            and (marker.kind == "mark" or age < radarEnemyTrackDuration + radarEnemyFadeDuration)
            and IsValid(marker.shooter) then
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
        local pingScale = 1
        if marker.pingedAt then
            local pingAge = now - marker.pingedAt
            local pingProgress = math.min(pingAge / radarPingDuration, 1)
            pingScale = 1 + (1 - pingProgress) * 0.75
        end
        local markerAlpha = 255
        if marker.kind == "mark" then
            local fadeStart = markerLifetime - radarMarkFadeDuration
            if age >= fadeStart then
                markerAlpha = 255 * (1 - (age - fadeStart) / radarMarkFadeDuration)
            end
        elseif not isTeammate and age >= radarEnemyTrackDuration then
            markerAlpha = 255 * (1 - (age - radarEnemyTrackDuration) / radarEnemyFadeDuration)
        end

        if not isTeammate or isSpectator then
            local markerBaseColor = isSpectator
                and (IsValid(marker.shooter) and team.GetColor(marker.shooter:Team()) or color_white)
                or radarEnemyColor
            local markerColor = Color(
                markerBaseColor.r,
                markerBaseColor.g,
                markerBaseColor.b,
                markerAlpha
            )
            local markerFacingAngle = IsValid(marker.shooter)
                and marker.shooter:EyeAngles().y - playerYaw
                or 0
            DrawRadarBlip(
                blipX,
                blipY,
                markerColor,
                scale * pingScale,
                false,
                isSpectator,
                markerFacingAngle
            )
        end
    end

    for _, teammate in player.Iterator() do
        if teammate == ply or not IsValid(teammate) or not teammate:Alive()
            or (not isSpectator and teammate:Team() ~= ply:Team()) then
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
        if fireMarker and not isSpectator then
            local pingAge = now - fireMarker.pingedAt
            if pingAge < radarPingDuration then
                teammateScale = scale * (1 + (1 - pingAge / radarPingDuration) * 0.75)
            end
        end

        local facingAngle = teammate:EyeAngles().y - playerYaw
        local teammateColor = isSpectator
            and (team.GetColor(teammate:Team()) or color_white)
            or playerColor
        DrawRadarBlip(
            blipX,
            blipY,
            teammateColor,
            teammateScale,
            teammate:GetNWBool("downed"),
            true,
            facingAngle
        )
    end

    for _, lootBox in ipairs(ents.FindByClass("loot_box")) do
        if not IsValid(lootBox) or lootBox:GetNWBool("jf_lootbox_open", false) then continue end

        local blipX, blipY = GetRadarBlipPosition(
            lootBox:GetPos(),
            radarOrigin,
            radarX,
            radarY,
            radarRadius,
            scale,
            sinYaw,
            cosYaw
        )

        DrawRadarLootBoxBlip(blipX, blipY, scale)
    end
end)