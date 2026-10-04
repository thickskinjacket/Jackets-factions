include("shared.lua")
include("cl_hud.lua")
include("cl_revive.lua")

CreateConVar("jf_spectator", "0", FCVAR_ARCHIVE)

local function ReceiveRoundState()
    GAMEMODE.round_state = net.ReadUInt(3)
end
net.Receive("JF_NotifyRoundState", ReceiveRoundState)