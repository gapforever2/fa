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
local SPAIFileName = '/lua/scenarioplatoonai.lua'
local Entity = import('/lua/sim/Entity.lua').Entity;
local EffectUtilities = import('/lua/effectutilities.lua')
local Cinematics = import('/lua/cinematics.lua')
local Explosions = import('/lua/defaultexplosions.lua')
local PingGroups = import('/lua/ScenarioFramework.lua').PingGroups
local Behaviors = import('/lua/ai/opai/OpBehaviors.lua')
local PrefetchUtils = import('/lua/sim/PrefetchUtilities.lua')
local OpStrings = import('/maps/X1CA_001/X1CA_001_strings.lua')
local FactionData = import('/lua/factions.lua')

ScenarioInfo.Player1 = 1
ScenarioInfo.Player2 = 2
ScenarioInfo.BotCity = 3
ScenarioInfo.Player3 = 4
ScenarioInfo.Player4 = 5
ScenarioInfo.Player5 = 6
ScenarioInfo.Player6 = 7

local Player1 = ScenarioInfo.Player1
local Player2 = ScenarioInfo.Player2
local Player3 = ScenarioInfo.Player3
local Player4 = ScenarioInfo.Player4

local Bot = ScenarioInfo.Player5
local City = ScenarioInfo.BotCity
local Enemy = ScenarioInfo.Player6
local NukeDeadArea1 = { {text = '<LOC X03_T01_430_010>[{i ZanAishahesh}]: [Language Not Recognized]', vid = 'X03_Zan-Aishahesh_T01_04347.sfd', bank = 'X03_VO', cue = 'X03_Zan-Aishahesh_T01_04347', faction = 'Seraphim'} }

local DestBase = { {text = '<LOC X06_M01_012_010>[{i HQ}]: База Серафим была уничтожена! Поздравляю', vid = 'X01_HQ_M01_04848.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'NONE'}, }
local RhizaFletcher = { 
{text = '<LOC X06_M01_012_010>[{i Rhiza}]: Серафим продвигаются Генерал Флетчер! Хоть что то сделаете!', vid = 'X01_Rhiza_M02_03676.sfd', bank = 'X01_VO', cue = 'NONE', faction = 'Aeon'},
{text = '<LOC X06_M01_012_010>[{i Fletcher}]: Отправил парочку отрядов вам в помощь, постарайтесь продержать Итот серафим как можно дольше.', vid = 'X01_Fletcher_M01_04816.sfd', bank = 'X01_VO', cue = 'NONE', faction = 'UEF'},
{text = '<LOC X06_M01_012_010>[{i Fletcher}]: Вам необходимо продержатся пару минут, скоро зонд выстрелит по ним и Итоты врага будут уничтожены.', vid = 'X01_Fletcher_M01_04816.sfd', bank = 'X01_VO', cue = 'NONE', faction = 'UEF'}, 
}
local AttackIntro = {'Atsh1', 'Atsh2', 'Atsh3', 'Player2', 'SpawnACUFletcherArea1', 'Player4'}
local SeraDead = {
  {text = '<LOC X01_M03_297_010>[{i Hall}]: All enemy forces have been defeated and Fort Clarke is safe. Well done, Commander. This is an important victory for us.', vid = 'X01_Hall_M03_04258.sfd', bank = 'X01_VO', cue = 'X01_Hall_M03_04258', faction = 'UEF'},
}
local DeadBMKAeon = { 
{text = '<LOC X06_M01_012_010>[{i Rhiza}]: Нет! Нет! Нет! Идиот ты зачем туда пошел...Принцесса извиняюсь, я не смогла сбереть этого командующего..', vid = 'X01_Rhiza_M02_03676.sfd', bank = 'X01_VO', cue = 'NONE', faction = 'Aeon'}, 
{text = '<LOC X06_M01_012_010>[{i Princess}]: Эх..Командующий Риза, возвращайтесь с другими командующеми Эон, на верных напал КИИ.', vid = 'X03_Princess_M01_03287.sfd', bank = 'X03_VO', cue = 'NONE', faction = 'Aeon'},
{text = '<LOC X06_M01_012_010>[{i Rhiza}]: Да Принцесса, начинаю протокол возврата.. 3..2..1..', vid = 'X01_Rhiza_M02_03676.sfd', bank = 'X01_VO', cue = 'NONE', faction = 'Aeon'},
}
local Area3 = false
local Sera4_1 = '<LOC X01_M03_OBJ_010_030>Командующий Серафим'

local Sera4_2 = '<LOC X01_M03_OBJ_010_040>Уничтожьте командующего пока его войска не дошли до Форта Кларк'

local Nuke1 = '<LOC X06_M01_012_010> Союзная Боеголовка'

local Nuke2 = '<LOC X06_M01_012_010> Защитите союзную боеголовку, если ее уничтожат, вы проиграете.'

local SeraWin = { {text = '<LOC X01_T01_290_010>[{i ShunUllevash}]: [Language Not Recognized]', vid = 'X01_Shun-Ullevash_T01_04342.sfd', bank = 'X01_VO', cue = 'X01_Shun-Ullevash_T01_04342', faction = 'Seraphim'}, }
local X01_M03_OBJ_010_010 = '<LOC X01_M03_OBJ_010_010>Здание администрации Форт Кларк'

local X01_M03_OBJ_010_020 = '<LOC X01_M03_OBJ_010_020>Командующии Коалиции находятся в здании администрации, защитите их!'

local Base1Order1 = '<LOC X01_M01_OBJ_010_010>Destroy the Order Bases'
local Base1Order2 = '<LOC X01_M01_OBJ_010_020>Move north across the channel and eliminate the designated Order bases.'

local Gari1 = '<LOC X01_M02_OBJ_010_050>Defeat Order Commander Gari'

local Gari2 = '<LOC X01_M02_OBJ_010_060>Gari must be defeated if Fort Clarke is to be saved.'

local GariAttack1 = '<LOC X06_M01_012_010>Атака Гари'

local GariAttack2 = '<LOC X06_M01_012_010>Отбейте атаку командующего Гари'

local Gari3 = {
  {text = '<LOC X01_T01_190_010>[{i Gari}]: The Seraphim will never be defeated!', vid = 'X01_Gari_T01_04530.sfd', bank = 'X01_VO', cue = 'X01_Gari_T01_04530', faction = 'Aeon'},
  {text = '<LOC X01_M02_320_010>[{i HQ}]: That sure was a pretty sight. Maybe the next Order commander won\'t be so eager to flap her jaw. HQ out.', vid = 'X01_HQ_M02_03675.sfd', bank = 'X01_VO', cue = 'X01_HQ_M02_03675', faction = 'NONE'},
}
local AirBot = true
local ECOCity = true
local OpenGari = { {text = '<LOC X01_M02_350_010>[{i HQ}]: Assuming you live through this, head up there and destroy Gari once and for all. HQ out.', vid = 'X01_HQ_M02_04852.sfd', bank = 'X01_VO', cue = 'X01_HQ_M02_04852', faction = 'NONE'}, }
local AttackNuke = true
local Event = true

local ColA1_1 = '<LOC X06_M01_012_010> Колоссы противника'
local ColA1_2 = '<LOC X06_M01_012_010> Противник использует колоссов для защиты, уничтожьте их если сможете.'
local ColA1_3 = { {text = '<LOC X06_M01_012_010>[{i HQ}]: Колоссы были уничтожены. Поздравляю', vid = 'X01_HQ_M01_04848.sfd', bank = 'X05_VO', cue = 'NONE', faction = 'NONE'}, }
local ECO = true
local OrderBase = { {text = '<LOC X01_M01_105_010>[{i Fletcher}]: Quit messin\' around and destroy those bases!', vid = 'X01_Fletcher_M01_04816.sfd', bank = 'X01_VO', cue = 'X01_Fletcher_M01_04816', faction = 'UEF'} }
local FletcherLeft = { {text = '<LOC X06_M01_012_010>[{i Fletcher}]: Командующие, я больше не смогу вам помогать тут на направлении.. Форт кларк атакован Серафим, мне придется вас покинуть', vid = 'X01_Fletcher_M01_04816.sfd', bank = 'X01_VO', cue = 'NONE', faction = 'UEF'} }
local OrderBaseDead = { {text = '<LOC X01_M01_140_010>[{i HQ}]: That\'s both of them. Proceed inland. HQ out.', vid = 'X01_HQ_M01_03625.sfd', bank = 'X01_VO', cue = 'X01_HQ_M01_03625', faction = 'NONE'}, }
local CityDio = {
  {text = '<LOC X01_M02_010_010>[{i HQ}]: Constable Graham is on the horn. I\'m patching him through.', vid = 'X01_HQ_M02_02893.sfd', bank = 'X01_VO', cue = 'X01_HQ_M02_02893', faction = 'NONE'},
  {text = '<LOC X01_M02_011_010>[{i Graham}]: Commander, Order units have overwhelmed most of our defenses. We\'ve been cut off from Fort Clarke, and General Fletcher is unable to get reinforcements to us. We need your help.', vid = 'X01_Graham_M02_04003.sfd', bank = 'X01_VO', cue = 'X01_Graham_M02_04003', faction = 'UEF'},
  {text = '<LOC X01_M02_012_010>[{i Hall}]: Change in plans, Commander. Fletcher\'s going to have to hold Fort Clarke a bit longer on his own -- you will defend the civilians and eradicate any enemy forces in the area.', vid = 'X01_Hall_M02_04004.sfd', bank = 'X01_VO', cue = 'X01_Hall_M02_04004', faction = 'UEF'},
  {text = '<LOC X01_M02_013_010>[{i Gari}]: I shall cleanse everyone on this planet! You are fools to stand against our might!', vid = 'X01_Gari_M02_02896.sfd', bank = 'X01_VO', cue = 'X01_Gari_M02_02896', faction = 'Aeon'},
}
local DeadCityArea2 = { {text = '<LOC X01_M02_040_010>[{i Graham}]: Oh no ... they\'ve wiped out the entire town. All those civilians ... dead.', vid = 'X01_Graham_M02_03643.sfd', bank = 'X01_VO', cue = 'X01_Graham_M02_03643', faction = 'UEF'}, }
local DefCityA1 = '<LOC X01_M02_OBJ_010_010>Defend the Civilians at Seabring'

local Points = {'NukeArea1_1', 'NukeArea1_2', 'NukeArea1_3', 'NukeArea1_4'}

local DefCityA2 = '<LOC X01_M02_OBJ_010_020>At least 50% of the civilian structures must survive.'
local BaseA2Order2_1 = '<LOC X01_M02_OBJ_010_070>Destroy the Order Assault Bases'

local BaseA2Order2_2 = '<LOC X01_M02_OBJ_010_080>Destroy the designated Order bases to break the siege against the town of Seabring.'
local SafeCity = { {text = '<LOC X01_M02_039_010>[{i Graham}]: The civilians are safe. I am forever in your in debt, Commander.', vid = 'X01_Graham_M02_04236.sfd', bank = 'X01_VO', cue = 'X01_Graham_M02_04236', faction = 'UEF'}, }
function OnPopulate(scenario)
	ScenarioUtils.InitializeScenarioArmies()
	PlayerCol()
end

function OnStart(self)
	ForkThread(SpawnComs)
end

function PlayerCol()
	local colors = {
		['Player1'] = {190, 20, 30},
        ['Player2'] = {250, 250, 0},
        ['Player3'] = {255, 255, 255},
		['Player4'] = {80, 250, 100}
    }
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end
	
	SetIgnorePlayableRect(Enemy, true)
	
	ScenarioFramework.SetUEFAlly1Color(Bot)
	ScenarioFramework.SetUEFAlly2Color(City)
	ScenarioFramework.SetAeonEvilColor(Enemy)
	local Players = {Player1, Player2, Player3, Player4, Bot}
	for k, v in Players do
		ScenarioFramework.AddRestriction(v, categories.url0002 + categories.ueb2401 + categories.xab1401 + categories.xab2307 + categories.url0401 + categories.urb2306)
	end
end

function SpawnComs()
	ForkThread(AntiPlayersSetting)
	WaitSeconds(1)
	ForkThread(StartArea2)
	ScenarioUtils.CreateArmyGroup('BotCity', 'Walls')
end

local RandFractions = {
  [1] = 'UefCommander',
  [2] = 'AeonCommander',
  [3] = 'CybranCommander'
}

local Fractions = {
  [1] = 'UefCommander',
  [2] = 'AeonCommander',
  [3] = 'CybranCommander',
  [4] = function()
      return RandFractions[Random(1,3)]
  end
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
            ScenarioFramework.CreateUnitDeathTrigger(function() ForkThread(LoseAllPlayers) end, ScenarioInfo['Player' .. Id .. 'CDR'])
        end
    end
end

function LoseAllPlayers()
	ScenarioFramework.PlayerLose()
end

function AntiPlayersSetting()
	WaitSeconds(2)
	ForkThread(GiveAmmoAnti1)
	WaitSeconds(4)
	ForkThread(DestCollosA1)
end
function GiveAmmoAnti1()
	local antinukes1 = ArmyBrains[Enemy]:GetListOfUnits(categories.uab4302, false)
	ScenarioInfo.Victoria = ScenarioUtils.CreateArmyUnit('Player6', 'VictoriaBot')
    for k,v in antinukes1 do
        v:GiveTacticalSiloAmmo(7)
    end
end
function DestCollosA1()
	WaitSeconds(1)
	ForkThread(QCollosDead)
end
function QCollosDead()
	ScenarioInfo.COlA1 = Objectives.CategoriesInArea(
        'secondary',
        'incomplete',
        ColA1_1,
        ColA1_2,
		'kill',
        {                               
            MarkUnits = true,
			ShowFaction = 'Aeon',
            Requirements = {
                {
                    Area = 'BaseOrder1',
                    Category = (categories.ual0401),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Enemy,
                },
            },
        }
    )
	ScenarioInfo.COlA1:AddResultCallback(
        function(result)
            if(result) then
				ScenarioFramework.Dialogue(ColA1_3)
            end
        end
    )
end

function StartArea2()
	ScenarioFramework.SetPlayableArea('Area2', false)
	WaitSeconds(0.5)
	ScenarioUtils.CreateArmyGroup('BotCity', 'Walls')
	ForkThread(SpawnEco)
	WaitSeconds(0.5)
	ScenarioUtils.CreateArmyGroup('Player6', 'Base1_2')
	ScenarioUtils.CreateArmyGroup('Player6', 'Base1_1')
	ForkThread(SpawnLandPatrol)
	WaitSeconds(1)
	ForkThread(CapPlayers2)
	WaitSeconds(1)
	ForkThread(InitialStart)
	WaitSeconds(1)
	ForkThread(SpawnNukeCity)
	WaitSeconds(60)
	ForkThread(SpawnCarrier)
	WaitSeconds(240)
	ForkThread(SpawnAttackA1Naval)
	WaitSeconds(180)
	ForkThread(SpawnAttackA1T2Naval)
end


function SpawnCarrier()
	if not ScenarioInfo.Victoria:IsDead() then
		local CarrierOrder = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnCarrier')
		
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR('uas0303', 'Player6', SpawnPoint[1] + Random(3,12), SpawnPoint[2], SpawnPoint[3] - Random(3,10), 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(CarrierOrder, {unit}, 'attack', 'GrowthFormation')
		end
		for k, v in CarrierOrder:GetPlatoonUnits() do
            IssueMove({v}, ScenarioUtils.MarkerToPosition('NukeArea1_4'))
        end
		
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnCarrier, CarrierOrder)
	end
end

function SpawnDefPatrolUefAir()
	if not ScenarioInfo.Victoria:IsDead() then
		local AirBot = ArmyBrains[Bot]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnUefBotAir')
		
		for i = 1, Random(3,7) do
			unit = CreateUnitHPR('uea0102', 'Player5', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(AirBot, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(1,4) do
			unit = CreateUnitHPR('uea0103', 'Player5', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(AirBot, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(1,2) do
			unit = CreateUnitHPR('uea0203', 'Player5', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(AirBot, {unit}, 'attack', 'GrowthFormation')
		end
		
		for k, v in AirBot:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('PatrolArea1UEF')))
		end
		
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnDefPatrolUefAir, AirBot)
	end
end

function SpawnAttackA1Naval()
	if not ScenarioInfo.Victoria:IsDead() then
		local NavalA1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnNavalA1')
		
		for i = 1, Random(1,3) do
			unit = CreateUnitHPR('uas0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1Order, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR('uas0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1Order, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(1,2) do
			unit = CreateUnitHPR('uas0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1Order, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(1,4) do
			unit = CreateUnitHPR('uas0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1Order, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(0,2) do
			unit = CreateUnitHPR('uas0201', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(NavalA1Order, 'AttackNavalA1')
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnAttackA1Naval, NavalA1Order)
	end
end

function SpawnAttackA1T2Naval()
	if not ScenarioInfo.Victoria:IsDead() then
		local NavalA1T2Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnNavalA1')
		
		for i = 1, Random(1,4) do
			unit = CreateUnitHPR('uas0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1T2Order, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(0,2) do
			unit = CreateUnitHPR('uas0201', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1T2Order, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(0,2) do
			unit = CreateUnitHPR('uas0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(NavalA1T2Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(NavalA1T2Order, 'AttackNavalA1')
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnAttackA1T2Naval, NavalA1T2Order)
	end
end
function InitialStart()
	WaitSeconds(1)
	local ExpOrder1 = ScenarioFramework.GetCatUnitsInArea(categories.ual0401, 'Area2', ArmyBrains[Enemy])
	for k,v in ExpOrder1 do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('ExpArea1Patrol')))
    end
	WaitSeconds(1)
	local sACUOrder = ScenarioFramework.GetCatUnitsInArea(categories.ual0301, 'Area2', ArmyBrains[Enemy])
	for k,v in sACUOrder do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area1sACU_Patrol')))
    end
	WaitSeconds(1)
	Cinematics.EnterNISMode()
	WaitSeconds(1)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_Initial'), 0)
	ScenarioFramework.CreateVisibleAreaLocation( 60, ScenarioUtils.MarkerToPosition( 'Marker1' ), 18, ArmyBrains[Bot] )
	ScenarioFramework.CreateVisibleAreaLocation( 60, ScenarioUtils.MarkerToPosition( 'NukeArea1_2' ), 25, ArmyBrains[Bot] )
	ScenarioFramework.CreateVisibleAreaLocation( 60, ScenarioUtils.MarkerToPosition( 'NukeArea1_3' ), 19, ArmyBrains[Bot] )
	ScenarioFramework.CreateVisibleAreaLocation( 60, ScenarioUtils.MarkerToPosition( 'NukeArea1_4' ), 21, ArmyBrains[Bot] )
	WaitSeconds(2)
	ScenarioFramework.Dialogue(OpStrings.X01_M01_010, nil, true)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam1_1'), 6)
	WaitSeconds(1)
	ScenarioInfo.QAIEvent = ScenarioUtils.CreateArmyUnit('Player6', 'EventQAI')
	WaitSeconds(1.5)
	ScenarioFramework.Dialogue(OpStrings.X01_M01_011, nil, true)
	IssueMove({ScenarioInfo.QAIEvent}, ScenarioUtils.MarkerToPosition('Blank Marker 57'))
	WaitSeconds(1)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam1_2'), 7)
	WaitSeconds(2)
	ScenarioFramework.Dialogue(OpStrings.X01_M01_012, nil, true)
	WaitSeconds(2)
	ScenarioFramework.CreateVisibleAreaLocation( 160, ScenarioUtils.MarkerToPosition( 'Blank Marker 63' ), 8, ArmyBrains[Bot] )
	WaitSeconds(1)
	ScenarioInfo.IntroGun = ScenarioUtils.CreateArmyGroup('Player6', 'CAMTech2SH')
	for k, v in ScenarioInfo.IntroGun do
        local platoon = ArmyBrains[Enemy]:MakePlatoon('', '')
        ArmyBrains[Enemy]:AssignUnitsToPlatoon(platoon, {v}, 'Attack', 'None')
        platoon:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition(AttackIntro[Random(1, 6)]))
    end
	WaitSeconds(1)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam1_3'), 4)
	ScenarioUtils.CreateArmyGroup('Player5', 'InBDead', true)
	ScenarioUtils.CreateArmyGroup('Player5', 'InB1')
	WaitSeconds(1)
	ScenarioFramework.CreateVisibleAreaLocation( 80, ScenarioUtils.MarkerToPosition( 'Mass 05' ), 8, ArmyBrains[Bot] )
	WaitSeconds(1)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam1_4'), 6)
	WaitSeconds(1)
	ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('Marker1'), 60)
	ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('NukeArea1_2'), 60)
	ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('NukeArea1_3'), 60)
	ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('NukeArea1_4'), 60)
	ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('Blank Marker 39'), 60)
	ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('Blank Marker 49'), 60)
	ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('Blank Marker 41'), 60)
	WaitSeconds(1)
	Cinematics.ExitNISMode()
	WaitSeconds(1)
	SpawnCom(1)
	WaitSeconds(0.5)
	for k, unit in ScenarioInfo.IntroGun do
        if ( unit and not unit:IsDead()) then
            unit:Kill()
        end
    end
	WaitSeconds(1)
	ScenarioFramework.Dialogue(OpStrings.X01_M01_014, nil, true)
	WaitSeconds(1)
	SpawnCom(2)
	WaitSeconds(1)
	SpawnCom(3)
	WaitSeconds(1)
	SpawnCom(4)
	WaitSeconds(1)
	ScenarioInfo.CDRBot = ScenarioUtils.CreateArmyUnit('Player5', 'CdrArea1')
	ScenarioInfo.CDRBot:PlayCommanderWarpInEffect()
	WaitSeconds(2)
	ForkThread(ZDOrder)
	WaitSeconds(200)
	ForkThread(TransportsAttack)
end

function TransportsAttack()
	if not ScenarioInfo.Victoria:IsDead() then
		for i = 1, Random(1,12) do
			TransA1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'TransAttack' .. Random(1,4), 'AttackFormation')
		
			ScenarioFramework.PlatoonAttackWithTransports(TransA1, 'Area1V' .. Random(1,4), 'Area1A' .. Random(1,5), true)
		end
		ScenarioFramework.CreatePlatoonDeathTrigger(RestTran1, TransA1)
	end
end

function RestTran1()
	ForkThread(RestTran2)
end

function RestTran2()
	WaitSeconds(120)
	ForkThread(TransportsAttack)
end

function SpawnLandPatrol()
	Land1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'LandIn1', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(Land1, 'In1')
	
	Land2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'LandIn2', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(Land2, 'In2')
	
	Land3_1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'In3_1', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(Land3_1, 'In3')
	Land3_2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'In3_2', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(Land3_2, 'In3')
	Land3_3 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'In3_3', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(Land3_3, 'In3')
	
end

function SpawnNukeCity()
	ScenarioInfo.NukeCity = ScenarioUtils.CreateArmyUnit('BotCity', 'NukeArea1')
	ScenarioInfo.NukeCity:SetVeterancy(1)
	ScenarioInfo.NukeCity:SetHealth(nil, 3260)
	WaitSeconds(3)
	ScenarioFramework.PauseUnitDeath(ScenarioInfo.NukeCity)
	ForkThread(DefendNuke)
	Air1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'AIRIn', 'GrowthFormation')
    for k, v in Air1:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('AirIn')))
    end
	WaitSeconds(2300)
	ForkThread(AttackNukeCityArea1)
end


function AttackNukeCityArea1()
	if(AttackNuke == true) then
		ScenarioInfo.NukeCity:GiveNukeSiloAmmo(1)
		WaitSeconds(10)
		IssueNuke({ScenarioInfo.NukeCity}, ScenarioUtils.MarkerToPosition(Points[Random(1, 4)]))
	end
	ForkThread(LocNuke2)
end

function LocNuke2()
	WaitSeconds(320)
	ForkThread(AttackNukeCityArea1)
end


function DefendNuke()
	ScenarioInfo.M1P6 = Objectives.Protect(
        'primary',                              # type
        'incomplete',                           # complete
        Nuke1,          # title
        Nuke2,          # description
        {                                       # target
            Units = {ScenarioInfo.NukeCity},
            PercentProgress = true,
        }
    )
    ScenarioInfo.M1P6:AddResultCallback(
        function(result)
            if(result == false) then
				ForkThread(PlayersDeathCity)
				ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.NukeCity)
				ForkThread(BMKNuke)
				ScenarioFramework.Dialogue(NukeDeadArea1, NoNukeCity, false)
            end
        end
    )
end
function BMKNuke()
	WaitSeconds(2.5)
	ScenarioInfo.NukeBMK = ScenarioUtils.CreateArmyUnit('City', 'NukeBMKEffect')
	ScenarioInfo.NukeBMK:Kill()
end
function NoNukeCity()
	WaitSeconds(1)
	AttackNuke = false
	Event = false
end
function CapPlayers2()
	SetArmyUnitCap(Player1, 750)
	SetArmyUnitCap(Player2, 750)
	SetArmyUnitCap(Player3, 750)
	SetArmyUnitCap(Player4, 750)
	SetArmyUnitCap(Bot, 800)
	SetArmyUnitCap(City, 550)
	SetArmyUnitCap(Enemy, 3000)
end

function ZDOrder()
	WaitSeconds(2)
	ForkThread(DestBaseOrder)
end
function DestBaseOrder()
	ScenarioInfo.Z1 = Objectives.CategoriesInArea(
        'primary',
        'incomplete',
        Base1Order1,
        Base1Order2,
		'kill',
        {                               
            MarkUnits = true,
			ShowFaction = 'Aeon',
            Requirements = {
                {
                    Area = 'BaseOrder1',
                    Category = (categories.FACTORY - categories.uaa0310 + categories.ual0301),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Enemy,
                },
            },
        }
    )
	ScenarioInfo.Z1:AddResultCallback(
        function(result)
            if(result) then
				ScenarioFramework.Dialogue(OrderBaseDead)
				ForkThread(Area3)
            end
        end
    )
end

function Area3()
	ScenarioInfo.M1P6:ManualResult(true)
	ScenarioFramework.Dialogue(CityDio, nil, true)
	WaitSeconds(4)
	ForkThread(CityCamera)
	ScenarioFramework.SetPlayableArea('Area3', true)
	WaitSeconds(2)
	ForkThread(AttackSceneSpawn)
	ScenarioInfo.Area3City = ScenarioUtils.CreateArmyGroup('BotCity', 'CityArea3')
	ScenarioUtils.CreateArmyGroup('Player5', 'DefCityArea3')
	ScenarioUtils.CreateArmyGroup('Player5', 'Area3DopDefUnits')
	ScenarioUtils.CreateArmyGroup('Player6', 'DopArea2Build')
	ScenarioUtils.CreateArmyGroup('Player6', 'Base2')
	WaitSeconds(1)
	ForkThread(DespawnArea1Base)
	ForkThread(AntiNukeArea2)
	AttackNuke = false
	Area3 = true
	ScenarioInfo.NukeCity:Destroy()
	Event = false
	ForkThread(DefCity)
end

function DespawnArea1Base()
	local BaseBot = ScenarioFramework.GetCatUnitsInArea(categories.UEF - categories.uel0001, 'Area2', ArmyBrains[Bot])
	for k,v in BaseBot do
        v:Kill()
    end
	WaitSeconds(3)
	ScenarioFramework.FakeTeleportUnit(ScenarioInfo.CDRBot, true)
end

function AntiNukeArea2()
	local antinukes2 = ArmyBrains[Enemy]:GetListOfUnits(categories.uab4302, false)
	for k,v in antinukes2 do
        v:GiveTacticalSiloAmmo(10)
    end
end
function AttackSceneSpawn()
	local units1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'At1', 'AttackFormation')
	for k, v in units1:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area3Attack')))
	end
	local units2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player6', 'At2', 'AttackFormation')
	for k, v in units2:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area3Attack')))
	end
	local units3 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player5', 'DefUnits', 'AttackFormation')
	for k, v in units3:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area3Def')))
	end
	WaitSeconds(3)
	local units4 = ScenarioUtils.CreateArmyGroupAsPlatoon('Player5', 'DefUn2', 'AttackFormation')
	for k, v in units4:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area3Def')))
	end
	WaitSeconds(15)
	ForkThread(AutoSpawnDef)
	WaitSeconds(2)
	ForkThread(AttackOrderArea3_1)
	WaitSeconds(3)
	ForkThread(AttackOrderArea3_2)
	WaitSeconds(4)
	ForkThread(AttackOrderArea3_3)
	WaitSeconds(4)
	ForkThread(AttackOrderArea3_4)
	WaitSeconds(5)
	ForkThread(AttackOrderArea3_5)
	WaitSeconds(3)
	ForkThread(AttackOrderPlayers1)
	WaitSeconds(6)
	ForkThread(AttackOrderPlayers2)
	WaitSeconds(2)
	ForkThread(PatrolArea3AirOrder)
	WaitSeconds(5)
	ForkThread(AttackOrderNavalPlayers)
end

function AttackOrderArea3_1()
	ForkThread(AttackOrder1City1)
	WaitSeconds(11)
	ForkThread(AttackOrder1City2)
	WaitSeconds(23)
	ForkThread(AttackOrder1City3)
end

function AttackOrderArea3_2()
	ForkThread(AttackOrder1City4)
	WaitSeconds(14)
	ForkThread(AttackOrder1City5)
	WaitSeconds(15)
	ForkThread(AttackOrder1City6)
end

function AttackOrderArea3_3()
	ForkThread(AttackOrder1City7)
	WaitSeconds(12)
	ForkThread(AttackOrder1City8)
	WaitSeconds(15)
	ForkThread(AttackOrder1City9)
end

function AttackOrderArea3_4()
	ForkThread(AttackOrder1City10)
	WaitSeconds(12)
	ForkThread(AttackOrder1City11)
	WaitSeconds(22)
	ForkThread(AttackOrder1City12)
	WaitSeconds(37)
	ForkThread(AttackOrder1City13)
end

function AttackOrderArea3_5()
	ForkThread(AttackOrder1City14)
	WaitSeconds(14)
	ForkThread(AttackOrder1City15)
	WaitSeconds(34)
	ForkThread(AttackOrder1City16)
	WaitSeconds(360)
	ForkThread(AttackOrderExp)
end

function AutoSpawnDef()
	if Area3 == true then
		local DefAirBot = ArmyBrains[Bot]:MakePlatoon('', '')
		local DefAirBotDefFull = ArmyBrains[Bot]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 24')
		local SpawnPointLand1 = ScenarioUtils.MarkerToPosition('Blank Marker 13')
		local SpawnPointLand2 = ScenarioUtils.MarkerToPosition('Blank Marker 12')
		
		for i = 1, Random(5,12) do
			unit = CreateUnitHPR('uea0203', 'Player5', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBot, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(7,14) do
			unit = CreateUnitHPR('uea0203', 'Player5', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBotDefFull, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(5,8) do
			unit = CreateUnitHPR('uea0303', 'Player5', SpawnPointLand1[1], SpawnPointLand1[2], SpawnPointLand1[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBot, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(6,10) do
			unit = CreateUnitHPR('uea0103', 'Player5', SpawnPointLand2[1], SpawnPointLand2[2], SpawnPointLand2[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBot, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,3) do
			unit = CreateUnitHPR('uea0305', 'Player5', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBotDefFull, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(4,6) do
			unit = CreateUnitHPR('uel0303', 'Player5', SpawnPointLand1[1], SpawnPointLand1[2], SpawnPointLand1[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBot, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(6,12) do
			unit = CreateUnitHPR('uel0202', 'Player5', SpawnPointLand1[1], SpawnPointLand1[2], SpawnPointLand1[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBot, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(8,14) do
			unit = CreateUnitHPR('uel0201', 'Player5', SpawnPointLand2[1], SpawnPointLand2[2], SpawnPointLand2[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBot, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(4,8) do
			unit = CreateUnitHPR('uel0111', 'Player5', SpawnPointLand2[1], SpawnPointLand2[2], SpawnPointLand2[3], 0, 1.5, 0 )
			ArmyBrains[Bot]:AssignUnitsToPlatoon(DefAirBot, {unit}, 'attack', 'GrowthFormation')
		end
		
		for k, v in DefAirBot:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area3Def')))
		end
		for k, v in DefAirBotDefFull:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area3Attack')))
		end
		ScenarioFramework.CreatePlatoonDeathTrigger(AutoSpawnDef, DefAirBot)
	end
end

function PatrolArea3AirOrder()
	if Area3 == true then
		local DefAirOrder = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 78')
		
		for i = 1, Random(5,15) do
			unit = CreateUnitHPR('uaa0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirOrder, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(8,21) do
			unit = CreateUnitHPR('uaa0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirOrder, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(3,8) do
			unit = CreateUnitHPR('uaa0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirOrder, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(13,24) do
			unit = CreateUnitHPR('uaa0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirOrder, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(14,26) do
			unit = CreateUnitHPR('uaa0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirOrder, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(4,7) do
			unit = CreateUnitHPR('uaa0302', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirOrder, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(10,14) do
			unit = CreateUnitHPR('xaa0305', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirOrder, {unit}, 'attack', 'GrowthFormation')
		end
		
		for k, v in DefAirOrder:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('Area3PatrolAir')))
		end
		ScenarioFramework.CreatePlatoonDeathTrigger(PatrolArea3AirOrder, DefAirOrder)
	end
end

function AttackOrder1City1()
	if Area3 == true then
		local Attack1City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn1')
		
		for i = 1, 4 do
			unit = CreateUnitHPR('ual0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack1City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, 2 do
			unit = CreateUnitHPR('ual0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack1City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, 2 do
			unit = CreateUnitHPR('ual0307', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack1City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack1City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City1, Attack1City1Order)
	end
end

function AttackOrder1City2()
	if Area3 == true then
		local Attack2City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn1')
		
		for i = 1, 6 do
			unit = CreateUnitHPR('ual0205', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack2City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, 2 do
			unit = CreateUnitHPR('ual0307', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack2City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack2City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City2, Attack2City1Order)
	end
end

function AttackOrder1City3()
	if Area3 == true then
		local Attack3City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn1')
		
		for i = 1, Random(1,3) do
			unit = CreateUnitHPR('ual0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack3City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack3City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City3, Attack3City1Order)
	end
end

function AttackOrder1City4()
	if Area3 == true then
		local Attack4City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn2')
		
		for i = 1, Random(3,6) do
			unit = CreateUnitHPR('xaa0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack4City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack4City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City4, Attack4City1Order)
	end
end

function AttackOrder1City5()
	if Area3 == true then
		local Attack5City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn2')
		
		for i = 1, Random(3,10) do
			unit = CreateUnitHPR('uaa0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack5City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack5City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City5, Attack5City1Order)
	end
end

function AttackOrder1City6()
	if Area3 == true then
		local Attack6City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn2')
		
		for i = 1, Random(2,7) do
			unit = CreateUnitHPR('uaa0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack6City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack6City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City6, Attack6City1Order)
	end
end

function AttackOrder1City7()
	if Area3 == true then
		local Attack7City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn3')
		
		for i = 1, Random(2,5) do
			unit = CreateUnitHPR('ual0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack7City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack7City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City7, Attack7City1Order)
	end
end

function AttackOrder1City8()
	if Area3 == true then
		local Attack8City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn3')
		
		for i = 1, Random(6,8) do
			unit = CreateUnitHPR('ual0201', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack8City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack8City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City8, Attack8City1Order)
	end
end

function AttackOrder1City9()
	if Area3 == true then
		local Attack9City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn3')
		
		for i = 1, Random(3,5) do
			unit = CreateUnitHPR('ual0111', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack9City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack9City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City9, Attack9City1Order)
	end
end

function AttackOrder1City10()
	if Area3 == true then
		local Attack10City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn4')
		
		for i = 1, Random(2,8) do
			unit = CreateUnitHPR('uaa0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack10City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack10City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City10, Attack10City1Order)
	end
end

function AttackOrder1City11()
	if Area3 == true then
		local Attack11City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn4')
		
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR('uaa0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack11City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack11City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City11, Attack11City1Order)
	end
end

function AttackOrder1City12()
	if Area3 == true then
		local Attack12City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn4')
		
		for i = 1, Random(4,9) do
			unit = CreateUnitHPR('uaa0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack12City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack12City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City12, Attack12City1Order)
	end
end

function AttackOrder1City13()
	if Area3 == true then
		local Attack13City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn4')
		
		for i = 1, Random(1,2) do
			unit = CreateUnitHPR('uaa0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack13City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack13City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City13, Attack13City1Order)
	end
end

function AttackOrder1City14()
	if Area3 == true then
		local Attack14City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn5')
		
		for i = 1, Random(2,6) do
			unit = CreateUnitHPR('ual0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack14City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack14City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City14, Attack14City1Order)
	end
end

function AttackOrder1City15()
	if Area3 == true then
		local Attack15City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn5')
		
		for i = 1, Random(4,8) do
			unit = CreateUnitHPR('ual0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack15City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack15City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City15, Attack15City1Order)
	end
end

function AttackOrder1City16()
	if Area3 == true then
		local Attack16City1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn5')
		
		for i = 1, Random(1,3) do
			unit = CreateUnitHPR('ual0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(Attack16City1Order, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(Attack16City1Order, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrder1City16, Attack16City1Order)
	end
end

function AttackOrderPlayers1()
	if Area3 == true then
		local AttackPlayersOrder1 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn4')
		
		for i = 1, 5 do
			unit = CreateUnitHPR('xaa0305', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackPlayersOrder1, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, 10 do
			unit = CreateUnitHPR('uaa0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackPlayersOrder1, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, 20 do
			unit = CreateUnitHPR('uaa0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackPlayersOrder1, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackPlayersOrder1, 'AttackOrderArea3')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrderPlayers1, AttackPlayersOrder1)
	end
end

function AttackOrderPlayers2()
	if Area3 == true then
		local AttackPlayersOrder2 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Order2Spawn2')
		
		for i = 1, 10 do
			unit = CreateUnitHPR('xaa0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackPlayersOrder2, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, 5 do
			unit = CreateUnitHPR('uaa0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackPlayersOrder2, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, 10 do
			unit = CreateUnitHPR('uaa0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackPlayersOrder2, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackPlayersOrder2, 'AttackOrderArea3')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrderPlayers2, AttackPlayersOrder2)
	end
end

function AttackOrderExp()
	if Area3 == true then
		local AttackExpCity = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 71')
		
		for i = 1, Random(0,1) do
			unit = CreateUnitHPR('ual0401', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackExpCity, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(8,14) do
			unit = CreateUnitHPR('ual0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackExpCity, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackExpCity, 'City1OrderAttack')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrderExp, AttackExpCity)
	end
end

function AttackOrderNavalPlayers()
	if Area3 == true then
		local AttackNavalOrderArea3 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnNavalA1')
		
		for i = 1, Random(0,3) do
			unit = CreateUnitHPR('uas0302', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalOrderArea3, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR('uas0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalOrderArea3, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(3,4) do
			unit = CreateUnitHPR('uas0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalOrderArea3, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(4,6) do
			unit = CreateUnitHPR('uas0201', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalOrderArea3, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(2,8) do
			unit = CreateUnitHPR('uas0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalOrderArea3, {unit}, 'attack', 'GrowthFormation')
		end
		for i = 1, Random(8,12) do
			unit = CreateUnitHPR('uas0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalOrderArea3, {unit}, 'attack', 'GrowthFormation')
		end
		ScenarioFramework.PlatoonPatrolChain(AttackNavalOrderArea3, 'AttackArea3Naval')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(AttackOrderNavalPlayers, AttackNavalOrderArea3)
	end
end

function CityCamera()
	Cinematics.EnterNISMode()
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_1'), 0)
    WaitSeconds(1)
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_2'), 5)
    WaitSeconds(1)

    # Sweep over the action southwards
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_3'), 5)
    #WaitSeconds(2)

    # We might not need these cameras after all...
    #Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_4'), 9)
    #WaitSeconds(1)
    # Look to where the attacks are coming from
    # Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_5'), 3)
	Cinematics.ExitNISMode()
end
function DefCity()
	ScenarioInfo.M3C2 = Objectives.Protect(
        'primary',
        'incomplete',
        DefCityA1,
        DefCityA2,
        {
            Units = ScenarioInfo.Area3City,
            NumRequired = math.ceil(table.getn(ScenarioInfo.Area3City)/2),
            PercentProgress = true,
            ShowFaction = 'UEF',
        }
    )
    ScenarioInfo.M3C2:AddResultCallback(
        function(result)
            if(result == false) then
                ScenarioFramework.Dialogue(DeadCityArea2, PlayersDeathCity, true)
            end
        end
    )
	ScenarioInfo.M2P2 = Objectives.CategoriesInArea(
        'primary',                      # type
        'incomplete',                   # status
        BaseA2Order2_1,  # title
        BaseA2Order2_2,  # description
        'Kill',
        {                               # target
            MarkUnits = true,
            Requirements = {
				{
                    Area = 'BaseOrder2',
                    Category = (categories.FACTORY),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Enemy,
                }, 
            },
        }
    )
    ScenarioInfo.M2P2:AddResultCallback(
        function(result)
            if(result) then
                ScenarioInfo.M3C2:ManualResult(true)
				Area3 = false
				ScenarioFramework.Dialogue(SafeCity, PreFinalStart, true)
            end
        end
    )
end

function PreFinalStart()
	ScenarioFramework.SetPlayableArea('Area4', true)
	WaitSeconds(1)
	ForkThread(SpawnCityArea4)
end
function SpawnCityArea4()
	ScenarioUtils.CreateArmyGroup('BotCity', 'CityStartArea4')
	ScenarioUtils.CreateArmyGroup('Player5', 'DefCityArea4')
	ScenarioUtils.CreateArmyGroup('Player6', 'Base3')
	ScenarioUtils.CreateArmyGroup('Player6', 'Dop3Base')
	WaitSeconds(1)
	ForkThread(SpawnAmmoOrderAN)
	WaitSeconds(2)
	ScenarioUtils.CreateArmyGroup('Player6', 'NavalBase')
	ScenarioUtils.CreateArmyGroup('Player6', 'BaseDopArea4')
	WaitSeconds(1)
	ForkThread(SpawnGari)
	WaitSeconds(3)
	ForkThread(SpawnNavalOrder)
	WaitSeconds(3)
	ForkThread(SpawnAirOrderArea4)
	WaitSeconds(3)
	ForkThread(SpawnLandAttackGari)
end

function SpawnNavalOrder()
	WaitSeconds(2)
	ForkThread(SpawnNavalOrder1)
	WaitSeconds(3)
	ForkThread(SpawnNavalOrder2)
	WaitSeconds(1)
	ForkThread(SpawnNavalOrder3)
	WaitSeconds(3)
	ForkThread(SpawnNavalOrder4)
	WaitSeconds(12)
	ForkThread(SpawnEXPNavalOrder)
end

function SpawnNavalOrder1()
	if not ScenarioInfo.Gari:IsDead() then
		local DefNaval1Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('NavalSpawn')
		
		for i = 1, Random(2,3) do
			unit = CreateUnitHPR('uas0201', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval1Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(3,4) do
			unit = CreateUnitHPR('uas0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval1Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR('uas0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval1Order, {unit}, 'attack', 'AttackFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(DefNaval1Order, 'Area4PatrolNaval' .. Random(1,2))
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnNavalOrder1, DefNaval1Order)
	end
end

function SpawnNavalOrder2()
	if not ScenarioInfo.Gari:IsDead() then
		local DefNaval2Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('NavalSpawn')
		
		for i = 1, Random(2,4) do
			unit = CreateUnitHPR('uas0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval2Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(4,6) do
			unit = CreateUnitHPR('uas0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval2Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(3,4) do
			unit = CreateUnitHPR('uas0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval2Order, {unit}, 'attack', 'AttackFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(DefNaval2Order, 'Area4PatrolNaval' .. Random(1,2))
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnNavalOrder2, DefNaval2Order)
	end
end

function SpawnNavalOrder3()
	if not ScenarioInfo.Gari:IsDead() then
		local DefNaval3Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('NavalSpawn')
		
		for i = 1, Random(1,2) do
			unit = CreateUnitHPR('uas0302', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval3Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(4,5) do
			unit = CreateUnitHPR('uas0201', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval3Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(1,3) do
			unit = CreateUnitHPR('uas0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval3Order, {unit}, 'attack', 'AttackFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(DefNaval3Order, 'Area4PatrolNaval' .. Random(1,2))
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnNavalOrder3, DefNaval3Order)
	end
end

function SpawnEXPNavalOrder()
	if not ScenarioInfo.Gari:IsDead() then
		local DefNavalEXP = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('NavalSpawn')
		
		for i = 1, Random(2,3) do
			unit = CreateUnitHPR('uas0401', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNavalEXP, {unit}, 'attack', 'AttackFormation')
		end
		
		for k, v in DefNavalEXP:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('ExpNavalPatrol')))
		end
		
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnEXPNavalOrder, DefNavalEXP)
	end
end

function SpawnNavalOrder4()
	if not ScenarioInfo.Gari:IsDead() then
		local DefNaval4Order = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('NavalSpawn')
		
		for i = 1, Random(3,4) do
			unit = CreateUnitHPR('uas0201', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval4Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(2,3) do
			unit = CreateUnitHPR('uas0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval4Order, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(1,4) do
			unit = CreateUnitHPR('uas0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefNaval4Order, {unit}, 'attack', 'AttackFormation')
		end
		
		
		ScenarioFramework.PlatoonPatrolChain(DefNaval4Order, 'Area4PatrolNaval' .. Random(1,2))
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnNavalOrder4, DefNaval4Order)
	end
end

function SpawnLandAttackGari()
	if not ScenarioInfo.Gari:IsDead() then
		local AttackLand = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('AttackCity4Order')
		
		for i = 1, Random(4,36) do
			unit = CreateUnitHPR('ual0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackLand, {unit}, 'attack', 'AttackFormation')
		end
		
		for i = 1, Random(0,4) do
			unit = CreateUnitHPR('ual0401', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackLand, {unit}, 'attack', 'AttackFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackLand, 'Area4Attack')
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnLandAttackGari, AttackLand)
	end
end
function SpawnAirOrderArea4() 
	if not ScenarioInfo.Gari:IsDead() then
		local DefArea4OrderAir = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnAirPatrolOrderBase')
		
		for i = 1, Random(15,45) do
			unit = CreateUnitHPR('uaa0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefArea4OrderAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(10,30) do
			unit = CreateUnitHPR('xaa0305', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefArea4OrderAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(20,40) do
			unit = CreateUnitHPR('uaa0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefArea4OrderAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(25,50) do
			unit = CreateUnitHPR('xaa0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefArea4OrderAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(15,80) do
			unit = CreateUnitHPR('uaa0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefArea4OrderAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(15,25) do
			unit = CreateUnitHPR('uaa0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefArea4OrderAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(30,45) do
			unit = CreateUnitHPR('xaa0306', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefArea4OrderAir, {unit}, 'attack', 'GrowthFormation')
		end
		
		
		for k, v in DefArea4OrderAir:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('PatrolAir3Order')))
		end
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnAirOrderArea4, DefArea4OrderAir)
	end
end
function SpawnAmmoOrderAN()
	local antinukes3 = ArmyBrains[Enemy]:GetListOfUnits(categories.uab4302, false)
	local nukes = ArmyBrains[Enemy]:GetListOfUnits(categories.uab2305, false)
	for k,v in antinukes3 do
        v:GiveTacticalSiloAmmo(7)
    end
	ScenarioFramework.RemoveRestriction(Enemy, categories.uab2305)
	ScenarioFramework.RemoveRestriction(Enemy, categories.uab2302)
	WaitSeconds(2)
	for k,v in nukes do
        v:GiveNukeSiloAmmo(10)
    end
end

function SpawnGari()
	ScenarioInfo.Gari = ScenarioUtils.CreateArmyUnit('Player6', 'GariCom')
    ScenarioInfo.Gari:SetCustomName(LOC '{i Gari}')
	ScenarioFramework.Dialogue(OpenGari, DestroyCDRGari, true)
	WaitSeconds(2)
	ForkThread(TarSpawn)
	WaitSeconds(6)
	ScenarioFramework.Dialogue(OpStrings.X01_M01_060, nil, true)
end

function TarSpawn()
	ScenarioInfo.targetArea4_1 = CreateUnitHPR('uaa0310', 'Player6', 532, 35, 480, 0, 0, 0)
	ScenarioInfo.targetArea4_2 = CreateUnitHPR('uaa0310', 'Player6', 542, 35, 460, 0, 0, 0)
	WaitSeconds(2)
	ForkThread(DestroyEnemyTar)
end

function DestroyEnemyTar()
	ScenarioInfo.M3P2 = Objectives.KillOrCapture(
        'primary',                      # type
        'incomplete',                   # complete
		GariAttack1,  # title
        GariAttack2,  # description
        {                               # target
            Units = {ScenarioInfo.targetArea4_1, ScenarioInfo.targetArea4_2},
            MarkUnits = true,
        }
    )
    ScenarioInfo.M3P2:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(OpStrings.X01_M02_280, nil, true)
            end
        end
    )
end

function DestroyCDRGari()
	ScenarioInfo.M3P1 = Objectives.KillOrCapture(
        'primary',                      # type
        'incomplete',                   # complete
        Gari1,  # title
        Gari2,  # description
        {                               # target
            Units = {ScenarioInfo.Gari},
            MarkUnits = true,
        }
    )
    ScenarioInfo.M3P1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(Gari3, FinalBattle, true)
            end
        end
    )
end

function FinalBattle()
	WaitSeconds(3)
	ScenarioInfo.ZD1 = ScenarioUtils.CreateArmyUnit('Player5', 'ZD1')
	ScenarioInfo.ZD2 = ScenarioUtils.CreateArmyUnit('Player5', 'ZD2')
	ScenarioInfo.ZD2:SetCustomName(LOC '{i Coalition_HQ}')
	ScenarioFramework.PauseUnitDeath(ScenarioInfo.ZD2)
	WaitSeconds(1)
	ScenarioFramework.SetPlayableArea('Area5', true)
	WaitSeconds(1)
	ForkThread(Camera2)
end

function SpawnSeraphim()
	WaitSeconds(2)
	ForkThread(SpawnAirSeraphimDef)
	WaitSeconds(6)
	ForkThread(SpawnNavalSeraphim)
	WaitSeconds(2)
	ForkThread(AttackSeraphimL)
	WaitSeconds(4)
	ForkThread(AttackSeraphimA)
end

function SpawnNavalSeraphim()
	WaitSeconds(1)
	ForkThread(NavalSera1)
	WaitSeconds(4)
	ForkThread(NavalSera2)
	WaitSeconds(40)
	ForkThread(NavalSera3)
	WaitSeconds(30)
	ForkThread(Sera1E)
end

function NavalSera1()
	if not ScenarioInfo.SeraCom:IsDead() then
		local PatrolSeraNav1 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera5N')
		local NavalSera = {'xss0103','xss0201','xss0202', 'xss0203', 'xss0302', 'xss0303', 'xss0304'}
		for i = 1, Random(12,24) do
			unit = CreateUnitHPR(NavalSera[Random(1,7)], 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(PatrolSeraNav1, {unit}, 'attack', 'GrowthFormation')
		end
		
		for k, v in PatrolSeraNav1:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('PatrolSera1')))
		end
		
		ScenarioFramework.CreatePlatoonDeathTrigger(NavalSera1, PatrolSeraNav1)
	end
	
end

function NavalSera2()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackNavalSera1 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera5N')
		local NavalSera = {'xss0103', 'xss0201', 'xss0202', 'xss0203', 'xss0304'}
		for i = 1, Random(5,13) do
			unit = CreateUnitHPR(NavalSera[Random(1,5)], 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalSera1, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackNavalSera1, 'AttackNavalA1')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(NavalSera2, AttackNavalSera1)
	end
end

function NavalSera3()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackNavalSera2 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera5N')
		local NavalSera = {'xss0201', 'xss0202', 'xss0203', 'xss0302'}
		
		for i = 1, Random(6,9) do
			unit = CreateUnitHPR(NavalSera[Random(1,4)], 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackNavalSera2, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackNavalSera2, 'AttackNavalA1')
		
		ScenarioFramework.CreatePlatoonDeathTrigger(NavalSera3, AttackNavalSera2)
	end
end

function AttackSeraphimL()
	WaitSeconds(1)
	ForkThread(Sera1L)
	WaitSeconds(1)
	ForkThread(Sera2L)
	WaitSeconds(1)
	ForkThread(Sera3L)
	WaitSeconds(1)
	ForkThread(Sera4L)
	WaitSeconds(1)
	ForkThread(Sera5L)
	WaitSeconds(1)
	ForkThread(Sera6L)
end

function AttackSeraphimA()
	WaitSeconds(3)
	ForkThread(Sera1A)
	WaitSeconds(3)
	ForkThread(Sera2A)
	WaitSeconds(3)
	ForkThread(Sera3A)
	WaitSeconds(3)
	ForkThread(Sera4A)
	WaitSeconds(3)
	ForkThread(Sera5A)
	WaitSeconds(3)
	ForkThread(Sera6A)
end

function Sera1L()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraL1 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera2L')
		
		for i = 1, Random(8,24) do
			unit = CreateUnitHPR('xsl0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraL1, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraL1, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera1L, Random(40, 62))
end

function Sera2L()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraL2 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera1L')
		
		for i = 1, Random(12,28) do
			unit = CreateUnitHPR('xsl0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraL2, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraL2, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera2L, Random(36, 48))
end

function Sera3L()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraL3 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera4L')
		
		for i = 1, Random(8,32) do
			unit = CreateUnitHPR('xsl0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraL3, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraL3, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera3L, Random(47, 56))
end

function Sera4L()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraL4 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera6L')
		
		for i = 1, Random(8,32) do
			unit = CreateUnitHPR('xsl0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraL4, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraL4, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera4L, Random(31, 51))
end

function Sera5L()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraL5 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera7L')
		
		for i = 1, Random(8,32) do
			unit = CreateUnitHPR('xsl0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraL5, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraL5, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera5L, Random(34, 48))
end

function Sera6L()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraL6 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera8L')
		
		for i = 1, Random(8,32) do
			unit = CreateUnitHPR('xsl0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraL6, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraL6, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera6L, Random(32, 61))
end

function Sera1A()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraA1 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera3A')
		
		for i = 1, Random(5,30) do
			unit = CreateUnitHPR('xsa0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA1, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(10,46) do
			unit = CreateUnitHPR('xsa0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA1, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraA1, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera1A, Random(46, 58))
end

function Sera2A()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraA2 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera3A')
		
		for i = 1, Random(10,46) do
			unit = CreateUnitHPR('xsa0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA2, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraA2, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera2A, Random(45, 58))
end

function Sera3A()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraA3 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('SpawnSera3A')
		
		for i = 1, Random(5,15) do
			unit = CreateUnitHPR('xsa0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA3, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraA3, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera3A, Random(38, 36))
end

function Sera4A()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraA4 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 182')
		
		for i = 1, Random(15,35) do
			unit = CreateUnitHPR('xsa0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA4, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraA4, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera4A, Random(42, 52))
end

function Sera5A()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraA5 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 182')
		
		for i = 1, Random(20,46) do
			unit = CreateUnitHPR('xsa0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA5, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraA5, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera5A, Random(32, 52))
end

function Sera6A()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraA6 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 182')
		
		for i = 1, Random(30,52) do
			unit = CreateUnitHPR('xsa0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA6, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(22,42) do
			unit = CreateUnitHPR('xsa0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraA6, {unit}, 'attack', 'GrowthFormation')
		end
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraA6, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera6A, Random(42, 54))
end

function Sera1E()
	if not ScenarioInfo.SeraCom:IsDead() then
		local AttackSeraE1 = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 182')
		local UnitE = {'xsl0401', 'xsa0402'}
		for i = 1, Random(1,4) do
			unit = CreateUnitHPR(UnitE[Random(1,2)], 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(AttackSeraE1, {unit}, 'attack', 'GrowthFormation')
		end
		
		
		ScenarioFramework.PlatoonPatrolChain(AttackSeraE1, 'AttackSeraphim' .. Random(1,4))
	end
	
	ScenarioFramework.CreateTimerTrigger(Sera1E, Random(62, 100))
end

function SpawnAirSeraphimDef()
	if not ScenarioInfo.SeraCom:IsDead() then
		local DefAirSeraphim = ArmyBrains[Enemy]:MakePlatoon('', '')
		local unit = false
		local SpawnPoint = ScenarioUtils.MarkerToPosition('Blank Marker 183')
		
		for i = 1, Random(50,75) do
			unit = CreateUnitHPR('xsa0303', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirSeraphim, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(25,50) do
			unit = CreateUnitHPR('xsa0304', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirSeraphim, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(15,30) do
			unit = CreateUnitHPR('xsa0203', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirSeraphim, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(20,40) do
			unit = CreateUnitHPR('xsa0202', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirSeraphim, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(5,12) do
			unit = CreateUnitHPR('xsa0402', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirSeraphim, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(30,45) do
			unit = CreateUnitHPR('xsa0103', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirSeraphim, {unit}, 'attack', 'GrowthFormation')
		end
		
		for i = 1, Random(50,60) do
			unit = CreateUnitHPR('xsa0102', 'Player6', SpawnPoint[1], SpawnPoint[2], SpawnPoint[3], 0, 1.5, 0 )
			ArmyBrains[Enemy]:AssignUnitsToPlatoon(DefAirSeraphim, {unit}, 'attack', 'GrowthFormation')
		end
		
		for k, v in DefAirSeraphim:GetPlatoonUnits() do
			ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('AirSeraPatrol')))
		end
		ScenarioFramework.CreatePlatoonDeathTrigger(SpawnAirSeraphimDef, DefAirSeraphim)
	end
end

function Camera2()
	ScenarioFramework.SetSeraphimColor(Enemy)
	ScenarioUtils.CreateArmyGroup('Player5', 'BaseFinalArea')
	ScenarioUtils.CreateArmyGroup('BotCity', 'CityAreaFinal')
	ScenarioUtils.CreateArmyGroup('Player6', 'SeraphimArea3')
	ScenarioInfo.AeonBMK1 = ScenarioUtils.CreateArmyUnit('Player5', 'AeonBMK1')
	ScenarioInfo.AeonBMK2 = ScenarioUtils.CreateArmyUnit('Player5', 'AeonBMK2')
	ScenarioInfo.AeonBMK3 = ScenarioUtils.CreateArmyUnit('Player5', 'AeonBMK3')
	ScenarioInfo.AeonRhiza = ScenarioUtils.CreateArmyUnit('Player5', 'Rhiza')
	ScenarioInfo.AeonRhiza:SetCustomName(LOC '{i Rhiza}')
	ScenarioInfo.AeonCollos = ScenarioUtils.CreateArmyUnit('Player5', 'ColossAeon')
	ScenarioInfo.AeonUnit = { ScenarioInfo.AeonRhiza, ScenarioInfo.AeonBMK1, ScenarioInfo.AeonBMK2, ScenarioInfo.AeonBMK3, ScenarioInfo.AeonCollos }
	ScenarioInfo.Itoto = ScenarioUtils.CreateArmyGroup('Player6', 'Itito')
	ScenarioInfo.Def = ScenarioUtils.CreateArmyGroupAsPlatoon('Player5', 'DefGroup', 'AttackFormation')
	for k, v in ScenarioInfo.Def:GetPlatoonUnits() do
		ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('DefArea5')))
	end
	for k, target in ScenarioInfo.Itoto do
        IssueAttack( ScenarioInfo.AeonUnit, target )
    end
	IssueAggressiveMove(ScenarioInfo.Itoto, ScenarioUtils.MarkerToPosition( 'Blank Marker 141' ))
	Cinematics.EnterNISMode()
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_3'), 0)
	WaitSeconds(1)
	ScenarioFramework.Dialogue(RhizaFletcher, nil, true)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_4'), 5)
	WaitSeconds(3)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_5'), 8)
	WaitSeconds(3)
	Cinematics.ExitNISMode()
	WaitSeconds(15)
	ScenarioInfo.AeonBMK3:Kill()
	WaitSeconds(1)
	ScenarioInfo.AeonBMK1:SetDoNotTarget(true)
    ScenarioInfo.AeonBMK1:SetCanTakeDamage(false)
    ScenarioInfo.AeonBMK1:SetCanBeKilled(false)
	WaitSeconds(1)
	ScenarioInfo.AeonBMK2:SetDoNotTarget(true)
    ScenarioInfo.AeonBMK2:SetCanTakeDamage(false)
    ScenarioInfo.AeonBMK2:SetCanBeKilled(false)
	WaitSeconds(1)
	ScenarioInfo.AeonRhiza:SetDoNotTarget(true)
    ScenarioInfo.AeonRhiza:SetCanTakeDamage(false)
    ScenarioInfo.AeonRhiza:SetCanBeKilled(false)
	WaitSeconds(2)
	ScenarioFramework.Dialogue(DeadBMKAeon, nil, true)
	WaitSeconds(4)
	ForkThread(Fake1)
	WaitSeconds(2)
	ForkThread(Fake2)
	WaitSeconds(3)
	ForkThread(Fake3)
	WaitSeconds(2)
	SetArmyUnitCap(Player1, 900)
	SetArmyUnitCap(Player2, 900)
	SetArmyUnitCap(Player3, 900)
	SetArmyUnitCap(Player4, 900)
	SetArmyUnitCap(Bot, 1000)
	SetArmyUnitCap(City, 600)
	SetArmyUnitCap(Enemy, 3000)
	ForkThread(DefZD)
	ForkThread(SpawnSeraphimCom)
	ScenarioFramework.CreateTimerTrigger(KillUnitsSeraAt, 1*60)
end
function KillUnitsSeraAt()
	for k, unit in ScenarioInfo.Itoto do
        if ( unit and not unit:IsDead()) then
            unit:Kill()
        end
    end
end

function Fake1()
	WaitSeconds(5)
	ScenarioFramework.FakeTeleportUnit(ScenarioInfo.AeonBMK1, true)
end

function Fake2()
	WaitSeconds(7)
	ScenarioFramework.FakeTeleportUnit(ScenarioInfo.AeonBMK2, true)
end

function Fake3()
	WaitSeconds(13)
	ScenarioFramework.FakeTeleportUnit(ScenarioInfo.AeonRhiza, true)
end

function SpawnSeraphimCom()
	ScenarioInfo.SeraCom = ScenarioUtils.CreateArmyUnit('Player6', 'Sera2')
	ScenarioInfo.SeraCom:SetCustomName(LOC '{i ShunUllevash}')
	WaitSeconds(3)
	for i = 1,3 do
		ScenarioUtils.CreateArmyGroup('Player6', 'BaseDopSeraphim' .. i)
		WaitSeconds(1)
	end
	WaitSeconds(1)
	local antinukes4 = ArmyBrains[Enemy]:GetListOfUnits(categories.xsb4302, false)
	local nukes2 = ArmyBrains[Enemy]:GetListOfUnits(categories.xsb2305, false)
	for k,v in antinukes4 do
        v:GiveTacticalSiloAmmo(7)
    end
	for k,v in nukes2 do
        v:GiveNukeSiloAmmo(5)
    end
	WaitSeconds(2)
	ForkThread(DestroySeraphim)
	WaitSeconds(1)
	ForkThread(SpawnSeraphim)
end

function DestroySeraphim()
	ScenarioInfo.M4P2 = Objectives.KillOrCapture(
        'primary',                              # type
        'incomplete',                           # complete
        Sera4_1,          # title
        Sera4_2,          # description
        {                                       # target
            Units = {ScenarioInfo.SeraCom},
            MarkUnits = true,
        }
    )
    ScenarioInfo.M4P2:AddResultCallback(
        function(result)
            if(result) then
				ScenarioFramework.Dialogue(SeraDead, nil, true)
				ForkThread(WinGame)
				ScenarioInfo.M4P1:ManualResult(true)
            end
        end
    )
end

function DefZD()
	ScenarioInfo.M4P1 = Objectives.Protect(
        'primary',                              # type
        'incomplete',                           # complete
        X01_M03_OBJ_010_010,          # title
        X01_M03_OBJ_010_020,          # description
        {                                       # target
            Units = {ScenarioInfo.ZD2},
            PercentProgress = true,
            ShowFaction = 'UEF',
        }
    )
    ScenarioInfo.M4P1:AddResultCallback(
        function(result)
            if(result == false) then
				ForkThread(PlayersDeathCity)
				ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.ZD2)
				ScenarioFramework.Dialogue(SeraWin, nil, true)
            end
        end
    )
end

function SpawnEco()
	ArmyBrains[Enemy]:GiveStorage('ENERGY', 5000000)
	ArmyBrains[City]:GiveStorage('ENERGY', 5000)
	ArmyBrains[Player1]:GiveStorage('ENERGY', 4000)
	ArmyBrains[Player2]:GiveStorage('ENERGY', 4000)
	ArmyBrains[Player3]:GiveStorage('ENERGY', 4000)
	ArmyBrains[Player4]:GiveStorage('ENERGY', 4000)
	ArmyBrains[Bot]:GiveStorage('ENERGY', 6000)
    while(ECO == true) do
        ArmyBrains[Enemy]:GiveResource('MASS', 20000)
        ArmyBrains[Enemy]:GiveResource('ENERGY', 100000)
        WaitSeconds(1.5)
    end
end

function PlayersDeathCity()
	ScenarioFramework.PlayerLose()
end

function WinGame()
	ScenarioFramework.EndOperationSafety()
    ScenarioInfo.OpComplete = true
	ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, nil)
end