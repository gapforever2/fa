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
    11, -- "ff436eee" (11) new blue1
    01, -- "FFe80a0a" (01) Cybran red

    -- 2v2
    12, -- "FF2929e1" (12) UEF blue
    02, -- "ff901427" (02) dark red

    -- 3v3
    14, -- "ff9161ff" (14) purple
    03, -- "FFFF873E" (03) Nomads orange

    -- 4v4
    15, -- "ff66ffcc" (15) aqua
    05, -- "ffa79602" (05) Sera golden

    -- beyond 4v4, which we'll not likely support any time soon.
    08,
    19,
    07,
    05,
    13,
    16,
    17,
    04
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
    LobbyColorOrder = { 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29 }, -- rainbow-like color for Fearghal

    -- If you end up working with this file, suggestion to install the Color Highlight extension:
    -- - https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight
    -- and temporarily pre-append a -- to each color :)

    -- Faction colours
    ArmyColors = {
       "FFe80a0a", -- (01) Cybran red
        "7c0000", -- (02) dark red
        "FFFF873E", -- (03) Nomads orange
        "914805", -- (04) new brown
        "ffa79602", -- (05) Sera golden
        "fffafa00", -- (06) new yellow
        "adff77", -- (07) Order Green
        "ff40bf40", -- (08) mid green
        "257100", -- (09) new green
        "FF2F4F4F", -- (10) olive (dark green)
        "3D66E2", -- (11) new blue1
        "3544C9", -- (12) UEF blue
        "9E18D3", -- (13) dark purple
        "ff9161ff", -- (14) purple
        "ff66ffcc", -- (15) aqua
        "ffffffff", -- (16) white
        "ff616d7e", -- (17) grey
        "ffff88ff", -- (18) pink
        "EC0BEC", -- (19) new fuschia
        "26018B", -- (20) VIOLET
        "FFBF00", -- (21) Gold
        "00BFFF", -- (22) Deep sky blue
        "26FF00", -- (23) Neon green
        "FF5E00", -- (24) Hot pink
        "EAFF004C", -- (25) Raspberry
        "09498A", -- (26) dark blue
        "FF009D", -- (27) pinkpink
        "660066", -- (28) The Great
        "00FFAA", -- (29) new turquoise
    },

    PlayerColors = {
        "FFe80a0a", -- (01) Cybran red
        "7c0000", -- (02) dark red
        "FFFF873E", -- (03) Nomads orange
        "914805", -- (04) new brown
        "ffa79602", -- (05) Sera golden
        "fffafa00", -- (06) new yellow
        "adff77", -- (07) Order Green
        "ff40bf40", -- (08) mid green
        "257100", -- (09) new green
        "FF2F4F4F", -- (10) olive (dark green)
        "3D66E2", -- (11) new blue1
        "3544C9", -- (12) UEF blue
        "9E18D3", -- (13) dark purple
        "ff9161ff", -- (14) purple
        "ff66ffcc", -- (15) aqua
        "ffffffff", -- (16) white
        "ff616d7e", -- (17) grey
        "ffff88ff", -- (18) pink
        "EC0BEC", -- (19) new fuschia
		"26018B", -- (20) VIOLET
        "FFBF00", -- (21) Gold
        "00BFFF", -- (22) Deep sky blue
        "26FF00", -- (23) Neon green
        "FF5E00", -- (24) Hot pink
        "EAFF004C", -- (25) Raspberry
        "09498A", -- (26) dark blue
        "FF009D", -- (27) pinkpink
        "660066", -- (28) The Great
        "00FFAA", -- (29) new turquoise
    },

    TeamColorMode = {
        Self = "RoyalBlue",
        Enemy = "FFE80A0A",
        Ally = "DarkGreen",
        Neutral = "Goldenrod",
    },

    UnidentifiedColor = "FF808080",
}
