AddCSLuaFile()

game.AddParticles("particles/nebula.pcf")
PrecacheParticleSystem("tarot_card")

TAROT = {}
AddCSLuaFile("cards/base.lua")
include("cards/base.lua")

NebulaTarot.Cards = {
    base = table.Copy(TAROT)
}

MsgC(Color(100, 50, 255), "Loading Nebula Tarot cards...\n")
local files, _ = file.Find("tarot/cards/*.lua", "LUA")
for k, v in pairs(files) do
    if (v == "base.lua") then continue end
    MsgC(Color(255, 255, 255), "\tLoading " .. string.sub(v, 1, #v - 4))
    AddCSLuaFile("tarot/cards/" .. v)
    include("tarot/cards/" .. v)
    NebulaTarot.Cards[string.sub(v, 1, -4)] = table.Copy(TAROT)
    TAROT = nil
    MsgC(Color(73, 255, 134), " :D\n")
end
MsgC(Color(100, 50, 255), "Finished Loading...\n")
local meta = FindMetaTable("Player")

function meta:getCards()
    return self._cards or {
        Equipped = {},
        Inventory = {},
    }
end