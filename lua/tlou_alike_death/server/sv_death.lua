print("TLOU Death init SERVER")

-- Imports --
---@class TlouUtils
local tlouUtils = include("tlou_alike_death/tlou_utils.lua")

-- Functions --
---@param ply Player
---@param inflictor Entity
---@param attacker Entity
local function TlouPlayerDeath(ply, inflictor, attacker)
    if not TD_CVAR_ENABLED:GetBool() then return end

    ply:Lock()
    timer.Create(ply:SteamID() .. "_respawn_timeout", TD_CVAR_DEATHOFFSET:GetFloat() + 2.5, 1, function()
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
        ply:UnLock()
    end
    
    net.Start("TLOU_OnPlayerSpawn")
    net.Send(ply)
end

---@param ply Player
---@param ragdoll Entity | nil
---@param forceChange boolean
local function RagdollRecheck(ply, ragdoll, forceChange)
    if not TD_CVAR_ENABLED:GetBool() then return end
    
    forceChange = forceChange or false
    local body = ragdoll or ply:GetRagdollEntity()

    if not body:IsValid() then return end
    
    net.Start("TLOU_OnRagdollRecheck")
    -- net.WriteEntity(body)
    net.WriteUInt(body:EntIndex(), 16)
    net.WriteBool(forceChange)
    net.Send(ply)
    
    print("Sent " .. tostring(body) .. " to " .. tostring(ply) .. "\nForce change: "  .. tostring(forceChange))
end

-- Hooks --
hook.Add("PlayerDeath", "TLOU_Death", TlouPlayerDeath)
hook.Add("PlayerSilentDeath", "TLOU_SilentDeath", TlouPlayerDeath)

-- Just to make sure that there is no modified ragdoll
hook.Add("PostPlayerDeath", "TLOU_RagdollRecheck", RagdollRecheck)

hook.Add("PlayerSpawn", "TLOU_PlayerSpawn", TlouPlayerSpawn)
hook.Add("PlayerSpawnAsSpectator", "TLOU_PlayerSpawn", TlouPlayerSpawn)

hook.Add("PlayerDeathSound", "TLOU_MuteDefaultDeathSnd", function(ply)
    if not TD_CVAR_ENABLED:GetBool() 
        or not tobool(ply:GetInfoNum(TD_CLCVAR_VOICE_ENABLED:GetName(), 0)) then return false end

    local body = ply:GetRagdollEntity()
    if body:IsValid() then
        local voType = tlouUtils.FindVoiceType(ply:GetModel(), ply)
        local deathSnd = tlouUtils.GetDeathVoice(voType)
        body:EmitSound(deathSnd)
    end

    return true
end)


------------------------
-- Addon support zone --
------------------------

-- ReAgdoll support --
---@param victim Player
---@param ragdoll Entity
hook.Add("ReAgdoll_CreatePlayerRagdoll", "TLOU_ReAgdollDeath", function(victim, ragdoll)
    print("ReAgdoll TLOU hook catch!")
    RagdollRecheck(victim, ragdoll, true)
end)