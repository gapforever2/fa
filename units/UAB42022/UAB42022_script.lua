----****************************************************************************
----**
----**  File     :  /cdimage/units/UAB42022/UAB42022_script.lua
----**  Author(s):  David Tomandl
----**
----**  Summary  :  Aeon Shield Generator Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local AShieldStructureUnit = import("/lua/aeonunits.lua").AShieldStructureUnit


-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add


---@class UAB42022 : AShieldStructureUnit
UAB42022 = ClassUnit(AShieldStructureUnit) {

    ShieldEffectsScale = 0.75,
	ShieldEffectsBone='Effect',
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_t2_01_emit.bp',
        '/effects/emitters/aeon_shield_generator_t2_02_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_03_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_04_emit.bp',
    },

    OnCreate = function(self)
        AShieldStructureUnit.OnCreate(self)
        local bag = TrashBag()
        self.ShieldEffectsBag = bag
        self.Trash:Add(bag)
		self.ShieldEnabled = false
    end,

    OnShieldEnabled = function(self)
        AShieldStructureUnit.OnShieldEnabled(self)
        local bag = self.ShieldEffectsBag
        local bone = self.ShieldEffectsBone
        local scale = self.ShieldEffectsScale
        local army = self.Army
        bag:Destroy()
        for _, effect in self.ShieldEffects do
            bag:Add(CreateAttachedEmitter(self, bone, army, effect):ScaleEmitter(scale)):OffsetEmitter(0,-2.2,0)
        end

        local trash = self.Trash

        local orbManip1 = self.OrbManip1
        if not orbManip1 then
            orbManip1 = CreateRotator(self, 'Orb', '-x', nil, 0, 45, 45)
            TrashBagAdd(trash, orbManip1)
            self.OrbManip1 = orbManip1
        else
			if self:IsUnitState('Upgrading') then
			orbManip1:SetSpinDown(true)
            orbManip1:SetTargetSpeed(9999)
			else
			orbManip1:SetSpinDown(false)
            orbManip1:SetTargetSpeed(45)
			end
        end

        local orbManip2 = self.OrbManip2 
        if not orbManip2 then
            orbManip2 = CreateRotator(self, 'Orb', 'z', nil, 0, 45, 45)
            TrashBagAdd(trash, orbManip2)
            self.OrbManip2 = orbManip2
        else
			if self:IsUnitState('Upgrading') then
			orbManip2:SetSpinDown(true)
            orbManip2:SetTargetSpeed(9999)
			else
			orbManip2:SetSpinDown(false)
            orbManip2:SetTargetSpeed(45)
			end
        end
		self.ShieldEnabled = true
    end,

    OnShieldDisabled = function(self)
        AShieldStructureUnit.OnShieldDisabled(self)
        self.ShieldEffectsBag:Destroy()

        if self.OrbManip1 then
            self.OrbManip1:SetSpinDown(true)
        end

        if self.OrbManip2 then
            self.OrbManip2:SetSpinDown(true)
        end
		self.ShieldEnabled = false
    end,
	
	OnStartBuild = function(self, unitBeingBuilt, order)
        AShieldStructureUnit.OnStartBuild(self, unitBeingBuilt, order)
		self.MercuryPool = import("/lua/EffectUtilitiesAeon.lua").CreateMercuryPoolOnBone(self, self.Army, 'Pool', 1.5,1.5,1.5, 0.1)
		self.MercuryPool2 = import("/lua/EffectUtilitiesAeon.lua").CreateMercuryPoolOnBone(self, self.Army, 'Ramp2', 0.65,0.65,0.65, 0.1)
        if self.OrbManip1 then
            self.OrbManip1:SetSpinDown(true)
			self.OrbManip1:SetTargetSpeed(9999)
        end

        if self.OrbManip2 then
            self.OrbManip2:SetSpinDown(true)
			self.OrbManip2:SetTargetSpeed(9999)
        end
    end,
	
	OnStopBuild = function(self, unitBeingBuilt, order)
        AShieldStructureUnit.OnStopBuild(self, unitBeingBuilt, order)
		self.MercuryPool:Destroy()
		self.MercuryPool2:Destroy()
		if self.ShieldEnabled == true then
		if self.OrbManip1 then
            self.OrbManip1:SetSpinDown(false)
			self.OrbManip1:SetTargetSpeed(45)
        end

        if self.OrbManip2 then
            self.OrbManip2:SetSpinDown(false)
			self.OrbManip2:SetTargetSpeed(45)
        end
		else
		
		end
    end,
}

TypeClass = UAB42022