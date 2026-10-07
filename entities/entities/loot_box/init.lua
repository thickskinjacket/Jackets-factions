AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hello neighbor/alpha prop/toolbox.mdl")

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local physicsObject = self:GetPhysicsObject()
    if IsValid(physicsObject) then
        physicsObject:Wake()
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.ItemsReleased then return end

    self:SetBodygroup(1, 1)
    self.ItemsReleased = true

    local itemPool = {
        "blade",
        "binding",
        "rag",
        "alcohol",
        "explosive",
        "sugar"
    }

    for index = 1, math.random(1, 6) do
        local item = itemPool[math.random(#itemPool)]
        local model = activator:GetItemModel(item)

        local itemEntity = ents.Create("prop_physics")
        if IsValid(itemEntity) then
            local angle = math.Rand(0, math.pi * 2)
            local distance = math.Rand(25, 40)
            itemEntity:SetModel(model)
            itemEntity:SetPos(self:GetPos() + Vector(math.cos(angle) * distance, math.sin(angle) * distance, 20))
            itemEntity:Spawn()
            itemEntity:Activate()

            itemEntity.ItemName = item
            function itemEntity:Use(player)
                if not IsValid(player) or not player:IsPlayer() then return end
                if not player:AddItem(self.ItemName, 1) then return end

                self:Remove()
            end
        end
    end
end
