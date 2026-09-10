--****************************************************************************
--** Generic visual-only aura radius bridge
--**
--** Unit scripts publish UnitData.AuraVisuals through Unit.AuraVisuals.  This
--** module copies those records into the native EXE renderer.  It does not
--** inspect weapons, damage, Intel or selection state.
--****************************************************************************

local GameMain = import('/lua/ui/game/gamemain.lua')
local WorldViewManager = import('/lua/ui/game/worldview.lua')

local DefaultColor = 'ffd000ff'

local AuraRadius = {
    Initialized = false,
    Visible = true,
    WarnedNativeUnavailable = false,
}

local function GetNativeFunctions()
    -- The UI environment uses strict global reads: referencing a missing native
    -- symbol directly aborts CreateUI. rawget lets us diagnose availability
    -- without breaking the rest of the interface.
    return rawget(_G, 'UI_SetAuraRadius'),
        rawget(_G, 'UI_ClearAuraRadii'),
        rawget(_G, 'UI_SetCustomRender')
end

local function IsCallable(value)
    -- Forged Alliance exposes native Lua callbacks as "cfunction" instead of
    -- the stock Lua "function" type.  Both values are valid call targets.
    local valueType = type(value)
    return valueType == 'function' or valueType == 'cfunction'
end

local function EnableAuraWorldViews(setCustomRender)
    for viewName, worldView in WorldViewManager.GetWorldViews() do
        if viewName ~= 'MiniMap' and worldView and not IsDestroyed(worldView) then
            -- The native renderer is attached to the existing custom world pass.
            -- Keep that pass enabled after the first active aura so movement is
            -- rendered every frame, independently of selection.
            local renderFunction = setCustomRender or worldView.SetCustomRender
            local ok, message = pcall(renderFunction, worldView, true)
            if not ok and WARN then
                WARN('[AURA][UI] SetCustomRender failed: ' .. tostring(message))
            end
        end
    end
end

local function GetUserUnit(entityId)
    local ok, unit = pcall(GetUnitById, entityId)
    if ok and unit and not IsDestroyed(unit) then
        return unit
    end

    -- UserSync commonly exposes entity IDs as string-number keys.  The native
    -- lookup expects the numeric entity ID on some game builds.
    local numericId = tonumber(entityId)
    if numericId and numericId ~= entityId then
        ok, unit = pcall(GetUnitById, numericId)
        if ok and unit and not IsDestroyed(unit) then
            return unit
        end
    end

    return nil
end

function AuraRadius.Refresh()
    local setAuraRadius, clearAuraRadii, setCustomRender = GetNativeFunctions()
    if not IsCallable(setAuraRadius) or not IsCallable(clearAuraRadii) then
        if not AuraRadius.WarnedNativeUnavailable then
            AuraRadius.WarnedNativeUnavailable = true
            WARN('[AURA][UI] native API is unavailable')
        end
        return
    end

    -- The registry is rebuilt from the latest sim snapshot.  The native side
    -- keeps the unit wrapper and updates its interpolated position each frame.
    clearAuraRadii()
    if not AuraRadius.Visible then
        return
    end

    local hasAura = false
    for entityId, unitData in UnitData do
        if type(unitData) == 'table' and type(unitData.AuraVisuals) == 'table' then
            local unit = GetUserUnit(entityId)
            if unit then
                for auraId, auraData in unitData.AuraVisuals do
                    if type(auraData) == 'table' and type(auraData.Radius) == 'number' and auraData.Radius > 0 then
                        local color = type(auraData.Color) == 'string' and auraData.Color or DefaultColor
                        local thickness = type(auraData.Thickness) == 'number' and auraData.Thickness or 0.04
                        local ok, message = pcall(
                            setAuraRadius,
                            unit,
                            tostring(auraId),
                            auraData.Radius,
                            color,
                            thickness
                        )
                        if ok then
                            hasAura = true
                        else
                            WARN('[AURA][UI] UI_SetAuraRadius failed: ' .. tostring(message))
                        end
                    end
                end
            end
        end
    end

    if hasAura then
        EnableAuraWorldViews(setCustomRender)
    end
end

function AuraRadius.SetVisible(visible)
    AuraRadius.Visible = visible == true
    AuraRadius.Refresh()
end

function AuraRadius.Initialize()
    if AuraRadius.Initialized then
        return
    end

    AuraRadius.Initialized = true
    -- A throttled sim-beat refresh is enough for sync changes; native rendering
    -- itself remains per-frame and therefore follows interpolated unit motion.
    GameMain.AddBeatFunction(AuraRadius.Refresh, true, 'AuraRadius')
    AuraRadius.Refresh()
end

Initialize = AuraRadius.Initialize
Refresh = AuraRadius.Refresh
SetVisible = AuraRadius.SetVisible
