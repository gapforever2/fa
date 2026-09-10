-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0301/URL0301_script.lua
-- Author(s):  David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Sub Commander Script
-- Copyright Š 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias CybranSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUCLOAKBONUS"
---| "SCUREGENERATEBONUS"
---| "SCUSTEALTHBONUS"

---@alias CybranSCUEnhancementBuffName        # BuffType
---| "CybranSCUBuildRate"                     # SCUBUILDRATE
---| "CybranSCUCloakBonus"                    # SCUCLOAKBONUS
---| "CybranSCURegenerateBonus"               # SCUREGENERATEBONUS
---| "CybranSCUStealthBonus"                  # SCUSTEALTHBONUS


local CybranUnits = import("/lua/cybranunits.lua")
local CCommandUnit = CybranUnits.CCommandUnit
local CWeapons = import("/lua/cybranweapons.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")
local CAAMissileNaniteWeapon = CWeapons.CAAMissileNaniteWeapon
local CDFLaserDisintegratorWeapon = CWeapons.CDFLaserDisintegratorWeapon02
local CDFLaserDisintegratorWeapon01 = CWeapons.CDFLaserDisintegratorWeapon01
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon
local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CDFParticleCannonWeapon = import('/lua/cybranweapons.lua').CDFParticleCannonWeapon
local StealthFieldAuraVisualId = 'StealthFieldCybranSCU'


---@class URL0301 : CCommandUnit
---@field HasStealthEnh? boolean
---@field HasCloakEnh? boolean
URL0301 = ClassUnit(CCommandUnit) {
    LeftFoot = 'Left_Foot02',
    RightFoot = 'Right_Foot02',

    -- Match the stock counter-intelligence overlay color while keeping the
    -- ring visible independently of selection. The radius follows the same
    -- live provider that configures RadarStealthField and SonarStealthField.
    AuraVisuals = {
        [StealthFieldAuraVisualId] = {
            IsActive = function(self)
                return self.HasStealthFieldEnh == true
                    and self.StealthFieldEnabled == true
                    and self:IsIntelEnabled('RadarStealthField')
                    and self:IsIntelEnabled('SonarStealthField')
            end,
            Color = 'ff804516',
            Thickness = 0.12,
            GetRadius = function(self)
                return self:GetEnhancementAuraRadius('StealthField')
            end,
        },
    },

    Weapons = {
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
        RightDisintegrator = ClassWeapon(CDFLaserDisintegratorWeapon) {
            OnCreate = function(self)
                CDFLaserDisintegratorWeapon.OnCreate(self)
                self:DisableBuff('STUN')
            end,

            ---@param self Weapon
            ---@param damage number|nil
            ---@param radius number|nil
            SetEMPShieldDamage = function(self, damage, radius)
                self.EMPShieldDamage = damage
                self.EMPShieldDamageRadius = radius
                self.damageTableCacheValid = false
            end,

            ---@param self Weapon
            ---@return WeaponDamageTable
            GetUpdatedDamageTable = function(self)
                local damageTable = CDFLaserDisintegratorWeapon.GetUpdatedDamageTable(self)
                damageTable.EMPShieldDamage = self.EMPShieldDamage
                damageTable.EMPShieldDamageRadius = self.EMPShieldDamageRadius
                return damageTable
            end,
        },
        NMissile = ClassWeapon(CAAMissileNaniteWeapon) {},
    },

    ---@param self URL0301
    OnCreate = function(self)
        CCommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:ShowBone('Engineering_Arm', true)
        self:HideBone('Barrel_L', true)
        self:HideBone('AA_Gun', true)
        self:HideBone('Power_Pack', true)
        self:HideBone('Rez_Protocol', true)
        self:HideBone('Torpedo', true)
        self:HideBone('Turbine', true)
        self:SetWeaponEnabledByLabel('NMissile', false)
        if self.Blueprint.General.BuildBones then
            self:SetupBuildBones()
        end
    end,

    ---@param self URL0301
    __init = function(self)
        CCommandUnit.__init(self, 'RightDisintegrator')
    end,

    --- Aggregates concurrently active enhancement upkeep instead of allowing
    --- stealth, sensors and the speed aura to overwrite the same engine value.
    ---@param self URL0301
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

    ---@param self URL0301
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CCommandUnit.OnStopBeingBuilt(self, builder, layer)
        self:BuildManipulatorSetEnabled(false)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self:DisableUnitIntel('Enhancement', 'Cloak')
        self:DisableUnitIntel('Enhancement', 'RadarStealthField')
        self:DisableUnitIntel('Enhancement', 'SonarStealthField')
        self.LeftArmUpgrade = 'EngineeringArm'
        self.RightArmUpgrade = 'Disintegrator'
    end,


    -- =====================================================================================================================4
    -- ENHANCEMENTS

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementCloakingGenerator = function (self, bp)

        self:AddToggleCap('RULEUTC_StealthToggle')
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        self.HasStealthEnh = true
        self:EnableUnitIntel('Enhancement', 'RadarStealth')
        self:EnableUnitIntel('Enhancement', 'SonarStealth')

        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:AddToggleCap('RULEUTC_CloakToggle')
        self.HasStealthEnh = false
        self.HasCloakEnh = true
        self:EnableUnitIntel('Enhancement', 'Cloak')
        self:ApplyEnhancementUpkeep('StealthSystem', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        if not Buffs['CybranSCUCloakBonus'] then
            BuffBlueprint {
                Name = 'CybranSCUCloakBonus',
                DisplayName = 'CybranSCUCloakBonus',
                BuffType = 'SCUCLOAKBONUS',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.NewHealth,
                        Mult = 1.0,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'CybranSCUCloakBonus') then
            Buff.RemoveBuff(self, 'CybranSCUCloakBonus')
        end
        Buff.ApplyBuff(self, 'CybranSCUCloakBonus')
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementCloakingGeneratorRemove = function (self, bp)

        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self.HasStealthEnh = false

        -- remove prerequisites
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')

        -- remove cloak
        self:DisableUnitIntel('Enhancement', 'Cloak')
        self.HasCloakEnh = false
        self:ApplyEnhancementUpkeep('StealthSystem', nil)
        self:RemoveToggleCap('RULEUTC_CloakToggle')
        if Buff.HasBuff(self, 'CybranSCUCloakBonus') then
            Buff.RemoveBuff(self, 'CybranSCUCloakBonus')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthGenerator = function (self, bp)
        if self.StealthFieldInstalled then
            self:SetStealthFieldEnabled(false)
            self.StealthFieldInstalled = false
            self.HasStealthFieldEnh = false
            self:RemoveToggleCap('RULEUTC_WeaponToggle')
        end

        self.PersonalStealthInstalled = true
        self:AddToggleCap('RULEUTC_StealthToggle')
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        self.HasStealthEnh = true
        self:EnableUnitIntel('StealthFieldStage', 'RadarStealth')
        self:EnableUnitIntel('StealthFieldStage', 'SonarStealth')
        self:EnableUnitIntel('Enhancement', 'RadarStealth')
        self:EnableUnitIntel('Enhancement', 'SonarStealth')
        self:ApplyEnhancementUpkeep('StealthSystem', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        if not Buffs['CybranSCUStealthBonus'] then
            BuffBlueprint {
                Name = 'CybranSCUStealthBonus',
                DisplayName = 'CybranSCUStealthBonus',
                BuffType = 'SCUSTEALTHBONUS',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.NewHealth or 2500,
                        Mult = 1.0,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'CybranSCUStealthBonus') then
            Buff.RemoveBuff(self, 'CybranSCUStealthBonus')
        end
        Buff.ApplyBuff(self, 'CybranSCUStealthBonus')
        self:SetScriptBit('RULEUTC_StealthToggle', false)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthGeneratorRemove = function (self, bp)
        if self.StealthFieldInstalled then
            self:SetStealthFieldEnabled(false)
            self.StealthFieldInstalled = false
            self.HasStealthFieldEnh = false
            self:RemoveToggleCap('RULEUTC_WeaponToggle')
        end
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('StealthFieldStage', 'RadarStealth')
        self:DisableUnitIntel('StealthFieldStage', 'SonarStealth')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self.PersonalStealthInstalled = false
        self.HasStealthEnh = false
        self:ApplyEnhancementUpkeep('StealthSystem', nil)
        if Buff.HasBuff(self, 'CybranSCUStealthBonus') then
            Buff.RemoveBuff(self, 'CybranSCUStealthBonus')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthField = function (self, bp)
        -- This is the next stage of the same slot. Area stealth replaces the
        -- personal stealth Intel, toggle and health bonus instead of stacking.
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('StealthFieldStage', 'RadarStealth')
        self:DisableUnitIntel('StealthFieldStage', 'SonarStealth')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self.PersonalStealthInstalled = false
        self.HasStealthEnh = false
        if Buff.HasBuff(self, 'CybranSCUStealthBonus') then
            Buff.RemoveBuff(self, 'CybranSCUStealthBonus')
        end

        self.HasStealthFieldEnh = true
        self.StealthFieldInstalled = true
        self.StealthFieldEnabled = true
        self:UpdateStealthFieldRadius()
        self:EnableUnitIntel('Enhancement', 'RadarStealthField')
        self:EnableUnitIntel('Enhancement', 'SonarStealthField')
        self:ApplyEnhancementUpkeep('StealthSystem', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:AddToggleCap('RULEUTC_WeaponToggle')
        self:SetScriptBit('RULEUTC_WeaponToggle', false)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthFieldRemove = function (self, bp)
        self:SetStealthFieldEnabled(false)
        self.HasStealthFieldEnh = false
        self.StealthFieldInstalled = false
        self:RemoveToggleCap('RULEUTC_WeaponToggle')
        self:ApplyEnhancementUpkeep('StealthSystem', nil)
    end,

    --- Enables or disables the installed area stealth field.
    ---@param self URL0301
    ---@param enabled boolean
    SetStealthFieldEnabled = function(self, enabled)
        if enabled and not self.StealthFieldInstalled then
            return
        end

        self.StealthFieldEnabled = enabled
        if enabled then
            self:EnableUnitIntel('ToggleBit1', 'RadarStealthField')
            self:EnableUnitIntel('ToggleBit1', 'SonarStealthField')
            local bp = self.Blueprint.Enhancements.StealthField
            self:ApplyEnhancementUpkeep('StealthSystem', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        else
            self:DisableUnitIntel('ToggleBit1', 'RadarStealthField')
            self:DisableUnitIntel('ToggleBit1', 'SonarStealthField')
            local personal = self.Blueprint.Enhancements.StealthGenerator
            local personalEnabled = self.HasStealthEnh
                and self:IsIntelEnabled('RadarStealth')
                and self:IsIntelEnabled('SonarStealth')
            self:ApplyEnhancementUpkeep(
                'StealthSystem',
                personalEnabled and personal.MaintenanceConsumptionPerSecondEnergy or nil
            )
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementNaniteMissileSystem = function(self, bp)
        self:ShowBone('AA_Gun', true)
        self:SetWeaponEnabledByLabel('NMissile', true)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementNaniteMissileSystemRemove = function(self, bp)
        self:HideBone('AA_Gun', true)
        self:SetWeaponEnabledByLabel('NMissile', false)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSelfRepairSystem = function(self, bp)
        local bpRegenRate = self.Blueprint.Enhancements.SelfRepairSystem.NewRegenRate or 0
        if not Buffs['CybranSCURegenerateBonus'] then
            BuffBlueprint {
                Name = 'CybranSCURegenerateBonus',
                DisplayName = 'CybranSCURegenerateBonus',
                BuffType = 'SCUREGENERATEBONUS',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    Regen = {
                        Add = bpRegenRate,
                        Mult = 1.0,
                    },
                    MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
            Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
        end
        Buff.ApplyBuff(self, 'CybranSCURegenerateBonus')
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSelfRepairSystemRemove = function(self, bp)
        if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
            Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
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
    ProcessEnhancementSwitchback = function(self, bp)
        self.BuildBotTotal = 4
        if not Buffs['CybranSCUBuildRate'] then
            BuffBlueprint {
                Name = 'CybranSCUBuildRate',
                DisplayName = 'CybranSCUBuildRate',
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
        Buff.ApplyBuff(self, 'CybranSCUBuildRate')
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSwitchbackRemove = function(self, bp)
        self.BuildBotTotal = 3
        if Buff.HasBuff(self, 'CybranSCUBuildRate') then
            Buff.RemoveBuff(self, 'CybranSCUBuildRate')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFocusConvertor = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:ReEnableBuff('STUN')
        wep:SetEMPShieldDamage(bp.EMPShieldDamage or 300, bp.EMPShieldDamageRadius or 3)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFocusConvertorRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:DisableBuff('STUN')
        wep:SetEMPShieldDamage(nil, nil)
        wep:ChangeMaxRadius(wep:GetBlueprint().MaxRadius or 25)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRapidFire = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRapidFireRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:ChangeRateOfFire(bp.RateOfFire or 1)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancer = function(self, bp)
        self.SensorRangeEnhancerInstalled = true
        self.SensorRangeEnhancerEnabled = true
        self:SetIntelRadius('Vision', bp.NewVisionRadius or 30)
        self:SetIntelRadius('Omni', bp.NewOmniRadius or 55)
        self:SetIntelRadius('Radar', bp.NewRadarRadius or 90)
        self:EnableUnitIntel('Enhancement', 'Omni')
        self:EnableUnitIntel('Enhancement', 'Radar')
        self:UpdateStealthFieldRadius()
        self:ApplyEnhancementUpkeep('SensorRangeEnhancer', bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:AddToggleCap('RULEUTC_IntelToggle')
        self:SetScriptBit('RULEUTC_IntelToggle', false)
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
        self:SetIntelRadius('Radar', bpIntel.RadarRadius or 0)
        self:UpdateStealthFieldRadius()
        self:ApplyEnhancementUpkeep('SensorRangeEnhancer', nil)
    end,

    --- Returns the live radius of an enhancement aura. The sensor upgrade
    --- adds its explicit bonus to the base radius of each supported aura.
    ---@param self URL0301
    ---@param enhancementName string
    ---@return number
    GetEnhancementAuraRadius = function(self, enhancementName)
        local enhancement = self.Blueprint.Enhancements[enhancementName]
        local radius = enhancement and enhancement.Radius or 0
        if self:HasEnhancement('SensorRangeEnhancer') then
            radius = radius + (enhancement and enhancement.SensorRangeBonus or 0)
        end
        return radius
    end,

    --- Keeps the engine's stealth-field Intel radius in sync with the aura
    --- radius, including the sensor upgrade's bonus.
    ---@param self URL0301
    UpdateStealthFieldRadius = function(self)
        local radius = self:GetEnhancementAuraRadius('StealthField')
        self:SetIntelRadius('RadarStealthField', radius)
        self:SetIntelRadius('SonarStealthField', radius)
    end,

    -- Аура скорости: бафает наземных союзников в радиусе, бонус зависит от уровня.
    -- Категории-исключения: воздух, флот/подлодки, постройки, БМК, эксперименталки.
    SpeedAuraBuffs = {
        CybranSpeedAuraT1  = 1.35,
        CybranSpeedAuraT2  = 1.20,
        CybranSpeedAuraT3  = 1.15,
        CybranSpeedAuraSCU = 1.35,
    },

    ---@param self URL0301
    SpeedAuraThread = function(self)
        local brain = self:GetAIBrain()
        local cat = categories.MOBILE
            - categories.AIR
            - categories.NAVAL
            - categories.STRUCTURE
            - categories.COMMAND
            - categories.EXPERIMENTAL

        while not self.Dead do
            -- The carrier is guaranteed to receive the SACU multiplier even if
            -- GetUnitsAroundPoint does not include the source unit.
            Buff.ApplyBuff(self, 'CybranSpeedAuraSCU')

            local radius = self:GetEnhancementAuraRadius('SpeedAura')
            local units = brain:GetUnitsAroundPoint(cat, self:GetPosition(), radius, 'Ally')
            for _, u in units do
                if u ~= self and not u.Dead and not u:IsBeingBuilt() then
                    local buffName
                    if EntityCategoryContains(categories.SUBCOMMANDER, u) then
                        buffName = 'CybranSpeedAuraSCU'
                    elseif EntityCategoryContains(categories.TECH3, u) then
                        buffName = 'CybranSpeedAuraT3'
                    elseif EntityCategoryContains(categories.TECH2, u) then
                        buffName = 'CybranSpeedAuraT2'
                    elseif EntityCategoryContains(categories.TECH1, u) then
                        buffName = 'CybranSpeedAuraT1'
                    end
                    if buffName then
                        Buff.ApplyBuff(u, buffName)
                    end
                end
            end
            WaitTicks(11)
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSpeedAura = function(self, bp)
        self.SpeedAuraInstalled = true
        for name, mult in self.SpeedAuraBuffs do
            if not Buffs[name] then
                BuffBlueprint {
                    Name = name,
                    DisplayName = name,
                    BuffType = 'CYBRANSCUSPEEDAURA',
                    Stacks = 'REPLACE',
                    Duration = 2,
                    Affects = {
                        MoveMult = {
                            Mult = mult,
                        },
                    },
                }
            end
        end
        self:GetWeaponByLabel('RightDisintegrator'):AddDamageMod(bp.NewDamageMod or -200)
        if not Buffs['CybranSpeedAuraSelfDebuff'] then
            BuffBlueprint {
                Name = 'CybranSpeedAuraSelfDebuff',
                DisplayName = 'CybranSpeedAuraSelfDebuff',
                BuffType = 'CYBRANSCUSPEEDAURADEBUFF',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.ACUAddHealth or -4500,
                        Mult = 1.0,
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'CybranSpeedAuraSelfDebuff') then
            Buff.RemoveBuff(self, 'CybranSpeedAuraSelfDebuff')
        end
        Buff.ApplyBuff(self, 'CybranSpeedAuraSelfDebuff')
        self:AddToggleCap('RULEUTC_SpecialToggle')
        self:SetSpeedAuraEnabled(true)
        self:SetScriptBit('RULEUTC_SpecialToggle', false)
    end,

    --- Starts or stops the kinetic acceleration aura without uninstalling it.
    ---@param self URL0301
    ---@param enabled boolean
    SetSpeedAuraEnabled = function(self, enabled)
        if enabled and not self.SpeedAuraInstalled then
            return
        end

        self.SpeedAuraEnabled = enabled
        if enabled then
            local bp = self.Blueprint.Enhancements.SpeedAura
            self:ApplyEnhancementUpkeep('SpeedAura', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            if not self.SpeedAuraThreadHandle then
                self.SpeedAuraThreadHandle = self:ForkThread(self.SpeedAuraThread)
            end
        else
            if self.SpeedAuraThreadHandle then
                KillThread(self.SpeedAuraThreadHandle)
                self.SpeedAuraThreadHandle = nil
            end
            self:ApplyEnhancementUpkeep('SpeedAura', nil)
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSpeedAuraRemove = function(self, bp)
        self:SetSpeedAuraEnabled(false)
        self.SpeedAuraInstalled = false
        self:RemoveToggleCap('RULEUTC_SpecialToggle')
        self:GetWeaponByLabel('RightDisintegrator'):AddDamageMod(
            -(self.Blueprint.Enhancements.SpeedAura.NewDamageMod or -200)
        )
        if Buff.HasBuff(self, 'CybranSpeedAuraSelfDebuff') then
            Buff.RemoveBuff(self, 'CybranSpeedAuraSelfDebuff')
        end
    end,

    --- Keep radar, area stealth, personal stealth and acceleration independent.
    ---@param self URL0301
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 1 then
            self:SetStealthFieldEnabled(false)
        elseif bit == 3 then
            self.SensorRangeEnhancerEnabled = false
            self:DisableUnitIntel('ToggleBit3', 'Radar')
            self:DisableUnitIntel('ToggleBit3', 'Omni')
            self:ApplyEnhancementUpkeep('SensorRangeEnhancer', nil)
        elseif bit == 5 then
            self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit5', 'SonarStealth')
            local field = self.Blueprint.Enhancements.StealthField
            self:ApplyEnhancementUpkeep(
                'StealthSystem',
                self.StealthFieldEnabled and field.MaintenanceConsumptionPerSecondEnergy or nil
            )
        elseif bit == 7 then
            self:SetSpeedAuraEnabled(false)
        else
            CCommandUnit.OnScriptBitSet(self, bit)
        end
    end,

    ---@param self URL0301
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 1 then
            self:SetStealthFieldEnabled(true)
        elseif bit == 3 then
            if self.SensorRangeEnhancerInstalled then
                self.SensorRangeEnhancerEnabled = true
                self:EnableUnitIntel('ToggleBit3', 'Radar')
                self:EnableUnitIntel('ToggleBit3', 'Omni')
                local bp = self.Blueprint.Enhancements.SensorRangeEnhancer
                self:ApplyEnhancementUpkeep('SensorRangeEnhancer', bp.MaintenanceConsumptionPerSecondEnergy or 0)
            end
        elseif bit == 5 then
            if self.HasStealthEnh then
                self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
                self:EnableUnitIntel('ToggleBit5', 'SonarStealth')
                local field = self.Blueprint.Enhancements.StealthField
                local personal = self.Blueprint.Enhancements.StealthGenerator
                self:ApplyEnhancementUpkeep(
                    'StealthSystem',
                    (self.StealthFieldEnabled and field.MaintenanceConsumptionPerSecondEnergy)
                        or personal.MaintenanceConsumptionPerSecondEnergy
                        or 0
                )
            end
        elseif bit == 7 then
            self:SetSpeedAuraEnabled(true)
        else
            CCommandUnit.OnScriptBitClear(self, bit)
        end
    end,

    ---@param self URL0301
    ---@param enh Enhancement
    CreateEnhancement = function(self, enh)
        CCommandUnit.CreateEnhancement(self, enh)
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

    IntelEffects = {
        Cloak = {
            {
                Bones = {
                    'Head',
                    'Right_Elbow',
                    'Left_Elbow',
                    'Right_Arm01',
                    'Left_Shoulder',
                    'Torso',
                    'URL0301',
                    'Left_Thigh',
                    'Left_Knee',
                    'Left_Leg',
                    'Right_Thigh',
                    'Right_Knee',
                    'Right_Leg',
                },
                Scale = 1.0,
                Type = 'Cloak01',
            },
        },
        Field = {
            {
                Bones = {
                    'Head',
                    'Right_Elbow',
                    'Left_Elbow',
                    'Right_Arm01',
                    'Left_Shoulder',
                    'Torso',
                    'URL0301',
                    'Left_Thigh',
                    'Left_Knee',
                    'Left_Leg',
                    'Right_Thigh',
                    'Right_Knee',
                    'Right_Leg',
                },
                Scale = 1.6,
                Type = 'Cloak01',
            },
        },
    },

    ---@param self URL0301
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CCommandUnit.OnIntelEnabled(self, intel)
        if self.HasCloakEnh and self:IsIntelEnabled('Cloak') then
            self:ApplyEnhancementUpkeep(
                'StealthSystem',
                self.Blueprint.Enhancements.CloakingGenerator.MaintenanceConsumptionPerSecondEnergy or 0
            )
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        elseif self.HasStealthFieldEnh
            and self:IsIntelEnabled('RadarStealthField')
            and self:IsIntelEnabled('SonarStealthField')
        then
            self:ApplyEnhancementUpkeep(
                'StealthSystem',
                self.Blueprint.Enhancements.StealthField.MaintenanceConsumptionPerSecondEnergy or 0
            )
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Field, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        elseif self.HasStealthEnh and self:IsIntelEnabled('RadarStealth') and self:IsIntelEnabled('SonarStealth') then
            self:ApplyEnhancementUpkeep(
                'StealthSystem',
                self.Blueprint.Enhancements.StealthGenerator.MaintenanceConsumptionPerSecondEnergy or 0
            )
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Field, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        end
    end,

    ---@param self URL0301
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CCommandUnit.OnIntelDisabled(self, intel)
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        if self.HasCloakEnh and not self:IsIntelEnabled('Cloak') then
            self:ApplyEnhancementUpkeep('StealthSystem', nil)
        elseif self.HasStealthFieldEnh
            and not self:IsIntelEnabled('RadarStealthField')
            and not self:IsIntelEnabled('SonarStealthField')
        then
            self:ApplyEnhancementUpkeep('StealthSystem', nil)
        elseif self.HasStealthEnh and not self:IsIntelEnabled('RadarStealth') and not self:IsIntelEnabled('SonarStealth') then
            self:ApplyEnhancementUpkeep('StealthSystem', nil)
        end
    end,
}

TypeClass = URL0301
