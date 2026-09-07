-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0301/XSL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Seraphim Sub Commander Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias SeraphimSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUUPGRADEDMG"

---@alias SeraphimSCUEnhancementBuffName      # BuffType
---| "SeraphimSCUDamageStabilization"         # SCUUPGRADEDMG
---| "SeraphimSCUBuildRate"                   # SCUBUILDRATE


local CommandUnit = import("/lua/defaultunits.lua").CommandUnit
local SWeapons = import("/lua/seraphimweapons.lua")
local Buff = import("/lua/sim/buff.lua")
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local SDFLightChronotronCannonWeapon = SWeapons.SDFLightChronotronCannonWeapon
local SDFOverChargeWeapon = SWeapons.SDFLightChronotronCannonOverchargeWeapon
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher

local SWalkingLandUnit = import("/lua/seraphimunits.lua").SWalkingLandUnit 
local WeaponsFile = import("/lua/seraphimweapons.lua")
local SDFAireauWeapon = WeaponsFile.SDFAireauWeapon

local RegenFieldBuffName = 'SeraphimSCURegenField'
local VitalityFieldBuffName = 'SeraphimSCUHealthField'
local VitalityFieldDefaultFactor = 1.15
local SeraphimAuraVisualId = 'SeraphimSCUFields'

---@param factor number
local function EnsureVitalityFieldBuff(factor)
    if Buffs[VitalityFieldBuffName] then
        return
    end

    BuffBlueprint {
        Name = VitalityFieldBuffName,
        DisplayName = VitalityFieldBuffName,
        BuffType = 'COMMANDERAURA_SCUHealthField',
        Stacks = 'IGNORE',
        Duration = -1,
        Effects = { '/effects/emitters/seraphim_regenerative_aura_02_emit.bp' },
        Affects = {
            MaxHealth = {
                Add = 0,
                Mult = factor,
                DoNotFill = true,
            },
        },
    }
end

---@param bp UnitBlueprintEnhancement
local function EnsureRegenFieldBuff(bp)
    if Buffs[RegenFieldBuffName] then
        return
    end

    BuffBlueprint {
        Name = RegenFieldBuffName,
        DisplayName = RegenFieldBuffName,
        BuffType = 'COMMANDERAURA_SCURegenField',
        Stacks = 'IGNORE',
        Duration = -1,
        Effects = { '/effects/emitters/seraphim_regenerative_aura_02_emit.bp' },
        Affects = {
            Regen = {
                Add = 0,
                Mult = bp.RegenPerSecond or 0.0275,
                Floor = bp.RegenFloor or 9,
                BPCeilings = {
                    TECH1 = bp.RegenCeilingT1 or 15,
                    TECH2 = bp.RegenCeilingT2 or 30,
                    TECH3 = bp.RegenCeilingT3 or 70,
                    EXPERIMENTAL = bp.RegenCeilingT4 or 90,
                    SUBCOMMANDER = bp.RegenCeilingSCU or 20,
                },
            },
        },
    }
end

---@param unit Unit
---@return boolean
local function HasLiveVitalitySource(unit)
    local sources = unit.SeraphimVitalitySources
    if not sources then
        return false
    end

    local found = false
    for source in pairs(sources) do
        if source and not source.Dead and source.HealthFieldEnabled then
            found = true
        else
            sources[source] = nil
        end
    end
    return found
end

---@param unit Unit
---@return boolean
local function HasLiveRegenFieldSource(unit)
    local sources = unit.SeraphimRegenFieldSources
    if not sources then
        return false
    end

    local found = false
    for source in pairs(sources) do
        if source and not source.Dead and source.RegenFieldEnabled then
            found = true
        else
            sources[source] = nil
        end
    end
    return found
end

---@class XSL0301 : CommandUnit
XSL0301 = ClassUnit(CommandUnit) {
    -- Both Seraphim fields share one gameplay radius. Keep one logical ring so
    -- installing both upgrades does not draw two identical circles.
    AuraVisuals = {
        [SeraphimAuraVisualId] = {
            IsActive = function(self)
                return self.RegenFieldEnabled == true or self.HealthFieldEnabled == true
            end,
            Color = 'ffd000ff',
            Thickness = 0.12,
            GetRadius = function(self)
                if self.AuraRadius then
                    return self.AuraRadius
                end

                local enhancements = self.Blueprint.Enhancements
                local regenRadius = self.RegenFieldEnabled and enhancements.RegenField.Radius or 0
                local healthRadius = self.HealthFieldEnabled and enhancements.HealthField.Radius or 0
                return math.max(regenRadius, healthRadius)
            end,
        },
    },

    Weapons = {
        LightChronatronCannon = ClassWeapon(SDFLightChronotronCannonWeapon) {},
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
        OverCharge = ClassWeapon(SDFOverChargeWeapon) {},
        AutoOverCharge = ClassWeapon(SDFOverChargeWeapon) {},
        Missile = ClassWeapon(SIFLaanseTacticalMissileLauncher) {
            OnCreate = function(self)
                SIFLaanseTacticalMissileLauncher.OnCreate(self)
                self:SetWeaponEnabled(false)
            end,
        },
    },

    ---@param self XSL0301
    __init = function(self)
        CommandUnit.__init(self, 'LightChronatronCannon')
    end,

    ---@param self XSL0301
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
    end,

    ---@param self XSL0301
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        self.RegenFieldEnabled = false
        self.HealthFieldEnabled = false
        if self.RegenFieldThread then
            KillThread(self.RegenFieldThread)
            self.RegenFieldThread = nil
        end
        self:RegenFieldRemoveAll()
        if self.HealthFieldThread then
            KillThread(self.HealthFieldThread)
            self.HealthFieldThread = nil
        end
        self:HealthFieldRemoveAll()
        CommandUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Turret', true)
        self:SetupBuildBones()
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
    end,

    -- Re-hide bones that get reset to visible by the teleport mesh recreation.
    -- Without this, the hidden 'Turret' bone reappears after teleporting.
    ---@param self XSL0301
    PlayTeleportInEffects = function(self)
        CommandUnit.PlayTeleportInEffects(self)
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Turret', true)
    end,

    ---@param self XSL0301
    ---@param builder Unit
    ---@param layer Layer
    StartBeingBuiltEffects = function(self, builder, layer)
        CommandUnit.StartBeingBuiltEffects(self, builder, layer)
        self.Trash:Add(ForkThread(EffectUtil.CreateSeraphimBuildThread, self, builder, self.OnBeingBuiltEffectsBag, 2))
    end,

    ---@param self XSL0301
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    -- =====================================================================================================================
    -- EMHANCEMENTS

    --- Tracks energy upkeep contributions from multiple enhancements so they don't overwrite
    --- each other through the single maintenance-consumption override.
    ---@param self XSL0301
    ---@param key string
    ---@param value? number
    ApplyAuraUpkeep = function(self, key, value)
        self.UpkeepSources = self.UpkeepSources or {}
        self.UpkeepSources[key] = value
        local total = 0
        for _, v in self.UpkeepSources do
            total = total + v
        end
        if total > 0 then
            self:SetEnergyMaintenanceConsumptionOverride(total)
            self:SetMaintenanceConsumptionActive()
        else
            self:SetEnergyMaintenanceConsumptionOverride(0)
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    --- Returns nearby allied units eligible for aura buffs.
    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ---@return Unit[]
    GetUnitsToBuff = function(self, bp)
        -- Build this category directly instead of parsing the enhancement string.
        -- Preset blueprints and category-string precedence must not be able to
        -- turn the shared target query into an empty result.
        local unitCat = (categories.LAND + categories.HOVER + categories.AMPHIBIOUS)
            - (categories.COMMAND + categories.AIR + categories.NAVAL + categories.STRUCTURE)
        local brain = self:GetAIBrain()
        local radius = self.AuraRadius or bp.Radius
        local all = brain:GetUnitsAroundPoint(unitCat, self:GetPosition(), radius, 'Ally')
        local units = {}
        for _, u in all do
            -- Both Seraphim SACU fields affect allied ground units of every
            -- faction. ACUs, aircraft, navy and structures are excluded.
            if u ~= self and not u.Dead and not u:IsBeingBuilt()
                and EntityCategoryContains(categories.LAND + categories.HOVER + categories.AMPHIBIOUS, u)
                and not EntityCategoryContains(categories.COMMAND + categories.AIR
                    + categories.NAVAL + categories.STRUCTURE, u) then
                table.insert(units, u)
            end
        end
        return units
    end,

    --- Adds this SACU as one non-stacking source of the target's percentage regen.
    --- Multiple overlapping fields keep one shared regen buff active.
    ---@param self XSL0301
    ---@param unit Unit
    RegenFieldRegisterTarget = function(self, unit)
        if unit.Dead then
            return
        end

        local sources = unit.SeraphimRegenFieldSources
        if not sources then
            sources = {}
            unit.SeraphimRegenFieldSources = sources
        end
        sources[self] = true

        if not Buff.HasBuff(unit, RegenFieldBuffName) then
            Buff.ApplyBuff(unit, RegenFieldBuffName, self)
            unit:RequestRefreshUI()
        end
    end,

    --- Removes this SACU as a regen source. The buff is removed only after the
    --- final overlapping restoration field no longer covers the target.
    ---@param self XSL0301
    ---@param unit Unit
    RegenFieldUnregisterTarget = function(self, unit)
        local sources = unit.SeraphimRegenFieldSources
        if sources then
            sources[self] = nil
        end
        if HasLiveRegenFieldSource(unit) then
            return
        end

        unit.SeraphimRegenFieldSources = nil
        if Buff.HasBuff(unit, RegenFieldBuffName) then
            Buff.RemoveBuff(unit, RegenFieldBuffName, true, self)
        end
        unit:RequestRefreshUI()
    end,

    --- Removes this source from every tracked target when the enhancement is
    --- removed or the aura carrier dies.
    ---@param self XSL0301
    RegenFieldRemoveAll = function(self)
        local active = self.RegenFieldActive
        if not active then
            return
        end

        local targets = {}
        for unit in pairs(active) do
            table.insert(targets, unit)
        end
        for _, unit in targets do
            if not unit.Dead then
                self:RegenFieldUnregisterTarget(unit)
            end
            active[unit] = nil
        end
        self.RegenFieldActive = nil
    end,

    --- Applies percentage-based regeneration to nearby own and allied land,
    --- hover and amphibious units of every faction. ACUs, aircraft, naval units
    --- and structures are excluded. Entry and exit are tracked so
    --- regeneration remains continuous while a unit is inside the field.
    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    RegenFieldAuraThread = function(self, bp)
        local active = self.RegenFieldActive or {}
        self.RegenFieldActive = active

        while not self.Dead and self.RegenFieldEnabled do
            local present = {}
            local units = self:GetUnitsToBuff(bp)
            for _, unit in units do
                if not unit.Dead then
                    present[unit] = true
                    if not active[unit] or not Buff.HasBuff(unit, RegenFieldBuffName) then
                        active[unit] = true
                        self:RegenFieldRegisterTarget(unit)
                    end
                end
            end

            for unit in pairs(active) do
                if not present[unit] or unit.Dead then
                    if not unit.Dead then
                        self:RegenFieldUnregisterTarget(unit)
                    end
                    active[unit] = nil
                end
            end
            WaitTicks(5)
        end
    end,

    --- Maintains a single, dimmed self aura emitter so the visual does not stack
    --- when more than one aura field is active at the same time.
    ---@param self XSL0301
    UpdateAuraVisual = function(self)
        local active = (self.RegenFieldThread ~= nil) or (self.HealthFieldThread ~= nil)
        if active then
            if not self.AuraVisualBag then
                self.AuraVisualBag = {}
                local emit = CreateAttachedEmitter(self, 'XSL0301', self.Army,
                    '/effects/emitters/seraphim_regenerative_aura_01_emit.bp')
                emit:ScaleEmitter(0.5)
                table.insert(self.AuraVisualBag, emit)
            end
        elseif self.AuraVisualBag then
            for _, v in self.AuraVisualBag do
                v:Destroy()
            end
            self.AuraVisualBag = nil
        end
        self:UpdateAuraVisualSync()
    end,

    --- Starts or stops the restoration field without uninstalling its upgrade.
    ---@param self XSL0301
    ---@param enabled boolean
    SetRestorationFieldEnabled = function(self, enabled)
        if enabled and not self.RegenFieldInstalled then
            return
        end

        self.RegenFieldEnabled = enabled
        local bp = self.Blueprint.Enhancements.RegenField
        if enabled then
            EnsureRegenFieldBuff(bp)
            if not Buff.HasBuff(self, RegenFieldBuffName) then
                Buff.ApplyBuff(self, RegenFieldBuffName, self)
            end
            if not self.RegenFieldThread then
                self.RegenFieldThread = self:ForkThread(self.RegenFieldAuraThread, bp)
            end
            self:ApplyAuraUpkeep('RegenField', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        else
            if self.RegenFieldThread then
                KillThread(self.RegenFieldThread)
                self.RegenFieldThread = nil
            end
            self:RegenFieldRemoveAll()
            if Buff.HasBuff(self, RegenFieldBuffName) then
                Buff.RemoveBuff(self, RegenFieldBuffName, true, self)
            end
            self:ApplyAuraUpkeep('RegenField', nil)
        end
        self:UpdateAuraVisual()
    end,

    --- Starts or stops the vitality field without uninstalling its upgrade.
    ---@param self XSL0301
    ---@param enabled boolean
    SetVitalityFieldEnabled = function(self, enabled)
        if enabled and not self.HealthFieldInstalled then
            return
        end

        self.HealthFieldEnabled = enabled
        local bp = self.Blueprint.Enhancements.HealthField
        if enabled then
            EnsureVitalityFieldBuff(bp.MaxHealthFactor or VitalityFieldDefaultFactor)
            if not self.HealthFieldThread then
                self.HealthFieldThread = self:ForkThread(self.HealthFieldAuraThread, bp)
            end
            self:ApplyAuraUpkeep('HealthField', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        else
            if self.HealthFieldThread then
                KillThread(self.HealthFieldThread)
                self.HealthFieldThread = nil
            end
            self:HealthFieldRemoveAll()
            self:ApplyAuraUpkeep('HealthField', nil)
        end
        self:UpdateAuraVisual()
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRegenField = function(self, bp)
        -- A preset can install Shield after RegenField in the same Back slot.
        -- HasEnhancement('RegenField') then becomes false even though its effects
        -- remain active, so the aura lifecycle uses this explicit state instead.
        self.RegenFieldInstalled = true
        EnsureRegenFieldBuff(bp)
        -- Powering the field weakens the SACU's own chassis: -7000 max health
        -- while the restoration field is active.
        if not Buffs['SeraphimSCURegenFieldSelf'] then
            BuffBlueprint {
                Name = 'SeraphimSCURegenFieldSelf',
                DisplayName = 'SeraphimSCURegenFieldSelf',
                BuffType = 'COMMANDERAURAFORSELF_SCURegen',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = { Add = bp.ACUAddHealth or -7000, Mult = 1 },
                },
            }
        end
        Buff.ApplyBuff(self, 'SeraphimSCURegenFieldSelf')
        self:AddToggleCap('RULEUTC_StealthToggle')
        self:SetRestorationFieldEnabled(true)
        self:SetScriptBit('RULEUTC_StealthToggle', false)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementRegenFieldRemove = function(self, bp)
        self:SetRestorationFieldEnabled(false)
        self.RegenFieldInstalled = false
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        if Buff.HasBuff(self, 'SeraphimSCURegenFieldSelf') then
            Buff.RemoveBuff(self, 'SeraphimSCURegenFieldSelf', true, self)
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHealthField = function(self, bp)
        self.HealthFieldInstalled = true
        EnsureVitalityFieldBuff(bp.MaxHealthFactor or VitalityFieldDefaultFactor)
        self:AddToggleCap('RULEUTC_SpecialToggle')
        self:SetVitalityFieldEnabled(true)
        self:SetScriptBit('RULEUTC_SpecialToggle', false)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementHealthFieldRemove = function(self, bp)
        self:SetVitalityFieldEnabled(false)
        self.HealthFieldInstalled = false
        self:RemoveToggleCap('RULEUTC_SpecialToggle')
    end,

    --- Adds this SACU as one non-stacking source of the target's +15% maximum
    --- health bonus. Multiple overlapping fields keep one shared bonus active.
    ---@param self XSL0301
    ---@param unit Unit
    HealthFieldRegisterTarget = function(self, unit)
        if unit.Dead then
            return
        end

        local sources = unit.SeraphimVitalitySources
        if not sources then
            sources = {}
            unit.SeraphimVitalitySources = sources
        end
        sources[self] = true

        if not Buff.HasBuff(unit, VitalityFieldBuffName) then
            Buff.ApplyBuff(unit, VitalityFieldBuffName, self)
            unit:RequestRefreshUI()
        end
    end,

    --- Removes this SACU as a source. The +15% maximum-health multiplier is only
    --- removed after the final overlapping field is gone.
    ---@param self XSL0301
    ---@param unit Unit
    HealthFieldUnregisterTarget = function(self, unit)
        local sources = unit.SeraphimVitalitySources
        if sources then
            sources[self] = nil
        end
        if HasLiveVitalitySource(unit) then
            return
        end

        unit.SeraphimVitalitySources = nil
        if Buff.HasBuff(unit, VitalityFieldBuffName) then
            Buff.RemoveBuff(unit, VitalityFieldBuffName, true, self)
        end
        unit:RequestRefreshUI()
    end,

    --- Removes this source from every unit immediately when the enhancement is
    --- removed or the aura carrier dies.
    ---@param self XSL0301
    HealthFieldRemoveAll = function(self)
        local active = self.HealthFieldActive
        if not active then
            return
        end

        local targets = {}
        for unit in pairs(active) do
            table.insert(targets, unit)
        end
        for _, unit in targets do
            if not unit.Dead then
                self:HealthFieldUnregisterTarget(unit)
            end
            active[unit] = nil
        end
        self.HealthFieldActive = nil
    end,

    --- Tracks entries/exits explicitly so the maximum-health multiplier changes
    --- exactly once per target.
    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    HealthFieldAuraThread = function(self, bp)
        local active = self.HealthFieldActive or {}
        self.HealthFieldActive = active

        while not self.Dead and self.HealthFieldEnabled do
            local present = {}
            local units = self:GetUnitsToBuff(bp)
            for _, unit in units do
                if not unit.Dead then
                    present[unit] = true
                    if not active[unit] then
                        active[unit] = true
                        self:HealthFieldRegisterTarget(unit)
                    end
                end
            end

            for unit in pairs(active) do
                if not present[unit] or unit.Dead then
                    if not unit.Dead then
                        self:HealthFieldUnregisterTarget(unit)
                    end
                    active[unit] = nil
                end
            end
            WaitTicks(5)
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporter = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporterRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementMissile = function(self, bp)
        self:AddCommandCap('RULEUCC_Tactical')
        self:AddCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', true)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementMissileRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Tactical')
        self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', false)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self.ShieldInstalled = true
        self:ApplyAuraUpkeep('Shield', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        local savedBonus = self.AeonShieldAmpBonus
        local savedMult = self.AeonShieldAmpMult
        if savedBonus then
            self:AeonShieldAmpRemove()
        end
        self:CreateShield(bp)
        if not Buffs['SeraphimSCUShieldSelf'] then
            BuffBlueprint {
                Name = 'SeraphimSCUShieldSelf',
                DisplayName = 'SeraphimSCUShieldSelf',
                BuffType = 'COMMANDERAURAFORSELF_SCUShield',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = { Add = bp.ACUAddHealth or -5000, Mult = 1 },
                },
            }
        end
        Buff.ApplyBuff(self, 'SeraphimSCUShieldSelf')
        if savedBonus and Buff.HasBuff(self, 'AeonShieldAmplifier') then
            self:AeonShieldAmpApply(nil, savedMult or 1)
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function(self, bp)
        self.ShieldInstalled = false
        self:AeonShieldAmpRemove()
        self:DestroyShield()
        self:ApplyAuraUpkeep('Shield', nil)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
        if Buff.HasBuff(self, 'SeraphimSCUShieldSelf') then
            Buff.RemoveBuff(self, 'SeraphimSCUShieldSelf')
        end
    end,

    --- Called by the Aeon SACU Shield Amplifier aura when this SACU enters its field.
    --- The SACU's personal shield is enhancement-based (Shield), not a Defense.Shield
    --- entry, so the base spec is taken from the current enhancement instead of the
    --- blueprint. Applies a fixed multiplier to the shield max (5000 -> 6000 for the
    --- Aeon amplifier).
    ---@param self XSL0301
    ---@param instigator Unit
    ---@param mult number # multiplier applied to the shield max
    AeonShieldAmpApply = function(self, instigator, mult)
        if self.Dead then
            return
        end
        if self.AeonShieldAmpBonus then
            return
        end
        local shield = self.MyShield
        if not shield or shield:BeenDestroyed() then
            return
        end
        local enhBp = self:GetBlueprint().Enhancements
        local baseBp = self:HasEnhancement('Shield') and enhBp.Shield or nil
        if not baseBp then
            return
        end
        local baseMax = baseBp.ShieldMaxHealth or 0
        local bonus = math.floor(baseMax * ((mult or 1) - 1) + 0.5)
        if bonus <= 0 then
            return
        end

        self:AeonShieldAmpApplyBonus(bonus, mult)
    end,

    --- Called when the SACU leaves the aura field (or the enhancement is removed):
    --- immediately subtracts the bonus from both current and max HP.
    ---@param self XSL0301
    AeonShieldAmpRemove = function(self)
        self:AeonShieldAmpRemoveBonus()
    end,

    ---@param self XSL0301
    RefreshShieldAmplifierBuff = function(self)
        local mult = self:AeonShieldAmpGetSourceMult() or self.AeonShieldAmpMult
        if mult and Buff.HasBuff(self, 'AeonShieldAmplifier') then
            self:AeonShieldAmpRemove()
            self:AeonShieldAmpApply(nil, mult)
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementOvercharge = function(self, bp)
        self:AddCommandCap('RULEUCC_Overcharge')
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = false
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = false
        local wep = self:GetWeaponByLabel('OverCharge')
        self:SetWeaponEnabledByLabel('OverCharge', true)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementOverchargeRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Overcharge')
        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
        local wep = self:GetWeaponByLabel('OverCharge')
        self:SetWeaponEnabledByLabel('OverCharge', false)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementEngineeringThroughput = function(self, bp)
        if not Buffs['SeraphimSCUBuildRate'] then
            BuffBlueprint {
                Name = 'SeraphimSCUBuildRate',
                DisplayName = 'SeraphimSCUBuildRate',
                BuffType = 'SCUBUILDRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    BuildRate = {
                        Add = bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
                        Mult = 1,
                    },
                },
            }
        end
        Buff.ApplyBuff(self, 'SeraphimSCUBuildRate')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEngineeringThroughputRemove = function(self, bp)
        if Buff.HasBuff(self, 'SeraphimSCUBuildRate') then
            Buff.RemoveBuff(self, 'SeraphimSCUBuildRate')
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilization = function (self, bp)
        if not Buffs['SeraphimSCUDamageStabilization'] then
            BuffBlueprint {
                Name = 'SeraphimSCUDamageStabilization',
                DisplayName = 'SeraphimSCUDamageStabilization',
                BuffType = 'SCUUPGRADEDMG',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.NewHealth,
                        Mult = 1.0,
                    },
                    Regen = {
                        Add = bp.NewRegenRate,
                        Mult = 1.0,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
        end
        Buff.ApplyBuff(self, 'SeraphimSCUDamageStabilization')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementDamageStabilizationRemove = function (self, bp)
        if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancer = function(self, bp)
        self.SensorRangeEnhancerInstalled = true
        self.SensorRangeEnhancerEnabled = true
        self:SetIntelRadius('Vision', bp.NewVisionRadius or 40)
        self:SetIntelRadius('Omni', bp.NewOmniRadius or 35)
        self:SetIntelRadius('Radar', bp.NewRadarRadius or 90)
        self:EnableUnitIntel('Enhancement', 'Omni')
        self:EnableUnitIntel('Enhancement', 'Radar')
        self:ApplyAuraUpkeep('Sensor', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        -- Aura fields extend their radius to match the omni sensor radius while the sensor upgrade is active.
        self.AuraRadius = bp.NewOmniRadius or 35
        self:AddToggleCap('RULEUTC_IntelToggle')
        self:SetScriptBit('RULEUTC_IntelToggle', false)
        self:UpdateAuraVisualSync()
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSensorRangeEnhancerRemove = function(self, bp)
        self.SensorRangeEnhancerEnabled = false
        self.SensorRangeEnhancerInstalled = false
        self:DisableUnitIntel('Enhancement', 'Omni')
        self:DisableUnitIntel('Enhancement', 'Radar')
        self:RemoveToggleCap('RULEUTC_IntelToggle')
        local bpIntel = self.Blueprint.Intel
        self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
        self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
        self:SetIntelRadius('Radar', bp.RadarRadius or 0)
        self:ApplyAuraUpkeep('Sensor', nil)
        -- Restore the auras to their base radius when the sensor upgrade is removed.
        self.AuraRadius = nil
        self:UpdateAuraVisualSync()
    end,

    --- Keep radar, restoration and vitality on independent script bits.
    ---@param self XSL0301
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 0 then
            self:EnableShield()
            if self.ShieldInstalled then
                local bp = self.Blueprint.Enhancements.Shield
                self:ApplyAuraUpkeep('Shield', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            end
        elseif bit == 3 then
            self.SensorRangeEnhancerEnabled = false
            self:DisableUnitIntel('ToggleBit3', 'Radar')
            self:DisableUnitIntel('ToggleBit3', 'Omni')
            self:ApplyAuraUpkeep('Sensor', nil)
        elseif bit == 5 then
            self:SetRestorationFieldEnabled(false)
        elseif bit == 7 then
            self:SetVitalityFieldEnabled(false)
        else
            CommandUnit.OnScriptBitSet(self, bit)
        end
    end,

    ---@param self XSL0301
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 0 then
            self:DisableShield()
            self:ApplyAuraUpkeep('Shield', nil)
        elseif bit == 3 then
            if self.SensorRangeEnhancerInstalled then
                self.SensorRangeEnhancerEnabled = true
                self:EnableUnitIntel('ToggleBit3', 'Radar')
                self:EnableUnitIntel('ToggleBit3', 'Omni')
                local bp = self.Blueprint.Enhancements.SensorRangeEnhancer
                self:ApplyAuraUpkeep('Sensor', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            end
        elseif bit == 5 then
            self:SetRestorationFieldEnabled(true)
        elseif bit == 7 then
            self:SetVitalityFieldEnabled(true)
        else
            CommandUnit.OnScriptBitClear(self, bit)
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementRapidFire = function(self, bp)
        local wep = self:GetWeaponByLabel('LightChronatronCannon')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        wep:ChangeRateOfFire(bp.NewRateOfFire or 1.5)
        wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 2.5)
        local wep = self:GetWeaponByLabel('OverCharge')
        wep:ChangeMaxRadius(35)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(35)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementRapidFireRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('LightChronatronCannon')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        wep:ChangeRateOfFire(bp.RateOfFire or 1)
        wep:AddDamageRadiusMod(bp.DamageRadiusMod or 0)
        local wep = self:GetWeaponByLabel('OverCharge')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bp.NewMaxRadius or 25)
    end,

    ---@param self XSL0301
    ---@param enh Enhancement
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self.Blueprint.Enhancements[enh]
        if not bp then return end

        local ref = 'ProcessEnhancement' .. enh
        local handler = self[ref]

        if handler then
            handler(self, bp)
        else
            WARN("Missing enhancement: ", enh, " for unit: ", self:GetUnitId(), " note that the function name should be called: ", ref)
        end
    end,
}

TypeClass = XSL0301
