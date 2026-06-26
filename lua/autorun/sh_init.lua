-- Imports --
AddCSLuaFile("tlou_alike_death/tlou_utils.lua")

-------------------------
-- Setup this bad boii --
-------------------------
util.PrecacheSound("tlou_death_sound.mp3")

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
end

if CLIENT then return end

-- Net Strings --
util.AddNetworkString("TLOU_OnPlayerDeath")
util.AddNetworkString("TLOU_OnPlayerSpawn")
util.AddNetworkString("TLOU_OnRagdollRecheck")