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

function draw.JCircle(PositionX, PositionY, Radius)
    local circle = {}
    local i = 0
    for ang = 0, 360 do
        i = i + 1
        circle[i] = {
            x = PositionX + math.cos(math.rad(ang)) * Radius,
            y = PositionY + math.sin(math.rad(ang)) * Radius
        }
    end
    return circle
end

function draw.JPie(PositionX, PositionY, Radius, StartAng, EndAng)
    StartAng = StartAng - 115
    EndAng = EndAng - 115
    local pie = {
        {x = PositionX, y = PositionY}
    }
    local i = 1
    for ang = StartAng, EndAng do
        i = i + 1
        pie[i] = {
            x = PositionX + math.cos(-math.rad(ang)) * Radius,
            y = PositionY + math.sin(-math.rad(ang)) * Radius
        }
    end
    return pie
end

function draw.JRing(PositionX, PositionY, Radius, Thickness, StartAng, EndAng)
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
        surface.DrawPoly(draw.JCircle(PositionX, PositionY, Radius - Thickness))
        render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
        surface.DrawPoly(draw.JPie(PositionX, PositionY, Radius, StartAng, EndAng))
    render.SetStencilEnable(false)
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
        local endAng = startAng + anglePerSegment - gap

        local segment = GetSegmentFill(i, hp, maxHP, totalSegments)

        if segment > 0 then
            local fillEndAng = startAng + ((anglePerSegment - gap) * segment)

            surface.SetDrawColor(255, 255, 255, 255)
            draw.JRing(x, y, radius, thickness, startAng, fillEndAng)
        end
    end
end

local ringConfig = { 
    margin = {
        x = 100, 
        y = 200,
    },
    radius = 65,
    thickness = 7 
}

local plyStartHP, plyOldHP, plyNewHP = 0, -1, -1

hook.Add("HUDPaint", "garrysfactions_hud", function()
    local scale = ScrH() / 1080

    local ply = LocalPlayer()

    local hp = ply:Health()
    local hpMax = ply:GetMaxHealth()
    local hpPercent = hp / hpMax

    if plyOldHP == -1 and plyNewHP == -1 then
        plyOldHP = hp
        plyNewHP = hp
    end

    if plyNewHP ~= hp then
        plyOldHP = plyNewHP
        plyNewHP = hp
        plyStartHP = CurTime()
    end

    -- Health bar
    local ringX = ScrW() - (ringConfig.margin.x * scale)
    local ringY = ScrH() - (ringConfig.margin.y * scale)
    local ringRadius = ringConfig.radius * scale
    local ringThickness = ringConfig.thickness * scale

    local delay = .25
    local duration = .15
    local fraction = math.Clamp((CurTime() - (plyStartHP + delay)) / duration, 0, 1)
    local lerpedHP = Lerp(fraction, plyOldHP, plyNewHP)

    -- Background ring
    surface.SetDrawColor(0, 0, 0, 255 * .75)
    draw.JRing(ringX, ringY, ringRadius, ringThickness, 0, 200)

    -- Health ring
    DrawHealthRing(ringX, ringY, ringRadius, ringThickness, lerpedHP, hpMax)
end)