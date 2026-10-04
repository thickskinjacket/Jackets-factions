include("shared.lua")
include("cl_hud.lua")

local function ReceiveRoundState()
    GAMEMODE.round_state = net.ReadUInt(3)
end
net.Receive("JF_NotifyRoundState", ReceiveRoundState)