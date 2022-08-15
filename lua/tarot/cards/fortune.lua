if SERVER then
    util.AddNetworkString("Nebula.Tarot:Fortune")
end

TAROT = {}
TAROT.Name = "Wheel Of Fortune"
TAROT.Help = "Applies a random buff which deals extra damage or gives money!"
TAROT.Max = 3
TAROT.Rarity = 3
TAROT.Cost = 6000
TAROT.Skin = 2

local texts = {
    [1] = "Deal temporaly 50% extra damage",
    [2] = "Receive -50% damage",
    [3] = "Earn x10$ of your damage received",
    [4] = "Earn x10$ of your damage dealt",
}

local cases = {
    [1] = function(requestEntity, dmg)
        if requestEntity.tarotWheel == 1 then
            dmg:ScaleDamage(1.5)
        end
    end,
    [2] = function(requestEntity, dmg)
        if requestEntity.tarotWheel == 2 then
            dmg:ScaleDamage(.5)
        end
    end,
    [3] = function(requestEntity, dmg)
        local amount = -dmg:GetDamage() * 10

        if owner:canAfford(amount) then
            owner:addMoney(amount)
            dmg:ScaleDamage(0)
        end
    end,
    [4] = function(requestEntity, dmg)
        local amount = dmg:GetDamage() * 10

        if victim:canAfford(amount) then
            owner:addMoney(amount)
            victim:addMoney(-amount / 2)
            dmg:ScaleDamage(0)
        end
    end
}

function TAROT:OnUse(ply)
    local dice = math.random(1, 4)
    net.Start("Nebula.Tarot:Fortune")
    net.WriteBool(true)
    net.WriteEntity(ply)
    net.SendPAS(ply:GetPos())

    ply:Wait(3, function()
        ply.tarotWheel = dice
        net.Start("Nebula.Tarot:Fortune")
        net.WriteBool(false)
        net.WriteUInt(dice, 3)
        net.Send(ply)

        ply:Wait(5, function()
            ply.tarotWheel = nil
            ply:EmitSound("nebularp/spell_teleport.wav")
        end)
    end)

    return true
end

function TAROT:OnRemove()
    ply.tarotWheel = nil
end

net.Receive("Nebula.Tarot:Fortune", function()
    local isStart = net.ReadBool()

    if isStart then
        local ent = net.ReadEntity()
        if not IsValid(ent) then return end
        local rings = 0
        local isBit = false

        local function doTick(val, progress)
            surface.PlaySound("nebularp/spelltick_0" .. (isBit and 2 or 1) .. ".wav")

            timer.Create("Nebula.Tarot:Fortune:Tick", .2 - (rings / val) * .2, 1, function()
                if not IsValid(ent) or not ent:Alive() then
                    timer.Remove("Nebula.Tarot:Fortune:Tick")

                    return
                end

                rings = rings + 1

                if rings == val then
                    timer.Simple(.2, function()
                        surface.PlaySound("nebularp/spelltick_set.wav")
                    end)

                    timer.Remove("Nebula.Tarot:Fortune:Tick")

                    return
                end

                doTick(val)
            end)

            isBit = not isBit
        end

        doTick(15)
    else
        local dice = net.ReadUInt(3)
        chat.AddText(Color(150, 50, 255), "[Tarot] ", Color(255, 255, 255), "You rolled a ", Color(150, 50, 255), dice, Color(255, 255, 255), "! ", Color(225, 200, 75), texts[dice])
    end
end)

hook.Add("EntityTakeDamage", "Tarot.FortuneWheel", function(ent, dmg)
    local att = dmg:GetAttacker()
    if att == ent or not IsValid(att) or not att:IsPlayer() then return end

    for _, v in ipairs({att, ent}) do
        if not v.tarotWheel then continue end
        local case = cases[v.tarotWheel]

        if case then
            case(v, dmg)
        end
    end
end)