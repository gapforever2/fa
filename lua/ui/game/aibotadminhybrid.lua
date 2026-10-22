local GroupDev = import('/lua/ui/game/groupdev.lua')
local listenerRegistered = false
local preferenceKey = 'AiBotAdminHybrid.Enabled'

local function PrintStatus(text, color)
    import('/lua/ui/game/textdisplay.lua').PrintToScreen({
        text = text,
        size = 16,
        color = color or 'ffffffff',
        duration = 3,
        location = 'centertop',
    })
end

local function RegisterStatusListener()
    if listenerRegistered then
        return
    end

    listenerRegistered = true
    AddOnSyncHashedCallback(function(events)
        for _, event in events or {} do
            if event.Army == GetFocusArmy() then
                SetPreference(preferenceKey, event.Enabled == true)
                if event.Enabled then
                    PrintStatus(string.format('AiBot: ENABLED (%d units)', event.UnitCount or 0), 'ff80ff80')
                else
                    PrintStatus('AiBot: DISABLED', 'ffff8080')
                end
            end
        end
    end, 'AiBotAdmin', 'AiBotAdminStatus')
end

function RestoreSavedState()
    RegisterStatusListener()
end

function Toggle()
    if not GroupDev.IsAdmin() or SessionIsReplay() then
        return
    end

    local army = GetFocusArmy()
    if army < 1 then
        return
    end

    RegisterStatusListener()
    SimCallback({ Func = 'AiBotAdminToggle', Args = {} })
end
