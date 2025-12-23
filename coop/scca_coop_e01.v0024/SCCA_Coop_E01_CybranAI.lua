local BaseManager = import('/lua/ai/opai/basemanager.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ThisFile = '/maps/scca_coop_e01.v0024/SCCA_Coop_E01_CybranAI.lua'

local SPAIFileName = '/lua/scenarioplatoonai.lua'
--------
-- Locals
--------
local Cybran = 3
local Difficulty = ScenarioInfo.Options.Difficulty

local CybranBaseAir = BaseManager.CreateBaseManager()
local CybranBaseDopLand = BaseManager.CreateBaseManager()
local DefenseS = BaseManager.CreateBaseManager()
local CybranBaseFinal = BaseManager.CreateBaseManager()

function CybranAirBaseAI()
	CybranBaseAir:Initialize(ArmyBrains[Cybran], 'AirBase', 'Cybran_AirBase', 110, { AirBase_Factorys = 220})
    CybranBaseAir:StartEmptyBase(16, true)
	CybranBaseAir:SetMaximumConstructionEngineers(6)
	CybranBaseAir:AddBuildGroup('AirBaseStructures', 105)
	CybranBaseAir:AddBuildGroup('BuildFactory_D' .. Difficulty, 106)
	CybranBaseAir:AddBuildGroup('Dopfactory', 120)
	if(Difficulty == 3) then
		ScenarioFramework.CreateTimerTrigger(TMLStartBotAI, 5*60)
	end
	if(Difficulty == 3) then
		CybranBaseAir:AddBuildGroup('DefenseAirBase', 105)
		CybranBaseAir:AddBuildGroup('DopEnergy_D3', 106)
	end
	ScenarioUtils.CreateArmyGroup('Cybran', 'AirBase_Factorys')
	
	CybranBaseAir:SetActive('AirScouting', true)
	CybranBaseAir:SetActive('LandScouting', true)
	if(Difficulty >= 2) then
		CybranBaseDopLand:Initialize(ArmyBrains[Cybran], 'DopBase', 'Blank Marker 01', 40, { Dopfactory = 120})
		CybranBaseDopLand:StartEmptyBase(8, true)
		CybranBaseDopLand:AddBuildGroup('DefenseAirBase', 150)
		LandAttacksAILandBase()
	end
	AirPatrolsAI()
	AirAttacksAI()
	LandAttacksAI()
end


function AIDefense()
	DefenseS:Initialize(ArmyBrains[Cybran], 'DefensiveLine', 'Defensive_Line', 60, { DefensiveLineStructures = 100})
	DefenseS:SetActive('TML', true)
	DefenseS:AddBuildGroup('DefensiveLineWalls_D2', 98)
	if(Difficulty == 3) then
		DefenseS:AddBuildGroup('DefensiveLineMass', 94)
		DefenseS:AddBuildGroup('DefensiveLine', 120)
	end
	DefenseS:StartEmptyBase(3, true)
end

function TMLStartBotAI()
	CybranBaseAir:AddBuildGroup('TMLBase', 240)
	CybranBaseAir:SetActive('TML', true)
end

function LandAttacksAILandBase()
	local Temp = {
        'M1_Hard_LandBase_Attack_1',
        'NoPlan',   
        { 'url0107', 1, 8, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Hard_LandBase_Attack_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 95,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'DopBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MASSPRODUCTION * (categories.TECH1 + categories.TECH2)},
		},
    }
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'M1_Hard_LandBase_Attack_2',
        'NoPlan',   
        { 'url0106', 1, 12, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Hard_LandBase_Attack_Builder_2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 94,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'DopBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.LAND * categories.MOBILE },
		},
    }
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'M1_Hard_LandBase_Attack_3',
        'NoPlan',   
        { 'url0104', 1, 6, 'Attack', 'GrowthFormation' },
		{ 'url0103', 1, 4, 'Attack', 'GrowthFormation' },
		{ 'url0107', 1, 6, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Hard_LandBase_Attack_Builder_3',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 96,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'DopBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.AIR * categories.MOBILE + categories.LAND * categories.MOBILE },
		},
    }
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'M1_Hard_LandBase_Attack_4',
        'NoPlan',   
        { 'url0105', 1, 3, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Hard_LandBase_Attack_Builder_4',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 97,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'DopBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ALLUNITS - categories.WALL - (categories.MOBILE * categories.LAND) - categories.COMMAND},
		},
    }
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
end

function MainBaseAI()
	CybranBaseFinal:InitializeDifficultyTables(ArmyBrains[Cybran], 'Final_Base_Cybran', 'Cybran_MainBase', 160, {MainBase = 200})
	CybranBaseFinal:StartNonZeroBase(14, true)
	CybranBaseFinal:SetActive('AirScouting', true)
	CybranBaseFinal:SetActive('LandScouting', true)
	if(Difficulty == 3) then
		CybranBaseFinal:AddBuildGroup('Defense_Hard', 120)
		CybranBaseFinal:AddBuildGroup('AADefense', 118)
	end
	CybranBaseFinal:AddBuildGroup('GroundDefense_D' .. Difficulty, 120)
	CybranBaseFinal:AddBuildGroup('EnergyBaseAA', 119)
	AttackFinalBase()
end

function AttackFinalBase()
	local opai = nil
	local quantity = {}
	quantity = {2, 4, 6}
	local Temp = {
		'M3_Hunt_Unit_1',
		'NoPlan',   
		{ 'url0202', 1, quantity[Difficulty], 'Attack', 'GrowthFormation' },
		}
	local Builder = {
		BuilderName = 'M3_Hunt_Unit_Builder_1',
		PlatoonTemplate = Temp,
		InstanceCount = 1,
		Priority = 116,
		PlatoonType = 'Land',
		RequiresConstruction = true,
		LocationType = 'Final_Base_Cybran',
		PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
		PlatoonData = {
			CategoryList = { categories.ALLUNITS - categories.WALL },
		},
	}
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
		'M3_Hunt_Unit_2',
		'NoPlan',   
		{ 'url0107', 1, 8, 'Attack', 'GrowthFormation' },
		}
	local Builder = {
		BuilderName = 'M3_Hunt_Unit_Builder_2',
		PlatoonTemplate = Temp,
		InstanceCount = 1,
		Priority = 116,
		PlatoonType = 'Land',
		RequiresConstruction = true,
		LocationType = 'Final_Base_Cybran',
		PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
		PlatoonData = {
			CategoryList = { categories.ALLUNITS - categories.WALL },
		},
	}
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	local Temp = {
		'M3_Hunt_Unit_3',
		'NoPlan',   
		{ 'ura0103', 1, 3, 'Attack', 'GrowthFormation' },
		}
	local Builder = {
		BuilderName = 'M3_Hunt_Unit_Builder_3',
		PlatoonTemplate = Temp,
		InstanceCount = 1,
		Priority = 116,
		PlatoonType = 'Air',
		RequiresConstruction = true,
		LocationType = 'Final_Base_Cybran',
		PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
		PlatoonData = {
			CategoryList = { categories.ALLUNITS - categories.WALL - categories.AIR * categories.MOBILE },
		},
	}
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
		'M3_Hunt_Unit_4',
		'NoPlan',   
		{ 'ura0102', 1, 5, 'Attack', 'GrowthFormation' },
		}
	local Builder = {
		BuilderName = 'M3_Hunt_Unit_Builder_4',
		PlatoonTemplate = Temp,
		InstanceCount = 1,
		Priority = 116,
		PlatoonType = 'Air',
		RequiresConstruction = true,
		LocationType = 'Final_Base_Cybran',
		PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
		PlatoonData = {
			CategoryList = { categories.AIR * categories.MOBILE },
		},
	}
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
		'M3_Hunt_Unit_8',
		'NoPlan',   
		{ 'xra0105', 1, 7, 'Attack', 'GrowthFormation' },
		}
	local Builder = {
		BuilderName = 'M3_Hunt_Unit_Builder_8',
		PlatoonTemplate = Temp,
		InstanceCount = 1,
		Priority = 116,
		PlatoonType = 'Air',
		RequiresConstruction = true,
		LocationType = 'Final_Base_Cybran',
		PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
		PlatoonData = {
			CategoryList = { categories.LAND * categories.MOBILE + categories.STRUCTURE},
		},
	}
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	if(Difficulty == 3) then
		local Temp = {
			'M3_Hunt_Unit_9',
			'NoPlan',   
			{ 'ura0203', 1, 2, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M3_Hunt_Unit_Builder_9',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 117,
			PlatoonType = 'Air',
			RequiresConstruction = true,
			LocationType = 'Final_Base_Cybran',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.LAND * categories.MOBILE + categories.STRUCTURE },
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
	if(Difficulty >= 2) then
		local Temp = {
			'M3_Hunt_Unit_5',
			'NoPlan',   
			{ 'ura0103', 1, 7, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M3_Hunt_Unit_Builder_5',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 118,
			PlatoonType = 'Air',
			RequiresConstruction = true,
			LocationType = 'Final_Base_Cybran',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ENGINEER + categories.LAND * categories.ANTIAIR },
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
	local Temp = {
		'M3_Hunt_Unit_6',
		'NoPlan',   
		{ 'url0104', 1, 6, 'Attack', 'GrowthFormation' },
		}
	local Builder = {
		BuilderName = 'M3_Hunt_Unit_Builder_6',
		PlatoonTemplate = Temp,
		InstanceCount = 1,
		Priority = 121,
		PlatoonType = 'Land',
		RequiresConstruction = true,
		LocationType = 'Final_Base_Cybran',
		PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
		PlatoonData = {
			CategoryList = { categories.AIR * categories.MOBILE },
		},
	}
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	if(Difficulty >= 2) then
		local Temp = {
			'M3_Hunt_Unit_7',
			'NoPlan',   
			{ 'url0106', 1, 18, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M3_Hunt_Unit_Builder_7',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 119,
			PlatoonType = 'Land',
			RequiresConstruction = true,
			LocationType = 'Final_Base_Cybran',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.LAND * categories.MOBILE + categories.MASSPRODUCTION * categories.TECH1 },
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
	
	if(Difficulty >= 2) then
		local Temp = {
			'M3_Hunt_Unit_8',
			'NoPlan',   
			{ 'url0202', 1, 12, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M3_Hunt_Unit_Builder_8',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 121,
			PlatoonType = 'Land',
			RequiresConstruction = true,
			LocationType = 'Final_Base_Cybran',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.LAND * categories.MOBILE + categories.MASSPRODUCTION * categories.TECH1 },
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end

    opai = CybranBaseFinal:AddOpAI('BasicLandAttack', 'M3_Attacks_Bot_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'Research_Chain',
            },
            Priority = 120,
        }
    )
    opai:SetChildQuantity({'LightBots', 'LightTanks', 'HeavyTanks'}, {4, 4, 2})
	
	opai = CybranBaseFinal:AddOpAI('BasicLandAttack', 'M3_Attacks_Bot_2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'Research_Chain',
            },
            Priority = 130,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'HeavyTanks'}, {6, 4})
	
	local Temp = {
        'M3_Patrol_FinalAir_1',
        'NoPlan',   
        { 'xra0105', 1, 4, 'Attack', 'GrowthFormation' },
		{ 'ura0102', 1, 6, 'Attack', 'GrowthFormation' },
		{ 'ura0103', 1, 4, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M3_Patrol_Air_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 130,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'Final_Base_Cybran',
        PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread'},     
        PlatoonData = {
           PatrolChain = 'Final_Base_Air_Patrol',
       },
    }
    ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	if(Difficulty >= 2) then
		local Temp = {
			'M3_Patrol_FinalAir_2',
			'NoPlan',   
			{ 'xra0105', 1, 3, 'Attack', 'GrowthFormation' },
			{ 'ura0102', 1, 3, 'Attack', 'GrowthFormation' },
			{ 'ura0203', 1, 2, 'Attack', 'GrowthFormation' },
			{ 'ura0103', 1, 4, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M3_Patrol_Air_Builder_2',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 125,
			PlatoonType = 'Air',
			RequiresConstruction = true,
			LocationType = 'Final_Base_Cybran',
			PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread'},     
			PlatoonData = {
				PatrolChain = 'Final_Base_Air_Patrol',
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
end


function LandAttacksAI()
	local opai = nil
    local quantity = {}
	
	quantity = {4, 6, 12}
    opai = CybranBaseAir:AddOpAI('BasicLandAttack', 'M1_Attack_Bots_Land_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
			PlatoonData = {
                PatrolChain = 'Air_Base_Attack_Players_2',
            },
            Priority = 120,
        }
    )
    opai:SetChildQuantity('LightBots', quantity[Difficulty])
	
	local Temp = {
        'M1_Patrol_Bots_1',
        'NoPlan',   
        { 'url0202', 1, 2, 'Attack', 'GrowthFormation' },
		{ 'url0107', 1, 8, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Patrol_Land_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 120,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'AirBase',
        PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread'},     
        PlatoonData = {
           PatrolChain = 'AirBase_Chain',
       },
    }
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'M1_Hunt_unitX_1',
        'NoPlan',   
        { 'url0111', 1, 3, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Hunt_unitX_Land_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 125,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'AirBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MASSPRODUCTION * (categories.TECH1 + categories.TECH2)},
		},
    }
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	local Temp = {
        'M1_Hunt_unitX_3',
        'NoPlan',   
        { 'url0107', 1, 4, 'Attack', 'GrowthFormation' },
		{ 'url0103', 1, 4, 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Hunt_unitX_Land_Builder_3',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 130,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'AirBase',
        PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ENERGYPRODUCTION * categories.TECH1 + categories.MOBILE * categories.LAND},
		},
    }
	ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	if(Difficulty == 3) then
		quantity = {0, 4, 3}
		local Temp = {
			'M1_Hunt_Bomb_1',
			'NoPlan',   
			{ 'xrl0302', 1, quantity[Difficulty], 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M1_Hunt_Bomb_Builder_1',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 110,
			PlatoonType = 'Land',
			RequiresConstruction = true,
			LocationType = 'AirBase',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MASSPRODUCTION * (categories.TECH1 + categories.TECH2)},
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
		local Temp = {
			'M1_Hunt_Tank_1',
			'NoPlan',   
			{ 'url0202', 1, 4, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M1_Hunt_tank_Builder_1',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 120,
			PlatoonType = 'Land',
			RequiresConstruction = true,
			LocationType = 'AirBase',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.LAND * categories.MOBILE + categories.MASSPRODUCTION * (categories.TECH1 + categories.TECH2)},
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
		
		local Temp = {
			'M1_Hunt_TML_1',
			'NoPlan',   
			{ 'url0111', 1, 4, 'Attack', 'GrowthFormation' },
			{ 'url0202', 1, 2, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M1_Hunt_TML_Builder_1',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 115,
			PlatoonType = 'Land',
			RequiresConstruction = true,
			LocationType = 'AirBase',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MASSPRODUCTION * categories.TECH2 + categories.ENERGYPRODUCTION * categories.TECH1 + categories.LAND * (categories.TECH1 + categories.TECH2)},
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
	
	if(Difficulty == 3) then
		local Temp = {
			'M1_Defense_tankT2_1',
			'NoPlan',   
			{ 'url0202', 1, 6, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M1_T2_Tank_Defense_Builder_1',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 115,
			PlatoonType = 'Land',
			RequiresConstruction = true,
			LocationType = 'AirBase',
			PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread'},     
			PlatoonData = {
				PatrolChain = 'AirBase_Chain',
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
end

function AirAttacksAI()
	local opai = nil
    local quantity = {}
	
	quantity = {2, 3, 4}
    opai = CybranBaseAir:AddOpAI('AirAttacks', 'M1_Attacks_Bomber_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'Air_Base_Attack_Players_1',
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity('Bombers', quantity[Difficulty])
end

function AirPatrolsAI()
	local opai = nil
    local quantity = {}
	
	quantity = {3, 4, 6}
	local Temp = {
        'M1_Patrol_Gunship_1',
        'NoPlan',   
        { 'xra0105', 1, quantity[Difficulty], 'Attack', 'GrowthFormation' },
        }
    local Builder = {
        BuilderName = 'M1_Patrol_Air_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 110,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'AirBase',
        PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread'},     
        PlatoonData = {
           PatrolChain = 'AirBase_Chain',
       },
    }
    ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	
	quantity = {2, 6, 8}
    opai = CybranBaseAir:AddOpAI('AirAttacks', 'M1_Patrol_Gunship_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'Air_Base_Attack_Players_1',
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity('Bombers', quantity[Difficulty])
	
	if(Difficulty >= 2) then
		quantity = {0, 2, 4}
		local Temp = {
			'M1_Hunt_Gunship_1',
			'NoPlan',   
			{ 'ura0203', 1, quantity[Difficulty], 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M1_Hunt_Gunship_1',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 105,
			PlatoonType = 'Air',
			RequiresConstruction = true,
			LocationType = 'AirBase',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MASSPRODUCTION },
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
	
	if(Difficulty >= 2) then
		quantity = {0, 5, 7}
		local Temp = {
			'M1_Hunt_Bombers_1',
			'NoPlan',   
			{ 'ura0103', 1, 5, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M1_Hunt_Bombers_1',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 112,
			PlatoonType = 'Air',
			RequiresConstruction = true,
			LocationType = 'AirBase',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.ENERGYPRODUCTION },
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
		
		quantity = {0, 3, 6}
		local Temp = {
			'M1_Hunt_Bombers_2',
			'NoPlan',   
			{ 'ura0103', 1, 4, 'Attack', 'GrowthFormation' },
			}
		local Builder = {
			BuilderName = 'M1_Hunt_Bombers_2',
			PlatoonTemplate = Temp,
			InstanceCount = 1,
			Priority = 110,
			PlatoonType = 'Air',
			RequiresConstruction = true,
			LocationType = 'AirBase',
			PlatoonAIFunction = {SPAIFileName, 'CategoryHunterPlatoonAI'},     
			PlatoonData = {
				CategoryList = { categories.MOBILE * categories.LAND },
			},
		}
		ArmyBrains[Cybran]:PBMAddPlatoon( Builder )
	end
end
