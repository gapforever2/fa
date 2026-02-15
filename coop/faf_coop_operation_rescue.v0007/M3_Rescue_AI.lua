local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

local UEF = 3

local Difficulty = ScenarioInfo.Options.Difficulty

local M3_UEF_Defenses = BaseManager.CreateBaseManager()

function RescueFunction()
    M3_UEF_Defenses:Initialize(ArmyBrains[UEF], 'TDefenses', 'M3_Base_Defenses', 85, {TFactory = 100, TDefenses = 90})
    M3_UEF_Defenses:StartEmptyBase(5, 1)
	
	BuildUEFLand()
end


function BuildUEFLand()
	local opai = nil
    local quantity = {}
	
	quantity = {6, 4, 4}
    opai = M3_UEF_Defenses:AddOpAI('BasicLandAttack', 'M3_Uef_Defense_Patrol_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M3_UEF_Reinforcement_Patrol'
            },
            Priority = 80,
        }
    )
    opai:SetChildQuantity('HeavyTanks', quantity[Difficulty])
	
	quantity = {12, 8, 6}
    opai = M3_UEF_Defenses:AddOpAI('BasicLandAttack', 'M3_Uef_Defense_Patrol_2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M3_UEF_Reinforcement_Patrol'
            },
            Priority = 75,
        }
    )
    opai:SetChildQuantity('LightBots', quantity[Difficulty])
	
	opai = M3_UEF_Defenses:AddOpAI('EngineerAttack', 'UEF_Eng_Reclaim_1',
		{
			MasterPlatoonFunction = {SPAIFileName, 'SplitPatrolThread'},
			PlatoonData = {
				PatrolChains = {
					'M3_UEF_Reinforcement_Patrol',
				},
			},
			Priority = 90,
		}
	)
    opai:SetChildQuantity('T1Engineers', 4)
	
end

function DisableBase()
    if(M3_UEF_Defenses) then
        M3_UEF_Defenses:BaseActive(false)
    end
end