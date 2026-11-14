-- GAF game-data replay UI. The original game's CreateUI owns its lifetime.
local createUIBeforeReplayTimeline = CreateUI
function CreateUI(isReplay)
    createUIBeforeReplayTimeline(isReplay)
    if not isReplay then
        import('/lua/gapengine/ui/game/lag_warning.lua').Create(GetGameParent())
    else
        if GetCommandLineArg('/upstreamreplaytimeline', 0) then
            if not DiskGetFileInfo('/lua/ui/game/replay_timeline.lua') then
                import('/lua/gapengine/ui/game/replay_timeline.lua').Create()
            end
        else
            import('/lua/gapengine/replay/timeline.lua').Create(GetGameParent())
        end
    end
end

-- The connectivity dialog and session teardown can close the loading panel.
local killWaitingDialogBeforeGap = KillWaitingDialog
function KillWaitingDialog()
    import('/lua/gapengine/ui/game/waiting_players.lua').Stop()
    if killWaitingDialogBeforeGap then
        killWaitingDialogBeforeGap()
    end
end
