--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2205/URB2205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Heavy Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon

local utilities = import("/lua/utilities.lua")

---@class URB2205 : CStructureUnit
URB2205 = ClassUnit(CStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
    },
	
	OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local pos = self:GetPosition()
        local armySelf = self.Army
        local health = self:GetHealth()
        local armies = ListArmies()
        local spottedByArmy = {}
        local fireState = self:GetFireState()

        for _, army in armies do
            if not IsAlly(armySelf, army) then
                local blip = self:GetBlip(army)

                if blip and blip:IsSeenEver(army) then
                    table.insert(spottedByArmy, ScenarioInfo.ArmySetup[army].ArmyIndex)
                end
            end
        end

        if not self:IsIdleState() then
            self.Trash:Add(ForkThread(self.CreateT2CybranTorpedosWithDelay, armySelf, pos, spottedByArmy, fireState,self))
        else
            self:Destroy()
            local newT2CybT = CreateUnitHPR('urb2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2CybT:SetHealth(newT2CybT, health)
            newT2CybT.SpottedByArmy = spottedByArmy
            newT2CybT:SetFireState(fireState)
        end
    end,
	
	CreateT2CybranTorpedosWithDelay = function(self, armySelf, pos, spottedByArmy, fireState)
        WaitTicks(1)
        if not self.Dead then
            local health = self:GetHealth()
            local target = self:GetTargetEntity()
            self:Destroy()
            local newT2CybT = CreateUnitHPR('urb2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2CybT:SetHealth(newT2CybT, health)
            newT2CybT.SpottedByArmy = spottedByArmy
            newT2CybT:SetFireState(fireState)
            if target then
                IssueAttack({ newT2CybT }, target)
            end
        end
    end,
	
	StartSinking = function(self, callback)
        if not self.sinkingFromBuild and self.Bottom then
            self.Trash:Add(ForkThread(callback,self))
        elseif self.sinkingFromBuild then
            self.sinkProjectile.callback = callback
            return
        else
            CStructureUnit.StartSinking(self, callback)
        end
    end,
}

TypeClass = URB2205