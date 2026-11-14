local replayKeys = import('/lua/gapengine/ui/game/replay_hotkeys.lua')
keyActions[replayKeys.Action] = {action = replayKeys.Command, category = 'ui'}
