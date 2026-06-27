-------------------------
-- Setup this bad boii --
-------------------------

-- Imports --
AddCSLuaFile("tlou_alike_death/tlou_utils.lua")
AddCSLuaFile("tlou_alike_death/client/cl_death.lua")

include("tlou_alike_death/sh_convars.lua")

util.PrecacheSound("tlou_death_sound.mp3")

if SERVER then
    -- Net Strings --
    util.AddNetworkString("TLOU_OnPlayerDeath")
    util.AddNetworkString("TLOU_OnPlayerSpawn")
    util.AddNetworkString("TLOU_OnRagdollRecheck")

    include("tlou_alike_death/server/sv_death.lua")

    return
end

if CLIENT then
    surface.CreateFont( "DermaLarger", {
        font		= "Roboto",
        size		= 48,
        weight		= 500,
        extended	= true
    } )

    surface.CreateFont( "DermaLargest", {
        font		= "Roboto",
        size		= 64,
        weight		= 500,
        extended	= true
    } )

    include("tlou_alike_death/client/cl_death.lua")
end