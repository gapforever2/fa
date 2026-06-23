-- File     :  /cdimage/units/URB3202/URB3202_script.lua
-- Author(s):  John Comes
-- Summary  :  Cybran Long Range Sonar Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit

-- Энергопотребление разделено между двумя кнопками-переключателями
local SonarEnergyConsumption = 400
local StealthEnergyConsumption = 200

---@class URB3302 : CSeaUnit
URB3302 = ClassUnit(CSeaUnit) {
    OnStopBeingBuilt = function(self, builder, layer)
        CSeaUnit.OnStopBeingBuilt(self, builder, layer)
        self.SonarEnabled = true
        self.StealthEnabled = true
        self:UpdateIntelConsumption()
    end,

    -- Пересчитывает расход энергии в зависимости от того, какие переключатели включены:
    -- сонар тратит 500, стелс-поле - 100
    UpdateIntelConsumption = function(self)
        local energy = 0
        if self.SonarEnabled then
            energy = energy + SonarEnergyConsumption
        end
        if self.StealthEnabled then
            energy = energy + StealthEnergyConsumption
        end
        self:SetEnergyMaintenanceConsumptionOverride(energy)
        if energy > 0 then
            self:SetMaintenanceConsumptionActive()
        else
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'Plunger',
            },
            Type = 'SonarBuoy01',
        },
    },

    CreateIdleEffects = function(self)
        CSeaUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self.Trash:Add(ForkThread(self.TimedIdleSonarEffects,self))
    end,

    TimedIdleSonarEffects = function(self)
        local layer = self.Layer
        local pos = self:GetPosition()

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects('FXIdle', layer, pos, vTypeGroup.Type, nil)

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale
                                or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0,
                                    vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                WaitTicks(61)
            end
        end
    end,

    DestroyIdleEffects = function(self)
        self.TimedSonarEffectsThread:Destroy()
        CSeaUnit.DestroyIdleEffects(self)
    end,

    ---@param self URB3302
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 3 then -- Переключатель сонара: выключить
            self.SonarEnabled = false
            self:UpdateIntelConsumption()
            self:DisableUnitIntel('ToggleBit3', 'Sonar')
        elseif bit == 5 then -- Переключатель стелс-поля: выключить
            self.StealthEnabled = false
            self:UpdateIntelConsumption()
            self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit5', 'RadarStealthField')
            self:DisableUnitIntel('ToggleBit5', 'SonarStealth')
            self:DisableUnitIntel('ToggleBit5', 'SonarStealthField')
        else
            CSeaUnit.OnScriptBitSet(self, bit)
        end
    end,

    ---@param self URB3302
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 3 then -- Переключатель сонара: включить
            self.SonarEnabled = true
            self:UpdateIntelConsumption()
            self:EnableUnitIntel('ToggleBit3', 'Sonar')
        elseif bit == 5 then -- Переключатель стелс-поля: включить
            self.StealthEnabled = true
            self:UpdateIntelConsumption()
            self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit5', 'RadarStealthField')
            self:EnableUnitIntel('ToggleBit5', 'SonarStealth')
            self:EnableUnitIntel('ToggleBit5', 'SonarStealthField')
        else
            CSeaUnit.OnScriptBitClear(self, bit)
        end
    end,
}

TypeClass = URB3302
