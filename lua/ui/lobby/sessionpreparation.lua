-- Map blueprints are loaded in a separate Lua state through PreGameData.
-- Persist the selected map before any background load or final launch.

---@param scenarioFile string
function PrepareMap(scenarioFile)
    local preGameData = GetPreference('PreGameData') or {}
    preGameData.CurrentMapDir = Dirname(scenarioFile)
    SetPreference('PreGameData', preGameData)
    SavePreferences()
end
