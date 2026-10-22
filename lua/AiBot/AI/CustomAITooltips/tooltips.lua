Tooltips = {
    pref_AiBotAIxOverwhelmR = {
        title = "AIx Overwhelm Rate",
        description = "Adjusts AiBot AIx build and cheat modifiers by this amount periodically (0.0 to disable)",
    },
    pref_AiBotAIxOverwhelmT = {
        title = "AIx Overwhelm Interval",
        description = "Time in minutes between each AIx overwhelm adjustment",
    },
    pref_AiBotAIxOverwhelmL = {
        title = "AIx Overwhelm Limit",
        description = "Stops changing the AIx overwhelm modifier once this AIx modifier is reached",
    },
    pref_AiBotTimeBetweenOrders = {
        title = "Time between AiBot orders",
        description = "Minimum number of seconds between orders for most units (e.g. makes AiBot kiting significantly weaker).  Doesnt affect certain microing",
    },
    pref_AiBotAggression = {
        title = "Enemy threat factor",
        description = "Adjusts certain enemy threat calculations by the value specified (a value below 1 means AiBot will treat enemy units as being worth less, and so will be more likely to engage with land units (but also less likely to consider nuke targets as worth nuking)",
    },
    pref_AiBotCPUPerformance = {
        title = 'AiBot: Enable performance mode?',
        description = 'If enabled, AiBot will use simpler functionality for parts of its logic, making it less challenging but also faster to run',
    },
    pref_AiBotPrioritiseBPs = {
        title = 'AiBot: Prioritise stronger units?',
        description = 'By default AiBot will always build certain T1-T3 land units over others (e.g. bricks instead of loyalists after a few have been built); disabling this should increase variety of units built',
    },
    pref_AiBotDodgeMicro = {
        title = 'AiBot: Limit use of dodge micro?',
        description = 'By default AiBot will try and dodge slow moving shots and bombs with units (except for AiBotEasy); you can limit the number of units it can dodge at once',
    },
    pref_AiBotHoverMicro = {
        title = 'AiBot: Limit use of hover micro?',
        description = 'By default AiBot will try and slow down his air units in certain scenarios (except for AiBotEasy), you can limit the number of units it can apply such hover micro to at once',
    },
    pref_AiBotCombinedArmy = {
        title = 'AiBot: AI assistant?',
        description = 'If enabled, human players can toggle AiBot logic on individual units',
    },
    pref_AiBotCAInherit = {
        title = 'AiBot: CA Inherit status?',
        description = 'AiBot will by default control units built by AiBot-controlled shared-army units',
    },
    pref_AiBotCAEngi = {
        title = 'AiBot: CA Disable Engis?',
        description = 'If combined armies are enabled, then this prevents factories controlled by the AI from building engineers',
    },
    pref_AiBotTeammate = {
        title = 'AiBot: Helpful teammates?',
        description = 'Should AiBot help by assisting player experimentals; gifting asfs to the air player; and gifting mexes it builds in a teammate\'s base',
    },
}
