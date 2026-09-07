--**********************************************************************************
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
--**********************************************************************************

local Unit = import("/lua/sim/unit.lua").Unit
local UnitOnCreate = Unit.OnCreate
local UnitOnKilled = Unit.OnKilled
local UnitDestroyAllTrashBags = Unit.DestroyAllTrashBags
local UnitCreateMovementEffects = Unit.CreateMovementEffects
local UnitDestroyMovementEffects = Unit.DestroyMovementEffects
local UnitStartBeingBuiltEffects = Unit.StartBeingBuiltEffects
local UnitOnStopBeingBuilt = Unit.OnStopBeingBuilt
local UnitOnLayerChange = Unit.OnLayerChange
local UnitOnDetachedFromTransport = Unit.OnDetachedFromTransport

local ShieldAmplifierMath = import('/lua/sim/aura/shieldamplifiermath.lua')
local ShieldAmplifierApplyValues = ShieldAmplifierMath.ShieldAmplifierApplyValues
local ShieldAmplifierRemoveValues = ShieldAmplifierMath.ShieldAmplifierRemoveValues

local EntitySetHealth = _G.moho.entity_methods.SetHealth
local EntitySetMaxHealth = _G.moho.entity_methods.SetMaxHealth
local ChangeState = ChangeState
local LOG = LOG

local TreadComponent = import("/lua/defaultcomponents.lua").TreadComponent
local TreadComponentOnCreate = TreadComponent.OnCreate
local TreadComponentCreateMovementEffects = TreadComponent.CreateMovementEffects
local TreadComponentDestroyMovementEffects = TreadComponent.DestroyMovementEffects

-- pre-import for performance
local CreateUEFUnitBeingBuiltEffects = import("/lua/effectutilities.lua").CreateUEFUnitBeingBuiltEffects

-- upvalue scope for performance
local TrashBag = TrashBag

---@class MobileUnit : Unit, TreadComponent
---@field MovementEffectsBag TrashBag
---@field TopSpeedEffectsBag TrashBag
---@field BeamExhaustEffectsBag TrashBag
---@field TransportBeamEffectsBag? TrashBag
---@field OnBeingBuiltEffectsBag? TrashBag
MobileUnit = ClassUnit(Unit, TreadComponent) {

    ---@param self MobileUnit
    OnCreate = function(self)
        UnitOnCreate(self)
        TreadComponentOnCreate(self)

        self.MovementEffectsBag = TrashBag()
        self.TopSpeedEffectsBag = TrashBag()
        self.BeamExhaustEffectsBag = TrashBag()
    end,

    ---@param self MobileUnit
    DestroyAllTrashBags = function(self)
        UnitDestroyAllTrashBags(self)

        self.MovementEffectsBag:Destroy()
        self.TopSpeedEffectsBag:Destroy()
        self.BeamExhaustEffectsBag:Destroy()

        -- only exists if unit is transported
        local transportBeamEffectsBag = self.TransportBeamEffectsBag
        if transportBeamEffectsBag then
            transportBeamEffectsBag:Destroy()
        end
    end,

    ---@param self MobileUnit
    ---@param effectsBag TrashBag
    ---@param typeSuffix string
    ---@param terrainType string
    CreateMovementEffects = function(self, effectsBag, typeSuffix, terrainType)
        UnitCreateMovementEffects(self, effectsBag, typeSuffix, terrainType)
        TreadComponentCreateMovementEffects(self)
    end,

    ---@param self MobileUnit
    DestroyMovementEffects = function(self)
        UnitDestroyMovementEffects(self)
        TreadComponentDestroyMovementEffects(self)
    end,

    ---@param self MobileUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        -- Skips a single OnKilled call
        -- currently used by transports with external storage, so that death effects can be applied later from OnImpact
        if self.killedInTransport then
            self.killedInTransport = false
        else
            UnitOnKilled(self, instigator, type, overkillRatio)
        end
    end,

    ---@param self MobileUnit
    ---@param builder Unit
    ---@param layer Layer
    StartBeingBuiltEffects = function(self, builder, layer)
        UnitStartBeingBuiltEffects(self, builder, layer)
        if self.Blueprint.FactionCategory == 'UEF' then
            CreateUEFUnitBeingBuiltEffects(self, builder, self.OnBeingBuiltEffectsBag)
        end
    end,

    -- Units with layer change effects (amphibious units like Megalith) need
    -- those changes applied when build ends, so we need to trigger the
    -- layer change event
    ---@param self MobileUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        UnitOnStopBeingBuilt(self, builder, layer)
        self:OnLayerChange(layer, 'None')
    end,

    ---@param self MobileUnit
    ---@param built Unit
    ---@param order string
    ---@return boolean
    OnStartBuild = function(self, built, order)
        if IsAlly(self.Army, built.Army) then
            return Unit.OnStartBuild(self, built, order)
        else
            self:OnFailedToBuild()
            IssueToUnitClearCommands(self)
            return false
        end
    end,

    ---@param self MobileUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)
        UnitOnLayerChange(self, new, old)

        -- Do this after the default function so the engine-bug guard in unit.lua works
        if self.transportDrop then
            self.transportDrop = nil
            self:SetImmobile(false)
        end
    end,

    ---@param self MobileUnit
    ---@param transport AirUnit
    ---@param bone Bone
    OnDetachedFromTransport = function(self, transport, bone)
        UnitOnDetachedFromTransport(self, transport, bone)

        -- Set unit immobile to prevent it to accelerating in the air, cleared in OnLayerChange
        if not self.Blueprint.CategoriesHash["AIR"] then
            self:SetImmobile(true)
            self.transportDrop = true
        end
    end,

    --- Applies a calculated Shield Amplifier bonus to the live shield entity.
    --- An active shield gains the bonus in both current and maximum HP immediately.
    --- A depleted, disabled or recharging shield changes maximum HP only; damage
    --- recharge will fill it to that live maximum when the normal timer completes.
    ---@param self MobileUnit
    ---@param bonus number
    ---@param mult number|table
    ---@return boolean
    AeonShieldAmpApplyBonus = function(self, bonus, mult)
        if self.Dead or self.AeonShieldAmpBonus or bonus <= 0 then
            return false
        end

        local shield = self.MyShield
        if not shield or shield:BeenDestroyed() then
            return false
        end

        local currentMax = shield:GetMaxHealth()
        local currentHP = shield:GetHealth()
        local shieldIsUp = shield:IsUp()
        local newHP, newMax = ShieldAmplifierApplyValues(currentHP, currentMax, bonus, shieldIsUp)

        EntitySetMaxHealth(shield, newMax)
        if shieldIsUp then
            EntitySetHealth(shield, self, newHP)
            shield:UpdateShieldRatio(newHP / newMax)
        end

        self.Sync.ShieldMaxHealth = newMax
        self.AeonShieldAmpBonus = bonus
        self.AeonShieldAmpMult = mult
        LOG('[AURA][SHIELD] applied unit=', self.UnitId or self:GetUnitId(),
            ' current=', currentHP, '/', currentMax, ' -> ', newHP, '/', newMax,
            ' up=', shieldIsUp)
        return true
    end,

    --- Removes the currently applied Shield Amplifier bonus. If subtracting the
    --- bonus consumes the remaining active shield HP, enter the engine's regular
    --- damage-recharge state. A shield already recharging remains at zero HP and
    --- keeps its existing recharge timer while only its maximum changes.
    ---@param self MobileUnit
    ---@return boolean
    AeonShieldAmpRemoveBonus = function(self)
        local bonus = self.AeonShieldAmpBonus
        if not bonus then
            return false
        end

        self.AeonShieldAmpBonus = nil
        self.AeonShieldAmpMult = nil

        local shield = self.MyShield
        if not shield or shield:BeenDestroyed() then
            return false
        end

        local currentMax = shield:GetMaxHealth()
        local currentHP = shield:GetHealth()
        local shieldIsUp = shield:IsUp()
        local newHP, newMax, collapse = ShieldAmplifierRemoveValues(currentHP, currentMax, bonus, shieldIsUp)

        EntitySetMaxHealth(shield, newMax)
        if shieldIsUp then
            EntitySetHealth(shield, self, newHP)
            shield:UpdateShieldRatio(newMax > 0 and newHP / newMax or 0)
        end
        self.Sync.ShieldMaxHealth = newMax

        if collapse then
            shield.DisallowCollisions = true
            ChangeState(shield, shield.DamageDrainedState)
        end

        LOG('[AURA][SHIELD] removed unit=', self.UnitId or self:GetUnitId(),
            ' current=', currentHP, '/', currentMax, ' -> ', newHP, '/', newMax,
            ' up=', shieldIsUp, ' collapse=', collapse)

        return true
    end,

    --- Registers one amplifier source. Sources never stack the bonus, but every
    --- source is retained so leaving one overlapping field does not remove a bonus
    --- still supplied by another field.
    ---@param self MobileUnit
    ---@param source Unit
    ---@param mult number|table
    ---@return boolean
    AeonShieldAmpRegisterSource = function(self, source, mult)
        if self.Dead or not source or IsDestroyed(source) then
            return false
        end

        local sources = self.AeonShieldAmpSources
        if not sources then
            sources = {}
            self.AeonShieldAmpSources = sources
        end
        sources[source] = mult

        if not self.AeonShieldAmpBonus then
            self:AeonShieldAmpApply(source, mult)
        end

        return self.AeonShieldAmpBonus ~= nil
    end,

    ---@param self MobileUnit
    ---@return number|table|nil
    AeonShieldAmpGetSourceMult = function(self)
        local sources = self.AeonShieldAmpSources
        if not sources then
            return nil
        end

        for source, mult in sources do
            if source and not IsDestroyed(source) and not source.Dead then
                return mult
            end
            sources[source] = nil
        end

        self.AeonShieldAmpSources = nil
        return nil
    end,

    ---@param self MobileUnit
    ---@param source Unit
    ---@return boolean lastSourceRemoved
    AeonShieldAmpUnregisterSource = function(self, source)
        local sources = self.AeonShieldAmpSources
        if not sources then
            return true
        end

        sources[source] = nil
        if self:AeonShieldAmpGetSourceMult() then
            return false
        end

        self:AeonShieldAmpRemove()
        return true
    end,

    --- Called by the Aeon SACU Shield Amplifier aura when this unit enters its field.
    ---@param self MobileUnit
    ---@param instigator Unit
    ---@param mult number # multiplier applied to the shield max
    AeonShieldAmpApply = function(self, instigator, mult)
        if self.Dead then
            return
        end
        -- Enhancement-specific shields pass a lookup table and resolve it in
        -- their unit class. The generic implementation cannot choose a value
        -- safely, so ignore an unresolved value instead of throwing every aura
        -- update tick.
        if type(mult) ~= 'number' then
            return
        end
        if self.AeonShieldAmpBonus then
            return
        end
        local shield = self.MyShield
        if not shield or shield:BeenDestroyed() then
            return
        end
        local baseBp = self:GetBlueprint().Defense.Shield
        if not baseBp then
            return
        end
        local baseMax = baseBp.ShieldMaxHealth or 0
        local bonus = math.floor(baseMax * ((mult or 1) - 1) + 0.5)
        if bonus <= 0 then
            return
        end

        self:AeonShieldAmpApplyBonus(bonus, mult)
    end,

    --- Called when this unit leaves the aura field (or the enhancement is removed):
    --- immediately subtracts the bonus from both current and max HP. If current goes
    --- to zero the shield enters recharge.
    ---@param self MobileUnit
    AeonShieldAmpRemove = function(self)
        self:AeonShieldAmpRemoveBonus()
    end,
}
