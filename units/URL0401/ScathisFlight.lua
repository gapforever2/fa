-- Simulation-side flight helpers. Real flight uses a separate air blueprint;
-- SetElevation alone does not change Scathis' amphibious navigation or categories.

local MathAbs = math.abs
local MathMax = math.max
local MathMin = math.min
local MathCeil = math.ceil

-- CreateUnit may invoke OnStopBeingBuilt before returning the new object.
-- This non-yielding scope lets both unit classes recognise that callback.
SpawningMorph = false

function Log(unit, message)
    LOG(string.format('[ScathisCopter] army=%s entity=%s %s',
        tostring(unit and unit.Army or '?'),
        tostring(unit and unit.EntityId or '?'), message))
end

function IsAlive(unit)
    return unit and not unit.Dead and not unit:BeenDestroyed()
end

-- SetElevation requests a flight-controller height; it does not prove that
-- the body reached that height. Entity:SetPosition(vector, immediate) is an
-- actual world-position API (3836 engine/Sim/Entity.lua:385), also used by the
-- stock XRB2309 unit. With immediate=false, rendering interpolates sim steps.
-- Keep the live airborne entity throughout this motion; folding starts only
-- after its measured position reaches the ground and Transform succeeds.
function MoveVertically(unit, targetY, durationTicks, phase, cancelPredicate)
    if not IsAlive(unit) then
        return false, 'unit-dead'
    end
    local start = unit:GetPosition()
    local x, startY, z = start[1], start[2], start[3]
    local surfaceY = MathMax(GetSurfaceHeight(x, z),
        GetTerrainHeight(x, z) + GetTerrainTypeOffset(x, z))
    local ticks = MathMax(1, MathCeil(durationTicks))
    Log(unit, string.format('motion-start phase=%s actualY=%.3f targetY=%.3f ticks=%d',
        tostring(phase), startY, targetY, ticks))

    for tick = 1, ticks do
        if not IsAlive(unit) then
            return false, 'unit-dead'
        end
        if cancelPredicate and cancelPredicate(unit) then
            return false, 'cancelled'
        end
        local fraction = tick / ticks
        local eased = fraction * fraction * (3 - 2 * fraction)
        local y = startY + (targetY - startY) * eased
        local moved, failure = pcall(function()
            -- Align the controller's target too, so unlocking it later does
            -- not immediately pull the body back toward its old hover height.
            unit:SetElevation(MathMax(0, y - surfaceY))
            unit:SetPosition({ x, y, z }, false)
        end)
        if not moved then
            Log(unit, 'motion-command-failed phase=' .. tostring(phase)
                .. ' reason=' .. tostring(failure))
            return false, 'position-command-failed'
        end
        WaitTicks(1)
        if not IsAlive(unit) then
            return false, 'unit-dead'
        end
        if tick == 1 or tick == math.floor(ticks / 2) or tick == ticks then
            local actual = unit:GetPosition()
            Log(unit, string.format('motion-sample phase=%s tick=%d/%d actualY=%.3f requestedY=%.3f targetY=%.3f',
                tostring(phase), tick, ticks, actual[2], y, targetY))
        end
    end

    -- A toggle can arrive during the final WaitTicks just like any other tick.
    if cancelPredicate and cancelPredicate(unit) then
        return false, 'cancelled'
    end
    local actual = unit:GetPosition()
    if MathAbs(actual[2] - targetY) > 0.25
        or MathAbs(actual[1] - x) > 0.25 or MathAbs(actual[3] - z) > 0.25
    then
        Log(unit, string.format('motion-incomplete phase=%s actualY=%.3f targetY=%.3f',
            tostring(phase), actual[2], targetY))
        return false, 'position-not-reached'
    end
    return true
end

local function ReadCustomName(unit)
    -- GetCustomName is exposed by some engine versions but is absent from the
    -- 3836 simulation API declarations. Never fail a transformation on it.
    if unit.GetCustomName then
        local ok, name = pcall(unit.GetCustomName, unit)
        if ok and type(name) == 'string' then
            return name
        end
    end
    return unit.CopterCustomName
end

local function RestoreState(source, target, state)
    target.CopterSavedFireState = state.fireState
    target.CopterCustomName = state.customName
    target.CopterRequestedFlight = state.airborne
    target.CopterAirborne = state.airborne
    target.CopterLanded = not state.airborne
    target.CopterFlightMorph = true

    -- CreateUnit can complete a unit synchronously in the native engine. Only
    -- call the normal completion callback if it has not already run.
    if not target.isFinishedUnit then
        local complete = target:OnStopBeingBuilt(nil, target:GetCurrentLayer())
        if complete == false or not IsAlive(target) then
            error('replacement failed completion')
        end
    end

    -- Reapply veterancy before health: AddVetLevel includes a one-time heal.
    if state.experience and state.experience > 0 then
        target:CalculateVeterancyLevelAfterTransfer(state.experience, true)
    end
    if state.massCredit then
        target.VetMassKillCredit = state.massCredit
        target:UpdateStat('VetMassKillCredit', state.massCredit)
    end
    target:SetHealth(target, MathMin(state.health, target:GetMaxHealth()))
    target:SetFireState(state.fireState)
    if state.customName then
        target:SetCustomName(state.customName)
    end
    if state.kills then
        target:SetStat('KILLS', state.kills)
    end

    -- Preserve the damage already dealt to Scathis. Changing modes must not
    -- erase the enemies' pending veterancy credit when it eventually dies.
    target.VetDamage = source.VetDamage
    target.VetDamageTaken = source.VetDamageTaken
    target.VetInstigators = source.VetInstigators
    target.LastTickDamaged = source.LastTickDamaged
    target.oldowner = source.oldowner
    target.UnitName = source.UnitName

    if state.airborne then
        target:SetScriptBit('RULEUTC_SpecialToggle', true)
    else
        target:SetScriptBit('RULEUTC_SpecialToggle', false)
        -- Also needed when CreateUnit completed before CopterLanded was set.
        if target.BeginCopterLandingCleanup then
            target:BeginCopterLandingCleanup()
        end
    end
    target.CopterFlightMorph = nil
end

local function CompensateMorphBuild(target)
    if target and target.CopterBuildCounted and not target.CopterBuildCompensated then
        -- Stock Unit.OnStopBeingBuilt increments this counter (3836 Unit.lua:
        -- 2480). A mode replacement is the same built unit, including when
        -- later initialisation fails and the replacement must be discarded.
        target.Brain:AddUnitStat(target.UnitId, 'built', -1)
        target.CopterBuildCompensated = true
    end
end

-- This function does not yield. A failed replacement leaves the source alive;
-- the caller restores its animation/elevation and unlocks it on nil return.
function Transform(unit, blueprintId, layer)
    if not IsAlive(unit) then
        return nil, 'source-dead'
    end
    if unit:GetFractionComplete() < 1 then
        return nil, 'source-incomplete'
    end

    local position = unit:GetPosition()
    local orientation = unit:GetOrientation()
    local airborne = layer == 'Air'
    local state = {
        airborne = airborne,
        health = unit:GetHealth(),
        fireState = unit.CopterSavedFireState or unit:GetFireState(),
        experience = unit.VetExperience,
        massCredit = unit.VetMassKillCredit,
        customName = ReadCustomName(unit),
        kills = unit:GetStat('KILLS', 0).Value,
    }
    local y = position[2]
    if not airborne then
        y = GetTerrainHeight(position[1], position[3])
            + GetTerrainTypeOffset(position[1], position[3])
    end

    local target
    SpawningMorph = true
    local ok, reason = pcall(function()
        target = CreateUnit(blueprintId, unit.Army,
            position[1], y, position[3],
            orientation[1], orientation[2], orientation[3], orientation[4], layer)
        if not IsAlive(target) then
            error('replacement spawn failed')
        end
        RestoreState(unit, target, state)
        CompensateMorphBuild(target)
        -- Native upgrade notification retains selection and control groups.
        -- See stock ConstructionUnit.OnStopBuild.
        NotifyUpgrade(unit, target)
    end)
    -- Always clear this before handling failures or destroying either entity.
    SpawningMorph = false

    if not ok then
        local compensated, compensationFailure = pcall(CompensateMorphBuild, target)
        if not compensated then
            Log(unit, 'build-counter-rollback-failed reason=' .. tostring(compensationFailure))
        end
        if IsAlive(target) then
            target:Destroy()
        end
        Log(unit, 'transform-failed destination=' .. tostring(blueprintId)
            .. ' reason=' .. tostring(reason))
        return nil, tostring(reason)
    end

    Log(unit, string.format('transform destination=%s newEntity=%s health=%.1f vet=%s',
        blueprintId, tostring(target.EntityId), state.health, tostring(state.experience or 0)))
    unit.CopterReplacedBy = target.EntityId
    unit:Destroy()
    return target
end

-- Check the whole landing footprint instead of only its centre. A circling
-- footprint is conservative for any heading of Scathis' square skirt.
function CanLand(unit)
    if not IsAlive(unit) then
        return false, 'unit-dead'
    end
    local blueprint = __blueprints.url0401
    if not blueprint then
        return false, 'ground-blueprint-missing'
    end
    local physics = blueprint.Physics or {}
    local halfX = 0.5 * (physics.SkirtSizeX or blueprint.SizeX or 8)
    local halfZ = 0.5 * (physics.SkirtSizeZ or blueprint.SizeZ or 8)
    -- Stock Scathis has an off-centre skirt (-1.5, -1). Include that
    -- displacement so rotating the unit cannot put a corner outside the check.
    local offsetX, offsetZ = physics.SkirtOffsetX or 0, physics.SkirtOffsetZ or 0
    local radius = math.sqrt(halfX * halfX + halfZ * halfZ)
        + math.sqrt(offsetX * offsetX + offsetZ * offsetZ) + 0.5
    local position = unit:GetPosition()
    local x, z = position[1], position[3]
    local map = ScenarioInfo.MapData
    local bounds = map and map.PlayableRect or { 0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2] }
    if x - radius < bounds[1] or z - radius < bounds[2]
        or x + radius > bounds[3] or z + radius > bounds[4]
    then
        return false, 'map-boundary'
    end

    local minHeight, maxHeight
    local previousRow
    local steps = MathCeil(radius * 2)
    local step = radius * 2 / steps
    for iz = 0, steps do
        local row = {}
        for ix = 0, steps do
            local px, pz = x - radius + ix * step, z - radius + iz * step
            local terrain = GetTerrainType(px, pz)
            if terrain and terrain.Blocking then
                return false, 'blocked-terrain'
            end
            local height = GetTerrainHeight(px, pz)
            if GetSurfaceHeight(px, pz) - height > 0.1 then
                return false, 'water'
            end
            -- 0.75 per world unit is the stock NavGenerator cliff limit.
            if (ix > 0 and MathAbs(height - row[ix - 1]) >= 0.75 * step)
                or (previousRow and MathAbs(height - previousRow[ix]) >= 0.75 * step)
            then
                return false, 'cliff'
            end
            row[ix] = height
            minHeight = minHeight and MathMin(minHeight, height) or height
            maxHeight = maxHeight and MathMax(maxHeight, height) or height
        end
        previousRow = row
    end
    if maxHeight - minHeight > 2 then
        return false, 'uneven-ground'
    end

    -- Native rectangle queries include units from every army. Inspect nearby
    -- centres with a generous margin so large building skirts are considered.
    local search = radius + 64
    local nearby = GetUnitsInRect(Rect(x - search, z - search, x + search, z + search)) or {}
    for _, other in pairs(nearby) do
        if other ~= unit and IsAlive(other) and other:GetCurrentLayer() ~= 'Air' then
            local bp = other.Blueprint or other:GetBlueprint()
            local otherPhysics = bp.Physics or {}
            local halfX = 0.5 * (otherPhysics.SkirtSizeX or bp.SizeX or 1)
            local halfZ = 0.5 * (otherPhysics.SkirtSizeZ or bp.SizeZ or 1)
            -- Bounding circles cover rotated rectangular skirts too.
            local offsetX = otherPhysics.SkirtOffsetX or 0
            local offsetZ = otherPhysics.SkirtOffsetZ or 0
            local otherRadius = math.sqrt(halfX * halfX + halfZ * halfZ)
                + math.sqrt(offsetX * offsetX + offsetZ * offsetZ)
            local otherPosition = other:GetPosition()
            if MathAbs(otherPosition[1] - x) < radius + otherRadius
                and MathAbs(otherPosition[3] - z) < radius + otherRadius
            then
                return false, 'occupied-unit-' .. tostring(other.EntityId)
            end
        end
    end
    return true
end
