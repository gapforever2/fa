local GroupDev = import('/lua/ui/game/groupdev.lua')
local listenerRegistered = false

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
                if event.BoomMode then
                    PrintStatus('AiBot: BOOM MODE (economy priority)', 'ff80ff80')
                else
                    PrintStatus('AiBot: boom mode off', 'ffff8080')
                end
            end
        end
    end, 'AiBotBoom', 'AiBotBoomStatus')
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
    SimCallback({ Func = 'AiBotBoomToggle', Args = {} })
end
