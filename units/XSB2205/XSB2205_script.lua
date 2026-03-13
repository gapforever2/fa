--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2205/XSB2205_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Seraphim Heavy Torpedo Launcher Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SANHeavyCavitationTorpedo = import("/lua/seraphimweapons.lua").SANHeavyCavitationTorpedo
local SDFAjelluAntiTorpedoDefense = import("/lua/seraphimweapons.lua").SDFAjelluAntiTorpedoDefense

XSB2205 = ClassUnit(SStructureUnit) {
    Weapons = {
        TorpedoTurrets = ClassWeapon(SANHeavyCavitationTorpedo) {},
        AjelluTorpedoDefense = ClassWeapon(SDFAjelluAntiTorpedoDefense) {},
    },
	
	OnStopBeingBuilt = function(self, builder, layer)
        SStructureUnit.OnStopBeingBuilt(self, builder, layer)

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
            self.Trash:Add(ForkThread(self.CreateT2SeraphimTorpedosWithDelay, armySelf, pos, spottedByArmy, fireState,self))
        else
            self:Destroy()
            local newT2SeraT = CreateUnitHPR('xsb2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2SeraT:SetHealth(newT2SeraT, health)
            newT2SeraT.SpottedByArmy = spottedByArmy
            newT2SeraT:SetFireState(fireState)
        end
    end,
	
	CreateT2SeraphimTorpedosWithDelay = function(self, armySelf, pos, spottedByArmy, fireState)
        WaitTicks(1)
        if not self.Dead then
            local health = self:GetHealth()
            local target = self:GetTargetEntity()
            self:Destroy()
            local newT2SeraT = CreateUnitHPR('xsb2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2SeraT:SetHealth(newT2SeraT, health)
            newT2SeraT.SpottedByArmy = spottedByArmy
            newT2SeraT:SetFireState(fireState)
            if target then
                IssueAttack({ newT2SeraT }, target)
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
            SStructureUnit.StartSinking(self, callback)
        end
    end,
}
TypeClass = XSB2205