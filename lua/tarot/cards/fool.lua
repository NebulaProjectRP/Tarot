TAROT = {}
TAROT.Name = "The Fool"
TAROT.Help = "All your items (Except suit) to return to your inventory"
TAROT.Max = 2
TAROT.Rarity = 4
TAROT.Cost = 20000
TAROT.Skin = 1

function TAROT:OnDeath(ply)
    local gotWeapons = false
    for k, v in pairs(ply:GetWeapons()) do
        if (v.ItemID) then
            gotWeapons = true
            ply:addItem(v.ItemID, 1)
        end
    end

    return gotWeapons
end