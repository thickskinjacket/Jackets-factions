local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudWeapon"] = true,
}

hook.Add("HUDShouldDraw", "HideTheDefaultHUD", function(name)
    if (hide[name]) then
        return false
    end
end)

hook.Add("HUDDrawTargetID", "HideDefaultTargetID", function()
    return false
end)

local HP_CIRCLE_CACHE = {}
local HP_PIE_CACHE = {}
local GHOST_CIRCLE_CACHE = {}
local GHOST_PIE_CACHE = {}
local BG_CIRCLE_CACHE = {}
local BG_PIE_CACHE = {}
local HUD_BACKGROUND_COLOR = Color(0, 0, 0, 255 * .75)
local HUD_OUTLINE_COLOR = Color(0, 0, 0, 220)
local HUD_ACTIVE_COLOR = Color(255, 255, 255, 255)
local HUD_INACTIVE_COLOR = Color(140, 140, 140, 255)
local HUD_SECONDARY_TEXT_COLOR = Color(180, 180, 180, 255)
local HUD_HEALTH_GHOST_COLOR = Color(140, 28, 26, 255)
local HUD_PARTS_COLOR = Color(127, 174, 149)
local HUD_ENEMY_NAME_COLOR = Color(166, 49, 49, 255)
local ENEMY_NAME_TAG_RANGE = 1000
local ENEMY_NAME_TAG_FOV = math.cos(math.rad(30))
local enemyNameTagAlpha = {}
local ENEMY_NAME_TAG_FADE_IN_SPEED = 6
local ENEMY_NAME_TAG_FADE_OUT_SPEED = 2

function draw.JCircle(PositionX, PositionY, Radius, CachedCircle)
    for i = 1, 361 do
        local ang = math.rad(i - 1)
        if not CachedCircle[i] then CachedCircle[i] = { x = 0, y = 0 } end
        CachedCircle[i].x = PositionX + math.cos(ang) * Radius
        CachedCircle[i].y = PositionY + math.sin(ang) * Radius
    end
    return CachedCircle
end

function draw.JPie(PositionX, PositionY, Radius, StartAng, EndAng, CachedPie, AngleOffset)
    AngleOffset = AngleOffset or 115
    StartAng = StartAng - AngleOffset
    EndAng = EndAng - AngleOffset
    
    CachedPie[1] = {x = PositionX, y = PositionY}
    local i = 2
    local step = StartAng <= EndAng and 1 or -1
    for ang = StartAng, EndAng, step do
        if not CachedPie[i] then CachedPie[i] = { x = 0, y = 0 } end
        CachedPie[i].x = PositionX + math.cos(math.rad(ang)) * Radius
        CachedPie[i].y = PositionY + math.sin(math.rad(ang)) * Radius
        i = i + 1
    end

    for k = i, #CachedPie do CachedPie[k] = nil end
    
    return CachedPie
end

function draw.JRing(PositionX, PositionY, Radius, Thickness, StartAng, EndAng, CachedCircle, CachedPie, AngleOffset)
    render.SetStencilWriteMask( 0xFF )
    render.SetStencilTestMask( 0xFF )
    render.SetStencilReferenceValue( 0 )
    render.SetStencilCompareFunction( STENCIL_ALWAYS )
    render.SetStencilPassOperation( STENCIL_KEEP )
    render.SetStencilFailOperation( STENCIL_KEEP )
    render.SetStencilZFailOperation( STENCIL_KEEP )
    render.ClearStencil()

    render.SetStencilEnable(true)
        render.SetStencilReferenceValue(1)
        render.SetStencilFailOperation(STENCIL_EQUAL)
        render.SetStencilCompareFunction(STENCIL_NEVER)
        surface.DrawPoly(draw.JCircle(PositionX, PositionY, Radius - Thickness, CachedCircle))
        render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
        surface.DrawPoly(draw.JPie(PositionX, PositionY, Radius, StartAng, EndAng, CachedPie, AngleOffset))
    render.SetStencilEnable(false)
end

local function DrawHUDBackground(x, y, radius, thickness, circleCache, pieCache, scale)
    local bgBoxW = 200 * scale
    local bgBoxH = 60 * scale

    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
        surface.SetDrawColor(HUD_BACKGROUND_COLOR)
        surface.DrawPoly(draw.JCircle(x, y, radius, circleCache))
    render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
        surface.SetDrawColor(HUD_BACKGROUND_COLOR)
        surface.DrawRect(x - bgBoxW, y - (bgBoxH / 2), bgBoxW, bgBoxH)
    render.SetStencilEnable(false)

    surface.SetDrawColor(HUD_INACTIVE_COLOR)
    draw.JRing(x, y, radius, thickness, 0, -198, circleCache, pieCache, -115)
end

local function DrawAmmoDisplay(x, y, offset, ply, scale)
    local currentWeapon = ply:GetActiveWeapon()
    if !currentWeapon:IsValid() then return end

    local clip = currentWeapon:Clip1()
    local clipMax = currentWeapon:GetStat("Primary.ClipSize")
    local ammoType = currentWeapon:GetPrimaryAmmoType()
    local clipReserve = ply:GetAmmoCount(ammoType)

    if clipMax <= 0 and ammoType == -1 then return end

    surface.SetFont("TLOU_Font_Ammo_Small")
    local ammoCountDisplayText = clip
    local countW, countH = surface.GetTextSize(ammoCountDisplayText)
    local ammoX = x + countW + (offset / 4)
    local ammoY = y + countH

    if clip == -1 and ammoType != nil then
        draw.SimpleText(clipReserve, "TLOU_Font_Ammo_Big", ammoX - (offset / 4) - (countW / 2), ammoY, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        return
    end

    local clipCountW = 2
    local clipCountH = 8
    local clipCountX = x - offset
    local clipCountY = y + (offset / 2)
    local clipCountLimit = math.min(30 * scale, clipMax)
    local gap = 4

    for i = 0, clipCountLimit - 1 do
        local posX = clipCountX + (i * -gap)

        if i < clip then surface.SetDrawColor(HUD_ACTIVE_COLOR)
        else surface.SetDrawColor(HUD_INACTIVE_COLOR) end

        surface.DrawRect(posX, clipCountY, clipCountW, clipCountH)
    end

    local ammoCountReserveDisplayText = " | " .. clipReserve
    local countReserveW, countReserveH = surface.GetTextSize(ammoCountReserveDisplayText)

    draw.SimpleText(ammoCountDisplayText, "TLOU_Font_Ammo_Big", ammoX - countReserveW, ammoY, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    draw.SimpleText(ammoCountReserveDisplayText, "TLOU_Font_Ammo_Small", ammoX, ammoY, HUD_SECONDARY_TEXT_COLOR, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

local function GetSegmentFill(segmentIndex, currentHP, maxHP, segments)
    local hpPerSegment = maxHP / segments
    local segmentStartHP = (segmentIndex - 1) * hpPerSegment
    local segmentEndHP = segmentIndex * hpPerSegment

    return math.Clamp((currentHP - segmentStartHP) / hpPerSegment, 0, 1)
end

local function DrawHealthRing(x, y, radius, thickness, hp, maxHP)
    local totalSegments = 5
    local hpMaxAngle = 200
    local anglePerSegment = hpMaxAngle / totalSegments
    local gap = 2

    for i = 1, totalSegments do
        local startAng = (i - 1) * anglePerSegment
        local segment = GetSegmentFill(i, hp, maxHP, totalSegments)

        if segment > 0 then
            local fillEndAng = startAng + ((anglePerSegment - gap) * segment)
            surface.SetDrawColor(HUD_ACTIVE_COLOR)
            draw.JRing(x, y, radius, thickness, -startAng, -fillEndAng, HP_CIRCLE_CACHE, HP_PIE_CACHE, -115)
        end
    end
end

local ringConfig = { 
    margin = {
        x = 100, 
        y = 200,
    },
    radius = 64,
    thickness = 7 
}

local function DrawPartsDisplay(ply, scale)
    local partsX = 64 * scale
    local partsY = ScrH() - (64 * scale) 

    draw.TextShadow({
        text = ply:GetNWInt("jf_parts", 0),
        font = "jf_parts_counter",
        pos = {
            partsX,
            partsY
        },
        color = HUD_PARTS_COLOR,
        xalign = TEXT_ALIGN_LEFT,
        yalign = TEXT_ALIGN_BOTTOM
    }, 1, 200)
end

local plyStartHP, plyOldHP, plyNewHP = 0, -1, -1

hook.Add("HUDPaint", "jacketsfactions_hud", function()
    local scale = ScrH() / 1080

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    DrawPartsDisplay(ply, scale)

    local hp = ply:Health()
    local hpMax = ply:GetMaxHealth()
    local hpPercent = hp / hpMax

    local ringX = ScrW() - (ringConfig.margin.x * scale)
    local ringY = ScrH() - (ringConfig.margin.y * scale)
    local ringRadius = ringConfig.radius * scale
    local ringThickness = ringConfig.thickness * scale

    -- Background
    DrawHUDBackground(ringX, ringY, ringRadius, ringThickness, BG_CIRCLE_CACHE, BG_PIE_CACHE, scale)

    -- Ammo
    DrawAmmoDisplay(ringX, ringY, ringRadius, ply, scale)

    if plyOldHP == -1 and plyNewHP == -1 then
        plyOldHP = hp
        plyNewHP = hp
        hpLossGhost = hp
    end

    local delay = .5
    local duration = .15
    local fraction = math.Clamp((CurTime() - (plyStartHP + delay)) / duration, 0, 1)
    local hpLossGhost = Lerp(fraction, plyOldHP, plyNewHP)

    if hp < plyNewHP then
        plyOldHP = hpLossGhost
        plyNewHP = hp
        plyStartHP = CurTime()
    elseif hp > plyNewHP then 
        plyOldHP = hp
        plyNewHP = hp
    end

    -- Health loss ghost bar
    if hpLossGhost > hp then
        local startAng = math.Clamp((hp / hpMax) * 200, 0, 200)
        local endAng = math.Clamp((hpLossGhost / hpMax) * 200, 0, 200)
        
        surface.SetDrawColor(HUD_HEALTH_GHOST_COLOR)
        draw.JRing(ringX, ringY, ringRadius, ringThickness, -startAng, -endAng, GHOST_CIRCLE_CACHE, GHOST_PIE_CACHE, -115)
    end

    -- Health ring
    DrawHealthRing(ringX, ringY, ringRadius, ringThickness, hp, hpMax)
end, HOOK_HIGH)

hook.Add("PreDrawHalos", "jacketsfactions_teammate_halos", function()
    local ply = LocalPlayer()
    
    if not IsValid(ply) then return end

    local plyTeam = ply:Team()

    local teammates = {}
    
    for _, otherPly in player.Iterator() do
        if IsValid(otherPly) and otherPly:Alive() and otherPly ~= ply and otherPly:Team() == plyTeam then
            if otherPly:GetNWBool("downed") then
                table.RemoveByValue(teammates, otherPly)
                local ragdoll = otherPly:GetNWEntity("downed_ragdoll")
                
                table.insert(teammates, ragdoll)
                continue
            end
            table.insert(teammates, otherPly)
        end
    end

    if #teammates > 0 then
        local haloColor = team.GetColor(plyTeam) or color_white
        
        halo.Add(teammates, haloColor, 2, 2, 2, true, true)
    end
end)

hook.Add("HUDPaint", "jacketsfactions_teammate_names", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local plyTeam = ply:Team()
    local nameColor = team.GetColor(plyTeam) or color_white

    for _, otherPly in player.Iterator() do
        if not IsValid(otherPly) or otherPly == ply or not otherPly:Alive() or otherPly:Team() ~= plyTeam then
            continue
        end
        if otherPly:GetNWBool("downed") then continue end

        local target = otherPly
        if otherPly:GetNWBool("downed") then
            target = otherPly:GetNWEntity("downed_ragdoll")
        end

        if not IsValid(target) then continue end

        local position = target:GetPos() + Vector(0, 0, target:OBBMaxs().z + 6)
        local screenPosition = position:ToScreen()

        if not screenPosition.visible then continue end

        draw.SimpleTextOutlined(
            otherPly:Nick(),
            "jf_teammate_name",
            screenPosition.x,
            screenPosition.y,
            nameColor,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            1,
            HUD_OUTLINE_COLOR
        )
    end
end)

hook.Add("HUDPaint", "jacketsfactions_enemy_names", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local eyePosition = ply:EyePos()
    local eyeForward = ply:EyeAngles():Forward()
    local rangeSquared = ENEMY_NAME_TAG_RANGE ^ 2
    local visibleEnemies = {}

    for _, otherPly in player.Iterator() do
        if not IsValid(otherPly) or otherPly == ply or otherPly:Team() == ply:Team() or otherPly:Team() <= 0 then
            continue
        end

        local isDowned = otherPly:GetNWBool("downed")
        local target = isDowned and otherPly:GetNWEntity("downed_ragdoll") or otherPly
        local isVisible = otherPly:Alive() and IsValid(target)
        local tagPosition

        if isVisible then
            local targetCenter = target:WorldSpaceCenter()
            local toTarget = targetCenter - eyePosition
            isVisible = toTarget:LengthSqr() <= rangeSquared

            if isVisible then
                toTarget:Normalize()
                isVisible = eyeForward:Dot(toTarget) >= ENEMY_NAME_TAG_FOV
            end

            if isVisible then
                local trace = util.TraceLine({
                    start = eyePosition,
                    endpos = targetCenter,
                    filter = ply,
                    mask = MASK_VISIBLE
                })
                isVisible = not trace.Hit or trace.Entity == otherPly
            end

            if isVisible then
                tagPosition = target:GetPos() + Vector(0, 0, target:OBBMaxs().z + 6)
                isVisible = tagPosition:ToScreen().visible
            end
        end

        local currentAlpha = enemyNameTagAlpha[otherPly] or 0
        if isVisible then
            currentAlpha = math.min(1, currentAlpha + FrameTime() * ENEMY_NAME_TAG_FADE_IN_SPEED)
            visibleEnemies[otherPly] = true
        else
            currentAlpha = math.max(0, currentAlpha - FrameTime() * ENEMY_NAME_TAG_FADE_OUT_SPEED)
        end
        enemyNameTagAlpha[otherPly] = currentAlpha

        if currentAlpha > 0 then
            tagPosition = tagPosition or target:GetPos() + Vector(0, 0, target:OBBMaxs().z + 6)
            local screenPosition = tagPosition:ToScreen()
            local nameColor = Color(HUD_ENEMY_NAME_COLOR.r, HUD_ENEMY_NAME_COLOR.g, HUD_ENEMY_NAME_COLOR.b, currentAlpha * 255)
            local outlineColor = Color(HUD_OUTLINE_COLOR.r, HUD_OUTLINE_COLOR.g, HUD_OUTLINE_COLOR.b, currentAlpha * HUD_OUTLINE_COLOR.a)

            draw.SimpleTextOutlined(
                otherPly:Nick(),
                "jf_teammate_name",
                screenPosition.x,
                screenPosition.y,
                nameColor,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                1,
                outlineColor
            )
        end
    end

    for otherPly in pairs(enemyNameTagAlpha) do
        if not IsValid(otherPly) then
            enemyNameTagAlpha[otherPly] = nil
        elseif not visibleEnemies[otherPly] and enemyNameTagAlpha[otherPly] <= 0 then
            enemyNameTagAlpha[otherPly] = nil
        end
    end
end)
