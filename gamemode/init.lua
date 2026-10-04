include("shared.lua")
include("player_ext.lua")
include("player_ext_shared.lua")
include("sv_workshop.lua")

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")

CreateConVar("jf_round_preparation_time", "15", FCVAR_NOTIFY)
CreateConVar("jf_round_time", "300", FCVAR_NOTIFY)

util.AddNetworkString("JF_NotifyRoundState")

function GM:Initialize()
    WaitForPlayers()
end

function NotifyRoundState(state, ply)
    net.Start("JF_NotifyRoundState")
        net.WriteUInt(state, 3)
    return ply and net.Send(ply) or net.Broadcast()
end

function SetRoundState(state)
    GAMEMODE.round_state = state

    print("Round state changed to: " .. state)
    NotifyRoundState(state)
end

function GetRoundState()
    return GAMEMODE.round_state
end

local function EnoughPlayers()
    local ready = 0
    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:ShouldSpawn() then
            ready = ready + 1
        end
    end

    return ready >= 2
end

function WaitForPlayers()
    SetRoundState(ROUND_WAITING)

    print("Waiting for players...")
    if not timer.Start("waiting_for_players") then
        timer.Create("waiting_for_players", 1, 0, function()
            if GetRoundState() == ROUND_WAITING and EnoughPlayers() then
                timer.Stop("waiting_for_players")
                PrepareRound()
            end
        end)
    end
end

function SetRoundEnd(endtime)
    SetGlobalFloat("jf_round_end", endtime)
end

function PrepareRound()
    SetRoundState(ROUND_STARTING)

    print("Preparing round...")
    local roundTime = GetConVar("jf_round_time"):GetInt()
    SetRoundEnd(CurTime() + roundTime)

    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:ShouldSpawn() then
            ply:Spawn()
        end
    end

    local roundPrepTime = GetConVar("jf_round_preparation_time"):GetInt()

    timer.Create("jf_round_timer", roundPrepTime, 1, function()
        StartRound()
    end)
end

function StartRound()
    SetRoundState(ROUND_ACTIVE)

    local roundTime = GetConVar("jf_round_time"):GetInt()
    print("Round started! Duration: " .. roundTime .. " seconds.")
    SetRoundEnd(CurTime() + roundTime)

    timer.Create("jf_round_timer", roundTime, 1, function()
        EndRound()
    end)
end

function EndRound()
    SetRoundState(ROUND_OVER)

    print("Round over.")
    timer.Simple(10, function()
        WaitForPlayers()
    end)
end

concommand.Add("jf_force_start", function(ply, cmd, args)
    -- Security check: only allow admins or the dedicated server console to run this
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "You do not have permission to force start the round.")
        return
    end

    print("[Debug] Admin " .. (IsValid(ply) and ply:Nick() or "Console") .. " forced the round to start!")
    
    -- 1. Stop the waiting loop so it doesn't interfere
    timer.Stop("waiting_for_players")
    
    -- 2. Instantly jump to the active phase
    PrepareRound()
end)