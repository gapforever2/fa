-----------------------------------------------------------------
-- **
-- File     :  /cdimage/units/UAL0001/UAL0001_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- **
-- Summary  :  Aeon Commander Script
-- **
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias AeonACUEnhancementBuffType
---| "DamageStabilization"
---| "ACUBUILDRATE"

---@alias AeonACUEnhancementBuffName          # BuffType
---| "AeonACUChronoDampener"                  # DamageStabilization
---| "AeonACUT2BuildRate"                     # ACUBUILDRATE
---| "AeonACUT3BuildRate"                     # ACUBUILDRATE


local ACUUnit = import("/lua/defaultunits.lua").ACUUnit
local AWeapons = import("/lua/aeonweapons.lua")
local ADFDisruptorCannonWeapon = AWeapons.ADFDisruptorCannonWeapon
local ACUDeathWeapon = import("/lua/sim/defaultweapons.lua").ACUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local ADFOverchargeWeapon = AWeapons.ADFOverchargeWeapon
local ADFChronoDampener = AWeapons.ADFChronoDampener
local Buff = import("/lua/sim/buff.lua")

---@class UAL0001 : ACUUnit
UAL0001 = ClassUnit(ACUUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        RightDisruptor = ClassWeapon(ADFDisruptorCannonWeapon) {},
        ChronoDampener = ClassWeapon(ADFChronoDampener) {},
        OverCharge = ClassWeapon(ADFOverchargeWeapon) {},
        AutoOverCharge = ClassWeapon(ADFOverchargeWeapon) {},
    },

    __init = function(self)
        ACUUnit.__init(self, 'RightDisruptor')
    end,

    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetupBuildBones()
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        -- Set initial range of Chrono here so that max range can be displayed in the UI
        local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
        local cd = self:GetWeaponByLabel('ChronoDampener')
        cd:ChangeMaxRadius(bpDisrupt)
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('RightDisruptor', true)
        self:SetWeaponEnabledByLabel('ChronoDampener', false)
        self:ForkThread(self.GiveInitialResources)
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        -- Resource Allocation
        if enh == 'ResourceAllocationAeon' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
        elseif enh == 'ResourceAllocationAeonRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvancedAeon' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
        elseif enh == 'ResourceAllocationAdvancedAeonRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        -- Shields
        elseif enh == 'ShieldAeon' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldAeonRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldHeavyAeon' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:ForkThread(self.CreateHeavyShield, bp)
        elseif enh == 'ShieldHeavyAeonRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        -- Teleporter
        elseif enh == 'TeleporterAeon' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterAeonRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        -- Chrono Dampener
        elseif enh == 'ChronoDampenerAeon' then
            self:SetWeaponEnabledByLabel('ChronoDampener', true)
            if not Buffs['AeonACUChronoDampener'] then
                BuffBlueprint {
                    Name = 'AeonACUChronoDampener',
                    DisplayName = 'AeonACUChronoDampener',
                    BuffType = 'DamageStabilization',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonACUChronoDampener')
        elseif enh == 'ChronoDampenerAeonRemove' then
            if Buff.HasBuff(self, 'AeonACUChronoDampener') then
                Buff.RemoveBuff(self, 'AeonACUChronoDampener')
            end
            self:SetWeaponEnabledByLabel('ChronoDampener', false)
        -- T2 Engineering
        elseif enh =='EngineeringT2Aeon' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)

        if not Buffs['AeonACUT2BuildRate'] then
                BuffBlueprint {
                    Name = 'AeonACUT2BuildRate',
                    DisplayName = 'AeonACUT2BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
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
            Buff.ApplyBuff(self, 'AeonACUT2BuildRate')
        elseif enh =='EngineeringT2AeonRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'AeonACUT2BuildRate') then
                Buff.RemoveBuff(self, 'AeonACUT2BuildRate')
         end
        -- T3 Engineering
        elseif enh =='T3EngineeringAeon' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['AeonACUT3BuildRate'] then
                BuffBlueprint {
                    Name = 'AeonACUT3BuildRate',
                    DisplayName = 'AeonCUT3BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
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
            Buff.ApplyBuff(self, 'AeonACUT3BuildRate')
        elseif enh =='T3EngineeringAeonRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'AeonACUT3BuildRate') then
                Buff.RemoveBuff(self, 'AeonACUT3BuildRate')
         end
        elseif enh == 'GAP_CrysalisBeamAdvancedAeon' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bp.NewMaxRadius)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius)
            local cd = self:GetWeaponByLabel('ChronoDampener')
            cd:ChangeMaxRadius(bp.NewMaxRadius)
        elseif enh == 'GAP_CrysalisBeamAdvancedAeonRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt)
            local cd = self:GetWeaponByLabel('ChronoDampener')
            cd:ChangeMaxRadius(bpDisrupt)
		elseif enh == 'GAP_CrysalisBeamAdaptiveAeon' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bp.NewMaxRadius)
			wep:ChangeRateOfFire(bp.NewRateOfFire)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius)
            local cd = self:GetWeaponByLabel('ChronoDampener')
            cd:ChangeMaxRadius(bp.NewMaxRadius)
        elseif enh == 'GAP_CrysalisBeamAdaptiveAeonRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
			local bpDisrupt = self:GetBlueprint().Weapon[1].RateOfFire
            wep:ChangeRateOfFire(bpDisrupt)
			wep:ChangeMaxRadius(bpDisrupt)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt)
            local cd = self:GetWeaponByLabel('ChronoDampener')
            cd:ChangeMaxRadius(bpDisrupt)
        -- Heat Sink Augmentation
        elseif enh == 'HeatSinkAeon' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeRateOfFire(bp.NewRateOfFire)
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bp.NewMaxRadius)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius)
            local cd = self:GetWeaponByLabel('ChronoDampener')
            cd:ChangeMaxRadius(bp.NewMaxRadius)
        elseif enh == 'HeatSinkAeonRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].RateOfFire
            wep:ChangeRateOfFire(bpDisrupt)
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt)
            local cd = self:GetWeaponByLabel('ChronoDampener')
            cd:ChangeMaxRadius(bpDisrupt)
        -- Enhanced Sensor Systems
        elseif enh == 'EnhancedSensorsAeon' then
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        elseif enh == 'EnhancedSensorsAeonRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
            self:SetMaintenanceConsumptionInactive()
      end
    end,

    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end
}

TypeClass = UAL0001
