-- File     :  /cdimage/units/XSL0001/XSL0001_script.lua
-- Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
-- Summary  :  Seraphim Commander Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------

---@alias SeraphimACUEnhancementBuffType
---| "ACUUPGRADEDMG"
---| "COMMANDERAURA"
---| "COMMANDERAURAFORSELF"
---| "ACUBUILDRATE"

---@alias SeraphimACUEnhancementBuffName      # BuffType
---| "SeraphimACUDamageStabilization"         # ACUUPGRADEDMG
---| "SeraphimACUDamageStabilizationAdv"      # ACUUPGRADEDMG
---| "SeraphimACUAdvancedRegenAura"           # COMMANDERAURA
---| "SeraphimACUAdvancedRegenAuraSelfBuff"   # COMMANDERAURAFORSELF
---| "SeraphimACURegenAura"                   # COMMANDERAURA
---| "SeraphimACURegenAuraSelfBuff"           # COMMANDERAURAFORSELF
---| "SeraphimACUT2BuildRate"                 # ACUBUILDRATE
---| "SeraphimACUT3BuildRate"                 # ACUBUILDRATE


local ACUUnit = import("/lua/defaultunits.lua").ACUUnit
local Buff = import("/lua/sim/buff.lua")
local SWeapons = import("/lua/seraphimweapons.lua")
local SDFChronotronCannonWeapon = SWeapons.SDFChronotronCannonWeapon
local SDFChronotronOverChargeCannonWeapon = SWeapons.SDFChronotronCannonOverChargeWeapon
local ACUDeathWeapon = import("/lua/sim/defaultweapons.lua").ACUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher
local AIUtils = import("/lua/ai/aiutilities.lua")
local RegenAuraVisualId = 'SeraphimRegenAura'
local RegenAuraEnhancement = 'RegenAuraSeraphim'
local AdvancedRegenAuraEnhancement = 'AdvancedRegenAuraSeraphim'

---@class XSL0001 : ACUUnit
---@field ShieldEffectsBag moho.IEffect[] # stores the regen aura effects (level 1 has 1 effect, level 2 has 2 effects)
XSL0001 = ClassUnit(ACUUnit) {
    -- One visual entry follows both levels of the same gameplay aura.  The basic
    -- enhancement displays its current blueprint radius; the advanced enhancement
    -- replaces it with its own upgraded blueprint radius.
    AuraVisuals = {
        [RegenAuraVisualId] = {
            IsActive = function(self)
                return self.RegenAuraPowered == true
            end,
            Color = 'ffd000ff',
            Thickness = 0.12,
            GetRadius = function(self)
                local enhancements = self.Blueprint.Enhancements
                if self.RegenAuraEnhancement == AdvancedRegenAuraEnhancement then
                    local advanced = enhancements[AdvancedRegenAuraEnhancement]
                    return advanced and advanced.Radius or 0
                end

                if self.RegenAuraEnhancement == RegenAuraEnhancement then
                    local basic = enhancements[RegenAuraEnhancement]
                    return basic and basic.Radius or 0
                end

                return 0
            end,
        },
    },

    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        ChronotronCannon = ClassWeapon(SDFChronotronCannonWeapon) {},
        Missile = ClassWeapon(SIFLaanseTacticalMissileLauncher) {
            OnCreate = function(self)
                SIFLaanseTacticalMissileLauncher.OnCreate(self)
                self:SetWeaponEnabled(false)
            end,
        },
        OverCharge = ClassWeapon(SDFChronotronOverChargeCannonWeapon) {},
        AutoOverCharge = ClassWeapon(SDFChronotronOverChargeCannonWeapon) {},
    },

    ---@param self XSL0001
    __init = function(self)
        ACUUnit.__init(self, 'ChronotronCannon')
    end,

    --- Keeps the indirect-fire overlay hidden until the missile enhancement exists.
    ---@param self XSL0001
    ---@param enabled boolean
    SetMissileOverlayRange = function(self, enabled)
        local missile = self:GetWeaponByLabel('Missile')
        local missileBlueprint = missile:GetBlueprint()
        missile:ChangeMinRadius(enabled and (missileBlueprint.MinRadius or 0) or 0)
        missile:ChangeMaxRadius(enabled and (missileBlueprint.MaxRadius or 0) or 0)
    end,

    ---@param self XSL0001
    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetupBuildBones()
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        self:AddBuildRestriction(categories.SERAPHIM *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    ---@param self XSL0001
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('ChronotronCannon', true)
        self:SetMissileOverlayRange(false)
        self.Trash:Add(ForkThread(self.GiveInitialResources, self))
        self.ShieldEffectsBag = {}
    end,

    ---@param self XSL0001
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones,
            self.BuildEffectsBag)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ---@return Unit[]
    GetUnitsToBuff = function(self, bp)
        -- Build the faction-neutral union directly. This preserves the original
        -- target set while avoiding comma-expression parsing differences.
        local unitCat = categories.BUILTBYTIER3FACTORY
            + categories.BUILTBYQUANTUMGATE
            + categories.NEEDMOBILEBUILD
            + categories.TRANSPORTATION
            + categories.FIELDENGINEER
        local brain = self:GetAIBrain()
        local all = brain:GetUnitsAroundPoint(unitCat, self:GetPosition(), bp.Radius, 'Ally')
        local units = {}

        for _, u in all do
            if not u.Dead and not u:IsBeingBuilt() then
                table.insert(units, u)
            end
        end

        return units
    end,

    RefreshRegenAuraTarget = function(self, unit)
        if unit.Dead then
            return
        end
        local sources = unit.SeraphimACURegenAuraSources
        local desired
        if sources then
            for source, buffName in pairs(sources) do
                if source and not source.Dead and source.RegenAuraPowered then
                    if buffName == 'SeraphimACUAdvancedRegenAura' then
                        desired = buffName
                    elseif not desired then
                        desired = buffName
                    end
                else
                    sources[source] = nil
                end
            end
        end

        for _, buffName in {'SeraphimACURegenAura', 'SeraphimACUAdvancedRegenAura'} do
            if buffName ~= desired and Buffs[buffName] and Buff.HasBuff(unit, buffName) then
                Buff.RemoveBuff(unit, buffName, true)
            end
        end
        if desired and not Buff.HasBuff(unit, desired) then
            Buff.ApplyBuff(unit, desired, self)
        end
        unit.SeraphimACURegenAuraActiveBuff = desired
        unit:RequestRefreshUI()
    end,

    RegisterRegenAuraTarget = function(self, unit)
        unit.SeraphimACURegenAuraSources = unit.SeraphimACURegenAuraSources or {}
        unit.SeraphimACURegenAuraSources[self] = self.RegenAuraBuffName
        self:RefreshRegenAuraTarget(unit)
    end,

    UnregisterRegenAuraTarget = function(self, unit)
        local sources = unit.SeraphimACURegenAuraSources
        if sources then
            sources[self] = nil
        end
        self:RefreshRegenAuraTarget(unit)
    end,

    RemoveAllRegenAuraTargets = function(self)
        local active = self.RegenAuraActiveTargets
        if not active then
            return
        end
        local targets = {}
        for unit in pairs(active) do
            table.insert(targets, unit)
        end
        for _, unit in targets do
            if not unit.Dead then
                self:UnregisterRegenAuraTarget(unit)
            end
            active[unit] = nil
        end
        self.RegenAuraActiveTargets = nil
    end,

    ---@param self XSL0001
    ---@param regenAuraType Enhancement
    RegenBuffThread = function(self)
        local bp = self.Blueprint.Enhancements[self.RegenAuraEnhancement]
        local active = self.RegenAuraActiveTargets or {}
        self.RegenAuraActiveTargets = active
        while not self.Dead and self.RegenAuraPowered do
            local present = {}
            local units = self:GetUnitsToBuff(bp)
            for _, unit in units do
                present[unit] = true
                if not active[unit] then
                    active[unit] = true
                    self:RegisterRegenAuraTarget(unit)
                end
            end
            for unit in pairs(active) do
                if not present[unit] or unit.Dead then
                    if not unit.Dead then
                        self:UnregisterRegenAuraTarget(unit)
                    end
                    active[unit] = nil
                end
            end
            WaitTicks(5)
        end
    end,

    SetRegenAuraPowered = function(self, powered)
        if powered == self.RegenAuraPowered then
            return
        end
        self.RegenAuraPowered = powered
        if powered then
            local selfBuff = self.RegenAuraEnhancement == AdvancedRegenAuraEnhancement
                and 'SeraphimACUAdvancedRegenAuraSelfBuff'
                or 'SeraphimACURegenAuraSelfBuff'
            Buff.ApplyBuff(self, selfBuff)
            self.ShieldEffectsBag = self.ShieldEffectsBag or {}
            table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 'XSL0001', self.Army,
                '/effects/emitters/seraphim_regenerative_aura_01_emit.bp'))
            self.RegenThreadHandle = self:ForkThread(self.RegenBuffThread)
        else
            if self.RegenThreadHandle then
                KillThread(self.RegenThreadHandle)
                self.RegenThreadHandle = nil
            end
            self:RemoveAllRegenAuraTargets()
            for _, selfBuff in {'SeraphimACURegenAuraSelfBuff', 'SeraphimACUAdvancedRegenAuraSelfBuff'} do
                if Buffs[selfBuff] and Buff.HasBuff(self, selfBuff) then
                    Buff.RemoveBuff(self, selfBuff, true)
                end
            end
            if self.ShieldEffectsBag then
                for _, effect in self.ShieldEffectsBag do
                    effect:Destroy()
                end
                self.ShieldEffectsBag = {}
            end
        end
        self:UpdateAuraVisualSync()
    end,

    RegenAuraPowerThread = function(self)
        while not self.Dead and self.RegenAuraEnabled do
            self:SetRegenAuraPowered(self:GetResourceConsumed() == 1)
            WaitTicks(5)
        end
        self.RegenAuraPowerThreadHandle = nil
    end,

    SetRegenAuraEnabled = function(self, enabled)
        if enabled and not self.RegenAuraEnhancement then
            return
        end
        self.RegenAuraEnabled = enabled
        if enabled then
            local bp = self.Blueprint.Enhancements[self.RegenAuraEnhancement]
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.RegenAuraPowerThreadHandle then
                self.RegenAuraPowerThreadHandle = self:ForkThread(self.RegenAuraPowerThread)
            end
        else
            if self.RegenAuraPowerThreadHandle then
                KillThread(self.RegenAuraPowerThreadHandle)
                self.RegenAuraPowerThreadHandle = nil
            end
            self:SetRegenAuraPowered(false)
            self:SetEnergyMaintenanceConsumptionOverride(0)
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    --====================================================================================================================================
    -- Enhancements

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRegenAuraSeraphim = function(self, bp)
        local type
        if not Buffs['SeraphimACURegenAura'] then
            local buff_bp = {
                Name = 'SeraphimACURegenAura',
                DisplayName = 'SeraphimACURegenAura',
                BuffType = 'COMMANDERAURA_RegenAura',
                Stacks = 'REPLACE',
                Duration = -1,
                Effects = { '/effects/emitters/seraphim_regenerative_aura_02_emit.bp' },
                Affects = {
                    Regen = {
                        Add = 0,
                        Mult = bp.RegenPerSecond,
                        Floor = bp.RegenFloor,
                        BPCeilings = {
                            TECH1 = bp.RegenCeilingT1,
                            TECH2 = bp.RegenCeilingT2,
                            TECH3 = bp.RegenCeilingT3,
                            EXPERIMENTAL = bp.RegenCeilingT4,
                            SUBCOMMANDER = bp.RegenCeilingSCU,
                        },
                    },
                },
            }
            buff_bp.Affects.MaxHealth = {
                Add = 0,
                Mult = bp.MaxHealthFactor,
                DoNotFill = true,
            }
            BuffBlueprint(buff_bp)
        end

        if not Buffs['SeraphimACURegenAuraSelfBuff'] then -- AURA SELF BUFF
            BuffBlueprint {
                Name = 'SeraphimACURegenAuraSelfBuff',
                DisplayName = 'SeraphimACURegenAuraSelfBuff',
                BuffType = 'COMMANDERAURAFORSELF',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.ACUAddHealth,
                        Mult = 1,
                    },
                    Regen = {
                        Add = bp.NewRegenRate,
                        Mult = 1,
                    },
                },
            }
        end

        self:SetRegenAuraEnabled(false)
        self.RegenAuraEnhancement = RegenAuraEnhancement
        self.RegenAuraBuffName = 'SeraphimACURegenAura'
        self:AddToggleCap('RULEUTC_SpecialToggle')
        self:SetRegenAuraEnabled(true)
        self:SetScriptBit('RULEUTC_SpecialToggle', false)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRegenAuraSeraphimRemove = function(self, bp)
        self:SetRegenAuraEnabled(false)
        self.RegenAuraEnhancement = nil
        self.RegenAuraBuffName = nil
        self:RemoveToggleCap('RULEUTC_SpecialToggle')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedRegenAuraSeraphim = function(self, bp)
        local type
        if not Buffs['SeraphimACUAdvancedRegenAura'] then
            local buff_bp = {
                Name = 'SeraphimACUAdvancedRegenAura',
                DisplayName = 'SeraphimACUAdvancedRegenAura',
                BuffType = 'COMMANDERAURA_AdvancedRegenAura',
                Stacks = 'REPLACE',
                Duration = -1,
                Effects = { '/effects/emitters/seraphim_regenerative_aura_02_emit.bp' },
                Affects = {
                    Regen = {
                        Add = 0,
                        Mult = bp.RegenPerSecond,
                        Floor = bp.RegenFloor,
                        BPCeilings = {
                            TECH1 = bp.RegenCeilingT1,
                            TECH2 = bp.RegenCeilingT2,
                            TECH3 = bp.RegenCeilingT3,
                            EXPERIMENTAL = bp.RegenCeilingT4,
                            SUBCOMMANDER = bp.RegenCeilingSCU,
                        },
                    },
                },
            }
            buff_bp.Affects.MaxHealth = {
                Add = 0,
                Mult = bp.MaxHealthFactor,
                DoNotFill = true,
            }
            BuffBlueprint(buff_bp)
        end

        if not Buffs['SeraphimACUAdvancedRegenAuraSelfBuff'] then -- AURA SELF BUFF
            BuffBlueprint {
                Name = 'SeraphimACUAdvancedRegenAuraSelfBuff',
                DisplayName = 'SeraphimACUAdvancedRegenAuraSelfBuff',
                BuffType = 'COMMANDERAURAFORSELF',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.ACUAddHealth,
                        Mult = 1,
                    },
                    Regen = {
                        Add = bp.NewRegenRate,
                        Mult = 1,
                    },
                },
            }
        end

        self:SetRegenAuraEnabled(false)
        self.RegenAuraEnhancement = AdvancedRegenAuraEnhancement
        self.RegenAuraBuffName = 'SeraphimACUAdvancedRegenAura'
        self:AddToggleCap('RULEUTC_SpecialToggle')
        self:SetRegenAuraEnabled(true)
        self:SetScriptBit('RULEUTC_SpecialToggle', false)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedRegenAuraSeraphimRemove = function(self, bp)
        self:SetRegenAuraEnabled(false)
        self.RegenAuraEnhancement = nil
        self.RegenAuraBuffName = nil
        self:RemoveToggleCap('RULEUTC_SpecialToggle')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationSeraphim = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        if not bp then return end
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationSeraphimRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationAdvancedSeraphim = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        if not bp then return end
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationAdvancedSeraphimRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationSeraphim = function(self, bp)
        if not Buffs['SeraphimACUDamageStabilization'] then
            BuffBlueprint {
                Name = 'SeraphimACUDamageStabilization',
                DisplayName = 'SeraphimACUDamageStabilization',
                BuffType = 'ACUUPGRADEDMG',
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
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilization')
        end
        Buff.ApplyBuff(self, 'SeraphimACUDamageStabilization')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationSeraphimRemove = function(self, bp)
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilization')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationAdvancedSeraphim = function(self, bp)
        if not Buffs['SeraphimACUDamageStabilizationAdv'] then
            BuffBlueprint {
                Name = 'SeraphimACUDamageStabilizationAdv',
                DisplayName = 'SeraphimACUDamageStabilizationAdv',
                BuffType = 'ACUUPGRADEDMG',
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
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilizationAdv') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilizationAdv')
        end
        Buff.ApplyBuff(self, 'SeraphimACUDamageStabilizationAdv')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationAdvancedSeraphimRemove = function(self, bp)
        -- since there's no way to just remove an upgrade anymore, if we're remove adv, were removing both
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilizationAdv') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilizationAdv')
        end
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilization')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporterSeraphim = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporterSeraphimRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementMissileSeraphim = function(self, bp)
        self:AddCommandCap('RULEUCC_Tactical')
        self:AddCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', true)
        self:SetMissileOverlayRange(true)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementMissileSeraphimRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Tactical')
        self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', false)
        self:SetMissileOverlayRange(false)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEngineeringT2Seraphim = function(self, bp)
        if not bp then return end
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)
        if not Buffs['SeraphimACUT2BuildRate'] then
            BuffBlueprint {
                Name = 'SeraphimACUT2BuildRate',
                DisplayName = 'SeraphimACUT2BuildRate',
                BuffType = 'ACUBUILDRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    BuildRate = {
                        Add = bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
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
        Buff.ApplyBuff(self, 'SeraphimACUT2BuildRate')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEngineeringT2SeraphimRemove = function(self, bp)
        local bp = self.Blueprint.Economy.BuildRate
        if not bp then return end
        self:RestoreBuildRestrictions()
        self:AddBuildRestriction(categories.SERAPHIM *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        if Buff.HasBuff(self, 'SeraphimACUT2BuildRate') then
            Buff.RemoveBuff(self, 'SeraphimACUT2BuildRate')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3EngineeringSeraphim = function(self, bp)
        if not bp then return end
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)
        if not Buffs['SeraphimACUT3BuildRate'] then
            BuffBlueprint {
                Name = 'SeraphimACUT3BuildRate',
                DisplayName = 'SeraphimCUT3BuildRate',
                BuffType = 'ACUBUILDRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    BuildRate = {
                        Add = bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
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
        Buff.ApplyBuff(self, 'SeraphimACUT3BuildRate')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3EngineeringSeraphimRemove = function(self, bp)
        local bp = self.Blueprint.Economy.BuildRate
        if not bp then return end
        self:RestoreBuildRestrictions()
        if Buff.HasBuff(self, 'SeraphimACUT3BuildRate') then
            Buff.RemoveBuff(self, 'SeraphimACUT3BuildRate')
        end
        self:AddBuildRestriction(categories.SERAPHIM *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementBlastAttackSeraphim = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadius or 5)
        wep:AddDamageMod(bp.AdditionalDamage)

        if not Buffs['SeraphimACUBlastAttackSpeed'] then
            BuffBlueprint {
                Name = 'SeraphimACUBlastAttackSpeed',
                DisplayName = 'SeraphimACUBlastAttackSpeed',
                BuffType = 'ACUBLASTATTACKSPEED',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MoveMult = {
                        Mult = (bp.NewMaxSpeed or 1.9) / (self.Blueprint.Physics.MaxSpeed or 1.7),
                    },
                },
            }
        end
        if not Buff.HasBuff(self, 'SeraphimACUBlastAttackSpeed') then
            Buff.ApplyBuff(self, 'SeraphimACUBlastAttackSpeed')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementBlastAttackSeraphimRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        wep:AddDamageRadiusMod(-self.Blueprint.Enhancements['BlastAttackSeraphim'].NewDamageRadius) -- unlimited AOE bug fix by brute51 [117]
        wep:AddDamageMod(-self.Blueprint.Enhancements['BlastAttackSeraphim'].AdditionalDamage)
        if Buff.HasBuff(self, 'SeraphimACUBlastAttackSpeed') then
            Buff.RemoveBuff(self, 'SeraphimACUBlastAttackSpeed')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRateOfFireSeraphim = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRateOfFireSeraphimRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        local bpDisrupt = self.Blueprint.Weapon[1].RateOfFire
        wep:ChangeRateOfFire(bpDisrupt or 1)
        bpDisrupt = self.Blueprint.Weapon[1].MaxRadius
        wep:ChangeMaxRadius(bpDisrupt or 22)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bpDisrupt or 22)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bpDisrupt or 22)
    end,

    OnScriptBitSet = function(self, bit)
        if bit == 7 then
            self:SetRegenAuraEnabled(false)
        else
            ACUUnit.OnScriptBitSet(self, bit)
        end
    end,

    OnScriptBitClear = function(self, bit)
        if bit == 7 then
            self:SetRegenAuraEnabled(true)
        else
            ACUUnit.OnScriptBitClear(self, bit)
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self:SetRegenAuraEnabled(false)
        ACUUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnDestroy = function(self)
        self:SetRegenAuraEnabled(false)
        ACUUnit.OnDestroy(self)
    end,

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)
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

TypeClass = XSL0001
