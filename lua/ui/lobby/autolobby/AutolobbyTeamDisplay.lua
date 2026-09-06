--******************************************************************************************************
--** GAF permanent autohost versus layout
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local GameColors = import("/lua/gamecolors.lua").GameColors

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local FactionIconPaths = {
    "/textures/ui/common/faction_icon-lg/uef_med.dds",
    "/textures/ui/common/faction_icon-lg/aeon_med.dds",
    "/textures/ui/common/faction_icon-lg/cybran_med.dds",
    "/textures/ui/common/faction_icon-lg/seraphim_med.dds",
}

local UnknownFactionIconPath = "/textures/ui/common/faction_icon-sm/random_ico.dds"
local AvatarDirectory = "/preferences/autolobby/avatars/"

---@class UIAutolobbyTeamPlayerRow : Group
---@field Mirrored boolean
---@field Spot? number
local AutolobbyTeamPlayerRow = Class(Group) {

    ---@param self UIAutolobbyTeamPlayerRow
    ---@param parent Control
    ---@param mirrored boolean
    __init = function(self, parent, mirrored)
        Group.__init(self, parent, "AutolobbyTeamPlayerRow")

        self.Mirrored = mirrored
        self.Spot = nil
        self.PlayerOptions = nil
        self.CurrentStatus = nil
        self.Background = UIUtil.CreateBitmapColor(self, "DD141A22")
        self.ColorBar = UIUtil.CreateBitmapColor(self, "FFFFFFFF")
        -- UIUtil.CreateBitmap requires a non-nil texture and crashes while the
        -- row is still waiting for the real account avatar.
        self.Avatar = Bitmap(self)
        self.Faction = UIUtil.CreateBitmap(self, UnknownFactionIconPath)
        self.Name = UIUtil.CreateText(self, "", 16, UIUtil.titleFont)
        self.Status = UIUtil.CreateText(self, "", 11, UIUtil.bodyFont)
        self.StatusDot = UIUtil.CreateBitmapColor(self, "FFFFC857")

        self.Name:SetColor("FFFFFFFF")
        self.Name:SetDropShadow(true)
        self.Name:SetClipToWidth(true)
        self.Status:SetColor("FFB8C2CC")
        self.Status:SetClipToWidth(true)

        self:DisableHitTest(true)
        self:Hide()
    end,

    ---@param self UIAutolobbyTeamPlayerRow
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self)
            :Width(360)
            :Height(58)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Background)
            :Fill(self)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.ColorBar)
            :Width(6)
            :Height(58)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Avatar)
            :Width(40)
            :Height(20)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Faction)
            :Width(28)
            :Height(28)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.StatusDot)
            :Width(8)
            :Height(8)
            :End()

        if self.Mirrored then
            LayoutHelpers.AtRightTopIn(self.ColorBar, self)
            LayoutHelpers.AtRightTopIn(self.Avatar, self, 18, 19)
            LayoutHelpers.AtLeftTopIn(self.Faction, self, 10, 15)
            LayoutHelpers.AtLeftTopIn(self.Name, self, 48, 8)
            LayoutHelpers.AtLeftTopIn(self.StatusDot, self, 48, 39)
            LayoutHelpers.AtLeftTopIn(self.Status, self, 62, 31)
        else
            LayoutHelpers.AtLeftTopIn(self.ColorBar, self)
            LayoutHelpers.AtLeftTopIn(self.Avatar, self, 18, 19)
            LayoutHelpers.AtRightTopIn(self.Faction, self, 10, 15)
            LayoutHelpers.AtLeftTopIn(self.Name, self, 70, 8)
            LayoutHelpers.AtLeftTopIn(self.StatusDot, self, 70, 39)
            LayoutHelpers.AtLeftTopIn(self.Status, self, 84, 31)
        end

        self.Name.Width:Set(220)
        self.Status.Width:Set(205)
    end,

    ---@param self UIAutolobbyTeamPlayerRow
    ---@param playerOptions UIAutolobbyPlayer
    UpdatePlayer = function(self, playerOptions)
        self.Spot = playerOptions.StartSpot
        self.PlayerOptions = playerOptions
        self.Name:SetText(playerOptions.PlayerName or "")

        local connected = playerOptions.OwnerID != nil
        self:UpdateStatus(nil, connected)
        self:Show()
    end,

    --- Player color, avatar and faction are authoritative only after this FA
    --- process has connected to every expected peer. Showing them earlier made
    --- server-side /random placeholders look like two unrelated faction icons.
    ---@param self UIAutolobbyTeamPlayerRow
    ---@param ready boolean
    UpdateDecorations = function(self, ready)
        local playerOptions = self.PlayerOptions
        if not ready or not playerOptions then
            self.AvatarLoaded = false
            self.ColorBar:Hide()
            self.Avatar:Hide()
            self.Faction:Hide()
            self.Name.Left:Set(function() return self.Left() + 14 end)
            self.StatusDot.Left:Set(function() return self.Left() + 14 end)
            self.Status.Left:Set(function() return self.Left() + 28 end)
            return
        end

        local color = GameColors.PlayerColors[playerOptions.PlayerColor or 0]
            or "FF6F7B88"
        self.ColorBar:SetSolidColor(color)
        self.ColorBar:Show()

        local factionIcon = FactionIconPaths[playerOptions.Faction]
            or UnknownFactionIconPath
        self.Faction:SetTexture(UIUtil.UIFile(factionIcon))
        self.Faction:Show()

        local hasAvatar = type(playerOptions.Avatar) == "string"
            and playerOptions.Avatar != ""
        local avatarFile = hasAvatar and playerOptions.Avatar or "none.png"
        hasAvatar = not not DiskGetFileInfo(AvatarDirectory .. avatarFile)
        self.AvatarLoaded = hasAvatar
        if hasAvatar then
            -- A mounted avatar is already a complete path, not a skin-relative UI asset.
            self.Avatar:SetTexture(AvatarDirectory .. avatarFile)
            self.Avatar:SetAlpha(1.0)
            self.Avatar:Show()
        else
            -- Do not upscale the tiny diplomacy silhouette: it becomes a very
            -- pixelated placeholder. Empty is both cleaner and truthful when
            -- the server did not select an account avatar.
            self.Avatar:Hide()
        end

        if self.Mirrored then
            self.Name.Left:Set(function() return self.Left() + 48 end)
            self.StatusDot.Left:Set(function() return self.Left() + 48 end)
            self.Status.Left:Set(function() return self.Left() + 62 end)
        elseif hasAvatar then
            self.Name.Left:Set(function() return self.Left() + 70 end)
            self.StatusDot.Left:Set(function() return self.Left() + 70 end)
            self.Status.Left:Set(function() return self.Left() + 84 end)
        else
            self.Name.Left:Set(function() return self.Left() + 14 end)
            self.StatusDot.Left:Set(function() return self.Left() + 14 end)
            self.Status.Left:Set(function() return self.Left() + 28 end)
        end
    end,

    ---@param self UIAutolobbyTeamPlayerRow
    ---@param status? UIPeerLaunchStatus
    ---@param connected? boolean
    UpdateStatus = function(self, status, connected)
        local previousStatus = self.CurrentStatus
        local previousConnected = self.Connected
        if connected == nil then
            connected = self.Connected
        else
            self.Connected = connected
        end

        self.CurrentStatus = status
        self:UpdateDecorations(connected and status == "Ready")

        if previousStatus != status or previousConnected != connected then
            local playerOptions = self.PlayerOptions or {}
            LOG("[GAF-AUTOLOBBY-ROW] spot=", tostring(self.Spot),
                " name=", tostring(playerOptions.PlayerName),
                " connected=", tostring(connected),
                " status=", tostring(status),
                " faction=", tostring(playerOptions.Faction),
                " avatar=", tostring(playerOptions.Avatar),
                " avatarLoaded=", tostring(self.AvatarLoaded),
                " decorated=", tostring(connected and status == "Ready"))
        end

        if self.PlayerOptions and self.PlayerOptions.ReturnDeclined then
            self:UpdateDecorations(false)
            self.Status:SetText(LOC("<LOC gaf_autolobby_return_declined>Will not return"))
            self.Status:SetColor("FFFF7777")
            self.StatusDot:SetSolidColor("FFFF5555")
        elseif connected and status == "Ready" then
            self.Status:SetText(LOC("<LOC lobui_0218>Ready"))
            self.Status:SetColor("FF78D98B")
            self.StatusDot:SetSolidColor("FF56D364")
        elseif connected then
            self.Status:SetText(LOC("<LOC gaf_autolobby_waiting>Waiting..."))
            self.Status:SetColor("FF8EC9FF")
            self.StatusDot:SetSolidColor("FF3DA5FF")
        else
            self.Status:SetText(LOC("<LOC lobui_0331>Connecting..."))
            self.Status:SetColor("FFFFD37A")
            self.StatusDot:SetSolidColor("FFFFC857")
        end
    end,

    Reset = function(self)
        self.Spot = nil
        self.PlayerOptions = nil
        self.CurrentStatus = nil
        self.Connected = false
        self:Hide()
    end,
}

---@class UIAutolobbyTeamDisplay : Group
---@field PlayerCount number
---@field MaxRows number
---@field LeftRows UIAutolobbyTeamPlayerRow[]
---@field RightRows UIAutolobbyTeamPlayerRow[]
local AutolobbyTeamDisplay = Class(Group) {

    ---@param self UIAutolobbyTeamDisplay
    ---@param parent Control
    ---@param playerCount number
    __init = function(self, parent, playerCount)
        Group.__init(self, parent, "AutolobbyTeamDisplay")

        self.PlayerCount = playerCount
        self.MaxRows = math.ceil(playerCount / 2)
        self.Statuses = {}
        self.LeftPanel = UIUtil.CreateBitmapColor(self, "B20A0F16")
        self.RightPanel = UIUtil.CreateBitmapColor(self, "B20A0F16")
        self.LeftHeader = UIUtil.CreateText(
            self, LOC("<LOC lobui_0096>Team") .. " 1", 20, UIUtil.titleFont
        )
        self.RightHeader = UIUtil.CreateText(
            self, LOC("<LOC lobui_0096>Team") .. " 2", 20, UIUtil.titleFont
        )
        self.VersusLabel = UIUtil.CreateText(self, "VS", 28, UIUtil.titleFont)
        self.LeftRows = {}
        self.RightRows = {}

        self.LeftHeader:SetColor("FF7EBBFF")
        self.LeftHeader:SetDropShadow(true)
        self.RightHeader:SetColor("FFFF8A8A")
        self.RightHeader:SetDropShadow(true)
        self.VersusLabel:SetColor("FFFFCC55")
        self.VersusLabel:SetDropShadow(true)

        for index = 1, self.MaxRows do
            self.LeftRows[index] = AutolobbyTeamPlayerRow(self, false)
            self.RightRows[index] = AutolobbyTeamPlayerRow(self, true)
        end

        self:DisableHitTest(true)
        self:Hide()
    end,

    ---@param self UIAutolobbyTeamDisplay
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self)
            :Fill(parent)
            :End()

        local panelHeight = 54 + self.MaxRows * 64
        LayoutHelpers.ReusedLayoutFor(self.LeftPanel)
            :Width(376)
            :Height(panelHeight)
            :End()
        self.LeftPanel.Right:Set(function() return self.Left() + self.Width() / 2 - 238 end)
        self.LeftPanel.Top:Set(function() return self.Top() + self.Height() / 2 - panelHeight / 2 end)

        LayoutHelpers.ReusedLayoutFor(self.RightPanel)
            :Width(376)
            :Height(panelHeight)
            :End()
        self.RightPanel.Left:Set(function() return self.Left() + self.Width() / 2 + 238 end)
        self.RightPanel.Top:Set(function() return self.Top() + self.Height() / 2 - panelHeight / 2 end)

        self.LeftHeader.Left:Set(function() return self.LeftPanel.Left() + 12 end)
        self.LeftHeader.Top:Set(function() return self.LeftPanel.Top() + 13 end)
        self.LeftHeader.Width:Set(352)
        self.RightHeader.Left:Set(function() return self.RightPanel.Left() + 12 end)
        self.RightHeader.Top:Set(function() return self.RightPanel.Top() + 13 end)
        self.RightHeader.Width:Set(352)

        LayoutHelpers.AtHorizontalCenterIn(self.VersusLabel, self)
        self.VersusLabel.Top:Set(function() return self.Top() + self.Height() / 2 - 254 end)

        for index = 1, self.MaxRows do
            local rowIndex = index
            local leftRow = self.LeftRows[index]
            leftRow.Left:Set(function() return self.LeftPanel.Left() + 8 end)
            leftRow.Top:Set(function() return self.LeftPanel.Top() + 48 + (rowIndex - 1) * 64 end)

            local rightRow = self.RightRows[index]
            rightRow.Left:Set(function() return self.RightPanel.Left() + 8 end)
            rightRow.Top:Set(function() return self.RightPanel.Top() + 48 + (rowIndex - 1) * 64 end)
        end
    end,

    ---@param self UIAutolobbyTeamDisplay
    ---@param rows UIAutolobbyTeamPlayerRow[]
    ResetRows = function(self, rows)
        for index = 1, self.MaxRows do
            rows[index]:Reset()
        end
    end,

    ---@param self UIAutolobbyTeamDisplay
    ---@param playerOptions UIAutolobbyPlayer[]
    UpdatePlayers = function(self, playerOptions)
        self:ResetRows(self.LeftRows)
        self:ResetRows(self.RightRows)
        if not playerOptions then
            return
        end

        local teamIds = {}
        local seenTeams = {}
        for spot = 1, self.PlayerCount do
            local options = playerOptions[spot]
            if options then
                local team = tonumber(options.Team) or 1
                if not seenTeams[team] then
                    seenTeams[team] = true
                    table.insert(teamIds, team)
                end
            end
        end
        table.sort(teamIds)

        local leftTeam = teamIds[1]
        local rightTeam = teamIds[2]
        local leftIndex = 0
        local rightIndex = 0

        for spot = 1, self.PlayerCount do
            local options = playerOptions[spot]
            if options then
                local team = tonumber(options.Team) or leftTeam
                local useRight = rightTeam and team != leftTeam
                if useRight and rightIndex < self.MaxRows then
                    rightIndex = rightIndex + 1
                    self.RightRows[rightIndex]:UpdatePlayer(options)
                    self.RightRows[rightIndex]:UpdateStatus(
                        self.Statuses[options.StartSpot], options.OwnerID != nil
                    )
                elseif leftIndex < self.MaxRows then
                    leftIndex = leftIndex + 1
                    self.LeftRows[leftIndex]:UpdatePlayer(options)
                    self.LeftRows[leftIndex]:UpdateStatus(
                        self.Statuses[options.StartSpot], options.OwnerID != nil
                    )
                elseif rightIndex < self.MaxRows then
                    rightIndex = rightIndex + 1
                    self.RightRows[rightIndex]:UpdatePlayer(options)
                    self.RightRows[rightIndex]:UpdateStatus(
                        self.Statuses[options.StartSpot], options.OwnerID != nil
                    )
                end
            end
        end

        self:Show()
    end,

    ---@param self UIAutolobbyTeamDisplay
    ---@param statuses UIAutolobbyStatus
    UpdateStatuses = function(self, statuses)
        self.Statuses = statuses or {}
        for index = 1, self.MaxRows do
            local leftRow = self.LeftRows[index]
            if leftRow.Spot then
                leftRow:UpdateStatus(self.Statuses[leftRow.Spot])
            end

            local rightRow = self.RightRows[index]
            if rightRow.Spot then
                rightRow:UpdateStatus(self.Statuses[rightRow.Spot])
            end
        end
    end,
}

---@param parent Control
---@param playerCount number
---@return UIAutolobbyTeamDisplay
Create = function(parent, playerCount)
    return AutolobbyTeamDisplay(parent, playerCount)
end
