-- ****************************************************************************
-- **
-- **  File     : /maps/x1ca_coop_001.v0028/X1CA_Coop_001_m2uefai.lua
-- **  Author(s): Jessica St. Croix
-- **
-- **  Summary  : UEF army AI for Mission 2 - X1CA_Coop_001
-- **
-- **  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
local BaseManager = import('/lua/ai/opai/basemanager.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

local SPAIFileName = '/lua/scenarioplatoonai.lua'

--------
-- Locals
--------
local UEF = 4
local Difficulty = ScenarioInfo.Options.Difficulty

-- ########################
-- Custom Attack Chains: #
-- ########################

local M2_UEF_AttackChain = {
    'M2_UEF_WestTown_Patrol_5',
    'M2_NIS_Vis_4',
    'M2_Order_AirDef_Patrol_4',
    'M2_Order_Land_North_Marker',
    'M2_Order_MainLand_Patrol_3',
    'M2_Order_Air_South_Marker',
    'M2_Order_LandDef1_Patrol_2',
    'M2_Order_SouthBase',
    'M2_Order_SouthLand_Patrol_3'
}


---------------
-- Base Managers
---------------
local UEFM2WesternTown = BaseManager.CreateBaseManager()

function UEFM2WesternTownAI()

    ------------------
    -- UEF Western Town
    ------------------
    ScenarioUtils.CreateArmyGroup('UEF', 'M2_Town_Init_Eng_D' .. Difficulty)
-- ScenarioUtils.CreateArmyGroup('UEF', 'M2_Town_Turrets_D' .. Difficulty)
    UEFM2WesternTown:Initialize(ArmyBrains[UEF], 'M2_Town_Defenses', 'UEF_M2_Base_Marker', 70,
    {
        M2_Town_Defenses = 100,
        M2_Town_Turrets_D1 = 95,
    }
    )
    UEFM2WesternTown:StartNonZeroBase({10, 8})
    UEFM2WesternTown:SetMaximumConstructionEngineers(4)
-- UEFM2WesternTown:SetBuild('Engineers', false)

-- UEFM2WesternTown:AddBuildGroupDifficulty('M2_Town_Turrets', 90)

    UEFM2WesternTownLandAttacks()
    UEFM2WesternTownAirAttacks()
end

function UEFM2WesternTownLandAttacks()
    local opai = nil

    -----------------------------------------
    -- UEF M2 Western Town Op AI, Land Attacks
    -----------------------------------------

    -- sends [mobile missiles]
    opai = UEFM2WesternTown:AddOpAI('BasicLandAttack', 'M2_LandAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'UEF_M2_West_Town_Patrol_Chain',
            },
        }
    )
    opai:SetChildQuantity('MobileMissiles', 6)

    -- sends [heavy tanks]
    opai = UEFM2WesternTown:AddOpAI('BasicLandAttack', 'M2_LandAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'UEF_M2_West_Town_Patrol_Chain',
            },
        }
    )
    opai:SetChildQuantity('HeavyTanks', 6)

    -- sends [light bots]
    opai = UEFM2WesternTown:AddOpAI('BasicLandAttack', 'M2_LandAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'UEF_M2_West_Town_Patrol_Chain',
            },
        }
    )
    opai:SetChildQuantity('LightBots', 6)

    -- sends [light artillery]
    opai = UEFM2WesternTown:AddOpAI('BasicLandAttack', 'M2_LandAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'UEF_M2_West_Town_Patrol_Chain',
            },
        }
    )
    opai:SetChildQuantity('LightArtillery', 6)

    -- sends [siege bots]
    opai = UEFM2WesternTown:AddOpAI('BasicLandAttack', 'M2_LandAttack5',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolRoute = M2_UEF_AttackChain,
            },
        }
    )
    opai:SetChildQuantity('SiegeBots', 4)
end

function UEFM2WesternTownAirAttacks()
    local opai = nil

    ------------------------------------------
    -- UEF M2 Western Town Op AI, Air Attacks
    ------------------------------------------

    -- air defense
    for i = 1, 6 do
        opai = UEFM2WesternTown:AddOpAI('AirAttacks', 'M2_AirDefense1' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'UEF_M2_West_Town_Patrol_Chain',
                },
            }
        )
        opai:SetChildQuantity('Gunships', 2)
    end
	
	for i = 1, 3 do
        opai = UEFM2WesternTown:AddOpAI('AirAttacks', 'M2_AirDefense2' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'UEF_M2_West_Town_Patrol_Chain',
                },
            }
        )
        opai:SetChildQuantity('Bombers', 3)
    end
end


function DisableBase()
    if(UEFM2WesternTown) then
        UEFM2WesternTown:BaseActive(false)
    end
end
