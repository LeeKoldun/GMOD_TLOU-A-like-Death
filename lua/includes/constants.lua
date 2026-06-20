-- NAME CONSTANTS
local CMD_PREFIX = "tlou_death_"
local SV_CMD_PREFIX = "sv_" .. CMD_PREFIX

---@class TlouConstants
local TLOU_CONSTANTS = {
    SV_CONVAR_ENABLED = CMD_PREFIX .. "enabled",
    CONVAR_VOICETYPE = CMD_PREFIX .. "voicetype",
    CONVAR_VOICE_ENABLED = CMD_PREFIX .. "voice_enabled",
    
    SV_CONVAR_OFFSET = SV_CMD_PREFIX .. "offset",
    SV_CONVAR_DEATH_MESSAGE = SV_CMD_PREFIX .. "death_message",
}

return TLOU_CONSTANTS