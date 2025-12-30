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

local OpStrings = import('/maps/Mission_War of Minds.0005/Map_Comp_strings.lua')

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
ScenarioInfo.Player1 = 1
ScenarioInfo.Player2 = 2
ScenarioInfo.Player3 = 3
ScenarioInfo.Player4 = 4
ScenarioInfo.Player5 = 5
ScenarioInfo.Player6 = 6
ScenarioInfo.Player7 = 7

local Et = 0
local Enemy = ScenarioInfo.Player1
local Player2 = ScenarioInfo.Player2
local Player3 = ScenarioInfo.Player3
local Player4 = ScenarioInfo.Player4
local Player5 = ScenarioInfo.Player5
local Player6 = ScenarioInfo.Player6
local Player7 = ScenarioInfo.Player7

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
	ScenarioFramework.SetUEFPlayerColor(Player2)
	ScenarioFramework.SetAeonAllyColor(Player3)
	ScenarioFramework.SetCybranPlayerColor(Player4)
	
	local colors = {
        
        ['Player5'] = {255, 191, 128}, 
        ['Player6'] = {189, 116, 16}, 
        ['Player7'] = {89, 133, 39},    
    }
    
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
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
	ScenarioInfo.RandomTP = {'TPACU', 'M1_FletcherBase_Eng_5', 'M1_Hex5_Main_LandAttack2_13', 'M2_Hex5_LandAttack_1_19', 'M1_Hex5_Main_AirAttack2_2', 'M1_Hex5_Res1_Def2_1', 'M3_QAI_ExpBase_Attack_18', 'M2_Hex5_LandAdapt_13'}
	ScenarioInfo.RandomEnhancement = {'EngineeringT2Cybran','ResourceAllocationCybran','MicrowaveLaserGeneratorCybran', 'StealthGeneratorCybran', 'TeleporterCybran'}
	ScenarioInfo.ACUQAI1 = CreateUnitHPR('url0001', 'Player1', 1016, 28, 282, 0, 0, 0)
	ScenarioInfo.ACUQAI1:SetCustomName(LOC '{i QAI}')
	Warp(ScenarioInfo.ACUQAI1, ScenarioUtils.MarkerToPosition('TPACU'))
	WaitSeconds(1)
	ScenarioInfo.ACUQAI2 = CreateUnitHPR('url0001', 'Player1', 1016, 28, 282, 0, 0, 0)
	ScenarioInfo.ACUQAI2:SetCustomName(LOC '{i QAI}')
	Warp(ScenarioInfo.ACUQAI2, ScenarioUtils.MarkerToPosition('TPACU'))
	WaitSeconds(1)
	ScenarioInfo.ACUQAI1:CreateEnhancement('TeleporterCybran')
	ScenarioInfo.ACUQAI2:CreateEnhancement('TeleporterCybran')
	WaitSeconds(1)
	ForkThread(ChechPlayerQAIACU)
	WaitSeconds(3)
	ForkThread(SpawnEXPArea1)
end

function LosePlayers()
	if(ScenarioInfo.KilledCDRs == ScenarioInfo.NumsPl) then
		ScenarioFramework.PlayerLose()
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

function ChechPlayerQAIACU()
	ScenarioFramework.CreateArmyIntelTrigger( DopZDKILLACU1, ArmyBrains[Player2], 'LOSNow', false, true, categories.url0001, true, ArmyBrains[Enemy] )
	ScenarioFramework.CreateArmyIntelTrigger( DopZDKILLACU3, ArmyBrains[Player2], 'LOSNow', false, true, categories.url0402, true, ArmyBrains[Enemy] )
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
                    Category = (categories.url0001),
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
	ScenarioInfo.ACUQAI = CreateUnitHPR('url0001', 'Player1', 1016, 32, 360, 0, 0, 0)
	ScenarioInfo.ACUQAI:SetCustomName(LOC '{i QAI}')
	ScenarioInfo.ACUQAI:CreateEnhancement(ScenarioInfo.RandomEnhancement[Random(1,5)])
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
	WaitSeconds(340)
	ForkThread(SpawnArea1AttackAir)
end


function SpawnArea1AttackAir()
	if(Area1 == true) then
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
		for i = 1, Random(1,3) do
			unit = CreateUnitHPR( 'ura0304', 'Player1', 762, 33.10346, 696, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(3,6) do
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
			unit = CreateUnitHPR( 'ura0303', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks5_Chain')
		elseif(Random(1,6) == 6) then
		for i = 1, Random(2,5) do
			unit = CreateUnitHPR( 'ura0203', 'Player1', 802, 24.10346, 562, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,5) do
			unit = CreateUnitHPR( 'ura0303', 'Player1', 631, 33.10346, 524, 0, 0, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Hex5AirAttack, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Hex5AirAttack, 'M1_Hex5_Air_Attacks3_Chain')
		end
		ScenarioFramework.CreateTimerTrigger(SpawnArea1AttackAir, 30)
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
	WaitSeconds(5)
	ScenarioUtils.CreateArmyGroup( 'Player1', 'Area1North' )
	WaitSeconds(60)
	ForkThread(SpawnAttackHex5Initial)
end

function SpawnAttackHex5Initial()
	WaitSeconds(24)
	local RandomGroupAt = {'M1_Hex5_Attack_Group1', 'M1_Hex5_Attack_Group2', 'M1_Hex5_Attack_Group3', 'M1_Hex5_Attack_Group4', 'M1_Hex5_Attack_Group5'}
	local RandomChainGr = {'M2_Hex5_LandAttack_1_Chain', 'M2_Hex5_LandAttack_2_Chain'}
	units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', RandomGroupAt[Random(1,5)], 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, RandomChainGr[Random(1,2)])
	WaitSeconds(1)
	ForkThread(StartAIAttackHex5)
	WaitSeconds(8)
	ForkThread(SpawnAttackMidHex5)
end

function SpawnAttackMidHex5()
	WaitSeconds(2)
	if(Area1 == true) then
		local RandomGroupAtMid = {'M1_Hex5_Attack_Mid1', 'M1_Hex5_Attack_Mid2', 'M1_Hex5_Attack_Mid3', 'M1_Hex5_Attack_Mid4', 'M1_Hex5_Attack_Mid5', 'M1_Hex5_Attack_Mid6'}
		local RandomChainGrMid = {'M1_Hex5_Main_LandAttack_1', 'M1_Hex5_Main_LandAttack_2', 'M1_Hex5_Main_LandAttack_3', 'M1_Hex5_Main_LandAttack_4', 'M1_Hex5_Resource1_Att1_Chain', 'M1_Hex5_Resource1_Att1b_Chain'}
		units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', RandomGroupAtMid[Random(1,6)], 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(units, RandomChainGrMid[Random(1,6)])
		if(Hard == true) then
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'M1_Hex5_DropArea'.. Random(1,4), 'GrowthFormation')
			ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_QAI_Main_Base_LandAttack_Chain')
		end
	end
	
	ScenarioFramework.CreateTimerTrigger(SpawnAttackMidHex5, Random(62, 140))
end

function StartAIAttackHex5()
	WaitSeconds(4)
	if(Area1 == true and Medium == true) then
		local RandomGroupAt = {'M1_Hex5_Attack_Group1', 'M1_Hex5_Attack_Group2', 'M1_Hex5_Attack_Group3', 'M1_Hex5_Attack_Group4', 'M1_Hex5_Attack_Group5'}
		local RandomChainGr = {'M2_Hex5_LandAttack_1_Chain', 'M2_Hex5_LandAttack_2_Chain', 'M1_Hex5_Resource1_Att1b_Chain'}
		units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', RandomGroupAt[Random(1,5)], 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(units, RandomChainGr[Random(1,3)])
	end
	
	ScenarioFramework.CreateTimerTrigger(StartAIAttackHex5, Random(72, 130))
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
	ScenarioInfo.Hex5:SetMaxHealth(60000)
	ScenarioInfo.Hex5:SetHealth(nil, 60000)
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
	ScenarioUtils.CreateArmyGroup( 'Player1', 'NavalDef' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'NavalFactory' )
	ScenarioUtils.CreateArmyGroup( 'Player1', 'QAI_ENG_Base' )
	
	CreateUnitHPR('url0401', 'Player1', 700, 30, 800, 0, 0, 0)
	
	if(Medium == true) then
		ScenarioUtils.CreateArmyGroup( 'Player1', 'NavalAttack' )
		ScenarioUtils.CreateArmyGroup( 'Player1', 'UnitsBaseDef' )
	end
	WaitSeconds(3)
	if(Hard == true) then
		ScenarioUtils.CreateArmyGroup( 'Player1', 'AttackUnitsQAI' )
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
				ScenarioInfo.Amalia = CreateUnitHPR('ual0301', 'Player2', 570.5, 31.98633, 679.5, 0, 0, 0)
                ScenarioInfo.Amalia:SetCustomName(LOC '{i Amalia}')
				IssueMove({ScenarioInfo.Amalia}, ScenarioUtils.MarkerToPosition('MoveAmalia'))
            end
        end
    )
end

function SpawnFletherPlayer5()
	WaitSeconds(2)
	ForkThread(StartArea2)
end