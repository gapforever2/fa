--****************************************************************************
--**
--**  File     :  /cdimage/units/DRL0204/DRL0204_script.lua
--**  Author(s):  Dru Staltman, Eric Williamson, Gordon Duclos
--**
--**  Summary  :  Cybran Rocket Bot Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CDFRocketIridiumWeapon02 = import("/lua/cybranweapons.lua").CDFRocketIridiumWeapon02
local DefaultProjectileWeapon = import("/lua/sim/weapons/DefaultProjectileWeapon.lua").DefaultProjectileWeapon

---@class DRL0204 : CWalkingLandUnit
DRL0204 = ClassUnit(import("/lua/cybranunits.lua").CWalkingLandUnit) {
    Weapons = {
        RocketBackpack = ClassWeapon(CDFRocketIridiumWeapon02) {
            RackSalvoFiringState = State(DefaultProjectileWeapon.RackSalvoFiringState) {
                Main = function(self)
                    local unit = self.unit
                    unit.Trash:Add(ForkThread(function()
                        WaitSeconds(0.35)
                        if IsDestroyed(unit) or IsDestroyed(self) or self.HaltFireOrdered then return end
                        local radonium = unit:GetWeaponByLabel('RadoniumBackpack')
                        if radonium then
                            ChangeState(radonium, radonium.RackSalvoFiringState)
                        end
                    end))
                    DefaultProjectileWeapon.RackSalvoFiringState.Main(self)
                end,
            },

            OnGotTarget = function(self)
                CDFRocketIridiumWeapon02.OnGotTarget(self)
                local radonium = self.unit:GetWeaponByLabel('RadoniumBackpack')
                local target = self:GetCurrentTarget()
                if target and radonium then
                    radonium:SetTargetEntity(target)
                end
            end,
        },
        RadoniumBackpack = ClassWeapon(CDFRocketIridiumWeapon02) {
            RackSalvoFireReadyState = State(DefaultProjectileWeapon.RackSalvoFireReadyState) {
                OnFire = function(self)
                end,
            },
        },
    },
}
TypeClass = DRL0204
