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
        "940000", -- (01) dark red
        "FE0000", -- (02) Cybran red
        "FF8385", -- (03) light red
        "A54900", -- (04) black and orange
        "FD862C", -- (05) light orange
        "FFAD7B", -- (06) light orange1
        "AD9A00", -- (07) dark yellow
        "FFFC04", -- (08) yellow
        "FFFF6B", -- (09) light yellow
        "007000", -- (10) dark green
        "00BE32", -- (11) nautical
        "72FF59", -- (12) light green
        "0008FF", -- (13) blue
        "3141D5", -- (14) UEF blue
        "5A69FF", -- (15) light blue
        "006162", -- (16) dark navy blue
        "00BDB6", -- (17) dark turquoise
        "00FFF7", -- (18) turquoise
        "6B01AC", -- (19) violet
		"B20ADB", -- (20) light purple
        "A461FF", -- (21) purple
        "FF009C", -- (22) dark pink
        "FF04F7", -- (23) pink
        "FF8EF6", -- (24) light pink
        "000000", -- (25) black
        "ffffffff", -- (26) white
        "ff616d7e", -- (27) grey
        "FF0042", -- (28) crimson
        "FF5D00", -- (29) orange
        "FFBE00", -- (30) gold
        "00FF01", -- (31) green
        "210193", -- (32) oceanic
        "004593", -- (33) lacustrine
        "014D49", -- (34) turquoise-green
        "00FEA4", -- (35) greenish-turquoise
    },

    PlayerColors = {
        "940000", -- (01) dark red
        "FE0000", -- (02) Cybran red
        "FF8385", -- (03) light red
        "A54900", -- (04) black and orange
        "FD862C", -- (05) light orange
        "FFAD7B", -- (06) light orange1
        "AD9A00", -- (07) dark yellow
        "FFFC04", -- (08) yellow
        "FFFF6B", -- (09) light yellow
        "007000", -- (10) dark green
        "00BE32", -- (11) nautical
        "72FF59", -- (12) light green
        "0008FF", -- (13) blue
        "3141D5", -- (14) UEF blue
        "5A69FF", -- (15) light blue
        "006162", -- (16) dark navy blue
        "00BDB6", -- (17) dark turquoise
        "00FFF7", -- (18) turquoise
        "6B01AC", -- (19) violet
		"B20ADB", -- (20) light purple
        "A461FF", -- (21) purple
        "FF009C", -- (22) dark pink
        "FF04F7", -- (23) pink
        "FF8EF6", -- (24) light pink
        "000000", -- (25) black
        "ffffffff", -- (26) white
        "ff616d7e", -- (27) grey
        "FF0042", -- (28) crimson
        "FF5D00", -- (29) orange
        "FFBE00", -- (30) gold
        "00FF01", -- (31) green
        "210193", -- (32) oceanic
        "004593", -- (33) lacustrine
        "014D49", -- (34) turquoise-green
        "00FEA4", -- (35) greenish-turquoise
    },

    TeamColorMode = {
        Self = "RoyalBlue",
        Enemy = "FFE80A0A",
        Ally = "DarkGreen",
        Neutral = "Goldenrod",
    },

    UnidentifiedColor = "FF808080",
}
