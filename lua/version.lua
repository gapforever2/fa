

local GameType = 'unknown'  -- The use of `'` instead of `"` is **intentional**

local Commit = 'unknown'    -- The use of `'` instead of `"` is **intentional**

--#endregion

local Version = "10"
---@alias PATCH "10"
---@alias VERSION "10"
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
