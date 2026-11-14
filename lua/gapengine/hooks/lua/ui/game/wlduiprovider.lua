-- Keep loading status updates independent of simulation-time Lua threads.
WldUIProvider.GapStartWaitingDialog = function(self)
    import('/lua/gapengine/ui/game/waiting_players.lua').Start()
    return true
end

WldUIProvider.GapUpdateWaitingDialog = function(self)
    import('/lua/gapengine/ui/game/waiting_players.lua').Update()
    return true
end

WldUIProvider.GapStopWaitingDialog = function(self)
    import('/lua/gapengine/ui/game/waiting_players.lua').Stop()
end
