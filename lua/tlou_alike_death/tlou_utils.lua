---@class TlouConstants
local constants = include("constants.lua")

local PreferedBones = {
    "ValveBiped.Bip01_Head1",
    "ValveBiped.Bip01_Neck1",
    "ValveBiped.Bip01_Spine4",
    "ValveBiped.Bip01_Spine3",
    "ValveBiped.Bip01_Spine2",
    "ValveBiped.Bip01_Spine1",
    "ValveBiped.Bip01_Spine",
}

-- Model names to determine sound type
local FemaleModelStrings = {"alyx", "mossman", "female", "chell"}
local CombineModelStrings = {"combine", "police", "stripped"}
local ZombieModelStrings = {"zombie", "corpse", "skeleton", "charple", "zombine"}

-- Default sounds for different sound types
local DeathVoice = {
    male = {
        "vo/npc/male01/pain07.wav",
        "vo/npc/male01/pain08.wav",
        "vo/npc/male01/pain09.wav"
    },
    female = {
        "vo/npc/female01/pain01.wav",
        "vo/npc/female01/pain05.wav",
        "vo/npc/female01/pain07.wav",
        "vo/npc/female01/pain08.wav",
        "vo/npc/female01/pain09.wav",
    },
    combine = {
        "npc/metropolice/die1.wav",
        "npc/metropolice/die2.wav",
        "npc/metropolice/die3.wav",
        "npc/metropolice/die4.wav",
        "npc/combine_soldier/die1.wav",
        "npc/combine_soldier/die2.wav",
        "npc/combine_soldier/die3.wav",
    },
    zombie = {
        "npc/zombie/zombie_die1.wav",
        "npc/zombie/zombie_die2.wav",
        "npc/zombie/zombie_die3.wav"
    }
}

---@class TlouUtils
local TlouUtils = {
    GetBoneId = function(body)
        if not body:IsValid() then return nil end

        for _, v in ipairs(PreferedBones) do
            if body:LookupBone(v) ~= nil then
                return body:LookupBone(v)
            end
        end

        return nil
    end,

    ---@param ply Player
    FindVoiceType = function (model, ply)
        local voIndex = ply:GetInfoNum(constants.CONVAR_VOICETYPE, 0)
        if voIndex ~= 0 then
            if voIndex == 1 then return "male" end
            if voIndex == 2 then return "female" end
            if voIndex == 3 then return "combine" end
            return "zombie"
        end
        
        for _, v in ipairs(ZombieModelStrings) do
            if string.find(model, v) then
                return "zombie"
            end
        end

        for _, v in ipairs(FemaleModelStrings) do
            if string.find(model, v) then
                return "female"
            end
        end

        for _, v in ipairs(CombineModelStrings) do
            if string.find(model, v) then
                return "combine"
            end
        end

        return "male"
    end,

    GetDeathVoice = function (voiceType)
        return table.Random(DeathVoice[voiceType])
    end,

    ---@param angle Angle
    ---@param shakeSpeed number
    ---@param shakeAmount number
    ApplyCamShake = function(angle, shakeSpeed, shakeAmount)    
        local newAng = Angle(angle)
        local time = CurTime() * shakeSpeed
            
        -- Generate pseudo-random offsets based on time
        local shakeX = math.sin(time) * math.cos(time * 0.8) * shakeAmount
        local shakeY = math.cos(time * 1.1) * math.sin(time * 0.9) * shakeAmount
        local shakeZ = math.sin(time * 1.3) * shakeAmount

        newAng.p = newAng.p + shakeX
        newAng.y = newAng.y + shakeY
        newAng.r = newAng.r + shakeZ

        return newAng
    end,

    ---@param entity Entity | NPC | Player
    ---@param followsPlayer boolean
    ---@param filter Entity[] | string[]
    GetRandomCamFollowPos = function (entity, followsPlayer, filter)
        local lookDir = entity.GetAimVector and entity:GetAimVector()
            or entity:GetForward()
        local angle = lookDir:Angle()
        angle.p = math.Rand(-45, followsPlayer and 45 or 0)
        angle.y = angle.y + math.Rand(-45, 45)

        local direction = angle:Forward() * (entity:IsPlayer() and 50 or 100)
        local trace = util.QuickTrace(entity:EyePos(), direction, filter)
        if trace.Hit then
            return trace.HitPos + trace.HitNormal * 5
        else
            return entity:EyePos() + direction
        end
    end,

    -- CheckHookListenerExists = function(hookName, listenerName)
    --     local eventHook = hook.GetTable()[hookName]
    --     if not eventHook then return false end

    --     return eventHook[listenerName] ~= nil
    -- end
}

return TlouUtils