local AiBotOverseer = import('/lua/AiBot/AI/AiBotOverseer.lua')
local AiBotUtilities = import('/lua/AiBot/AI/AiBotUtilities.lua')
local AiBotMap = import('/lua/AiBot/AI/AiBotMap.lua')
local AiBotProfiler = import('/lua/AiBot/AI/AiBotProfiler.lua')
local AiBotConfig = import('/lua/AiBot/AiBotConfig.lua')
local AiBotEvents = import('/lua/AiBot/AI/AiBotEvents.lua')

--Note - looks like this logic may be moved to lua\aibrains\base-ai.lua at some point based on FAF develop (as at May 2023)
--In theory the below shouldt be needed once the FAF-Develop changes are integrated into FAF (expected June 2023), although probably no harm leaving for backwards compatibility
--Superceded from the June 2023 changes by AiBotBrain.lua and index.lua
    --V24 - removed the below as couldn't get the new appraoch (which requires map to be generated later than OnCreateAI triggers) to work with this code still here

AiBotAIBrainClass = AIBrain
AIBrain = Class(AiBotAIBrainClass) {

    OnDefeat = function(self)
        AiBotAIBrainClass.OnDefeat(self)
        if AiBotUtilities.bSteamActive then
            ForkThread(AiBotEvents.OnPlayerDefeated, self)
        end
    end,

    OnCreateAI = function(self, planName)
        if AiBotUtilities.bSteamActive then
            local AiBotConditions = import('/lua/AiBot/AI/AiBotConditions.lua')
            --Only apply AiBot to easy and normal
            LOG('Brain OnCreateAI for brain'..self.Nickname..' with personality '..(self.Personality or ScenarioInfo.ArmySetup[self.Name].AIPersonality or 'nil'))
            local sPersonality = self.Personality or ScenarioInfo.ArmySetup[self.Name].AIPersonality
            if not(AiBotConditions.IsCivilianBrain(self)) and (sPersonality == 'easy' or sPersonality == 'medium') then
                self.AiBotAI = true
                if sPersonality == 'easy' then self.AiBotEasy = true end
                AiBotUtilities.bAiBotAIInGame = true
                ForkThread(AiBotEvents.OnCreateBrain, self, planName, false)--]]
            else
                AiBotAIBrainClass.OnCreateAI(self, planName)
                ForkThread(AiBotOverseer.ConsiderSteamMessageIfNoAiBot)
            end
        else
            AiBotAIBrainClass.OnCreateAI(self, planName)
        end
        --[[if (ScenarioInfo.ArmySetup[self.Name].AIPersonality == 'aibotai' or ScenarioInfo.ArmySetup[self.Name].AIPersonality == 'aibotaicheat') then
            self.AiBotAI = true
            AiBotUtilities.bAiBotAIInGame = true
        end
        if not(self.AiBotAI) then
            LOG('Running normal aiBrain creation code for brain '..(self.Nickname or 'nil'))
            AiBotAIBrainClass.OnCreateAI(self, planName)
        end
        ForkThread(AiBotEvents.OnCreateBrain, self, planName, false)--]]
    end,

    --[[OnBeginSession = function(self)
        AiBotAIBrainClass.OnBeginSession(self)
        AiBotOverseer.bBeginSessionTriggered = true
        import("/lua/sim/NavUtils.lua").Generate()
    end,--]]

    OnCreateHuman = function(self, planName)
        AiBotAIBrainClass.OnCreateHuman(self, planName)
        ForkThread(AiBotEvents.OnCreateBrain, self, planName, true)
    end,

    --Redundancy - make sure base AI doesnt run for AiBotAI
    InitializeSkirmishSystems = function(self)
        if self.AiBotAI then
            --Do nothing
            LOG('BaseAIHook - AiBotAI InitializeSkirmishSystems disabled')
        else
            --LOG('BaseAIHook - InitializeSkirmishSystems, self='..(self.Nickname or 'nil'))
            AiBotAIBrainClass.InitializeSkirmishSystems(self)
        end
    end,
    InitializeAttackManager = function(self, attackDataTable)
        if self.AiBotAI then
            --Do nothing
            LOG('BaseAIHook - AiBotAI InitializeAttackManager disabled')
        else
            --LOG('BaseAIHook - InitializeAttackManager, ai='..(self.Nickname or 'nil'))
            AiBotAIBrainClass.InitializeAttackManager(self, attackDataTable)
        end
    end,
    InitializePlatoonBuildManager = function(self)
        if self.AiBotAI then
            --Do nothing
            LOG('BaseAIHook - AiBotAI InitializePlatoonBuildManager disabled')
        else
            --LOG('BaseAIHook - InitializePlatoonBuildManager, ai='..(self.Nickname or 'nil'))
            AiBotAIBrainClass.InitializePlatoonBuildManager(self)
        end
    end,
    BaseMonitorInitialization = function(self, spec)
        if self.AiBotAI then
            --Do nothing
            LOG('BaseAIHook - AiBotAI BaseMonitorInitialization disabled')
        else
            --LOG('BaseAIHook - BaseMonitorInitialization, ai='..(self.Nickname or 'nil'))
            AiBotAIBrainClass.BaseMonitorInitialization(self, spec)
        end
    end,
    BaseMonitorInitializationSorian = function(self, spec)
        if self.AiBotAI then
            --Do nothing
            LOG('BaseAIHook - AiBotAI BaseMonitorInitializationSorian disabled')
        else
            --LOG('BaseAIHook - BaseMonitorInitializationSorian, ai='..(self.Nickname or 'nil'))
            AiBotAIBrainClass.BaseMonitorInitializationSorian(self, spec)
        end
    end,
}