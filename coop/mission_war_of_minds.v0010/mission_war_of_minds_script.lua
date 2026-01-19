local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local BaseManager = import('/lua/ai/opai/basemanager.lua')
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local Utilities = import('/lua/utilities.lua')
local TauntManager = import('/lua/TauntManager.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local Weather = import('/lua/weather.lua')
local Buff = import('/lua/sim/Buff.lua')
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
local Entity = import('/lua/sim/Entity.lua').Entity;
local EffectUtilities = import('/lua/effectutilities.lua')
local Cinematics = import('/lua/cinematics.lua')
local Explosions = import('/lua/defaultexplosions.lua')
local PingGroups = import('/lua/ScenarioFramework.lua').PingGroups
local Behaviors = import('/lua/ai/opai/OpBehaviors.lua')
local PrefetchUtils = import('/lua/sim/PrefetchUtilities.lua')
local AIUtils = import('/lua/AI/aiutilities.lua')

local ThisFile = '/maps/mission_war_of_minds.v0010/mission_war_of_minds_script.lua'

ScenarioInfo.Deads = 0
ScenarioInfo.PlayersRespawn = 0

ScenarioInfo.PointsN = {'Player2', 'Player3', 'Player4', 'Player5', 'Player6', 'Player7', 'Blank Marker 52', 'M3_QAI_NavalBase_Def2_1', 'Blank Marker 65', 'Blank Marker 11G'}

local CybranBotBase = BaseManager.CreateBaseManager()

local OpStrings = import('/maps/mission_war_of_minds.v0010/mission_war_of_minds_strings.lua')

local KillEXPPreArea2 = { {text = '<LOC X06_M01_012_010>[{i HQ}]: Атака была отбита, хорошая работа.', vid = 'X01_HQ_M01_04848.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'NONE'} }

local OnEasy = { {text = '<LOC X06_M01_012_010>[Игровой ИИ]: Сложность: Легкая. Будет достаточно легко проходить.', vid = 'X05_QAI_M02_03855.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'Cybran'} }
local OnMedium = { {text = '<LOC X06_M01_012_010>[Игровой ИИ]: Сложность: Средняя. Немного попотеть придется.', vid = 'X05_QAI_M02_03855.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'Cybran'} }
local OnHard = { {text = '<LOC X06_M01_012_010>[Игровой ИИ]: Сложность: Сложная. Придется сильно попоптеть, ожидайте почти всего от врага!', vid = 'X05_QAI_M02_03855.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'Cybran'} }
local OnNightmarish = { {text = '<LOC X06_M01_012_010>[Игровой ИИ]: Сложность: Кошмарная, Добро пожаловать в ад командующие хах ха! Враг все использует у себя.', vid = 'X05_QAI_M02_03855.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'Cybran'} }
local BaseOffHex5 = { {text = '<LOC X06_M01_012_010>[{i HQ}]: База была уничтожена, поздравляю командующие. Действуйте дальше. Конец связи.', vid = 'X01_HQ_M01_04848.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'NONE'} }
local KillACUsQAI = { {text = '<LOC X06_M01_012_010>[{i HQ}]: Отлично. БМК КИИ был уничтожен. Продвигайтесь дальше. Конец связи.', vid = 'X01_HQ_M01_04848.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'NONE'} }
local HEX5Target = { {text = '<LOC X05_M01_190_020>[{i HQ}]: You heard the old man, Commander. Destroy Hex5. HQ out.', vid = 'X05_HQ_M01_04439.sfd', bank = 'X05_VO', cue = 'X05_HQ_M01_04439', faction = 'NONE'} }
local HQACUsQAI = { {text = '<LOC X02_M03_120_010>[{i HQ}]: QAI\'s got a Cybran ACU in its base. Dunno if it\'s piloted or if it\'s simply being controlled by QAI. Regardless, you need to destroy it. HQ out.', vid = 'X02_HQ_M03_04310.sfd', bank = 'X02_VO', cue = 'X02_HQ_M03_04310', faction = 'NONE'}, }
local KillEXPHex5 = { {text = '<LOC X06_M01_012_010>[{i HQ}]: Пауки уничтожены, продвигайтесь дальше и уничтожьте базу противника.', vid = 'X01_HQ_M01_04848.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'NONE'} }
local Area2 = true

local Hex5DeadCDR = {
  {text = '<LOC X05_M02_200_009>[{i Hex5}]: Wait! Master!', vid = 'X05_Hex5_T01_04437.sfd', bank = 'X05_VO', cue = 'X05_Hex5_T01_04437', faction = 'Cybran'},
  {text = '<LOC X05_M02_200_010>[{i Brackman}]: And so a traitor dies. Oh yes. So much loss. So much sorrow.', vid = 'X05_Brackman_M02_03853.sfd', bank = 'X05_VO', cue = 'X05_Brackman_M02_03853', faction = 'Cybran'},
}

local UnitsMB1 = true
local UnitsMB2 = true
local UnitsMB3 = true
local UnitsMB4 = true



ScenarioInfo.Player1 = 1
ScenarioInfo.Player2 = 2
ScenarioInfo.Player3 = 3
ScenarioInfo.Player4 = 4
ScenarioInfo.Player5 = 5
ScenarioInfo.Player6 = 6
ScenarioInfo.Player7 = 7
ScenarioInfo.Bot = 8

local MOD = ScenarioInfo.Options.Mod

local Et = 0
local Enemy = ScenarioInfo.Player1
local Player2 = ScenarioInfo.Player2
local Player3 = ScenarioInfo.Player3
local Player4 = ScenarioInfo.Player4
local Player5 = ScenarioInfo.Player5
local Player6 = ScenarioInfo.Player6
local Player7 = ScenarioInfo.Player7

local CybranBot = ScenarioInfo.Bot

ScenarioInfo.KilledCDRs = 0
ScenarioInfo.NumsPl = 0
local Area1 = true

local Medium = false
local Hard = false
local Nightmarish = false
local ECO = true
local SpawnQAIBots = false
local AIBots = true
local SpawnENG = true

function OnPopulate()
    ScenarioUtils.InitializeScenarioArmies()
	ScenarioFramework.SetCybranEvilColor(Enemy)
	ScenarioFramework.SetCybranPlayerColor(CybranBot)
	local colors = {
		['Player2'] = {30, 170, 40}, 
		['Player3'] = {230, 230, 45}, 
        ['Player4'] = {20, 20, 240}, 
        ['Player5'] = {255, 191, 128}, 
        ['Player6'] = {139, 5, 255}, 
        ['Player7'] = {89, 133, 39},		
    }
    
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end
	if(MOD == 1) then
		if tblArmy[ScenarioInfo.Player2] then
		ScenarioFramework.AddRestriction(Player2, categories.url0002 + categories.urb2306 + categories.xab1401)
		end
		if tblArmy[ScenarioInfo.Player3] then
		ScenarioFramework.AddRestriction(Player3, categories.url0002 + categories.urb2306 + categories.xab1401)
		end
		if tblArmy[ScenarioInfo.Player4] then
		ScenarioFramework.AddRestriction(Player4, categories.url0002 + categories.urb2306 + categories.xab1401)
		end
		if tblArmy[ScenarioInfo.Player5] then
		ScenarioFramework.AddRestriction(Player5, categories.url0002 + categories.urb2306 + categories.xab1401)
		end
		if tblArmy[ScenarioInfo.Player6] then
		ScenarioFramework.AddRestriction(Player6, categories.url0002 + categories.urb2306 + categories.xab1401)
		end
		if tblArmy[ScenarioInfo.Player7] then
		ScenarioFramework.AddRestriction(Player7, categories.url0002 + categories.urb2306 + categories.xab1401)
		end
	end
    SetIgnorePlayableRect(Enemy, true)
end

function DifficultyIf1()
	ForkThread(DifficultyIf1_1)
end

function SpawnAllUnitsHex5()
	ScenarioInfo.sACU1 = CreateUnitHPR('url0301', 'Player1', 950, 30, 500, 0, 0, 0)
	ScenarioInfo.sACU2 = CreateUnitHPR('uel0301', 'Player1', 950, 30, 500, 0, 0, 0)
	ScenarioInfo.sACU3 = CreateUnitHPR('ual0301', 'Player1', 950, 30, 500, 0, 0, 0)
	ScenarioInfo.sACU4 = CreateUnitHPR('xsl0301', 'Player1', 950, 30, 500, 0, 0, 0)
	ScenarioInfo.sACU5 = CreateUnitHPR('url0301', 'Player1', 950, 30, 500, 0, 0, 0)
	ScenarioInfo.sACU6 = CreateUnitHPR('uel0301', 'Player1', 950, 30, 500, 0, 0, 0)
	ScenarioInfo.sACU7 = CreateUnitHPR('ual0301', 'Player1', 950, 30, 500, 0, 0, 0)
	ScenarioInfo.sACU8 = CreateUnitHPR('xsl0301', 'Player1', 950, 30, 500, 0, 0, 0)
	if(MOD == 1) then
		ScenarioInfo.RandomTP = {'TPACU', 'M1_FletcherBase_Eng_5', 'M1_Hex5_Main_LandAttack2_13', 'M2_Hex5_LandAttack_1_19', 'M1_Hex5_Main_AirAttack2_2', 'M1_Hex5_Res1_Def2_1', 'M3_QAI_ExpBase_Attack_18', 'M2_Hex5_LandAdapt_13'}
		ScenarioInfo.ACUQAI1 = CreateUnitHPR('url0002', 'Player1', 1016, 28, 282, 0, 0, 0)
		ScenarioInfo.ACUQAI1:SetCustomName(LOC '{i QAI}')
		Warp(ScenarioInfo.ACUQAI1, ScenarioUtils.MarkerToPosition('TPACU'))
		WaitSeconds(1)
		ScenarioInfo.ACUQAI2 = CreateUnitHPR('url0002', 'Player1', 1016, 28, 282, 0, 0, 0)
		ScenarioInfo.ACUQAI2:SetCustomName(LOC '{i QAI}')
		Warp(ScenarioInfo.ACUQAI2, ScenarioUtils.MarkerToPosition('TPACU'))
		WaitSeconds(1)
		ForkThread(ChechPlayerQAIACU)
	end
	WaitSeconds(1)
	WaitSeconds(2)
	ForkThread(SpawnEXPArea1)
	WaitSeconds(1)
	ForkThread(PatrolEXPArea1)
	WaitSeconds(1)
	ForkThread(BotBaseAI)
	if(Medium == true) then
		ScenarioFramework.CreateTimerTrigger(SpawnMediumUnits, 4*60)
	end
	if(Hard == true) then
		WaitSeconds(1)
		ScenarioFramework.CreateTimerTrigger(SpawnLAreaUnits, 5*60)
		WaitSeconds(4)
		ScenarioFramework.CreateTimerTrigger(Spawnhex5Transport, 32*60)
	end
end

function Spawnhex5Transport()
	if(Area1 == true) then
		local TransportsT1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'TransportXX', 'GrowthFormation')
		ScenarioFramework.PlatoonAttackWithTransports(TransportsT1, 'M2_Hex5_Transport_Landing_Chain', 'M2_Hex5_Transport_Attack_Chain', true)
		local TransportsT2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'TransportXX', 'GrowthFormation')
		ScenarioFramework.PlatoonAttackWithTransports(TransportsT2, 'M2_Hex5_Transport_Landing_Chain', 'M2_Hex5_Transport_Attack_Chain', true)
		ScenarioFramework.CreateTimerTrigger(Spawnhex5Transport, Random(70, 140))
	end
end


function SpawnMediumUnits()
	if(Area1 == true) then
		local RandomGroupAtMid = {'M1_Hex5_Attack_Mid1', 'M1_Hex5_Attack_Mid2', 'M1_Hex5_Attack_Mid3', 'M1_Hex5_Attack_Mid4', 'M1_Hex5_Attack_Mid5', 'M1_Hex5_Attack_Mid6'}
		local RandomChainGrMid = {'M1_Hex5_Main_LandAttack_1', 'M1_Hex5_Main_LandAttack_2', 'M1_Hex5_Main_LandAttack_3', 'M1_Hex5_Main_LandAttack_4', 'M1_Hex5_Resource1_Att1_Chain', 'M1_Hex5_Resource1_Att1b_Chain'}
		units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', RandomGroupAtMid[Random(1,6)], 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(units, RandomChainGrMid[Random(1,6)])
		ScenarioFramework.CreateTimerTrigger(SpawnMediumUnits, Random(42, 74))
	end
end

function SpawnLAreaUnits()
	if(Hard == true and Area1 == true ) then
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_DropArea'.. Random(1,4), 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_QAI_Main_Base_LandAttack_Chain')
		ScenarioFramework.CreateTimerTrigger(SpawnLAreaUnits, Random(24, 68))
	end
end

function MiniBase1Z()
	ScenarioFramework.CreateAreaTrigger(UnitsMB1F, ScenarioUtils.AreaToRect('MiniBase1'), categories.FACTORY, true, true, ArmyBrains[Enemy])
	ScenarioFramework.CreateAreaTrigger(UnitsMB2F, ScenarioUtils.AreaToRect('MiniBase2'), categories.FACTORY, true, true, ArmyBrains[Enemy])
	ScenarioFramework.CreateAreaTrigger(UnitsMB3F, ScenarioUtils.AreaToRect('MiniBase3'), categories.FACTORY, true, true, ArmyBrains[Enemy])
	ScenarioFramework.CreateAreaTrigger(UnitsMB4F, ScenarioUtils.AreaToRect('MiniBase4'), categories.FACTORY, true, true, ArmyBrains[Enemy])
end

function UnitsMB1F()
	UnitsMB1 = false
	local NUKEMB1 = CreateUnitHPR('urb2306', 'Player1', 963, 23, 587, 0, 0, 0)
	NUKEMB1:GiveNukeSiloAmmo(1)
	local NUKEMB5 = CreateUnitHPR('urb2306', 'Player1', 952, 23, 602, 0, 0, 0)
	NUKEMB5:GiveNukeSiloAmmo(1)
	WaitSeconds(2)
	IssueNuke({NUKEMB1}, ScenarioUtils.MarkerToPosition(ScenarioInfo.PointsN[Random(1,10)]))
	IssueNuke({NUKEMB5}, ScenarioUtils.MarkerToPosition(ScenarioInfo.PointsN[Random(1,10)]))
end

function UnitsMB2F()
	UnitsMB2 = false
	local NUKEMB2 = CreateUnitHPR('urb2306', 'Player1', 972, 23, 617, 0, 0, 0)
	NUKEMB2:GiveNukeSiloAmmo(5)
	WaitSeconds(2)
	IssueNuke({NUKEMB2}, ScenarioUtils.MarkerToPosition(ScenarioInfo.PointsN[Random(1,10)]))
end

function UnitsMB3F()
	UnitsMB3 = false
	local NUKEMB3 = CreateUnitHPR('urb2306', 'Player1', 957, 23, 595, 0, 0, 0)
	NUKEMB3:GiveNukeSiloAmmo(1)
	WaitSeconds(2)
	IssueNuke({NUKEMB3}, ScenarioUtils.MarkerToPosition(ScenarioInfo.PointsN[Random(1,10)]))
end

function UnitsMB4F()
	UnitsMB4 = false
	local NUKEMB4 = CreateUnitHPR('urb2306', 'Player1', 956, 23, 630, 0, 0, 0)
	NUKEMB4:GiveNukeSiloAmmo(1)
	WaitSeconds(2)
	IssueNuke({NUKEMB4}, ScenarioUtils.MarkerToPosition(ScenarioInfo.PointsN[Random(1,10)]))
end

function LosePlayers()
	if(ScenarioInfo.KilledCDRs == ScenarioInfo.NumsPl) then
		ScenarioFramework.PlayerLose()
	end
end

function BotBaseAI()
    CybranBotBase:Initialize(ArmyBrains[CybranBot], 'Bot_Base', 'BotBase', 150, {InBase = 100})
    CybranBotBase:StartEmptyBase(8, true)
    CybranBotBase:SetActive('AirScouting', true)
    CybranBotBase:SetSupportACUCount(1)
    CybranBotBase:SetSACUUpgrades({'ResourceAllocation', 'DisintigratorGun', 'Switchback'})    
	ScenarioUtils.CreateArmyGroup( 'BotAreas', 'Engineers' )
    CybranBotBase:AddBuildGroup('B1', 95)
	CybranBotBase:AddBuildGroup('B2', 94)
	CybranBotBase:AddBuildGroup('B3', 92)
	
	ForkThread(BuildBotUnits)
	ForkThread(BuildEXPBot)
end

function BuildEXPBot()
	opai = CybranBotBase:AddOpAI('BotLandExp1',
        {
            Amount = 2,
            KeepAlive = true,
            PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
			PlatoonData = {
				MoveRoute = {'Blank Marker 119'},
				PatrolChain = 'PatrolUnitsBotPlayer',
			},
            MaxAssist = 2,
            Retry = true,
			Priority = 97,
        }
    )
	opai = CybranBotBase:AddOpAI('BotLandExp1',
        {
            Amount = 4,
            KeepAlive = true,
            PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
			PlatoonData = {
				MoveRoute = {'Blank Marker 119'},
				PatrolChain = 'PatrolUnitsBotPlayer',
			},
            MaxAssist = 3,
            Retry = true,
			Priority = 97,
        }
    )
	opai = CybranBotBase:AddOpAI('BotLandExp2',
        {
            Amount = 2,
            KeepAlive = true,
            PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
			PlatoonData = {
				MoveRoute = {'Blank Marker 119'},
				PatrolChain = 'PatrolUnitsBotPlayer',
			},
            MaxAssist = 23,
            Retry = true,
			Priority = 97,
        }
    )
	opai = CybranBotBase:AddOpAI('BotAirExp',
        {
            Amount = 3,
            KeepAlive = true,
            PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
			PlatoonData = {
				MoveRoute = {'Blank Marker 119'},
				PatrolChain = 'PatrolUnitsBotPlayer',
			},
            MaxAssist = 4,
            Retry = true,
			Priority = 94,
        }
    )
end

function BuildBotUnits()
	local Temp = {
        'M1_Bot_Units1',
        'NoPlan',
		{ 'url0303', 1, 12, 'Attack', 'AttackFormation' },
    }
    local Builder = {
        BuilderName = 'M1_Bot_Units1_Builder',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 90,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'Bot_Base',
        PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
		PlatoonData = {
            MoveRoute = {'Blank Marker 119'},
			PatrolChain = 'PatrolUnitsBotPlayer',
        },
    }
    ArmyBrains[CybranBot]:PBMAddPlatoon(Builder)
	
	local Temp = {
        'M1_Bot_Units2',
        'NoPlan',
		{ 'url0202', 1, 6, 'Attack', 'AttackFormation' },
		{ 'url0303', 1, 8, 'Attack', 'AttackFormation' },
    }
    local Builder = {
        BuilderName = 'M1_Bot_Units2_Builder',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 90,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'Bot_Base',
        PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
		PlatoonData = {
            MoveRoute = {'Blank Marker 119'},
			PatrolChain = 'PatrolUnitsBotPlayer',
        },
    }
    ArmyBrains[CybranBot]:PBMAddPlatoon(Builder)
	
	local Temp = {
        'M1_Bot_Units3',
        'NoPlan',
		{ 'dra0202', 1, 5, 'Attack', 'AttackFormation' },
		{ 'ura0203', 1, 5, 'Attack', 'AttackFormation' },
    }
    local Builder = {
        BuilderName = 'M1_Bot_Units3_Builder',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 93,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'Bot_Base',
        PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
		PlatoonData = {
            MoveRoute = {'Blank Marker 119'},
			PatrolChain = 'PatrolUnitsBotPlayer',
        },
    }
    ArmyBrains[CybranBot]:PBMAddPlatoon(Builder)
	
	local Temp = {
        'M1_Bot_Units4',
        'NoPlan',
		{ 'ura0103', 1, 10, 'Attack', 'AttackFormation' },
    }
    local Builder = {
        BuilderName = 'M1_Bot_Units4_Builder',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 92,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'Bot_Base',
        PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
		PlatoonData = {
            MoveRoute = {'Blank Marker 119'},
			PatrolChain = 'PatrolUnitsBotPlayer',
        },
    }
    ArmyBrains[CybranBot]:PBMAddPlatoon(Builder)
	
	local Temp = {
        'M1_Bot_Units5',
        'NoPlan',
		{ 'ura0102', 1, 10, 'Attack', 'AttackFormation' },
    }
    local Builder = {
        BuilderName = 'M1_Bot_Units5_Builder',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 92,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'Bot_Base',
        PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
		PlatoonData = {
            MoveRoute = {'Blank Marker 119'},
			PatrolChain = 'PatrolUnitsBotPlayer',
        },
    }
    ArmyBrains[CybranBot]:PBMAddPlatoon(Builder)

	local Temp = {
        'M1_Bot_Units6',
        'NoPlan',
		{ 'url0301_cloak', 1, 1, 'Attack', 'AttackFormation' },
    }
    local Builder = {
        BuilderName = 'M1_Bot_Units6_Builder',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 97,
        PlatoonType = 'Gate',
        RequiresConstruction = true,
        LocationType = 'Bot_Base',
        PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
		PlatoonData = {
            MoveRoute = {'Blank Marker 119'},
			PatrolChain = 'PatrolUnitsBotPlayer',
        },
    }
    ArmyBrains[CybranBot]:PBMAddPlatoon(Builder)

	local Temp = {
        'M1_Bot_Units7',
        'NoPlan',
		{ 'url0301_engineer', 1, 1, 'Attack', 'AttackFormation' },
    }
    local Builder = {
        BuilderName = 'M1_Bot_Units7_Builder',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 97,
        PlatoonType = 'Gate',
        RequiresConstruction = true,
        LocationType = 'Bot_Base',
        PlatoonAIFunction = {ThisFile, 'GivePlayerUnits'},
		PlatoonData = {
            MoveRoute = {'Blank Marker 119'},
			PatrolChain = 'PatrolUnitsBotPlayer',
        },
    }
    ArmyBrains[CybranBot]:PBMAddPlatoon(Builder)
end

function GivePlayerUnits(platoon)
    local givenUnits = {}
	local data = platoon.PlatoonData

    if not data then
        error('*MoveAndGivePlatoonToPlayer: PlatoonData not defined', 2)
    elseif not (data.MoveRoute or data.MoveChain) then
        error('*MoveAndGivePlatoonToPlayer: MoveToRoute or MoveChain not defined', 2)
    end

    local movePositions = {}
    if data.MoveChain then
        movePositions = ScenarioUtils.ChainToPositions(data.MoveChain)
    else
        for _, v in data.MoveRoute do
            if type(v) == 'string' then
                table.insert(movePositions, ScenarioUtils.MarkerToPosition(v))
            else
                table.insert(movePositions, v)
            end
        end
    end

    for _, v in movePositions do
        platoon:MoveToLocation(v, false)
    end

    WaitSeconds(1)

    for _, unit in platoon:GetPlatoonUnits() do
		while (not unit.Dead and unit:IsUnitState('Moving')) do
            WaitSeconds(1)
        end

        local tempUnit = ScenarioFramework.GiveUnitToArmy(unit, 'Player1')
        table.insert(givenUnits, tempUnit)
    end
	
	if data.PatrolChain then
        ScenarioFramework.GroupPatrolChain(givenUnits, data.PatrolChain)
    end
end
function SpawnEXPArea1()
	local Hex5LandEXPP = ArmyBrains[Enemy]:MakePlatoon('', '')
	for i = 1, Random(2, 5) do
		EXP = CreateUnitHPR('url0402', 'Player1', 832, 24, 484, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5LandEXPP, {EXP}, 'attack', 'GrowthFormation')
	end
	
	for k, v in Hex5LandEXPP:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5Def_EXP_Chain')))
	end
end

function PatrolEXPArea1()
	local Hex5LandEXPPat = ArmyBrains[Enemy]:MakePlatoon('', '')
	for i = 1, Random(1, 2) do
		EXP = CreateUnitHPR('url0402', 'Player1', 759, 24, 590, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5LandEXPPat, {EXP}, 'attack', 'GrowthFormation')
	end
	
	for k, v in Hex5LandEXPPat:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Patrol_hard_Hex5')))
	end
end

function ChechPlayerQAIACU()
	ScenarioFramework.CreateArmyIntelTrigger( DopZDKILLACU1, ArmyBrains[Player2], 'LOSNow', false, true, categories.url0002, true, ArmyBrains[Enemy] )
	ScenarioFramework.CreateArmyIntelTrigger( DopZDKILLACU3, ArmyBrains[Player2], 'LOSNow', false, true, categories.url0402, true, ArmyBrains[Enemy] )
	WaitSeconds(3)
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttackLandT1, 5*60 )
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttackLandT2B2, 8*60 )
	WaitSeconds(4)
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttackAir, 13*60)
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttackLightAir, 9*60)
	WaitSeconds(2)
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttackAirT3, 22*60 )
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttackExperemental, 36*60 )
	
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttackCirposh, 19*60 )
	ScenarioFramework.CreateTimerTrigger( SpawnArea1AttacksACUs, 40*60 )
end

function SpawnArea1AttackCirposh()
	if(Area1 == true) then
		local RandomChainsHeavy = {'M1_Hex5_T3Heavy_Land1_Chain','M1_Hex5_T3Heavy_Land2_Chain'}
		local Hex5T3Heavyland = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		for i = 1, Random(8,12) do
			unit = CreateUnitHPR( 'xrl0305', 'Player1', 804.5, 23.10346, 567.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5T3Heavyland, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5T3Heavyland, RandomChainsHeavy[Random(1,2)])
		ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackCirposh, 50)
	end
end

function SpawnArea1AttacksACUs()
	if(Area1 == true) then
		local RandomChainsHeavy = {'M1_Hex5_T3Heavy_Land1_Chain','M1_Hex5_T3Heavy_Land2_Chain'}
		local Hex5sACUs = ArmyBrains[Enemy]:MakePlatoon('', '')
		local randomsACU = {'uel0301','ual0301','url0301','xsl0301'}
		local unit = false
		for i = 1, Random(1,5) do
			unit = CreateUnitHPR( randomsACU[Random(1,4)], 'Player1', 812.5, 23.10346, 584.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5T3Heavyland, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.CreateTimerTrigger(SpawnArea1AttacksACUs, 75)
	end
end


local ATTACK_WAVESLand = {
    {
        units = {
            {id = 'url0106', count = {3, 8}}
        },
        spawn = {475, 23, 546.5},
        chain = 'M1_Hex5_AttackMiniBase1_Chain'
    },
    {
        units = {
            {id = 'url0107', count = {4, 8}},
			{id = 'url0103', count = {2, 4}}
        },
        spawn = {475, 23, 546.5},
        chain = 'M1_Hex5_AttackMiniBase1_Chain'
    },
	{
        units = {
            {id = 'url0107', count = {3, 9}},
			{id = 'url0106', count = {3, 7}}
        },
        spawn = {475, 23, 546.5},
        chain = 'M1_Hex5_AttackMiniBase1_Chain'
    },
	{
        units = {
            {id = 'url0104', count = {2, 6}},
			{id = 'url0103', count = {3, 7}}
        },
        spawn = {475, 23, 546.5},
        chain = 'M1_Hex5_AttackMiniBase1_Chain'
    },
}

local function CreateUnitGroup(platoon, unitId, count, spawnPos, enemyBrain)
	for i = 1, count do
		local unit = CreateUnitHPR(unitId, 'Player1', spawnPos[1], spawnPos[2], spawnPos[3], 0, 0, 0)
		enemyBrain:AssignUnitsToPlatoon(platoon, {unit}, 'attack', 'GrowthFormation')
	end
end

function SpawnArea1AttackLandT1()
    if not UnitsMB1 then return end
	
	
    local enemyBrain = ArmyBrains[Enemy]
    local waveIndex = Random(1, 4)
    local waveConfig = ATTACK_WAVESLand[waveIndex]
    
    local Mini1LandAttackPlatoon = enemyBrain:MakePlatoon('', '')    
    for _, unitConfig in ipairs(waveConfig.units) do
        local unitCount = Random(unitConfig.count[1], unitConfig.count[2])
        CreateUnitGroup(Mini1LandAttackPlatoon, unitConfig.id, unitCount, waveConfig.spawn, enemyBrain)
    end
    ScenarioFramework.PlatoonPatrolChain(Mini1LandAttackPlatoon, waveConfig.chain)
    
    ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackLandT1, 45)
end


local ATTACK_WAVESLandT3 = {
    {
        units = {
            {id = 'url0303', count = {4, 8}}
        },
        spawn = {795, 23, 562.5},
        chain = 'M1_Hex5_Main_LandAttack_2'
    },
    {
        units = {
            {id = 'url0303', count = {4, 8}},
			{id = 'xrl0305', count = {2, 4}}
        },
        spawn = {795, 23, 562.5},
        chain = 'M1PatrolChain6'
    },
	{
        units = {
            {id = 'drlk0001', count = {4, 6}},
			{id = 'url0303', count = {4, 8}}
        },
        spawn = {795, 23, 562.5},
        chain = 'QAIAttackChain'
    },
	{
        units = {
            {id = 'url0304', count = {3, 5}},
			{id = 'url0303', count = {6, 12}}
        },
        spawn = {795, 23, 562.5},
        chain = 'QAIAttackChain'
    },
	{
        units = {
            {id = 'url0305', count = {2, 4}},
			{id = 'url0304', count = {2, 4}}
        },
        spawn = {795, 23, 562.5},
        chain = 'M1_Hex5_Main_LandAttack_4'
    },
	{
        units = {
            {id = 'url0303', count = {4, 8}},
			{id = 'url0305', count = {3, 8}}
        },
        spawn = {795, 23, 562.5},
        chain = 'M1_Attack_Hex5T3_Land_Chain'
    },
}

local function CreateUnitGroupT3(platoon, unitId, count, spawnPos, enemyBrain)
	for i = 1, count do
		local unit = CreateUnitHPR(unitId, 'Player1', spawnPos[1], spawnPos[2], spawnPos[3], 0, 0, 0)
		enemyBrain:AssignUnitsToPlatoon(platoon, {unit}, 'attack', 'GrowthFormation')
	end
end

function SpawnArea1AttackLandT3()
    if not Area1 then return end
    local enemyBrain = ArmyBrains[Enemy]
    local waveIndex = Random(1, 6)
    local waveConfig = ATTACK_WAVESLandT3[waveIndex]
    
    local landGBaseAttackPlatoon = enemyBrain:MakePlatoon('', '')    
    for _, unitConfig in ipairs(waveConfig.units) do
        local unitCount = Random(unitConfig.count[1], unitConfig.count[2])
        CreateUnitGroupT3(landGBaseAttackPlatoon, unitConfig.id, unitCount, waveConfig.spawn, enemyBrain)
    end
    ScenarioFramework.PlatoonPatrolChain(landGBaseAttackPlatoon, waveConfig.chain)
    
    ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackLandT3, Random(45, 80))
end

local ATTACK_WAVESLand2 = {
    {
        units = {
            {id = 'url0202', count = {4, 6}},
			{id = 'url0203', count = {2, 6}}
        },
        spawn = {473, 23, 740.5},
        chain = 'M1_AttackMinibase2_Chain'
    },
    {
        units = {
            {id = 'url0202', count = {4, 8}},
			{id = 'url0111', count = {4, 6}}
        },
        spawn = {473, 23, 740.5},
        chain = 'M1_AttackMinibase2_Chain'
    },
	{
        units = {
            {id = 'url0103', count = {4, 8}},
			{id = 'url0202', count = {4, 6}},
			{id = 'url0107', count = {6, 8}}
        },
        spawn = {473, 23, 740.5},
        chain = 'M1_AttackMinibase2_Chain'
    },
}

local function CreateUnitGroup2(platoon, unitId, count, spawnPos, enemyBrain)
	for i = 1, count do
		local unit = CreateUnitHPR(unitId, 'Player1', spawnPos[1], spawnPos[2], spawnPos[3], 0, 0, 0)
		enemyBrain:AssignUnitsToPlatoon(platoon, {unit}, 'attack', 'GrowthFormation')
	end
end

function SpawnArea1AttackLandT2B2()
    if not UnitsMB2 then return end
	
	
    local enemyBrain = ArmyBrains[Enemy]
    local waveIndex = Random(1, 3)
    local waveConfig = ATTACK_WAVESLand2[waveIndex]
    
    local Mini2LandAttackPlatoon = enemyBrain:MakePlatoon('', '')    
    for _, unitConfig in ipairs(waveConfig.units) do
        local unitCount = Random(unitConfig.count[1], unitConfig.count[2])
        CreateUnitGroup(Mini2LandAttackPlatoon, unitConfig.id, unitCount, waveConfig.spawn, enemyBrain)
    end
    ScenarioFramework.PlatoonPatrolChain(Mini2LandAttackPlatoon, waveConfig.chain)
    
    ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackLandT2B2, 45)
end

function DopZDKILLACU1()
	ScenarioFramework.Dialogue(HQACUsQAI)
	ScenarioFramework.CreateTimerTrigger(DopZDKILLACU2, 8)
end

function DopZDKILLACU2()
	ScenarioInfo.D1KQ = Objectives.CategoriesInArea(
        'secondary',
        'incomplete',
        'БМК КИИ',
        'КИИ использует бмк кибран, что бы оборонять позиции Хекс5. Уничтожьте все бмк КИИ в области',
		'kill',
        {                               
            MarkUnits = true,
            Requirements = {
                {
                    Area = 'Area1',
                    Category = (categories.url0002),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Enemy,
                },
            },
        }
    )
	ScenarioInfo.D1KQ:AddResultCallback(
        function(result)
            if(result) then
				ScenarioFramework.Dialogue(KillACUsQAI)
            end
        end
    )
end

function DopZDKILLACU3()
	ScenarioInfo.D2KQ = Objectives.CategoriesInArea(
        'secondary',
        'incomplete',
        'Эксперементальные пауки',
        'Хекс5 использует пауков что бы оборонятся от вас.. Уничтожьте всех пауков в облости, что бы уничтожить базу Хекс5.',
		'kill',
        {                               
            MarkUnits = true,
            Requirements = {
                {
                    Area = 'Area1',
                    Category = (categories.url0402),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Enemy,
                },
            },
        }
    )
	ScenarioInfo.D2KQ:AddResultCallback(
        function(result)
            if(result) then
				ScenarioFramework.Dialogue(KillEXPHex5)
            end
        end
    )
end

function OnShiftF3()
    ForkThread(SpawnCDRCybranArea1)
end

function SpawnCDRCybranArea1()
	if( ArmyBrains[Enemy].Nickname == 'Armagedon3113') then
	ScenarioInfo.ACUQAI = CreateUnitHPR('url0002', 'Player1', 1016, 32, 360, 0, 0, 0)
	ScenarioInfo.ACUQAI:SetCustomName(LOC '{i QAI}')
	WaitSeconds(2)
	Warp(ScenarioInfo.ACUQAI, ScenarioUtils.MarkerToPosition(ScenarioInfo.RandomTP[Random(1,8)]))
	else
		ScenarioFramework.SimAnnouncement('Извиняемся, но это вам недоступно.')
	end
end

function CapArea1Players1()
	local tblArmy = ListArmies()
	if tblArmy[ScenarioInfo.Player2] then
	SetArmyUnitCap(Player2, 600)
	end
	if tblArmy[ScenarioInfo.Player3] then
	SetArmyUnitCap(Player3, 600)
	end
	if tblArmy[ScenarioInfo.Player4] then
	SetArmyUnitCap(Player4, 600)
	end
	if tblArmy[ScenarioInfo.Player5] then
	SetArmyUnitCap(Player5, 600)
	end
	if tblArmy[ScenarioInfo.Player6] then
	SetArmyUnitCap(Player6, 600)
	end
	if tblArmy[ScenarioInfo.Player7] then
	SetArmyUnitCap(Player7, 600)
	end
	SetArmyUnitCap(Enemy, 2000)
	SetArmyUnitCap(CybranBot, 1200)
end

function CapArea1Players2()
	local tblArmy = ListArmies()
	if tblArmy[ScenarioInfo.Player2] then
	SetArmyUnitCap(Player2, 900)
	end
	if tblArmy[ScenarioInfo.Player3] then
	SetArmyUnitCap(Player3, 900)
	end
	if tblArmy[ScenarioInfo.Player4] then
	SetArmyUnitCap(Player4, 900)
	end
	if tblArmy[ScenarioInfo.Player5] then
	SetArmyUnitCap(Player5, 900)
	end
	if tblArmy[ScenarioInfo.Player6] then
	SetArmyUnitCap(Player6, 900)
	end
	if tblArmy[ScenarioInfo.Player7] then
	SetArmyUnitCap(Player7, 900)
	end
end

function CapArea1Players3()
	local tblArmy = ListArmies()
	if tblArmy[ScenarioInfo.Player2] then
	SetArmyUnitCap(Player2, 1000)
	end
	if tblArmy[ScenarioInfo.Player3] then
	SetArmyUnitCap(Player3, 1000)
	end
	if tblArmy[ScenarioInfo.Player4] then
	SetArmyUnitCap(Player4, 1000)
	end
	if tblArmy[ScenarioInfo.Player5] then
	SetArmyUnitCap(Player5, 1000)
	end
	if tblArmy[ScenarioInfo.Player6] then
	SetArmyUnitCap(Player6, 1000)
	end
	if tblArmy[ScenarioInfo.Player7] then
	SetArmyUnitCap(Player7, 1000)
	end
end

function DifficultyIf1_1()
	WaitSeconds(3)
	ForkThread(DifficultyIf2)
end

function OnStart(self)
	ForkThread(DifficultyIf1)
	ForkThread(SpawnComs)
	ForkThread(EcoStart)
end

function EcoStart()
	ArmyBrains[Enemy]:GiveStorage('ENERGY', 1000000)
    while(ECO == true) do
        ArmyBrains[Enemy]:GiveResource('MASS', 20000)
        ArmyBrains[Enemy]:GiveResource('ENERGY', 30000)
        WaitSeconds(2)
    end
end

function SpawnComs()
	ForkThread(StartGame)
end

function StartGame()
	WaitSeconds(1)
	ScenarioFramework.SetPlayableArea('Area1', false)
	WaitSeconds(1)
	local tblArmy = ListArmies()
	if tblArmy[ScenarioInfo.Player2] then
		SpawnCom(2)
		ScenarioInfo.NumsPl = 1
	end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player3] then
		SpawnCom(3)
		ScenarioInfo.NumsPl = 2
	end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player4] then
		SpawnCom(4)
		ScenarioInfo.NumsPl = 3
	end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player5] then
		SpawnCom(5)
		ScenarioInfo.NumsPl = 4
	end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player6] then
		SpawnCom(6)
		ScenarioInfo.NumsPl = 5
	end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player7] then
		SpawnCom(7)
		ScenarioInfo.NumsPl = 6
	end
	WaitSeconds(1)
	ForkThread(CapArea1Players1)
	WaitSeconds(4)
	ForkThread(SpawnArea1PatrolAir)
end

function SpawnArea1AttackLightAir()
	if(Area1 == true and UnitsMB3 == true) then
		local Hex5AirT1Attack = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		if(Random(1,7) == 1) then
		for i = 1, Random(6,9) do
			unit = CreateUnitHPR( 'ura0102', 'Player1', 769, 24.10346, 547.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirT1Attack, 'M1_Hex5_Air_Attacks1_Chain')
		elseif(Random(1,7) == 2) then
		for i = 1, Random(3,8) do
			unit = CreateUnitHPR( 'xra0105', 'Player1', 632, 33.10346, 514, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirT1Attack, 'M1_Hex5_Air_Attacks2_Chain')
		elseif(Random(1,7) == 3) then
		for i = 1, Random(2,6) do
			unit = CreateUnitHPR( 'ura0103', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(4,9) do
			unit = CreateUnitHPR( 'ura0102', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirT1Attack, 'M1_Hex5_Air_Attacks3_Chain')
		elseif(Random(1,7) == 4) then
		for i = 1, Random(3,6) do
			unit = CreateUnitHPR( 'ura0103', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR( 'ura0102', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirT1Attack, 'M1_Hex5_Air_Attacks4_Chain')
		elseif(Random(1,7) == 5) then
		for i = 1, Random(4,7) do
			unit = CreateUnitHPR( 'ura0103', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,7) do
			unit = CreateUnitHPR( 'xra0105', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirT1Attack, 'M1_Hex5_Air_Attacks5_Chain')
		elseif(Random(1,7) == 6) then
		for i = 1, Random(3,6) do
			unit = CreateUnitHPR( 'ura0102', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(4,8) do
			unit = CreateUnitHPR( 'ura0103', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirT1Attack, 'M1_Hex5_Air_Attacks3_Chain')
		elseif(Random(1,7) == 7) then
		for i = 1, Random(4,7) do
			unit = CreateUnitHPR( 'xra0105', 'Player1', 684, 32.10346, 542, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(3,9) do
			unit = CreateUnitHPR( 'ura0102', 'Player1', 684, 32.10346, 542, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirT1Attack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirT1Attack, 'M1_Hex5_Air_Attacks2_Chain')
		end
		ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackLightAir, 25)
	end
end


function SpawnArea1AttackAir()
	if(Area1 == true and UnitsMB4 == true) then
		local Hex5AirAttack = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		if(Random(1,6) == 1) then
		for i = 1, Random(3,8) do
			unit = CreateUnitHPR( 'ura0203', 'Player1', 769, 24.10346, 547.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks1_Chain')
		elseif(Random(1,6) == 2) then
		for i = 1, Random(3,8) do
			unit = CreateUnitHPR( 'ura0203', 'Player1', 632, 33.10346, 514, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks2_Chain')
		elseif(Random(1,6) == 3) then
		for i = 1, Random(3,12) do
			unit = CreateUnitHPR( 'ura0103', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,8) do
			unit = CreateUnitHPR( 'ura0203', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks3_Chain')
		elseif(Random(1,6) == 4) then
		for i = 1, Random(3,6) do
			unit = CreateUnitHPR( 'dra0202', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(7,12) do
			unit = CreateUnitHPR( 'ura0102', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks4_Chain')
		elseif(Random(1,6) == 5) then
		for i = 1, Random(2,5) do
			unit = CreateUnitHPR( 'ura0203', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,5) do
			unit = CreateUnitHPR( 'dra0202', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks5_Chain')
		elseif(Random(1,6) == 6) then
		for i = 1, Random(2,5) do
			unit = CreateUnitHPR( 'ura0203', 'Player1', 802, 24.10346, 562, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(3,8) do
			unit = CreateUnitHPR( 'ura0103', 'Player1', 802, 24.10346, 562, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks3_Chain')
		end
		ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackAir, 32)
	end
end

function SpawnArea1AttackAirT3()
	if(Area1 == true and UnitsMB4 == true) then
		local Hex5AirAttackT3 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		if(Random(1,3) == 1) then
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR( 'ura0303', 'Player1', 769, 24.10346, 547.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttackT3, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR( 'xra0305', 'Player1', 769, 24.10346, 547.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttackT3, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttackT3, 'M1_Hex5_Air_Attacks1_Chain')
		elseif(Random(1,3) == 2) then
		for i = 1, Random(2,6) do
			unit = CreateUnitHPR( 'ura0304', 'Player1', 632, 33.10346, 514, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttackT3, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttackT3, 'M1_Hex5_Air_Attacks2_Chain')
		elseif(Random(1,3) == 3) then
		for i = 1, Random(4,8) do
			unit = CreateUnitHPR( 'ura0203', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttackT3, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(3,6) do
			unit = CreateUnitHPR( 'ura0303', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttackT3, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttackT3, 'M1_Hex5_Air_Attacks3_Chain')
		end
		ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackAirT3, 50)
	end
end

function SpawnArea1AttackExperemental()
	if(Area1 == true) then
		local Hex5ExperementalAtA1 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		if(Random(1,3) == 1) then
		for i = 1, Random(1,2) do
			unit = CreateUnitHPR( 'url0402', 'Player1', 802.5, 23.10346, 560.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5ExperementalAtA1, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5ExperementalAtA1, 'M1_Hex5_Air_Attacks1_Chain')
		elseif(Random(1,3) == 2) then
		for i = 1, Random(1,2) do
			unit = CreateUnitHPR( 'ura0401', 'Player1', 802.5, 23.10346, 560.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5ExperementalAtA1, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5ExperementalAtA1, 'M1_Hex5_Air_Attacks2_Chain')
		elseif(Random(1,3) == 3) then
		for i = 1, Random(1,2) do
			unit = CreateUnitHPR( 'xrl0403', 'Player1', 802.5, 23.10346, 560.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5ExperementalAtA1, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5ExperementalAtA1, 'M1_Hex5_Air_Attacks3_Chain')
		end
		ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackExperemental, 2*60)
	end
end

function SpawnArea1PatrolAir()
	local hex5Area1patrol = ArmyBrains[Enemy]:MakePlatoon('', '')
	local unit = false
	local UnitsAirFinal = {'ura0101', 'ura0102', 'ura0103', 'xra0105', 'ura0203', 'ura0103', 'ura0303', 'ura0302', 'ura0203', 'ura0203'}
	-- T1
	for i = 1, 42 do
		unit = CreateUnitHPR( UnitsAirFinal[Random(1,10)], 'Player1', 748, 26.10346, 536.5, 0, 0, 0 )
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(hex5Area1patrol, {unit}, 'attack', 'GrowthFormation')
	end
	
	if(Hard == true) then
		for i = 1, 36 do
			unit = CreateUnitHPR( UnitsAirFinal[Random(1,10)], 'Player1', 748, 26.10346, 536.5, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(hex5Area1patrol, {unit}, 'attack', 'GrowthFormation')
		end
	end
	
	for k, v in hex5Area1patrol:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_SpawnAir_Patrolhex5_Chain')))
	end
end


function SpawnAirScoutHex5Ar1()
	local Hex5AirScout = ArmyBrains[Enemy]:MakePlatoon('', '')
	if (Area1 == true) then
		local unit = false
		
		if(Random(1,2) == 1) then
			for i = 1, Random(2,4) do
				unit = CreateUnitHPR( 'ura0101', 'Player1', 764, 28.10, 556.5, 0, 0, 0 )
				ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirScout, {unit}, 'attack', 'GrowthFormation')
			end
		elseif(Random(1,2) == 2) then
			for i = 1, 2 do
				unit = CreateUnitHPR( 'ura0302', 'Player1', 764, 33.10, 706.5, 0, 0, 0 )
				ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirScout, {unit}, 'attack', 'GrowthFormation')
			end
		end
		for k, v in Hex5AirScout:GetPlatoonUnits() do
			if(not v:IsDead()) then
				IssueClearCommands({v})
				ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Scout_Hex5_Chain')))
			end
		end
		ScenarioFramework.CreateTimerTrigger(SpawnAirScoutHex5Ar1, 80)
	end
end

function DifficultyIf2()
	local dialogue = CreateDialogue('Приветствую командующие, какая сложность?:', { 'Легкая', 'Средняя', 'Сложная', 'Кошмарная' })
	dialogue.OnButtonPressed = function(self, info)
    dialogue:Destroy()
		if info.buttonID == 1 then
			ScenarioFramework.Dialogue(OnEasy)
			ForkThread(SpawnEnemyBases)
		elseif info.buttonID == 2 then
			ScenarioFramework.Dialogue(OnMedium)
			ForkThread(SpawnEnemyBases)
			Medium = true
		elseif info.buttonID == 3 then
			ScenarioFramework.Dialogue(OnHard)
			ForkThread(SpawnEnemyBases)
			Medium = true
			Hard = true
		elseif info.buttonID == 4 then
			ScenarioFramework.Dialogue(OnNightmarish)
			ForkThread(SpawnEnemyBases)
			Medium = true
			Hard = true
			Nightmarish = true
		end
	end
end

function SpawnEnemyBases()
	local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Main_LandDefWest_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolChain({v}, 'M1_Hex5_Main_LandDefWest_Chain')
    end
	WaitSeconds(2)
	ScenarioFramework.Dialogue(OpStrings.X05_M01_011)
	WaitSeconds(5)
	ForkThread(SpawnAllUnitsHex5)
	ScenarioFramework.Dialogue(OpStrings.X05_M01_012)
	WaitSeconds(6)
	ScenarioFramework.Dialogue(OpStrings.X05_M01_013)
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Main_LandDefPatrol_D' .. Random(1,3), 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M1_Hex5_Resource1_Def2_Chain')
	WaitSeconds(1)
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Main_LandDefPatrol_D' .. Random(1,3), 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M1_Hex5_Prison_LandDef_Chain')
	
	WaitSeconds(1)
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Main_LandDefEast_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolChain({v}, 'M1_Hex5_Main_LandDefEast_Chain')
    end
	WaitSeconds(1)
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Main_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Main_AirDef_Chain')))
    end
	
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Main_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Main_AirDef_Chain')))
    end
	
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Main_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Main_AirDef_Chain')))
    end
	
	WaitSeconds(0.5)
	ForkThread(SpawnAirScoutHex5Ar1)
	WaitSeconds(0.5)
	ScenarioInfo.PlayersRespawn = 8
	WaitSeconds(1)
	if(Medium == true) then
		ScenarioInfo.PlayersRespawn = 6
	end
	WaitSeconds(0.5)
	if(Hard == true) then
		ScenarioInfo.PlayersRespawn = 4
	end
	if(Nightmarish == true) then
		ScenarioInfo.PlayersRespawn = 3
	end
	
	-- ScenarioFramework.SimAnnouncement('Количество респавнов играков: ' .. ScenarioInfo.PlayersRespawn .. ' ')
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource1_LandDef_D' .. Random(1,3), 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M1_Hex5_Resource1_Def1_Chain')
	
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Patrol_LandDef1', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'Patrol_Hex5_Land')
	
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Patrol_LandDef2', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M1_Hex5_Main_LandAttack_2')
	
	
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	WaitSeconds(1)
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	WaitSeconds(1)
	if(Hard == true) then
		units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource1_LandDef_D3', 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(units, 'Patrol_hard_Hex5')
	end
	WaitSeconds(2)
	ScenarioUtils.CreateArmyGroup( 'Player1', 'DefArea1' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'MiniBase1' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'MiniBase2' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'MiniBase3' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'MiniBase4' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'PrisonZD' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'Hex5_TargetBase' )
	WaitSeconds(1)
	ForkThread(StartMission1)
	WaitSeconds(7)
	ScenarioFramework.Dialogue(OpStrings.X05_M01_070)
	WaitSeconds(5)
	ForkThread(DeadMiniBases)
	ScenarioInfo.Prison = ScenarioInfo.UnitNames[Enemy]['PrisonCybAeon']
	ScenarioInfo.Prison:SetDoNotTarget(true)
    ScenarioInfo.Prison:SetCanTakeDamage(false)
    ScenarioInfo.Prison:SetCanBeKilled(false)
    ScenarioInfo.Prison:SetReclaimable(false)
	WaitSeconds(1)
	ScenarioFramework.Dialogue(OpStrings.X05_M01_140)
	WaitSeconds(9)
	ForkThread(AssignM1S2)
	if(Nightmarish == true) then
		ScenarioUtils.CreateArmyGroup( 'Player1', 'Nigt_Ivent_Unit' )
		ScenarioUtils.CreateArmyGroup( 'Player1', 'NEWHARDER' )
	end
	local antinukes1 = ArmyBrains[Enemy]:GetListOfUnits(categories.urb4302, false)
	for k,v in antinukes1 do
        v:GiveTacticalSiloAmmo(2)
    end
	local FactoryMiniBase1 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'MiniBase4', ArmyBrains[Enemy])
	for k,v in FactoryMiniBase1 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('Base4'))
    end
	WaitSeconds(2)
	local FactoryMiniBase2 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'MiniBase3', ArmyBrains[Enemy])
	for k,v in FactoryMiniBase2 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('Base3'))
    end
	WaitSeconds(2)
	local FactoryMiniBase3 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'MiniBase2', ArmyBrains[Enemy])
	for k,v in FactoryMiniBase3 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('Base2'))
    end
	WaitSeconds(2)
	local FactoryMiniBase4 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'MiniBase1', ArmyBrains[Enemy])
	for k,v in FactoryMiniBase4 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('Base1'))
    end
	WaitSeconds(3)
	local FactoryBase = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'BaseTargetEnemy', ArmyBrains[Enemy])
	for k,v in FactoryBase do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('TargetBase'))
    end
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	WaitSeconds(2)
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_Resource2_AirDef_D' .. Random(1,3), 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Hex5_Resource2_AirDef_Chain')))
    end
	if(Nightmarish == true) then
		WaitSeconds(10*60)
		ForkThread(SpawnArea1AttackLandT3)
	end
end

local Fractions = {
  [1] = 'UEFCom',
  [2] = 'AeonCom',
  [3] = 'CybranCom',
  [4] = 'SeraCom'
}

function SpawnCom(Id)
    local tblArmy = ListArmies()
    for iArmy, strArmy in pairs(tblArmy) do
        if iArmy == ScenarioInfo['Player' .. Id] then
      local factionIdx = GetArmyBrain(strArmy):GetFactionIndex()
      local Fraction = Fractions[factionIdx]
      if type(Fraction) == "function" then
                Fraction = Fraction()
            end
            ScenarioInfo['Player' .. Id .. 'CDR'] = ScenarioUtils.CreateArmyUnit('Player' .. Id, Fraction)
            ScenarioInfo['Player' .. Id .. 'CDR']:PlayCommanderWarpInEffect()
            ScenarioFramework.CreateUnitDeathTrigger(
				function() 
				ScenarioInfo.KilledCDRs = ScenarioInfo.KilledCDRs + 1 
				ForkThread(LosePlayers)
				end, 
				ScenarioInfo['Player' .. Id .. 'CDR']
				)
        end
    end
end


function StartMission1()
    ScenarioInfo.M1P1 = Objectives.CategoriesInArea(
        'primary',                      # type
        'incomplete',                   # complete
        'База Хекс5',  # title
        'Уничтожьте базу Хекс5',  # description
        'kill',                         # action
        {                               # target
            MarkArea = true,
            Requirements = {
                {
                    Area = 'BaseTargetEnemy',
                    Category = ( categories.FACTORY + categories.url0309 + (categories.SHIELD * categories.STRUCTURE) + categories.urb1302),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Enemy,
                },
            },
        }
    )
    ScenarioInfo.M1P1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(BaseOffHex5)
				Area1 = false
				ForkThread(SpawnFletherPlayer5)
            end
        end
    )
end

function StartArea2()
	WaitSeconds(1)
	ScenarioFramework.SetPlayableArea('Area2', true)
	ScenarioUtils.CreateArmyGroup( 'Player1', 'Area2Base' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'ComArea2' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'BaseArea2Eng' )
	ScenarioInfo.Hex5 = ScenarioInfo.UnitNames[Enemy]['Hex5Com']
	WaitSeconds(1)
	ForkThread(CapArea1Players2)
	WaitSeconds(1)
    ScenarioInfo.Hex5:SetCustomName(LOC '{i Hex5}')
	ScenarioInfo.Hex5:CreateEnhancement('StealthGeneratorCybran')
	ScenarioInfo.Hex5:CreateEnhancement('GAP_SelfRepairSystemCybran')
	ScenarioInfo.Hex5:CreateEnhancement('CloakingGeneratorCybran')
	ScenarioInfo.Hex5:CreateEnhancement('MicrowaveLaserGeneratorCybran')
	ScenarioInfo.Hex5:CreateEnhancement('EngineeringT2Cybran')
	ScenarioInfo.Hex5:CreateEnhancement('T3EngineeringCybran')
	WaitSeconds(1)
	ScenarioInfo.Hex5:SetVeterancy(5)
	ScenarioInfo.Hex5:SetMaxHealth(45000)
	ScenarioInfo.Hex5:SetHealth(nil, 45000)
	ScenarioFramework.Dialogue(HEX5Target)
	Et = 2
	if(Medium == true) then
		local DefPAt1 = {'M2_Hex5_Main_AirDef_N_Chain','M2_Hex5_Main_AirDef_W_Chain'}
		local DefPAt2 = {'M2_Hex5_Main_LandDef_N1_Chain', 'M2_Hex5_Main_LandDef_N2_Chain', 'M2_Hex5_Main_LandDef_W_Chain'}
		ScenarioUtils.CreateArmyGroupAsPlatoon( 'Player1', 'Area2DefBase', 'GrowthFormation' )
		local UnitsAir = ArmyBrains[Enemy]:GetListOfUnits(categories.AIR * categories.MOBILE, false)
		local UnitsAirEnemy = ArmyBrains[Enemy]:MakePlatoon('', '')
		for k, v in UnitsAir do
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(UnitsAirEnemy, {v}, 'Attack', 'GrowthFormation')
		end
		WaitSeconds(2)
		for k, v in UnitsAirEnemy:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(DefPAt1[Random(1,2)])))
		end
		local UnitsLand = ArmyBrains[Enemy]:GetListOfUnits(categories.LAND * categories.MOBILE + categories.EXPERIMENTAL - categories.COMMAND - categories.ENGINEER, false)
		local UnitsLandEnemy = ArmyBrains[Enemy]:MakePlatoon('', '')
		for k, v in UnitsLand do
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(UnitsLandEnemy, {v}, 'Attack', 'GrowthFormation')
		end
		WaitSeconds(2)
		for k, v in UnitsLandEnemy:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(DefPAt2[Random(1,3)])))
		end
	end
	WaitSeconds(3)
	if(Hard == true) then
		ForkThread(StartContAttackHex5)
		ScenarioUtils.CreateArmyGroup( 'Player1', 'Hard_Nuke' )
	end
	WaitSeconds(2)
	if(Nightmarish == true) then
		CreateUnitHPR('url0401', 'Player1', 784.5, 23.0014, 990.5, 0, 0, 0)
		CreateUnitHPR('url0401', 'Player1', 988.5, 23.0014, 912.5, 0, 0, 0)
		CreateUnitHPR('urb4207', 'Player1', 794.5, 23.0014, 992.5, 0, 0, 0)
		CreateUnitHPR('urb4207', 'Player1', 994.5, 23.0014, 914.5, 0, 0, 0)
	end
	local antinukes2 = ArmyBrains[Enemy]:GetListOfUnits(categories.urb4302, false)
	for k,v in antinukes2 do
        v:GiveTacticalSiloAmmo(25)
    end
	local nukes2 = ArmyBrains[Enemy]:GetListOfUnits(categories.urb2305, false)
	for k,v in nukes2 do
        v:GiveNukeSiloAmmo(15)
    end
	WaitSeconds(2)
	ForkThread(DestHex5)
	WaitSeconds(2)
	local FactoryBaseHex5 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'BaseHex5', ArmyBrains[Enemy])
	for k,v in FactoryBaseHex5 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('Hex5base'))
    end
	WaitSeconds(5)
	local FactoryBaseHex5Land = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'LandBaseHex5', ArmyBrains[Enemy])
	for k,v in FactoryBaseHex5Land do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('Hex5BaseLandDop'))
    end
	
	WaitSeconds(5)
	ForkThread(StartInitialAttackArea2Hex5)
end

function StartInitialAttackArea2Hex5()
	if(Area2 == true and Medium == true) then
		local PathArea2 = {'M2_Hex5_LandAttack_1_Chain', 'M2_Hex5_LandAttack_2_Chain', 'M2_Hex5_AirAttack_1_Chain', 'M2_Hex5_AirAttack_2_Chain'}
		local UnitsArea2 = {'M2_Hex5_Attack_Group1', 'M2_Hex5_Attack_Group2', 'M2_Hex5_Attack_Group3', 'M2_Hex5_Attack_Group4', 'M2_Hex5_Attack_Group5', 'M2_Hex5_Attack_Group6', 'M2_Hex5_Attack_Group7', 'M2_Hex5_Attack_Group8', 'M2_Hex5_Attack_Group9', 'M2_Hex5_Attack_Group10'}
		units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', UnitsArea2[Random(1,10)], 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(units, PathArea2[Random(1,4)])
	end
	WaitSeconds(10)
	if(Area2 == true and Hard == true) then
		local PathArea2 = {'M2_Hex5_LandAttack_1_Chain', 'M2_Hex5_LandAttack_2_Chain', 'M2_Hex5_AirAttack_1_Chain', 'M2_Hex5_AirAttack_2_Chain'}
		local UnitsArea2 = {'M2_Hex5_Attack_Group1', 'M2_Hex5_Attack_Group2', 'M2_Hex5_Attack_Group3', 'M2_Hex5_Attack_Group4', 'M2_Hex5_Attack_Group5', 'M2_Hex5_Attack_Group6', 'M2_Hex5_Attack_Group7', 'M2_Hex5_Attack_Group8', 'M2_Hex5_Attack_Group9', 'M2_Hex5_Attack_Group10'}
		units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', UnitsArea2[Random(1,10)], 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(units, PathArea2[Random(1,4)])
	end
	ScenarioFramework.CreateTimerTrigger(StartInitialAttackArea2Hex5, Random(70, 90))
end

function StartContAttackHex5()
	if(Medium == true) then
		for i = 1, 3 do
			units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M2_Hex5_InitAir_' .. i .. '_D' .. Random(1,3), 'GrowthFormation')
			ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitAir_Attack_Chain')
		end
	end
	local landChains = {'M2_Hex5_InitLand_3_Chain', 'M2_Hex5_InitLand_2_Chain', 'M2_Hex5_InitLand_2_Chain', 'M2_Hex5_InitLand_2_Chain', 'M2_Hex5_InitLand_2_Chain', 'M2_Hex5_InitLand_1_Chain', 'M2_Hex5_InitLand_3_Chain'}
    for i = 1, 7 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M2_Hex5_InitLand_' .. i .. '_D' .. Random(1,3), 'GrowthFormation')
        ScenarioFramework.PlatoonPatrolChain(units, landChains[i])
    end
	units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_' .. Random(1,3), 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_3_Chain')
	
	units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_' .. Random(1,3), 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_3_Chain')
	
	WaitSeconds(2)
	
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_1', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_3_Chain')
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_2', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_3_Chain')
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_3', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_2_Chain')
	WaitSeconds(2)
	
	for i = 1, 4 do
		units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_4', 'GrowthFormation', 5)
		ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_2_Chain')
		WaitSeconds(2)
	end
	
	units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_5', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_2_Chain')
			
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_InitLandAtack_6', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitLand_1_Chain')
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_L_Siege', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_LandAdapt_Chain')
	
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_L_Siege_b', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_LandAdapt_Chain')
	
	WaitSeconds(4)
	
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_L_Missile', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_LandAdapt_Chain')
		
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_L_Missile_b', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_LandAdapt_Chain')
	
	WaitSeconds(3)
	
    units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_L_Artil', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_LandAdapt_Chain')
    
	units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_L_Artil_b', 'GrowthFormation', 5)
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_LandAdapt_Chain')
    for i = 1, 6 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M2_Hex5_Adapt_Xport1', 'GrowthFormation')
        for k,v in units:GetPlatoonUnits() do
            if(v:GetUnitId() == 'ura0104') then
                local interceptors = ScenarioUtils.CreateArmyGroup('Player1', 'M2_Hex5_Adapt_Xport_Interceptors')
                IssueGuard(interceptors, v)
                break
            end
        end
        ScenarioFramework.PlatoonAttackWithTransports(units, 'M2_Hex5_Transport_Landing_Chain', 'M2_Hex5_Transport_Attack_Chain', false)
    end

    for i = 1, 4 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M2_Hex5_Adapt_Bombers', 'GrowthFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitAir_Attack_Chain')
    end
	WaitSeconds(10)
    for i = 1, 8 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_Gunships', 'GrowthFormation', 5)
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitAir_Attack_Chain')
		WaitSeconds(3)
    end
    for i = 1, 6 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Player1', 'M2_Hex5_Adapt_AirSup', 'GrowthFormation', 5)
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_Hex5_InitAir_Attack_Chain')
    end
end

function SpawnEHex5()
	WaitSeconds(100)
	ScenarioUtils.CreateArmyGroup( 'Player1', 'Nightmarish_Unit_Hex5' )
end

function DestHex5()
	ScenarioInfo.M2P1 = Objectives.KillOrCapture(
        'primary',                      # type
        'incomplete',                   # complete
        'хекс5',  # title
        'Убейте командующего Хекс5',  # description
        {                               # target
            Units = {ScenarioInfo.Hex5},
            MarkUnits = true,
        }
    )
    ScenarioInfo.M2P1:AddResultCallback(
        function(result)
            if(result) then
				ForkThread(Area3)
				ScenarioFramework.Dialogue(Hex5DeadCDR, nil, true)
				Area2 = false
            end
        end
    )
end

function Area3()
	ScenarioFramework.SetPlayableArea('Area3', true)
	ScenarioInfo.QAIBuildsT = ScenarioUtils.CreateArmyGroup( 'Player1', 'Build_QAI' )
	ScenarioInfo.QAI = ScenarioInfo.UnitNames[Enemy]['QAIStation']
    ScenarioInfo.QAI:SetCustomName(LOC '{i QAI}')
	Et = 3
	WaitSeconds(1)
	ForkThread(CapArea1Players3)
	WaitSeconds(1)
	ScenarioInfo.QAI:SetDoNotTarget(true)
    ScenarioInfo.QAI:SetCanTakeDamage(false)
    ScenarioInfo.QAI:SetCanBeKilled(false)
    ScenarioInfo.QAI:SetReclaimable(false)
	ScenarioUtils.CreateArmyGroup( 'Player1', 'Base_QAI' )
	local DefenseAir_Naval = ScenarioUtils.CreateArmyGroupAsPlatoon( 'Player1', 'NavalDef', 'GrowthFormation' )
	for k, v in DefenseAir_Naval:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('QAI_NavalDef_Air_Area3')))
	end
	ScenarioUtils.CreateArmyGroup( 'Player1', 'NavalFactory' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'QAI_ENG_Base' )
	for i = 1, Random(3, 7) do
		CreateUnitHPR('url0402', 'Player1', 700, 30, 800, 0, 0, 0)
	end
	WaitSeconds(3)
	if(Hard == true) then
		ScenarioUtils.CreateArmyGroup( 'Player1', 'QAIBaseScatis' )
		CreateUnitHPR('url0401', 'Player1', 602, 32, 788, 0, 0, 0)
	end
	
	if(Medium == true) then
		ScenarioUtils.CreateArmyGroup( 'Player1', 'NavalAttack' )
		local DefenseAir_baseQAI = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran( 'Player1', 'UnitsBaseDef', 'GrowthFormation' )
		for k, v in DefenseAir_baseQAI:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M3_QAI_AirDefenseBase_Chain')))
		end
	end
	WaitSeconds(3)
	if(Hard == true) then
		local AttackPozition = {'Player2', 'Player3', 'Player4', 'Player5', 'Player6', 'Player7'}
		ScenarioInfo.QAIAttackArea3 = ScenarioUtils.CreateArmyGroup( 'Player1', 'AttackUnitsQAI' )
		for k, v in ScenarioInfo.QAIAttackArea3 do
			local platoon = ArmyBrains[Enemy]:MakePlatoon('', '')
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(platoon, {v}, 'Attack', 'None')
			platoon:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPozition[Random(1, 6)]))
		end
	end
	WaitSeconds(1)
	if(Nightmarish == true) then
		ScenarioUtils.CreateArmyGroup( 'Player1', 'Nightmarish_Units' )
	end
	ForkThread(CaptureQAI)
	WaitSeconds(2)
	local antinukes3 = ArmyBrains[Enemy]:GetListOfUnits(categories.urb4302, false)
	for k,v in antinukes3 do
        v:GiveTacticalSiloAmmo(25)
    end
	WaitSeconds(5)
	local FactoryBaseQAINaval = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'QAINaval', ArmyBrains[Enemy])
	for k,v in FactoryBaseQAINaval do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('NavalBaseQAI'))
    end
	WaitSeconds(5)
	local FactoryBaseQAIEXP = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'EXPBaseQAI', ArmyBrains[Enemy])
	for k,v in FactoryBaseQAIEXP do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('EXP_Base_QAI'))
    end
	WaitSeconds(5)
	local FactoryBaseQAI1 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'Base1QAI', ArmyBrains[Enemy])
	for k,v in FactoryBaseQAI1 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('QAIBase1'))
    end
	WaitSeconds(5)
	local FactoryBaseQAI2 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'Base2QAI', ArmyBrains[Enemy])
	for k,v in FactoryBaseQAI2 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('QAIBase2'))
    end
	WaitSeconds(5)
	local FactoryBaseQAI3 = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY, 'Base3QAI', ArmyBrains[Enemy])
	for k,v in FactoryBaseQAI3 do
        IssueClearFactoryCommands({v})
		IssueFactoryRallyPoint({v}, ScenarioUtils.MarkerToPosition('QAIBase3'))
    end
end

function CaptureQAI()
	ScenarioInfo.M1S3 = Objectives.Capture(
        'primary',                    # type
        'incomplete',                   # complete
        'КИИ',  # title
        'Захватите станцию КИИ, что бы доктор Брэкман смог взять коды врат.',  # description
        {
            Units = {ScenarioInfo.QAI},
        }
    )
    ScenarioInfo.M1S3:AddResultCallback(
        function(result)
            if(result) then
				ScenarioFramework.Dialogue(OpStrings.X05_DB01_010, WinPlayers, true)
            end
        end
    )
end

function WinPlayers()
	ScenarioFramework.EndOperationSafety()
    ScenarioInfo.OpComplete = true
	ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, nil)
end

function DeadMiniBases()
    ScenarioInfo.M1S1 = Objectives.CategoriesInArea(
        'secondary',                    # type
        'incomplete',                   # complete
        'Мини базы',  # title
        'Уничтожьте все 4 мини базы врага.',  # description
        'kill',                         # action
        {                               # target
            MarkUnits = true,
            Requirements = {
                {
                    Area = 'MiniBase1',
                    ArmyIndex = Enemy,
                    Category = categories.FACTORY + (categories.ENERGYPRODUCTION * categories.TECH2) + (categories.RADAR * categories.STRUCTURE),
                    CompareOp = '<=',
                    MarkArea = true,
                    Value = 0,
                },
                {
                    Area = 'MiniBase2',
                    ArmyIndex = Enemy,
                    Category = categories.FACTORY + (categories.ENERGYPRODUCTION * categories.TECH2) + (categories.RADAR * categories.STRUCTURE) + categories.AIRSTAGINGPLATFORM,
                    CompareOp = '<=',
                    MarkArea = true,
                    Value = 0,
                },
                {
                    Area = 'MiniBase3',
                    ArmyIndex = Enemy,
                    Category = categories.FACTORY + (categories.ENERGYPRODUCTION * categories.TECH2) + (categories.COUNTERINTELLIGENCE * categories.STRUCTURE) + categories.AIRSTAGINGPLATFORM,
                    CompareOp = '<=',
                    MarkArea = true,
                    Value = 0,
                },
				{
                    Area = 'MiniBase4',
                    ArmyIndex = Enemy,
                    Category = categories.FACTORY + (categories.ENERGYPRODUCTION * categories.TECH2) + (categories.RADAR * categories.STRUCTURE) +(categories.COUNTERINTELLIGENCE * categories.STRUCTURE) + categories.AIRSTAGINGPLATFORM,
                    CompareOp = '<=',
                    Value = 0,
                },
            },
        }
    )
    ScenarioInfo.M1S1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(OpStrings.X05_M01_100)
            end
        end
    )
	WaitSeconds(3)
	ForkThread(MiniBase1Z)
end


function AssignM1S2()
    ScenarioInfo.M1S4 = Objectives.Capture(
        'secondary',                    # type
        'incomplete',                   # complete
        'Темница',  # title
        'Захватите темницу что бы освободить командующую Амалию.',  # description
        {
            Units = {ScenarioInfo.Prison},
        }
    )
    ScenarioInfo.M1S4:AddResultCallback(
        function(result)
            if(result) then
				ScenarioFramework.Dialogue(OpStrings.X05_M01_180)
				ScenarioInfo.Amalia = CreateUnitHPR('ual0301_AntiNavy', 'Player2', 570.5, 31.98633, 679.5, 0, 0, 0)
                ScenarioInfo.Amalia:SetCustomName(LOC '{i Amalia}')
				IssueMove({ScenarioInfo.Amalia}, ScenarioUtils.MarkerToPosition('MoveAmalia'))
            end
        end
    )
end

function SpawnFletherPlayer5()
	WaitSeconds(3)
	ForkThread(SpawnAttacksEnemyPreArea2)
end

function SpawnAttacksEnemyPreArea2()
	ScenarioInfo.EnemyUnitsPreArea2 = ArmyBrains[Enemy]:MakePlatoon('', '')
	for i = 1, Random(5, 7) do
		unit = CreateUnitHPR('url0402', 'Player1', 832, 30, 803, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(ScenarioInfo.EnemyUnitsPreArea2, {unit}, 'attack', 'GrowthFormation')
	end
	for i = 1, Random(12, 18) do
		unit = CreateUnitHPR('url0303', 'Player1', 832, 30, 803, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(ScenarioInfo.EnemyUnitsPreArea2, {unit}, 'attack', 'GrowthFormation')
	end
	for i = 1, Random(6, 10) do
		unit = CreateUnitHPR('url0305', 'Player1', 832, 30, 803, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(ScenarioInfo.EnemyUnitsPreArea2, {unit}, 'attack', 'GrowthFormation')
	end
	for i = 1, Random(2, 4) do
		unit = CreateUnitHPR('url0002', 'Player1', 832, 30, 803, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(ScenarioInfo.EnemyUnitsPreArea2, {unit}, 'attack', 'GrowthFormation')
	end
	for i = 1, Random(8, 12) do
		unit = CreateUnitHPR('url0305', 'Player1', 840, 30, 803, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(ScenarioInfo.EnemyUnitsPreArea2, {unit}, 'attack', 'GrowthFormation')
	end
	for i = 1, Random(2, 5) do
		unit = CreateUnitHPR('xrl0403', 'Player1', 840, 30, 803, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(ScenarioInfo.EnemyUnitsPreArea2, {unit}, 'attack', 'GrowthFormation')
	end
	for i = 1, Random(4, 7) do
		unit = CreateUnitHPR('ura0401', 'Player1', 840, 30, 803, 0, 0, 0)
		ArmyBrains[Enemy]:AssignUnitsToPlatoon(ScenarioInfo.EnemyUnitsPreArea2, {unit}, 'attack', 'GrowthFormation')
	end
	WaitSeconds(5)
	ForkThread(DefensePlayers)
end

function DefensePlayers()
	ScenarioFramework.CreatePlatoonDeathTrigger(UA1, ScenarioInfo.EnemyUnitsPreArea2)
	ScenarioInfo.X1S = Objectives.Basic(
        'primary',                          -- type
        'incomplete',                       -- complete
        'Вражеская Атака',      -- title
        'Отбейте Атаку врага',      -- description
        Objectives.GetActionIcon('kill'),
        {                                   -- target
        }
    )
end

function UA1()
	ScenarioInfo.Deads = ScenarioInfo.Deads + 1
	ForkThread(D1S)
end

function D1S()
	if(ScenarioInfo.Deads == 1) then
		ScenarioFramework.Dialogue(KillEXPPreArea2, StartArea2, true)
		ScenarioInfo.X1S:ManualResult(true)
	end
end