
util.AddNetworkString("Nebula.Tarot:RequestUse")
util.AddNetworkString("Nebula.Tarot:DoEffect")
util.AddNetworkString("Nebula.Tarot:UpdateCards")
util.AddNetworkString("Nebula.Tarot:BuyCard")

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
        self._cards[id] = math.Clamp((self._cards[id] or 0) - 1, 0, definition.Max)
        net.Start("Nebula.Tarot:UpdateCards")
        net.WriteString(id)
        net.WriteUInt(self._cards[id], 8)
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
        self._cards = {}
    end

    self._cards[id] = math.Clamp((self._cards[id] or 0) + 1, 0, definition.Max)
    net.Start("Nebula.Tarot:UpdateCards")
    net.WriteString(id)
    net.WriteUInt(self._cards[id], 8)
    net.Send(self)

    if not ignore then
        NebulaDriver:MySQLUpdate("tarot", {
            cards = util.TableToJSON(self._cards)
        }, "steamid = " .. self:SteamID64(), function(a, req)
            MsgN(req)
        end)
    end
end

hook.Add("DatabaseCreateTables", "NebulaTarot", function()
    NebulaDriver:MySQLCreateTable("tarot", {
        cards = "TEXT NOT NULL",
        steamid = "VARCHAR(22)"
    }, "steamid")

    NebulaDriver:MySQLHook("tarot", function(ply, data)
        MsgN(ply," ", data)
        if (not data or not data[1]) then
            NebulaDriver:MySQLQuery("INSERT INTO tarot (steamid, cards) " ..
			"VALUES (" .. ply:SteamID64() .. ", '{}');")
            ply._cards = {}
            data = {{cards = {}}}
        end

        data = data[1]
        if (not data or not data.cards) then return end
        for k, v in pairs(data.cards) do
            ply:addCard(k, true)
        end
    end)
end)

local cache = {}
local function randomFromRarity(id)
    if not cache[id] then
        cache[id] = {}
        for k, v in pairs(NebulaTarot.Cards) do
            if (v.Rarity == id) then
                table.insert(cache[id], k)
            end
        end
    end
    return cache[id][math.random(1, #cache[id])]
end

local heap = {}
local nextHeap = 0
net.Receive("Nebula.Tarot:BuyCard", function(l, ply)
    if (not ply:canAfford(NebulaTarot.Price)) then
        MsgN("Poor kid")
        //return
    end

    if (nextHeap < CurTime()) then
        heap = {}
        nextHeap = CurTime() + 30
        for i, iterations in pairs({40, 30, 20, 10}) do
            for _ = 1, iterations do
                table.insert(heap, randomFromRarity(i))
            end
        end
    end

    local result = heap[math.random(1, 100)]
    ply:addCard(result)
    net.Start("Nebula.Tarot:BuyCard")
    net.WriteString(result)
    net.Send(ply)
end)

net.Receive("Nebula.Tarot:RequestUse", function(l, ply)
    local id = net.ReadString()
    if not ply:getCards()[id] then return end

    ply:useCard(id)
end)