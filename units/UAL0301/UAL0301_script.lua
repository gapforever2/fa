-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0301/UAL0301_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Aeon Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
---@alias AeonSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUREGENRATE"

---@alias AeonSCUEnhancementBuffName          # BuffType
---| "AeonSCUBuildRate"                       # SCUBUILDRATE
---| "AeonSCURegenRate"                       # SCUREGENRATE

local CommandUnit = import("/lua/defaultunits.lua").CommandUnit
local AWeapons = import("/lua/aeonweapons.lua")
local ADFReactonCannon = AWeapons.ADFReactonCannon
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")
local ADFCannonQuantumWeapon = AWeapons.ADFCannonQuantumWeapon

local ADFEntropyField = import("/lua/sim/weapons/aeon/adfentropyfield.lua").ADFEntropyField

local EntropyAuraVisualId = 'RegenDampener'
local ShieldAmplifierAuraVisualId = 'ShieldAmplifier'
local LOG = LOG

local function GetShieldAmplifierUnitId(unit)
    local unitId = unit.UnitId or unit:GetUnitId()
    return unitId and string.lower(tostring(unitId)) or nil
end

local function DestroyEntropyVisuals(unit)
    if unit.EntropyVisuals then
        for _, emit in unit.EntropyVisuals do
            if emit then
                emit:Destroy()
            end
        end
        unit.EntropyVisuals = nil
    end
end

-- The Shield Amplifier grants each affected unit its own shield-HP multiplier.
-- No category tiers: a unit either has an entry (and gets its multiplier) or it
-- does not. A number is a multiplier; a table holds separate multipliers per
-- shield enhancement (the ACU). `ual0301` (the SACU's own shield) is handled by
-- ShieldAmplifierApplySelf with a fixed 7/6, so its entry here only marks it as
-- eligible.
--
-- Multipliers are derived from the base shield HP: mult = (base + bonus) / base.
local AeonShieldAmpTargets = {
    ual0202 = 1.142857,   -- Obsidian (T2 heavy tank): 1750 + 250
    ual0307 = 1.142857,   -- Asylum (T2 mobile shield generator): 3500 + 500
    ual0303 = 2.2,        -- Harbinger Mark IV (T3 assault bot): 1000 + 1200
    ual0001 = {           -- the ACU: light and heavy shield, each its own multiplier
        ShieldAeon = 1.25,        -- light shield: 8000 + 2000
        ShieldHeavyAeon = 1.2,    -- heavy shield: 25000 + 5000
    },
    ual0301 = true,       -- eligibility marker; own shield handled by ShieldAmplifierApplySelf
    xsl0301 = 1.2,        -- Seraphim SACU (personal shield): 5000 + 1000
    xsl0307 = 1.25,       -- Athanah (T3 Seraphim mobile shield): 10000 + 2500
    uel0307 = 1.25,       -- UEF T2 mobile shield generator: 3000 + 750
    uel0303 = 2.142857,   -- Titan (T3 assault bot, personal shield): 700 + 800
    uel0401 = 1.125,      -- Fatboy (T4 experimental tank): 20000 + 2500
    uel0001 = {           -- UEF ACU: personal and bubble shield, each its own multiplier
        ShieldUEF = 1.157895,             -- personal shield: 19000 + 3000
        ShieldGeneratorFieldUEF = 2.142857, -- bubble shield: 7000 + 8000
    },
    uel0301 = {           -- UEF SACU: personal, support and heavy bubble shield
        Shield = 1.076923,                        -- personal shield: 26000 + 2000
        ShieldGeneratorFieldSupport = 1.057143,   -- light bubble shield: 17500 + 1000
        ShieldGeneratorField = 1.038462,          -- heavy bubble shield: 52000 + 2000
    },
}

---@class UAL0301 : CommandUnit
UAL0301 = ClassUnit(CommandUnit) {
    AuraVisuals = {
        [EntropyAuraVisualId] = {
            IsActive = function(self)
                return self.EntropyFieldEnabled == true
            end,
            Color = 'ffd000ff',
            Thickness = 0.12,
            GetRadius = function(self)
                local weapon = self:GetWeaponByLabel('RegenDampener')
                return weapon and weapon:GetMaxRadius() or 0
            end,
        },
        [ShieldAmplifierAuraVisualId] = {
            IsActive = function(self)
                return self.ShieldAmplifierEnabled == true
            end,
            Color = 'ffd000ff',
            Thickness = 0.12,
            GetRadius = function(self)
                return self:GetShieldAmplifierRadius()
            end,
        },
    },

    Weapons = {
        RightReactonCannon = ClassWeapon(ADFReactonCannon) {},
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
        RedeemerGun = ClassWeapon(ADFCannonQuantumWeapon) {},

        --- White entropy field: suppresses enemy HP regen and damages enemies with its wave.
        RegenDampener = ClassWeapon(ADFEntropyField) {},
    },

    ---@param self UAL0301
    __init = function(self)
        CommandUnit.__init(self, 'RightReactonCannon')
    end,

    --- Returns the single gameplay radius used by both the shield target scan and
    --- the declarative visual ring.
    ---@param self UAL0301
    ---@return number
    GetShieldAmplifierRadius = function(self)
        if self.SensorRangeEnhancerInstalled then
            local sensor = self.Blueprint.Enhancements.SensorRangeEnhancer
            return sensor and sensor.NewOmniRadius or 45
        end

        local amplifier = self.Blueprint.Enhancements.ShieldAmplifier
        return amplifier and amplifier.Radius or 30
    end,

    --- Aggregates concurrently installed enhancement upkeep instead of allowing
    --- SensorRangeEnhancer and ShieldAmplifier to overwrite the same engine value.
    ---@param self UAL0301
    ---@param key string
    ---@param value number|nil
    ApplyEnhancementUpkeep = function(self, key, value)
        local upkeep = self.EnhancementUpkeep
        if not upkeep then
            upkeep = {}
            self.EnhancementUpkeep = upkeep
        end

        upkeep[key] = value and value > 0 and value or nil

        local total = 0
        for _, amount in upkeep do
            total = total + amount
        end

        self:SetEnergyMaintenanceConsumptionOverride(total)
        if total > 0 then
            self:SetMaintenanceConsumptionActive()
        else
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    ---@param self UAL0301
    ---@return number
    GetActiveShieldUpkeep = function(self)
        local name = self.ActiveShieldEnhancement
        local bp = name and self.Blueprint.Enhancements[name]
        return bp and bp.MaintenanceConsumptionPerSecondEnergy or 0
    end,

    ---@param self UAL0301
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        CommandUnit.OnStopBuild(self, unitBeingBuilt)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel('RightReactonCannon', true)
        self:GetWeaponManipulatorByLabel('RightReactonCannon'):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    ---@param self UAL0301
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('RegenDampener', false)
    end,

    ---@param self UAL0301
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        self.EntropyFieldEnabled = false
        self.ShieldAmplifierEnabled = false
        if self.EntropyActivationThread then
            KillThread(self.EntropyActivationThread)
            self.EntropyActivationThread = nil
        end
        if self.ShieldAmplifierThreadHandle then
            KillThread(self.ShieldAmplifierThreadHandle)
            self.ShieldAmplifierThreadHandle = nil
        end
        self:ShieldAmplifierRemoveAll()
        if self.ShieldAmplifierVisual then
            self.ShieldAmplifierVisual:Destroy()
            self.ShieldAmplifierVisual = nil
        end
        DestroyEntropyVisuals(self)
        CommandUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    --- Releases every registered target when the unit is removed directly
    --- (scenario cleanup, transfer cleanup, or scripted Destroy). Normal combat
    --- death already does this in OnKilled; the operation is safe to repeat.
    ---@param self UAL0301
    OnDestroy = function(self)
        self.ShieldAmplifierEnabled = false
        if self.ShieldAmplifierThreadHandle then
            KillThread(self.ShieldAmplifierThreadHandle)
            self.ShieldAmplifierThreadHandle = nil
        end
        self:ShieldAmplifierRemoveAll()
        CommandUnit.OnDestroy(self)
    end,

    ---@psaram self UAL0301
    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Turbine', true)
        self:SetupBuildBones()
    end,

    ---@param self UAL0301
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    ---------------------------------------------------------------------------
    --#region Enhancements

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporter = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporterRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancer = function(self, bp)
        self.SensorRangeEnhancerInstalled = true
        self.SensorRangeEnhancerEnabled = true
        self:SetIntelRadius('Vision', bp.NewVisionRadius or 30)
        self:SetIntelRadius('Omni', bp.NewOmniRadius or 45)
        self:SetIntelRadius('Radar', bp.NewRadarRadius or 110)
        self:EnableUnitIntel('Enhancement', 'Omni')
        self:EnableUnitIntel('Enhancement', 'Radar')
        self:ApplyEnhancementUpkeep('SensorRangeEnhancer', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        -- Entropy Field range scales with the omni sensor radius.
        self:GetWeaponByLabel('RegenDampener'):ChangeMaxRadius(bp.NewOmniRadius or 45)
        self:AddToggleCap('RULEUTC_IntelToggle')
        self:SetScriptBit('RULEUTC_IntelToggle', false)
    end,

    ---@param self UAL0301
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
        self:SetIntelRadius('Radar', bpIntel.RadarRadius or 0)
        self:ApplyEnhancementUpkeep('SensorRangeEnhancer', nil)
        -- Entropy Field reverts to its base radius.
        self:GetWeaponByLabel('RegenDampener'):ChangeMaxRadius(30)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self.ActiveShieldEnhancement = 'Shield'
        self:ApplyEnhancementUpkeep('Shield', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:CreateShield(bp)
        if self:HasEnhancement('ShieldAmplifier') then
            self:ShieldAmplifierApplySelf()
        end
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function(self, bp)
        self:AeonShieldAmpRemove()
        self:DestroyShield()
        self.ActiveShieldEnhancement = nil
        self:ApplyEnhancementUpkeep('Shield', nil)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldHeavy = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self.ActiveShieldEnhancement = 'ShieldHeavy'
        local savedBonus = self.AeonShieldAmpBonus
        local savedMult = self.AeonShieldAmpMult
        if savedBonus then
            self:AeonShieldAmpRemove()
        end
        self:CreateShield(bp)
        self:ApplyEnhancementUpkeep('Shield', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        if savedBonus and self:HasEnhancement('ShieldAmplifier') then
            self:ShieldAmplifierApplySelf()
        end
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldHeavyRemove = function(self, bp)
        self:AeonShieldAmpRemove()
        self:DestroyShield()
        self.ActiveShieldEnhancement = nil
        self:ApplyEnhancementUpkeep('Shield', nil)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEngineeringFocusingModule = function(self, bp)
        if not Buffs['AeonSCUBuildRate'] then
            BuffBlueprint {
                Name = 'AeonSCUBuildRate',
                DisplayName = 'AeonSCUBuildRate',
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
        Buff.ApplyBuff(self, 'AeonSCUBuildRate')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementEngineeringFocusingModuleRemove = function(self, bp)
        if Buff.HasBuff(self, 'AeonSCUBuildRate') then
            Buff.RemoveBuff(self, 'AeonSCUBuildRate')
        end
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSystemIntegrityCompensator = function(self, bp)
        if not Buffs['AeonSCURegenRate'] then
            BuffBlueprint {
                Name = 'AeonSCURegenRate',
                DisplayName = 'AeonSCURegenRate',
                BuffType = 'SCUREGENRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.NewHealth,
                        Mult = 1.0,
                    },
                    Regen = {
                        Add = bp.NewRegenRate - self.Blueprint.Defense.RegenRate,
                        Mult = 1,
                    },
                    MoveMult = {
                        Mult = 1.15,
                    },
                },
            }
        end
        Buff.ApplyBuff(self, 'AeonSCURegenRate')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSystemIntegrityCompensatorRemove = function(self, bp)
        if Buff.HasBuff(self, 'AeonSCURegenRate') then
            Buff.RemoveBuff(self, 'AeonSCURegenRate')
        end
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSacrifice = function(self, bp)
        self:AddCommandCap('RULEUCC_Sacrifice')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSacrificeRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Sacrifice')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStabilitySuppressant = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 2)
        wep:ChangeRateOfFire(bp.NewRateOfFire or 1.5)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 40)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStabilitySuppressantRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
        wep:ChangeRateOfFire(bp.RateOfFire or 1)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 30)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementRegenDampener = function(self, bp)
        self.EntropyFieldInstalled = true
        self:SetWeaponEnabledByLabel('RegenDampener', false)
        -- Powering the entropy field drains the main cannon: 300 -> 100 damage.
        self:GetWeaponByLabel('RightReactonCannon'):AddDamageMod(bp.NewDamageMod or -200)
        -- Field radius follows the omni sensor radius: 45 with the radar upgrade, else base 30.
        local radius = self.SensorRangeEnhancerInstalled
            and (self.Blueprint.Enhancements['SensorRangeEnhancer'].NewOmniRadius or 45)
            or 30
        self:GetWeaponByLabel('RegenDampener'):ChangeMaxRadius(radius)
        -- Remove emitters left by older test builds. The Lotus itself belongs to
        -- the weapon muzzle flash and must only exist while a real wave fires.
        DestroyEntropyVisuals(self)

        self:AddToggleCap('RULEUTC_SpecialToggle')
        self:SetEntropyFieldEnabled(true)
        self:SetScriptBit('RULEUTC_SpecialToggle', false)
    end,

    --- Starts or stops entropy waves without uninstalling the enhancement.
    ---@param self UAL0301
    ---@param enabled boolean
    SetEntropyFieldEnabled = function(self, enabled)
        if enabled and not self.EntropyFieldInstalled then
            return
        end

        self.EntropyFieldEnabled = enabled
        self:SetWeaponEnabledByLabel('RegenDampener', false)
        if self.EntropyActivationThread then
            KillThread(self.EntropyActivationThread)
            self.EntropyActivationThread = nil
        end
        DestroyEntropyVisuals(self)

        if enabled then
            -- Do not fire a wave immediately after enabling the field.
            self.EntropyActivationThread = self:ForkThread(self.EntropyActivationDelayThread)
        end
        self:UpdateAuraVisualSync()
    end,

    ---@param self UAL0301
    EntropyActivationDelayThread = function(self)
        local weapon = self:GetWeaponByLabel('RegenDampener')
        local weaponBp = weapon and weapon.Blueprint
        local rateOfFire = weaponBp and weaponBp.RateOfFire or 0.1
        local delayTicks = math.max(1, math.floor(10 / rateOfFire + 0.5))
        WaitTicks(delayTicks)

        self.EntropyActivationThread = nil
        if not self.Dead and self.EntropyFieldEnabled then
            self:SetWeaponEnabledByLabel('RegenDampener', true)
        end
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementRegenDampenerRemove = function(self, bp)
        self:SetEntropyFieldEnabled(false)
        self.EntropyFieldInstalled = false
        self:RemoveToggleCap('RULEUTC_SpecialToggle')
        -- Restore the main cannon damage.
        self:GetWeaponByLabel('RightReactonCannon'):AddDamageMod(-(self.Blueprint.Enhancements.RegenDampener.NewDamageMod or -200))
    end,

    -- Shield Amplifier boosts existing shields on the explicitly whitelisted allied
    -- ground units. It does not grant a shield. Each unit or shield enhancement gets
    -- its own fixed multiplier from AeonShieldAmpTargets; overlapping amplifiers are
    -- tracked as independent sources but never stack the bonus.
    --  Running the field strains the SACU's own chassis, cutting its max health by 5500
    --  while the amplifier is installed.
    --  The aura thread changes the live shield entity's current/max HP without
    --  recreating it, so the engine's damage-recharge state and timer are preserved.
    --  The buff is only the marker (UI icon + target emitter).
    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldAmplifier = function(self, bp)
        self.ShieldAmplifierInstalled = true
        if not Buffs['AeonShieldAmplifier'] then
            BuffBlueprint {
                Name = 'AeonShieldAmplifier',
                DisplayName = 'Aeon Shield Amplifier',
                BuffType = 'AEONSCUSHIELDAURA',
                Stacks = 'REPLACE',
                Duration = -1,
                Effects = { '/effects/emitters/aeon_shield_amplifier_aura_02_emit.bp' },
                Icon = true,
                Affects = {},
            }
        end
        -- Powering the field strains the SACU's own chassis: -5500 max health.
        if not Buffs['AeonShieldAmpSelfDebuff'] then
            BuffBlueprint {
                Name = 'AeonShieldAmpSelfDebuff',
                DisplayName = 'AeonShieldAmpSelfDebuff',
                BuffType = 'AEONSCUSHIELDDEBUFF',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = { Add = bp.ACUAddHealth or -5500, Mult = 1 },
                },
            }
        end
        Buff.ApplyBuff(self, 'AeonShieldAmpSelfDebuff')
        self:AddToggleCap('RULEUTC_StealthToggle')
        self:SetShieldAmplifierEnabled(true)
        self:SetScriptBit('RULEUTC_StealthToggle', false)
    end,

    --- Starts or stops the shield-amplifier field without uninstalling it.
    ---@param self UAL0301
    ---@param enabled boolean
    SetShieldAmplifierEnabled = function(self, enabled)
        if enabled and not self.ShieldAmplifierInstalled then
            return
        end

        self.ShieldAmplifierEnabled = enabled
        if enabled then
            self:ShieldAmplifierApplySelf()
            if not Buff.HasBuff(self, 'AeonShieldAmplifier') then
                Buff.ApplyBuff(self, 'AeonShieldAmplifier', self)
            end
            local bp = self.Blueprint.Enhancements.ShieldAmplifier
            self:ApplyEnhancementUpkeep('ShieldAmplifier', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            if not self.ShieldAmplifierThreadHandle then
                self.ShieldAmplifierThreadHandle = self:ForkThread(self.ShieldAmplifierThread)
            end
        else
            if self.ShieldAmplifierThreadHandle then
                KillThread(self.ShieldAmplifierThreadHandle)
                self.ShieldAmplifierThreadHandle = nil
            end
            self:ApplyEnhancementUpkeep('ShieldAmplifier', nil)
            self:AeonShieldAmpRemove()
            if Buff.HasBuff(self, 'AeonShieldAmplifier') then
                Buff.RemoveBuff(self, 'AeonShieldAmplifier')
            end
            self:ShieldAmplifierRemoveAll()
        end
        self:UpdateShieldAmplifierVisual()
        self:UpdateAuraVisualSync()
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldAmplifierRemove = function(self, bp)
        self:SetShieldAmplifierEnabled(false)
        self.ShieldAmplifierInstalled = false
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        if Buff.HasBuff(self, 'AeonShieldAmpSelfDebuff') then
            Buff.RemoveBuff(self, 'AeonShieldAmpSelfDebuff')
        end
    end,

    ---@param self UAL0301
    ShieldAmplifierRemoveAll = function(self)
        if self.ShieldAmplifierActive then
            local list = {}
            for u in pairs(self.ShieldAmplifierActive) do
                table.insert(list, u)
            end
            for _, u in list do
                if not u.Dead then
                    local lastSource = true
                    if u.AeonShieldAmpUnregisterSource then
                        lastSource = u:AeonShieldAmpUnregisterSource(self)
                    elseif u.AeonShieldAmpRemove then
                        u:AeonShieldAmpRemove()
                    end
                    if lastSource and Buff.HasBuff(u, 'AeonShieldAmplifier') then
                        Buff.RemoveBuff(u, 'AeonShieldAmplifier', true)
                    end
                    u:RequestRefreshUI()
                end
                self.ShieldAmplifierActive[u] = nil
            end
            self.ShieldAmplifierActive = nil
        end
    end,

    ---@param self UAL0301
    ---@param u Unit
    ---@return boolean
    ShieldAmplifierEligible = function(self, u)
        local shield = u.MyShield
        if not shield or shield:BeenDestroyed() then
            return false
        end
        -- Only the listed shield units are affected: Obsidian, the T2 mobile
        -- shield, the Harbinger, the ACU, the SACU itself and the Seraphim T3
        -- mobile shield (Athanah). Everything else is ignored. Each target has
        -- its own fixed multiplier in AeonShieldAmpTargets.
        local unitId = GetShieldAmplifierUnitId(u)
        return unitId and AeonShieldAmpTargets[unitId] ~= nil
    end,

    -- Any friendly SACU's personal shield is reinforced by a fixed 7/6 multiplier:
    -- the basic shield 15000 -> 17500 (+2500) and the heavy shield 30000 -> 35000
    -- (+5000). The effect is multiplicative and non-stacking: it never compounds
    -- with the aura's other multipliers or with multiple amplifiers.
    ---@param self UAL0301
    ---@return number
    ShieldAmplifierSelfMult = function(self)
        if self:HasEnhancement('ShieldHeavy') or self:HasEnhancement('Shield') then
            return 1.166667
        end
        return 1
    end,

    --- Applies the fixed SACU personal-shield bonus through the shared live-state
    --- transition used by every Shield Amplifier target.
    ---@param self UAL0301
    ShieldAmplifierApplySelf = function(self)
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
        local enhBp = self.Blueprint.Enhancements
        local base = self:HasEnhancement('ShieldHeavy') and enhBp.ShieldHeavy
            or (self:HasEnhancement('Shield') and enhBp.Shield or nil)
        if not base then
            return
        end
        local baseMax = base.ShieldMaxHealth or 0
        local bonus = math.floor(baseMax * (self:ShieldAmplifierSelfMult() - 1) + 0.5)
        if bonus <= 0 then
            return
        end

        self:AeonShieldAmpApplyBonus(bonus, self:ShieldAmplifierSelfMult())
    end,

    ---@param self UAL0301
    ---@param instigator Unit
    ---@param mult number|table
    AeonShieldAmpApply = function(self, instigator, mult)
        self:ShieldAmplifierApplySelf()
    end,

    --- Restores the SACU's own personal shield by subtracting the bonus.
    ---@param self UAL0301
    AeonShieldAmpRemove = function(self)
        self:AeonShieldAmpRemoveBonus()
    end,

    --- Maintains a single, dimmed emitter on the SACU itself so the field is visible
    --- while the enhancement is active. Mirrors the XSL0301 self-aura visual.
    ---@param self UAL0301
    UpdateShieldAmplifierVisual = function(self)
        if self.ShieldAmplifierThreadHandle then
            if not self.ShieldAmplifierVisual then
                local emit = CreateAttachedEmitter(self, 0, self.Army,
                    '/effects/emitters/aeon_shield_amplifier_aura_02_emit.bp')
                emit:ScaleEmitter(0.5)
                self.ShieldAmplifierVisual = emit
            end
        elseif self.ShieldAmplifierVisual then
            self.ShieldAmplifierVisual:Destroy()
            self.ShieldAmplifierVisual = nil
        end
    end,

    ---@param self UAL0301
    ShieldAmplifierThread = function(self)
        local brain = self:GetAIBrain()
        local cat = categories.MOBILE
            - categories.AIR
            - categories.NAVAL
            - categories.STRUCTURE

        local active = self.ShieldAmplifierActive or {}
        self.ShieldAmplifierActive = active
        LOG('[AURA][SHIELD] watcher started source=', self.UnitId or self:GetUnitId(),
            ' radius=', self:GetShieldAmplifierRadius())

        while not self.Dead and self.ShieldAmplifierEnabled do
            local ok, err = pcall(function()
            local radius = self:GetShieldAmplifierRadius()
            local present = {}

            local units = brain:GetUnitsAroundPoint(cat, self:GetPosition(), radius, 'Ally')
            for _, u in units do
                if not u.Dead and not u:IsBeingBuilt() and self:ShieldAmplifierEligible(u) then
                    present[u] = true
                    local unitId = GetShieldAmplifierUnitId(u)
                    local targetMult = AeonShieldAmpTargets[unitId]
                    local wasActive = active[u]
                    local applyOk, applyErr = pcall(function()
                        local applied
                        if u.AeonShieldAmpRegisterSource then
                            applied = u:AeonShieldAmpRegisterSource(self, targetMult)
                        elseif u.AeonShieldAmpApply then
                            u:AeonShieldAmpApply(self, targetMult)
                            applied = u.AeonShieldAmpBonus ~= nil
                        else
                            WARN('[AURA][SHIELD] target has no apply method: ', unitId)
                        end
                        if applied then
                            if not Buff.HasBuff(u, 'AeonShieldAmplifier') then
                                Buff.ApplyBuff(u, 'AeonShieldAmplifier', self)
                                u:RequestRefreshUI()
                            end
                            active[u] = true
                            if not wasActive then
                                local shield = u.MyShield
                                LOG('[AURA][SHIELD] target entered source=', self.UnitId or self:GetUnitId(),
                                    ' target=', unitId, ' mult=', targetMult,
                                    ' result=', shield and shield:GetHealth() or 'none', '/',
                                    shield and shield:GetMaxHealth() or 'none')
                            end
                        end
                    end)
                    if not applyOk then
                        WARN('UAL0301 ShieldAmplifier apply FAILED for ', u.UnitId, ': ', applyErr)
                    end
                end
            end

            -- Units that left the field (or lost their shield) drop the buff and
            -- restore their shield through AeonShieldAmpRemove (subtracts the bonus).
            for u in pairs(active) do
                if not present[u] or u.Dead then
                    if not u.Dead then
                        local removeOk, lastSource = pcall(function()
                            if u.AeonShieldAmpUnregisterSource then
                                return u:AeonShieldAmpUnregisterSource(self)
                            elseif u.AeonShieldAmpRemove then
                                u:AeonShieldAmpRemove()
                            end
                            return true
                        end)
                        if not removeOk then
                            WARN('UAL0301 ShieldAmplifier remove FAILED for ', u.UnitId, ': ', lastSource)
                        end
                        if removeOk then
                            LOG('[AURA][SHIELD] target left source=', self.UnitId or self:GetUnitId(),
                                ' target=', GetShieldAmplifierUnitId(u), ' lastSource=', lastSource)
                        end
                        local buffOk, buffErr = pcall(function()
                            if removeOk and lastSource and Buff.HasBuff(u, 'AeonShieldAmplifier') then
                                Buff.RemoveBuff(u, 'AeonShieldAmplifier', true)
                            end
                            u:RequestRefreshUI()
                        end)
                        if not buffOk then
                            WARN('UAL0301 ShieldAmplifier buff remove FAILED for ', u.UnitId, ': ', buffErr)
                        end
                    end
                    active[u] = nil
                end
            end
            end) -- pcall
            if not ok then
                WARN('UAL0301 ShieldAmplifierThread iteration FAILED: ', err)
            end

            WaitTicks(5)
        end
    end,

    --- Keep radar, entropy and shield amplification independent.
    ---@param self UAL0301
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 0 then
            self:EnableShield()
            self:ApplyEnhancementUpkeep('Shield', self:GetActiveShieldUpkeep())
        elseif bit == 3 then
            self.SensorRangeEnhancerEnabled = false
            self:DisableUnitIntel('ToggleBit3', 'Radar')
            self:DisableUnitIntel('ToggleBit3', 'Omni')
            self:ApplyEnhancementUpkeep('SensorRangeEnhancer', nil)
        elseif bit == 5 then
            self:SetShieldAmplifierEnabled(false)
        elseif bit == 7 then
            self:SetEntropyFieldEnabled(false)
        else
            CommandUnit.OnScriptBitSet(self, bit)
        end
    end,

    ---@param self UAL0301
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 0 then
            self:DisableShield()
            self:ApplyEnhancementUpkeep('Shield', nil)
        elseif bit == 3 then
            if self.SensorRangeEnhancerInstalled then
                self.SensorRangeEnhancerEnabled = true
                self:EnableUnitIntel('ToggleBit3', 'Radar')
                self:EnableUnitIntel('ToggleBit3', 'Omni')
                local bp = self.Blueprint.Enhancements.SensorRangeEnhancer
                self:ApplyEnhancementUpkeep('SensorRangeEnhancer', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            end
        elseif bit == 5 then
            self:SetShieldAmplifierEnabled(true)
        elseif bit == 7 then
            self:SetEntropyFieldEnabled(true)
        else
            CommandUnit.OnScriptBitClear(self, bit)
        end
    end,

    ---@param self UAL0301
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
        self:UpdateAuraVisualSync()
    end,

    --#endregion
}

TypeClass = UAL0301
