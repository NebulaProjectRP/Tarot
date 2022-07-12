MsgC(Color(200, 50, 200), "[Tarot]", color_white, " Tarot it's loading...\n")

NebulaTarot = {}

include("tarot/sh_meta.lua")

if SERVER then
    AddCSLuaFile("tarot/cl_init.lua")
    include("tarot/sv_init.lua")
else
    include("tarot/cl_init.lua")
end

MsgC(Color(200, 50, 200), "[Tarot]", color_white, " Finished loading\n")