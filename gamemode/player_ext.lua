local meta = FindMetaTable("Player")

function meta:ShouldSpawn()
    if self:IsSpectator() and GetRoundState() ~= ROUND_WAITING and GetRoundState() ~= ROUND_STARTING then
        return false
    end

    return true
end