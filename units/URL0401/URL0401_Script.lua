-- File     :  /cdimage/units/URL0304/URL0304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Heavy Mobile Artillery Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CIFArtilleryWeapon = import("/lua/cybranweapons.lua").CIFArtilleryWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local Util = import("/lua/utilities.lua")
local barrelBones = { 'Turret_Barrel_F_B01', 'Turret_Barrel_E_B01', 'Turret_Barrel_D_B01', 'Turret_Barrel_C_B01',
    'Turret_Barrel_B_B01', 'Turret_Barrel_A_B01' }
local recoilBones = { 'Turret_Barrel_F_B02', 'Turret_Barrel_E_B02', 'Turret_Barrel_D_B02', 'Turret_Barrel_C_B02',
    'Turret_Barrel_B_B02', 'Turret_Barrel_A_B02' }
local muzzleBones = { 'Turret_Barrel_F_B03', 'Turret_Barrel_E_B03', 'Turret_Barrel_D_B03', 'Turret_Barrel_C_B03',
    'Turret_Barrel_B_B03', 'Turret_Barrel_A_B03' }

---@class URL0401 : CLandUnit
URL0401 = ClassUnit(CLandUnit) {

    Weapons = {
        ---@class URL0401_Gun01 : CIFArtilleryWeapon
        ---@field losttarget boolean
        ---@field initialaim boolean
        ---@field PitchRotators moho.RotateManipulator[] # Pitch rotators for the fake turret barrels
        ---@field currentbarrel number # Which barrel is currently aligned with the aim's yaw
        ---@field Goal number # Yaw goal of fake barrels
        ---@field restdirvector Vector
        ---@field dirvector Vector
        ---@field basedirvector Vector
        ---@field basediftorest number # "BaseDifToRest" angle in between Yaw aim bone and the resting fake barrel
        ---@field pitchdif number # "PitchDif" angle in between fake barrel pitch and aim barrel pitch
        ---@field Rotator moho.RotateManipulator # Yaw rotator for the `"Turret_Fake"` bone created every time the weapon fires after being packed
        ---@field unit URL0401
        Gun01 = ClassWeapon(CIFArtilleryWeapon) {
            ---@param self URL0401_Gun01
            OnCreate = function(self)
                CIFArtilleryWeapon.OnCreate(self)
                self.losttarget = false
                self.initialaim = true
                self.PitchRotators = {}
                self.restdirvector = Vector(0, 0, 0)
                self.dirvector = Vector(0, 0, 0)
                self.basedirvector = Vector(0, 0, 0)
                self.currentbarrel = 1
            end,

            ---@param self URL0401_Gun01
            OnLostTarget = function(self)
                CIFArtilleryWeapon.OnLostTarget(self)
                self.losttarget = true
            end,

            ---@param self URL0401_Gun01
            PlayFxWeaponPackSequence = function(self)
                if self.PitchRotators then
                    for k, v in barrelBones do
                        if self.PitchRotators[k] then
                            self.PitchRotators[k]:Destroy()
                            self.PitchRotators[k] = nil
                        end
                    end
                end
                self.losttarget = false
                self.initialaim = true
                CIFArtilleryWeapon.PlayFxWeaponPackSequence(self)
            end,

            ---@param self URL0401_Gun01
            LaunchEffects = function(self)
                local FxLaunch = EffectTemplate.CArtilleryFlash02
                for k, v in FxLaunch do
                    CreateEmitterAtEntity(self.unit, self.unit.Army, v)
                end
            end,

            --- Empty function because `CreateProjectileAtMuzzle` will wait when aiming the fake barrels, so the FX needs to be created in there for correct timing
            ---@param self URL0401_Gun01
            ---@param muzzle Bone
            PlayFxMuzzleSequence = function(self, muzzle)
            end,

            ---@param self URL0401_Gun01
            ---@param muzzle Bone
            CreateProjectileAtMuzzle = function(self, muzzle)
                -- set up the yaw and pitch rotators for the fake barrels since we just unpacked
                -- Creates the animation where the barrels are at their lowest pitch and look spread out
                if self.initialaim then
                    self.Rotator = CreateRotator(self.unit, 'Turret_Fake', 'y')
                    self.unit.Trash:Add(self.Rotator)

                    for k, v in barrelBones do
                        local tmprotator = CreateRotator(self.unit, v, 'x')
                        tmprotator:SetSpeed(30)
                        tmprotator:SetGoal(0)
                        self.PitchRotators[k] = tmprotator
                        self.unit.Trash:Add(self.PitchRotators[k])
                    end

                    -- fake barrel with the same yaw as the aim yaw
                    local barrel = self.currentbarrel
                    local basedirvector = self.basedirvector

                    self.Goal = 0
                    self.restdirvector[1], self.restdirvector[2], self.restdirvector[3] = self.unit:GetBoneDirection(barrelBones
                        [barrel])
                    basedirvector[1], basedirvector[2], basedirvector[3] = self.unit:GetBoneDirection('Turret_Aim')
                    self.basediftorest = Util.GetAngleInBetween(self.restdirvector, basedirvector)
                end

                -- since we got a new target, adjust the pitch of the fake barrels to match the aim barrel
                if self.losttarget or self.initialaim then
                    local dirvector = self.dirvector
                    dirvector[1], dirvector[2], dirvector[3] = self.unit:GetBoneDirection('Turret_Aim_Barrel')
                    local basedirvector = self.basedirvector
                    basedirvector[1], basedirvector[2], basedirvector[3] = self.unit:GetBoneDirection('Turret_Aim')

                    local basediftoaim = Util.GetAngleInBetween(dirvector, basedirvector)


                    self.pitchdif = self.basediftorest - basediftoaim

                    for k, v in barrelBones do
                        self.PitchRotators[k]:SetGoal(self.pitchdif)
                    end

                    WaitFor(self.PitchRotators[1])
                    -- Wait for aesthetics, to let the barrel rest at the final position a bit before firing
                    WaitTicks(3)

                    if self.losttarget then
                        self.losttarget = false
                    end

                    if self.initialaim then
                        self.initialaim = false
                    end
                end

                CIFArtilleryWeapon.PlayFxMuzzleSequence(self, muzzle)
                CIFArtilleryWeapon.CreateProjectileAtMuzzle(self, muzzle)
                self.Trash:Add(ForkThread(self.LaunchEffects, self))
                self.Trash:Add(ForkThread(self.RotateBarrels, self))
            end,

            ---@param self URL0401_Gun01
            RotateBarrels = function(self)
                if not self.losttarget then
                    self.Rotator:SetSpeed(320)
                    self.Goal = self.Goal + 60
                    if self.Goal >= 360 then
                        self.Goal = 0
                    end
                    WaitTicks(2)
                    self.Rotator:SetGoal(self.Goal)
                    self.currentbarrel = self.currentbarrel + 1
                    if self.currentbarrel > 6 then
                        self.currentbarrel = 1
                    end
                end
            end,
        },
    },
}

TypeClass = URL0401

-- Native flight extension. All dependencies are mounted game resources.
local PreviousURL0401 = URL0401
local PreviousGun = PreviousURL0401.Weapons.Gun01
local Rotor = import('/units/URL0401/ScathisRotor.lua')
local Flight = import('/units/URL0401/ScathisFlight.lua')

URL0401 = ClassUnit(PreviousURL0401) {
    SendNotifyMessage = function(self, message, ...)
        if message == 'completed' and (self.CopterFlightMorph or Flight.SpawningMorph) then
            return
        end
        return PreviousURL0401.SendNotifyMessage(self, message, unpack(arg))
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        local result = PreviousURL0401.OnStopBeingBuilt(self, builder, layer)
        if result == false then
            return false
        end
        self.CopterBuildCounted = true
        self.CopterChangingBit = true
        self:SetScriptBit('RULEUTC_SpecialToggle', false)
        self.CopterChangingBit = false
        LOG(string.format('[ScathisCopter] ground-ready id=%d landed=%s', self.EntityId, tostring(self.CopterLanded == true)))
        if self.CopterLanded then
            self:BeginCopterLandingCleanup()
        end
        return result
    end,

    SetCopterButton = function(self, state)
        self.CopterChangingBit = true
        self:SetScriptBit('RULEUTC_SpecialToggle', state)
        self.CopterChangingBit = false
    end,

    OnScriptBitSet = function(self, bit)
        if bit ~= 7 then
            return PreviousURL0401.OnScriptBitSet(self, bit)
        end
        if self.CopterChangingBit or self.CopterFlightMorph then
            return
        end
        if self.CopterTransition or self:GetFractionComplete() < 1 then
            self:SetCopterButton(false)
            return
        end
        self.CopterTransition = true
        self.CopterTakingOff = true
        self.CopterCancelTakeoff = false
        self.CopterLiftElevation = 0
        self.CopterSavedFireState = self:GetFireState()
        self:SuspendCopterWeapon()
        self:SetImmobile(true)
        self:SetBusy(true)
        self.CopterThread = self:ForkThread(self.CopterTakeoffThread)
    end,

    OnScriptBitClear = function(self, bit)
        if bit ~= 7 then
            return PreviousURL0401.OnScriptBitClear(self, bit)
        end
        if not self.CopterChangingBit and not self.CopterFlightMorph and self.CopterTakingOff then
            self.CopterCancelTakeoff = true
            LOG(string.format('[ScathisCopter] takeoff-cancel-request id=%d', self.EntityId))
        end
    end,

    SuspendCopterWeapon = function(self)
        local weapon = self:GetWeaponByLabel('Gun01')
        self:SetFireState(1)
        ChangeState(weapon, weapon.CopterDisabledState)
        weapon:SetWeaponEnabled(false)
        weapon:AimManipulatorSetEnabled(false)
        weapon:ResetTarget()
        weapon.WeaponCanFire = false
        if weapon.UnpackAnimator then
            self.CopterDeployFraction = weapon.UnpackAnimator:GetAnimationFraction()
            weapon.UnpackAnimator:Destroy()
            weapon.UnpackAnimator = nil
        end
        if weapon.Rotator then
            weapon.Rotator:Destroy()
            weapon.Rotator = nil
        end
        for index, rotator in weapon.PitchRotators or {} do
            rotator:Destroy()
        end
        weapon.PitchRotators = {}
        weapon.initialaim = true
        weapon.losttarget = false
        weapon.currentbarrel = 1
        weapon.Goal = 0
        weapon.WeaponPackState = 'Packed'
    end,

    RestoreCopterGround = function(self)
        if self.Dead or self:BeenDestroyed() then
            return
        end
        self:RevertElevation()
        self:SetCopterButton(false)
        self.CopterTakingOff = false
        self.CopterTransition = false
        self.CopterCancelTakeoff = false
        self.CopterLiftElevation = nil
        self:SetImmobile(false)
        self:SetBusy(false)
        self:SetFireState(self.CopterSavedFireState or 2)
        local weapon = self:GetWeaponByLabel('Gun01')
        weapon.WeaponCanFire = true
        ChangeState(weapon, weapon.IdleState)
        weapon:SetWeaponEnabled(true)
        weapon:AimManipulatorSetEnabled(true)
        self.CopterSavedFireState = nil
        LOG(string.format('[ScathisCopter] ground-restored id=%d', self.EntityId))
    end,

    CopterTakeoffThread = function(self)
        LOG(string.format('[ScathisCopter] takeoff-start id=%d', self.EntityId))
        local ready = Rotor.Start(self, false)
        if ready and not self.CopterCancelTakeoff then
            for tick = 1, 30 do
                WaitTicks(1)
                if self.Dead or self:BeenDestroyed() then
                    return
                end
                if self.CopterCancelTakeoff then
                    break
                end
                self.CopterLiftElevation = 18 * tick / 30
                self:SetElevation(self.CopterLiftElevation)
            end
        end
        if self.Dead or self:BeenDestroyed() then
            return
        end
        if ready and not self.CopterCancelTakeoff then
            local replacement, reason = Flight.Transform(self, 'sca0401', 'Air')
            if replacement then
                return
            end
            WARN('[ScathisCopter] takeoff-transform-failed ' .. tostring(reason))
        end
        -- Return from the current height even when cancelled partway through lift.
        local elevation = self.CopterLiftElevation or 0
        for tick = 29, 0, -1 do
            self:SetElevation(elevation * tick / 30)
            WaitTicks(1)
            if self.Dead or self:BeenDestroyed() then
                return
            end
        end
        if Rotor.Stop(self, false) then
            self:RestoreCopterGround()
        end
    end,

    -- Flight.Transform also calls this after creating an already finished unit.
    BeginCopterLandingCleanup = function(self)
        if self.CopterLandingCleanupStarted then
            return
        end
        self.CopterLandingCleanupStarted = true
        self.CopterTakingOff = true
        self.CopterTransition = true
        self:SuspendCopterWeapon()
        self:SetCopterButton(false)
        self:SetElevation(0)
        self:SetImmobile(true)
        self:SetBusy(true)
        Rotor.Start(self, true)
        self.CopterThread = self:ForkThread(function(unit)
            if Rotor.Stop(unit, false) then
                unit:RestoreCopterGround()
            end
        end)
    end,

    Weapons = {
        Gun01 = ClassWeapon(PreviousGun) {
            SetWeaponEnabled = function(self, enabled)
                PreviousGun.SetWeaponEnabled(self, enabled and not self.unit.CopterTakingOff)
            end,

            CreateProjectileAtMuzzle = function(self, muzzle)
                if not self.unit.CopterTakingOff then
                    return PreviousGun.CreateProjectileAtMuzzle(self, muzzle)
                end
            end,

            -- The stock helper forks independently and sleeps two ticks. Check
            -- ownership again after the sleep before touching the shared bone.
            RotateBarrels = function(self)
                local rotor = self.Rotator
                if self.unit.CopterTakingOff or self.losttarget or not rotor then
                    return
                end
                rotor:SetSpeed(320)
                self.Goal = math.mod(self.Goal + 60, 360)
                WaitTicks(2)
                if self.unit.CopterTakingOff or self.Rotator ~= rotor then
                    return
                end
                rotor:SetGoal(self.Goal)
                self.currentbarrel = math.mod(self.currentbarrel, 6) + 1
            end,

            CopterDisabledState = State {
                WeaponWantEnabled = false,
                WeaponAimWantEnabled = false,
                Main = function(self) end,
                OnFire = function(self) end,
                OnGotTarget = function(self) end,
                OnLostTarget = function(self) end,
            },
        },
    },
}

TypeClass = URL0401
