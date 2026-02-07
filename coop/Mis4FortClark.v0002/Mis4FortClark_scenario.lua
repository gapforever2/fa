version = 3 -- Lua Version. Dont touch this
ScenarioInfo = {
    name = "Custom mission: Fort Clark",
    description = "",
    preview = '',
    map_version = 2,
    type = 'campaign_coop',
    starts = true,
    size = {1024, 1024},
    reclaim = {3119211, 0},
    map = '/maps/Mis4FortClark.v0002/Mis4FortClark.scmap',
    save = '/maps/Mis4FortClark.v0002/Mis4FortClark_save.lua',
    script = '/maps/Mis4FortClark.v0002/Mis4FortClark_script.lua',
    norushradius = 0,
    Configurations = {
        ['standard'] = {
            teams = {
                {
                    name = 'FFA',
                    armies = {'Player1', 'Player2', 'BotCity', 'Player3', 'Player4', 'Player5', 'Player6'}
                },
            },
            customprops = {
            },
			factions = {
                {'uef', 'aeon', 'cybran'},
                {'uef', 'aeon', 'cybran'},
                {'uef', 'aeon', 'cybran'},
                {'uef', 'aeon', 'cybran'},
                {'uef'},
                {'aeon'}
            },
        },
    },
}
