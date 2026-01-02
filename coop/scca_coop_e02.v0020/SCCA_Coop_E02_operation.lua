-- ****************************************************************************
-- **
-- **  File     :  /maps/scca_coop_e02.v0020/SCCA_Coop_E02_operation.lua
-- **  Author(s):  Evan Pongress
-- **
-- **  Summary  :  Operation data for OpE2
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local OpStrings = import('/maps/scca_coop_e02.v0020/SCCA_Coop_E02_strings.lua')

operationData = 
{
    key = 'SCCA_Coop_E02',
    feedbackURL = 'http://forums.faforever.com/viewtopic.php?f=78&t=13899',
    opName = OpStrings.OPERATION_NAME,
    opDesctiption = OpStrings.OPERATION_DESCRIPTION,
    opBriefing = OpStrings.BriefingData,
    opDebriefingSuccess = OpStrings.E02_DB01_010,
    opDebriefingFailure = OpStrings.E02_DB01_020,
}