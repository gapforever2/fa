-- ****************************************************************************
-- **
-- **  File     :  /maps/scca_coop_r06.v0021/SCCA_Coop_R06_script.lua
-- **  Author(s):  Jessica St. Croix
-- **
-- **  Summary  :  Custom PBM functions
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
local OpStrings = import('/maps/scca_coop_r06.v0021/SCCA_Coop_R06_strings.lua')
local ScenarioFramework = import('/lua/scenarioframework.lua')

-- ###############################################################################
-- function: CzarAttack = AddFunction    doc = ""
--
-- parameter 0: string    platoon         = "default_platoon"
--
-- ###############################################################################
function CzarAttack(platoon)
    platoon:AttackTarget(ScenarioInfo.ControlCenter)
end
