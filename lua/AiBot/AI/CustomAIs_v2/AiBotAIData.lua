AI = {
    Name = 'AI: AiBot',
    Version = '1',
    AIList = {
        {
            key = 'aibotai', --need to update index.lua in aibrains folder hook with the keys of all ais being added
            name = 'AI: AiBot Adaptive',
            rating = 1100,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotaie',
            name = 'AI: AiBot Easy',
            rating = 850,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotaiair',
            name = 'AI: AiBot Air',
            rating = 1000,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotailand',
            name = 'AI: AiBot Land',
            rating = 1000,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotairush',
            name = 'AI: AiBot Rush',
            rating = 1000,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.8,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.8, -- 40x40
                [4096] = 0.7,  -- 80x80
            }
        },
        {
            key = 'aibotaitech',
            name = 'AI: AiBot Tech',
            rating = 900,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotaiturtle',
            name = 'AI: AiBot Turtle',
            rating = 800,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotainavy',
            name = 'AI: AiBot Navy',
            rating = 800,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotairandom',
            name = 'AI: AiBot Random',
            rating = 800,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniBonus = 0,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
    },
    CheatAIList = {
        {
            key = 'aibotaicheat', --need to update index.lua in aibrains folder hook with the keys of all ais being added
            name = 'AIx: AiBot Adaptive',
            rating = 1100,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotaiecheat',
            name = 'AIx: AiBot Easy',
            rating = 850,
            ratingCheatMultiplier = 1100.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 800.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotaiaircheat',
            name = 'AIx: AiBot Air',
            rating = 1000,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotailandcheat',
            name = 'AIx: AiBot Land',
            rating = 1000,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotairushcheat',
            name = 'AIx: AiBot Rush',
            rating = 1000,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.8,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.8, -- 40x40
                [4096] = 0.7,  -- 80x80
            }
        },
        {
            key = 'aibotaitechcheat',
            name = 'AIx: AiBot Tech',
            rating = 900,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },

        {
            key = 'aibotaiturtlecheat', --need to update index.lua in aibrains folder hook with the keys of all ais being added
            name = 'AIx: AiBot Turtle',
            rating = 800,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotainavycheat', --need to update index.lua in aibrains folder hook with the keys of all ais being added
            name = 'AIx: AiBot Navy',
            rating = 800,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
        {
            key = 'aibotairandomcheat', --need to update index.lua in aibrains folder hook with the keys of all ais being added
            name = 'AIx: AiBot Random',
            rating = 800,
            ratingCheatMultiplier = 1300.0, --This is multiplied to the value, so 1.0 will give this amount
            ratingBuildMultiplier = 1000.0,
            ratingNegativeThreshold = 200,
            ratingOmniBonus = 50,
            ratingMapMultiplier = {
                [256] = 0.7895,   -- 5x5 (was 0.778)
                [512] = 1,   -- 10x10
                [1024] = 1.05,  -- 20x20
                [2048] = 1, -- 40x40
                [4096] = 0.9,  -- 80x80
            }
        },
    },
}
