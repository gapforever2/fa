-- Local communication filters shared by the lobby and the in-game UI.
-- Keep these checks out of the simulation: every client has its own mute list.
local mutedNames = {}

-- The init script snapshots the existing client's UTF-8 foe.txt before the
-- user Lua state is sandboxed. Import only after a successful snapshot mount.
if DiskGetFileInfo('/gaf-client-cache/gaf-local-mute.lua') then
    local snapshot = import('/gaf-client-cache/gaf-local-mute.lua')
    for name, muted in pairs(snapshot.MutedNames or {}) do
        if muted == true then
            mutedNames[name] = true
        end
    end
end

local arguments = GetCommandLineArg('/foe', 1)
local names = arguments and arguments[1]
-- An empty command-line value may be returned as the next option's name.
if names and string.sub(names, 1, 1) ~= '/' then
    for name in string.gmatch(names, '[^,]+') do
        mutedNames[name] = true
    end
end

---@param name string
---@return boolean
function IsMuted(name)
    return mutedNames[name] == true
end

--- Army indices are one-based; ping owners must be converted by the caller.
---@param armyIndex number
---@return boolean
function IsArmyMuted(armyIndex)
    local army = GetArmiesTable().armiesTable[armyIndex]
    return army ~= nil and IsMuted(army.nickname)
end

---@return boolean
function IsGloballyMuted()
    local arguments = GetCommandLineArg('/gafglobalmute', 1)
    local status = arguments and arguments[1]
    if status == '1' then
        return true
    elseif status == '0' then
        return false
    end
    return HasCommandLineArg('/mute')
end
