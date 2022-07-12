TAROT = {}
TAROT.Name = "Chariot"
TAROT.Help = "Gets ejected from your suit once it gets destroyed and get invisible for 3 seconds."
TAROT.Rarity = 1
TAROT.Cost = 1000
TAROT.Max = 10
TAROT.Skin = 0

function TAROT:OnDeath(ply)
    if (!ply:hasSuit()) then
        return false
    end

    local suit = ply:getSuitData()
    ply:addItem(suit.item, 1)

    return true
end