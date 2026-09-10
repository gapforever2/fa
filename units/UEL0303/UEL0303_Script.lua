--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0303/UEL0303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Siege Assault Bot with Missile Pod Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TerranWeaponFile = import("/lua/terranweapons.lua")
local TWalkingLandUnit = import("/lua/terranunits.lua").TWalkingLandUnit
local TDFHeavyPlasmaCannonWeapon = TerranWeaponFile.TDFHeavyPlasmaCannonWeapon
local TSAMLauncher = TerranWeaponFile.TSAMLauncher
local utilities = import("/lua/utilities.lua")

local MissileTargetCategories = categories.LAND * categories.MOBILE

---@class UEL0303MissileLauncher : TSAMLauncher
UEL0303MissileLauncher = ClassWeapon(TSAMLauncher) {

    ---@param self UEL0303MissileLauncher
    ---@param rateOfFire number
    RenderClockThread = function(self, rateOfFire)
        if self.CurrentRackSalvoNumber ~= 1 then
            return
        end
        local unit = self.unit
        local bp = self.Blueprint
        local rackSpacing = rateOfFire
        local rackFireTime = (bp.MuzzleSalvoSize - 1) * (bp.MuzzleSalvoDelay or 0)
        local cycleTime = (self.NumRackBones - 1) * rackSpacing + rackFireTime + bp.RackSalvoReloadTime
        local clockTime = math.round(10 * cycleTime)
        local totalTime = clockTime
        while clockTime >= 0 and
            not self:BeenDestroyed() and
            not unit.Dead do
            unit:SetWorkProgress(1 - clockTime / totalTime)
            clockTime = clockTime - 1
            WaitSeconds(0.1)
        end
    end,

    ---@param self UEL0303MissileLauncher
    ---@param muzzle Bone
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = TSAMLauncher.CreateProjectileAtMuzzle(self, muzzle)
        if proj and not proj:BeenDestroyed() then
            local target = self:GetNextMissileTarget()
            if target then
                proj.OriginalTarget = target
                proj:SetNewTarget(target)
            end
        end
        return proj
    end,

    ---@param self UEL0303MissileLauncher
    ---@return Unit|nil
    GetNextMissileTarget = function(self)
        local unit = self.unit
        if not unit or unit.Dead then
            return nil
        end

        local bp = self.Blueprint
        local targets = utilities.GetTrueEnemyUnitsInSphere(unit, unit:GetPosition(), bp.MaxRadius, MissileTargetCategories)
        if not targets or table.empty(targets) then
            local current = self:GetCurrentTarget()
            if current and not current.Dead then
                return current
            end
            return nil
        end

        -- pick the target that was hit least recently so consecutive missiles spread over the group
        local lastShot = self.MissileTargetLastShot or {}
        local now = GetGameTick()
        local chosen
        local chosenLast
        for _, target in targets do
            if not target.Dead then
                local last = lastShot[target.EntityId] or -10000
                if not chosen or last < chosenLast then
                    chosen = target
                    chosenLast = last
                end
            end
        end

        if chosen then
            lastShot[chosen.EntityId] = now
            self.MissileTargetLastShot = lastShot
        end
        return chosen
    end,
}

---@class UEL0303 : TWalkingLandUnit
UEL0303 = ClassUnit(TWalkingLandUnit) {

    Weapons = {
        HeavyPlasma01 = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {
            DisabledFiringBones = {
                'Torso', 'ArmR_B02', 'Barrel_R', 'ArmR_B03', 'ArmR_B04',
                'ArmL_B02', 'Barrel_L', 'ArmL_B03', 'ArmL_B04',
            },
        },
        MissilePod = ClassWeapon(UEL0303MissileLauncher) {},
    },
}

TypeClass = UEL0303
