--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2205/UEB2205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Heavy Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler

---@class UEB2205 : TStructureUnit
UEB2205 = ClassUnit(TStructureUnit) {
    Weapons = {
         Torpedo = ClassWeapon(TANTorpedoAngler) {
       },
    },
	OnStopBeingBuilt = function(self, builder, layer)
        TStructureUnit.OnStopBeingBuilt(self, builder, layer)

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
            self.Trash:Add(ForkThread(self.CreateT2UEFTorpedosWithDelay, armySelf, pos, spottedByArmy, fireState,self))
        else
            self:Destroy()
            local newT2UEFT = CreateUnitHPR('ueb2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2UEFT:SetHealth(newT2UEFT, health)
            newT2UEFT.SpottedByArmy = spottedByArmy
            newT2UEFT:SetFireState(fireState)
        end
    end,
	
	CreateT2UEFTorpedosWithDelay = function(self, armySelf, pos, spottedByArmy, fireState)
        WaitTicks(1)
        if not self.Dead then
            local health = self:GetHealth()
            local target = self:GetTargetEntity()
            self:Destroy()
            local newT2UEFT = CreateUnitHPR('ueb2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2UEFT:SetHealth(newT2UEFT, health)
            newT2UEFT.SpottedByArmy = spottedByArmy
            newT2UEFT:SetFireState(fireState)
            if target then
                IssueAttack({ newT2UEFT }, target)
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
            TStructureUnit.StartSinking(self, callback)
        end
    end,
}

TypeClass = UEB2205