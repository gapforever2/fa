local CDisintegratorLaserProjectile = import("/lua/cybranprojectiles.lua").CDisintegratorLaserProjectile

--- Cybran Disintegrator Laser
---@class CDFLaserDisintegrator03 : CDisintegratorLaserProjectile
CDFLaserDisintegrator03 = ClassProjectile(CDisintegratorLaserProjectile) {

    --- Applies the enhancement's EMP component as separate anti-shield area
    --- damage. The normal projectile damage remains direct and unchanged.
    ---@param self CDFLaserDisintegrator03
    ---@param instigator Unit
    ---@param DamageData WeaponDamageTable
    ---@param targetEntity Entity
    ---@param cachedPosition Vector
    DoDamage = function(self, instigator, DamageData, targetEntity, cachedPosition)
        local empDamage = DamageData.EMPShieldDamage
        if empDamage and empDamage > 0 then
            DamageArea(
                instigator,
                cachedPosition or self:GetPosition(),
                DamageData.EMPShieldDamageRadius or 3,
                empDamage,
                'FAF_AntiShield',
                false
            )
        end

        CDisintegratorLaserProjectile.DoDamage(self, instigator, DamageData, targetEntity, cachedPosition)
    end,

    ---@param self CDFLaserDisintegrator03
    ---@param army number
    ---@param EffectTable table
    ---@param EffectScale number
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local launcher = self.Launcher
        if launcher and (launcher:HasEnhancement('EMPCharge') or launcher:HasEnhancement('FocusConvertor')) then
            CreateLightParticle(self, -1, self.Army, 1.9, 9, 'ring_07', 'ramp_red_04')
            CreateEmitterAtEntity(self, self.Army,'/effects/emitters/cybran_empgrenade_hit_03_emit.bp')
        end
        CDisintegratorLaserProjectile.CreateImpactEffects(self, army, EffectTable, EffectScale)
    end,
}

TypeClass = CDFLaserDisintegrator03

