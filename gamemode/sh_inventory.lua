local meta = FindMetaTable("Player")

local maxPerItem = 3

local itemModels = {
    blade = "models/props_junk/garbage_glassbottle003a_chunk02.mdl",
    alcohol = "models/props_junk/PopCan01a.mdl",
    rag = "models/weapons/csgo/atts/silencer_clothwrapped.mdl",
    explosive = "models/props_junk/garbage_bag001a.mdl",
    sugar = "models/props_junk/metal_paintcan001b.mdl",
    binding = "models/weapons/w_package.mdl"
}

local function GetInventoryKey(item)
    return "inventory_" .. item
end

function meta:GetItemModel(item)
    return itemModels[string.lower(item)]
end

function meta:InitializeInventory()
    self.inventory = {
        blade = 0,
        binding = 0,
        rag = 0,
        alcohol = 0,
        explosive = 0,
        sugar = 0
    }
end

function meta:SetItemCount(item, amount)
    item = string.lower(item)
    if not amount then return false end

    self.inventory = self.inventory or {}
    self.inventory[item] = math.Clamp(math.floor(amount), 0, maxPerItem)
    self:SetNWInt(GetInventoryKey(item), self.inventory[item])

    return true
end

function meta:GetItemCount(item)
    item = string.lower(item)
    self.inventory = self.inventory or {}
    self.inventory[item] = self:GetNWInt(GetInventoryKey(item), self.inventory[item] or 0)

    return self.inventory[item]
end

function meta:AddItem(item, amount)
    item = string.lower(item)
    if amount <= 0 then return false end

    local currentAmount = self:GetItemCount(item)
    if currentAmount + amount > maxPerItem then return false end

    self:SetItemCount(item, currentAmount + amount)

    return true
end

function meta:RemoveItem(item, amount)
    item = string.lower(item)
    if amount <= 0 then return false end

    local currentAmount = self:GetItemCount(item)
    if currentAmount < amount then return false end

    self:SetItemCount(item, currentAmount - amount)

    return true
end

function meta:HasItem(item)
    return self:GetItemCount(item) > 0
end

function meta:GetInventory()
    return self.inventory or {}
end

hook.Add("PlayerInitialSpawn", "InitializePlayerInventory", function(player)
    player:InitializeInventory()
end)

if SERVER then
    concommand.Add("inventory", function(player)
        if not IsValid(player) then return end

        local inventory = player:GetInventory()
        local items = {}

        for item, amount in pairs(inventory) do
            items[#items + 1] = item .. ": " .. amount
        end

        table.sort(items)
        player:ChatPrint("Inventory: " .. table.concat(items, ", "))
    end)
end
