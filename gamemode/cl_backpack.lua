local backgroundColor = Color(0, 0, 0, 200) 

local backpack = {
    isOpen = false,
    panel = nil
}

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
    function rightPanel:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, backgroundColor)
    end

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