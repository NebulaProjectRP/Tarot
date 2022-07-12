
util.AddNetworkString("Nebula.Tarot:RequestUse")
util.AddNetworkString("Nebula.Tarot:DoEffect")
util.AddNetworkString("Nebula.Tarot:UpdateCards")

local meta = FindMetaTable("Player")
local waitingDeaths = {}
function meta:useCard(id, force)
    if (not force and not self:getCards()[id]) then return end

    local card = table.Copy(NebulaTarot.Cards[id])
    if not card then return end
    table.Merge(card, TAROT_BASE)

    if (card.OnUse) then
        local result = card:OnUse(self)
        if result == false then
            return
        end
    end

    if (card.OnDeath) then
        waitingDeaths[self] = function()
            card:OnDeath(self)
        end
    end

    if not force then
        local definition = NebulaTarot.Cards[id]
        self._cards.Inventory[id] = math.Clamp((self._cards.Inventory[id] or 0) - 1, 0, definition.Max)
        net.Start("Nebula.Tarot:UpdateCards")
        net.WriteString(id)
        net.WriteUInt(self._cards.Inventory[id], 8)
        net.Send(self)
    end
end

hook.Add("DoPlayerDeath", "Tarot.PostDeath", function(ply)
    if (waitingDeaths[ply]) then
        waitingDeaths[ply]()
        waitingDeaths[ply] = nil
    end
end)

function meta:addCard(id, ignore)
    local definition = NebulaTarot.Cards[id]
    if not definition then
        error("Missing card definition for " .. id)
        return
    end

    if not self._cards then
        self._cards = {
            Equipped = {},
            Inventory = {},
        }
    end

    self._cards.Inventory[id] = math.Clamp((self._cards.Inventory[id] or 0) + 1, 0, definition.Max)
    net.Start("Nebula.Tarot:UpdateCards")
    net.WriteString(id)
    net.WriteUInt(self._cards.Inventory[id], 8)
    net.Send(self)

    if not ignore then
        NebulaDriver:MySQLUpdate("tarot", {
            cards = util.TableToJSON(self._cards)
        }, "steamid = " .. self:SteamID64())
    end
end

hook.Add("DatabaseCreateTables", "NebulaTarot", function()
    NebulaDriver:MySQLCreateTable("tarot", {
        cards = "TEXT NOT NULL",
        steamid = "VARCHAR(22)"
    }, "steamid")

    NebulaDriver:MySQLHook("tarot", function(ply, data)
        data = data[1]
        if (not data or not data.cards) then return end
        for k, v in pairs(data.cards) do
            ply:addCard(k, true)
        end
    end)
end)