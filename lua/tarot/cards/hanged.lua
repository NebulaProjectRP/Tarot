TAROT = {}
TAROT.Name = "The Hanged Man"
TAROT.Help = "Headshots cannot get you"
TAROT.Max = 5
TAROT.Rarity = 4
TAROT.Cost = 10000
TAROT.Skin = 3

function TAROT:OnUse(ply)
    ply:addBuff("noheadshots", 10)
    ply.noHeadShots = true
    ply:EmitSound("nebularp/duck_pickup_pos_01.wav", 140)
    ply:Wait(10, function()
        self:Remove(ply)
    end)
end

function TAROT:OnRemove(ply)
    ply.noHeadShots = false
    ply:removeBuff("noheadshots", 10)
    ply:EmitSound("nebularp/spell_teleport.wav")
end