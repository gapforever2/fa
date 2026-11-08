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
        [23] = 'admin',
    },

    -- If you end up working with this file, suggestion to install the Color Highlight extension:
    -- - https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight
    -- and temporarily pre-append a -- to each color :)

    -- Faction colours
    ArmyColors = {
        "940000", -- (01) dark red
        "FE0000", -- (02) Cybran red
        "A54900", -- (03) black and orange
        "FE8630", -- (04) light orange
        "FFFC01", -- (05) yellow
        "00FF01", -- (06) green
        "007000", -- (07) dark green
        "00BE32", -- (08) light green
        "0008FF", -- (09) blue
        "42AAFF", -- (10) UEF blue
        "006162", -- (11) dark navy blue
        "00BDB6", -- (12) dark turquoise
        "6B01AC", -- (13) violet
        "FF04F7", -- (14) pink light
        "ffffffff", -- (15) white
        "ff616d7e", -- (16) grey
        "FF009C", -- (17) pink
        "FF5D00", -- (18) orange
        "FFBE00", -- (19) gold
        "004593", -- (20) lacustrine
        "00FEA4", -- (21) greenish-turquoise
        "00FFF7", -- (22) turquoise
        "FF000000", -- (23) black, explicitly opaque
    },

    PlayerColors = {
        "940000", -- (01) dark red
        "FE0000", -- (02) Cybran red
        "A54900", -- (03) black and orange
        "FE8630", -- (04) light orange
        "FFFC01", -- (05) yellow
        "00FF01", -- (06) green
        "007000", -- (07) dark green
        "00BE32", -- (08) light green
        "0008FF", -- (09) blue
        "42AAFF", -- (10) UEF blue
        "006162", -- (11) dark navy blue
        "00BDB6", -- (12) dark turquoise
        "6B01AC", -- (13) violet
        "FF04F7", -- (14) pink light
        "ffffffff", -- (15) white
        "ff616d7e", -- (16) grey
        "FF009C", -- (17) pink
        "FF5D00", -- (18) orange
        "FFBE00", -- (19) gold
        "004593", -- (20) lacustrine
        "00FEA4", -- (21) greenish-turquoise
        "00FFF7", -- (22) turquoise
        "FF000000", -- (23) black, explicitly opaque
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
