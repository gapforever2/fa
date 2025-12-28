-- ****************************************************************************
-- **
-- **  File     :  /maps/scca_coop_a02.v0021/SCCA_Coop_A02_operation.lua
-- **  Author(s):  Evan Pongress
-- **
-- **  Summary  :  Operation data for OpA2
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local OpStrings = import('/maps/scca_coop_a02.v0021/SCCA_Coop_A02_strings.lua')

operationData = 
{
    key = 'SCCA_Coop_A02',
    feedbackURL = 'http://forums.faforever.com/viewtopic.php?f=78&t=13893',
    opName = OpStrings.OPERATION_NAME,
    opDesctiption = OpStrings.OPERATION_DESCRIPTION,
    opBriefing = OpStrings.BriefingData,
    opDebriefingSuccess = OpStrings.A02_DB01_010,
    opDebriefingFailure = OpStrings.A02_DB01_020,
}