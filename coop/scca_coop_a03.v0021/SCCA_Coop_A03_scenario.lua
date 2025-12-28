version = 3 -- Lua Version. Dont touch this
ScenarioInfo = {
    name = "Aeon Mission 3 - High Tide",
    description = "Ten days ago we launched an offensive against UEF forces positioned on Matar.\nDespite my planning, seizing the planet has proven much more difficult than expected. This is unacceptable.\nYou will go to Matar and relieve Crusader Eris. She has been in constant battle and is in need of rest.",
    preview = '',
    map_version = 21,
    type = 'campaign_coop',
    starts = true,
    size = {512, 512},
    reclaim = {270408.1, 35280},
    map = '/maps/scca_coop_a03.v0021/SCCA_Coop_A03.scmap',
    save = '/maps/scca_coop_a03.v0021/SCCA_Coop_A03_save.lua',
    script = '/maps/scca_coop_a03.v0021/SCCA_Coop_A03_script.lua',
    norushradius = 0,
    Configurations = {
        ['standard'] = {
            teams = {
                {
                    name = 'FFA',
                    armies = {'Player1', 'UEF', 'Eris', 'Player2', 'Player3', 'Player4'}
                },
            },
            customprops = {
            },
            factions = {
                {'aeon'},
                {'aeon'},
                {'aeon'},
                {'aeon'}
            },
        },
    },
}
