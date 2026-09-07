--**********************************************************************************
--** Entropy Field weapon (Aeon SACU enhancement "Поле энтропии" / Entropy Field).
--**
--** Based on the Aeon Chrono Dampener: it reuses the same expanding-wave firing and
--** targeting. Instead of slowing enemies, its wave:
--**   * reduces the health regeneration of nearby land units by 80% (percentage, so it
--**     also cuts nano-repair and regen auras), for 15s, and
--**   * deals 2500 damage to enemy shields within a fixed radius (no health damage).
--** Visual is the Chrono Dampener's, recoloured to acid-swamp green. Does not affect the caster.
--**********************************************************************************

local ADFChronoDampener = import("/lua/sim/weapons/aeon/adfchronodampener.lua").ADFChronoDampener
local Utilities = import("/lua/utilities.lua")
local Buff = import("/lua/sim/buff.lua")
local GetClosestVisualBone = import("/lua/sim/aura/visualbones.lua").GetClosestVisualBone

local ENTROPY_REGEN_MULT = 0.2     -- regen multiplier while debuffed (0.2 = 80% reduction)
local ENTROPY_REGEN_DURATION = 150 -- debuff duration in ticks (15 s)

--- Reduces a target's TOTAL health regeneration by 80% for 15 s. The reduction is applied
--- as a multiplier on the final regen value (computed from all the unit's sources: blueprint
--- base, veterancy, upgrades, auras), so it correctly cuts 80% off whatever the unit actually
--- regenerates. The Buff.lua Regen affect keeps the multiplier applied on every recalc, so it
--- stays correct even while regen auras / nano keep reapplying. Re-applying refreshes the timer.
---@param target Unit
local function ApplyEntropyRegenDebuff(target)
    target.EntropyRegenExpireTick = GetGameTick() + ENTROPY_REGEN_DURATION

    if target.EntropyRegenActive then
        return
    end
    target.EntropyRegenActive = true
    target.EntropyRegenMult = ENTROPY_REGEN_MULT
    Buff.RecalculateRegenWithEntropy(target)

    target.Trash:Add(ForkThread(function()
        while not target.Dead and GetGameTick() < target.EntropyRegenExpireTick do
            WaitTicks(5)
        end
        target.EntropyRegenMult = nil
        target.EntropyRegenActive = nil
        if not target.Dead then
            Buff.RecalculateRegenWithEntropy(target)
        end
    end))
end

local function DestroyEntropyTargetFx(target)
    if target.EntropyTargetFx then
        for _, emit in target.EntropyTargetFx do
            if emit then
                emit:Destroy()
            end
        end
        target.EntropyTargetFx = nil
    end
end

local function StartEntropyTargetFxCleanup(target)
    if target.EntropyTargetFxThread then
        return
    end

    target.EntropyTargetFxThread = ForkThread(function()
        while not target.Dead and GetGameTick() < (target.EntropyRegenExpireTick or 0) do
            WaitTicks(5)
        end

        if not target.Dead then
            DestroyEntropyTargetFx(target)
        else
            target.EntropyTargetFx = nil
        end
        target.EntropyTargetFxThread = nil
    end)
    target.Trash:Add(target.EntropyTargetFxThread)
end

local function CreateEntropyTargetFx(weapon, target, flashScale, initial)
    if not initial then
        return
    end

    for _, effect in weapon.FxUnitStunFlash do
        local emit = CreateEmitterOnEntity(target, target.Army, effect)
        emit:ScaleEmitter(flashScale * math.max(target.Blueprint.SizeX, target.Blueprint.SizeZ))
    end

    -- Keep exactly one cyclic green marker attached to a real model bone. Picking
    -- the bone nearest the physical centre avoids distant muzzle/attachment bones,
    -- while CreateAttachedEmitter makes the marker follow moving and animated units.
    DestroyEntropyTargetFx(target)
    target.EntropyTargetFx = {}

    local effect = weapon.FxUnitStun[1]
    if effect then
        local bone = GetClosestVisualBone(target)
        local emit = CreateAttachedEmitter(target, bone, target.Army, effect)
        emit:ScaleEmitter(0.5)

        local lods = target.Blueprint.Display.Mesh.LODs
        if lods then
            emit:SetEmitterParam("LODCUTOFF", lods[table.getn(lods)].LODCutoff)
        end

        target.Trash:Add(emit)
        table.insert(target.EntropyTargetFx, emit)
    end

    StartEntropyTargetFxCleanup(target)
end

---@class ADFEntropyField : ADFChronoDampener
ADFEntropyField = Class(ADFChronoDampener) {
    -- Chrono Dampener wave cadence with a two-layer rotating Lotus and particles.
    -- The original Chrono scale puts the particle edge outside the live aura
    -- ring at the upgraded radius. This calibrated base scale keeps both edges
    -- aligned while the parent class still scales it with ChangeMaxRadius().
    FxMuzzleFlashScale = 0.44,
    FxMuzzleFlash = {
        '/effects/emitters/aeon_entropy_lotus_01_emit.bp',
        '/effects/emitters/aeon_entropy_lotus_02_emit.bp',
        '/effects/emitters/aeon_entropy_lotus_03_emit.bp',
        '/effects/emitters/aeon_entropy_lotus_04_emit.bp',
        '/effects/emitters/aeon_entropy_lotus_05_emit.bp',
    },
    FxUnitStun = {
        '/effects/emitters/aeon_regen_dampener_charge_01_emit.bp',
    },

    --- Uses the Chrono Dampener's expanding-wave timing while applying the Entropy
    --- debuff and one shield hit per wave. Visual target flashes remain Chrono-like.
    ---@param self ADFEntropyField
    ExpandingStunThread = function(self)
        local unit = self.unit
        local pos = unit:GetPosition()
        local bp = self.Blueprint
        local fieldRadius = self:GetMaxRadius()
        local buff = bp.Buffs[1]
        local slices = 10
        local sliceSize = fieldRadius / slices
        local sliceTime = buff.Duration * 10 / slices + 1
        local affected = {}
        local shieldDamaged = {}

        if not Buffs['AeonSCUEntropySlow'] then
            BuffBlueprint {
                Name = 'AeonSCUEntropySlow',
                DisplayName = 'AeonSCUEntropySlow',
                BuffType = 'AeonSCUEntropySlow',
                Stacks = 'REPLACE',
                Duration = 15,
                Affects = {
                    MoveMult = { Mult = 0.9 },
                },
            }
        end

        local shieldDamage = bp.AuraShieldDamage or 0
        for i = 1, slices do
            local waveRadius = i * sliceSize
            local flashScale = 0.5 + (slices - i) / (slices - 1) * 1.5
            local targets = Utilities.GetTrueEnemyUnitsInSphere(
                self, pos, waveRadius, self.CategoriesToStun
            )

            for _, target in targets do
                if not target:BeenDestroyed() then
                    local initial = not affected[target]
                    ApplyEntropyRegenDebuff(target)
                    Buff.ApplyBuff(target, 'AeonSCUEntropySlow')
                    CreateEntropyTargetFx(self, target, flashScale, initial)
                    affected[target] = true
                end
            end

            if shieldDamage > 0 then
                local shieldTargets = Utilities.GetTrueEnemyUnitsInSphere(
                    self, pos, waveRadius, categories.ALLUNITS
                )
                for _, st in shieldTargets do
                    if not shieldDamaged[st] and not st:BeenDestroyed()
                        and st.MyShield and st.MyShield:IsUp() then
                        -- FAF_AntiShield suppresses personal-shield overkill, so this
                        -- wave can collapse the shield but never damage unit health.
                        st.MyShield:ApplyDamage(unit, shieldDamage, st:GetPosition(), 'FAF_AntiShield', false)
                        shieldDamaged[st] = true
                    end
                end
            end

            WaitTicks(sliceTime)
        end
    end,
}
