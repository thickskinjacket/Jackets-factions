local TFA_OVERRIDES = {
    ["tlou_burstrifle"] = {
        Primary = {
            RPM = 500,
            ClipSize = 9
        }
    },
    ["tlou_frontier"] = {
        Primary = {
            RPM = 1000,
            ClipSize = 4
        }
    },
    ["tlou_huntingrifle"] = {
        Primary = {
            RPM = 150,
            ClipSize = 1
        },
        Attachments = {
            [2] = {
                atts = {
                    "tlou_scope_4x"
                },
                sel = 1
            }
        }
    },
    ["tlou_semiauto"] = {
        Primary = {
            RPM = 200,
            ClipSize = 8
        }
    },
    ["tlou_fullautorifle"] = {
        Primary = {
            RPM = 260,
            ClipSize = 8
        }
    },
    ["tlou_tacshotgun"] = {
        Primary = {
            RPM = 350,
            ClipSize = 3
        }
    },
    ["tlou_variablerifle"] = {
        Primary = {
            RPM = 400,
            ClipSize = 10
        },
        Attachments = {
            [2] = {
                atts = {
                    "tlou_scope_2x"
                },
                sel = 1
            }
        }
    },
    ["tlou_9mm"] = {
        Primary = {
            RPM = 300,
            ClipSize = 9
        }
    },
    ["tlou_burstpistol"] = {
        Primary = {
            RPM = 500,
            ClipSize = 9
        }
    },
    ["tlou_enforcer"] = {
        Primary = {
            RPM = 300,
            ClipSize = 7
        }
    },
    ["tlou_revolver"] = {
        Primary = {
            RPM = 180,
            ClipSize = 6
        }
    },
    ["tlou_shorty"] = {
        Primary = {
            RPM = 60,
            ClipSize = 2
        }
    },
    ["tlou_dbarrel"] = {
        Primary = {
            RPM = 300,
            ClipSize = 2
        }
    },
    ["tlou_diablo"] = {
        Primary = {
            RPM = 200,
            ClipSize = 6
        },
        Attachments = {
            [1] = {
                atts = {
                    "tlou_scope_2x"
                },
                sel = 1
            }
        }
    },
    ["tlou_specter"] = {
        Primary = {
            RPM = 700,
            ClipSize = 20
        },
        Attachments = {
            [1] = {
                atts = {
                    "tlou_silencer"
                },
                sel = 1
            }
        }
    },
    ["tlou_woodshotgun"] = {
        Primary = {
            RPM = 400,
            ClipSize = 6
        }
    },
    ["tlou_assaultrifle"] = {
        Primary = {
            RPM = 500,
            ClipSize = 20
        }
    },
    ["tlou_militarysniper"] = {
        Primary = {
            RPM = 500,
            ClipSize = 5
        }
    },
    ["tlou_ellies"] = {
        Primary = {
            RPM = 400,
            ClipSize = 6
        }
    },
    ["tlou_servicepistol"] = {
        Primary = {
            RPM = 200,
            ClipSize = 6
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
