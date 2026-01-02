-- ****************************************************************************
-- **
-- **  File     :  /maps/scca_coop_e03.v0022/SCCA_Coop_E03_operation.lua
-- **  Author(s):  Evan Pongress
-- **
-- **  Summary  :  Operation data for OpE3
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local OpStrings = import('/maps/scca_coop_e03.v0022/SCCA_Coop_E03_strings.lua')

operationData = 
{
    key = 'SCCA_Coop_E03',
    feedbackURL = 'http://forums.faforever.com/viewtopic.php?f=78&t=13900',
    opName = OpStrings.OPERATION_NAME,
    opDesctiption = OpStrings.OPERATION_DESCRIPTION,
    opBriefing = OpStrings.BriefingData,
    opDebriefingSuccess = OpStrings.E03_DB01_010,
    opDebriefingFailure = OpStrings.E03_DB01_020,
}