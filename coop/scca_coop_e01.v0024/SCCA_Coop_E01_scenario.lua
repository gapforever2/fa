version = 3
ScenarioInfo = {
    name = 'UEF Mission 1 - Black Earth v24',
    description = 'Intel reports that two Cybran Commanders gated to Capella over an hour ago.\nWe presume they\'re attempting to inflame the Symbiont population.',
	preview = '',
	map_version = 23,
    type = 'campaign_coop',
    starts = true,
	size = {512, 512},
	reclaim = {292401.4, 101325},
    map = '/maps/scca_coop_e01.v0024/SCCA_Coop_E01.scmap',
    save = '/maps/scca_coop_e01.v0024/SCCA_Coop_E01_save.lua',
    script = '/maps/scca_coop_e01.v0024/SCCA_Coop_E01_script.lua',
	norushradius = 0,
    Configurations = {
        ['standard'] = {
            teams = {
                { 
					name = 'FFA', 
					armies = {'Player1', 'Arnold', 'Cybran', 'EastResearch', 'NeutralStructures', 'Player2', 'Player3', 'Player4', 'Player5', 'Player6'} 
				},
            },
            customprops = {
            },
            factions = { 
				{'uef'}, 
				{'uef'}, 
				{'uef'}, 
				{'uef'},
				{'uef'},
				{'uef'}
			},
        },
    },
}
