local replayKeys = import('/lua/gapengine/ui/game/replay_hotkeys.lua')
local originalCurrentKeyMap = GetCurrentKeyMap
function GetCurrentKeyMap()
    return replayKeys.DefaultMapping(originalCurrentKeyMap())
end

local originalBinding = GetCurrentKeyBinding
function GetCurrentKeyBinding(action)
    if action == replayKeys.Action then return replayKeys.Binding() end
    return originalBinding(action)
end

local originalClear = ClearUserKeyMapping
function ClearUserKeyMapping(key)
    local wasReplay = key and GetCurrentKeyMap()[key] == replayKeys.Action
    originalClear(key)
    if wasReplay then replayKeys.MarkConfigured(true) end
end

local originalSet = SetUserKeyMapping
function SetUserKeyMapping(key, oldKey, action)
    originalSet(key, oldKey, action)
    if key and action == replayKeys.Action then replayKeys.MarkConfigured(true) end
end

local originalReset = ResetUserKeyMapTo
function ResetUserKeyMapTo(preset)
    replayKeys.MarkConfigured(false)
    originalReset(preset)
end

local originalClearAll = ClearUserKeyMap
function ClearUserKeyMap()
    replayKeys.MarkConfigured(false)
    originalClearAll()
end
