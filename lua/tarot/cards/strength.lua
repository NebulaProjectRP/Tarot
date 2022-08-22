TAROT = {}
TAROT.Name = "Strength"
TAROT.Help = "Your hits knockbacks more"
TAROT.Rarity = 2
TAROT.Max = 5
TAROT.Cost = 3000
TAROT.Skin = 6

function TAROT:OnUse(ply)
    ply:addBuff("strength", 10)
    ply:EmitSound("nebularp/spell_overheal.wav")
    ply:Wait(10, function()
        self:Remove(ply)
    end)
end

function TAROT:OnRemove(ply)
    ply:EmitSound("nebularp/duck_pickup_neg_01.wav")
    ply:removeBuff("strength")
end

function TAROT:OnUse(ply)
    local health = (1 - math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1)) / 4
    ply:SetHealth(ply:Health() + health * ply:GetMaxHealth())

    local armor = (1 - math.Clamp(ply:Armor() / ply:GetMaxArmor(), 0, 1)) / 4
    ply:SetArmor(ply:Armor() + armor * 100)

    for k, v in pairs(ply:GetWeapons()) do
        v:SetClip1(v:GetMaxClip1())
    end

    ply:EmitSound("nebularp/spell_overheal.wav", 140)
end