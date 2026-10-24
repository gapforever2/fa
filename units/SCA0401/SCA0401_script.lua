local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local Flight = import('/units/URL0401/ScathisFlight.lua')
local Rotor = import('/units/URL0401/ScathisRotor.lua')

SCA0401 = ClassUnit(CAirUnit) {
    -- The airborne blueprint has no weapons: rotating barrels cannot fire.
    Weapons = {},

    OnStopBeingBuilt = function(self, builder, layer)
        local result = CAirUnit.OnStopBeingBuilt(self, builder, layer)
        if result == true then
            self.CopterBuildCounted = true
        end
        if result == false or not Flight.IsAlive(self) then
            return false
        end
        self.CopterAirborne = true
        self.CopterRequestedFlight = true
        self.CopterFlightMorph = true
        self:SetScriptBit('RULEUTC_SpecialToggle', true)
        self.CopterFlightMorph = nil
        Rotor.Start(self, true)
        Flight.Log(self, 'airborne-ready weapons=none')
        return result
    end,

    SendNotifyMessage = function(self, message, ...)
        -- Stock Unit.OnStopBeingBuilt sends 'completed' after incrementing
        -- its build statistic (3836 Unit.lua:2480,2498). Keep actual build
        -- alerts and suppress only our synchronously spawned replacements.
        if message == 'completed' and (self.CopterFlightMorph or Flight.SpawningMorph) then
            return
        end
        return CAirUnit.SendNotifyMessage(self, message, unpack(arg))
    end,

    OnScriptBitSet = function(self, bit)
        if bit == 7 then
            self.CopterRequestedFlight = true
            return
        end
        CAirUnit.OnScriptBitSet(self, bit)
    end,

    OnScriptBitClear = function(self, bit)
        if bit == 7 then
            if self.CopterFlightMorph or self.CopterTransition then
                return
            end
            self.CopterRequestedFlight = false
            self.CopterTransition = true
            self:ForkThread(self.CopterLandingThread)
            return
        end
        CAirUnit.OnScriptBitClear(self, bit)
    end,

    CopterRejectLanding = function(self, reason)
        if not Flight.IsAlive(self) then
            return
        end
        self.CopterRequestedFlight = true
        self.CopterFlightMorph = true
        self:SetScriptBit('RULEUTC_SpecialToggle', true)
        self.CopterFlightMorph = nil

        -- Cancellation and a newly obstructed landing site recover from the
        -- actual current height; changing the hover target must not snap us up.
        local position = self:GetPosition()
        local surfaceY = math.max(GetSurfaceHeight(position[1], position[3]),
            GetTerrainHeight(position[1], position[3])
                + GetTerrainTypeOffset(position[1], position[3]))
        local hoverY = surfaceY + (self.Blueprint.Physics.Elevation or 18)
        if math.abs(position[2] - hoverY) > 0.25 then
            self:SetImmobile(true)
            local recovered, recoveryFailure = Flight.MoveVertically(self, hoverY, 30, 'landing-recovery')
            if not Flight.IsAlive(self) then
                return
            end
            if not recovered then
                Flight.Log(self, 'landing-recovery-incomplete reason=' .. tostring(recoveryFailure))
            end
        end
        self:RevertElevation()
        self:SetImmobile(false)
        self.CopterFlightMorph = true
        self:SetScriptBit('RULEUTC_SpecialToggle', true)
        self.CopterFlightMorph = nil
        self.CopterTransition = nil
        Flight.Log(self, 'landing-rejected reason=' .. tostring(reason))
    end,

    CopterLandingThread = function(self)
        if not Flight.IsAlive(self) then
            return
        end
        local valid, reason = Flight.CanLand(self)
        if not valid then
            self:CopterRejectLanding(reason)
            return
        end

        IssueClearCommands({ self })
        IssueStop({ self })
        self:SetImmobile(true)
        Flight.Log(self, 'landing-start')
        local position = self:GetPosition()
        local groundY = GetTerrainHeight(position[1], position[3])
            + GetTerrainTypeOffset(position[1], position[3])
        local landed, movementFailure = Flight.MoveVertically(self, groundY, 30, 'landing',
            function(unit) return unit.CopterRequestedFlight end)
        if not Flight.IsAlive(self) then
            return
        end
        if not landed then
            self:CopterRejectLanding(movementFailure)
            return
        end
        if self.CopterRequestedFlight then
            self:CopterRejectLanding('cancelled')
            return
        end
        -- Units may move into the footprint during the three-second descent.
        valid, reason = Flight.CanLand(self)
        if not valid then
            self:CopterRejectLanding(reason)
            return
        end
        local replacement, failure = Flight.Transform(self, 'url0401', nil)
        if not replacement and Flight.IsAlive(self) then
            self:CopterRejectLanding('transform-' .. tostring(failure))
        end
    end,
}

TypeClass = SCA0401
