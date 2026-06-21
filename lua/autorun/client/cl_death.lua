print("TLOU Death init CLIENT")

-- Imports --
---@class TlouConstants
local consts = include("tlou/constants.lua")

---@class TlouUtils
local tlouUtils = include("tlou/tlou_utils.lua")

-- local vars --
local locPly = LocalPlayer()

local showDS = false
local showTexts = false
local customMessage = ""
local textsAlpha = 0

---@type Entity | nil
local body
---@type Entity | nil
local recheckedBody
---@type Entity | nil
local oldRecheckedBody

---@class DeathData
---@field boneId number | nil
---@field attacker Entity
---@field camPos Vector
---@field camAngle Angle | nil
---@field fov number
---@field roll number
local deathData = {}

-- Functions --
local function ResetVars()
    showDS = false
    showTexts = false
    textsAlpha = 0
end

local function RemoveDeathScreen()
    hook.Remove("CalcView", "TLOU_DeathCam")
    hook.Remove("PostDrawHUD", "TLOU_DeathScreen")

    oldRecheckedBody = recheckedBody
    ResetVars()

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
        (customMessage ~= "" and customMessage) or "Press SPACE to respawn...", 
        "DermaLarge", ScrW() / 2, ScrH() / 2, Color(255, 255, 255, textsAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(
        "Press CTRL to remove the death screen", 
        "DermaLarge", ScrW() / 2, ScrH() * 0.95, Color(150, 150, 150, textsAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if input.IsButtonDown(KEY_LCONTROL) then
        RemoveDeathScreen()
    end
end

local function CalculateDeathCam(ply, origin, angles, fov, znear, zfar)
    if not GetConVar(consts.SV_CONVAR_ENABLED):GetBool() then return end

    local bonePos = (deathData.boneId and IsValid(body)) and body:GetBonePosition(deathData.boneId)
    local followPos = bonePos
        or (deathData.attacker:IsValid() and deathData.attacker:EyePos())
        or locPly:WorldSpaceCenter()

    local camDir = followPos - deathData.camPos
    deathData.camPos = LerpVector(1 * FrameTime(), deathData.camPos, followPos + (-camDir:GetNormalized() * 100))
    
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

---@param attacker Entity | NPC | Player
local function SetupDeathScreen(attacker)    
    ResetVars()

    customMessage = GetConVar(consts.SV_CONVAR_DEATH_MESSAGE):GetString()
    print(oldRecheckedBody, recheckedBody)
    body = (oldRecheckedBody ~= recheckedBody and recheckedBody) or locPly:GetRagdollEntity()
    
    deathData.boneId = tlouUtils.GetBoneId(body)
    deathData.attacker = attacker
    
    local followEntity = (deathData.boneId or not IsValid(attacker)) and locPly or attacker
    
    deathData.camPos = tlouUtils.GetRandomCamFollowPos(followEntity, deathData.boneId ~= nil, {followEntity, locPly, "prop_ragdoll"})
    
    deathData.camAngle = nil
    deathData.fov = 100
    deathData.roll = math.Rand(-50, 50)
    
    hook.Add("CalcView", "TLOU_DeathCam", CalculateDeathCam)
    hook.Add("PostDrawHUD", "TLOU_DeathScreen", DrawDeathScreen)    
end

-- Net receives --
net.Receive("TLOU_OnPlayerDeath", function()
    local attacker = net.ReadEntity()
    SetupDeathScreen(attacker)

    if timer.Exists("CL_TLOU_DeathSequence") then return end
    
    -- NextSpawn muste be: CONVAR_OFFSET + 2.5
    timer.Create("CL_TLOU_DeathSequence", GetConVar(consts.SV_CONVAR_OFFSET):GetFloat(), 1, function()
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
net.Receive("TLOU_OnRagdollRecheck", function()
    local newRagdoll = net.ReadEntity()
    local forceChange = net.ReadBool()

    if not newRagdoll:IsValid() then return end
    if IsValid(body) and not forceChange then return end

    body = newRagdoll
    recheckedBody = newRagdoll
    deathData.boneId = tlouUtils.GetBoneId(newRagdoll)
    deathData.camPos = tlouUtils.GetRandomCamFollowPos(locPly, deathData.boneId ~= nil, {locPly, "prop_ragdoll"})

    print("Set new body: " .. tostring(body))
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
        pnl:ControlHelp("\n\nSERVER")
        pnl:CheckBox("Enable death", consts.SV_CONVAR_ENABLED)
        pnl:NumSlider("Death offset (Def: 1)", consts.SV_CONVAR_OFFSET, 0.5, 2, 1)
        pnl:TextEntry("Death message", consts.SV_CONVAR_DEATH_MESSAGE)
        pnl:ControlHelp([[
Leave empty to use default
    - SPACEs also count as custom message
        ]])

        pnl:ControlHelp("\nCLIENT")
        pnl:CheckBox("Should use death voice", consts.CONVAR_VOICE_ENABLED)
        local voiceSelect = pnl:ComboBox("Voice type", consts.CONVAR_VOICETYPE)
        voiceSelect:SetSortItems(false)
        voiceSelect:AddChoice("Auto", 0)
        voiceSelect:AddChoice("Male", 1)
        voiceSelect:AddChoice("Female", 2)
        voiceSelect:AddChoice("Combine", 3)
        voiceSelect:AddChoice("Zombie", 4)
    end)
end)