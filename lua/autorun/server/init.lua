-- Imports --
AddCSLuaFile("tlou_alike_death/constants.lua")
AddCSLuaFile("tlou_alike_death/tlou_utils.lua")

---@class TlouConstants
local consts = include("tlou_alike_death/constants.lua")

-------------------------
-- Setup this bad boii --
-------------------------
util.PrecacheSound("tlou_death_sound.mp3")

-- Convars --
CreateConVar(consts.SV_CONVAR_ENABLED, "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should TLOU a-like death be enabled", 0, 1)
CreateConVar(consts.SV_CONVAR_DEATH_MESSAGE, "", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Custom death message")
CreateConVar(consts.SV_CONVAR_OFFSET, "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How far should offset the death screen sequence", 0.5, 2)

CreateClientConVar(consts.CONVAR_VOICE_ENABLED, "1", true, true, "Should death voice be enabled", 0, 1)
CreateClientConVar(consts.CONVAR_VOICETYPE, "0", true, true, [[
    0 - auto
    1 - male
    2 - female
    3 - combine
    4 - zombie]], 0, 4)

-- Net Strings --
util.AddNetworkString("TLOU_OnPlayerDeath")
util.AddNetworkString("TLOU_OnPlayerSpawn")
util.AddNetworkString("TLOU_OnRagdollRecheck")