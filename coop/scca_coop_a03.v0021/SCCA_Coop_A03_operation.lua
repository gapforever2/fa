-- ****************************************************************************
-- **
-- **  File     :  /maps/scca_coop_a03.v0021/SCCA_Coop_A03_operation.lua
-- **  Author(s):  Evan Pongress
-- **
-- **  Summary  :  Operation data for OpA3
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local OpStrings = import('/maps/scca_coop_a03.v0021/SCCA_Coop_A03_strings.lua')

operationData = 
{
    key = 'SCCA_Coop_A03',
    feedbackURL = 'http://forums.faforever.com/viewtopic.php?f=78&t=13894',
    opName = OpStrings.OPERATION_NAME,
    opDesctiption = OpStrings.OPERATION_DESCRIPTION,
    opBriefing = OpStrings.BriefingData,
    opDebriefingSuccess = OpStrings.A03_DB01_010,
    opDebriefingFailure = OpStrings.A03_DB01_020,
}