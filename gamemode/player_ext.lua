local meta = FindMetaTable("Player")

function meta:ShouldSpawn()
    if self:IsSpectator() then return false end
    
    return true
end