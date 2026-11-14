Action = 'gap_replay_toggle_panel'
Command = "UI_Lua import('/lua/gapengine/ui/game/replay_hotkeys.lua').Toggle()"
local Prefs = import('/lua/user/prefs.lua')
local configured = 'GapReplayHotkeyConfigured'

function DefaultMapping(map)
    -- A saved assignment or explicit unbind always wins. Never take a key
    -- already used by another action, including hotbuild's debug bindings.
    for _, action in map do if action == Action then return map end end
    if Prefs.GetFromCurrentProfile(configured) then return map end
    for _, key in {'Ctrl-T', 'Ctrl-Shift-T'} do
        if not map[key] then map[key] = Action; break end
    end
    return map
end

function MarkConfigured(value)
    Prefs.SetToCurrentProfile(configured, value)
end

function Binding()
    for key, action in import('/lua/keymap/keymapper.lua').GetCurrentKeyMap() do
        if action == Action then return key end
    end
    return false
end

function Hint()
    local key = Binding()
    local russian = string.lower(__language or '') == 'ru'
    return (key and string.gsub(key, '-', '+') or (russian and 'Не назначено' or 'Unbound'))
        .. (russian and ' · F1: настройка клавиш' or ' · F1: key bindings')
end

function Install()
    local keys = {}
    for key, action in import('/lua/keymap/keymapper.lua').GetCurrentKeyMap() do
        if action == Action then keys[key] = {action = Command} end
    end
    IN_AddKeyMapTable(keys)
end

function Toggle()
    if not SessionIsReplay() then return end
    if GetCommandLineArg('/upstreamreplaytimeline', 0) then
        import('/lua/gapengine/ui/game/replay_timeline.lua').Toggle()
    else
        import('/lua/gapengine/replay/timeline.lua').Toggle()
    end
end
