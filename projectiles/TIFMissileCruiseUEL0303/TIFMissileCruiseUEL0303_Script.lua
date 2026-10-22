local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

local DebuffDurationTicks = 150
local DebuffSplashRadius = 6
local FirstStackCut = 0.10
local PerStackCut = 0.05
local MaxCut = 0.45
local MaxStacks = 10

local function EntropyMult(stacks)
    local cut = math.min(FirstStackCut + (stacks - 1) * PerStackCut, MaxCut)
    return 1 - cut
end

local function StartEntropyWatchdog(target)
    local Buff = import("/lua/sim/buff.lua")
    target.Trash:Add(ForkThread(function()
        while not target.Dead and target.UEL0303EntropyActive do
            WaitTicks(5)
            local expires = target.UEL0303EntropyExpires
            local now = GetGameTick()
            if expires and table.getn(expires) > 0 then
                for i = table.getn(expires), 1, -1 do
                    if expires[i] <= now then
                        table.remove(expires, i)
                    end
                end
                if table.getn(expires) == 0 then
                    target.UEL0303EntropyActive = nil
                    target.UEL0303EntropyMult = nil
                    if not target.Dead then
                        Buff.RecalculateRegenWithEntropy(target)
                    end
                    return
                end
                local mult = EntropyMult(table.getn(expires))
                if target.UEL0303EntropyMult ~= mult then
                    target.UEL0303EntropyMult = mult
                    if not target.Dead then
                        Buff.RecalculateRegenWithEntropy(target)
                    end
                end
            end
        end
    end))
end

local function ApplyEntropyDebuff(target)
    local Buff = import("/lua/sim/buff.lua")
    if not target.Dead then
        if not target.UEL0303EntropyActive then
            target.UEL0303EntropyActive = true
            target.UEL0303EntropyExpires = {}
            StartEntropyWatchdog(target)
        end
        local expires = target.UEL0303EntropyExpires
        if table.getn(expires) < MaxStacks then
            table.insert(expires, GetGameTick() + DebuffDurationTicks)
        else
            expires[1] = GetGameTick() + DebuffDurationTicks
        end
        target.UEL0303EntropyMult = EntropyMult(table.getn(expires))
        Buff.RecalculateRegenWithEntropy(target)
    end
end

TIFMissileCruiseUEL0303 = ClassProjectile(TMissileCruiseProjectile) {

    FxTrails = { '/effects/emitters/missile_sam_munition_trail_01_emit.bp' },
    FxTrailOffset = -0.5,
    FxTrailScale = 1,
    TrailDelay = 1,

    FxImpactUnit = EffectTemplate.TUEL0303CruiseMissileHit,
    FxImpactProp = EffectTemplate.TUEL0303CruiseMissileHit,
    FxImpactLand = EffectTemplate.TUEL0303CruiseMissileHit,
    FxImpactWater = EffectTemplate.TUEL0303CruiseMissileHit,
    FxImpactNone = EffectTemplate.TUEL0303CruiseMissileHit,
    FxImpactAirUnit = EffectTemplate.TUEL0303CruiseMissileHit,
    FxImpactShield = EffectTemplate.FlashSml01,
    FxImpactProjectile = EffectTemplate.TMissileHit02,

    FxAirUnitHitScale = 0.5,
    FxLandHitScale = 0.5,
    FxNoneHitScale = 0.5,
    FxPropHitScale = 0.5,
    FxProjectileHitScale = 0.5,
    FxProjectileUnderWaterHitScale = 0.5,
    FxShieldHitScale = 0.5,
    FxUnderWaterHitScale = 0.5,
    FxUnitHitScale = 0.5,
    FxWaterHitScale = 0.5,
    FxOnKilledScale = 0.5,

    MovementThread = function(self, skipLaunchSequence)
        LOG('UEL0303_MISSILE: MovementThread RUNNING')
        if not skipLaunchSequence then
            WaitTicks(1)
            local target = self.Target
            if target and not target.Dead then
                local pos = self:GetPosition()
                local tpos = target:GetPosition()
                local dx = tpos[1] - pos[1]
                local dy = tpos[2] - pos[2]
                local dz = tpos[3] - pos[3]
                local horiz = math.sqrt(dx * dx + dz * dz)
                local aimY = dy + horiz * 0.45
                local len = math.sqrt(dx * dx + aimY * aimY + dz * dz)
                if len > 0 then
                    self:SetVelocity(dx / len * 20, aimY / len * 20, dz / len * 20)
                end
            end
            self:TrackTarget(false)
            WaitTicks(4)
            self:SetTurnRate(360)
            self:TrackTarget(true)
            WaitTicks(8)
        end
    end,

    OnImpact = function(self, targetType, targetEntity)
        LOG('UEL0303_MISSILE: IMPACT type=' .. tostring(targetType))
        local Buff = import("/lua/sim/buff.lua")
        local utilities = import("/lua/utilities.lua")

        if targetEntity and not targetEntity.Dead and EntityCategoryContains(categories.LAND, targetEntity) then
            ApplyEntropyDebuff(targetEntity)
        end

        local launcher = self.Launcher
        if launcher then
            local targets = utilities.GetTrueEnemyUnitsInSphere(launcher, self:GetPosition(), DebuffSplashRadius, categories.LAND)
            if targets then
                for _, target in targets do
                    ApplyEntropyDebuff(target)
                end
            end
        end

        TMissileCruiseProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFMissileCruiseUEL0303
