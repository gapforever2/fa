--**********************************************************************************
--** Mobile sonar unit.
--**
--** A sonar that behaves like a regular naval (surface) unit: it can move on the
--** water but - unlike the Seraphim sonar - it cannot submerge. It is based on the
--** mobile SeaUnit so that engine movement (RULEUMT_Water) works.
--**
--** On top of that it re-implements the regular, vanilla "UpgradesTo" upgrade that
--** structures use (the upgrade button). The unit builds its upgrade in place and,
--** like a structure, it sits still for the duration of the upgrade. This is the
--** normal upgrade button - NOT the ACU/SACU enhancement system.
--**********************************************************************************

local Unit = import("/lua/sim/unit.lua").Unit
local UnitOnStopBuild = Unit.OnStopBuild
local UnitOnFailedToBuild = Unit.OnFailedToBuild

local SeaUnit = import("/lua/sim/units/seaunit.lua").SeaUnit
local SeaUnitOnStartBuild = SeaUnit.OnStartBuild
local SeaUnitOnStopBeingBuilt = SeaUnit.OnStopBeingBuilt
local SeaUnitCreateIdleEffects = SeaUnit.CreateIdleEffects
local SeaUnitDestroyIdleEffects = SeaUnit.DestroyIdleEffects

---@class MobileSonarUnit : SeaUnit
---@field TimedSonarEffectsThread? thread
MobileSonarUnit = ClassUnit(SeaUnit) {

    ---@param self MobileSonarUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        SeaUnitOnStopBeingBuilt(self, builder, layer)
        -- Make sure the sonar drains its energy upkeep (MaintenanceConsumptionPerSecondEnergy).
        -- Mirrors the vanilla T3 mobile sonar (urs0305), which re-asserts this explicitly.
        self:SetMaintenanceConsumptionActive()
    end,

    --#region Sonar idle effects (moved here from the stationary SonarUnit)

    ---@param self MobileSonarUnit
    CreateIdleEffects = function(self)
        SeaUnitCreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread(self.TimedIdleSonarEffects)
    end,

    ---@param self MobileSonarUnit
    TimedIdleSonarEffects = function(self)
        local layer = self.Layer
        local pos = self:GetPosition()

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects('FXIdle', layer, pos, vTypeGroup.Type, nil)

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            local emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0, vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                self:PlayUnitSound('Sonar')
                WaitSeconds(6.0)
            end
        end
    end,

    ---@param self MobileSonarUnit
    DestroyIdleEffects = function(self)
        SeaUnitDestroyIdleEffects(self)
        local timedSonarEffectsThread = self.TimedSonarEffectsThread
        if timedSonarEffectsThread then
            timedSonarEffectsThread:Destroy()
        end
    end,

    --#endregion

    --#region Vanilla "UpgradesTo" upgrade (same behaviour as a structure upgrade)

    ---@param self MobileSonarUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    ---@return boolean
    OnStartBuild = function(self, unitBeingBuilt, order)
        -- keep the regular (ally-check) build handling of the mobile unit
        if not SeaUnitOnStartBuild(self, unitBeingBuilt, order) then
            return false
        end
        self.UnitBeingBuilt = unitBeingBuilt

        local builderBp = self.Blueprint
        local targetBp = unitBeingBuilt.Blueprint
        local performUpgrade =
            targetBp.General.UpgradesFrom == builderBp.BlueprintId or
            targetBp.General.UpgradesFrom == builderBp.General.UpgradesTo

        if performUpgrade and order == 'Upgrade' then
            ChangeState(self, self.UpgradingState)
        end

        return true
    end,

    ---@param self MobileSonarUnit unused
    ---@param unitBeingBuilt Unit
    StartUpgradeEffects = function(self, unitBeingBuilt)
        unitBeingBuilt:HideBone(0, true)
    end,

    ---@param self MobileSonarUnit unused
    ---@param unitBeingBuilt Unit
    StopUpgradeEffects = function(self, unitBeingBuilt)
        unitBeingBuilt:ShowBone(0, true)
    end,

    --- Completes the in-place upgrade by removing this (the old) unit once the upgraded
    --- unit is finished. Unlike structures, mobile units are not automatically consumed
    --- by the engine when they build their upgrade, so we remove the old unit ourselves -
    --- this is the same "destroy and replace" primitive that HARMS (XRB2308) uses.
    ---@param self MobileSonarUnit
    ---@param unitBuilding Unit
    FinishUpgrade = function(self, unitBuilding)
        if self.UpgradeFinished then
            return
        end
        self.UpgradeFinished = true
        NotifyUpgrade(self, unitBuilding)
        self:StopUpgradeEffects(unitBuilding)
        self:PlayUnitSound('UpgradeEnd')
        self:Destroy()
    end,

    IdleState = State {
        Main = function(self)
        end,
    },

    UpgradingState = State {
        Main = function(self)
            self:PlayUnitSound('UpgradeStart')
            self:DisableDefaultToggleCaps()

            local unitBuilding = self.UnitBeingBuilt

            local animation = self:GetUpgradeAnimation(unitBuilding)
            if animation then
                self.AnimatorUpgradeManip = CreateAnimator(self)
                self.Trash:Add(self.AnimatorUpgradeManip)
                self:StartUpgradeEffects(unitBuilding)
                self.AnimatorUpgradeManip:PlayAnim(animation, false):SetRate(0)
            end

            -- Drive the upgrade animation and wait for the upgraded unit to finish.
            -- We don't rely on OnStopBuild firing (it isn't reliable for a mobile builder),
            -- so the old unit is removed here once the upgrade reaches 100%.
            while not self.Dead and unitBuilding and not unitBuilding.Dead and unitBuilding:GetFractionComplete() < 1 do
                if self.AnimatorUpgradeManip then
                    self.AnimatorUpgradeManip:SetAnimationFraction(unitBuilding:GetFractionComplete())
                end
                WaitTicks(1)
            end

            if not self.Dead and unitBuilding and not unitBuilding.Dead and unitBuilding:GetFractionComplete() == 1 then
                if self.AnimatorUpgradeManip then
                    self.AnimatorUpgradeManip:SetRate(1)
                end
                self:FinishUpgrade(unitBuilding)
            end
        end,

        OnStopBuild = function(self, unitBuilding, order)
            UnitOnStopBuild(self, unitBuilding, order)
            self:EnableDefaultToggleCaps()

            if unitBuilding:GetFractionComplete() == 1 then
                self:FinishUpgrade(unitBuilding)
            end
        end,

        -- Override OnFailedToBuild so that the upgrade is NOT cancelled by other
        -- orders (move/patrol/attack/stop). Only an explicit build-cancel should stop it.
        -- The upgrade continues even if the sonar receives other commands.
        OnFailedToBuild = function(self)
            -- Just re-enable controls but stay in the upgrade state.
            -- The upgrade will continue in the Main loop regardless of other orders.
            self:EnableDefaultToggleCaps()
            if self.AnimatorUpgradeManip then
                self.AnimatorUpgradeManip:Destroy()
                self.AnimatorUpgradeManip = nil
            end
            -- Do NOT play 'UpgradeFailed' sound or ChangeState.
            -- Stay in UpgradingState and let the Main loop continue building.
        end,
    },

    --#endregion
}
