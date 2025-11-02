--****************************************************************************
--**
--**  File     :  /cdimage/units/XSL0303/XSL0303_script.lua
--**  Author(s):  Dru Staltman, Aaron Lundquist
--**
--**  Summary  :  Seraphim Siege Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit
local WeaponsFile = import("/lua/seraphimweapons.lua")
local SDFUltraChromaticBeamGenerator = import("/lua/seraphimweapons.lua").SDFUltraChromaticBeamGenerator
local SDFAireauBolter = WeaponsFile.SDFAireauBolterWeapon
local SANUallCavitationTorpedo = WeaponsFile.SANUallCavitationTorpedo
local EffectUtil = import("/lua/effectutilities.lua")

---@class XSL0303 : SLandUnit
XSL0303 = ClassUnit(SLandUnit) {
    Weapons = {
        MainTurret = ClassWeapon(SDFUltraChromaticBeamGenerator) {},
        Torpedo01 = ClassWeapon(SANUallCavitationTorpedo) {},
        LeftTurret = ClassWeapon(SDFAireauBolter) {},
        RightTurret = ClassWeapon(SDFAireauBolter) {},
    },
}

TypeClass = XSL0303