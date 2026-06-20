print("TLOU Death init SERVER")
-- Imports --
---@class TlouConstants
local consts = include("tlou/constants.lua")

---@class TlouUtils
local tlouUtils = include("tlou/tlou_utils.lua")

-- Setup --
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

-- Functions --
---@param ply Player
---@param inflictor Entity
---@param attacker Entity
local function TlouPlayerDeath(ply, inflictor, attacker)
    if not tobool(GetConVar(consts.SV_CONVAR_ENABLED):GetBool()) then return end

    ply:Lock()
    timer.Create(ply:SteamID() .. "_respawn_timeout", GetConVar(consts.SV_CONVAR_OFFSET):GetFloat() + 2.5, 1, function()
        ply:UnLock()
    end)
    
    net.Start("TLOU_OnPlayerDeath")
    net.WriteEntity(attacker or ply)
    net.Send(ply)
end

---@param ply Player
local function TlouPlayerSpawn(ply)
    if timer.Exists(ply:SteamID() .. "_respawn_timeout") then
        timer.Remove(ply:SteamID() .. "_respawn_timeout")
    end
    
    net.Start("TLOU_OnPlayerSpawn")
    net.Send(ply)
end

-- Hooks --
hook.Add("PlayerDeath", "TLOU_Death", TlouPlayerDeath)
hook.Add("PlayerSilentDeath", "TLOU_SilentDeath", TlouPlayerDeath)

-- Just to make sure that there is no modified ragdoll
hook.Add("PostPlayerDeath", "TLOU_RagdollRecheck", function(ply)
    local body = ply:GetRagdollEntity()
    if not body:IsValid() then return end

    net.Start("TLOU_OnRagdollRecheck")
    net.WriteEntity(body)
    net.Send(ply)
end)

hook.Add("PlayerSpawn", "TLOU_PlayerSpawn", TlouPlayerSpawn)
hook.Add("PlayerSpawnAsSpectator", "TLOU_PlayerSpawn", TlouPlayerSpawn)

hook.Add("PlayerDeathSound", "TLOU_MuteDefaultDeathSnd", function(ply)
    if not tobool(GetConVar(consts.SV_CONVAR_ENABLED):GetBool()) 
        or not tobool(ply:GetInfoNum(consts.CONVAR_VOICE_ENABLED, 0)) then return false end

    local body = ply:GetRagdollEntity()
    if body:IsValid() then
        local voType = tlouUtils.FindVoiceType(ply:GetModel(), ply)
        local deathSnd = tlouUtils.GetDeathVoice(voType)
        body:EmitSound(deathSnd)
    end

    return true
end)