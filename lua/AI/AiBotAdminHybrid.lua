--******************************************************************************************************
--** Admin hotkey controlled AiBot mode.
--**
--** The current client adds `/group admin` from its authenticated API groups.
--** The lobby turns that role into a synchronized match-start allowlist. The
--** callback maps the command source to its own human army and requires that
--** army's player name to be present in that immutable allowlist.
--******************************************************************************************************

local function GetGroupRole(brain)
    if not brain or not ScenarioInfo or not ScenarioInfo.ArmySetup then
        return false
    end

    local setup = ScenarioInfo.ArmySetup[brain.Name]
    if setup and type(setup.GroupRole) == 'string' then
        return string.lower(setup.GroupRole)
    end

    return false
end

local function IsAuthorizedAdmin(brain)
    if not brain or not ScenarioInfo or not ScenarioInfo.Options then
        return false
    end

    local adminPlayers = ScenarioInfo.Options.AiBotAdminPlayers
    if type(adminPlayers) == 'table' and adminPlayers[brain.Nickname] == true then
        return true
    end

    return false
end

local function IsHybridBrain(brain)
    return brain
        and brain.BrainType == 'Human'
        and brain.AiBotAdminRequested == true
end

local function ConfigureAiBotOptions()
    -- These option names belong to the embedded AI engine and are deliberately
    -- retained for compatibility with its internal implementation.
    ScenarioInfo.Options.AiBotCombinedArmy = 1
    ScenarioInfo.Options.AiBotCAInherit = 1
    ScenarioInfo.Options.AiBotCAEngi = 2
end

function ApplyCurrentStateToUnits(units, army)
    local brain = ArmyBrains[army]
    if not IsHybridBrain(brain) then
        return 0
    end

    local enabled = brain.AiBotAdminEnabled == true
    local value = enabled and 1 or 0
    local count = 0

    for _, unit in units or {} do
        if IsEntity(unit) and not unit.Dead and unit.Army == army then
            unit.AiBotActive = enabled
            unit:UpdateStat('AiBotActive', value)
            count = count + 1
        end
    end

    return count
end

local function ApplyCurrentStateToUnitsBatched(brain, units, army, generation)
    local enabled = brain.AiBotAdminEnabled == true
    local value = enabled and 1 or 0
    local count = 0
    local batch = 0

    for _, unit in units or {} do
        -- A second hotkey press supersedes the previous batch. This prevents
        -- an old enable pass from turning units back on after a quick disable.
        if brain.AiBotAdminApplyGeneration != generation then
            return
        end
        if IsEntity(unit) and not unit.Dead and unit.Army == army then
            unit.AiBotActive = enabled
            unit:UpdateStat('AiBotActive', value)
            count = count + 1
        end
        batch = batch + 1
        if batch >= 50 then
            batch = 0
            WaitTicks(1)
        end
    end

    brain.AiBotAdminAppliedUnitCount = count
end

local function InitializeBrain(brain, bSyncTimestamp)
    -- Auto-lobby normally supplies this table. Keep sandbox/custom launches
    -- compatible because the embedded AI records an estimated rating at setup.
    ScenarioInfo.Options.Ratings = ScenarioInfo.Options.Ratings or {}

    local overseer = import('/lua/AiBot/AI/AiBotOverseer.lua')
    if bSyncTimestamp then
        -- The old implementation set a shared timestamp here and made
        -- OnCreateBrain wait a full second. Activation already runs in its own
        -- forked thread; one tick is enough to let the current command finish.
        WaitTicks(1)
    end
    -- OnCreateBrain may already have marked this human brain as processed while
    -- another admin was being initialized.  Register all newly requested admin
    -- brains before entering that guarded setup path.
    overseer.SetAiBotActiveFlag()
    import('/lua/AiBot/AI/AiBotEvents.lua').OnCreateBrain(brain, brain.Name, true)
    ForkThread(import('/lua/AiBot/AI/AiBotChat.lua').RunAdminTauntLoop, brain)
    brain.AiBotAdminInitializing = false
end

-- Single sim-side state transition for the requested admin army.  The UI
-- hotkey/callback is the only way to enable admin-hybrid mode; it starts off.
local function SetHybridForBrain(brain, enabled, bSyncTimestamp)
    ConfigureAiBotOptions()
    brain.AiBotAdminRequested = true

    if not brain.AiBotAI and not brain.AiBotAdminInitializing then
        brain.AiBotAdminInitializing = true
        ForkThread(InitializeBrain, brain, bSyncTimestamp)
    end

    brain.AiBotAdminEnabled = enabled
    local army = brain:GetArmyIndex()
    local count = 0
    -- At game-start activation no units exist yet and every later spawn inherits
    -- AiBotActive from AiBotAdminEnabled via the unit OnCreate hook.
    local ok, units = pcall(function()
        return brain:GetListOfUnits(categories.ALLUNITS, false, false)
    end)
    if ok and units then
        brain.AiBotAdminApplyGeneration = (brain.AiBotAdminApplyGeneration or 0) + 1
        ForkThread(ApplyCurrentStateToUnitsBatched, brain, units, army, brain.AiBotAdminApplyGeneration)
        -- Report the number scheduled rather than forcing the whole army to
        -- be updated synchronously inside the hotkey callback.
        count = table.getn(units)
    end
    local event = {
        Army = army,
        Enabled = enabled,
        UnitCount = count,
    }

    Sync.AiBotAdmin = Sync.AiBotAdmin or {}
    table.insert(Sync.AiBotAdmin, event)

    LOG(string.format(
        'AiBot control %s for army %d (%d units)',
        enabled and 'enabled' or 'disabled',
        army,
        count
    ))

    return true
end

function ToggleFromCurrentCommandSource()
    local commandSource = GetCurrentCommandSource()
    local army = import('/lua/simutils.lua').GetCurrentCommandSourceArmy()
    local brain = ArmyBrains[army]
    if not brain or brain.BrainType != 'Human' then
        WARN(string.format(
            'Rejected AiBot toggle from command source %s (army %s)',
            tostring(commandSource),
            tostring(army)
        ))
        return false
    end

    local groupRole = GetGroupRole(brain)
    if not IsAuthorizedAdmin(brain) then
        WARN(string.format(
            'Rejected unauthorized AiBot toggle from command source %s (army %s, player %s, role %s)',
            tostring(commandSource),
            tostring(army),
            tostring(brain.Nickname),
            tostring(groupRole)
        ))
        return false
    end

    return SetHybridForBrain(brain, not (brain.AiBotAdminEnabled == true), true)
end

local function GetBoomTargetBrain()
    local commandSource = GetCurrentCommandSource()
    local army = import('/lua/simutils.lua').GetCurrentCommandSourceArmy()
    local brain = ArmyBrains[army]
    if not brain then
        WARN(string.format(
            'Rejected AiBot boom toggle from command source %s (army %s)',
            tostring(commandSource),
            tostring(army)
        ))
        return nil
    end
    return brain
end

function ToggleBoomFromCurrentCommandSource()
    --Boom mode applies to the brain being controlled, whether that is a
    --hybrid-controlled human brain or an AiBot AI brain on the same team.
    local brain = GetBoomTargetBrain()
    if not brain or brain.BrainType ~= 'Human' then
        WARN(string.format(
            'Rejected AiBot boom toggle for brain %s (type %s)',
            tostring(brain and brain.Nickname),
            tostring(brain and brain.BrainType)
        ))
        return false
    end

    local groupRole = GetGroupRole(brain)
    if not IsAuthorizedAdmin(brain) then
        WARN(string.format(
            'Rejected unauthorized AiBot boom toggle from command source %s (army %s, player %s, role %s)',
            tostring(GetCurrentCommandSource()),
            tostring(brain:GetArmyIndex()),
            tostring(brain.Nickname),
            tostring(groupRole)
        ))
        return false
    end

    local overseer = import('/lua/AiBot/AI/AiBotOverseer.lua')
    brain[overseer.refbBoomMode] = not (brain[overseer.refbBoomMode] == true)

    local iTeam = brain.AiBotTeam or 1
    overseer.SetTeamBoomMode(iTeam, brain[overseer.refbBoomMode] == true)
    local bTeamBoom = overseer.IsTeamBoomMode(iTeam)

    local event = {
        Army = brain:GetArmyIndex(),
        BoomMode = brain[overseer.refbBoomMode] == true,
        TeamBoom = bTeamBoom,
    }

    Sync.AiBotBoom = Sync.AiBotBoom or {}
    table.insert(Sync.AiBotBoom, event)

    LOG(string.format(
        'AiBot boom mode %s for army %d (team %d boom=%s)',
        event.BoomMode and 'enabled' or 'disabled',
        event.Army,
        iTeam,
        tostring(bTeamBoom)
    ))

    return true
end
