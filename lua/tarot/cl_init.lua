game.AddParticles("particles/nebula.pcf")
PrecacheParticleSystem("tarot_card")

if IsValid(NebulaTarot.Card) then
    NebulaTarot.Card:Remove()
    NebulaTarot.Card = nil
end

function NebulaTarot:ShowCard(id)
    if IsValid(NebulaTarot.Card) then
        NebulaTarot.Card:Remove()
        NebulaTarot.Card = nil
    end

    local pnl = vgui.Create("DModelPanel")
    NebulaTarot.Card = pnl
    surface.PlaySound("nebularp/gotohell.wav")
    surface.PlaySound("nebularp/gotohell.wav")
    pnl:SetSize(450, 600)
    pnl:SetPos(ScrW() / 2 - pnl:GetWide() / 2, ScrH() - pnl:GetTall())
    pnl:SetModel("models/nebularp/tarot.mdl")
    pnl:SetCamPos(Vector(0, -80, 40))
    pnl:SetFOV(50)
    pnl.Start = RealTime()
    pnl.Duration = 3
    pnl.Disabled = false
    pnl.Distance = 0

    pnl.LayoutEntity = function(s, ent)
        local cycle = 1 - math.Clamp(((s.Start + s.Duration) - RealTime()) / s.Duration, 0, 1)
        ent:SetCycle(cycle)

        if not s.Disabled and cycle >= .95 then
            s.Disabled = true
        elseif s.Disabled then
            s.Distance = s.Distance + FrameTime() * 48
            ent:SetLocalPos(Vector(0, 0, -s.Distance))

            if s.Distance >= 32 then
                s:Remove()
            end
        end
    end

    local noloop = false

    pnl.PreDrawModel = function(s, ent)
        if not noloop then
            noloop = true
            render.SuppressEngineLighting(true)

            if s.Part then
                local pos, ang = ent:GetBonePosition(0)
                s.Part:Render()
                s.Part:SetControlPoint(0, pos - ang:Right() * 12)
                s.Part:SetControlPoint(1, pos + ang:Right() * 12)
                s.Part:SetControlPoint(2, pos)
                s.Part:SetControlPoint(3, pos + ang:Up() * 4)
            end

            render.ResetModelLighting(1, 1, 1)
            render.SetModelLighting(BOX_TOP, 10, 15, 45)
            render.SetModelLighting(BOX_BOTTOM, 125, 25, 0)
            ent:DrawModel()
            render.SuppressEngineLighting(false)
            noloop = false
        end

        return false
    end

    local ent = pnl:GetEntity()
    ent:SetSkin(self.Cards[id].Skin)
    pnl.Part = CreateParticleSystem(ent, "tarot_card", PATTACH_ABSORIGIN_FOLLOW, 0, Vector(0, 0, 0))
    pnl.Part:SetShouldDraw(false)
    ent:ResetSequence("show")
end

function NebulaTarot:CreateParticle(ent)
    if ent.cardParticle then
        ent.cardParticle:StopEmissionAndDestroyImmediately()
        ent.cardParticle = nil
    end

    local Part = CreateParticleSystem(ent, "tarot_card", PATTACH_ABSORIGIN_FOLLOW, 0, Vector(0, 0, 0))
    Part:SetControlPoint(0, ent:GetShootPos() - Vector(0, 0, 32))
    Part:SetControlPoint(1, ent:GetShootPos())
    Part:SetControlPoint(2, ent:GetPos() + ent:OBBCenter())
    Part:SetControlPoint(3, ent:GetPos() + ent:OBBCenter())
    ent.cardParticle = Part
end

net.Receive("Nebula.Tarot:DoEffect", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    NebulaTarot:CreateParticle(ent)
end)

net.Receive("Nebula.Tarot:UpdateCards", function()
    local id = net.ReadString()
    local am = net.ReadUInt(8)

    if not LocalPlayer()._cards then
        LocalPlayer()._cards = {}
    end

    LocalPlayer()._cards[id] = am
end)

NebulaTarot.Favorites = NebulaTarot.Favorites or util.JSONToTable(cookie.GetString("cards_equipped", "[]"))

if IsValid(NebulaTarot.CardHUD) then
    NebulaTarot.CardHUD:Remove()
end

function NebulaTarot:CreateHUD()
    if IsValid(NebulaTarot.CardHUD) then
        NebulaTarot.CardHUD:Remove()
    end

    local dark = Material("gui/center_gradient")
    local black, white = Color(0, 0, 0, 200), Color(255, 255, 255, 25)
    local cards = vgui.Create("DPanel")
    cards:SetSize(48 * 3, 128)
    cards:AlignBottom(32)
    cards:AlignRight(300)

    cards.Paint = function(s, w, h)
        surface.SetMaterial(dark)
        surface.SetDrawColor(s.ShouldDisplay and white or black)
        surface.DrawTexturedRect(0, h - 32, w, 32)
        draw.SimpleText("[T] Karma", NebulaUI:Font(20), w / 2, h - 18, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if AvailableGrapple then
            DisableClipping(true)
            surface.DrawTexturedRect(-w + 8, h - 32, w, 32)
            draw.SimpleText("[G] Grappling Hook", NebulaUI:Font(20), 8, h - 18, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            DisableClipping(false)
        end
    end

    hook.Add("PlayerBindPress", cards, function(cards, ply, bind, pressed)
        if not pressed then return end
        if not cards.ShouldDisplay then return end

        if string.StartWith(bind, "slot") then
            local id = tonumber(string.sub(bind, 5))
            local card = NebulaTarot.Favorites[id]

            if not card then
                surface.PlaySound("physics/cardboard/cardboard_box_impact_soft2.wav")

                return
            end

            if (LocalPlayer():getCards()[card] or 0) > 0 then
                NebulaTarot:ShowCard(card)
                net.Start("Nebula.Tarot:RequestUse")
                net.WriteString(card)
                net.SendToServer()
            end

            return true
        end
    end)

    cards.Models = {}
    cards.ModelOn = false

    cards.Think = function(s)
        s.ShouldDisplay = not vgui.CursorVisible() and input.IsButtonDown(KEY_T)

        if s.ShouldDisplay ~= s.ModelOn then
            s.ModelOn = s.ShouldDisplay

            if s.ModelOn then
                surface.PlaySound("physics/cardboard/cardboard_box_impact_soft7.wav")

                for k, v in pairs(s.Models) do
                    v.Progress = 0
                    v:AlphaTo(255, 0.25, 0)
                end
            else
                surface.PlaySound("physics/cardboard/cardboard_box_impact_soft4.wav")

                for k, v in pairs(s.Models) do
                    v:AlphaTo(0, 0.25, 0)
                end
            end
        end
    end

    for k = 1, 3 do
        local ent = vgui.Create("DModelPanel", cards)
        table.insert(cards.Models, ent)
        ent:SetModel("models/nebularp/tarot.mdl")
        ent:Dock(LEFT)
        ent:SetWide(48)
        ent:SetFOV(40)
        ent:SetAlpha(0)
        ent:SetCamPos(Vector(0, -40, -5))
        ent:SetLookAt(Vector(0, 0, -10))
        ent.Progress = 0
        ent.Card = self.Favorites[k]

        ent.PreDrawModel = function(s, e)
            if not s.Card then
                e:SetLocalAngles(Angle(0, 180, 0))

                return
            end

            local amount = LocalPlayer():getCards()[s.Card] or 0
            render.SuppressEngineLighting(true)
            render.SetColorModulation(.8, .8, .8)
            render.SetBlend((amount == 0 and .25 or 1) * (s:GetAlpha() / 255))
            e:DrawModel()
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
            render.SuppressEngineLighting(false)

            return false
        end

        ent.LayoutEntity = function(s, e)
            e:SetSequence(s.Card and "on" or "off")
            s.Progress = math.Clamp(s.Progress + FrameTime() * 4, 0, 1)
            e:SetCycle(s.Progress)
        end

        ent.PaintOver = function(s, w, h)
            draw.SimpleText("(" .. k .. ")", NebulaUI:Font(16), w / 2, -4, color_white, TEXT_ALIGN_CENTER)

            if s.Card then
                local amount = LocalPlayer():getCards()[s.Card] or 0
                draw.SimpleText("x" .. amount, NebulaUI:Font(16), w / 2, h - 52, color_white, TEXT_ALIGN_CENTER)

                if amount > 0 then
                    draw.SimpleText("x" .. amount, NebulaUI:Font(18), w / 2 + 2, h - 51, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER)
                end
            end
        end

        if ent.Card then
            ent:GetEntity():SetSkin(self.Cards[ent.Card].Skin)
        end
    end

    self.CardHUD = cards
end

if IsValid(LocalPlayer()) then
    NebulaTarot:CreateHUD()
end

hook.Add("InitPostEntity", "NebulaTarot.HUD", function()
    NebulaTarot:CreateHUD()
end)