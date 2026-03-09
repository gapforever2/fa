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

local utilities = import("/lua/utilities.lua")

---@class UEB2205 : TStructureUnit
UEB2206 = ClassUnit(TStructureUnit) {
    Weapons = {
         Torpedo = ClassWeapon(TANTorpedoAngler) {
       },
    },
	
	OnStopBeingBuilt = function(self, builder, layer)
        TStructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:StartSinkingFromBuild()
		
        ChangeState(self, self.IdleState)
    end,
	
	StartSinkingFromBuild = function(self)
        local position = self:GetPosition()
        if GetSurfaceHeight(position[1], position[3]) > position[2] then return end
        local bone = 0
        local proj = self:CreateProjectileAtBone('/projectiles/Sinker/Sinker_proj.bp', bone)
        self.sinkProjectile = proj

        proj:SetLocalAngularVelocity(0, 0, 0)
        proj:Start(0, self, bone)
        proj:SetBallisticAcceleration(-0.3)
        self.Trash:Add(proj)
		self.Depthwatcher = self.Trash:Add(ForkThread(self.DepthWatcher,self))
    end,
	
	DepthWatcher = function(self)
        self.sinkingFromBuild = true

        local sinkFor = 2.5
        while self.sinkProjectile and sinkFor > 0 do
            WaitTicks(1)
            sinkFor = sinkFor - 0.1
        end

        local bottom = true
        if not self.Dead then
            if self.sinkProjectile then
                bottom = false
                self.sinkProjectile:Destroy()
                self.sinkProjectile = nil
            end

            self:SetPosition(self:GetPosition(), true)
        end

        self.sinkingFromBuild = false
        self.Bottom = bottom
    end,
	
	DeathThread = function(self, overkillRatio, instigator)
        local bp = self.Blueprint
        local army = self.Army

        self:DestroyAllDamageEffects()
        self:PlaySound(bp.Audio.Destroyed)

        local isNaval = true
        local shallSink = true

        WaitSeconds(utilities.GetRandomFloat(self.DestructionExplosionWaitDelayMin, self.DestructionExplosionWaitDelayMax))

        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(overkillRatio)
        end

        if self.ShowUnitDestructionDebris and overkillRatio then
            self:CreateUnitDestructionDebris(true, true, overkillRatio > 2)
        end

        self.DisallowCollisions = true
        self.Trash:Add(ForkThread(self.SinkDestructionEffects,self))
        self.overkillRatio = overkillRatio
        local this = self
        self:StartSinking(
            function()
                this:DestroyUnit(overkillRatio)
            end
        )
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

TypeClass = UEB2206