-- ****************************************************************************
-- **
-- **  File     :  /maps/scca_coop_e04.v0020/SCCA_Coop_E04_operation.lua
-- **  Author(s):  Evan Pongress
-- **
-- **  Summary  :  Operation data for OpE4
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local OpStrings = import('/maps/scca_coop_e04.v0020/SCCA_Coop_E04_strings.lua')

operationData = 
{
    key = 'SCCA_Coop_E04',
    feedbackURL = 'http://forums.faforever.com/viewtopic.php?f=78&t=13901',
    opName = OpStrings.OPERATION_NAME,
    opDesctiption = OpStrings.OPERATION_DESCRIPTION,
    opBriefing = OpStrings.BriefingData,
    opDebriefingSuccess = OpStrings.E04_DB01_010,
    opDebriefingFailure = OpStrings.E04_DB01_020,
}