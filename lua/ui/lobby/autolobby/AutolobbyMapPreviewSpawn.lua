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

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local GameColors = import("/lua/gamecolors.lua").GameColors
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

---@class UIAutolobbyMapPreviewSpawn : Bitmap
---@field Icon Bitmap
---@field Faction? number
local AutolobbyMapPreviewSpawn = ClassUI(Bitmap) {

    CommanderPath = "/textures/ui/icons_strategic/commander_generic.dds",
    FactionNames = {'UEF', 'Aeon', 'Cybran', 'Seraphim', 'Random'},

    ---@param self UIAutolobbyMapPreviewSpawn
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent, self.CommanderPath)
        self:SetColorMask('ff101018')
        self.Icon = Bitmap(self, self.CommanderPath)
        self.Icon:DisableHitTest()

        self.Faction = nil
        self:Hide()
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self)
            :Width(24)
            :Height(24)
            :Over(parent, 32)
            :End()
        LayoutHelpers.ReusedLayoutFor(self.Icon)
            :Width(20)
            :Height(20)
            :AtCenterIn(self)
            :Over(self, 1)
            :End()
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    Reset = function(self)
        self.Faction = nil
        self:Hide()
    end,

    ---@param self Control
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:SetAlpha(0.8)
        elseif event.Type == 'MouseExit' then
            self:SetAlpha(1.0)
        end

        return true
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    Show = function(self)
        if self.Faction then
            Bitmap.Show(self)
        else
            self:Hide()
        end
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    ---@param playerOptions UIAutolobbyPlayer
    Update = function(self, playerOptions)
        self.Faction = playerOptions.Faction or 5
        self.Icon:SetColorMask(GameColors.PlayerColors[playerOptions.PlayerColor or 0] or 'ffffffff')
        Tooltip.AddControlTooltip(self, {
            text = playerOptions.PlayerName or '',
            body = '#' .. tostring(playerOptions.StartSpot or '')
                .. '  ' .. (self.FactionNames[self.Faction] or 'Random'),
        })
        self:Show()
    end,
}

---@param parent Control
---@return UIAutolobbyMapPreviewSpawn
Create = function(parent)
    return AutolobbyMapPreviewSpawn(parent)
end
