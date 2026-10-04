local meta = FindMetaTable("Player")

function meta:IsSpectator()
    return self:Team() == TEAM_SPECTATOR
end