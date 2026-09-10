--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB3202/UEB3202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Long Range Sonar Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local MobileSonarUnit = import("/lua/sim/units/mobilesonarunit.lua").MobileSonarUnit

---@class UEB3202 : MobileSonarUnit
UEB3202 = ClassUnit(MobileSonarUnit) {
    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'UEB3202',
            },
            Offset = {
                0,
                -1.3,
                0,
            },
            Type = 'SonarBuoy01',
        },
    },
}

TypeClass = UEB3202