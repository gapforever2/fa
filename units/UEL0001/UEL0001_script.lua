-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0001/UEL0001_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  UEF Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias UEFACUEnhancementBuffType
---| "DamageStabilization"
---| "ACUBUILDRATE"

---@alias UEFACUEnhancementBuffName           # BuffType
---| "UEFACUDamageStabilization"              # DamageStabilization
---| "UEFACUT2BuildRate"                      # ACUBUILDRATE
---| "UEFACUT3BuildRate"                      # ACUBUILDRATE


local Shield = import("/lua/shield.lua").Shield
local ACUUnit = import("/lua/defaultunits.lua").ACUUnit
local TerranWeaponFile = import("/lua/terranweapons.lua")
local TDFZephyrCannonWeapon = TerranWeaponFile.TDFZephyrCannonWeapon
local ACUDeathWeapon = import("/lua/sim/defaultweapons.lua").ACUDeathWeapon
local TIFCruiseMissileLauncher = TerranWeaponFile.TIFCruiseMissileLauncher
local TDFOverchargeWeapon = TerranWeaponFile.TDFOverchargeWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")

---@class UEL0001 : ACUUnit
---@field LeftPod TConstructionPodUnit
---@field RightPod TConstructionPodUnit
UEL0001 = ClassUnit(ACUUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        RightZephyr = ClassWeapon(TDFZephyrCannonWeapon) {},
        OverCharge = ClassWeapon(TDFOverchargeWeapon) {},
        AutoOverCharge = ClassWeapon(TDFOverchargeWeapon) {},
        TacMissile = ClassWeapon(TIFCruiseMissileLauncher) {
            PlayFxRackSalvoChargeSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoChargeSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    hatch:SetGoal(0, 0, 1.9):SetSpeed(9.5) -- Matches charge time - 0.1 seconds
                end
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoReloadSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    self.Trash:Add(
                        ForkThread(
                            self.CloseHatchThread, self, hatch
                        )
                    )
                end
            end,

            CloseHatchThread = function(self, slider)
                -- wait for the launch effects to clear
                WaitTicks(30)

                if IsDestroyed(slider) then
                    return
                end

                slider:SetGoal(0, 0, 0)
                slider:SetSpeed(1.12) -- speed matches reload time
            end,
        },

        TacNukeMissile = ClassWeapon(TIFCruiseMissileLauncher) {
            PlayFxRackSalvoChargeSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoChargeSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    self.unit.MissileHatchSlider:SetGoal(0, 0, 1.9):SetSpeed(9.5) -- Matches charge time - 0.1 seconds
                end
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoReloadSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    self.Trash:Add(
                        ForkThread(
                            self.CloseHatchThread, self, hatch
                        )
                    )
                end
            end,

            CloseHatchThread = function(self, slider)
                -- wait for the launch effects to clear
                WaitTicks(30)

                if IsDestroyed(slider) then
                    return
                end

                -- speed matches reload time
                slider:SetGoal(0, 0, 0)
                slider:SetSpeed(0.077)
            end,
        },
    },

    ---@param self UEL0001
    __init = function(self)
        ACUUnit.__init(self, 'RightZephyr')
    end,

    --- Keeps the indirect-fire overlay in sync with the installed launcher.
    ---@param self UEL0001
    ---@param tacticalEnabled boolean
    ---@param billyEnabled boolean
    SetMissileOverlayRanges = function(self, tacticalEnabled, billyEnabled)
        local tactical = self:GetWeaponByLabel('TacMissile')
        local tacticalBlueprint = tactical:GetBlueprint()
        tactical:ChangeMinRadius(tacticalEnabled and (tacticalBlueprint.MinRadius or 0) or 0)
        tactical:ChangeMaxRadius(tacticalEnabled and (tacticalBlueprint.MaxRadius or 0) or 0)

        local billy = self:GetWeaponByLabel('TacNukeMissile')
        local billyBlueprint = billy:GetBlueprint()
        billy:ChangeMinRadius(billyEnabled and (billyBlueprint.MinRadius or 0) or 0)
        billy:ChangeMaxRadius(billyEnabled and (billyBlueprint.MaxRadius or 0) or 0)
    end,

    ---@param self UEL0001
    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        self:HideBone('Back_Upgrade_B01', true)
        self:SetupBuildBones()
        self.HasLeftPod = false
        self.HasRightPod = false
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))

        local hatchBone = 'Back_Upgrade_B02'
        if self:IsValidBone(hatchBone) then
            self.MissileHatchSlider = CreateSlider(self, hatchBone)
        else
            WARN('*ERROR: Trying to use the bone, ' ..
                hatchBone .. ' on unit ' .. self.UnitId .. ' and it does not exist in the model.')
        end
    end,

    ---@param self UEL0001
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        if self:BeenDestroyed() then return end
        self.Animator = CreateAnimator(self)
        self.Animator:SetPrecedence(0)
        self:BuildManipulatorSetEnabled(false)
        self:SetWeaponEnabledByLabel('RightZephyr', true)
        self:SetWeaponEnabledByLabel('TacMissile', false)
        self:SetWeaponEnabledByLabel('TacNukeMissile', false)
        self:SetMissileOverlayRanges(false, false)
        self:ForkThread(self.GiveInitialResources)
    end,

    ---@param self UEL0001
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        ACUUnit.OnStartBuild(self, unitBeingBuilt, order)
        if self.Animator then
            self.Animator:SetRate(0)
        end
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStopBuild = function(self, unitBeingBuilt, order)
        ACUUnit.OnStopBuild(self, unitBeingBuilt, order)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingRepaired Unit
    OnStartRepair = function(self, unitBeingRepaired)
        ACUUnit.OnStartRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingRepaired Unit
    OnStopRepair = function(self, unitBeingRepaired)
        ACUUnit.OnStopRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param target Unit|Prop
    OnStartReclaim = function(self, target)
        ACUUnit.OnStartReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param target Unit|Prop
    OnStopReclaim = function(self, target)
        ACUUnit.OnStopReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            EffectUtil.CreateUEFCommanderBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones,
                self.BuildEffectsBag)
        else
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    ---@param self UEL0001
    ---@param PodNumber integer

    ---@param self UEL0001
    ---@param pod string
    ---@param rebuildDrone boolean
    RebuildPod = function(self, PodNumber)
        if PodNumber == 1 then
            -- Force pod rebuilds to queue up
            if self.RebuildingPod2 ~= nil then
                WaitFor(self.RebuildingPod2)
            end
            if self.HasLeftPod == true then
                self.RebuildingPod = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod)
                self.RebuildingPod = nil
                local location = self:GetPosition('AttachSpecial02')
                local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'LeftPod')
                pod:SetCreator(self)
                self.Trash:Add(pod)
                self.LeftPod = pod
            end
        elseif PodNumber == 2 then
            -- Force pod rebuilds to queue up
            if self.RebuildingPod ~= nil then
                WaitFor(self.RebuildingPod)
            end
            if self.HasRightPod == true then
                self.RebuildingPod2 = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod2)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod2)
                self.RebuildingPod2 = nil
                local location = self:GetPosition('AttachSpecial01')
                local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'RightPod')
                pod:SetCreator(self)
                self.Trash:Add(pod)
                self.RightPod = pod
            end
        end
        self:RequestRefreshUI()
    end,

    NotifyOfPodDeath = function(self, pod, rebuildDrone)
        if rebuildDrone == true then
            if pod == 'LeftPod' then
                if self.HasLeftPod == true then
                    self.RebuildThread = self:ForkThread(self.RebuildPod, 1)
                end
            elseif pod == 'RightPod' then
                if self.HasRightPod == true then
                    self.RebuildThread2 = self:ForkThread(self.RebuildPod, 2)
                end
            end
        else
            self:CreateEnhancement(pod..'Remove')
        end
    end,

    ---Calling this function will pull any pods without explicit orders to our current task
    ---@param self UEL0001
    RefreshPodFocus = function(self)
        for _, pod in self:GetPods() do
            if not pod.Dead and pod:GetCommandQueue()[1].commandType == 29 then
                IssueToUnitClearCommands(pod)
            end
        end
    end,

    ---@param self UEL0001
    ---@return Unit[]? pods
    GetPods = function(self)
        return {self.LeftPod, self.RightPod}
    end,

    ---@param self UEL0001
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportAttach = function(self, bone, attachee)
        ACUUnit.OnTransportAttach(self, bone, attachee)
        attachee:SetDoNotTarget(true)
    end,

    ---@param self UEL0001
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportDetach = function(self, bone, attachee)
        ACUUnit.OnTransportDetach(self, bone, attachee)
        attachee:SetDoNotTarget(false)
    end,

    ---@param self UEL0001
    ---@param enh string
    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)

        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        if enh == 'LeftPod' then
            local location = self:GetPosition('AttachSpecial02')
            local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'LeftPod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.HasLeftPod = true
            self.LeftPod = pod
        elseif enh == 'RightPod' then
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'RightPod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.HasRightPod = true
            self.RightPod = pod
        elseif enh == 'LeftPodRemove' or enh == 'RightPodRemove' then
            if self.HasLeftPod == true then
                self.HasLeftPod = false
                if self.LeftPod and not self.LeftPod.Dead then
                    self.LeftPod:Kill()
                    self.LeftPod = nil
                end
                if self.RebuildingPod ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod)
                    self.RebuildingPod = nil
                end
            end
            if self.HasRightPod == true then
                self.HasRightPod = false
                if self.RightPod and not self.RightPod.Dead then
                    self.RightPod:Kill()
                    self.RightPod = nil
                end
                if self.RebuildingPod2 ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod2)
                    self.RebuildingPod2 = nil
                end
            end
            KillThread(self.RebuildThread)
            KillThread(self.RebuildThread2)
        elseif enh == 'TeleporterUEF' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterUEFRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        elseif enh == 'ShieldUEF' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:CreateShield(bp)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:RefreshShieldAmplifierBuff()
        elseif enh == 'ShieldUEFRemove' then
            self:AeonShieldAmpRemove()
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            RemoveUnitEnhancement(self, 'ShieldRemove')
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldGeneratorFieldUEF' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            local savedBonus = self.AeonShieldAmpBonus
            local savedMult = self.AeonShieldAmpMult
            if savedBonus then
                self:AeonShieldAmpRemove()
            end
            self:DestroyShield()
            self:CreateShield(bp)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            if savedBonus and Buff.HasBuff(self, 'AeonShieldAmplifier') then
                self:AeonShieldAmpApply(nil, savedMult or 1)
            end
        elseif enh == 'ShieldGeneratorFieldUEFRemove' then
            self:AeonShieldAmpRemove()
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'EngineeringT2UEF' then
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['UEFACUT2BuildRate'] then
                BuffBlueprint {
                    Name = 'UEFACUT2BuildRate',
                    DisplayName = 'UEFACUT2BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add = bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
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
            Buff.ApplyBuff(self, 'UEFACUT2BuildRate')
        elseif enh == 'EngineeringT2UEFRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction(categories.UEF *
                (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            self:AddBuildRestriction(categories.UEF *
                (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'UEFACUT2BuildRate') then
                Buff.RemoveBuff(self, 'UEFACUT2BuildRate')
            end
        elseif enh == 'T3EngineeringUEF' then
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['UEFACUT3BuildRate'] then
                BuffBlueprint {
                    Name = 'UEFACUT3BuildRate',
                    DisplayName = 'UEFCUT3BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add = bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
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
            Buff.ApplyBuff(self, 'UEFACUT3BuildRate')
        elseif enh == 'T3EngineeringUEFRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            if Buff.HasBuff(self, 'UEFACUT3BuildRate') then
                Buff.RemoveBuff(self, 'UEFACUT3BuildRate')
            end
            self:AddBuildRestriction(categories.UEF *
                (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        elseif enh == 'DamageStabilizationUEF' then
            if not Buffs['UEFACUDamageStabilization'] then
                BuffBlueprint {
                    Name = 'UEFACUDamageStabilization',
                    DisplayName = 'UEFACUDamageStabilization',
                    BuffType = 'DamageStabilization',
                    Stacks = 'REPLACE',
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
            Buff.ApplyBuff(self, 'UEFACUDamageStabilization')
        elseif enh == 'DamageStabilizationUEFRemove' then
            if Buff.HasBuff(self, 'UEFACUDamageStabilization') then
                Buff.RemoveBuff(self, 'UEFACUDamageStabilization')
            end
        elseif enh == 'HeavyAntiMatterCannonUEF' then
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:AddDamageMod(bp.ZephyrDamageMod)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        elseif enh == 'HeavyAntiMatterCannonUEFRemove' then
            local bp = self:GetBlueprint().Enhancements['HeavyAntiMatterCannonUEF']
            if not bp then return end
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:AddDamageMod(-bp.ZephyrDamageMod)
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt or 22)
        elseif enh == 'HeavyAntiMatterDeeKeyUEF' then
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:ChangeProjectileBlueprint(bp.NewProjectileId)
            wep:AddDamageRadiusMod(bp.NewDamageRadius or 1)
            wep:AddDamageMod(bp.AdditionalDamage)
            wep:ChangeRateOfFire(bp.NewRateOfFire or 1.5)
        elseif enh == 'HeavyAntiMatterDeeKeyUEFRemove' then
            local bp = self:GetBlueprint().Enhancements['HeavyAntiMatterDeeKeyUEF']
            if not bp then return end
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:ChangeProjectileBlueprint(bp.ProjectileId)
            wep:AddDamageRadiusMod(-bp.NewDamageRadius or 1)
            wep:ChangeRateOfFire(bp.RateOfFire or 1)
            wep:AddDamageMod(-bp.AllDamageModAdd)
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 22)
            local bpDisruptRateOfFire = self:GetBlueprint().Weapon[1].RateOfFire
            wep:ChangeRateOfFire(bpDisruptRateOfFire or 1)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt or 22)
        elseif enh == 'ResourceAllocationUEF' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
        elseif enh == 'ResourceAllocationUEFRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'TacticalMissileUEF' then
            self:AddCommandCap('RULEUCC_Tactical')
            self:AddCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('TacMissile', true)
            self:SetMissileOverlayRanges(true, false)
        elseif enh == 'TacticalNukeMissileUEF' then
            self:RemoveCommandCap('RULEUCC_Tactical')
            self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
            self:AddCommandCap('RULEUCC_Nuke')
            self:AddCommandCap('RULEUCC_SiloBuildNuke')
            self:SetWeaponEnabledByLabel('TacMissile', false)
            self:SetWeaponEnabledByLabel('TacNukeMissile', true)
            self:SetMissileOverlayRanges(false, true)
            local amt = self:GetTacticalSiloAmmoCount()
            self:RemoveTacticalSiloAmmo(amt or 0)
            self:StopSiloBuild()
        elseif enh == 'TacticalMissileUEFRemove' or enh == 'TacticalNukeMissileUEFRemove' then
            self:RemoveCommandCap('RULEUCC_Nuke')
            self:RemoveCommandCap('RULEUCC_SiloBuildNuke')
            self:RemoveCommandCap('RULEUCC_Tactical')
            self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('TacMissile', false)
            self:SetWeaponEnabledByLabel('TacNukeMissile', false)
            self:SetMissileOverlayRanges(false, false)
            local amt = self:GetTacticalSiloAmmoCount()
            self:RemoveTacticalSiloAmmo(amt or 0)
            local amt = self:GetNukeSiloAmmoCount()
            self:RemoveNukeSiloAmmo(amt or 0)
            self:StopSiloBuild()
        end
    end,

    --- Called by the Aeon SACU Shield Amplifier aura when this ACU enters its field.
    --- The ACU's shields are enhancement-based (ShieldUEF / ShieldGeneratorFieldUEF),
    --- not a Defense.Shield entry, so the base spec is taken from the current
    --- enhancement instead of the blueprint. Applies a fixed multiplier to the shield
    --- max (a number for all shields, or a table with per-enhancement values).
    ---@param self UEL0001
    ---@param instigator Unit
    ---@param mult number|table # multiplier, or { ShieldUEF = n, ShieldGeneratorFieldUEF = n }
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
        local baseBp = self:HasEnhancement('ShieldGeneratorFieldUEF') and enhBp.ShieldGeneratorFieldUEF
            or (self:HasEnhancement('ShieldUEF') and enhBp.ShieldUEF or nil)
        if not baseBp then
            return
        end

        local resolvedMult = mult
        if type(mult) == 'table' then
            resolvedMult = self:HasEnhancement('ShieldGeneratorFieldUEF') and mult.ShieldGeneratorFieldUEF or mult.ShieldUEF or 1
        end
        local baseMax = baseBp.ShieldMaxHealth or 0
        local bonus = math.floor(baseMax * ((resolvedMult or 1) - 1) + 0.5)
        if bonus <= 0 then
            return
        end

        self:AeonShieldAmpApplyBonus(bonus, mult)
    end,

    --- Called when the ACU leaves the aura field (or the enhancement is removed):
    --- immediately subtracts the bonus from both current and max HP.
    ---@param self UEL0001
    AeonShieldAmpRemove = function(self)
        self:AeonShieldAmpRemoveBonus()
    end,

    --- Re-applies the shield amplifier boost after the ACU switches shield
    --- enhancements while standing inside the aura.
    ---@param self UEL0001
    RefreshShieldAmplifierBuff = function(self)
        local mult = self:AeonShieldAmpGetSourceMult() or self.AeonShieldAmpMult
        if mult and Buff.HasBuff(self, 'AeonShieldAmplifier') then
            self:AeonShieldAmpRemove()
            self:AeonShieldAmpApply(nil, mult)
        end
    end,
}

TypeClass = UEL0001
