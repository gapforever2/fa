version = 3 -- Lua Version. Dont touch this
ScenarioInfo = {
    name = "Custom Mission: QAI (6 players vs QAI) V2",
    description = "Custom mission created by armagedon",
    preview = '',
    map_version = 6,
    type = 'campaign_coop',
    starts = true,
    size = {1024, 1024},
    reclaim = {4131044, 108235},
    map = '/maps/mission_war_of_minds.v0006/mission_war_of_minds.scmap',
    save = '/maps/mission_war_of_minds.v0006/mission_war_of_minds_save.lua',
    script = '/maps/mission_war_of_minds.v0006/mission_war_of_minds_script.lua',
    norushradius = 0,
    Configurations = {
        ['standard'] = {
            teams = {
                {
                    name = 'FFA',
                    armies = {'Player1', 'Player2', 'Player3', 'Player4', 'Player5', 'Player6', 'Player7'}
                },
            },
            customprops = {
            },
			factions = { {'cybran'}, {'uef', 'aeon','cybran', 'seraphim'}, {'uef', 'aeon','cybran', 'seraphim'}, {'uef', 'aeon','cybran', 'seraphim'}, {'uef', 'aeon','cybran', 'seraphim'}, {'uef', 'aeon','cybran', 'seraphim'}, {'uef', 'aeon','cybran', 'seraphim'} },
        },
    },
}
