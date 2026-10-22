-- Deliberately replaces the upstream permissive per-selection callback. The hotkey
-- toggles the entire command-source army and validation happens in SIM.
local AiBotAdminHybrid = import('/lua/AI/AiBotAdminHybrid.lua')
RegisterSimCallback('AiBotAdminToggle', function(data, units)
    AiBotAdminHybrid.ToggleFromCurrentCommandSource()
end)

-- Boom (economy priority) mode toggle, same authorization path as hybrid control.
RegisterSimCallback('AiBotBoomToggle', function(data, units)
    AiBotAdminHybrid.ToggleBoomFromCurrentCommandSource()
end)
