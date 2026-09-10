------------------------------------------------------------
--  File     :  /data/projectiles/CDFRocketRadonium01/CDFRocketRadonium01_Script.lua
--  Author(s):  Matt Vainio
--  Summary  :  Cybran Radonium Rocket Tubes, DRL0204 : cyb T2 range bot (hoplite)
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local CIridiumRocketProjectile = import("/lua/cybranprojectiles.lua").CIridiumRocketProjectile

--- Cybran Radonium Rocket Tubes, DRL0204 : cyb T2 range bot (hoplite)
---@class CDFRocketRadonium01 : CIridiumRocketProjectile
CDFRocketRadonium01 = ClassProjectile(CIridiumRocketProjectile) {
    DoDamage = function(self, instigator, DamageData, targetEntity, cachedPosition)
        DamageArea(
            instigator,
            cachedPosition or self:GetPosition(),
            DamageData.DamageRadius or 2,
            DamageData.DamageToShields or 200,
            'FAF_AntiShield',
            DamageData.DamageFriendly
        )
    end,
}
TypeClass = CDFRocketRadonium01
