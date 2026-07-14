-- XAA0305 dual-range missile behavior.
-- Drop-in unit script for a FAF 3836 balance archive.

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local ADFQuadLaserLightWeapon = import('/lua/aeonweapons.lua').ADFQuadLaserLightWeapon
local AAAZealot02MissileWeapon = import('/lua/aeonweapons.lua').AAAZealot02MissileWeapon

local ModeAuto = 'auto'
local ModeDirectAir = 'direct-air'
local ModeDirectSurface = 'direct-surface'

local MissilePairs = {
    { Air = 'AAGun01', Ground = 'GroundMissile01' },
    { Air = 'AAGun02', Ground = 'GroundMissile02' },
}

local function DebugLog(unit, message)
    LOG(string.format(
        '* XAA0305 Ground Missiles [%s]: %s',
        tostring(unit.EntityId or 'unknown'),
        message
    ))
end

local function CopyAim(unit, sourceLabel, destinationLabel)
    local source = unit:GetWeaponManipulatorByLabel(sourceLabel)
    local destination = unit:GetWeaponManipulatorByLabel(destinationLabel)

    if source and destination then
        destination:SetHeadingPitch(source:GetHeadingPitch())
    end
end

local function GetDirectAttackMode(unit)
    local queue = unit:GetCommandQueue()
    local command = queue and queue[1]

    if not command
        or (command.commandType ~= 10 and command.commandType ~= 11)
        or not command.target
    then
        return ModeAuto, nil
    end

    local target = command.target
    if not IsUnit(target) and target.GetSource then
        target = target:GetSource() or target
    end

    if IsUnit(target) and EntityCategoryContains(categories.AIR, target) then
        return ModeDirectAir, target
    end

    return ModeDirectSurface, target
end

local function MakeAirMissileWeapon(airLabel, groundLabel)
    return ClassWeapon(AAAZealot02MissileWeapon) {
        IdleState = State(AAAZealot02MissileWeapon.IdleState) {
            OnGotTarget = function(self)
                AAAZealot02MissileWeapon.IdleState.OnGotTarget(self)

                local unit = self.unit

                if unit.MissileTargetMode == ModeDirectSurface then
                    DebugLog(
                        unit,
                        airLabel .. ' rejected automatic air target=' .. tostring(self:GetCurrentTarget())
                            .. ' during direct surface attack'
                    )
                    unit:SetWeaponEnabledByLabel(airLabel, false)
                    return
                end

                CopyAim(unit, groundLabel, airLabel)
                unit:SetWeaponEnabledByLabel(groundLabel, false)
                DebugLog(
                    unit,
                    airLabel .. ' acquired air target=' .. tostring(self:GetCurrentTarget())
                        .. '; ' .. groundLabel .. ' disabled'
                )
            end,
        },

        OnLostTarget = function(self)
            AAAZealot02MissileWeapon.OnLostTarget(self)

            local unit = self.unit
            CopyAim(unit, airLabel, groundLabel)

            local airManipulator = unit:GetWeaponManipulatorByLabel(airLabel)
            if airManipulator then
                airManipulator:SetHeadingPitch(0, 0)
            end

            if unit.MissileTargetMode ~= ModeDirectAir then
                unit:SetWeaponEnabledByLabel(groundLabel, true)
                DebugLog(unit, airLabel .. ' lost air target; ' .. groundLabel .. ' enabled')
            else
                DebugLog(unit, airLabel .. ' lost air target during direct air attack')
            end
        end,
    }
end

local function MakeGroundMissileWeapon(airLabel, groundLabel)
    return ClassWeapon(AAAZealot02MissileWeapon) {
        IdleState = State(AAAZealot02MissileWeapon.IdleState) {
            OnGotTarget = function(self)
                AAAZealot02MissileWeapon.IdleState.OnGotTarget(self)

                if self.unit.MissileTargetMode == ModeDirectSurface then
                    self.unit:SetWeaponEnabledByLabel(airLabel, false)
                end

                DebugLog(
                    self.unit,
                    groundLabel .. ' acquired surface target=' .. tostring(self:GetCurrentTarget())
                )
            end,
        },
    }
end

---@class XAA0305 : AAirUnit
XAA0305 = ClassUnit(AAirUnit) {
    Weapons = {
        Turret = ClassWeapon(ADFQuadLaserLightWeapon) {},
        AAGun01 = MakeAirMissileWeapon('AAGun01', 'GroundMissile01'),
        AAGun02 = MakeAirMissileWeapon('AAGun02', 'GroundMissile02'),
        GroundMissile01 = MakeGroundMissileWeapon('AAGun01', 'GroundMissile01'),
        GroundMissile02 = MakeGroundMissileWeapon('AAGun02', 'GroundMissile02'),
    },

    SetMissileTargetMode = function(self, mode, target)
        if self.MissileTargetMode == mode and self.MissileCommandTarget == target then
            return
        end

        self.MissileTargetMode = mode
        self.MissileCommandTarget = target

        if mode == ModeDirectSurface then
            for _, pair in MissilePairs do
                self:SetWeaponEnabledByLabel(pair.Air, false)
                self:SetWeaponEnabledByLabel(pair.Ground, true)
            end
        elseif mode == ModeDirectAir then
            for _, pair in MissilePairs do
                self:SetWeaponEnabledByLabel(pair.Ground, false)
                self:SetWeaponEnabledByLabel(pair.Air, true)
            end
        else
            for _, pair in MissilePairs do
                local airWeapon = self:GetWeaponByLabel(pair.Air)
                local hasAirTarget = airWeapon and airWeapon:GetCurrentTarget()

                self:SetWeaponEnabledByLabel(pair.Air, true)
                self:SetWeaponEnabledByLabel(pair.Ground, not hasAirTarget)
            end
        end

        DebugLog(self, 'target mode=' .. mode .. '; command target=' .. tostring(target))
    end,

    MissileTargetModeThread = function(self)
        while not self.Dead do
            local mode, target = GetDirectAttackMode(self)
            self:SetMissileTargetMode(mode, target)
            WaitTicks(1)
        end
    end,

    OnCreate = function(self)
        AAirUnit.OnCreate(self)
        self.MissileTargetMode = ModeAuto
        self.MissileCommandTarget = nil
        self:ForkThread(self.MissileTargetModeThread)
        DebugLog(self, 'unit created; dual-range direct-order logic active')
    end,
}

TypeClass = XAA0305

