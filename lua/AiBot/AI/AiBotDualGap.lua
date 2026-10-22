-- Dual Gap role policy.
--
-- This module intentionally has no AiBot imports. AiBotMap and AiBotOverseer
-- import each other, so keeping this map data independent avoids another
-- circular import during brain creation.

-- This table is only a compatibility fallback for older DualGap versions.
-- Army indices are lobby/order data and are not a reliable indication of a
-- slot when the map or the lobby reorders player starts.
local RoleByArmyIndexFallback = {
    [1] = 'top_air',
    [2] = 'top_air',
    [3] = 'mid',
    [4] = 'mid',
    [5] = 'navy',
    [6] = 'navy',
    [7] = 'bottom_air',
    [8] = 'bottom_air',
    [9] = 'upper_mid',
    [10] = 'upper_mid',
    [11] = 'eco',
    [12] = 'eco',
}

-- DualGap Adaptive v14 start positions. Resolve the role from the actual
-- position assigned to the brain, not from GetArmyIndex(). This also gives us
-- a useful diagnostic when a lobby assigns a different army number to a slot.
local DualGapAdaptiveV14StartPositions = {
    { anchorArmy = 1, slot = 'top_air_left', role = 'top_air', x = 112.5, z = 390.5 },
    { anchorArmy = 2, slot = 'top_air_right', role = 'top_air', x = 911.5, z = 390.5 },
    { anchorArmy = 3, slot = 'mid_left', role = 'mid', x = 184.5, z = 466.5 },
    { anchorArmy = 4, slot = 'mid_right', role = 'mid', x = 839.5, z = 466.5 },
    { anchorArmy = 5, slot = 'navy_left', role = 'navy', x = 159.5, z = 609.5 },
    { anchorArmy = 6, slot = 'navy_right', role = 'navy', x = 864.5, z = 609.5 },
    { anchorArmy = 7, slot = 'bottom_air_left', role = 'bottom_air', x = 148.5, z = 681.5 },
    { anchorArmy = 8, slot = 'bottom_air_right', role = 'bottom_air', x = 875.5, z = 681.5 },
    { anchorArmy = 9, slot = 'upper_mid_left', role = 'upper_mid', x = 139.5, z = 436.5 },
    { anchorArmy = 10, slot = 'upper_mid_right', role = 'upper_mid', x = 884.5, z = 436.5 },
    { anchorArmy = 11, slot = 'eco_left', role = 'eco', x = 114.5, z = 639.5 },
    { anchorArmy = 12, slot = 'eco_right', role = 'eco', x = 909.5, z = 639.5 },
}

-- Air slots own their eight home mexes. DualGap Adaptive v14 also has
-- central/side mexes which are intentionally left to the mid/expansion slots.
-- Keep this list in world coordinates because adaptive resource scaling makes
-- the map marker order unsuitable as a stable runtime identifier.
local DualGapAdaptiveV14AirMexPositionsByAnchorArmy = {
    [1] = {
        {112.5, 398.5}, {112.5, 382.5}, {128.5, 382.5}, {112.5, 378.5},
        {128.5, 378.5}, {128.5, 398.5}, {112.5, 402.5}, {128.5, 402.5},
    },
    [2] = {
        {911.5, 382.5}, {911.5, 398.5}, {895.5, 382.5}, {911.5, 378.5},
        {895.5, 378.5}, {895.5, 398.5}, {911.5, 402.5}, {895.5, 402.5},
    },
    [7] = {
        {148.5, 673.5}, {148.5, 689.5}, {164.5, 673.5}, {148.5, 669.5},
        {164.5, 669.5}, {164.5, 689.5}, {148.5, 693.5}, {164.5, 693.5},
    },
    [8] = {
        {875.5, 673.5}, {875.5, 689.5}, {859.5, 673.5}, {875.5, 669.5},
        {859.5, 669.5}, {859.5, 689.5}, {875.5, 693.5}, {859.5, 693.5},
    },
}

local Profiles = {
    top_air = {
        primary = 'air',
        secondary = 'land',
        prioritiseAir = true,
        prioritiseHighTech = true,
        navyUnlock = 600,
        commitmentEnd = 600,
        airUnlock = 0,
        factoryLimits = { land = 1, air = 2 },
        mexUpgradeStart = 130,
        mexUpgradeSpacing = 10,
        mexUpgradeTargetCount = 8,
        airTechRushTime = 150,
        airT3TechRushTime = 330,
        airTechTarget = 3,
        t2PowerRushTime = 300,
        t3PowerRushTime = 510,
        reclaimEngineerCount = 30,
    },
    upper_mid = {
        primary = 'land',
        secondary = 'air',
        prioritiseLand = true,
        navyUnlock = 600,
        commitmentEnd = 360,
        airUnlock = 180,
        factoryLimits = { land = 2, air = 1 },
    },
    mid = {
        primary = 'land',
        secondary = 'navy',
        prioritiseLand = true,
        -- The mid slot's normal opening is a land HQ into early mex upgrades,
        -- not a second T1 land factory. High-tech priority makes the generic
        -- economy scheduler consider the first land HQ upgrade sooner.
        prioritiseHighTech = true,
        navyUnlock = 480,
        commitmentEnd = 360,
        airUnlock = 0,
        factoryLimits = { land = 1, air = 0 },
        landTechRushTime = 300,
        landTechTarget = 3,
        navyFactoryLimit = 1,
        mexUpgradeStart = 180,
        mexUpgradeSpacing = 20,
    },
    navy = {
        primary = 'navy',
        secondary = 'land',
        prioritiseNavy = true,
        navyUnlock = 0,
        commitmentEnd = 360,
        airUnlock = 600,
        factoryLimits = { land = 1, air = 0, navy = 2 },
    },
    eco = {
        primary = 'eco',
        secondary = 'air',
        prioritiseAir = true,
        prioritiseHighTech = true,
        navyUnlock = 900,
        commitmentEnd = 600,
        airUnlock = 0,
        factoryLimits = { land = 1, air = 2 },
        mexUpgradeStart = 130,
        mexUpgradeSpacing = 10,
        mexUpgradeTargetCount = 8,
        airTechRushTime = 150,
        airT3TechRushTime = 330,
        airTechTarget = 3,
        t2PowerRushTime = 300,
        t3PowerRushTime = 510,
        reclaimEngineerCount = 30,
    },
    bottom_air = {
        primary = 'air',
        secondary = 'land',
        prioritiseAir = true,
        prioritiseHighTech = true,
        navyUnlock = 600,
        commitmentEnd = 600,
        airUnlock = 0,
        factoryLimits = { land = 1, air = 2 },
        mexUpgradeStart = 130,
        mexUpgradeSpacing = 10,
        mexUpgradeTargetCount = 8,
        airTechRushTime = 150,
        airT3TechRushTime = 330,
        airTechTarget = 3,
        t2PowerRushTime = 300,
        t3PowerRushTime = 510,
        reclaimEngineerCount = 30,
    },
}

-- A human admin brain can be enabled after the normal startup sweep.  Give
-- the scenario metadata a short, fixed window to become available before we
-- fall back to the generic AiBot profile.
local DualGapDetectionDeadlineSeconds = 20

local function GetScenarioMapName()
    local name = tostring(ScenarioInfo and ScenarioInfo.name or '')
    local scenarioFile = tostring(ScenarioInfo and ScenarioInfo.ScenarioFile or '')
    local optionScenarioFile = tostring(ScenarioInfo and ScenarioInfo.Options and ScenarioInfo.Options.ScenarioFile or '')
    return string.lower(name..' '..scenarioFile..' '..optionScenarioFile)
end

local function IsDualGapMap()
    -- Accept the common spellings: DualGap, Dual Gap and Dual_Gap.
    local normalizedName = string.gsub(GetScenarioMapName(), '[^%w]', '')
    if string.find(normalizedName, 'dualgap', 1, true) ~= nil then
        return true
    end

    -- The Adaptive v14 map can arrive with a generated/non-descriptive
    -- ScenarioInfo.name.  Its version and 10x10 size are stable identifiers
    -- for this map family and let late admin activation recognize it anyway.
    local mapVersion = tonumber(ScenarioInfo and ScenarioInfo.map_version or 0) or 0
    local mapSize = ScenarioInfo and ScenarioInfo.size
    return mapVersion == 14 and mapSize and mapSize[1] == 1024 and mapSize[2] == 1024
end

local function GetMapVersion()
    return tonumber(ScenarioInfo and ScenarioInfo.map_version or 0) or 0
end

local function GetRoleFromStartPosition(aiBrain)
    local ok, startX, startZ = pcall(function()
        return aiBrain:GetArmyStartPos()
    end)

    if not ok or type(startX) ~= 'number' or type(startZ) ~= 'number' then
        return nil, nil, startX, startZ, nil, 'start_position_unavailable', nil
    end

    local nearest
    local nearestDistanceSq
    for _, anchor in DualGapAdaptiveV14StartPositions do
        local dx = startX - anchor.x
        local dz = startZ - anchor.z
        local distanceSq = dx * dx + dz * dz
        if not nearestDistanceSq or distanceSq < nearestDistanceSq then
            nearest = anchor
            nearestDistanceSq = distanceSq
        end
    end

    -- The saved map coordinates are exact. Keep a small tolerance for a
    -- scenario that nudges a start marker by a few world units.
    if nearest and nearestDistanceSq <= (75 * 75) then
        return nearest.role, nearest.slot, startX, startZ, nearestDistanceSq, 'start_position', nearest.anchorArmy
    end

    return nil, nil, startX, startZ, nearestDistanceSq, 'start_position_unresolved', nearest and nearest.anchorArmy
end

function GetProfileForBrain(aiBrain)
    if not aiBrain then
        return nil
    end

    local role
    local slot
    local startX
    local startZ
    local distanceSq
    local source
    local anchorArmy

    -- Prefer the actual start marker whenever it is available.  Some Dual
    -- Gap scenario names are generated or localized, and some versions do
    -- not expose map_version consistently.  The position is the reliable
    -- identifier for the slot in that case.
    role, slot, startX, startZ, distanceSq, source, anchorArmy = GetRoleFromStartPosition(aiBrain)

    if not role and IsDualGapMap() then
        role = RoleByArmyIndexFallback[aiBrain:GetArmyIndex()]
        source = 'army_index_fallback'
    end

    if not role then
        return nil
    end

    local profile = Profiles[role]

    return role, profile, slot, startX, startZ, distanceSq, source, anchorArmy
end

function ApplyToBrain(aiBrain)
    local role, profile, slot, startX, startZ, distanceSq, source, anchorArmy = GetProfileForBrain(aiBrain)
    if not profile then
        if IsDualGapMap() and not aiBrain.AiBotDualGapRoleUnresolvedLogged then
            LOG('AiBot Dual Gap role unresolved: army='..tostring(aiBrain:GetArmyIndex())..'; source='..tostring(source)..'; start='..tostring(startX)..','..tostring(startZ)..'; nearest anchor army='..tostring(anchorArmy)..'; distanceSq='..tostring(distanceSq))
            aiBrain.AiBotDualGapRoleUnresolvedLogged = true
        end
        return nil
    end

    aiBrain.AiBotDualGapRole = role
    aiBrain.AiBotDualGapSlot = slot or 'unknown'
    aiBrain.AiBotDualGapPositionSource = source or 'unknown'
    aiBrain.AiBotDualGapAnchorArmy = anchorArmy
    aiBrain.AiBotDualGapStartX = startX
    aiBrain.AiBotDualGapStartZ = startZ
    aiBrain.AiBotDualGapStartDistanceSq = distanceSq
    aiBrain.AiBotDualGapSide = string.find(aiBrain.AiBotDualGapSlot, '_left', 1, true) and 'left'
            or (string.find(aiBrain.AiBotDualGapSlot, '_right', 1, true) and 'right' or nil)
    aiBrain.AiBotDualGapPrimary = profile.primary
    aiBrain.AiBotDualGapSecondary = profile.secondary
    aiBrain.AiBotDualGapNavyUnlock = profile.navyUnlock
    aiBrain.AiBotDualGapCommitmentEnd = profile.commitmentEnd
    aiBrain.AiBotDualGapAirUnlock = profile.airUnlock or 0
    aiBrain.AiBotDualGapFactoryLimits = profile.factoryLimits
    aiBrain.AiBotDualGapMexUpgradeStart = profile.mexUpgradeStart
    aiBrain.AiBotDualGapMexUpgradeSpacing = profile.mexUpgradeSpacing
    aiBrain.AiBotDualGapMexUpgradeTargetCount = profile.mexUpgradeTargetCount
    aiBrain.AiBotDualGapAirTechRushTime = profile.airTechRushTime
    aiBrain.AiBotDualGapAirT3TechRushTime = profile.airT3TechRushTime
    aiBrain.AiBotDualGapAirTechTarget = profile.airTechTarget
    aiBrain.AiBotDualGapT2PowerRushTime = profile.t2PowerRushTime
    aiBrain.AiBotDualGapT3PowerRushTime = profile.t3PowerRushTime
    aiBrain.AiBotDualGapLandTechRushTime = profile.landTechRushTime
    aiBrain.AiBotDualGapLandTechTarget = profile.landTechTarget
    aiBrain.AiBotDualGapNavyFactoryLimit = profile.navyFactoryLimit
    -- DualGap has enough reclaim near the starting lanes to justify keeping a
    -- small reclaim crew active even after the economy is no longer stalling.
    aiBrain.AiBotDualGapReclaimAlways = profile.reclaimAlways ~= false
    aiBrain.AiBotDualGapReclaimEngineerCount = profile.reclaimEngineerCount or 2
    aiBrain.AiBotDualGapRolePhase = 'commitment'

    -- Keep the role contract measurable in the game log without polling every
    -- frame. These two checkpoints match the mid-slot milestones and help us
    -- distinguish economy scheduling from factory selection problems.
    if not aiBrain.AiBotDualGapProgressLogStarted then
        aiBrain.AiBotDualGapProgressLogStarted = true
        ForkThread(function()
            local loggedFiveMinutes = false
            local loggedSevenMinutes = false
            local loggedTenMinutes = false
            local loggedFifteenMinutes = false
            while not aiBrain:IsDefeated() and not aiBrain.AiBotIsDefeated do
                local now = GetGameTimeSeconds()
                if not loggedFiveMinutes and now >= 300 then
                    LOG('AiBot Dual Gap progress: army='..tostring(aiBrain:GetArmyIndex())..'; role='..tostring(aiBrain.AiBotDualGapRole)..'; time='..tostring(now)..'; t1 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH1))..'; t2 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH2))..'; land fac='..tostring(aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE))..'; t2 land fac='..tostring(aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE * categories.TECH2))..'; air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE))..'; t2 air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE * categories.TECH2))..'; t3 air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE * categories.TECH3)))
                    loggedFiveMinutes = true
                end
                if not loggedSevenMinutes and now >= 420 then
                    LOG('AiBot Dual Gap progress: army='..tostring(aiBrain:GetArmyIndex())..'; role='..tostring(aiBrain.AiBotDualGapRole)..'; time='..tostring(now)..'; t1 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH1))..'; t2 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH2))..'; land fac='..tostring(aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE))..'; t2 land fac='..tostring(aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE * categories.TECH2))..'; air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE))..'; t2 air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE * categories.TECH2))..'; t3 air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE * categories.TECH3))..'; t2 pd='..tostring(aiBrain:GetCurrentUnits(categories.DEFENSE * categories.DIRECTFIRE * categories.STRUCTURE * categories.TECH2))..'; t2 power='..tostring(aiBrain:GetCurrentUnits(categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.TECH2)))
                    loggedSevenMinutes = true
                end
                if not loggedTenMinutes and now >= 600 then
                    LOG('AiBot Dual Gap progress: army='..tostring(aiBrain:GetArmyIndex())..'; role='..tostring(aiBrain.AiBotDualGapRole)..'; time='..tostring(now)..'; t1 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH1))..'; t2 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH2))..'; t3 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH3))..'; land fac='..tostring(aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE))..'; t2 land fac='..tostring(aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE * categories.TECH2))..'; air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE))..'; t2 air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE * categories.TECH2))..'; t3 air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE * categories.TECH3))..'; t2 pd='..tostring(aiBrain:GetCurrentUnits(categories.DEFENSE * categories.DIRECTFIRE * categories.STRUCTURE * categories.TECH2))..'; t2 power='..tostring(aiBrain:GetCurrentUnits(categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.TECH2))..'; t3 power='..tostring(aiBrain:GetCurrentUnits(categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.TECH3))..'; t3 strat='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.BOMBER * categories.TECH3)))
                    loggedTenMinutes = true
                end
                if not loggedFifteenMinutes and now >= 900 then
                    LOG('AiBot Dual Gap progress: army='..tostring(aiBrain:GetArmyIndex())..'; role='..tostring(aiBrain.AiBotDualGapRole)..'; time='..tostring(now)..'; t1 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH1))..'; t2 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH2))..'; t3 mex='..tostring(aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH3))..'; t3 air fac='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.FACTORY * categories.STRUCTURE * categories.TECH3))..'; t2 power='..tostring(aiBrain:GetCurrentUnits(categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.TECH2))..'; t3 power='..tostring(aiBrain:GetCurrentUnits(categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.TECH3))..'; t3 strat='..tostring(aiBrain:GetCurrentUnits(categories.AIR * categories.BOMBER * categories.TECH3)))
                    loggedFifteenMinutes = true
                end
                if loggedFiveMinutes and loggedSevenMinutes and loggedTenMinutes and loggedFifteenMinutes then
                    break
                end
                WaitSeconds(5)
            end
        end)
    end

    return profile
end

-- Apply the map-specific profile once ScenarioInfo has been populated.  This
-- matters for late admin activation: the brain can be created before the map
-- name/start metadata is visible to the Lua layer.
function ApplyToBrainWhenReady(aiBrain)
    local detectionDeadline = DualGapDetectionDeadlineSeconds
    local mapName
    local startX
    local startZ

    while true do
        local profile = ApplyToBrain(aiBrain)
        if profile then
            return profile
        end

        mapName = GetScenarioMapName()
        -- If the start position is already available and does not match a
        -- Dual Gap slot, this is a normal map.  If it is not available yet,
        -- keep the requested startup window instead of trusting a generic
        -- or localized ScenarioInfo.name too early.
        local _, _, probeStartX, probeStartZ = GetRoleFromStartPosition(aiBrain)
        startX = probeStartX
        startZ = probeStartZ
        if mapName ~= '' and not IsDualGapMap() and (startX or startZ) then
            return nil
        end

        if GetGameTimeSeconds() >= detectionDeadline then
            LOG('AiBot Dual Gap detection timed out: army='..tostring(aiBrain:GetArmyIndex())..'; map='..tostring(mapName)..'; map_version='..tostring(ScenarioInfo and ScenarioInfo.map_version or 'nil'))
            return nil
        end

        WaitTicks(1)
    end
end

local function IsDualGapAirRole(aiBrain)
    return aiBrain and (aiBrain.AiBotDualGapRole == 'top_air'
            or aiBrain.AiBotDualGapRole == 'bottom_air'
            or aiBrain.AiBotDualGapRole == 'eco')
end

local function IsAllowedAirMexPosition(aiBrain, position)
    if not IsDualGapAirRole(aiBrain) or GetMapVersion() ~= 14 or not position then
        return true
    end

    local allowedPositions = DualGapAdaptiveV14AirMexPositionsByAnchorArmy[aiBrain.AiBotDualGapAnchorArmy]
    if not allowedPositions then
        return true
    end

    local x = position[1]
    local z = position[3] or position[2]
    if type(x) ~= 'number' or type(z) ~= 'number' then
        return true
    end

    for _, allowedPosition in allowedPositions do
        local dx = x - allowedPosition[1]
        local dz = z - allowedPosition[2]
        if dx * dx + dz * dz <= 3 * 3 then
            return true
        end
    end
    return false
end

function IsAirHomeMexZone(aiBrain, mexLocations)
    if not IsDualGapAirRole(aiBrain) or GetMapVersion() ~= 14 then
        return true
    end
    if not mexLocations then
        return false
    end
    for _, position in mexLocations do
        if IsAllowedAirMexPosition(aiBrain, position) then
            return true
        end
    end
    return false
end

-- The generic engineer scheduler searches the land zone around the engineer.
-- On DualGap that can be the central zone even when the engineer belongs to
-- an air slot.  Give that search a home-mex anchor first, so it discovers the
-- air player's own resource zone instead of selecting a central mex and then
-- being rejected by CanBuildMexAt().
function GetAirMexSearchPosition(aiBrain, position)
    if not IsDualGapAirRole(aiBrain) or GetMapVersion() ~= 14 or not position then
        return nil
    end
    if GetGameTimeSeconds() >= 600 then
        return nil
    end

    local allowedPositions = DualGapAdaptiveV14AirMexPositionsByAnchorArmy[aiBrain.AiBotDualGapAnchorArmy]
    if not allowedPositions then
        return nil
    end

    local x = position[1]
    local z = position[3] or position[2]
    if type(x) ~= 'number' or type(z) ~= 'number' then
        return nil
    end

    local nearestPosition
    local nearestDistanceSq
    for _, allowedPosition in allowedPositions do
        local dx = x - allowedPosition[1]
        local dz = z - allowedPosition[2]
        local distanceSq = dx * dx + dz * dz
        if not nearestDistanceSq or distanceSq < nearestDistanceSq then
            nearestPosition = allowedPosition
            nearestDistanceSq = distanceSq
        end
    end

    if nearestPosition then
        local targetX = nearestPosition[1]
        local targetZ = nearestPosition[2]
        if nearestDistanceSq > 3 * 3 then
            local now = GetGameTimeSeconds and GetGameTimeSeconds() or 0
            if not aiBrain.AiBotDualGapMexSearchLogTime or now - aiBrain.AiBotDualGapMexSearchLogTime >= 30 then
                LOG('AiBot Dual Gap mex search reanchored: army='..tostring(aiBrain:GetArmyIndex())..'; role='..tostring(aiBrain.AiBotDualGapRole)..'; from='..tostring(x)..','..tostring(z)..'; home='..tostring(targetX)..','..tostring(targetZ)..'; time='..tostring(now))
                aiBrain.AiBotDualGapMexSearchLogTime = now
            end
        end
        return {targetX, GetSurfaceHeight(targetX, targetZ), targetZ}
    end
    return nil
end

-- Return false only for a DualGap Adaptive v14 air slot attempting to build
-- outside its own eight starting mexes. Other maps/roles retain the generic
-- bot behaviour, and an unresolved slot is never hard-blocked.
function CanBuildMexAt(aiBrain, position)
    if not IsDualGapAirRole(aiBrain) or GetMapVersion() ~= 14 or not position then
        return true
    end

    -- From minute ten an air/eco player may rescue genuinely unclaimed mexes
    -- missed by teammates. Normal buildability/ownership checks still reject
    -- occupied points; this only removes the eight-home-mex role restriction.
    if GetGameTimeSeconds() >= 600 then
        local bSerialT3MexPhase = aiBrain:GetCurrentUnits(categories.AIR * categories.BOMBER * categories.TECH3) > 0
                and aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH3) < 8
        if not bSerialT3MexPhase then
            return true
        end
        -- Once the strat is ready, finish the eight-home-mex T3 push before
        -- spending mass on further expansion mexes. Expansion automatically
        -- reopens as soon as that milestone is complete.
    end

    local x = position[1]
    local z = position[3]
    if type(x) ~= 'number' or type(z) ~= 'number' then
        return true
    end

    if IsAllowedAirMexPosition(aiBrain, position) then
        return true
    end

    local now = GetGameTimeSeconds and GetGameTimeSeconds() or 0
    if not aiBrain.AiBotDualGapMexBlockLogTime or now - aiBrain.AiBotDualGapMexBlockLogTime >= 30 then
        LOG('AiBot Dual Gap mex blocked: army='..tostring(aiBrain:GetArmyIndex())..'; role='..tostring(aiBrain.AiBotDualGapRole)..'; target='..tostring(x)..','..tostring(z)..'; policy=home_mexes_only; time='..tostring(now))
        aiBrain.AiBotDualGapMexBlockLogTime = now
    end
    return false
end

function CanBuildTransport(aiBrain)
    if not IsDualGapAirRole(aiBrain) or GetMapVersion() ~= 14 then
        return true
    end
    -- Re-enable transports only after the opening strat. They are reserved
    -- for engineer reclaim drops; home-mex construction remains restricted.
    return aiBrain:GetCurrentUnits(categories.AIR * categories.BOMBER * categories.TECH3) > 0
end

function CanUseTransportDrop(oTransport)
    if not oTransport or not oTransport.GetAIBrain then
        return true
    end
    local aiBrain = oTransport:GetAIBrain()
    if not IsDualGapAirRole(aiBrain) or GetMapVersion() ~= 14 then
        return true
    end

    -- After the opening strat, permit engineer-only reclaim drops. Combat
    -- cargo remains blocked, and CanBuildMexAt still prevents taking mid mexes.
    local tCargo = oTransport:GetCargo()
    if tCargo then
        for _, oCargo in tCargo do
            if EntityCategoryContains(categories.COMMAND + categories.SUBCOMMANDER, oCargo.UnitId) then
                return true
            end
            if not EntityCategoryContains(categories.ENGINEER * categories.TECH1, oCargo.UnitId) then
                return false
            end
        end
        return aiBrain:GetCurrentUnits(categories.AIR * categories.BOMBER * categories.TECH3) > 0
    end
    return false
end

local function GetFactoryCategory(factoryType)
    if factoryType == 'land' then
        return categories.LAND * categories.FACTORY * categories.STRUCTURE
    elseif factoryType == 'air' then
        return categories.AIR * categories.FACTORY * categories.STRUCTURE
    elseif factoryType == 'navy' then
        return categories.NAVAL * categories.FACTORY * categories.STRUCTURE
    end
    return nil
end

local function GetCurrentFactoryCount(aiBrain, factoryType)
    local category = GetFactoryCategory(factoryType)
    if not category then
        return 0
    end
    return aiBrain:GetCurrentUnits(category) or 0
end

local function DenyFactoryWithLog(aiBrain, factoryType, reason)
    local now = GetGameTimeSeconds()
    aiBrain.AiBotDualGapFactoryBlockLog = aiBrain.AiBotDualGapFactoryBlockLog or {}
    local logKey = factoryType..':'..reason
    if not aiBrain.AiBotDualGapFactoryBlockLog[logKey]
            or now - aiBrain.AiBotDualGapFactoryBlockLog[logKey] >= 30 then
        LOG('AiBot Dual Gap factory blocked: army='..tostring(aiBrain:GetArmyIndex())..'; role='..tostring(aiBrain.AiBotDualGapRole)..'; type='..factoryType..'; reason='..reason..'; time='..tostring(now))
        aiBrain.AiBotDualGapFactoryBlockLog[logKey] = now
    end
    return false
end

function CanBuildNavalFactory(aiBrain)
    if not aiBrain or not aiBrain.AiBotDualGapRole then
        return true
    end

    if aiBrain.AiBotDualGapPrimary == 'navy' then
        return true
    end

    -- A DualGap mid is allowed to become the single naval support slot only
    -- after its T3 land HQ exists. This prevents the nearby water zone from
    -- stealing the opening economy before the land timing is secured.
    if aiBrain.AiBotDualGapRole == 'mid' then
        local iT3LandFactories = aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE * categories.TECH3) or 0
        if iT3LandFactories < 1 then
            return DenyFactoryWithLog(aiBrain, 'navy', 'mid_land_tech_first')
        end
        if GetCurrentFactoryCount(aiBrain, 'navy') >= (aiBrain.AiBotDualGapNavyFactoryLimit or 1) then
            return DenyFactoryWithLog(aiBrain, 'navy', 'mid_navy_cap')
        end
    end

    -- Non-navy slots may transition to support mode later in the game. Until
    -- then, the naval builder must not spend the early economy on a factory
    -- just because a water zone exists nearby.
    return GetGameTimeSeconds() >= (aiBrain.AiBotDualGapNavyUnlock or 600)
end

function CanBuildFactory(aiBrain, factoryType)
    if not aiBrain or not aiBrain.AiBotDualGapRole then
        return true
    end

    if factoryType == 'navy' and not CanBuildNavalFactory(aiBrain) then
        return DenyFactoryWithLog(aiBrain, factoryType, 'navy_unlock')
    end

    local bAirEcoRole = aiBrain.AiBotDualGapRole == 'top_air'
            or aiBrain.AiBotDualGapRole == 'bottom_air'
            or aiBrain.AiBotDualGapRole == 'eco'
    if bAirEcoRole and factoryType == 'air'
            and GetCurrentFactoryCount(aiBrain, 'air') >= 1
            and aiBrain:GetCurrentUnits(categories.MASSEXTRACTION * categories.STRUCTURE * categories.TECH3) < 8 then
        return DenyFactoryWithLog(aiBrain, factoryType, 'air_grid_after_eight_t3_mexes')
    end

    -- Air is owned by the dedicated top/bottom slots on DualGap. A mid must
    -- not turn into a mixed land/air player after its commitment timer ends.
    if aiBrain.AiBotDualGapRole == 'mid' and factoryType == 'air' then
        return DenyFactoryWithLog(aiBrain, factoryType, 'mid_land_only')
    end

    local now = GetGameTimeSeconds()
    if factoryType == 'air' and now < (aiBrain.AiBotDualGapAirUnlock or 0) then
        return DenyFactoryWithLog(aiBrain, factoryType, 'air_unlock')
    end

    -- During the role commitment phase, cap only the factory types that are
    -- not the slot's main job. This leaves one defensive factory available
    -- while preventing generic team heuristics from turning every slot into
    -- a mixed land/air/navy economy.
    if now < (aiBrain.AiBotDualGapCommitmentEnd or 0) then
        local limit = aiBrain.AiBotDualGapFactoryLimits and aiBrain.AiBotDualGapFactoryLimits[factoryType]
        if limit ~= nil and GetCurrentFactoryCount(aiBrain, factoryType) >= limit then
            return DenyFactoryWithLog(aiBrain, factoryType, 'commitment_cap')
        end
    end

    if aiBrain.AiBotDualGapRole == 'mid' and factoryType == 'land' then
        local iT3LandFactories = aiBrain:GetCurrentUnits(categories.LAND * categories.FACTORY * categories.STRUCTURE * categories.TECH3) or 0
        local iLandFactoryLimit = iT3LandFactories > 0 and 3 or 2
        if GetCurrentFactoryCount(aiBrain, 'land') >= iLandFactoryLimit then
            return DenyFactoryWithLog(aiBrain, factoryType, 'mid_land_cap')
        end
    end

    return true
end
