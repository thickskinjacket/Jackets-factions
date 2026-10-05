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

JF_CONFIG = JF_CONFIG or {}

JF_CONFIG.WEAPON_TIER_MULTIPLIERS = {
    ["tlou_variablerifle"] = {
        [1] = { rpm = 1, accuracy = 1, recoil = 0.1 },
        [2] = { rpm = 1.08, accuracy = 0.9, recoil = 0.1 },
        [3] = { rpm = 1.16, accuracy = 0.8, recoil = 0.1 }
    }
}

JF_CONFIG.WEAPON_POOLS = {
	LONG_GUN = {
		{
			class = "tlou_burstrifle",
			ammo = { start = 15, cost = 120, bullets = 3 }
		},
		{
			class = "tlou_frontier",
			ammo = { start = 6, cost = 225, bullets = 3 }
		},
		{
			class = "tlou_huntingrifle",
			ammo = { start = 5, cost = 240, bullets = 3 }
		},
		{
			class = "tlou_semiauto",
			ammo = { start = 7, cost = 220, bullets = 4 }
		},
		{
			class = "tlou_fullautorifle",
			ammo = { start = 12, cost = 200, bullets = 5 }
		},
		{
			class = "tlou_tacshotgun",
			ammo = { start = 5, cost = 210, bullets = 3 }
		},
		{
			class = "tlou_variablerifle",
			ammo = { start = 9, cost = 150, bullets = 5 }
		},
	},
	SIDE_ARM = {
		{
			class = "tlou_9mm",
			ammo = { start = 10, cost = 150, bullets = 5 }
		},
		{
			class = "tlou_burstpistol",
			ammo = { start = 12, cost = 120, bullets = 3 }
		},
		{
			class = "tlou_enforcer",
			ammo = { start = 60, cost = 160, bullets = 5 }
		},
		{
			class = "tlou_revolver",
			ammo = { start = 7, cost = 180, bullets = 4 }
		},
		{
			class = "tlou_shorty",
			ammo = { start = 7, cost = 75, bullets = 1 }
		},

	},
	BUYABLE_GUNS = {
		{
			class = "tlou_dbarrel",
			ammo = { start = 4, cost = 280, bullets = 4 },
			buyCost = 240
		},
		{
			class = "tlou_specter",
			ammo = { start = 15, cost = 390, bullets = 15 }, // 390 --> 465
			buyCost = 315
		},
		{
			class = "tlou_woodshotgun",
			ammo = { start = 2, cost = 480, bullets = 2 },
			buyCost = 400
		},
		{
			class = "tlou_assaultrifle",
			ammo = { start = 10, cost = 380, bullets = 10 },
			buyCost = 300
		},
		{
			class = "tlou_militarysniper",
			ammo = { start = 4, cost = 480, bullets = 4 },
			buyCost = 400
		},
		{
			class = "tlou_diablo",
			ammo = { start = 3, cost = 315, bullets = 3 },
			buyCost = 270
		},
	}
}

PART_REWARDS = {
    DOWN = {
        amount = 100,
        message = "Downed Enemy"
    },
	ASSIST = {
		amount = 50,
		message = "Assist"
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
	CRAFT_ITEM = {
		amount = 30,
		message = "Craft Item"
	},
	MARKED_TARGET_DOWNED = {
		amount = 25,
		message = "Marked Target Downed"
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

JF_CONFIG.PLAYER_MODELS = {
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