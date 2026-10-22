------------------------------------------------------------
-- File     :  /data/projectiles/TDFFragmentationGrenade01/TDFFragmentationGrenade01_script.lua
-- Author(s):  Matt Vainio
-- Summary  :  UEF Fragmentation Shells, DEL0204 : mongoose
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local TFragmentationGrenade = import("/lua/terranprojectiles.lua").TFragmentationGrenade
local TFragmentationGrenadeOnImpact = TFragmentationGrenade.OnImpact

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

--- UEF Fragmentation Grenade
---@class TDFFragmentationGrenade01: TFragmentationGrenade
TDFFragmentationGrenade01 = ClassProjectile(TFragmentationGrenade) {
    ---@param self TDFFragmentationGrenade01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)

        TFragmentationGrenadeOnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TDFFragmentationGrenade01
