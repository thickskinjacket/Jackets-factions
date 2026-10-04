GM.Name = "Garry's Factions"
GM.Author = "thickskinjacket"

DeriveGamemode("sandbox")

ROUND_WAITING = 0
ROUND_STARTING = 1
ROUND_ACTIVE = 2
ROUND_OVER = 3

TEAM_FIREFLIES = 1
TEAM_HUNTERS = 2

function GM:CreateTeams()
	team.SetUp(TEAM_FIREFLIES, "Fireflies", Color(255, 0, 0), true)
	team.SetUp(TEAM_HUNTERS, "Hunters", Color(0, 0, 255), true)

	team.SetSpawnPoint(TEAM_FIREFLIES, "info_player_deathmatch")
   	team.SetSpawnPoint(TEAM_HUNTERS, "info_player_deathmatch")
end

function GM:Initialize()
	-- Do stuff
end