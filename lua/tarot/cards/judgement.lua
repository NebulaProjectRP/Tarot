TAROT = {}
TAROT.Name = "Judgement"
TAROT.Help = "You don't need to reload for the next 5 seconds"
TAROT.Rarity = 3
TAROT.Max = 3
TAROT.Cost = 10000
TAROT.Skin = 4

function TAROT:OnUse(ply)
    ply:addBuff("judgement", 5)
    ply.infiniteBullets = true
    ply:EmitSound("nebularp/spell_overheal.wav", 140)
    ply:Wait(10, function()
        self:Remove(ply)
        ply:EmitSound("nebularp/duck_pickup_neg_01.wav")
    end)
end

function TAROT:OnRemove(ply)
    ply:removeBuff("judgement")
end
