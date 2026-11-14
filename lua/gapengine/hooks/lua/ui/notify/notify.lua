-- This hook is concatenated with GAF's notify module, so its private ACU
-- records can be checkpointed without retaining Unit userdata or threads.
local onStartBeforeReplayCheckpoint = onStartEnhancement
function onStartEnhancement(id, army, category, source)
    onStartBeforeReplayCheckpoint(id, army, category, source)
    if id and ACUs[id] then
        -- A replay's interpolated UI clock differs between ordinary playback
        -- and seek catch-up. Enhancement events belong to their displayed sim
        -- tick, so their retained start time must use that same tick in both.
        if SessionIsReplay() then
            local timeline = GetReplaySeekInfo()
            if timeline.current then ACUs[id].startTime = timeline.current end
        end
        ACUs[id].replayCategory = category
        ACUs[id].replaySource = source
    end
end

function ReplayCheckpointCapture()
    local units = {}
    for id, data in ACUs do
        if data.watcher and data.replayCategory and data.replaySource then
            units[id] = {
                army = data.army, startTime = data.startTime,
                category = data.replayCategory, source = data.replaySource,
            }
        end
    end
    return {units = units, counts = messageCounts}
end

function ReplayCheckpointReset()
    for _, data in ACUs do
        if data.watcher then KillThread(data.watcher) end
    end
    ACUs = {}
    messageCounts = {}
    for _, overlay in NotifyOverlay.overlays do overlay:Destroy() end
    NotifyOverlay.overlays = {}
end

function ReplayCheckpointRestore(state)
    messageCounts = state.counts or {}
    for id, saved in state.units or {} do
        if GetUnitById(id) then
            local categoryMessages = messages and messages()[saved.category]
            local text = categoryMessages and categoryMessages[saved.source]
            if text then
                local data = {
                    id = id, army = saved.army, startTime = saved.startTime,
                    replayCategory = saved.category, replaySource = saved.source,
                }
                ACUs[id] = data
                data.watcher = ForkThread(watchEnhancement, id, text, saved.category, saved.source)
            end
        end
    end
end

-- GAF game-data hook (lua/gapengine/hooks in lua.nx2): appended to
-- /lua/ui/notify/notify.lua.

--- The replay viewer's new sim: the units these threads watch are gone, and each looked its unit up once.
--- FAF's notify.lua may define it already (issue #327). rawget on the module: FAF's Lua errors on reading a global
--- that doesn't exist.
if not rawget(getfenv(1), 'KillAllWatchers') then
    function KillAllWatchers()
        for _, data in ACUs do
            killWatcher(data)
        end
    end

    --- As FAF's, but it stops when its unit is gone: a replay move can remove the units while it loads, before
    --- KillAllWatchers runs.
    function watchEnhancement(id, text, category, source)
        local overlayData = {}
        overlayData.unit = GetUnitById(id)
        overlayData.pos = overlayData.unit:GetPosition()
        overlayData.msg = {to = 'allies', NotifyOverlay = true, data = {id = id, text = text, category = category, source = source}}
        overlayData.eta = -1

        while true do
            if IsDestroyed(overlayData.unit) then
                local data = ACUs[id]
                if data and data.watcher == CurrentThread() then
                    data.watcher = false
                    NotifyOverlay.sendDestroyOverlayMessage(id)
                end
                return
            end
            NotifyOverlay.generateEnhancementMessage(overlayData)
            WaitSeconds(0.1)
        end
    end
end
