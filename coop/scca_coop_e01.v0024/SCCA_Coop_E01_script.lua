
local BaseManager = import('/lua/ai/opai/basemanager.lua')
local Cinematics = import('/lua/cinematics.lua')
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local PingGroups = import('/lua/ScenarioFramework.lua').PingGroups
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local TauntManager = import('/lua/TauntManager.lua')
local Utilities = import('/lua/utilities.lua')
local FactionData = import('/lua/factions.lua')
local Buff = import('/lua/sim/Buff.lua')
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
local Behaviors = import('/lua/ai/opai/OpBehaviors.lua')

local OpStrings = import('/maps/scca_coop_e01.v0024/SCCA_Coop_E01_strings.lua')

local markers = ScenarioUtils.GetMarkers();
local DeadCommand = 0
local AirTran2 = false

local MOD = ScenarioInfo.Options.Mod


local CybranAI = import('/maps/scca_coop_e01.v0024/SCCA_Coop_E01_CybranAI.lua')
local UEFAllyAI = import('/maps/scca_coop_e01.v0024/SCCA_Coop_E01_UEFBotAI.lua')

local AirTran = true

local Difficulty = ScenarioInfo.Options.Difficulty
local Dif4 = ScenarioInfo.Options.Dif4
local AttackTr = false
local BonusChaos = false
local NighBot1 = false

local NighBot2 = false
local BonusACUHP = 10
---------
-- Globals
---------
ScenarioInfo.Player1 = 1
ScenarioInfo.Arnold = 2
ScenarioInfo.Cybran = 3
ScenarioInfo.EastResearch = 4
ScenarioInfo.NeutralStructures = 5
ScenarioInfo.Player2 = 6
ScenarioInfo.Player3 = 7
ScenarioInfo.Player4 = 8
ScenarioInfo.Player5 = 9
ScenarioInfo.Player6 = 10

local Player1 = ScenarioInfo.Player1
local Player2 = ScenarioInfo.Player2
local Player3 = ScenarioInfo.Player3
local Player4 = ScenarioInfo.Player4
local Player5 = ScenarioInfo.Player5
local Player6 = ScenarioInfo.Player6
local Arnold = ScenarioInfo.Arnold
local Cybran = ScenarioInfo.Cybran
local EastResearch = ScenarioInfo.EastResearch
local NeuUEF = ScenarioInfo.NeutralStructures

ScenarioInfo.PowerGenDestroyed = 0

--------------------------
-- Objective Reminder Times
--------------------------
local M1P1Time = 300
local M1P2Time = 300
local M2P1Time = 300
local M3P1Time = 300
local M4P1Time = 300
local M5P1Time = 900
local M6P1Time = 900
local M7P1Time = 900
local M7P2Time = 900
local M7S1Time = 600
local SubsequentTime = 600
local AirBaseAI = false
ScenarioInfo.NumPlayers = {}
-------------
-- Misc Locals
-------------
local M1P1_MassRequired = 3
local M1P2_PowerRequired = 4
local M3P1_TanksRequired = 4
local M3P1_ArtyRequired = 4

local leopardTaunt = 1


function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()
    LeaderFaction, LocalFaction = ScenarioFramework.GetLeaderAndLocalFactions()
	local tblArmy = ListArmies()
	
	if not tblArmy[ScenarioInfo.Player2] and not tblArmy[ScenarioInfo.Player3] and not tblArmy[ScenarioInfo.Player4] and not tblArmy[ScenarioInfo.Player5] and not tblArmy[ScenarioInfo.Player6] then
        ScenarioInfo.UseUEFAllyAI = true
	else 
		ScenarioInfo.UseUEFAllyAI = false
    end
	
    if tblArmy[ScenarioInfo.Player1] then
        ScenarioInfo.NumPlayers = 1
    end
    if tblArmy[ScenarioInfo.Player2] then
        ScenarioInfo.NumPlayers = 2
    end
	
	if tblArmy[ScenarioInfo.Player3] then
        ScenarioInfo.NumPlayers = 3
    end
	
	if tblArmy[ScenarioInfo.Player4] then
        ScenarioInfo.NumPlayers = 4
    end
	
	if tblArmy[ScenarioInfo.Player5] then
        ScenarioInfo.NumPlayers = 5
    end
	
	if tblArmy[ScenarioInfo.Player6] then
        ScenarioInfo.NumPlayers = 6
    end
end

function OnStart(scenario)
    -- Adjust buildable categories for Player
    for _, player in ScenarioInfo.HumanPlayers do
         ScenarioFramework.AddRestriction(player, categories.UEF)
         ScenarioFramework.AddRestriction(player, categories.CYBRAN)
    end
	
	ScenarioFramework.AddRestriction(Cybran, categories.url0309)
    ScenarioFramework.RemoveRestrictionForAllHumans(categories.ueb1103 + categories.ueb1101 + categories.uea0101 + categories.ueb0101 + categories.ueb0102 + categories.ueb2101 + categories.ueb2104 + categories.ueb5101 + categories.uel0105)  -- T1 Mass Extractor
	-- Lock off cdr upgrades
    ScenarioFramework.RestrictEnhancements({'EngineeringT2UEF',
                                            'DamageStabilizationUEF',
                                            'HeavyAntiMatterCannonUEF',
                                            'HeavyAntiMatterDeeKeyUEF',
                                            'LeftPodUEF',
                                            'ResourceAllocationUEF',
                                            'RightPodUEF',
                                            'ShieldUEF',
											'RegenUEF',
                                            'ShieldGeneratorFieldUEF',
                                            'T3EngineeringUEF',
                                            'TacticalMissileUEF',
											'TacticalNukeMissileUEF',
											'TeleporterUEF'})
    -- Unit Cap
	local tblArmy = ListArmies()
	for i = 1, ScenarioInfo.NumPlayers do
		ScenarioFramework.SetSharedUnitCap(160 * i)
	end
    -- Army Colors
    ScenarioFramework.SetUEFColor(Player1)
    ScenarioFramework.SetUEFAllyColor(Arnold)
    ScenarioFramework.SetCybranColor(Cybran)
    ScenarioFramework.SetUEFNeutralColor(EastResearch)
    local colors = {
        ['Player2'] = {67, 110, 238}, 
        ['Player3'] = {97, 109, 126}, 
        ['Player4'] = {255, 255, 255},
		['Player5'] = {70, 140, 184},
		['Player6'] = {37, 192, 48}
    }
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end
    
    -- Disable friendly AI sharing resources to players
    GetArmyBrain(EastResearch):SetResourceSharing(false)

    ScenarioFramework.SetPlayableArea('M2Area', false)
    ScenarioFramework.StartOperationJessZoom('M1Area', IntroMission1)
	
end

function SpawnAttacksAIMap()
	if (AirBaseAI == true) then
		local CybranAt = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('DefensiveLine_Patrol1')
		local AttackPoint = {'AttackPoint1','AttackPoint2', 'AttackPoint3'}
		-- T3
		for i = 1, 2 * ScenarioInfo.NumPlayers + Difficulty * Random(1,3) do
			unit = CreateUnitHPR( 'url0107', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAt, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, 2 * Random(1,4) do
			unit = CreateUnitHPR( 'url0106', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAt, {unit}, 'attack', 'GrowthFormation')
		end
		if(Dif4 == 1) then
			for i = 1, 1 * Random(1,3) do
				unit = CreateUnitHPR( 'url0303', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAt, {unit}, 'attack', 'GrowthFormation')
			end
		end
		
		if(Difficulty == 3) then
			for i = 1, 2 * ScenarioInfo.NumPlayers - (Difficulty * Random(1,2) + ( Random(1,4) - Random(1,2) ) ) do
				unit = CreateUnitHPR( 'url0202', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAt, {unit}, 'attack', 'GrowthFormation')
			end
		end
		CybranAt:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[1]))
		CybranAt:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[2]))
		CybranAt:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[3]))
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIMap, 5*60)
	end
end

function SpawnAttacksAIMapAir()
	if (AirBaseAI == true) then
		local CybranAt2 = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('ForwardBase_Patrol3')
		local AttackPoint = {'SpawnTMLLandHARD','Blank Marker 03', 'Def_Patrol4'}
		-- T3
		for i = 1, Random(4,8) do
			unit = CreateUnitHPR( 'ura0203', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAt2, {unit}, 'attack', 'GrowthFormation')
		end
		CybranAt2:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[1]))
		CybranAt2:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[2]))
		CybranAt2:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[3]))
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIMapAir, 4*60)
	end
end

function OnShiftF4()
    ForkThread(TestSpawn)
end

function KillPlayer1()
	GetArmyBrain('Player1'):OnDefeat()
	ForkThread(PlayersLose)
	DeadCommand = DeadCommand + 1
end

function KillPlayer2()
	GetArmyBrain('Player2'):OnDefeat()
	ForkThread(PlayersLose)
	DeadCommand = DeadCommand + 1
end

function KillPlayer3()
	GetArmyBrain('Player3'):OnDefeat()
	ForkThread(PlayersLose)
	DeadCommand = DeadCommand + 1
end

function KillPlayer4()
	GetArmyBrain('Player4'):OnDefeat()
	ForkThread(PlayersLose)
	DeadCommand = DeadCommand + 1
end

function KillPlayer5()
	GetArmyBrain('Player5'):OnDefeat()
	ForkThread(PlayersLose)
	DeadCommand = DeadCommand + 1
end

function KillPlayer6()
	GetArmyBrain('Player6'):OnDefeat()
	ForkThread(PlayersLose)
	DeadCommand = DeadCommand + 1
end

function OnShiftF5()
	BonusChaos = true
	ScenarioFramework.CreateTimerTrigger(SpawnCDRBonusAngel, 1*5)
end

function TestSpawn()
	if (true) then
		local TestUEFAt = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		for i = 1, Random(2,8) do
			unit = CreateUnitHPR( 'url0107', 'Cybran',  78, 31.2, 126.5, 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(TestUEFAt, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(1,7) do
			unit = CreateUnitHPR( 'url0106', 'Cybran', 82, 31.2, 130.5, 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(TestUEFAt, {unit}, 'attack', 'GrowthFormation')
		end
		if(Difficulty >= 2) then
			for i = 1, Random(1,4) do
				unit = CreateUnitHPR( 'url0202', 'Cybran', 80.5, 31.39, 132.5, 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(TestUEFAt, {unit}, 'attack', 'GrowthFormation')
			end
		end
		
		if(Difficulty == 3) then
			for i = 1, Random(1,2) do
				unit = CreateUnitHPR( 'url0111', 'Cybran', 76.5, 31.39, 132.5, 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(TestUEFAt, {unit}, 'attack', 'GrowthFormation')
			end
		end
		for i = 1, 8 do
			TestUEFAt:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition('Def_Patrol' .. Random(1,6)))
			TestUEFAt:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition('AttackPoint' .. Random(1,3)))
		end
	end
end

function OnShiftF3()
    ForkThread(TestSpawnArnold)
end

function TestSpawnArnold()
	if (true) then
		local TestUEFDef = ArmyBrains[Arnold]:MakePlatoon('', '')
		local unit = false
		local UnitsArnold = {'uel0201', 'uel0202', 'uel0106', 'uel0101', 'uel0201', 'uel0103'}
		local PatrolPoints = {'Def_Patrol1','Def_Patrol2','Def_Patrol3','Def_Patrol4','Def_Patrol5','Def_Patrol6','AttackPoint1','AttackPoint2','AttackPoint3','AirBase_Patrol1','AirBase_Patrol2', 'AirBase_Patrol3', 'AirBase_Patrol4'}
		for i = 1, 1 * Random(1,4) do
			unit = CreateUnitHPR(UnitsArnold[Random(1,6)], 'Arnold', 274.5, 31.64844, 94.5, 0, 0, 0 )
			ArmyBrains[Arnold]:AssignUnitsToPlatoon(TestUEFDef, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, 6 do
			TestUEFDef:Patrol(ScenarioUtils.MarkerToPosition(PatrolPoints[Random(1,13)]))
		end
	end
end

function SpawnAttacksAIBase()
	if (AirBaseAI == true) then
		local CybranAt2 = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		local AttackPoint = {'AttackPoint1','AttackPoint2', 'AttackPoint3'}
		-- T1
		for i = 1, Random(2,6) * Random(1,2) do
			unit = CreateUnitHPR( 'url0107', 'Cybran', 82, 31.10, 135.5, 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAt2, {unit}, 'attack', 'GrowthFormation')
		end
		if(Difficulty >= 2) then
			for i = 1, Random(1,3) do
				unit = CreateUnitHPR( 'url0202', 'Cybran', 82, 31.10, 135.5, 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAt2, {unit}, 'attack', 'GrowthFormation')
			end
		end
		CybranAt2:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[1]))
		CybranAt2:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[2]))
		CybranAt2:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[3]))
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIBase, 3*60)
	end
end

function SpawnAirFinalPatrol()
	local CybranFinalAir = ArmyBrains[Cybran]:MakePlatoon('', '')
	local unit = false
	local UnitsAirFinal = {'ura0101', 'ura0102', 'ura0103', 'xra0105', 'ura0203', 'ura0103', 'ura0101', 'ura0102'}
	-- T1
	for i = 1, 28 do
		unit = CreateUnitHPR( UnitsAirFinal[Random(1,8)], 'Cybran', 250, 31.10346, 385.5, 0, 0, 0 )
		ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranFinalAir, {unit}, 'attack', 'GrowthFormation')
	end
	
	if(Difficulty == 3) then
		for i = 1, 26 do
			unit = CreateUnitHPR( UnitsAirFinal[Random(1,8)], 'Cybran', 250, 31.10346, 385.5, 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranFinalAir, {unit}, 'attack', 'GrowthFormation')
		end
	end
	
	for k, v in CybranFinalAir:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Final_Base_Air_Patrol')))
	end
end
----------
-- End Game
----------
function KillBase()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = true
        ScenarioFramework.Dialogue(OpStrings.E01_M07_090, false, true)
        WaitSeconds(10)
            local units = GetUnitsInRect(ScenarioUtils.AreaToRect('M6Area'))
            local cybranUnits = {}
            if(units) then
                for k, v in units do
                    if(not v:IsDead() and v:GetAIBrain() == ArmyBrains[Cybran]) then
                        table.insert(cybranUnits, v)
                    end
                end
            end
            if(cybranUnits) then
                for k, v in cybranUnits do
                    v:Kill()
                end
            end
            WaitSeconds(1.5)
        ScenarioFramework.Dialogue(OpStrings.E01_M07_080, PlayerWin, true)
    end
end

function PlayerWin()
    ScenarioFramework.Dialogue(OpStrings.E01_M07_130, StartKillGame, true)
end
function PlayersLose()
	if (DeadCommand == NumPlayers) then
		ScenarioFramework.PlayerLose()
	end
end

function StartKillGame()
    ForkThread(KillGame)
end

function KillGame()
    if(not ScenarioInfo.OpComplete) then
        WaitSeconds(15)
    end
    local secondaries = Objectives.IsComplete(ScenarioInfo.M7S1)
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, secondaries)
end

function TestTransport()
	if(AirTran == true and Difficulty >= 2) then
		local Cybranland = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		-- T1
		local TransportsT1 = ScenarioUtils.CreateArmyGroup('Cybran', 'AirTransportsM1')
		
		for i = 1, 1 * Difficulty + Random(1,3) do
			unit = CreateUnitHPR( 'url0202', 'Cybran', 238.5, 31.10346, 253.5, 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(Cybranland, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, 4 do
			unit = CreateUnitHPR( 'url0103', 'Cybran', 238.5, 31.10346, 253.5, 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(Cybranland, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, 2 do
			unit = CreateUnitHPR( 'url0107', 'Cybran', 238.5, 31.10346, 253.5, 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(Cybranland, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.AttachUnitsToTransports(Cybranland:GetPlatoonUnits(), TransportsT1)
		IssueTransportUnload(TransportsT1, ScenarioPlatoonAI.PlatoonChooseRandomNonNegative(ArmyBrains[Cybran], ScenarioUtils.ChainToPositions('Patrol_Base'), 3))
		ScenarioFramework.PlatoonPatrolRoute(Cybranland, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Patrol_Base')))
		
		ScenarioFramework.CreateTimerTrigger(TestTransport, 3*60)
	end
end
-----------
-- Mission 1
-----------

function TestHPPlayers(PlayerCDR)
	if not Buffs['HpPlayer'] then
            BuffBlueprint {
                Name = 'HpPlayer',
                DisplayName = 'HpPlayer',
                BuffType = 'ACUUPGRADEDMG',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = 3000, 
                        Mult = 1.0,
                    },
                    Regen = {
                        Add = 5,
                        Mult = 1.0,
                    },
                },
            } 	
		end
	Buff.ApplyBuff(PlayerCDR, 'HpPlayer')
end

function HPACUNigh(BotCDR)
	if not Buffs['HpBot'] then
            BuffBlueprint {
                Name = 'HpBot',
                DisplayName = 'HpBot',
                BuffType = 'ACUUPGRADEDMG',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = 25000, 
                        Mult = 1.0,
                    },
					BuildRate = {
						Add = 16,
						Mult = 1.0,
					},
                },
            } 	
		end
	Buff.ApplyBuff(BotCDR, 'HpBot')
end

function HPHard(BotCDR)
	if not Buffs['HpH'] then
            BuffBlueprint {
                Name = 'HpH',
                DisplayName = 'HpH',
                BuffType = 'ACUUPGRADEDMG',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = 18200, 
                        Mult = 1.0,
                    },
					BuildRate = {
						Add = 12,
						Mult = 1.0,
					},
                },
            } 	
		end
	Buff.ApplyBuff(BotCDR, 'HpH')
end

function HPBonusACU()
	if not Buffs['HpBonusACU1'] then
            BuffBlueprint {
                Name = 'HpBonusACU1',
                DisplayName = 'HpBonusACU1',
                BuffType = 'ACUUPGRADEDMG',
                Stacks = 'ALWAYS',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = 12000, 
                        Mult = 1.0,
                    },
                    Regen = {
                        Add = 6,
                        Mult = 1.0,
                    },
                },
            } 	
		end
	Buff.ApplyBuff(ScenarioInfo.CDRAngel, 'HpBonusACU1')
end

function WarpBotCom()
	ScenarioFramework.FakeTeleportUnit(ScenarioInfo.AllyPlayerBot, true)
	UEFAllyAI.DisableBase()
end
function IntroMission1()
    ScenarioInfo.MissionNumber = 1

    -- Player CDR
	ScenarioInfo.Player1CDR = ScenarioFramework.SpawnCommander('Player1', 'Commander', 'Warp', true, true, KillPlayer1)
	ScenarioFramework.PauseUnitDeath(ScenarioInfo.Player1CDR)
	if (MOD == 1) then
		TestHPPlayers(ScenarioInfo.Player1CDR)
	end
	if(ScenarioInfo.UseUEFAllyAI and MOD == 1) then
		ScenarioInfo.AllyPlayerBot = ScenarioFramework.SpawnCommander('Arnold', 'ACUBot', 'Warp', 'Командующий Лин', false, WarpBotCom)
		ScenarioInfo.AllyPlayerBot:SetProductionPerSecondMass(7);
		ScenarioInfo.AllyPlayerBot:SetAutoOvercharge(true)
	    ScenarioInfo.AllyPlayerBot:SetProductionPerSecondEnergy(75);
		UEFAllyAI.BotBaseAI()
		if (MOD == 1) then
			TestHPPlayers(ScenarioInfo.AllyPlayerBot)
		end
	end
    -- spawn coop players too
	WaitSeconds(1)
    local tblArmy = ListArmies()
    if tblArmy[ScenarioInfo.Player2] then
        ScenarioInfo.Player2CDR = ScenarioFramework.SpawnCommander('Player2', 'Commander', 'Warp', true, false, KillPlayer2)
		ScenarioFramework.PauseUnitDeath(ScenarioInfo.Player2CDR)
		if (MOD == 1) then
			TestHPPlayers(ScenarioInfo.Player2CDR)
		end
    end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player3] then
        ScenarioInfo.Player3CDR = ScenarioFramework.SpawnCommander('Player3', 'Commander', 'Warp', true, false, KillPlayer3)
		ScenarioFramework.PauseUnitDeath(ScenarioInfo.Player3CDR)
		if (MOD == 1) then
			TestHPPlayers(ScenarioInfo.Player3CDR)
		end
    end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player4] then
        ScenarioInfo.Player4CDR = ScenarioFramework.SpawnCommander('Player4', 'Commander', 'Warp', true, false, KillPlayer4)
		ScenarioFramework.PauseUnitDeath(ScenarioInfo.Player4CDR)
		if (MOD == 1) then
			TestHPPlayers(ScenarioInfo.Player4CDR)
		end
    end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player5] then
        ScenarioInfo.Player5CDR = ScenarioFramework.SpawnCommander('Player5', 'Commander', 'Warp', true, false, KillPlayer5)
		ScenarioFramework.PauseUnitDeath(ScenarioInfo.Player5CDR)
		if (MOD == 1) then
			TestHPPlayers(ScenarioInfo.Player5CDR)
		end
    end
	WaitSeconds(1)
	if tblArmy[ScenarioInfo.Player6] then
        ScenarioInfo.Player6CDR = ScenarioFramework.SpawnCommander('Player6', 'Commander', 'Warp', true, false, KillPlayer6)
		ScenarioFramework.PauseUnitDeath(ScenarioInfo.Player6CDR)
		if (MOD == 1) then
			TestHPPlayers(ScenarioInfo.Player6CDR)
		end
    end
	
	WaitSeconds(1)
	
	if( ScenarioInfo.NumPlayers == 1 ) then
		ScenarioFramework.SimAnnouncement('Приветствуем тебя ' .. ArmyBrains[Player1].Nickname .. ' желаем насладится игрой! Удачи.')
		WaitSeconds(2)
		ScenarioFramework.SimAnnouncement(' Удачи. С тобой была команда Balance Team. ')
	elseif(ScenarioInfo.NumPlayers == 2) then
		ScenarioFramework.SimAnnouncement('Приветствуем вас ' .. ArmyBrains[Player1].Nickname .. ' ,' .. ArmyBrains[Player2].Nickname .. ' желаем насладится игрой! Удачи.')
		WaitSeconds(2)
		ScenarioFramework.SimAnnouncement(' Удачи. С вами была команда Balance Team. ')
	elseif(ScenarioInfo.NumPlayers == 3) then
		ScenarioFramework.SimAnnouncement('Приветствуем вас ' .. ArmyBrains[Player1].Nickname .. ' ,' .. ArmyBrains[Player2].Nickname .. ' ,' .. ArmyBrains[Player3].Nickname .. ' желаем насладится игрой! Удачи.')
		WaitSeconds(2)
		ScenarioFramework.SimAnnouncement(' Удачи. С вами была команда Balance Team. ')
	elseif(ScenarioInfo.NumPlayers == 4) then
		ScenarioFramework.SimAnnouncement('Приветствуем вас ' .. ArmyBrains[Player1].Nickname .. ' ,' .. ArmyBrains[Player2].Nickname .. ' ,' .. ArmyBrains[Player3].Nickname .. ' ,' .. ArmyBrains[Player4].Nickname ..' желаем насладится игрой! Удачи.')
		WaitSeconds(2)
		ScenarioFramework.SimAnnouncement(' Удачи. С вами была команда Balance Team. ')
	elseif(ScenarioInfo.NumPlayers == 5) then
		WaitSeconds(2)
		ScenarioFramework.SimAnnouncement('Охохо, сколько же тут игроков.. ну приветствуем вас ', ''.. ArmyBrains[Player1].Nickname .. ', ' .. ArmyBrains[Player2].Nickname .. ' ')
		WaitSeconds(4)
		ScenarioFramework.SimAnnouncement(' '.. ArmyBrains[Player3].Nickname .. ', ' .. ArmyBrains[Player4].Nickname .. ', ' .. ArmyBrains[Player5].Nickname .. ' желаем вам провести хорошо время!')
		WaitSeconds(4)
		ScenarioFramework.SimAnnouncement(' Удачи. С вами была команда Balance Team. ')
	elseif(ScenarioInfo.NumPlayers == 6) then
		WaitSeconds(2)
		ScenarioFramework.SimAnnouncement('Охохо, сколько же тут игроков.. очень много.. ну тогда мы.. привествуем вас ', ''.. ArmyBrains[Player1].Nickname .. ', ' .. ArmyBrains[Player2].Nickname .. ' ')
		WaitSeconds(4)
		ScenarioFramework.SimAnnouncement(' '.. ArmyBrains[Player3].Nickname .. ', ' .. ArmyBrains[Player4].Nickname .. ', ' .. ArmyBrains[Player5].Nickname .. ', ' .. ArmyBrains[Player6].Nickname .. ' желаем вам провести хорошо время!')
		WaitSeconds(4)
		ScenarioFramework.SimAnnouncement(' Удачи. С вами была команда Balance Team. ')
	end
	WaitSeconds(2)
    ScenarioFramework.Dialogue(OpStrings.E01_M01_040, nil)
	WaitSeconds(1)
	ForkThread(StartMission1Part1)
	
	ScenarioFramework.RestrictEnhancements({'EngineeringT2UEF',
                                            'DamageStabilizationUEF',
                                            'HeavyAntiMatterDeeKeyUEF',
                                            'LeftPodUEF',
                                            'ResourceAllocationUEF',
                                            'RightPodUEF',
                                            'ShieldUEF',
											'RegenUEF',
                                            'ShieldGeneratorFieldUEF',
                                            'T3EngineeringUEF',
											'TacticalNukeMissileUEF',
											'TeleporterUEF'})
end


function StartMission1Part1()
    -- Primary Objective 1
    ScenarioInfo.M1P1 = Objectives.ArmyStatCompare(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M1P2_Title,     -- title
        OpStrings.OpE01_M1P2_Desc,      -- description
        'build',                        -- action
        {                               -- target
            Armies = {'HumanPlayers'},
            StatName = 'Units_Active',
            CompareOp = '>=',
            Value = 1 * ScenarioInfo.NumPlayers,
            Category = categories.ueb1103,
            ShowProgress = true,
        }
   )
    ScenarioInfo.M1P1:AddResultCallback(
        function()
            StartMission1Part2()
        end
   )

    -- Primary Objective 1 Reminder
    ScenarioFramework.CreateTimerTrigger(M1P1Reminder1, M1P1Time)
end

function M1P1Reminder1()
    if(ScenarioInfo.M1P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_065)
        ScenarioFramework.CreateTimerTrigger(M1P1Reminder2, SubsequentTime)
    end
end

function M1P1Reminder2()
    if(ScenarioInfo.M1P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_070)
        ScenarioFramework.CreateTimerTrigger(M1P1Reminder3, SubsequentTime)
    end
end

function M1P1Reminder3()
    if(ScenarioInfo.M1P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M1P1Reminder1, SubsequentTime)
    end
end


function StartMission1Part2()
    -- Adjust buildable categories for Player
    -- Primary Objective 2
    ScenarioInfo.M1P2 = Objectives.ArmyStatCompare(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M1P1_Title,     -- title
        OpStrings.OpE01_M1P1_Desc,      -- description
        'build',                        -- action
        {                               -- target
            Armies = {'HumanPlayers'},
            StatName = 'Units_Active',
            CompareOp = '>=',
            Value = 3 * ScenarioInfo.NumPlayers,
            Category = categories.ueb1101,
            ShowProgress = true,
        }
   )
    ScenarioInfo.M1P2:AddResultCallback(
        function()
            IntroMission2()
        end
   )

    -- Primary Objective 2 Reminder
    ScenarioFramework.CreateTimerTrigger(M1P2Reminder1, M1P2Time)
end

function M1P2Reminder1()
    if(ScenarioInfo.M1P2.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_050)
        ScenarioFramework.CreateTimerTrigger(M1P2Reminder2, SubsequentTime)
    end
end

function M1P2Reminder2()
    if(ScenarioInfo.M1P2.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_055)
        ScenarioFramework.CreateTimerTrigger(M1P2Reminder3, SubsequentTime)
    end
end

function M1P2Reminder3()
    if(ScenarioInfo.M1P2.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M1P2Reminder1, SubsequentTime)
    end
end

-----------
-- Mission 2
-----------
function IntroMission2()
    ScenarioInfo.MissionNumber = 2
    ScenarioFramework.Dialogue(OpStrings.E01_M02_010, nil)
	WaitSeconds(1)
	ForkThread(StartMission2)
end

function StartMission2()
    -- Primary Objective 1
    ScenarioInfo.M2P1 = Objectives.ArmyStatCompare(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M2P1_Title,     -- title
        OpStrings.OpE01_M2P1_Desc,      -- description
        'build',                        -- action
        {                               -- target
            Armies = {'HumanPlayers'},
            StatName = 'Units_Active',
            CompareOp = '>=',
            Value = ScenarioInfo.NumPlayers,
            Category = categories.ueb0101,
            ShowProgress = true,
        }
   )
    ScenarioInfo.M2P1:AddResultCallback(
        function()
            IntroMission3()
        end
   )

    -- M2P1 Objective Reminder
    ScenarioFramework.CreateTimerTrigger(M2P1Reminder1, M2P1Time)
end

function M2P1Reminder1()
    if(ScenarioInfo.M2P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M02_020)
        ScenarioFramework.CreateTimerTrigger(M2P1Reminder2, SubsequentTime)
    end
end

function M2P1Reminder2()
    if(ScenarioInfo.M2P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M02_025)
        ScenarioFramework.CreateTimerTrigger(M2P1Reminder3, SubsequentTime)
    end
end

function M2P1Reminder3()
    if(ScenarioInfo.M2P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M2P1Reminder1, SubsequentTime)
    end
end

-----------
-- Mission 3
-----------
function IntroMission3()
    ScenarioInfo.MissionNumber = 3
    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.uel0201 + -- T1 Medium Tank
        categories.ueb3101 + -- T1 Radar
		categories.uel0103 -- T1 Arty
    )
	ScenarioFramework.RestrictEnhancements({'EngineeringT2UEF',
                                            'DamageStabilizationUEF',
                                            'LeftPodUEF',
                                            'ResourceAllocationUEF',
                                            'RightPodUEF',
                                            'ShieldUEF',
                                            'ShieldGeneratorFieldUEF',
                                            'T3EngineeringUEF',
											'TacticalNukeMissileUEF',
											'TeleporterUEF'})
	if (Dif4 == 1 and Difficulty == 3) then
		NighBot1 = true
		ScenarioFramework.CreateTimerTrigger(SpawnAirCybranNigh, 1*60)
	end
    ScenarioFramework.Dialogue(OpStrings.E01_M03_010, StartMission3)
end

function SpawnAirCybranNigh()
	if (NighBot1 == true) then
		local CybranAir = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnTMLLandHARD')
		local AttackPoint = {'FlyoverDeath', 'SpawnAir', 'Blank Marker 11', 'TankStop2'}
		-- T3
		
		for i = 1, 13 do
			unit = CreateUnitHPR( 'ura0103', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		if(Dif4 == 1) then
			for i = 1, Random(1,11) do
				unit = CreateUnitHPR( 'ura0102', 'Cybran', 490, 37, 122, 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranAir, {unit}, 'attack', 'GrowthFormation')
			end
		end
		CybranAir:MoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[1]), false)
		CybranAir:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[2]))
		CybranAir:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[3]))
		CybranAir:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[4]))
		ScenarioFramework.CreateTimerTrigger(SpawnAirCybranNigh, 3*60)
	end
end

function StartMission3()
    -- Primary Objective 1
    ScenarioInfo.M3P1 = Objectives.ArmyStatCompare(
        'primary',                                              -- type
        'incomplete',                                           -- complete
        LOCF(OpStrings.OpE01_M3P1_Title, M3P1_TanksRequired),   -- title
        LOCF(OpStrings.OpE01_M3P1_Desc, M3P1_TanksRequired),    -- description
        'build',                                                -- action
        {                                                       -- target
            Armies = {'HumanPlayers'},
            StatName = 'Units_Active',
            CompareOp = '>=',
            Value = M3P1_TanksRequired,
            Category = categories.uel0201,
            ShowProgress = true,
        }
   )
    ScenarioInfo.M3P1:AddResultCallback(
        function()
            IntroMission4()
        end
   )
   
   ScenarioInfo.M3P2 = Objectives.ArmyStatCompare(
        'secondary',                                              -- type
        'incomplete',                                           -- complete
        LOCF(OpStrings.OpE01_M3P2_Title, M3P1_ArtyRequired),   -- title
        LOCF(OpStrings.OpE01_M3P2_Desc, M3P1_ArtyRequired),    -- description
        'build',                                                -- action
        {                                                       -- target
            Armies = {'HumanPlayers'},
            StatName = 'Units_Active',
            CompareOp = '>=',
            Value = M3P1_ArtyRequired,
            Category = categories.uel0103,
            ShowProgress = true,
        }
   )
   
   ScenarioInfo.M3P2:AddResultCallback(
        function()
            GodJopP2()
        end
   )
    -- M3P1 Objective Reminder
    ScenarioFramework.CreateTimerTrigger(M3P1Reminder1, M3P1Time)
end

function SpawnCDRBonusAngel()
	if(BonusChaos == true and Difficulty >= 1) then
		ScenarioUtils.CreateArmyGroup('Cybran', 'BaseEventCybranM2')
		local Marker1 = ScenarioFramework.CreateVisibleAreaLocation(30, 'MoveCDR', 0, ArmyBrains[Player1])
		Cinematics.EnterNISMode()
		Cinematics.CameraMoveToMarker('BonusCam1', 0)
		WaitSeconds(2)
		Cinematics.CameraMoveToMarker('BonusCam2', 4)
		ScenarioInfo.CDRAngel = ScenarioFramework.SpawnCommander('Cybran', 'CDRBonusAngel', 'Warp', 'Командующий Rox_', false, false)
		ScenarioInfo.CDRAngel:SetAutoOvercharge(true)
		WaitSeconds(1)
		Cinematics.CameraTrackEntity(ScenarioInfo.UnitNames[Cybran]['CDRBonusAngel'], 40, 3)
		WaitSeconds(3)
		IssueMove({ScenarioInfo.CDRAngel}, ScenarioUtils.MarkerToPosition('Blank Marker 05'))
		WaitSeconds(1)
		IssueMove({ScenarioInfo.CDRAngel}, ScenarioUtils.MarkerToPosition('SPAWNCOMMAND'))
		WaitSeconds(2)
		ScenarioInfo.healthValueACUB = ScenarioInfo.CDRAngel:GetHealth()
		WaitSeconds(2)
		ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('MoveCDR'), 30)
		Marker1:Destroy()
		WaitSeconds(1)
		Cinematics.ExitNISMode()
		ForkThread(HPBonusACU)
	end
end

function GodJopP2()
	ScenarioFramework.Dialogue(OpStrings.GodJopF_1)
end

function ArnoldFlyover()
    WaitSeconds(10)
    ScenarioInfo.Flyover = ScenarioUtils.CreateArmyGroupAsPlatoon('Arnold', 'FlyOver', 'StaggeredChevronFormation')
    ScenarioInfo.Flyover.PlatoonData = {}
    ScenarioInfo.Flyover.PlatoonData.MoveRoute = {'FlyoverDeath'}
    ScenarioPlatoonAI.MoveToThread(ScenarioInfo.Flyover)
    WaitSeconds(15)
    KillFlyover()
    --ScenarioFramework.CreateAreaTrigger(KillFlyover, ScenarioUtils.AreaToRect('FlyoverDeath'), categories.UEF,
      -- true, false, ArmyBrains[Arnold], table.getn(ScenarioInfo.Flyover:GetPlatoonUnits()))
end

function KillFlyover()
    ScenarioInfo.Flyover:Destroy()
end

function M3P1Reminder1()
    if(ScenarioInfo.M3P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M03_050)
        ScenarioFramework.CreateTimerTrigger(M3P1Reminder2, SubsequentTime)
    end
end

function M3P1Reminder2()
    if(ScenarioInfo.M3P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M03_060)
        ScenarioFramework.CreateTimerTrigger(M3P1Reminder3, SubsequentTime)
    end
end

function M3P1Reminder3()
    if(ScenarioInfo.M3P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M3P1Reminder1, SubsequentTime)
    end
end

-----------
-- Mission 4
-----------
function IntroMission4()
    ScenarioInfo.MissionNumber = 4
	
	if (Dif4 == 1 and Difficulty == 3) then
		NighBot1 = false
	end
    -- Adjust buildable categories for Cybran in case Player captures them
    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.urb0101 + -- T1 Land Factory
        categories.urb1101 + -- T1 Power Generator
        categories.urb1103 + -- T1 Mass Extractor
        categories.urb3101 + -- T1 Radar
        categories.url0105 + -- T1 Engineer
        categories.url0107 + -- T1 Assault Bot
        categories.urb5101   -- Wall 
    )

    ScenarioInfo.Radar = ScenarioUtils.CreateArmyUnit('Cybran', 'Radar')
    ScenarioInfo.Radar:SetCapturable(false)
    ScenarioInfo.Radar:SetReclaimable(false)
    local radarPatrol = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'RadarPatrol', 'AttackFormation')
    for i = 1, 3 do
        radarPatrol:Patrol(ScenarioUtils.MarkerToPosition('Radar_Patrol' .. i))
    end
	
	
    ScenarioUtils.CreateArmyGroup('Cybran', 'RadarStructures')

    ScenarioFramework.Dialogue(OpStrings.E01_M04_010, StartMission4)
end

function StartMission4()
    ScenarioFramework.SetPlayableArea('M3Area')

    -- Primary Objective 1
    ScenarioInfo.M4P1 = Objectives.KillOrCapture (
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M4P1_Title,     -- title
        OpStrings.OpE01_M4P1_Desc,      -- description
        {                               -- target
            Units = {ScenarioInfo.Radar},
        }
   )
    ScenarioInfo.M4P1:AddResultCallback(
        function(result)
            IntroMission5()
        end
   )

    -- M4P1 Objective Reminder
    ScenarioFramework.CreateTimerTrigger(M4P1Reminder1, M4P1Time)
end

function M4P1Reminder1()
    if(ScenarioInfo.M4P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M04_050)
        ScenarioFramework.CreateTimerTrigger(M4P1Reminder2, SubsequentTime)
    end
end

function M4P1Reminder2()
    if(ScenarioInfo.M4P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M04_055)
        ScenarioFramework.CreateTimerTrigger(M4P1Reminder3, SubsequentTime)
    end
end

function M4P1Reminder3()
    if(ScenarioInfo.M4P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M4P1Reminder1, SubsequentTime)
    end
end


function SpawnAttacksAIMapTML()
	if (AirBaseAI == true) then
		local CybranTML = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnTMLLandHARD')
		local AttackPoint = {'AttackTML','Def_Patrol6', 'Blank Marker 08', 'Def_Patrol1'}
		-- T3
		
		for i = 1, 2 * Random(1,3) do
			unit = CreateUnitHPR( 'url0111', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranTML, {unit}, 'attack', 'GrowthFormation')
		end
		
		if(MOD == 1) then
			for i = 1, Random(1,6) do
				unit = CreateUnitHPR( 'url0107', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranTML, {unit}, 'attack', 'GrowthFormation')
			end
		end
		
		if(Dif4 == 1) then
			for i = 1, Random(1,2) do
				unit = CreateUnitHPR( 'url0303', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranTML, {unit}, 'attack', 'GrowthFormation')
			end
		end
		CybranTML:MoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[1]), false)
		CybranTML:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[2]))
		CybranTML:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[3]))
		CybranTML:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[4]))
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIMapTML, 6*60)
	end
end

function SpawnAttackCiviliansBase()
	local CybranCA = ArmyBrains[Cybran]:MakePlatoon('', '')
	local unit = false
	local SpawnPoint = ScenarioUtils.MarkerToPosition('Cybran')
	local AttackPoint = {'ForwardBase_Patrol4','EastResearch_Patrol2'}
	-- T3
	
	for i = 1, 2 * Random(1,4) do
		unit = CreateUnitHPR( 'url0107', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
		ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranCA, {unit}, 'attack', 'GrowthFormation')
	end
	
	for i = 1, 3 * Random(1,2) do
		unit = CreateUnitHPR( 'url0106', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
		ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranCA, {unit}, 'attack', 'GrowthFormation')
	end
	
	for i = 1, 1 * Random(1,6) do
		unit = CreateUnitHPR( 'url0103', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
		ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranCA, {unit}, 'attack', 'GrowthFormation')
	end
	
	if(Difficulty == 2) then
	for i = 1, 2 * Random(1,2) do
		unit = CreateUnitHPR( 'url0202', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
		ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranCA, {unit}, 'attack', 'GrowthFormation')
	end
	elseif(Difficulty == 3) then
		for i = 1, 3 * Random(1,3) do
			unit = CreateUnitHPR( 'url0202', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranCA, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, 1 * Random(1,3) do
			unit = CreateUnitHPR( 'url0303', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranCA, {unit}, 'attack', 'GrowthFormation')
		end
	end
	CybranCA:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[1]))
	CybranCA:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[2]))
	ScenarioFramework.CreateTimerTrigger(SpawnAttackCiviliansBase, 1*60)
end

function SpawnAirAttackNOTank()
	if (AirBaseAI == true) then
		local CybranTML = ArmyBrains[Cybran]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnTMLLandHARD')
		local AttackPoint = {'AttackTML','Def_Patrol6', 'Blank Marker 08', 'Def_Patrol1'}
		-- T3
		
		for i = 1, 4 * Random(1,3) do
			unit = CreateUnitHPR( 'url0111', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
			ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranTML, {unit}, 'attack', 'GrowthFormation')
		end
		
		if(MOD == 1) then
			for i = 1, Random(1,4) do
				unit = CreateUnitHPR( 'url0107', 'Cybran', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 0, 0 )
				ArmyBrains[Cybran]:AssignUnitsToPlatoon(CybranTML, {unit}, 'attack', 'GrowthFormation')
			end
		end
		CybranTML:MoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[1]), false)
		CybranTML:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[2]))
		CybranTML:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[3]))
		CybranTML:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackPoint[4]))
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIMapTML, 6*60)
	end
end

function SpawnAirTestBot()
	ScenarioFramework.CreateTimerTrigger(TestTransport, 4*60)
end
-----------
-- Mission 5
-----------
function IntroMission5()
    ScenarioInfo.MissionNumber = 5
	local tblArmy = ListArmies()
	for i = 1, ScenarioInfo.NumPlayers do
		ScenarioFramework.SetSharedUnitCap(230 * i)
	end

    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.uel0101 +
        categories.uel0104 +
        categories.uel0106 + 
		categories.ueb1202 +
		categories.ueb1106
    )
	
	ForkThread(SpawnAirTestBot)
	
	ScenarioFramework.RestrictEnhancements({'EngineeringT2UEF',
                                            'RightPodUEF',
                                            'ShieldUEF',
											'RegenUEF',
                                            'ShieldGeneratorFieldUEF',
                                            'T3EngineeringUEF',
											'TacticalNukeMissileUEF',
											'TeleporterUEF'})
	
	if(Difficulty == 1) then
		ScenarioFramework.RemoveRestrictionForAllHumans(categories.ueb0201 + categories.ueb0202 + categories.uel0202 + categories.uel0111 + categories.uel0208 + categories.uel0205 + categories.zeb9501 + categories.ueb4201 + categories.ueb2301)
		ScenarioFramework.SimAnnouncement('Передаем чертежи Т2 завода и техники + инженер')
	elseif(Difficulty == 2) then
		ScenarioFramework.RemoveRestrictionForAllHumans(categories.ueb0201 + categories.ueb0202 + categories.uel0202 + categories.uel0111 + categories.uel0208 + categories.uel0205 + categories.zeb9501 + categories.ueb4201 + categories.ueb2301)
		ScenarioFramework.SimAnnouncement('Передаем чертежи Т2 завода и техники + инженер')
	elseif(Difficulty == 3) then
		ScenarioFramework.RemoveRestrictionForAllHumans(categories.ueb0201 + categories.ueb0202 + categories.uel0202 + categories.uel0111 + categories.uel0208 + categories.uel0205 + categories.zeb9501 + categories.ueb4201 + categories.ueb2301)
		ScenarioFramework.SimAnnouncement('Передаем чертежи Т2 завода и техники + инженер')
	end

    -- Adjust buildable categories for Cybran in case Player captures them
    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.url0101 + -- Land Scout
        categories.url0103 + -- Mobile Light Artillery
        categories.url0104 + -- Mobile AA Gun
        categories.url0106 + -- Light Assault Bot
        categories.urb0102 + -- T1 Air Factory
		categories.url0105 + -- T1 Engineer
		categories.urb0101 +  -- T1 Land Factory
		categories.urb0102 +
		categories.ura0101 +
		categories.ura0102 +
		categories.ura0103
	)

    -- Cybran Air Base
	ScenarioUtils.CreateArmyGroup('Cybran', 'AirBasePreBuilt')
	ScenarioUtils.CreateArmyGroup('Cybran', 'DopEnergy_D' .. Difficulty)
	ScenarioUtils.CreateArmyGroup('Cybran', 'EngM1')
	
	if(Difficulty >= 2) then
		ScenarioUtils.CreateArmyGroup('Cybran', 'DefenseAirBase')
	end
	
	if (Difficulty >= 2) then
		AirBaseAI = true
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIMap, 6*60)
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIBase, 5*60)
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIMapTML, 6*60)
		ScenarioFramework.CreateTimerTrigger(SpawnAttacksAIMapAir, 6*60)
	end
    -- Cybran Air Base Patrols
    for i = 1, 3 do
        local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'AirBasePatrol_D' .. i, 'AttackFormation')
        platoon.PlatoonData = {}
        platoon.PlatoonData.PatrolChain = 'AirBase_Chain'
        platoon:ForkAIThread(ScenarioPlatoonAI.RandomPatrolThread)
    end
	CybranAI.CybranAirBaseAI()
	
    ScenarioFramework.Dialogue(OpStrings.E01_M05_010, StartMission5)
end

function StartMission5()
    ScenarioFramework.CreateAreaTrigger(Leopard11Dialogue, ScenarioUtils.AreaToRect('Cybran_Air_Base'),
        categories.ALLUNITS, true, false, ArmyBrains[Player1], 1, false)

    -- Primary Objective 1
    ScenarioInfo.M5P1 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M5P1_Title,     -- title
        OpStrings.OpE01_M5P1_Desc,      -- description
		'kill',
        {                               -- target
            FlashVisible = true,
            MarkUnits = true,
            Requirements = {
                {Area = 'Cybran_Air_Base', Category = categories.FACTORY, CompareOp = '<=', Value = 0, ArmyIndex = Cybran},
            },
        }
	)
    ScenarioInfo.M5P1:AddResultCallback(
        function(result)
            ForkThread(ArnoldFlyover)
            IntroMission6()
        end
   )
	ForkThread(CybranEcoMini)
    -- M5P1 Objective Reminder
    ScenarioFramework.CreateTimerTrigger(M5P1Reminder1, M5P1Time)

    ScenarioFramework.SetPlayableArea('M4Area')
end

function CybranEcoMini()
	ArmyBrains[Cybran]:GiveStorage('MASS', 1500)
	ArmyBrains[Cybran]:GiveStorage('ENERGY', 7500)
    while(true) do
        ArmyBrains[Cybran]:GiveResource('MASS', 200)
        ArmyBrains[Cybran]:GiveResource('ENERGY',250)
        WaitSeconds(1.5)
    end
end

function Leopard11Dialogue()
    ScenarioFramework.Dialogue(OpStrings.E01_M01_030)

    -- Kickoff UEF Taunts
    ScenarioFramework.CreateTimerTrigger(Taunt, Random(600, 900))
end

function Taunt()
    if(leopardTaunt <= 8) then
        ScenarioFramework.Dialogue(OpStrings['TAUNT' .. leopardTaunt])
        leopardTaunt = leopardTaunt + 1
        ScenarioFramework.CreateTimerTrigger(Taunt, Random(300, 500))
    end
	if(leopardTaunt > 8) then
		leopardTaunt = 1
		ScenarioFramework.CreateTimerTrigger(Taunt, Random(100, 200))
	end
end

function M5P1Reminder1()
    if(ScenarioInfo.M5P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M05_050)
        ScenarioFramework.CreateTimerTrigger(M5P1Reminder2, SubsequentTime)
    end
end

function M5P1Reminder2()
    if(ScenarioInfo.M5P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M05_055)
        ScenarioFramework.CreateTimerTrigger(M5P1Reminder3, SubsequentTime)
    end
end

function M5P1Reminder3()
    if(ScenarioInfo.M5P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M5P1Reminder1, SubsequentTime)
    end
end

-----------
-- Mission 6
-----------
function IntroMission6()
    ScenarioInfo.MissionNumber = 6
	
	AirTran = false
    -- Cybran Defensive Line
    ScenarioInfo.DefensiveLine = ScenarioUtils.CreateArmyGroup('Cybran', 'DefensiveLineStructures_D' .. ScenarioInfo.Options.Difficulty)
    for i = 1, ScenarioInfo.Options.Difficulty do
        local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'DefensiveLinePatrol_D' .. i, 'AttackFormation')
        platoon.PlatoonData = {}
        platoon.PlatoonData.PatrolChain = 'DefensiveLine_Chain'
        platoon:ForkAIThread(ScenarioPlatoonAI.RandomPatrolThread)
    end
    ScenarioUtils.CreateArmyGroup('Cybran', 'DefensiveLineMass')
	if(Difficulty == 3) then
		AirBaseAI = false
	end
	
	AttackTr = true
    if(ScenarioInfo.Options.Difficulty >= 2) then
        ScenarioUtils.CreateArmyGroup('Cybran', 'DefensiveLineWalls_D2')
        ScenarioUtils.CreateArmyGroup('Cybran', 'DefensiveLineEngineers')
    end
	CybranAI.AIDefense()
    ScenarioFramework.Dialogue(OpStrings.E01_M05_020, StartMission6)
end

function StartMission6()
	
	local tblArmy = ListArmies()
	for i = 1, ScenarioInfo.NumPlayers do
		ScenarioFramework.SetSharedUnitCap(380 * i)
	end

    ScenarioFramework.Dialogue(OpStrings.E01_M05_025)
    ScenarioFramework.SetPlayableArea('M5Area')
	ScenarioInfo.M6P1 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M6P1_Title,     -- title
        OpStrings.OpE01_M6P1_Desc,      -- description
		'kill',
        {                               -- target
            FlashVisible = true,
            MarkUnits = true,
            Requirements = {
                {Area = 'AreaDefense', Category = categories.DEFENSE * categories.STRUCTURE - categories.WALL, CompareOp = '<=', Value = 0, ArmyIndex = Cybran},
            },
        }
	)
    ScenarioInfo.M6P1:AddResultCallback(
        function(result)
            IntroMission7()
        end
   )

    -- M6P1 Objective Reminder
    ScenarioFramework.CreateTimerTrigger(M6P1Reminder1, M6P1Time)
end

function M6P1Reminder1()
    if(ScenarioInfo.M6P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M06_050)
        ScenarioFramework.CreateTimerTrigger(M6P1Reminder2, SubsequentTime)
    end
end

function M6P1Reminder2()
    if(ScenarioInfo.M6P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M06_055)
        ScenarioFramework.CreateTimerTrigger(M6P1Reminder3, SubsequentTime)
    end
end

function M6P1Reminder3()
    if(ScenarioInfo.M6P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M6P1Reminder1, SubsequentTime)
    end
end
-----------
-- Mission 7
-----------
function IntroMission7()
    ScenarioInfo.MissionNumber = 7
	
	for i = 1, ScenarioInfo.NumPlayers do
		ScenarioFramework.SetSharedUnitCap(500* i)
	end

    ScenarioFramework.Dialogue(OpStrings.E01_M06_020)

    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.uea0102 + -- Interceptor
        categories.uea0103   -- Attack Bomber
    )
	
    -- Player has access to HeavyAntiMatterCannon and DamageStabilization

    -- Adjust buildable categories for Cybran in case Player captures them
    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.urb2104 + -- T1 AA Tower
        categories.urb3101 + -- T1 Radar
        categories.ura0101 + -- Air Scout
        categories.ura0102 + -- Interceptor
        categories.ura0103 + -- Attack Bomber
        categories.urb1105 + -- Energy Storage
        categories.urb1104 + -- T2 Mass Fabricator
		categories.url0208 +
        categories.urb1201   -- T2 Power Generator
    )

    -- Eastern R&D
    ScenarioUtils.CreateArmyGroup('EastResearch', 'EastResearchStructures_Undamaged')
	ScenarioUtils.CreateArmyGroup('EastResearch', 'Defense_PRO')
    local structures = ScenarioUtils.CreateArmyGroup('EastResearch', 'EastResearchStructures_Damaged')
    for k, v in structures do
        v:AdjustHealth(v, Random(0, v:GetHealth()) * -1)
    end
	
	local EngResearch = ScenarioUtils.CreateArmyGroupAsPlatoon('EastResearch', 'EastResearchEngineers', 'AttackFormation')
    EngResearch.PlatoonData = {}
    EngResearch.PlatoonData.PatrolChain = 'EastResearch_Chain'
    EngResearch:ForkAIThread(ScenarioPlatoonAI.PatrolThread)
	

    -- Disable light artillery
    ScenarioInfo.LightArtillery = ScenarioUtils.CreateArmyUnit('EastResearch', 'LightArtillery')
    ScenarioInfo.LightArtillery:SetWeaponEnabledByLabel('MainGun', false)
	
    -- Cybran Main Base
	
    ScenarioInfo.CybranCDR = ScenarioUtils.CreateArmyUnit('Cybran', 'CommanderCybran')
	if(Difficulty == 3) then
		HPHard(ScenarioInfo.CybranCDR)
	end
	if(Dif4 == 1) then
		HPACUNigh(ScenarioInfo.CybranCDR)
	end
	local cdrPlatoon = ArmyBrains[Cybran]:MakePlatoon('','')
    ArmyBrains[Cybran]:AssignUnitsToPlatoon(cdrPlatoon, {ScenarioInfo.CybranCDR}, 'Attack', 'AttackFormation')
	cdrPlatoon.PlatoonData = {}
    cdrPlatoon.PlatoonData.PatrolChain = 'MainBase_Chain'
    cdrPlatoon:ForkAIThread(ScenarioPlatoonAI.PatrolThread)
	WaitSeconds(4)
	-- ScenarioInfo.CybranCDR:SetAutoOvercharge(true)
	
	if(Difficulty == 2) then
		ScenarioInfo.CybranCDR:CreateEnhancement('CoolingUpgradeCybran')
	elseif(Difficulty == 3) then
		ScenarioInfo.CybranCDR:CreateEnhancement('CoolingUpgradeCybran')
		ScenarioInfo.CybranCDR:CreateEnhancement('MicrowaveLaserGeneratorCybran')
	end
    ScenarioInfo.CybranCDR:SetCustomName(LOC '{i CDR_Leopard_11}')
	
    ScenarioFramework.PauseUnitDeath(ScenarioInfo.CybranCDR)
 
    ScenarioUtils.CreateArmyGroup('Cybran', 'WallsBase') 
	if(Difficulty == 3) then
		ScenarioUtils.CreateArmyGroup('Cybran', 'Defense_Hard')
	end
	
	ScenarioUtils.CreateArmyGroup('Cybran', 'GroundDefense_D' .. Difficulty)
	
	CybranAI.MainBaseAI()
	
	ForkThread(SpawnAttackCiviliansBase)

    -- Research Attack
    local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'ResearchAttack', 'AttackFormation')
    platoon.PlatoonData = {}
    platoon.PlatoonData.PatrolChain = 'Research_Chain'
    platoon:ForkAIThread(ScenarioPlatoonAI.PatrolThread)

    -- Cybran Power Base
    ScenarioInfo.PowerGens = ScenarioUtils.CreateArmyGroup('NeutralStructures', 'Gens')
	
	ScenarioUtils.CreateArmyGroup('NeutralStructures', 'BuildZD', true)
	ScenarioUtils.CreateArmyGroup('NeutralStructures', 'WALLS')
	ScenarioUtils.CreateArmyGroup('Cybran', 'Cybran_Building_D' .. Difficulty)
	
	local Un1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'Cybran_Power_G1_D' ..Difficulty, 'AttackFormation')
    Un1.PlatoonData = {}
    Un1.PlatoonData.PatrolChain = 'PowerBaseTank_Patrol_1'
    Un1:ForkAIThread(ScenarioPlatoonAI.PatrolThread)

	local Un2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'Cybran_Power_G2_D' ..Difficulty, 'AttackFormation')
    Un2.PlatoonData = {}
    Un2.PlatoonData.PatrolChain = 'PowerBaseTank_Patrol_2'
    Un2:ForkAIThread(ScenarioPlatoonAI.PatrolThread)
	
	local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'Cybran_Power_G3_D1', 'AttackFormation')
	for k, v in units:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Power_BasePatrol_Air')))
	end
	if(Difficulty >= 2) then
		ForkThread(SpawnAirFinalPatrol)
	end
	if(Difficulty >= 2) then
		local Un3 = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'Cybran_Power_G2_D2', 'AttackFormation')
		Un3.PlatoonData = {}
		Un3.PlatoonData.PatrolChain = 'PowerBaseTank_Patrol_3'
		Un3:ForkAIThread(ScenarioPlatoonAI.PatrolThread)
    end
    for k, v in ScenarioInfo.PowerGens do
        v:SetDoNotTarget(true)
    end
    
	
	
	if(Difficulty == 3) then
		local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'Cybran_Power_G3_D3', 'AttackFormation')
		for k, v in units:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Power_BasePatrol_Air')))
		end
	end
    ScenarioFramework.Dialogue(OpStrings.E01_M07_010, StartMission7)
end

function StartMission7()
    ScenarioFramework.SetPlayableArea('M6Area')

    -- Primary Objective 1
    ScenarioInfo.M7P1 = Objectives.KillOrCapture(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M7P1_Title,     -- title
        OpStrings.OpE01_M7P1_Desc,      -- description
        {                               -- target
            Units = {ScenarioInfo.CybranCDR},
        }
   )
    ScenarioInfo.M7P1:AddResultCallback(
        function()
            -- ScenarioFramework.EndOperationCamera(ScenarioInfo.CybranCDR)

            -- enemy CDR destroyed
            ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.CybranCDR)
			AttackTr = false
            ForkThread(KillBase)
        end
   )

    -- M7P1 Objective Reminders
    ScenarioFramework.CreateTimerTrigger(M7P1Reminder1, M7P1Time)

    -- Eastern R&D ally
    ScenarioFramework.Dialogue(OpStrings.E01_M07_020, RDAlly)

    -- After 1 minutes: Secondary Objective 1 revealed
    ScenarioFramework.CreateTimerTrigger(RevealSO1, 60)

    -- After 5 minutes: Thompson VO
    ScenarioFramework.CreateTimerTrigger(ThompsonStrategy, 300)
end

function RDAlly()
    for _, player in ScenarioInfo.HumanPlayers do
        SetAlliance(player, EastResearch, 'Ally')
        SetAlliance(EastResearch, player, 'Ally')
    end
end

function RevealSO1()
    ScenarioFramework.Dialogue(OpStrings.E01_M07_030, AssignSO1)
end

function AssignSO1()
    -- Secondary Objective 1
    ScenarioInfo.M7S1 = Objectives.Capture(
        'secondary',                    -- type
        'incomplete',                   -- complete
        OpStrings.OpE01_M7S1_Title,     -- title
        OpStrings.OpE01_M7S1_Desc,      -- description
        {                               -- target
            NumRequired = 1,
            FlashVisible = true,
            Units = ScenarioInfo.PowerGens,
        }
   )
    ScenarioInfo.M7S1:AddResultCallback(
        function(result)
            if(result) then
                if(ScenarioInfo.CybranCDR and not ScenarioInfo.CybranCDR:IsDead()) then
                    ScenarioFramework.Dialogue(OpStrings.E01_M07_100)
                end
                ForkThread(LRAAttack)
            end
        end
   )
end

function ThompsonStrategy()
    ScenarioFramework.Dialogue(OpStrings.E01_M07_040)
end

function LRAAttack()
    ScenarioInfo.LightArtillery:SetWeaponEnabledByLabel('MainGun', true)
end

function M7P1Reminder1()
    if(ScenarioInfo.M7P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M07_160)
        ScenarioFramework.CreateTimerTrigger(M7P1Reminder2, SubsequentTime)
    end
end

function M7P1Reminder2()
    if(ScenarioInfo.M7P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M07_165)
        ScenarioFramework.CreateTimerTrigger(M7P1Reminder3, SubsequentTime)
    end
end

function M7P1Reminder3()
    if(ScenarioInfo.M7P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.E01_M01_060)
        ScenarioFramework.CreateTimerTrigger(M7P1Reminder1, SubsequentTime)
    end
end