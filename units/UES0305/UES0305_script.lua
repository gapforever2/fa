----****************************************************************************
----**
----**  File     :  /cdimage/units/UES0305/UES0305_script.lua
----**  Author(s):  John Comes
----**
----**  Summary  :  UEF T3 Mobile Sonar
----**
----**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler
local CreateBuildCubeThread = import("/lua/effectutilities.lua").CreateBuildCubeThread

-- Энергопотребление разделено между двумя кнопками-переключателями
local SonarEnergyConsumption = 400
local JammerEnergyConsumption = 100

---@class UES0305 : TSeaUnit
UES0305 = ClassUnit(TSeaUnit) {
    Weapons = {
        Torpedo01 = ClassWeapon(TANTorpedoAngler) {},
    },

    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'B14',
            },
            Offset = {
                0,
                -0.6,
                0,
            },
            Type = 'SonarBuoy01',
        },
    }, 

    OnStopBeingBuilt = function(self, builder, layer)
        TSeaUnit.OnStopBeingBuilt(self, builder, layer)
        self.SonarEnabled = true
        self.JammerEnabled = true
        self:UpdateIntelConsumption()
    end,

    -- Пересчитывает расход энергии в зависимости от того, какие переключатели включены:
    -- сонар тратит 500, джаммер - 100
    UpdateIntelConsumption = function(self)
        local energy = 0
        if self.SonarEnabled then
            energy = energy + SonarEnergyConsumption
        end
        if self.JammerEnabled then
            energy = energy + JammerEnergyConsumption
        end
        self:SetEnergyMaintenanceConsumptionOverride(energy)
        if energy > 0 then
            self:SetMaintenanceConsumptionActive()
        else
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    CreateIdleEffects = function(self)
        TSeaUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread(self.TimedIdleSonarEffects)
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
                            emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0,vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end                    
                end
                WaitSeconds(6)                
            end
        end
    end,

    DestroyIdleEffects = function(self)
        self.TimedSonarEffectsThread:Destroy()
        TSeaUnit.DestroyIdleEffects(self)
    end,     

    StartBeingBuiltEffects = function(self, builder, layer)
        self:HideBone(0, true)
        self.BeingBuiltShowBoneTriggered = false
        if self:GetBlueprint().General.UpgradesFrom ~= builder.UnitId then
            self.OnBeingBuiltEffectsBag:Add(self:ForkThread(CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag))
        end
    end,

    ---@param self UES0305
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 2 then -- Переключатель джаммера: выключить
            self.JammerEnabled = false
            self:UpdateIntelConsumption()
            self:DisableUnitIntel('ToggleBit2', 'Jammer')
        elseif bit == 3 then -- Переключатель сонара: выключить
            self.SonarEnabled = false
            self:UpdateIntelConsumption()
            self:DisableUnitIntel('ToggleBit3', 'Sonar')
        else
            TSeaUnit.OnScriptBitSet(self, bit)
        end
    end,

    ---@param self UES0305
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 2 then -- Переключатель джаммера: включить
            self.JammerEnabled = true
            self:UpdateIntelConsumption()
            self:EnableUnitIntel('ToggleBit2', 'Jammer')
        elseif bit == 3 then -- Переключатель сонара: включить
            self.SonarEnabled = true
            self:UpdateIntelConsumption()
            self:EnableUnitIntel('ToggleBit3', 'Sonar')
        else
            TSeaUnit.OnScriptBitClear(self, bit)
        end
    end,
}

TypeClass = UES0305
