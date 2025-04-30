local GameType = "GAF"
local Commit = "GAF Balance"
local Version = "7"

---@alias PATCH "7"
---@alias VERSION "7"
---@return PATCH
function GetVersion()
    LOG(string.format('Supreme Commander: Forged Alliance Lua version %s at %s (%s)', Version, GameType, Commit))
    return Version
end

---@return PATCH
---@return string # game type
---@return string # commit hash
function GetVersionData()
    return Version, GameType, Commit
end
