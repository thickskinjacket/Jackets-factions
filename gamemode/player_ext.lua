local meta = FindMetaTable("Player")

function meta:SetParts(amount)
    self:SetNWInt("jf_parts", math.max(0, math.floor(amount)))
end

function meta:GetParts()
    return self:GetNWInt("jf_parts", 0)
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