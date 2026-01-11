-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0401/UEL0401_script.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos
-- Summary  :  UEF Mobile Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TMobileFactoryUnit = import("/lua/terranunits.lua").TMobileFactoryUnit
local WeaponsFile = import("/lua/terranweapons.lua")
local TDFGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon
local TAALinkedRailgun = WeaponsFile.TAALinkedRailgun
local TANTorpedoAngler = WeaponsFile.TANTorpedoAngler
local TAAFlakArtilleryCannon = import("/lua/terranweapons.lua").TAAFlakArtilleryCannon
local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")

local TShieldLandUnit = import("/lua/terranunits.lua").TShieldLandUnit
local ExternalFactoryComponent = import("/lua/defaultcomponents.lua").ExternalFactoryComponent
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent
local DefaultExplosions = import("/lua/defaultexplosions.lua")

local IsDestroyed = IsDestroyed

local Buff = import("/lua/sim/buff.lua")

---@class UEL0401 : TMobileFactoryUnit, ExternalFactoryComponent
---@field UnitBeingBuilt Unit | nil
---@field AttachmentSliderManip moho.SlideManipulator
---@field PrepareToBuildManipulator moho.AnimationManipulator
UEL0401 = ClassUnit(TMobileFactoryUnit, ExternalFactoryComponent, TShieldLandUnit, ShieldEffectsComponent) {
    PrepareToBuildAnimRate = 5,
    BuildAttachBone = 'Build_Attachpoint',
    FactoryAttachBone = 'ExternalFactoryPoint',
    RollOffBones = { 'Arm_Right03_Build_Emitter', 'Arm_Left03_Build_Emitter', },

	ShieldEffectsBone = 'Spinner',
    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_mobile_01_emit.bp',
        '/effects/emitters/terran_shield_generator_mobile_02_emit.bp',
    },

    ExplosionBones = {
        'Turret_Right01',
        '1Turret_Right02',
        'Turret_Left01',
        '1Turret_Left02',
        'Wheel_Right01',
        'Wheel_Right02',
        'Wheel_Left01',
        '1Wheel_Left02',
        'AA_Turret_Left',
        'AA_Turret_Right',
        'Flak_Turret_Left',
        'Flak_Turret_Right',
        'Attachpoint_field01',
        'Attachpoint_field02',
        'Attachpoint_field03',
        'Bay_Cover',
    },
    Weapons = {
        RightTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        RightTurret02 = ClassWeapon(TDFGaussCannonWeapon) {},
        LeftTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        LeftTurret02 = ClassWeapon(TDFGaussCannonWeapon) {},
        RiotgunRight01 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RiotgunRight02 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RiotgunRight03 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RiotgunLeft01 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RiotgunLeft02 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RiotgunLeft03 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RightAAGun = ClassWeapon(TAALinkedRailgun) {},
        LeftAAGun = ClassWeapon(TAALinkedRailgun) {},
        Torpedo = ClassWeapon(TANTorpedoAngler) {},
        RighFlakGun = ClassWeapon(TAAFlakArtilleryCannon) {},
        LeftFlakGun = ClassWeapon(TAAFlakArtilleryCannon) {},
    },

    ---@param self UEL0401
    OnCreate = function(self)
        TMobileFactoryUnit.OnCreate(self)
		TShieldLandUnit.OnCreate(self)
		ShieldEffectsComponent.OnCreate(self)
        local blueprint = self.Blueprint
        self.BuildEffectBones = blueprint.General.BuildBones.BuildEffectBones
        if blueprint.General.BuildBones then
            self:SetupBuildBones()
        end
        if blueprint.Display.AnimationBuild then
            self.BuildingOpenAnim = blueprint.Display.AnimationBuild
        end
    end,

    ---@param self UEL0401
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        TMobileFactoryUnit.OnStopBeingBuilt(self, builder, layer)
		TShieldLandUnit.OnStopBeingBuilt(self, builder, layer)
        ExternalFactoryComponent.OnStopBeingBuilt(self, builder, layer)
        self.PrepareToBuildManipulator = CreateAnimator(self)
        self.PrepareToBuildManipulator:PlayAnim(self:GetBlueprint().Display.AnimationBuild, false):SetRate(0)
        self.ReleaseEffectsBag = {}
        self.AttachmentSliderManip = CreateSlider(self, self.BuildAttachBone)
        ChangeState(self, self.IdleState)
		ForkThread(self.STGamemode, self)
    end,

    ---@param self UEL0401
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        TMobileFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
    end,

    ---@param self UEL0401
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        TMobileFactoryUnit.OnStopBuild(self, unitBeingBuilt)
        -- Unbuilt units can be in `OnStopBuild` when a `BuildMobile` order gets cancelled.
        if not unitBeingBuilt.Dead and not unitBeingBuilt.isFinishedUnit then
            unitBeingBuilt:Destroy()
        end
        self.BuildingUnit = false
    end,

    ---@param self UEL0401
    OnFailedToBuild = function(self)
        TMobileFactoryUnit.OnFailedToBuild(self)
        self.BuildingUnit = false
        ChangeState(self, self.IdleState)
    end,

    ---@param self UEL0401
    ---@param new Layer
    ---@param old Layer
    OnLayerChange = function(self, new, old)
        TMobileFactoryUnit.OnLayerChange(self, new, old)
		TShieldLandUnit.OnLayerChange(self, new, old)
        ExternalFactoryComponent.OnLayerChange(self, new, old)
        if self.ExternalFactory then
            if new == 'Land' then
                self.ExternalFactory:RestoreBuildRestrictions()
                self.ExternalFactory:RequestRefreshUI()
            elseif new == 'Seabed' then
                self.ExternalFactory:AddBuildRestriction(categories.ALLUNITS)
                self.ExternalFactory:RequestRefreshUI()
            end
        end
    end,

    ---Fixes a bug with external factories where ordering "deploy" will detach the unit under construction
    ---@param self UEL0401
    ---@param attachBone string
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        if not self.Dead and not unit.Dead and unit:GetFractionComplete() < 1.0 then
            unit:AttachBoneTo(-2, self, attachBone)
        else
            TMobileFactoryUnit.OnTransportDetach(self, attachBone, unit)
        end
    end,
	
	
	STGamemode = function(self)
		local GM = true
		while not self:IsDead() do
			if not self:IsDead() and self:GetScriptBit('RULEUTC_WeaponToggle') == true and GM == true then
				self:RemoveCommandCap('RULEUCC_Move')
				self:RemoveCommandCap('RULEUCC_Patrol')
				GM = false
				local wp1 = self:GetWeaponByLabel('RightTurret01')
				wp1:ChangeMaxRadius(70)
				local wp2 = self:GetWeaponByLabel('RightTurret02')
				wp2:ChangeMaxRadius(70)
				local wp3 = self:GetWeaponByLabel('LeftTurret01')
				wp3:ChangeMaxRadius(70)
				local wp4 = self:GetWeaponByLabel('LeftTurret02')
				wp4:ChangeMaxRadius(70)
				local DWP1 = self:GetWeaponByLabel('RightTurret01')
				DWP1:AddDamageMod(70)
				DWP1:ChangeRateOfFire(10/16.66)
				DWP1:AddDamageRadiusMod(2)
				local DWP2 = self:GetWeaponByLabel('RightTurret02')
				DWP2:AddDamageMod(70)
				DWP2:ChangeRateOfFire(10/16.66)
				DWP2:AddDamageRadiusMod(2)
				local DWP3 = self:GetWeaponByLabel('LeftTurret01')
				DWP3:AddDamageMod(70)
				DWP3:ChangeRateOfFire(10/16.66)
				DWP3:AddDamageRadiusMod(2)
				local DWP4 = self:GetWeaponByLabel('LeftTurret02')
				DWP4:AddDamageMod(70)
				DWP4:ChangeRateOfFire(10/16.66)
				DWP4:AddDamageRadiusMod(2)
				self:SetSpeedMult(0.01)
				if not Buffs['STHP'] then
                BuffBlueprint {
                    Name = 'STHP',
                    DisplayName = 'STHP',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = 36500,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = 39,
                            Mult = 1.0,
                        },
                    },
                }
            end
			Buff.ApplyBuff(self, 'STHP')
			elseif not self:IsDead() and self:GetScriptBit('RULEUTC_WeaponToggle') == false and GM == false then
				self:AddCommandCap('RULEUCC_Move')
				self:AddCommandCap('RULEUCC_Patrol')
				self:SetSpeedMult(1)
				if Buff.HasBuff(self, 'STHP') then
					Buff.RemoveBuff(self, 'STHP')
				end
				GM = true
				local wp1 = self:GetWeaponByLabel('RightTurret01')
				wp1:ChangeMaxRadius(80)
				local wp2 = self:GetWeaponByLabel('RightTurret02')
				wp2:ChangeMaxRadius(80)
				local wp3 = self:GetWeaponByLabel('LeftTurret01')
				wp3:ChangeMaxRadius(80)
				local wp4 = self:GetWeaponByLabel('LeftTurret02')
				wp4:ChangeMaxRadius(80)
				local DWP1 = self:GetWeaponByLabel('RightTurret01')
				DWP1:AddDamageMod(-70)
				DWP1:ChangeRateOfFire(10/10.52)
				DWP1:AddDamageRadiusMod(-2)
				local DWP2 = self:GetWeaponByLabel('RightTurret02')
				DWP2:AddDamageMod(-70)
				DWP2:ChangeRateOfFire(10/10.52)
				DWP2:AddDamageRadiusMod(-2)
				local DWP3 = self:GetWeaponByLabel('LeftTurret01')
				DWP3:AddDamageMod(-70)
				DWP3:ChangeRateOfFire(10/10.52)
				DWP3:AddDamageRadiusMod(-2)
				local DWP4 = self:GetWeaponByLabel('LeftTurret02')
				DWP4:AddDamageMod(-70)
				DWP4:ChangeRateOfFire(10/10.52)
				DWP4:AddDamageRadiusMod(-2)
			end
			WaitTicks(8)
		end
	end,

    IdleState = State {
        ---@param self UEL0401
        ---@param unitBeingBuilt Unit
        ---@param order string
        OnStartBuild = function(self, unitBeingBuilt, order)
            TMobileFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
            self.UnitBeingBuilt = unitBeingBuilt
            self.UnitBuildOrder = order
            self.BuildingUnit = true
            self.PrepareToBuildManipulator:SetRate(self.PrepareToBuildAnimRate)
            ChangeState(self, self.BuildingState)
        end,

        ---@param self UEL0401
        Main = function(self)
            self.PrepareToBuildManipulator:SetRate(-self.PrepareToBuildAnimRate)
            self:DetachAll(self.BuildAttachBone)
            self.OnIdle(self)
        end,
    },

    BuildingState = State {
        ---@param self UEL0401
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            if unitBuilding then
                self.PrepareToBuildManipulator:SetRate(self.PrepareToBuildAnimRate)
                local bone = self.BuildAttachBone
                self:DetachAll(bone)
                if not self.UnitBeingBuilt.Dead then
                    unitBuilding:AttachBoneTo(-2, self, bone)
                    local unitHeight = unitBuilding:GetBlueprint().SizeY
                    self.AttachmentSliderManip:SetGoal(0, unitHeight, 0)
                    self.AttachmentSliderManip:SetSpeed(-1)
                    unitBuilding:HideBone(0, true)
                end
                WaitFor(self.PrepareToBuildManipulator)
                unitBuilding:ShowBone(0, true)
            end
        end,

        ---@param self UEL0401
        ---@param unitBeingBuilt Unit
        OnStopBuild = function(self, unitBeingBuilt)
            TMobileFactoryUnit.OnStopBuild(self, unitBeingBuilt)
            -- Unbuilt units can be in `OnStopBuild` when a `BuildMobile` order gets cancelled.
            if unitBeingBuilt:GetFractionComplete() < 1 then
                unitBeingBuilt:Destroy()
                ChangeState(self, self.IdleState)
                return
            end

            ChangeState(self, self.RollingOffState)
        end,
    },

    RollingOffState = State {
        ---@param self UEL0401
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            if not unitBuilding.Dead then
                unitBuilding:ShowBone(0, true)
            end
            WaitFor(self.PrepareToBuildManipulator)
            WaitFor(self.AttachmentSliderManip)

            self:CreateRollOffEffects()
            self.AttachmentSliderManip:SetSpeed(10)
            self.AttachmentSliderManip:SetGoal(0, 0, 17)
            WaitFor(self.AttachmentSliderManip)

            self.AttachmentSliderManip:SetGoal(0, -3, 17)
            WaitFor(self.AttachmentSliderManip)

            if not unitBuilding.Dead then
                unitBuilding:DetachFrom(true)
            end

            self:DestroyRollOffEffects()
            ChangeState(self, self.IdleState)
        end,
    },

    ---@param self UEL0401
    CreateRollOffEffects = function(self)
        local army = self.Army
        local unitB = self.UnitBeingBuilt
        for k, v in self.RollOffBones do
            local fx = AttachBeamEntityToEntity(self, v, unitB, -1, army, EffectTemplate.TTransportBeam01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)

            fx = AttachBeamEntityToEntity(unitB, -1, self, v, army, EffectTemplate.TTransportBeam02)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)

            fx = CreateEmitterAtBone(self, v, army, EffectTemplate.TTransportGlow01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
        end
    end,

    ---@param self UEL0401
    DestroyRollOffEffects = function(self)
        for k, v in self.ReleaseEffectsBag do
            v:Destroy()
        end
        self.ReleaseEffectsBag = {}
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        TMobileFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
        ExternalFactoryComponent.OnKilled(self, instigator, type, overkillRatio)
    end,

    ---@param self UEL0401
    ---@param overkillRatio number
    ---@param instigator Unit
    DeathThread = function(self, overkillRatio, instigator)

        self:PlayUnitSound('Destroyed')

        -- transform data
        local explosionBones = {}
        local explosionBoneCount = table.getn(self.ExplosionBones)

        -- Since this is a thread, it is delayed by 1 tick so the instigator may be destroyed
        if not IsDestroyed(instigator) then
            -- if there is an instigator, favor exploding bits that are near the instigator
            local ix, iy, iz = instigator:GetPositionXYZ()
            for k, bone in self.ExplosionBones do
                local bonePosition = self:GetPosition(bone)
                local dx = bonePosition[1] - ix
                local dy = bonePosition[2] - iy
                local dz = bonePosition[3] - iz
                local distance = dx * dx + dy * dy + dz * dz
                explosionBones[k] = {
                    Distance = distance,
                    BoneName = bone,
                    Position = bonePosition
                }
            end

            -- sort the order
            table.sort(explosionBones, function(e1, e2) return e1.Distance < e2.Distance end)
        else
            -- if there is no instigator (self destruct, for example) then take a random direction
            for k, bone in self.ExplosionBones do
                local bonePosition = self:GetPosition(bone)
                explosionBones[k] = {
                    Distance = 0,
                    BoneName = bone,
                    Position = bonePosition
                }
            end

            -- shuffle the order
            for k = explosionBoneCount, 1, -1 do
                local j = math.floor(Random(1, k));
                local value = explosionBones[j];
                explosionBones[j] = explosionBones[k];
                explosionBones[k] = value;
            end
        end

        -- create a few random sparks
        CreateAttachedEmitter(self, -1, self.Army, '/effects/emitters/explosion_fire_sparks_02_emit.bp')

        -- create explosions that gradually move away from the instigator
        self:PlayUnitSound('Destroyed')
        for k = 1, 2 do
            local index = Random(1, 3)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 2, 1, "TreeFire", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2,
                { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        WaitTicks(1)
        self:PlayUnitSound('Destroyed')
        for k = 1, 3 do
            local index = Random(2, 5)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 3, 1, "TreeFire", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2,
                { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        WaitTicks(1)
        self:PlayUnitSound('Destroyed')
        DefaultExplosions.CreateScalableUnitExplosion(self)
        for k = 1, 3 do
            local index = Random(3, 7)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 4, 1, "TreeForce", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2,
                { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        WaitTicks(1)
        self:PlayUnitSound('Destroyed')
        DefaultExplosions.CreateScalableUnitExplosion(self)
        for k = 1, 5 do
            local index = Random(4, explosionBoneCount)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 5, 1, "TreeForce", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2,
                { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        self:DestroyUnit(overkillRatio)
    end,
	
	OnShieldEnabled = function(self)
		TShieldLandUnit.OnShieldEnabled(self)
        TMobileFactoryUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)

        KillThread(self.DestroyManipulatorsThread)
        if not self.RotatorManipulator then
            self.RotatorManipulator = CreateRotator(self, 'Spinner', 'y')
            self.Trash:Add(self.RotatorManipulator)
        end
        self.RotatorManipulator:SetAccel(5)
        self.RotatorManipulator:SetTargetSpeed(30)
        if not self.AnimationManipulator then
            local myBlueprint = self:GetBlueprint()
            self.AnimationManipulator = CreateAnimator(self)
            self.AnimationManipulator:PlayAnim(myBlueprint.Display.AnimationOpen)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:SetRate(1)
    end,
	
	OnShieldDisabled = function(self)
		TShieldLandUnit.OnShieldDisabled(self)
        TMobileFactoryUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
        KillThread(self.DestroyManipulatorsThread)
        self.DestroyManipulatorsThread = self:ForkThread(self.DestroyManipulators)
    end,
	
	DestroyManipulators = function(self)
        if self.RotatorManipulator then
            self.RotatorManipulator:SetAccel(10)
            self.RotatorManipulator:SetTargetSpeed(0)
            -- Unless it goes smoothly back to its original position,
            -- it will snap there when the manipulator is destroyed.
            -- So for now, we'll just keep it on.
            --WaitFor( self.RotatorManipulator )
            --self.RotatorManipulator:Destroy()
            --self.RotatorManipulator = nil
        end
        if self.AnimationManipulator then
            self.AnimationManipulator:SetRate(-1)
            WaitFor(self.AnimationManipulator)
            self.AnimationManipulator:Destroy()
            self.AnimationManipulator = nil
        end
    end,
	
}

TypeClass = UEL0401
