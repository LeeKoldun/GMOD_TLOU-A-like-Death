-- NAME CONSTANTS
local CMD_PREFIX = "tlou_death_"
local SV_CMD_PREFIX = "sv_" .. CMD_PREFIX

-- Convars --
TD_CVAR_ENABLED = CreateConVar(SV_CMD_PREFIX .. "enabled", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should TLOU a-like death be enabled", 0, 1)
TD_CVAR_DEATHMESSAGE = CreateConVar(SV_CMD_PREFIX .. "death_message", "", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Custom death message")
TD_CVAR_DEATHOFFSET = CreateConVar(SV_CMD_PREFIX .. "offset", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How far should offset the death screen sequence", 0.1, 5)

TD_CLCVAR_FOLLOW_ATTACKER = CreateClientConVar(CMD_PREFIX .. "follow_attacker", "0", true, true, "Should cam follow attacker if player's ragdoll is invalid", 0, 1)
TD_CLCVAR_FACE_PLAYER = CreateClientConVar(CMD_PREFIX .. "track_face", "0", true, true, "Should cam try to face player on death", 0, 1)
TD_CLCVAR_VOICE_ENABLED = CreateClientConVar(CMD_PREFIX .. "voice_enabled", "1", true, true, "Should death voice be enabled", 0, 1)
TD_CLCVAR_VOICETYPE =  CreateClientConVar(CMD_PREFIX .. "voicetype", "0", true, true, [[
    0 - auto
    1 - male
    2 - female
    3 - combine
    4 - zombie]], 0, 4)