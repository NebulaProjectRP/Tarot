TAROT = {}
TAROT.Name = "Justice"
TAROT.Help = "You recover 25% of your missing health and armor, also your weapons get reloaded"
TAROT.Rarity = 2
TAROT.Max = 5
TAROT.Cost = 3000
TAROT.Skin = 5

function TAROT:OnUse(ply)
    local health = (1 - math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1)) / 2
    ply:SetHealth(ply:Health() + health * ply:GetMaxHealth())

    local armor = (1 - math.Clamp(ply:Armor() / ply:GetMaxArmor(), 0, 1)) / 2
    ply:SetArmor(ply:Armor() + armor * 100)

    for k, v in pairs(ply:GetWeapons()) do
        v:SetClip1(v:GetMaxClip1())
    end

    ply:EmitSound("nebularp/spell_overheal.wav")
end