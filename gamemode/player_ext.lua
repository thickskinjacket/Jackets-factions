local meta = FindMetaTable("Player")

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

function meta:SetParts(amount)
    self:SetNWInt("jf_parts", math.max(0, math.floor(amount)))
end

function meta:GetParts()
    return self:GetNWInt("jf_parts", 0)
end

function meta:AddParts(reward)
    if not reward or not isnumber(reward.amount) or reward.amount < 0 then return false end

    self:SetParts(self:GetParts() + math.floor(reward.amount))
    return true
end

function meta:SpendParts(amount)
    amount = math.floor(amount)
    if amount < 0 or self:GetParts() < amount then return false end

    self:SetParts(self:GetParts() - amount)
    return true
end

function meta:ShouldSpawn()
    if self:IsSpectator() and GetRoundState() ~= ROUND_WAITING and GetRoundState() ~= ROUND_STARTING then
        return false
    end

    return true
end