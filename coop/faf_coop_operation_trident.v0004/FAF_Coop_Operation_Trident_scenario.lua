version = 3
ScenarioInfo = {
    name = "Operation Trident",
    description = "Operation Trident",
    preview = '',
    map_version = 1,
    type = 'campaign_coop',
    starts = true,
    size = {1024, 1024},
    map = '/maps/faf_coop_operation_trident.v0004/FAF_Coop_Operation_Trident.scmap',
    save = '/maps/faf_coop_operation_trident.v0004/FAF_Coop_Operation_Trident_save.lua',
    script = '/maps/faf_coop_operation_trident.v0004/FAF_Coop_Operation_Trident_script.lua',
    norushradius = 0,
    Configurations = {
        ['standard'] = {
            teams = {
                {
                    name = 'FFA',
                    armies = {'Player1', 'Aeon', 'UEF', 'Cybran', 'Civilians', 'Player2'}
                },
            },
            customprops = {
            },
            factions = {
                {'cybran'},
                {'cybran'}
            },
        },
    },
}
