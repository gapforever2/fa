-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0301/UEL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  UEF Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local DefaultWep = import("/lua/sim/defaultweapons.lua")
local DefaultUnit = import("/lua/defaultunits.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local TWeapons = import("/lua/terranweapons.lua")
local Buff = import("/lua/sim/buff.lua")
local TargetingLaser = import("/lua/kirvesweapons.lua").TargetingLaser

local CommandUnit = DefaultUnit.CommandUnit
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon
local SCUDeathWeapon = DefaultWep.SCUDeathWeapon

---@class UEL0301 : CommandUnit
---@field HasPodEnh boolean
---@field RebuildPodThread? thread
---@field RebuildingPod? EconomyEvent
---@field Pod TConstructionPodUnit
UEL0301 = ClassUnit(CommandUnit) {
    IntelEffects = {
        {
            Bones = {
                'Jetpack',
            },
            Scale = 0.5,
            Type = 'Jammer01',
        },
    },

    Weapons = {
        RightHeavyPlasmaCannon = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {},
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
    },

    ---@param self UEL0301
    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:ShowBone('Arm_Right_B03', true)
        self:HideBone('Arm_Right_Barrel01', true)
        self:HideBone('Jetpack', true)
        self:HideBone('SAM', true)
        self:SetupBuildBones()
    end,

    ---@param self UEL0301
    __init = function(self)
        CommandUnit.__init(self, 'RightHeavyPlasmaCannon')
    end,

    --- Aggregates upkeep from independently toggled SACU systems.
    ---@param self UEL0301
    ---@param key string
    ---@param value number|nil
    ApplyEnhancementUpkeep = function(self, key, value)
        self.EnhancementUpkeep = self.EnhancementUpkeep or {}
        self.EnhancementUpkeep[key] = value and value > 0 and value or nil

        local total = 0
        for _, amount in self.EnhancementUpkeep do
            total = total + amount
        end
        self:SetEnergyMaintenanceConsumptionOverride(total)
        if total > 0 then
            self:SetMaintenanceConsumptionActive()
        else
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    ---@param self UEL0301
    ---@return number
    GetActiveShieldUpkeep = function(self)
        local name = self.ActiveShieldEnhancement
        local bp = name and self.Blueprint.Enhancements[name]
        return bp and bp.MaintenanceConsumptionPerSecondEnergy or 0
    end,

    ---@param self UEL0301
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('RightHeavyPlasmaCannon', true)
        -- Block Jammer until Enhancement is built
        self:DisableUnitIntel('Enhancement', 'Jammer')
    end,

    ---@param self UEL0301
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            EffectUtil.CreateUEFCommanderBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        else
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    ---@param self UEL0301
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        self:SetWeaponEnabledByLabel('RightHeavyPlasmaCannon', false)
        CommandUnit.OnStartBuild(self, unitBeingBuilt, order)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStopBuild = function(self, unitBeingBuilt, order)
        self:SetWeaponEnabledByLabel('RightHeavyPlasmaCannon', true)
        CommandUnit.OnStopBuild(self, unitBeingBuilt, order)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param unitBeingRepaired Unit
    OnStartRepair = function(self, unitBeingRepaired)
        self:SetWeaponEnabledByLabel('RightHeavyPlasmaCannon', false)
        CommandUnit.OnStartRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param unitBeingRepaired Unit
    OnStopRepair = function(self, unitBeingRepaired)
        self:SetWeaponEnabledByLabel('RightHeavyPlasmaCannon', true)
        CommandUnit.OnStopRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param target Unit|Prop
    OnStartReclaim = function(self, target)
        self:SetWeaponEnabledByLabel('RightHeavyPlasmaCannon', false)
        CommandUnit.OnStartReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param target Unit|Prop
    OnStopReclaim = function(self, target)
        self:SetWeaponEnabledByLabel('RightHeavyPlasmaCannon', true)
        CommandUnit.OnStopReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    RebuildPod = function(self)
        if self.HasPodEnh == true then
            self.RebuildingPod = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
            self:RequestRefreshUI()
            WaitFor(self.RebuildingPod)
            self:SetWorkProgress(0.0)
            RemoveEconomyEvent(self, self.RebuildingPod)
            self.RebuildingPod = nil
            local location = self:GetPosition('AttachSpecial01')
            ---@type UEA0003
            ---@diagnostic disable-next-line: assign-type-mismatch
            local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'Pod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.Pod = pod
        end
    end,

    ---@param self UEL0301
    ---@param pod TConstructionPodUnit unused
    ---@param rebuildDrone boolean
    NotifyOfPodDeath = function(self, pod, rebuildDrone)
        if rebuildDrone == true then
            if self.HasPodEnh == true then
                self.RebuildPodThread = self:ForkThread(self.RebuildPod)
            end
        else
            self:CreateEnhancement('PodRemove')
        end
    end,

    ---Calling this function will pull any pods without explicit orders to our current task
    ---@param self UEL0301
    RefreshPodFocus = function(self)
        for _, pod in self:GetPods() do
            if not pod.Dead and pod:GetCommandQueue()[1].commandType == 29 then
                IssueToUnitClearCommands(pod)
            end
        end
    end,

    ---@param self UEL0301
    ---@return Unit[]? pods
    GetPods = function(self)
        return { self.Pod }
    end,

    ---@param self UEL0301
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportAttach = function(self, bone, attachee)
        CommandUnit.OnTransportAttach(self, bone, attachee)
        attachee:SetDoNotTarget(true)
    end,

    ---@param self UEL0301
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportDetach = function(self, bone, attachee)
        CommandUnit.OnTransportDetach(self, bone, attachee)
        attachee:SetDoNotTarget(false)
    end,


    -- ============================================================================================================================================================
    -- ENHANCEMENTS

    --- Returns the live radius of the light support bubble shield.
    --- The heavy bubble deliberately does not use this bonus.
    ---@param self UEL0301
    ---@return number
    GetSupportShieldRadius = function(self)
        local shieldBp = self.Blueprint.Enhancements.ShieldGeneratorFieldSupport
        local radius = shieldBp and shieldBp.ShieldSize or 0
        if self:HasEnhancement('SensorRangeEnhancer') then
            radius = radius + (shieldBp and shieldBp.SensorRangeBonus or 0)
        end
        return radius
    end,

    --- Applies the radar bonus to the currently active light bubble shield.
    --- The heavy bubble is checked first because it keeps the light shield as
    --- a prerequisite in the enhancement list.
    ---@param self UEL0301
    UpdateSupportShieldRadius = function(self)
        if self:HasEnhancement('ShieldGeneratorField')
            or not self:HasEnhancement('ShieldGeneratorFieldSupport') then
            return
        end

        local shield = self.MyShield
        if not shield or shield:BeenDestroyed() then
            return
        end

        local radius = self:GetSupportShieldRadius()
        if shield.Size == radius then
            return
        end

        shield:SetSize(radius)
        if shield:IsUp() then
            -- Rebuild the active mesh and collision sphere without recreating
            -- the shield entity or resetting its current health.
            shield:RemoveShield()
            shield:CreateShieldMesh()
        end
    end,

    --- Drone Upgrade
    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementPod = function(self, bp)
        local location = self:GetPosition('AttachSpecial01')
        ---@type UEA0003
        ---@diagnostic disable-next-line: assign-type-mismatch
        local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
        pod:SetParent(self, 'Pod')
        pod:SetCreator(self)
        self.Trash:Add(pod)
        self.HasPodEnh = true
        self.Pod = pod
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementPodRemove = function(self, bp)
        if self.HasPodEnh == true then
            self.HasPodEnh = false
            if self.Pod and not self.Pod:BeenDestroyed() then
                self.Pod:Kill()
                self.Pod = nil
            end
            if self.RebuildingPod ~= nil then
                RemoveEconomyEvent(self, self.RebuildingPod)
                self.RebuildingPod = nil
            end
        end
        KillThread(self.RebuildPodThread)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function (self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self.ActiveShieldEnhancement = 'Shield'
        local savedBonus = self.AeonShieldAmpBonus
        local savedMult = self.AeonShieldAmpMult
        if savedBonus then
            self:AeonShieldAmpRemove()
        end
        self:ApplyEnhancementUpkeep('Shield', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:CreateShield(bp)
        if savedBonus and Buff.HasBuff(self, 'AeonShieldAmplifier') then
            self:AeonShieldAmpApply(nil, savedMult or 1)
        end
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function (self, bp)
        RemoveUnitEnhancement(self, 'Shield')
        self:AeonShieldAmpRemove()
        self:DestroyShield()
        self.ActiveShieldEnhancement = nil
        self:ApplyEnhancementUpkeep('Shield', nil)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorField = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self.ActiveShieldEnhancement = 'ShieldGeneratorField'
        local savedBonus = self.AeonShieldAmpBonus
        local savedMult = self.AeonShieldAmpMult
        if savedBonus then
            self:AeonShieldAmpRemove()
        end
        self:DestroyShield()
        self:CreateShield(bp)
        self:ApplyEnhancementUpkeep('Shield', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        if savedBonus and Buff.HasBuff(self, 'AeonShieldAmplifier') then
            self:AeonShieldAmpApply(nil, savedMult or 1)
        end
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldGeneratorFieldRemove = function(self, bp)
        self:AeonShieldAmpRemove()
        self:DestroyShield()
        self.ActiveShieldEnhancement = nil
        self:ApplyEnhancementUpkeep('Shield', nil)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorFieldSupport = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self.ActiveShieldEnhancement = 'ShieldGeneratorFieldSupport'
        local savedBonus = self.AeonShieldAmpBonus
        local savedMult = self.AeonShieldAmpMult
        if savedBonus then
            self:AeonShieldAmpRemove()
        end
        self:DestroyShield()
        self:CreateShield(bp)
        self:ApplyEnhancementUpkeep('Shield', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:UpdateSupportShieldRadius()
        if savedBonus and Buff.HasBuff(self, 'AeonShieldAmplifier') then
            self:AeonShieldAmpApply(nil, savedMult or 1)
        end
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldGeneratorFieldSupportRemove = function(self, bp)
        self:AeonShieldAmpRemove()
        self:DestroyShield()
        self.ActiveShieldEnhancement = nil
        self:ApplyEnhancementUpkeep('Shield', nil)
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancer = function(self, bp)
        self.SensorRangeEnhancerInstalled = true
        self.SensorRangeEnhancerEnabled = true
        self:SetIntelRadius('Vision', bp.NewVisionRadius or 40)
        self:SetIntelRadius('Omni', bp.NewOmniRadius or 35)
        self:SetIntelRadius('Radar', bp.NewRadarRadius or 120)
        self:EnableUnitIntel('Enhancement', 'Omni')
        self:EnableUnitIntel('Enhancement', 'Radar')
        self:UpdateSupportShieldRadius()
        self:ApplyEnhancementUpkeep('SensorRangeEnhancer', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:AddToggleCap('RULEUTC_IntelToggle')
        self:SetScriptBit('RULEUTC_IntelToggle', false)
    end,

    ---@param self UEL0301
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
        self:UpdateSupportShieldRadius()
        self:ApplyEnhancementUpkeep('SensorRangeEnhancer', nil)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRadarJammer = function(self, bp)
        self.RadarJammerEnh = true
        self:SetIntelRadius('Jammer', bp.NewJammerRadius or 26)
        self:EnableUnitIntel('Enhancement', 'Jammer')
        self:AddToggleCap('RULEUTC_JammingToggle')
        self:ApplyEnhancementUpkeep('RadarJammer', bp.MaintenanceConsumptionPerSecondEnergy or 0)

        -- Бонус здоровья за джаммер
        if bp.ACUAddHealth and bp.ACUAddHealth > 0 then
            if not Buffs['UEL0301JammerHealth'] then
                BuffBlueprint {
                    Name = 'UEL0301JammerHealth',
                    DisplayName = 'UEL0301JammerHealth',
                    BuffType = 'SCUBUFF',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.ACUAddHealth,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'UEL0301JammerHealth')
        end

        if self.IntelEffects then
            self.IntelEffectsBag = {}
            self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle',  self.Layer, nil, self.IntelEffectsBag)
        end
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementRadarJammerRemove = function(self, bp)
        self.RadarJammerEnh = false
        self:SetIntelRadius('Jammer', 0)
        self:DisableUnitIntel('Enhancement', 'Jammer')
        self:RemoveToggleCap('RULEUTC_JammingToggle')
        self:ApplyEnhancementUpkeep('RadarJammer', nil)

        -- Снимаем бонус здоровья
        if Buff.HasBuff(self, 'UEL0301JammerHealth') then
            Buff.RemoveBuff(self, 'UEL0301JammerHealth')
        end

        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
        end
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedCoolingUpgrade = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:ChangeRateOfFire(bp.NewRateOfFire)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementAdvancedCoolingUpgradeRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:ChangeRateOfFire(self.Blueprint.Weapon[1].RateOfFire or 1)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHighExplosiveOrdnance = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadius)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHighExplosiveOrdnanceRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadius)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        wep:ChangeRateOfFire(self.Blueprint.Weapon[1].RateOfFire or 1)
        wep:ChangeRateOfFire(self.Blueprint.Weapon[1].RateOfFire or 1)
    end,

    --- Keep the dome shield, jammer and radar independently switchable.
    ---@param self UEL0301
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 0 then
            self:EnableShield()
            self:ApplyEnhancementUpkeep('Shield', self:GetActiveShieldUpkeep())
        elseif bit == 2 then
            self:DisableUnitIntel('ToggleBit2', 'Jammer')
            self:ApplyEnhancementUpkeep('RadarJammer', nil)
        elseif bit == 3 then
            self.SensorRangeEnhancerEnabled = false
            self:DisableUnitIntel('ToggleBit3', 'Radar')
            self:DisableUnitIntel('ToggleBit3', 'Omni')
            self:ApplyEnhancementUpkeep('SensorRangeEnhancer', nil)
        else
            CommandUnit.OnScriptBitSet(self, bit)
        end
    end,

    ---@param self UEL0301
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 0 then
            self:DisableShield()
            self:ApplyEnhancementUpkeep('Shield', nil)
        elseif bit == 2 then
            if self.RadarJammerEnh then
                self:EnableUnitIntel('ToggleBit2', 'Jammer')
                local bp = self.Blueprint.Enhancements.RadarJammer
                self:ApplyEnhancementUpkeep('RadarJammer', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            end
        elseif bit == 3 then
            if self.SensorRangeEnhancerInstalled then
                self.SensorRangeEnhancerEnabled = true
                self:EnableUnitIntel('ToggleBit3', 'Radar')
                self:EnableUnitIntel('ToggleBit3', 'Omni')
                local bp = self.Blueprint.Enhancements.SensorRangeEnhancer
                self:ApplyEnhancementUpkeep('SensorRangeEnhancer', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            end
        else
            CommandUnit.OnScriptBitClear(self, bit)
        end
    end,

    ---@param self UEL0301
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

    ---@param self UEL0301
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CommandUnit.OnIntelEnabled(self, intel)
        if self.RadarJammerEnh and self:IsIntelEnabled('Jammer') then
            if self.IntelEffects then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle',  self.Layer, nil, self.IntelEffectsBag)
            end
            self:ApplyEnhancementUpkeep(
                'RadarJammer',
                self.Blueprint.Enhancements.RadarJammer.MaintenanceConsumptionPerSecondEnergy or 0
            )
        end
    end,

    ---@param self UEL0301
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CommandUnit.OnIntelDisabled(self, intel)
        if self.RadarJammerEnh and not self:IsIntelEnabled('Jammer') then
            self:ApplyEnhancementUpkeep('RadarJammer', nil)
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            end
        end
    end,

    --- Called by the Aeon SACU Shield Amplifier aura when this SACU enters its field.
    --- The SACU's shields are enhancement-based (Shield / ShieldGeneratorFieldSupport
    --- / ShieldGeneratorField), not a Defense.Shield entry, so the base spec is taken
    --- from the current enhancement instead of the blueprint. Applies a fixed
    --- multiplier to the shield max (a number for all shields, or a table with
    --- per-enhancement values).
    ---@param self UEL0301
    ---@param instigator Unit
    ---@param mult number|table # multiplier, or { Shield = n, ShieldGeneratorFieldSupport = n, ShieldGeneratorField = n }
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
        local baseBp = self:HasEnhancement('ShieldGeneratorField') and enhBp.ShieldGeneratorField
            or (self:HasEnhancement('ShieldGeneratorFieldSupport') and enhBp.ShieldGeneratorFieldSupport or nil)
            or (self:HasEnhancement('Shield') and enhBp.Shield or nil)
        if not baseBp then
            return
        end

        local resolvedMult = mult
        if type(mult) == 'table' then
            resolvedMult = self:HasEnhancement('ShieldGeneratorField') and mult.ShieldGeneratorField
                or (self:HasEnhancement('ShieldGeneratorFieldSupport') and mult.ShieldGeneratorFieldSupport or nil)
                or mult.Shield or 1
        end
        local baseMax = baseBp.ShieldMaxHealth or 0
        local bonus = math.floor(baseMax * ((resolvedMult or 1) - 1) + 0.5)
        if bonus <= 0 then
            return
        end

        self:AeonShieldAmpApplyBonus(bonus, mult)
    end,

    --- Called when the SACU leaves the aura field (or the enhancement is removed):
    --- immediately subtracts the bonus from both current and max HP.
    ---@param self UEL0301
    AeonShieldAmpRemove = function(self)
        self:AeonShieldAmpRemoveBonus()
    end,

    --- Re-applies the shield amplifier boost after the SACU switches shield
    --- enhancements while standing inside the aura.
    ---@param self UEL0301
    RefreshShieldAmplifierBuff = function(self)
        local mult = self:AeonShieldAmpGetSourceMult() or self.AeonShieldAmpMult
        if mult and Buff.HasBuff(self, 'AeonShieldAmplifier') then
            self:AeonShieldAmpRemove()
            self:AeonShieldAmpApply(nil, mult)
        end
    end,
}

TypeClass = UEL0301

--#region Mod Compatibility
local Shield = import("/lua/shield.lua").Shield
--#endregion
