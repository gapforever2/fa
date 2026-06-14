--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB3202/UAB3202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Long Range Sonar Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local MobileSonarUnit = import("/lua/sim/units/mobilesonarunit.lua").MobileSonarUnit

---@class UAB3202 : MobileSonarUnit
UAB3202 = ClassUnit(MobileSonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'Probe',
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = UAB3202