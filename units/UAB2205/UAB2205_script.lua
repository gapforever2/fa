--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2205/UAB2205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Aeon Heavy Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AANChronoTorpedoWeapon = import("/lua/aeonweapons.lua").AANChronoTorpedoWeapon

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add

---@class UAB2205 : AStructureUnit
UAB2205 = ClassUnit(AStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(AANChronoTorpedoWeapon) {},
    },
	OnStopBeingBuilt = function(self, builder, layer)
        AStructureUnit.OnStopBeingBuilt(self, builder, layer)

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
            self.Trash:Add(ForkThread(self.CreateT2AeonTorpedosWithDelay, armySelf, pos, spottedByArmy, fireState,self))
        else
            self:Destroy()
            local newT2AeonT = CreateUnitHPR('uab2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2AeonT:SetHealth(newT2AeonT, health)
            newT2AeonT.SpottedByArmy = spottedByArmy
            newT2AeonT:SetFireState(fireState)
        end
    end,
	
	CreateT2AeonTorpedosWithDelay = function(self, armySelf, pos, spottedByArmy, fireState)
        WaitTicks(1)
        if not self.Dead then
            local health = self:GetHealth()
            local target = self:GetTargetEntity()
            self:Destroy()
            local newT2AeonT = CreateUnitHPR('uab2206', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newT2AeonT:SetHealth(newT2AeonT, health)
            newT2AeonT.SpottedByArmy = spottedByArmy
            newT2AeonT:SetFireState(fireState)
            if target then
                IssueAttack({ newT2AeonT }, target)
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
            AStructureUnit.StartSinking(self, callback)
        end
    end,

	OnCreate = function(self)
		AStructureUnit.OnCreate(self)
        local trash = self.Trash

        self.DomeEntity = import("/lua/sim/entity.lua").Entity({Owner = self,})
        self.DomeEntity:AttachBoneTo( -1, self, 'UAB2205' )
        self.DomeEntity:SetMesh('/effects/Entities/UAB2205_Dome/UAB2205_Dome_mesh')
        self.DomeEntity:SetDrawScale(0.45)
        self.DomeEntity:SetVizToAllies('Intel')
        self.DomeEntity:SetVizToNeutrals('Intel')
        self.DomeEntity:SetVizToEnemies('Intel')         
        TrashBagAdd(trash,self.DomeEntity)
	end,    
}

TypeClass = UAB2205