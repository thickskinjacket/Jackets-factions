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

local HP_CIRCLE_CACHE = {}
local HP_PIE_CACHE = {}
local GHOST_CIRCLE_CACHE = {}
local GHOST_PIE_CACHE = {}
local BG_CIRCLE_CACHE = {}
local BG_PIE_CACHE = {}

function draw.JCircle(PositionX, PositionY, Radius, CachedCircle)
    for i = 1, 361 do
        local ang = math.rad(i - 1)
        if not CachedCircle[i] then CachedCircle[i] = { x = 0, y = 0 } end
        CachedCircle[i].x = PositionX + math.cos(ang) * Radius
        CachedCircle[i].y = PositionY + math.sin(ang) * Radius
    end
    return CachedCircle
end

function draw.JPie(PositionX, PositionY, Radius, StartAng, EndAng, CachedPie)
    StartAng = StartAng - 115
    EndAng = EndAng - 115
    
    CachedPie[1] = {x = PositionX, y = PositionY}
    local i = 2
    for ang = StartAng, EndAng do
        if not CachedPie[i] then CachedPie[i] = { x = 0, y = 0 } end
        CachedPie[i].x = PositionX + math.cos(-math.rad(ang)) * Radius
        CachedPie[i].y = PositionY + math.sin(-math.rad(ang)) * Radius
        i = i + 1
    end

    for k = i, #CachedPie do CachedPie[k] = nil end
    
    return CachedPie
end

function draw.JRing(PositionX, PositionY, Radius, Thickness, StartAng, EndAng, CachedCircle, CachedPie)
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
        surface.DrawPoly(draw.JPie(PositionX, PositionY, Radius, StartAng, EndAng, CachedPie))
    render.SetStencilEnable(false)
end

local function DrawHUDBackground(x, y, radius, thickness, circleCache, pieCache, scale)
    local bgBoxW = 200 * scale
    local bgBoxH = 70 * scale

    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
        surface.SetDrawColor(0, 0, 0, 255 * .75)
        surface.DrawPoly(draw.JCircle(x, y, radius, circleCache))
    render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
        surface.SetDrawColor(0, 0, 0, 255 * .75)
        surface.DrawRect(x - bgBoxW, y - (bgBoxH / 2), bgBoxW, bgBoxH)
    render.SetStencilEnable(false)

    surface.SetDrawColor(150, 150, 150, 255 * .75)
    draw.JRing(x, y, radius, thickness, 0, 198, circleCache, pieCache)
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
            surface.SetDrawColor(255, 255, 255, 255)
            draw.JRing(x, y, radius, thickness, startAng, fillEndAng, HP_CIRCLE_CACHE, HP_PIE_CACHE)
        end
    end
end

local function DrawHealthRing(x, y, radius, thickness, hp, maxHP)
    local totalSegments = 5
    local hpMaxAngle = 200
    local anglePerSegment = hpMaxAngle / totalSegments
    local gap = 2

    for i = 1, totalSegments do
        local startAng = (i - 1) * anglePerSegment
        local endAng = startAng + anglePerSegment - gap

        local segment = GetSegmentFill(i, hp, maxHP, totalSegments)

        if segment > 0 then
            local fillEndAng = startAng + ((anglePerSegment - gap) * segment)

            surface.SetDrawColor(255, 255, 255, 255)
            draw.JRing(x, y, radius, thickness, startAng, fillEndAng, HP_CIRCLE_CACHE, HP_PIE_CACHE)
        end
    end
end

local ringConfig = { 
    margin = {
        x = 100, 
        y = 200,
    },
    radius = 62,
    thickness = 7 
}

local plyStartHP, plyOldHP, plyNewHP = 0, -1, -1

hook.Add("HUDPaint", "garrysfactions_hud", function()
    local scale = ScrH() / 1080

    local ply = LocalPlayer()

    local hp = ply:Health()
    local hpMax = ply:GetMaxHealth()
    local hpPercent = hp / hpMax

    local ringX = ScrW() - (ringConfig.margin.x * scale)
    local ringY = ScrH() - (ringConfig.margin.y * scale)
    local ringRadius = ringConfig.radius * scale
    local ringThickness = ringConfig.thickness * scale

    -- Background
    DrawHUDBackground(ringX, ringY, ringRadius, ringThickness, BG_CIRCLE_CACHE, BG_PIE_CACHE, scale)

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
        
        surface.SetDrawColor(140, 28, 26, 255)
        draw.JRing(ringX, ringY, ringRadius, ringThickness, startAng, endAng, GHOST_CIRCLE_CACHE, GHOST_PIE_CACHE)
    end

    -- Health ring
    DrawHealthRing(ringX, ringY, ringRadius, ringThickness, hp, hpMax)
end, HOOK_HIGH)