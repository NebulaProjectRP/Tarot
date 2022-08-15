TAROT = {}
TAROT.Name = "The Fool"
TAROT.Help = "All your items (except suit) return to your inventory!"
TAROT.Max = 2
TAROT.Rarity = 4
TAROT.Cost = 20000
TAROT.Skin = 1

function TAROT:OnDeath(ply)
    ply.hasFool = true
end