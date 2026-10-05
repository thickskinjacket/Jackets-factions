local TFA_OVERRIDES = {
    ["tlou_diablo"] = {
        Attachments = {
            [1] = {
                atts = {
                    "tlou_scope_2x"
                },
                sel = 1
            }
        }
    },
    ["tlou_huntingrifle"] = {
        Attachments = {
            [2] = {
                atts = {
                    "tlou_scope_4x"
                },
                sel = 1
            }
        }
    },
    ["tlou_specter"] = {
        Attachments = {
            [1] = {
                atts = {
                    "tlou_silencer"
                },
                sel = 1
            }
        }
    },
    ["tlou_variablerifle"] = {
        Attachments = {
            [2] = {
                atts = {
                    "tlou_scope_2x"
                },
                sel = 1
            }
        }
    }
}

local function MergeTFASettings(target, settings)
    for settingName, value in pairs(settings) do
        if istable(value) and istable(target[settingName]) then
            MergeTFASettings(target[settingName], value)
        else
            target[settingName] = value
        end
    end
end

local function ApplyTFAOverride(className, settings)
    local weapon = weapons.GetStored(className)
    if not weapon then
        ErrorNoHalt(string.format("[[Jacket's Factions] TFA weapon not found: %s\n", className))
        return
    end

    for sectionName, sectionSettings in pairs(settings) do
        if not istable(sectionSettings) then
            ErrorNoHalt(string.format(
                "[Jacket's Factions] Invalid TFA settings section '%s' for %s\n",
                sectionName,
                className
            ))
            continue
        end

        weapon[sectionName] = weapon[sectionName] or {}
        MergeTFASettings(weapon[sectionName], sectionSettings)
    end

    print("[Jacket's Factions] Applied TFA override: " .. className)
end

local function ApplyTFAOverrides()
    for className, settings in pairs(TFA_OVERRIDES) do
        ApplyTFAOverride(className, settings)
    end
end

timer.Simple(0, ApplyTFAOverrides)
