local BaseManager = import('/lua/ai/opai/basemanager.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ThisFile = '/maps/scca_coop_e01.v0024/SCCA_Coop_E01_UEFBotAI.lua'

local SPAIFileName = '/lua/scenarioplatoonai.lua'

--------
-- Locals
--------
local BotUEF = 2
local Difficulty = ScenarioInfo.Options.Difficulty

local UEFBaseBot = BaseManager.CreateBaseManager()

function BotBaseAI()
	UEFBaseBot:Initialize(ArmyBrains[BotUEF], 'BotBase', 'TankStop5', 120,
        {
            Build1 = 250,
            Build2 = 230,
            Build3 = 220,
            Build4 = 210,
			Build5 = 200,
			Build6 = 190,
			Build7 = 170,
			Build8 = 160,
			Build9 = 150,
			Build10 = 130,
         }
    )
    UEFBaseBot:StartEmptyBase(12, true)
	UEFBaseBot:SetMaximumConstructionEngineers(6)
	UEFBaseBot:SetActive('LandScouting', true)
	UEFBaseBot:SetActive('AirScouting', true)
	BotBuildingUEF()
end

function DisableBase()
    if(UEFBaseBot) then
        UEFBaseBot:SetBuild('Engineers', false)
        UEFBaseBot:SetBuildAllStructures(false)
        UEFBaseBot:SetActive('AirScouting', false)
        UEFBaseBot:SetActive('LandScouting', false)
        UEFBaseBot:BaseActive(false)
    end
end

function BotBuildingUEF()
	local Temp = {
        'BotAttacksLand_1',
        'NoPlan',   
        { 'uel0201', 1, 4, 'Attack', 'GrowthFormation' },
		{ 'uel0103', 1, 4, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotLand_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 75,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ALLUNITS - categories.WALL},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksAir_1',
        'NoPlan',   
        { 'uea0102', 1, 5, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotAir_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 80,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.AIR * categories.MOBILE},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksAir_2',
        'NoPlan',   
        { 'uea0103', 1, 3, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotAir_Builder_2',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 79,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MOBILE * categories.LAND},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksAir_3',
        'NoPlan',   
        { 'uea0101', 1, 1, 'Attack', 'GrowthFormation' },
		{ 'uea0103', 1, 3, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotAir_Builder_3',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 82,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MOBILE * categories.LAND},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksAir_4',
        'NoPlan',   
        { 'uea0101', 1, 1, 'Attack', 'GrowthFormation' },
		{ 'uea0102', 1, 4, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotAir_Builder_4',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 82,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.AIR * categories.MOBILE},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	--local Temp = {
    --    'BotGivePlayer',
    --    'NoPlan',   
    --    { 'uel0202', 1, 2, 'Attack', 'GrowthFormation' },
    --    }
    --local Builder = {
    --    BuilderName = 'BotAny_Builder_1',
    --    PlatoonTemplate = Temp,
    --    InstanceCount = 2,
    --    Priority = 80,
    --    PlatoonType = 'Any',
    --    RequiresConstruction = true,
    --    LocationType = 'BotBase',
    --    PlatoonAIFunction = {ThisFile, 'GivePlayerAi'},     
	--		PlatoonData = {
	--			CategoryList = { categories.MOBILE * categories.LAND},
	--	},
    --}
	--ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksLand_2',
        'NoPlan',   
        { 'uel0201', 1, 8, 'Attack', 'GrowthFormation' },
		{ 'uel0104', 1, 4, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotLand_Builder_2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 75,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ALLUNITS - categories.WALL},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksLand_3',
        'NoPlan',   
        { 'uel0106', 1, 8, 'Attack', 'GrowthFormation' },
		{ 'uel0201', 1, 4, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotLand_Builder_3',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 75,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ALLUNITS - categories.WALL},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksLand_4',
        'NoPlan',   
        { 'uel0202', 1, 2, 'Attack', 'GrowthFormation' },
		{ 'uel0201', 1, 6, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotLand_Builder_4',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 78,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ALLUNITS - categories.WALL},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksLand_5',
        'NoPlan',   
        { 'uel0201', 1, 6, 'Attack', 'GrowthFormation' },
		{ 'uel0106', 1, 8, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotLand_Builder_5',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 78,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ALLUNITS - categories.WALL},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksLand_6',
        'NoPlan',   
        { 'uel0101', 1, 3, 'Attack', 'GrowthFormation' },
		{ 'uel0106', 1, 7, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotLand_Builder_6',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 82,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ALLUNITS - categories.WALL},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'BotAttacksLand_7',
        'NoPlan',   
        { 'uel0202', 1, 4, 'Attack', 'GrowthFormation' },
		{ 'uel0205', 1, 2, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'BotLand_Builder_7',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 89,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'BotBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.AIR * categories.MOBILE - categories.WALL},
		},
    }
	ArmyBrains[BotUEF]:PBMAddPlatoon( Builder )
end