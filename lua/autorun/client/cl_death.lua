print("TLOU Death init CLIENT")

-- Imports --
---@class TlouUtils
local tlouUtils = include("tlou_alike_death/tlou_utils.lua")

-- local vars --
local locPly = LocalPlayer()

local showDS = false
local showTexts = false
local textsAlpha = 0

---@class Config
local config = {
    shouldFollowAttacker = false,
    trackFace = false,
    customMessage = "",
    font = "DermaLarge",
}

---@type Entity | nil
local body
---@type Entity | nil
local recheckedBody
---@type Entity | nil
local oldRecheckedBody

---@class DeathData
---@field boneId number | nil
---@field attacker Entity | nil
---@field camPos Vector
---@field camAngle Angle | nil
---@field fov number
---@field roll number
local deathData = {}

-- Functions --

local CompatibilityCheck -- Moved to Addon support zone 

local function ResetVars()
    showDS = false
    showTexts = false
    textsAlpha = 0
end

local function RemoveDeathScreen()
    hook.Remove("CalcView", "TLOU_DeathCam")
    hook.Remove("PostDrawHUD", "TLOU_DeathScreen")

    oldRecheckedBody = recheckedBody
    recheckedBody = nil
    body = nil
    deathData.attacker = nil
    ResetVars()
    CompatibilityCheck(true)

    if not IsValid(locPly) then return end
    locPly:ConCommand("soundfade 0 0 [0.5 0]")
end

local function DrawDeathScreen()
    if not showDS then return end

    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, ScrW(), ScrH())

    if not showTexts then return end

    textsAlpha = math.Clamp(textsAlpha + (FrameTime() * 20), 0, 200)
    draw.SimpleText(
        (config.customMessage ~= "" and config.customMessage) or "Press SPACE to respawn...", 
        config.font, ScrW() / 2, ScrH() / 2, Color(255, 255, 255, textsAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(
        "Press CTRL to remove the death screen", 
        config.font, ScrW() / 2, ScrH() * 0.95, Color(150, 150, 150, textsAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if input.IsButtonDown(KEY_LCONTROL) then
        RemoveDeathScreen()
    end
end

local function CalculateDeathCam(ply, origin, angles, fov, znear, zfar)
    if not TD_CVAR_ENABLED:GetBool() then return end

    ---@type Vector | nil, Angle | nil
    local bonePos, boneAngle
    if deathData.boneId and IsValid(body) then
        ---@diagnostic disable-next-line: need-check-nil
        bonePos, boneAngle = body:GetBonePosition(deathData.boneId)
    end

    local followPos = bonePos
        or (IsValid(deathData.attacker) and deathData.attacker:EyePos())
        or locPly:WorldSpaceCenter()

    local camDir = followPos - deathData.camPos

    ---@type Vector
    local targetPos
    if config.trackFace and boneAngle then
        local boneLookDir = boneAngle:Right()
        if boneLookDir.z < 0 then
            boneLookDir.z = -camDir:GetNormalized().z
        end
        
        targetPos = followPos + boneLookDir * 100
    else
        targetPos = followPos + (-camDir:GetNormalized() * 100)
    end

    local surfaceCheck = util.QuickTrace(followPos, targetPos - followPos, {body, recheckedBody, deathData.attacker, "prop_ragdoll"})
    if surfaceCheck.Hit then
        targetPos = surfaceCheck.HitPos + surfaceCheck.HitNormal * 5
    end

    deathData.camPos = LerpVector(FrameTime(), deathData.camPos, targetPos)
    
    local camAngle = camDir:Angle()
    if not deathData.camAngle then
        deathData.camAngle = camAngle
    end

    deathData.roll = Lerp(0.5 * FrameTime(), deathData.roll, 0)
    camAngle.r = deathData.roll
    
    deathData.camAngle = LerpAngle(10 * FrameTime(), deathData.camAngle, camAngle)
    camAngle = tlouUtils.ApplyCamShake(deathData.camAngle, 2, 5)

    deathData.fov = Lerp(0.5 * FrameTime(), deathData.fov, 30)

    local view = {}
    view.origin = deathData.camPos
    view.angles = camAngle
    view.fov = deathData.fov
    view.znear = znear
    view.zfar = zfar

    return view
end

local function SetBody()
    body = (oldRecheckedBody ~= recheckedBody) and recheckedBody or locPly:GetRagdollEntity()
    deathData.boneId = tlouUtils.GetBoneId(body)
end

---@param attacker Entity | NPC | Player | nil
local function SetupDeathScreen(attacker)
    ResetVars()

    config.trackFace = TD_CLCVAR_FACE_PLAYER:GetBool()
    config.customMessage = TD_CVAR_DEATHMESSAGE:GetString()
    config.shouldFollowAttacker = TD_CLCVAR_FOLLOW_ATTACKER:GetBool()

    local fontIndex = TD_CLCVAR_FONT:GetInt()
    if fontIndex == 1 then
        config.font = "DermaLarger"
    elseif fontIndex == 2 then
        config.font = "DermaLargest"
    else
        config.font = "DermaLarge"
    end

    print(oldRecheckedBody, recheckedBody)

    attacker = config.shouldFollowAttacker and attacker or nil
    deathData.attacker = attacker

    local followEntity = (deathData.boneId or not IsValid(attacker)) and locPly
        or attacker

    ---@diagnostic disable-next-line: param-type-mismatch
    deathData.camPos = tlouUtils.GetRandomCamFollowPos(followEntity, deathData.boneId ~= nil,
        {
            "prop_ragdoll",
            locPly:GetClass(),
            
            ---@diagnostic disable-next-line: need-check-nil
            IsValid(body) and body:GetClass() or nil,
            ---@diagnostic disable-next-line: need-check-nil
            IsValid(recheckedBody) and recheckedBody:GetClass() or nil
        }
    )

    if game.SinglePlayer() then
        SetBody()
    else
        tlouUtils.SetupLatencyChecker(function ()
            return locPly:GetRagdollEntity():IsValid()
        end, SetBody, "GetDefaultRag")
    end
    
    deathData.camAngle = nil
    deathData.fov = 100
    deathData.roll = math.Rand(-50, 50)
    
    hook.Add("CalcView", "TLOU_DeathCam", CalculateDeathCam)
    hook.Add("PostDrawHUD", "TLOU_DeathScreen", DrawDeathScreen)
    CompatibilityCheck(false)
end

---@param newRagdoll Entity
---@param forceChange boolean
local function RecheckBody(newRagdoll, forceChange)
    if not newRagdoll:IsValid() then return end
    if IsValid(body) and not forceChange then return end

    body = newRagdoll
    recheckedBody = newRagdoll
    deathData.boneId = tlouUtils.GetBoneId(newRagdoll)

    print("Set new body: " .. tostring(body) .. "\nForce changed: " .. tostring(forceChange))
end

-- Net receives --
net.Receive("TLOU_OnPlayerDeath", function()
    local attacker = net.ReadEntity()
    SetupDeathScreen(attacker)

    if timer.Exists("CL_TLOU_DeathSequence") then return end
    
    -- NextSpawn muste be: CONVAR_OFFSET + 2.5
    timer.Create("CL_TLOU_DeathSequence", TD_CVAR_DEATHOFFSET:GetFloat(), 1, function()
        if locPly:Alive() then return end

        surface.PlaySound("tlou_death_sound.mp3")
        timer.Simple(1, function()
            if locPly:Alive() then return end

            showDS = true
            locPly:ConCommand("soundfade 100 99999 [0, 0.4]")

            timer.Simple(1.5, function()
                if locPly:Alive() then return end
                
                showTexts = true
            end)
        end)
    end)
end)

-- Just to make sure that there is no modified ragdoll
net.Receive("TLOU_OnRagdollRecheck", function ()
    local ragId = net.ReadUInt(16)
    local force = net.ReadBool()

    if game.SinglePlayer() then
        RecheckBody(Entity(ragId), force)
    else
        tlouUtils.SetupLatencyChecker(function ()
            return Entity(ragId):IsValid()
        end, function ()
            RecheckBody(Entity(ragId), force)
        end, "BasicRagRecheck")
    end
end)

net.Receive("TLOU_OnPlayerSpawn", RemoveDeathScreen)

-- Hooks --
hook.Add("InitPostEntity", "TLOU_InitPly", function()
    locPly = LocalPlayer()
end)

-- Menu Setup --
hook.Add("PopulateToolMenu", "TLOU_MenuSetup", function()
    ---@param pnl Panel | DForm
    ---@diagnostic disable-next-line: deprecated
    spawnmenu.AddToolMenuOption("Options", "Player", "tlou_options", "TLOU Death", nil, nil, function(pnl)
        -- Server
        pnl:ControlHelp("\nSERVER")
        pnl:CheckBox("Enable death", TD_CVAR_ENABLED:GetName())
        pnl:NumSlider("Death offset (Def: 1)", TD_CVAR_DEATHOFFSET:GetName(), 0.1, 5, 1)
        pnl:TextEntry("Death message", TD_CVAR_DEATHMESSAGE:GetName())
        pnl:ControlHelp([[
Leave empty to use default
    - SPACEs also count as custom message
        ]])

        -- Client
        pnl:ControlHelp("\nCLIENT")
        
        pnl:CheckBox("Should follow attacker", TD_CLCVAR_FOLLOW_ATTACKER:GetName())
        pnl:ControlHelp("Should cam follow attacker if player's ragdoll is invalid")

        pnl:CheckBox("Try face player", TD_CLCVAR_FACE_PLAYER:GetName())
        pnl:ControlHelp("Should cam try to face player on death\nWARNING: camera goofiness possibility")

        local fontSelect = pnl:ComboBox("Message font size", TD_CLCVAR_FONT:GetName())
        fontSelect:SetSortItems(false)
        fontSelect:AddChoice("Default", 0)
        fontSelect:AddChoice("Large", 1)
        fontSelect:AddChoice("Largest", 2)
        pnl:ControlHelp("Change if the death message appear do be small")

        pnl:CheckBox("Should use death voice", TD_CLCVAR_VOICE_ENABLED:GetName())
        local voiceSelect = pnl:ComboBox("Voice type", TD_CLCVAR_VOICETYPE:GetName())
        voiceSelect:SetSortItems(false)
        voiceSelect:AddChoice("Auto", 0)
        voiceSelect:AddChoice("Male", 1)
        voiceSelect:AddChoice("Female", 2)
        voiceSelect:AddChoice("Combine", 3)
        voiceSelect:AddChoice("Zombie", 4)
    end)
end)


------------------------
-- Addon support zone --
------------------------

-- Shootout to "cool death effect" devs!
-- https://steamcommunity.com/sharedfiles/filedetails/?id=3746609320
-- Thank you so much for the found hooks for ZCity :^)
local zcityRenderScene
local zcityCalcView

-- RagDeath V2
local ragDeathCalcView

---@type fun(onScreenRemove: boolean)
CompatibilityCheck = function(onScreenRemove)
    local hooks = hook.GetTable()
    if onScreenRemove then

        -- ZCity stuff
        -- Кто придумывал названия этих хуков 🥀
        if zcityRenderScene then
            hook.Add("RenderScene", "jopa", zcityRenderScene)
            zcityRenderScene = nil
        end
        if zcityCalcView then
            hook.Add("CalcView", "homigrad-view", zcityCalcView)
            zcityCalcView = nil
        end
        if ragDeathCalcView then
            hook.Add("CalcView", "RagDeath_Cam", ragDeathCalcView)
            ragDeathCalcView = nil
        end

    else

        -- ZCity stuff
        if tlouUtils.CheckHookListenerExists("RenderScene", "jopa") then
            zcityRenderScene = hooks["RenderScene"]["jopa"]
            hook.Remove("RenderScene", "jopa")
        end
        if tlouUtils.CheckHookListenerExists("CalcView", "homigrad-view") then
            zcityCalcView = hooks["CalcView"]["homigrad-view"]
            hook.Remove("CalcView", "homigrad-view")
        end

        -- RagDeath V2 stuff
        if tlouUtils.CheckHookListenerExists("CalcView", "RagDeath_Cam") then
            ragDeathCalcView = hooks["CalcView"]["RagDeath_Cam"]
            hook.Remove("CalcView", "RagDeath_Cam")
        end

    end
end

-- Enhanced Death Animations support --
net.Receive("PlayerRag_StartDeathCam", function()
    local ragId = net.ReadInt(32)

    if game.SinglePlayer() then
        local ragdoll = Entity(ragId)
        RecheckBody(ragdoll, true)
    else
        tlouUtils.SetupLatencyChecker(function ()
            return IsValid(Entity(ragId))
        end, function ()
            RecheckBody(Entity(ragId), true)
        end, "EDA_Support")
    end
end)

-- RagDeath V2 support --
net.Receive("ragdeath_client", function ()
    local entIndex = net.ReadInt(32)
    local plyIndex = net.ReadInt(32)

    local owner = Entity(plyIndex)

    if owner ~= locPly then return end

    if game.SinglePlayer() then
        local ragdoll = Entity(entIndex)
        RecheckBody(ragdoll, true)
    else
        tlouUtils.SetupLatencyChecker(function ()
            return IsValid(Entity(entIndex))
        end, function ()
            RecheckBody(Entity(entIndex), true)
        end, "RagDeath_Support")
    end
end)