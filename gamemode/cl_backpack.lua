local backgroundColor = Color(0, 0, 0, 200) 

local backpack = {
    isOpen = false,
    panel = nil
}
JF_Backpack = backpack

function backpack:Create()
    if IsValid(self.panel) then
        self.panel:Remove()
    end

    local frameW, frameH = ScrW() / 2, ScrH()

    local frame = vgui.Create("DPanel")
    frame:MakePopup()
    frame:SetSize(frameW, frameH)
    frame:SetPos(ScrW() / 2, 0)
    function frame:Paint() end
    function frame:OnKeyCodePressed(key)
        if key == KEY_Q then
            backpack:Close()
        end
    end

    local leftPanel = vgui.Create("DPanel", frame)
    leftPanel:Dock(LEFT)
    leftPanel:SetWide(frameW * 0.15)
    leftPanel:DockMargin(0, 0, 50, 0)
    function leftPanel:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, backgroundColor)
    end

    local rightPanel = vgui.Create("DPanel", frame)
    rightPanel:Dock(FILL)
    rightPanel:DockMargin(0, 0, 100, 0)
    rightPanel:DockPadding(32, 64, 32, 64)
    function rightPanel:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, backgroundColor)
    end

    local tabs = vgui.Create("DPropertySheet", rightPanel)
    tabs:Dock(TOP)
    tabs:SetTall(64)
    function tabs:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
    end

    // CRAFTING TAB

    local craftingPanel = vgui.Create("DPanel", rightPanel)
    craftingPanel:Dock(FILL)
    function craftingPanel:Paint(w, h) 
        draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
    end

    local craftingLabel = vgui.Create("DLabel", craftingPanel)
    craftingLabel:SetText("CRAFTING")
    craftingLabel:SetFont("textFont")
    craftingLabel:SizeToContents()
    craftingLabel:Dock(TOP)
    function craftingLabel:Paint(w, h)
        surface.SetDrawColor(255, 255, 255, 255)

        surface.DrawRect(0, 0, w, 1)
        surface.DrawRect(0, h - 1, w, 1)
    end

    local selectedItemPanel = vgui.Create("DPanel", craftingPanel)
    selectedItemPanel:Dock(TOP)
    selectedItemPanel:SetTall(100)
    selectedItemPanel:DockPadding(0, 8, 0, 8)
    function selectedItemPanel:Paint(w, h) 
        draw.RoundedBox(0, 0, 0, w, h, Color(100, 100, 255, 255))
    end

    local selectedItemIcon = vgui.Create("DImage", selectedItemPanel)
    selectedItemIcon:Dock(LEFT)
    selectedItemIcon:SetWide(selectedItemPanel:GetTall() - 16)
    selectedItemIcon:SetTall(selectedItemPanel:GetTall() - 16)
    function selectedItemIcon:Paint(w, h) 
        surface.SetDrawColor(255, 255, 255, 255)
        draw.RoundedBox(0, 0, 0, w, h, Color(150, 255, 150, 255))
    end

    local selectedItemDetailsPanel = vgui.Create("DPanel", selectedItemPanel)
    selectedItemDetailsPanel:Dock(FILL)
    function selectedItemDetailsPanel:Paint(w, h) 
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 150, 150, 255))
    end

    local selectedItemNameLabel = vgui.Create("DLabel", selectedItemDetailsPanel)
    selectedItemNameLabel:Dock(TOP)
    selectedItemNameLabel:SetText("ITEM NAME")
    selectedItemNameLabel:SetFont("textFont")
    selectedItemNameLabel:SetTextColor(Color(255, 255, 255, 255))
    
    local selectedItemDescriptionLabel = vgui.Create("DLabel", selectedItemDetailsPanel)
    selectedItemDescriptionLabel:Dock(TOP)
    selectedItemDescriptionLabel:SetText("Item description goes here.")
    selectedItemDescriptionLabel:SetFont("TLOU_Font_Ammo_Small")
    selectedItemDescriptionLabel:SetTextColor(Color(255, 255, 255, 255))

    local selectedItemCraftButton = vgui.Create("DLabel", selectedItemDetailsPanel)
    selectedItemCraftButton:Dock(TOP)
    selectedItemCraftButton:SetText("HOLD X TO CRAFT")
    selectedItemCraftButton:SetFont("textFont")
    selectedItemCraftButton:SetTextColor(Color(255, 255, 255, 255))

    local itemsPanel = vgui.Create("DPanel", craftingPanel)
    itemsPanel:Dock(FILL)
    itemsPanel:DockPadding(0, 16, 0, 16)
    function itemsPanel:Paint(w, h) end

    local collectibleItems = {
        "blade",
        "binding",
        "rag",
        "alcohol",
        "explosive",
        "sugar"
    }

    for _, itemName in ipairs(collectibleItems) do
        local itemRow = vgui.Create("DPanel", itemsPanel)
        itemRow:Dock(TOP)
        itemRow:SetTall(40)
        itemRow:DockMargin(0, 0, 0, 8)
        function itemRow:Paint() end

        local itemLabel = vgui.Create("DLabel", itemRow)
        itemLabel:Dock(LEFT)
        itemLabel:SetWide(120)
        itemLabel:SetText(string.upper(itemName))
        itemLabel:SetFont("textFont")
        itemLabel:SetTextColor(Color(255, 255, 255, 255))

        local itemSlots = vgui.Create("DPanel", itemRow)
        itemSlots:Dock(LEFT)
        itemSlots:SetWide(3 * 32 + 2 * 8)
        function itemSlots:Paint() end

        for slot = 1, 3 do
            local itemSlot = vgui.Create("DPanel", itemSlots)
            itemSlot:Dock(LEFT)
            itemSlot:SetSize(32, 32)
            itemSlot:DockMargin(0, 4, slot < 3 and 8 or 0, 4)
            function itemSlot:Paint(w, h)
                local itemCount = LocalPlayer():GetItemCount(itemName)
                local color = slot <= itemCount and Color(255, 255, 255, 255) or Color(100, 100, 100, 255)
                draw.RoundedBox(0, 0, 0, w, h, color)
            end
        end
    end

    // CRAFTING TAB

    // INVENTORY TAB

    -- local weaponsPanel = vgui.Create("DPanel", rightPanel)
    -- weaponsPanel:Dock(FILL)
    -- function weaponsPanel:Paint(w, h) 
    --     draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
    -- end

    -- local weaponsLabel = vgui.Create("DLabel", weaponsPanel)
    -- weaponsLabel:SetText("Weapons")
    -- weaponsLabel:SetFont("textFont")
    -- weaponsLabel:SizeToContents()
    -- weaponsLabel:Dock(TOP)
    -- weaponsLabel:DockPadding(0, 8, 0, 8)
    -- function weaponsLabel:Paint(w, h)
    --     surface.SetDrawColor(255, 255, 255, 255)

    --     surface.DrawRect(0, 0, w, 1)
    --     surface.DrawRect(0, h - 1, w, 1)
    -- end

    // INVENTORY TAB

    self.panel = frame
    self.isOpen = true
end

function backpack:Open()
    self.isOpen = true
end

function backpack:Close()
    self.isOpen = false
    if IsValid(self.panel) then
        self.panel:SetVisible(false)
    end
end

function backpack:Toggle()
    self.isOpen = not self.isOpen
    if self.isOpen then
        self:Open()
    else
        self:Close()
    end
end

hook.Add("PlayerBindPress", "JF_BackpackMenu", function(_, bind, pressed)
    if not pressed or string.Trim(string.lower(bind)) ~= "+menu" then return end

    if backpack.isOpen then
        backpack:Close()
    else
        backpack:Create()
    end

    return true
end)

hook.Add("CreateMove", "JF_BackpackStopMovement", function(cmd)
    if not backpack.isOpen then return end

    cmd:SetForwardMove(0)
    cmd:SetSideMove(0)
    cmd:SetUpMove(0)
end)