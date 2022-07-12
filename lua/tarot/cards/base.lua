TAROT_BASE = {}
TAROT_BASE.Name = "Base"
TAROT_BASE.Rarity = 1
TAROT_BASE.Cost = 500

function TAROT_BASE:Remove(ply)
    self:OnRemove(ply)
end