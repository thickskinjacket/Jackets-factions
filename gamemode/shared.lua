GM.Name = "Garry's Factions"
GM.Author = "thickskinjacket"

DeriveGamemode("sandbox")

include("sh_revive.lua")

ROUND_WAITING = 0
ROUND_STARTING = 1
ROUND_ACTIVE = 2
ROUND_OVER = 3

TEAM_FIREFLIES = 1
TEAM_HUNTERS = 2

PART_REWARDS = {
    DOWN = {
        amount = 100,
        message = "Downed Enemy"
    },
    LONG_RANGE_KILL = {
        amount = 30,
        message = "Long Range Kill"
    },
    HEADSHOT = {
        amount = 30,
        message = "Headshot"
    },
    EXECUTION = {
        amount = 50,
        message = "Execution"
    },
    REVIVE = {
        amount = 100,
        message = "Revive"
    },
    MARK = {
        amount = 15,
        message = "Marked Target"
    },
    RAMPAGE = {
        amount = 50,
        message = "Rampage"
    },
    REVENGE = {
        amount = 50,
        message = "Revenge"
    }
}

GAMEMODE.PLAYER_MODELS = {
    [TEAM_HUNTERS] = {
        "models/dizcordum/citizens/playermodels/p_female_01.mdl",
        "models/dizcordum/citizens/playermodels/p_female_02.mdl",
        "models/dizcordum/citizens/playermodels/p_female_03.mdl",
        "models/dizcordum/citizens/playermodels/p_female_04.mdl",
        "models/dizcordum/citizens/playermodels/p_female_05.mdl",
        "models/dizcordum/citizens/playermodels/p_female_06.mdl",
        "models/dizcordum/citizens/playermodels/p_female_07.mdl",
        "models/dizcordum/citizens/playermodels/p_female_08.mdl",
        "models/dizcordum/citizens/playermodels/p_female_09.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_01.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_01s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_01s2.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_02.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_02s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_02s2.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_03.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_03s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_03s2.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_04.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_04s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_04s2.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_05.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_05s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_05s2.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_06.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_06s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_06s21.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_07.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_07s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_07s2.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_08.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_08s1.mdl",
        "models/dizcordum/citizens/playermodels/pm_male_08s2.mdl"
    },
    [TEAM_FIREFLIES] = {
        "models/ninja/esp/rusty/merc/merc_brad_vest_1.mdl",
        "models/ninja/esp/rusty/merc/merc_brad_vest_1a.mdl",
        "models/ninja/esp/rusty/merc/merc_brad_vest_2.mdl",
        "models/ninja/esp/rusty/merc/merc_brad_vest_western_1.mdl",
        "models/ninja/esp/rusty/merc/merc_brad_vest_western_1a.mdl",
        "models/ninja/esp/rusty/merc/merc_brad_vest_western_2.mdl",
        "models/ninja/esp/rusty/merc/merc_hajaar_vest_1.mdl",
        "models/ninja/esp/rusty/merc/merc_hajaar_vest_1a.mdl",
        "models/ninja/esp/rusty/merc/merc_hajaar_vest_2.mdl",
        "models/ninja/esp/rusty/merc/merc_hajaar_vest_western_1.mdl",
        "models/ninja/esp/rusty/merc/merc_hajaar_vest_western_1a.mdl",
        "models/ninja/esp/rusty/merc/merc_hajaar_vest_western_2.mdl",
        "models/ninja/esp/rusty/merc/merc_jack_vest_1.mdl",
        "models/ninja/esp/rusty/merc/merc_jack_vest_1a.mdl",
        "models/ninja/esp/rusty/merc/merc_jack_vest_2.mdl",
        "models/ninja/esp/rusty/merc/merc_jack_vest_western_1.mdl",
        "models/ninja/esp/rusty/merc/merc_jack_vest_western_1a.mdl",
        "models/ninja/esp/rusty/merc/merc_jack_vest_western_2.mdl",
        "models/ninja/esp/rusty/merc/merc_steven_vest_1.mdl",
        "models/ninja/esp/rusty/merc/merc_steven_vest_2.mdl",
        "models/ninja/esp/rusty/merc/merc_steven_vest_western_1.mdl",
        "models/ninja/esp/rusty/merc/merc_steven_vest_western_2.mdl",
        "models/ninja/esp/rusty/militia1hoodie.mdl",
        "models/ninja/esp/rusty/militia1hoodie2.mdl",
        "models/ninja/esp/rusty/militia1hoodie3.mdl",
        "models/ninja/esp/rusty/militia1hoodie4.mdl",
        "models/ninja/esp/rusty/militia1hoodie5.mdl",
        "models/ninja/esp/rusty/militia1jacket.mdl",
        "models/ninja/esp/rusty/militia1jacket2.mdl",
        "models/ninja/esp/rusty/militia1jacket3.mdl",
        "models/ninja/esp/rusty/militia1jacket4.mdl",
        "models/ninja/esp/rusty/militia1jacket5.mdl",
        "models/ninja/esp/rusty/militia1shirt.mdl",
        "models/ninja/esp/rusty/militia1shirt2.mdl",
        "models/ninja/esp/rusty/militia1shirt3.mdl",
        "models/ninja/esp/rusty/militia1shirt4.mdl",
        "models/ninja/esp/rusty/militia1shirt5.mdl",
        "models/ninja/esp/rusty/militia2hoodie.mdl",
        "models/ninja/esp/rusty/militia2jacket2.mdl",
        "models/ninja/esp/rusty/militia2shirt3.mdl",
        "models/ninja/esp/rusty/militia3hoodie.mdl",
        "models/ninja/esp/rusty/militia3jacket2.mdl",
        "models/ninja/esp/rusty/militia3shirt3.mdl",
        "models/ninja/esp/rusty/militia4hoodie.mdl",
        "models/ninja/esp/rusty/militia4shirt3.mdl",
        "models/ninja/esp/rustynew/militiateelong.mdl"
    }
}

function GM:CreateTeams()
	team.SetUp(TEAM_FIREFLIES, "Fireflies", Color(244, 203, 63), true)
	team.SetUp(TEAM_HUNTERS, "Hunters", Color(64, 169, 233), true)

	team.SetSpawnPoint(TEAM_FIREFLIES, "info_player_deathmatch")
   	team.SetSpawnPoint(TEAM_HUNTERS, "info_player_deathmatch")
end

function GM:Initialize()
	-- Do stuff
end