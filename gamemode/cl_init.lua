include("shared.lua")
include("cl_fonts.lua")
include("cl_hud.lua")
include("cl_revive.lua")
include("cl_radar.lua")
include("cl_backpack.lua")

CreateConVar("jf_spectator", "0", FCVAR_ARCHIVE)

cvars.AddChangeCallback("jf_spectator", function(_, _, newValue)
    net.Start("JF_SetSpectator")
        net.WriteBool(tonumber(newValue) == 1)
    net.SendToServer()
end, "JF_SpectatorSync")

hook.Add("InitPostEntity", "JF_SyncSpectatorState", function()
    net.Start("JF_SetSpectator")
        net.WriteBool(GetConVar("jf_spectator"):GetBool())
    net.SendToServer()
end)

hook.Add("SpawnMenuOpen", "JF_AdminOnlySpawnMenu", function()
    if not LocalPlayer():IsAdmin() then
        return false
    end
end)

hook.Add("ContextMenuOpen", "JF_AdminOnlyContextMenu", function()
    if not LocalPlayer():IsAdmin() then
        return false
    end
end)

local function ReceiveRoundState()
    GAMEMODE.round_state = net.ReadUInt(3)
end
net.Receive("JF_NotifyRoundState", ReceiveRoundState)

local function ApplyClientWeaponTier(weapon, tier)
    if not IsValid(weapon) then
        ErrorNoHalt("[Jacket's Factions] Cannot apply weapon tier to an invalid client weapon.\n")
        return
    end

    local tierConfig = JF_CONFIG.WEAPON_TIER_MULTIPLIERS[tier]
    local recoilMultiplier = tierConfig.recoil
    local clipSizeMultiplier = tierConfig.clipSize

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

    weapon.Primary_TFA = weapon.Primary_TFA or weapon.Primary
    weapon.JFTierBaseClipSize = weapon.JFTierBaseClipSize or weapon.Primary_TFA.ClipSize
    weapon.Primary_TFA.ClipSize = math.max(1, math.floor(weapon.JFTierBaseClipSize * clipSizeMultiplier + 0.5))
    weapon:ClearStatCache("Primary.ClipSize")

    weapon.JFTier = tier
end

net.Receive("JF_ApplyWeaponTier", function()
    local weapon = net.ReadEntity()
    local tier = net.ReadUInt(2)
    ApplyClientWeaponTier(weapon, tier)
end)