include("shared.lua")
include("cl_fonts.lua")
include("cl_hud.lua")
include("cl_revive.lua")
include("cl_radar.lua")

CreateConVar("jf_spectator", "0", FCVAR_ARCHIVE)

local function ReceiveRoundState()
    GAMEMODE.round_state = net.ReadUInt(3)
end
net.Receive("JF_NotifyRoundState", ReceiveRoundState)

local function ApplyClientWeaponTier(weapon, tier)
    if not IsValid(weapon) then
        ErrorNoHalt("[Jacket's Factions] Cannot apply weapon tier to an invalid client weapon.\n")
        return
    end

    local weaponClass = weapon:GetClass()
    local tierConfig = JF_CONFIG.WEAPON_TIER_MULTIPLIERS[weaponClass][tier]
    local recoilMultiplier = tierConfig.recoil

    if weapon.RecoilTable and not weapon.JFTierBaseRecoilTable then
        weapon.JFTierBaseRecoilTable = {}

        for index, recoil in ipairs(weapon.RecoilTable) do
            weapon.JFTierBaseRecoilTable[index] = Angle(recoil.p, recoil.y, recoil.r)
        end
    end

    if weapon.JFTierBaseRecoilTable then
        weapon.RecoilTable = {}

        for index, recoil in ipairs(weapon.JFTierBaseRecoilTable) do
            weapon.RecoilTable[index] = Angle(
                recoil.p * recoilMultiplier,
                recoil.y * recoilMultiplier,
                recoil.r * recoilMultiplier
            )
        end
    end

    weapon.JFTier = tier
end

net.Receive("JF_ApplyWeaponTier", function()
    local weapon = net.ReadEntity()
    local tier = net.ReadUInt(2)
    ApplyClientWeaponTier(weapon, tier)
end)