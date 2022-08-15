local PANEL = {}

function PANEL:Init()
    NebulaTarot.Store = self
    NebulaTarot.Controller = {}
    local mx, my = ScrW() * .05, ScrH() * .05
    self:SetSize(ScrW(), ScrH())
    self:DockPadding(mx, my, mx, my)
    self:SetAlpha(0)
    self:AlphaTo(255, .25, 0)
    self:ShowCloseButton(false)
    self.Foot = vgui.Create("nebula.button", self)
    self.Foot:Dock(BOTTOM)
    self.Foot:DockMargin(mx * 4, 0, mx * 4, 0)
    self.Foot:SetTall(64)
    self.Foot:SetText("Close")

    self.Foot.DoClick = function(s)
        self:SetMouseInputEnabled(false)
        self:KillFocus()
        gui.EnableScreenClicker(false)

        self:AlphaTo(0, .15, 0, function()
            self:Remove()
        end)
    end

    self.Scene = vgui.Create("DPanel", self)
    self.Scene:Dock(LEFT)
    self.Inventory = vgui.Create("DPanel", self)
    self.Inventory:Dock(FILL)
    self:InvalidateLayout(true)
    self:SetupScene()
    self:SetupInventory()
    self:MakePopup()
    self.start = SysTime()
end

function PANEL:SetupScene()
    self.Scene:DockMargin(0, 0, 16, 16)

    self.Scene.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10))
        draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(19, 4, 17, 240))
    end

    self.Buy = vgui.Create("nebula.button", self.Scene)
    self.Buy:SetText("Buy a card")
    self.Buy:SetSize(256, 64)
    self.Buy:SetFont(NebulaUI:Font(32))
    self.Buy:CenterHorizontal(.5)
    self.Buy:SetContentAlignment(8)
    self.Buy:SetTextInset(0, 2)

    self.Buy.PaintOver = function(s, w, h)
        draw.SimpleText(DarkRP.formatMoney(NebulaTarot.CardPrice), NebulaUI:Font(24), w / 2, h - 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.Buy:AlignBottom(48)

    self.Buy.DoClick = function(s)
        if not LocalPlayer():canAfford(NebulaTarot.CardPrice) then
            Derma_Message("You cannot afford a card!", "Error", "Ok")

            return
        end

        net.Start("Nebula.Tarot:BuyCard")
        net.SendToServer()
    end

    self.Model = vgui.Create("DModelPanel", self.Scene)
    self.Model:SetModel("models/nebularp/tarot.mdl")
    self.Model:SetFOV(55)
    self.Model:SetMouseInputEnabled(false)

    self.Model.PreDrawModel = function(s, ent)
        render.SuppressEngineLighting(true)
        ent:DrawModel()

        if s.Part then
            local pos, ang = ent:GetBonePosition(0)
            s.Part:Render()
            s.Part:SetControlPoint(0, pos - ang:Right() * 12)
            s.Part:SetControlPoint(1, pos + ang:Right() * 12)
            s.Part:SetControlPoint(2, pos)
            s.Part:SetControlPoint(3, pos + ang:Up() * 4)
        end

        render.SuppressEngineLighting(false)

        return false
    end

    self.Model.LayoutEntity = function(s, ent)
        if not s.IsOpening then
            ent:SetLocalAngles(Angle(0, 20, -10))
            ent:SetSequence("off")

            return
        end

        s.Progress = math.Clamp(s.Progress + FrameTime(), 0, s.Duration)
        local progress = s.Progress / s.Duration
        ent:SetSequence("show")
        ent:SetCycle(progress * s.Max)
    end

    self.Model:SetCamPos(Vector(0, -80, 0))
    self.Model:SetLookAt(Vector(0, 0, 0))
    self.Model:Dock(FILL)
end

function PANEL:AddReward(id)
    local info = NebulaTarot.Cards[id]
    if not info then return end
    self.Model:GetEntity():SetSkin(info.Skin)
    self.Model:GetEntity():SetLocalPos(Vector(0, 0, -16))
    self.Model:GetEntity():SetLocalAngles(Angle(0, 0, 0))
    self.Model.IsOpening = true
    self.Model.Progress = 0
    self.Model.Duration = 4
    self.Model.Max = .75
end

local parcial = Color(255, 255, 255, 20)

function PANEL:SetupInventory()
    self.Inventory.Paint = function(s, w, h)
        draw.SimpleText("Your Cards:", NebulaUI:Font(48), 0, 0, color_white)
    end

    self.Inventory:DockPadding(0, 54, 0, 0)
    self:InvalidateLayout(true)
    self.Inventory:InvalidateLayout(true)
    local tall = ((self.Inventory:GetTall() - 60) / 7) - 8
    local i = 0

    for k, v in SortedPairsByMemberValue(NebulaTarot.Cards, "Rarity") do
        if k == "base" then continue end
        local btn = vgui.Create("DButton", self.Inventory)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 8)
        btn:SetTall(tall)
        btn:SetText("")
        btn.Amount = LocalPlayer():getCards()[k] or 0

        btn.Paint = function(s, w, h)
            local pad = s:IsHovered() and 2 or 1
            draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10 * pad))
            draw.RoundedBox(4, pad, pad, w - pad * 2, h - pad * 2, Color(36, 10, 34, 204))
            draw.SimpleText(v.Name, NebulaUI:Font(28), tall - 24, 0, color_white)
            draw.SimpleText(s.Amount .. "/" .. v.Max, NebulaUI:Font(28), w - 16, 4, s.Amount > 0 and color_white or Color(255, 255, 255, 50), TEXT_ALIGN_RIGHT)

            if s.mk then
                s.mk:Draw(tall - 24, 32)
            end
        end

        btn.Card = vgui.Create("DModelPanel", btn)
        btn.Card:Dock(LEFT)
        btn.Card:SetWide(tall * .7)
        btn.Card:SetModel("models/nebularp/tarot.mdl")
        btn.Card:SetMouseInputEnabled(false)
        btn.Card:GetEntity():SetSkin(v.Skin)

        btn.Card.PreDrawModel = function(s, ent)
            render.SuppressEngineLighting(true)
            ent:DrawModel()
            render.SuppressEngineLighting(false)

            return false
        end

        btn.Card.LayoutEntity = function(s, ent)
            ent:SetSequence("off")
        end

        btn.Card:SetCamPos(Vector(-4, -20, 0))
        btn.Card:SetLookAt(Vector(0, 10, 0))
        btn.mk = markup.Parse("<font=" .. NebulaUI:Font(14) .. ">" .. v.Help .. "</font>", self.Inventory:GetWide() - 96)
        btn.bottom = vgui.Create("nebula.button", btn)
        btn.bottom:Dock(BOTTOM)
        btn.bottom:DockMargin(4, 0, 8, 8)
        btn.bottom:SetTall(24)

        btn.bottom.Think = function(s)
            if not s:IsHovered() then return end
            local w, _ = s:GetSize()
            local point = s:ScreenToLocal(gui.MouseX(), gui.MouseY())
            local val = 2

            if point < w / 2 - w / 6 then
                val = 1
            elseif point > w / 2 + w / 6 then
                val = 3
            end

            s.hovering = val
        end

        btn.bottom.id = k

        btn.bottom.PaintOver = function(s, w, h)
            if s:IsHovered() then
                local equipedTable = NebulaTarot.Favorites
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(w / 2 - w / 6, 2, 2, h - 4)
                surface.DrawTexturedRect(w / 2 + w / 6 - 2, 2, 2, h - 4)
                draw.SimpleText("1", NebulaUI:Font(20), w / 6, h / 2, (s.hovering == 1 or (NebulaTarot.Favorites[1] == s.id)) and color_white or parcial, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("2", NebulaUI:Font(20), w / 2, h / 2, (s.hovering == 2 or (NebulaTarot.Favorites[2] == s.id)) and color_white or parcial, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("3", NebulaUI:Font(20), w - w / 6, h / 2, (s.hovering == 3 or (NebulaTarot.Favorites[3] == s.id)) and color_white or parcial, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        btn.bottom.OnCursorEntered = function(s)
            s:SetText("")
        end

        btn.bottom.OnCursorExited = function(s)
            local found = false

            for si = 1, 3 do
                if NebulaTarot.Favorites[si] == s.id then
                    s:SetText("(SLOT " .. si .. ")")
                    found = true
                    break
                end
            end

            if not found then
                s:SetText("Equip")
            end

            for _, pnl in pairs(NebulaTarot.Controller) do
                if pnl == s then continue end
                pnl:OnCursorExited()
            end
        end

        btn.bottom:OnCursorExited()

        btn.bottom.DoClick = function(s)
            for k, v in pairs(NebulaTarot.Favorites) do
                if v == s.id then
                    NebulaTarot.Favorites[k] = nil
                end
            end

            local old = NebulaTarot.Controller[NebulaTarot.Favorites[s.hovering] or 1]

            if IsValid(old) and IsValid(old.bottom) then
                old.bottom:SetText("Equip")
            end

            local repeated = s.selected and s.selected == s.id
            NebulaTarot.Favorites[s.hovering] = not repeated and s.id or nil
            s.selected = s.hovering
            cookie.Set("cards_equipped", util.TableToJSON(NebulaTarot.Favorites))
            NebulaTarot:CreateHUD()
        end

        NebulaTarot.Controller[k] = btn
        i = i + 1
    end
end

function PANEL:PerformLayout(w, h)
    self.Scene:SetWide(w * 0.7)
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h)
    Derma_DrawBackgroundBlur(self, self.start)
end

vgui.Register("nebulaui.tarot.store", PANEL, "DFrame")

timer.Simple(1, function()
    NebulaTarot.Favorites = util.JSONToTable(cookie.GetString("cards_equipped", "[]"))
end)

net.Receive("Nebula.Tarot:BuyCard", function()
    local result = net.ReadString()

    if IsValid(NebulaTarot.Store) then
        NebulaTarot.Store.Model.Part = CreateParticleSystem(NebulaTarot.Store.Model:GetEntity(), "tarot_card", PATTACH_ABSORIGIN_FOLLOW, 0, Vector(0, 0, 0))
        NebulaTarot.Store.Model.Part:SetShouldDraw(false)
        NebulaTarot.Store:AddReward(result)

        timer.Simple(1, function()
            if not IsValid(NebulaTarot.Controller[result]) then return end
            NebulaTarot.Controller[result].Amount = LocalPlayer():getCards()[result]
        end)
    end
end)

if IsValid(NebulaTarot.Store) then
    NebulaTarot.Store:Remove()
end