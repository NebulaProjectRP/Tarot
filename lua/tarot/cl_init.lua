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
        if (not s.Disabled and cycle >= .95) then
            s.Disabled = true
        elseif (s.Disabled) then
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
            if (s.Part) then
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
    ent:SetSkin(id)
    pnl.Part = CreateParticleSystem(ent, "tarot_card", PATTACH_ABSORIGIN_FOLLOW, 0, Vector(0, 0, 0))
    pnl.Part:SetShouldDraw(false)
    ent:ResetSequence("show")
end

function NebulaTarot:CreateParticle(ent)
    if (ent.cardParticle) then
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
        LocalPlayer()._cards = {
            Equipped = {},
            Inventory = {},
        }
    end

    LocalPlayer()._cards.Inventory[id] = am
end)