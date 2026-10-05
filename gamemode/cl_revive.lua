local chasePos

hook.Add("CalcView", "downed_state_view", function(ply, pos, ang, fov)
    local downed_ragdoll = ply:GetNWEntity("downed_ragdoll")
    if not IsValid(downed_ragdoll) then return end
    if not ply:GetNWBool("downed") then 
        if not ply:Alive() then
            downed_ragdoll:ManipulateBoneScale(6, Vector(1, 1, 1))
        end

        return 
    end

    downed_ragdoll:ManipulateBoneScale(6, Vector(1, 1, 1))

    local target = downed_ragdoll:WorldSpaceCenter() + Vector(0, 0, 20)

    local desired = target - ang:Forward() * 60

    local tr = util.TraceHull({
        start  = target,
        endpos = desired,
        filter = function(ent)
            if ent:IsPlayer() or ent:IsNPC() then return false end
        end
    })

    local finalPos = tr.Hit and (tr.HitPos + tr.HitNormal) or desired

    local t = math.Clamp(FrameTime() * 8, 0, 1)
    chasePos = chasePos and LerpVector(t, chasePos, finalPos) or finalPos

    local camAng = (target - chasePos):Angle()

    return {
        origin = chasePos,
        angles = camAng
    }
end)

local downedPlayers = {}

local matWhite = Material("vgui/white")
local health_icon = Material("hud/small-health.png")

local circle60
local circle75
local pie60 = {}
local pie75 = {}
local hudCircle = {}
local hudPie = {}

hook.Add("HUDPaintBackground", "downed_bleed_out_hud", function()
    local ply = LocalPlayer()
    local rag = ply:GetNWEntity("downed_ragdoll")

	if not ply:GetNWBool("downed") or not IsValid(ply) or not IsValid(rag) or not ply:Alive() then return end

    local bleed_out_time = GetConVar("jf_bleedout_time"):GetInt()
    local revive_time = GetConVar("jf_revive_time"):GetInt()

    local scale = ScrW() / 1600
    local savior = rag:GetNWEntity("savior")
    local isBeingRevived = IsValid(savior)

    // Math
    -- Bleed out
    local startBleedOutTime = rag:GetNWFloat("bleedOutStartTime", 0)
    local elapsedBleedOut = CurTime() - startBleedOutTime
    local fractionBleedOut = 1 - math.Clamp(elapsedBleedOut / bleed_out_time, 0, 1)

    -- Revive
    local startReviveTime = rag:GetNWFloat("reviveStartTime", 0)
    local elapsedRevive = CurTime() - startReviveTime
    local fractionRevive = math.Clamp(elapsedRevive / revive_time, 0, 1)

    // Text properties
    surface.SetFont("textFont")
    local downedMessage = isBeingRevived and "You are being helped up" or "You are bleeding out"
    local textW, textH = surface.GetTextSize(downedMessage)

    // Ring properties
    local pulseSpeed = 4
    local pulse = (math.sin(CurTime() * pulseSpeed) + 1) / 2
    local minGB = 100
    local g = minGB + (255 - minGB) * pulse
    local b = minGB + (255 - minGB) * pulse
    local ringRadius = 20 * scale
    local ringThickSkinJacket = 5 * scale
    local ringColor = isBeingRevived and Color(123, 183, 232, 255) or Color(255, g, b, 255)
    local ringFraction = isBeingRevived and fractionRevive or fractionBleedOut

    // Background box properties
    local boxW, boxH = textW + (10 + (ringRadius * 2 + 10) * scale), 50 * scale
    local boxX, boxY = ScrW() / 2 - (boxW / 2), ScrH() / 2 - (boxH / 2) + (250 * scale)

    // Background box
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(boxX, boxY, boxW, boxH)

    // Text 
    surface.SetDrawColor(255, 255, 255, 255)
    draw.SimpleText(downedMessage, "textFont", boxX + (textW / 2) + 5, boxY + (boxH / 2), Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    // Timer ring
    surface.SetDrawColor(ringColor)
    draw.JRing(boxX + boxW - (ringRadius) - 5, boxY + (boxH / 2), ringRadius, ringThickSkinJacket, 0, 360 * ringFraction, hudCircle, hudPie, 90)
end)

hook.Add("PostDrawOpaqueRenderables", "draw_downed_players_icons", function()
    if table.IsEmpty(downedPlayers) then return end

    local bleed_out_time = GetConVar("jf_bleedout_time"):GetInt()
    local revive_time = GetConVar("jf_revive_time"):GetInt()
    local lp = LocalPlayer()
    local eyepos = EyePos()

    if not circle60 then
        circle60 = {}
    end
    if not circle75 then
        circle75 = {}
    end

    for ply, rag in pairs(downedPlayers) do
        if not IsValid(rag) or not IsValid(ply) or not ply:Alive() then continue end
        if ply:Team() ~= lp:Team() then continue end
        if ply == LocalPlayer() then continue end

        local pos = rag:GetPos()
        pos.z = pos.z + 20

        local ang = (eyepos - pos):Angle()
        ang:RotateAroundAxis(ang:Right(), 270)
        ang:RotateAroundAxis(ang:Up(), 90)

        local distance = eyepos:DistToSqr(pos)

        local pausedElapsed = rag:GetNWFloat("bleedOutPausedElapsed", -1)

        local startBleedOutTime = rag:GetNWFloat("bleedOutStartTime", 0)
        local elapsedBleedOut = 0
        if pausedElapsed >= 0 then
            elapsedBleedOut = pausedElapsed
        else
            elapsedBleedOut = CurTime() - startBleedOutTime
        end    
        local fractionBleedOut = 1 - math.Clamp(elapsedBleedOut / bleed_out_time, 0, 1)

        local startReviveTime = rag:GetNWFloat("reviveStartTime", 0)
        local elapsedRevive = CurTime() - startReviveTime
        local fractionRevive = math.Clamp(elapsedRevive / revive_time, 0, 1)
        
        cam.IgnoreZ(true)
        cam.Start3D2D(pos, ang, math.max(240, math.sqrt(distance)) / 2400)
            surface.SetMaterial(matWhite)

            if LocalPlayer() == rag:GetNWEntity("savior") then
                surface.SetDrawColor(11, 16, 183, 255)
                draw.JRing(0, 0, 75, 10, 0, 360 * fractionRevive, circle75, pie75, 90)
            end

            surface.SetDrawColor(57, 59, 61, 255)
            draw.JRing(0, 0, 60, 10, 0, 360, circle60, pie60, 90)
            surface.SetDrawColor(167, 15, 16, 255)
            draw.JRing(0, 0, 60, 10, 0, 360 * fractionBleedOut, circle60, pie60, 90)

            surface.SetDrawColor(123, 183, 232, 255)
            surface.SetMaterial(health_icon) 
            surface.DrawTexturedRect(-32, -32, 64, 64)

            draw.SimpleTextOutlined(ply:Nick(), "plyNickFont", 0, -110, team.GetColor(LocalPlayer():Team()), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
        cam.End3D2D()
        cam.IgnoreZ(false)
    end
end)

hook.Add("OnEntityCreated", "apply_colour_to_ragdoll", function(ent)
    if not IsValid(ent) then return end
    if ent:GetClass() != "prop_ragdoll" then return end

    timer.Simple(0, function()
        ent.GetPlayerColor = function ()
            return ent:GetNWVector("rag_ply_color", Vector(0, 0, 0))
        end
    end)
end)

net.Receive("downedPlayerLocation", function()
    local ragdoll = net.ReadEntity()
    local ragdollOwner = net.ReadEntity()

    for ply, rag in pairs(downedPlayers) do
        if not IsValid(ply) or not IsValid(rag) then
            downedPlayers[ply] = nil
        end
    end

    if not IsValid(ragdoll) then
        downedPlayers[ragdollOwner] = nil

        return
    end

    downedPlayers[ragdollOwner] = ragdoll
end)