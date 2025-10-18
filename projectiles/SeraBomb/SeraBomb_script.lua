--******************************************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local SUallCavitationTorpedo = import("/lua/seraphimprojectiles.lua").SUallCavitationTorpedo
local SUallCavitationTorpedoOnCreate = SUallCavitationTorpedo.OnCreate
local SUallCavitationTorpedoOnEnterWater = SUallCavitationTorpedo.OnEnterWater
local SUallCavitationTorpedoOnImpact = SUallCavitationTorpedo.OnImpact

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- Depth Charge Script
---@class SeraBomb : SUallCavitationTorpedo
---@field HasImpacted boolean
SeraBomb = ClassProjectile(SUallCavitationTorpedo) {
    CountdownLengthInTicks = 101,

    ---@param self SeraBomb
    OnCreate = function(self)
        SUallCavitationTorpedoOnCreate(self)
        self.HasImpacted = false
        self.Trash:Add(ForkThread(self.CountdownExplosion, self))
    end,

    ---@param self SeraBomb
    CountdownExplosion = function(self)
        WaitTicks(self.CountdownLengthInTicks)
        if not self.HasImpacted then
            self:OnImpact('Underwater', nil)
        end
    end,

    ---@param self SeraBomb
    OnEnterWater = function(self)
        SUallCavitationTorpedoOnEnterWater(self)
        self:TrackTarget(true)
        self:SetMaxSpeed(20)
        self:SetVelocity(0)
        self:SetAcceleration(5)
        self:SetTurnRate(180)
    end,

    ---@param self SeraBomb
    OnLostTarget = function(self)
        self:SetMaxSpeed(2)
        self:SetAcceleration(-0.6)
        self.Trash:Add(ForkThread(self.CountdownMovement, self))
    end,

    ---@param self SeraBomb
    CountdownMovement = function(self)
        WaitTicks(31)
        self:SetMaxSpeed(0)
        self:SetAcceleration(0)
        self:SetVelocity(0)
    end,

    ---@param self SeraBomb
    OnImpact = function(self, TargetType, TargetEntity)
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)
		marker:UpdateIntel(self.Army, 5, 'WaterVision', true)
        SUallCavitationTorpedoOnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = SeraBomb
