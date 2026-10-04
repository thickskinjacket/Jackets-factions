include("shared.lua")
include("player.lua")
include("player_ext.lua")
include("player_ext_shared.lua")
include("sv_workshop.lua")
include("sv_revive.lua")

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_revive.lua")
AddCSLuaFile("sh_revive.lua")

CreateConVar("jf_round_preparation_time", "2", FCVAR_NOTIFY)
CreateConVar("jf_round_time", "300", FCVAR_NOTIFY)
CreateConVar("jf_round_post_time", "2", FCVAR_NOTIFY)
CreateConVar("jf_respawn_time", "5", FCVAR_NOTIFY)
CreateConVar("jf_team_lives", "4", FCVAR_NOTIFY)

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

local function AssignTeams(players)
    for i, ply in player.Iterator() do
        ply:SetTeam(i % 2 == 0 and TEAM_FIREFLIES or TEAM_HUNTERS)
    end
end

local function ResetTeamLives()
    local teamLives = GetConVar("jf_team_lives"):GetInt()
    GAMEMODE.TeamLives = {}
    GAMEMODE.TeamLives[TEAM_FIREFLIES] = teamLives
    GAMEMODE.TeamLives[TEAM_HUNTERS] = teamLives

    SetGlobalInt("jf_teamlives_" .. TEAM_FIREFLIES, GAMEMODE.TeamLives[TEAM_FIREFLIES])
    SetGlobalInt("jf_teamlives_" .. TEAM_HUNTERS, GAMEMODE.TeamLives[TEAM_HUNTERS])
end

function StartWinCheck()
    local firefliesAlive = GAMEMODE.TeamLives[TEAM_FIREFLIES] > 0
    local huntersAlive = GAMEMODE.TeamLives[TEAM_HUNTERS] > 0

    for _, ply in player.Iterator() do
        if IsValid(ply) then
            local isPlaying = ply:Alive() or (ply.NextRespawnTime ~= nil)

            if isPlaying then
                if ply:Team() == TEAM_FIREFLIES then
                    firefliesAlive = true
                elseif ply:Team() == TEAM_HUNTERS then
                    huntersAlive = true
                end
            end
        end
    end

    if not firefliesAlive or not huntersAlive then
        EndRound()
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
    
    ResetTeamLives()

    local players = {}
    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:ShouldSpawn() then
            table.insert(players, ply)
        end
    end

    AssignTeams(players)

    for _, ply in ipairs(players) do
        ply:Spawn()
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

    local postRoundTime = GetConVar("jf_round_post_time"):GetInt()
    timer.Simple(postRoundTime, function()
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

concommand.Add("jf_lives", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "You do not have permission to check team lives.")
        return
    end

    local firefliesLives = GAMEMODE.TeamLives[TEAM_FIREFLIES] or 0
    local huntersLives = GAMEMODE.TeamLives[TEAM_HUNTERS] or 0

    print("[Debug] Team Lives:")
    print("Fireflies: " .. firefliesLives)
    print("Hunters: " .. huntersLives)
end)