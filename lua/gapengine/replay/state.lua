-- Only accumulated presentation data is rewound. UI controls and camera keep
-- their existing lifetime and the viewer's current settings.
local reclaim = import('/lua/ui/game/reclaim.lua')
local score = import('/lua/ui/game/score.lua')
local knownReclaim = {}
local notificationsChecked = false
local notifications = nil
local pendingNotifications = nil

function BeforeRestore()
    -- End cursor modes while their old unit/decal objects still exist, then
    -- discard the cached mode so a modifier key cannot resurrect those objects.
    local commandMode = import('/lua/ui/game/commandmode.lua')
    commandMode.EndCommandMode(true)
    commandMode.CacheAndClearCommandMode()
    commandMode.CacheCommandMode()
    for _, view in import('/lua/ui/game/worldview.lua').MapControls or {} do
        if view.OnCursor then view:OnCursor(nil) end
    end
end

local function Notifications()
    if not notificationsChecked then
        notificationsChecked = true
        if DiskGetFileInfo('/lua/ui/notify/notify.lua') then
            local module = import('/lua/ui/notify/notify.lua')
            if rawget(module, 'ReplayCheckpointCapture') then notifications = module end
        end
    end
    return notifications
end

function Observe(sync)
    -- The replacement sync creates fresh Unit userdata after Restore runs.
    -- Resume GAF's presentation watchers on the next normal sync, once those
    -- replicas exist, using IDs instead of references into the discarded world.
    if pendingNotifications then
        local saved = pendingNotifications
        pendingNotifications = nil
        Notifications().ReplayCheckpointRestore(saved)
    end
    if sync.Reclaim then
        for id, point in sync.Reclaim do
            knownReclaim[id] = point or nil
        end
    end
end

function Capture()
    local notify = Notifications()
    return {
        units = UnitData,
        scores = score.currentScores or {},
        reclaim = knownReclaim,
        notifications = notify and notify.ReplayCheckpointCapture() or nil,
    }
end

function Restore(state)
    local notify = Notifications()
    if notify then notify.ReplayCheckpointReset() end
    pendingNotifications = state.notifications
    local removed = {}
    for id in knownReclaim do
        removed[id] = false
    end
    reclaim.UpdateReclaim(removed)
    knownReclaim = state.reclaim or {}
    reclaim.UpdateReclaim(knownReclaim)
    _G.UnitData = state.units or {}
    score.currentScores = state.scores or {}
    _G.Sync = {}
    _G.PreviousSync = {}
end
