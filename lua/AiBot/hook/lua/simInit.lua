
local AiBotMap = import('/lua/AiBot/AI/AiBotMap.lua')

--Approach of hooking to get around adaptive map issues is based on Softels DilliDalli AI - alternative is using CanBuildStructureAt to check, but that runs into issues if the resource point has reclaim on it
local AiBotOldCreateResourceDeposit = CreateResourceDeposit
local AiBotEvents = import('/lua/AiBot/AI/AiBotEvents.lua')

CreateResourceDeposit = function(t,x,y,z,size)
    AiBotOldCreateResourceDeposit(t,x,y,z,size)
    ForkThread(AiBotMap.RecordResourcePoint,t,x,y,z,size)
end

--Put anything we want to only run once (not once per aiBrain) below
local AiBotBeginSession = BeginSession
function BeginSession()
    AiBotBeginSession()
    AiBotEvents.OnGameStart()
end

