include("shared.lua")
include("sv_workshop.lua")

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")

util.AddNetworkString("JF_NotifyRoundState")

function GM:Initialize()
    -- Do stuff
end

function NotifyRoundState(state, ply)
    net.Start("JF_NotifyRoundState")
        net.WriteUInt(state, 3)
    return ply and net.Send(ply) or net.Broadcast()
end

function SetRoundState(state)
    GAMEMODE.round_state = state

    NotifyRoundState(state)
end

function GetRoundState()
    return GAMEMODE.round_state
end