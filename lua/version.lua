

local GameType = 'unknown'  -- The use of `'` instead of `"` is **intentional**

local Commit = 'unknown'    -- The use of `'` instead of `"` is **intentional**

--#endregion

local Version = "9"
---@alias PATCH "9"
---@alias VERSION "9"
---@return PATCH    # Game release
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
