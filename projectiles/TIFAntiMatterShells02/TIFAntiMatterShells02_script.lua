local TArtilleryAntiMatterSmallProjectile = import("/lua/terranprojectiles.lua").TArtilleryAntiMatterSmallProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- UEF T3 Mobile Artillery Anti-Matter Shells : uel0304
---@class TIFAntiMatterShells02: TArtilleryAntiMatterSmallProjectile
TIFAntiMatterShells02 = ClassProjectile(TArtilleryAntiMatterSmallProjectile) {

    ---@param self TIFAntiMatterShells02
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        local px, _, pz = self:GetPositionXYZ()
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)

        TArtilleryAntiMatterSmallProjectile.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}
TypeClass = TIFAntiMatterShells02
