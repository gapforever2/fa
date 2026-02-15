version = 3 -- Lua Version. Dont touch this
ScenarioInfo = {
    name = "Operation Rescue",
    description = "A group of UEF scientists are trapped on a planet and a Cybran Commander gated near them quite a while back. They managed to send a distress signal before the Cybran built a long-range Jammer. We've managed to locate the scientists. Commander, you will gate in and help those scientists.",
    preview = '',
    map_version = 6,
    type = 'campaign_coop',
    starts = true,
    size = {1024, 1024},
    reclaim = {469790.4, 13800},
    map = '/maps/faf_coop_operation_rescue.v0007/FAF_Coop_Operation_Rescue.scmap',
    save = '/maps/faf_coop_operation_rescue.v0007/FAF_Coop_Operation_Rescue_save.lua',
    script = '/maps/faf_coop_operation_rescue.v0007/FAF_Coop_Operation_Rescue_script.lua',
    norushradius = 0,
    Configurations = {
        ['standard'] = {
            teams = {
                {
                    name = 'FFA',
                    armies = {'Player1', 'Cybran', 'UEF', 'Player2', 'Player3', 'Player4'}
                },
            },
            customprops = {
            },
            factions = {
                {'uef'},
                {'uef'},
                {'uef'},
                {'uef'}
            },
        },
    },
}
