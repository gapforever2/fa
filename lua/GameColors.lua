--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- When launching a lobby each player has a configuration. This configuration has the
-- fields `ArmyColor` and `PlayerColor`. The values of these fields are numbers. This
-- module is responsible for converting the integer-based player and army colors
-- into a hex-based color string that the engine understands.

local WarmColdMapping = {
    -- 1v1
    9, -- blue
    2, -- Cybran red

    -- 2v2
    10, -- UEF blue
    1, -- dark red

    -- 3v3
    13, -- violet
    4, -- light orange

    -- 4v4
    12, -- turquoise
    5, -- yellow

    -- beyond 4v4, which we'll not likely support any time soon.
    8,
    3,
    7,
    6,
    11,
    14,
    16,
    15
}

--- Maps the start location of a player into a a warm vs cold color scheme. Read the
--- introduction of this module for more context.
---@param startSpot number
---@return number
MapToWarmCold = function(startSpot)
    return WarmColdMapping[startSpot]
end

--- Determines the available colors for players and the default color order for
-- matchmaking. See autolobby.lua and lobby.lua for more information.
GameColors = {

    CivilianArmyColor = "BurlyWood",

    -- Default color order used for lobbies/TMM if not otherwise specified. Tightly coupled
    -- with the ArmyColors and the PlayerColors tables.
    LobbyColorOrder = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 },

    -- Every color needs an explicit policy, independent of its position/RGB.
    -- Add new colors to BOTH arrays below, then add their policy here.
    -- Missing/unknown policies are denied in-game and block publication.
    PlayerColorAccess = {
        [1] = 'public',
        [2] = 'public',
        [3] = 'public',
        [4] = 'public',
        [5] = 'public',
        [6] = 'public',
        [7] = 'public',
        [8] = 'public',
        [9] = 'public',
        [10] = 'public',
        [11] = 'public',
        [12] = 'public',
        [13] = 'public',
        [14] = 'public',
        [15] = 'public',
        [16] = 'public',
        [17] = 'premium',
        [18] = 'premium',
        [19] = 'premium',
        [20] = 'premium',
        [21] = 'premium',
        [22] = 'premium',
        [23] = 'premium',
        [24] = 'premium',
        [25] = 'premium',
        [26] = 'admin',
    },

    -- If you end up working with this file, suggestion to install the Color Highlight extension:
    -- - https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight
    -- and temporarily pre-append a -- to each color :)

    -- Faction colours
    ArmyColors = {
        "FFe80a0a", -- (01) Cybran red
        "7c0000",   -- (02) dark red
        "FFFF873E", -- (03) Nomads orange
        "914805",   -- (04) new brown
        "ffa79602", -- (05) Sera golden
        "fffafa00", -- (06) new yellow
        "adff77",   -- (07) Order Green
        "ff40bf40", -- (08) mid green
        "257100",   -- (09) new green
        "FF2F4F4F", -- (10) olive (dark green)
        "3D66E2",   -- (11) new blue1
        "9E18D3",   -- (12) dark purple
        "ff9161ff", -- (13) purple
        "ff66ffcc", -- (14) aqua
        "ffffffff", -- (15) white
        "ff616d7e", -- (16) grey
        "ffff88ff", -- (17) pink
        "26018B",   -- (18) VIOLET
        "FFBF00",   -- (19) Gold
        "00BFFF",   -- (20) Deep sky blue
        "26FF00",   -- (21) Neon green
        "FF5E00",   -- (22) Hot pink
        "EAFF004C", -- (23) Raspberry
        "09498A",   -- (24) dark blue
        "FF009D",   -- (25) pinkpink
        "FF000000", -- (26) black, explicitly opaque
    },

    PlayerColors = {
       "FFe80a0a", -- (01) Cybran red
        "7c0000",   -- (02) dark red
        "FFFF873E", -- (03) Nomads orange
        "914805",   -- (04) new brown
        "ffa79602", -- (05) Sera golden
        "fffafa00", -- (06) new yellow
        "adff77",   -- (07) Order Green
        "ff40bf40", -- (08) mid green
        "257100",   -- (09) new green
        "FF2F4F4F", -- (10) olive (dark green)
        "3D66E2",   -- (11) new blue1
        "9E18D3",   -- (12) dark purple
        "ff9161ff", -- (13) purple
        "ff66ffcc", -- (14) aqua
        "ffffffff", -- (15) white
        "ff616d7e", -- (16) grey
        "ffff88ff", -- (17) pink
        "26018B",   -- (18) VIOLET
        "FFBF00",   -- (19) Gold
        "00BFFF",   -- (20) Deep sky blue
        "26FF00",   -- (21) Neon green
        "FF5E00",   -- (22) Hot pink
        "EAFF004C", -- (23) Raspberry
        "09498A",   -- (24) dark blue
        "FF009D",   -- (25) pinkpink
        "FF000000", -- (26) black, explicitly opaque
    },

    TeamColorMode = {
        Self = "RoyalBlue",
        Enemy = "FFE80A0A",
        Ally = "DarkGreen",
        Neutral = "Goldenrod",
    },

    UnidentifiedColor = "FF808080",
}

--- Shared UI/host policy. The autohost server independently enforces this policy.
CanUsePlayerColor = function(index, role)
    if type(index) ~= 'number' or index ~= math.floor(index) or not GameColors.PlayerColors[index] then
        return false
    end
    role = type(role) == 'string' and string.lower(role) or ''
    local access = GameColors.PlayerColorAccess[index]
    if access == 'public' then
        return true
    end
    if access == 'admin' then
        return role == 'admin'
    end
    if access == 'premium' then
        return role == 'admin' or role == 'mod' or role == 'bal' or role == 'yt' or role == 'bs'
    end
    return false
end
