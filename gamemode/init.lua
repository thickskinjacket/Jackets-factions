include("shared.lua")
include("player.lua")
include("player_ext.lua")
include("player_ext_shared.lua")
include("sv_workshop.lua")
include("sv_revive.lua")
include("sv_radar.lua")

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_revive.lua")
AddCSLuaFile("cl_fonts.lua")
AddCSLuaFile("sh_revive.lua")
AddCSLuaFile("cl_radar.lua")

resource.AddFile("materials/resource/fonts/D-DIN.ttf")
resource.AddFile("materials/resource/fonts/D-DIN-Bold.ttf")
resource.AddFile("materials/resource/fonts/D-DIN-Italic.ttf")
resource.AddFile("materials/resource/fonts/D-DINCondensed.ttf")
resource.AddFile("materials/resource/fonts/D-DINCondensed-Bold.ttf")
resource.AddFile("materials/resource/fonts/D-DINExp.ttf")
resource.AddFile("materials/resource/fonts/D-DINExp-Bold.ttf")
resource.AddFile("materials/resource/fonts/D-DINExp-Italic.ttf")
resource.AddFile("materials/hud/small-health.png")
resource.AddFile("materials/hud/up-arrow2.png")
resource.AddFile("materials/hud/man.png")


CreateConVar("jf_round_preparation_time", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("jf_round_time", "300", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("jf_round_post_time", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("jf_respawn_time", "5", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("jf_team_lives", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY})

util.AddNetworkString("JF_NotifyRoundState")
util.AddNetworkString("JF_SendRadarPosition")

local function GetRandomTeamModel(ply)
    local models = GAMEMODE.PLAYER_MODELS[ply:Team()]
    if not models or #models == 0 then return nil end

    return models[math.random(#models)]
end

function GM:PlayerSetModel(ply)
    local model = ply.JFTeamModel or GetRandomTeamModel(ply)
    if not model then return end

    ply.JFTeamModel = model
    ply:SetModel(model)
end

function GM:PlayerSpawn(ply)
    local model = ply.JFTeamModel or GetRandomTeamModel(ply)
    if not model then return end

    ply.JFTeamModel = model
    ply:SetModel(model)

    timer.Simple(0, function()
        if IsValid(ply) and ply:Alive() then
            self:GiveRoundLoadout(ply)
        end
    end)
end

function GM:GiveRoundLoadout(ply)
    local loadout = ply.JFRoundLoadout
    if not loadout then return end

    ply:StripWeapons()

    local longGun = ply:Give(loadout.longGun.class, true)
    local sideArm = ply:Give(loadout.sideArm.class, true)

    if not IsValid(longGun) then
        ErrorNoHalt(string.format("[Garrys Factions] Failed to give long gun '%s' to %s\n", loadout.longGun.class, ply:Nick()))
    end

    if not IsValid(sideArm) then
        ErrorNoHalt(string.format("[Garrys Factions] Failed to give sidearm '%s' to %s\n", loadout.sideArm.class, ply:Nick()))
    end

    local function SetStartingAmmo(weapon, weaponConfig)
        if not IsValid(weapon) then return end

        local ammoType = weapon:GetPrimaryAmmoType()
        if ammoType >= 0 then
            ply:SetAmmo(weaponConfig.ammo.start, ammoType)
        end
    end

    SetStartingAmmo(longGun, loadout.longGun)
    SetStartingAmmo(sideArm, loadout.sideArm)

    if IsValid(longGun) then
        ply:SelectWeapon(longGun:GetClass())
    elseif IsValid(sideArm) then
        ply:SelectWeapon(sideArm:GetClass())
    end
end

function GM:PlayerLoadout(ply)
    self:GiveRoundLoadout(ply)
    return false
end

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
    for i = #players, 2, -1 do
        local randomIndex = math.random(i)
        players[i], players[randomIndex] = players[randomIndex], players[i]
    end

    for i, ply in ipairs(players) do
        local plyTeam = i % 2 == 0 and TEAM_FIREFLIES or TEAM_HUNTERS
        ply:SetTeam(plyTeam)
        ply.JFTeamModel = GetRandomTeamModel(ply)
    end
end

local function AssignRoundWeapons(players)
    local longGuns = GAMEMODE.WEAPON_POOLS.LONG_GUN
    local sideArms = GAMEMODE.WEAPON_POOLS.SIDE_ARM

    for _, ply in ipairs(players) do
        ply.JFRoundLoadout = {
            longGun = longGuns[math.random(#longGuns)],
            sideArm = sideArms[math.random(#sideArms)]
        }
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

local function SpawnRespawnWave()
    if GetRoundState() ~= ROUND_ACTIVE then return end

    for _, ply in player.Iterator() do
        if not IsValid(ply) or ply:Alive() or ply.NextRespawnWave ~= true then continue end

        ply:Spawn()
        ply.NextRespawnWave = nil

        local plyTeam = ply:Team()
        SetGlobalInt("jf_teamlives_" .. plyTeam, GAMEMODE.TeamLives[plyTeam])
    end
end

function StartWinCheck()
    local firefliesAlive = GAMEMODE.TeamLives[TEAM_FIREFLIES] > 0
    local huntersAlive = GAMEMODE.TeamLives[TEAM_HUNTERS] > 0

    for _, ply in player.Iterator() do
        if IsValid(ply) then
            local isPlaying = ply:Alive() or ply.NextRespawnWave == true

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
    timer.Remove("jf_respawn_wave")

    print("Preparing round...")
    local roundTime = GetConVar("jf_round_time"):GetInt()
    SetRoundEnd(CurTime() + roundTime)
    
    ResetTeamLives()

    local players = {}
    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:ShouldSpawn() then
            ply:SetParts(0)
            table.insert(players, ply)
        end
    end

    AssignTeams(players)
    AssignRoundWeapons(players)

    for _, ply in ipairs(players) do
        ply.NextRespawnWave = nil
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

    local respawnTime = math.max(GetConVar("jf_respawn_time"):GetFloat(), 1)
    timer.Create("jf_respawn_wave", respawnTime, 0, SpawnRespawnWave)

    timer.Create("jf_round_timer", roundTime, 1, function()
        EndRound()
    end)
end

function EndRound()
    SetRoundState(ROUND_OVER)
    timer.Remove("jf_respawn_wave")

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

concommand.Add("jf_set_team", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local teamID = tonumber(args[1])
    if not teamID then
        ply:PrintMessage(HUD_PRINTCONSOLE, "Usage: jf_set_team <team_number>")
        return
    end

    ply:SetTeam(teamID)
    ply:PrintMessage(HUD_PRINTCONSOLE, "You are now on team: " .. team.GetName(teamID))
end)