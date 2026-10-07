AddCSLuaFile("shared.lua")
include("shared.lua")

local LOOTBOX_RESET_DELAY = 150

function ENT:Initialize()
    self:SetModel("models/hello neighbor/alpha prop/toolbox.mdl")
    self:SetNWBool("jf_lootbox_open", false)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local physicsObject = self:GetPhysicsObject()
    if IsValid(physicsObject) then
        physicsObject:Wake()

        timer.Simple(1, function()
            if not IsValid(self) then return end

            local physicsObject = self:GetPhysicsObject()
            if IsValid(physicsObject) then
                physicsObject:EnableMotion(false)
            end
        end)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.ItemsReleased then return end

    self:SetBodygroup(1, 1)
    self.ItemsReleased = true
    self:SetNWBool("jf_lootbox_open", true)

    timer.Simple(LOOTBOX_RESET_DELAY, function()
        if not IsValid(self) then return end

        self:SetBodygroup(1, 0)
        self.ItemsReleased = false
        self:SetNWBool("jf_lootbox_open", false)
    end)

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

            local itemPosition = self:GetPos() + Vector(math.cos(angle) * distance, math.sin(angle) * distance, 100)
            local trace = util.TraceLine({
                start = itemPosition,
                endpos = itemPosition - Vector(0, 0, 200),
                filter = {self, itemEntity}
            })

            itemEntity:Spawn()
            itemEntity:Activate()

            local minimums = itemEntity:OBBMins()
            if trace.Hit then
                itemPosition.z = trace.HitPos.z - minimums.z
            end

            itemEntity:SetPos(itemPosition)
            itemEntity:SetCollisionGroup(COLLISION_GROUP_WORLD)
            itemEntity:SetUseType(SIMPLE_USE)

            local physicsObject = itemEntity:GetPhysicsObject()
            if IsValid(physicsObject) then
                physicsObject:EnableMotion(false)
            end

            itemEntity.ItemName = item
        end
    end
end

hook.Add("PlayerUse", "LootBoxItemPickup", function(player, entity)
    if not entity.ItemName then return end
    if not player:AddItem(entity.ItemName, 1) then return false end

    entity:Remove()
    return false
end)
