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

-- This module is designed to support a form of 'hot reload' that is seen in modern programming
-- languages. To make this possible there can be only one instance of the class that this module
-- represents. And no direct references of the module and/or of the instance should be kept. In
-- short:
--
-- - (1) Always import the module whenever you need to interact with it.
-- - (2) Always use the `GetSingleton` helper function to obtain a reference to the instance.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local AutolobbyMapPreview = import("/lua/ui/lobby/autolobby/autolobbymappreview.lua")
local AutolobbyConnectionMatrix = import("/lua/ui/lobby/autolobby/autolobbyconnectionmatrix.lua")
local AutolobbyTeamDisplay = import("/lua/ui/lobby/autolobby/autolobbyteamdisplay.lua")

---@class UIAutolobbyInterfaceState
---@field PlayerCount number
---@field PlayerOptions? table<UILobbyPeerId, UIAutolobbyPlayer>
---@field PathToScenarioFile? FileName
---@field GameOptions? UILobbyLaunchGameOptionsConfiguration
---@field Connections? UIAutolobbyConnections
---@field Statuses? UIAutolobbyStatus
---@field ConnectionTimeoutSeconds? number
---@field IsGafAutohost? boolean

---@class UIAutolobbyInterface : Group
---@field State UIAutolobbyInterfaceState
---@field BackgroundTextures string[]
---@field Background Bitmap
---@field Preview UIAutolobbyMapPreview
---@field ConnectionMatrix UIAutolobbyConnectionMatrix
---@field TeamDisplay UIAutolobbyTeamDisplay
---@field TimeoutLabel Text
---@field TimeoutThread? thread
local AutolobbyInterface = Class(Group) {

    BackgroundTextures = {
        "/menus02/background-paint01_bmp.dds",
        "/menus02/background-paint02_bmp.dds",
        "/menus02/background-paint03_bmp.dds",
        "/menus02/background-paint04_bmp.dds",
        "/menus02/background-paint05_bmp.dds",
    },

    ---@param self UIAutolobbyInterface
    ---@param parent Control
    __init = function(self, parent, playerCount)
        Group.__init(self, parent, "AutolobbyInterface")

        -- initial, empty state
        self.State = {
            PlayerCount = playerCount
        }

        local backgroundTexture = self.BackgroundTextures[math.random(1, 5)] --[[@as FileName]]
        self.Background = UIUtil.CreateBitmap(self, backgroundTexture)
        self.Preview = AutolobbyMapPreview.GetInstance(self)
        self.ConnectionMatrix = AutolobbyConnectionMatrix.Create(self, playerCount)
        self.TeamDisplay = AutolobbyTeamDisplay.Create(self, playerCount)
        self.TimeoutLabel = UIUtil.CreateText(self, "", 16, UIUtil.bodyFont)
        self.TimeoutLabel:SetColor("FFFFCC00")
        self.TimeoutLabel:SetDropShadow(true)
        self.TimeoutLabel:DisableHitTest(true)
        self.TimeoutLabel:Hide()
        self.TimeoutThread = nil
    end,

    ---@param self UIAutolobbyInterface
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self)
            :Fill(parent)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Background)
            :Fill(self)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Preview)
            :AtCenterIn(self, -100, 0)
            :Width(400)
            :Height(400)
            :Hide()
            :End()

        LayoutHelpers.ReusedLayoutFor(self.ConnectionMatrix)
            :CenteredBelow(self.Preview, 20)
            :Hide()
            :End()

        LayoutHelpers.ReusedLayoutFor(self.TeamDisplay)
            :Fill(self)
            :Hide()
            :End()

        LayoutHelpers.ReusedLayoutFor(self.TimeoutLabel)
            :CenteredBelow(self.ConnectionMatrix, 10)
            :Hide()
            :End()
    end,

    --- Switches to the GAF permanent-autohost presentation. Matchmaking and
    --- regular client lobbies retain the original connection matrix.
    ---@param self UIAutolobbyInterface
    ---@param enabled boolean
    SetGafAutohostMode = function(self, enabled)
        enabled = enabled == true
        self.State.IsGafAutohost = enabled

        if enabled then
            self.ConnectionMatrix:Hide()
            self.TeamDisplay:Show()
            LayoutHelpers.ReusedLayoutFor(self.Preview)
                :AtCenterIn(self, 0, -8)
                :Width(400)
                :Height(400)
                :End()
            LayoutHelpers.ReusedLayoutFor(self.TimeoutLabel)
                :CenteredBelow(self.Preview, 14)
                :End()
        else
            self.TeamDisplay:Hide()
            LayoutHelpers.ReusedLayoutFor(self.Preview)
                :AtCenterIn(self, -100, 0)
                :Width(400)
                :Height(400)
                :End()
            LayoutHelpers.ReusedLayoutFor(self.ConnectionMatrix)
                :CenteredBelow(self.Preview, 20)
                :End()
            LayoutHelpers.ReusedLayoutFor(self.TimeoutLabel)
                :CenteredBelow(self.ConnectionMatrix, 10)
                :End()
        end
    end,

    ---@param self UIAutolobbyInterface
    ---@param ownership boolean[][]
    UpdateOwnership = function(self, ownership)
        self.State.OwnerShip = ownership

        if not self.State.IsGafAutohost then
            self.ConnectionMatrix:Show()
            self.ConnectionMatrix:UpdateOwnership(ownership)
        end
    end,

    ---@param self UIAutolobbyInterface
    ---@param connections UIAutolobbyConnections
    UpdateConnections = function(self, connections)
        self.State.Connections = connections

        if not self.State.IsGafAutohost then
            self.ConnectionMatrix:Show()
            self.ConnectionMatrix:UpdateConnections(connections)
        end
    end,

    ---@param self UIAutolobbyInterface
    ---@param statuses UIAutolobbyStatus
    UpdateLaunchStatuses = function(self, statuses)
        self.State.Statuses = statuses

        if self.State.IsGafAutohost then
            self.TeamDisplay:UpdateStatuses(statuses)
        else
            self.ConnectionMatrix:Show()
            self.ConnectionMatrix:UpdateStatuses(statuses)
        end
    end,

    ---@param self UIAutolobbyInterface
    ---@param pathToScenarioInfo FileName
    ---@param playerOptions UIAutolobbyPlayer[]
    UpdateScenario = function(self, pathToScenarioInfo, playerOptions)
        self.State.PathToScenarioFile = pathToScenarioInfo
        self.State.PlayerOptions = playerOptions

        if self.State.IsGafAutohost then
            self.ConnectionMatrix:Hide()
            self.TeamDisplay:UpdatePlayers(playerOptions)
        else
            self.ConnectionMatrix:Show()
            self.ConnectionMatrix:UpdatePlayerNames(playerOptions)
        end

        if pathToScenarioInfo and playerOptions then
            -- hide it for now until we have a better way to decipher its possible (negative) impact
            self.Preview:Show()
            self.Preview:UpdateScenario(pathToScenarioInfo, playerOptions)
        end
    end,

    ---@param self UIAutolobbyInterface
    ---@param id number
    UpdateIsAliveStamp = function(self, id)
        if not self.State.IsGafAutohost then
            self.ConnectionMatrix:UpdateIsAliveTimestamp(id)
        end
    end,

    --- Shows the server-provided time remaining for peers to connect.
    ---@param self UIAutolobbyInterface
    ---@param timeoutSeconds number
    StartConnectionCountdown = function(self, timeoutSeconds)
        if self.TimeoutThread then
            KillThread(self.TimeoutThread)
            self.TimeoutThread = nil
        end

        timeoutSeconds = math.max(0, tonumber(timeoutSeconds) or 0)
        if timeoutSeconds <= 0 then
            self.TimeoutLabel:Hide()
            return
        end

        local deadline = GetSystemTimeSeconds() + timeoutSeconds
        -- Rebuilding the view must never grant a new connection window.
        if self.State.ConnectionDeadlineSeconds then
            deadline = math.min(deadline, self.State.ConnectionDeadlineSeconds)
        end
        self.State.ConnectionDeadlineSeconds = deadline
        self.TimeoutLabel:Show()
        self.TimeoutThread = ForkThread(function()
            while not IsDestroyed(self) do
                local remaining = math.max(0, math.ceil(deadline - GetSystemTimeSeconds()))
                local minutes = math.floor(remaining / 60)
                local seconds = math.mod(remaining, 60)
                local clock = string.format("%02d:%02d", minutes, seconds)
                self.TimeoutLabel:SetText(string.format(
                    LOC("<LOC gaf_autolobby_connect_timeout>Waiting for players: %s"),
                    clock
                ))
                if remaining <= 0 then
                    self.TimeoutThread = nil
                    -- No more peers may join after the server deadline. Closing
                    -- this stalled auto-lobby also lets the Java client present
                    -- the final timeout state instead of leaving FA open forever.
                    ExitApplication()
                    return
                end
                WaitSeconds(1)
            end
        end)
    end,

    OnDestroy = function(self)
        if self.TimeoutThread then
            KillThread(self.TimeoutThread)
            self.TimeoutThread = nil
        end
        Group.OnDestroy(self)
    end,

    --#region Debugging

    ---@param self UIAutolobbyInterface
    ---@param state UIAutolobbyInterfaceState
    RestoreState = function(self, state)
        self.State = state
        self:SetGafAutohostMode(state.IsGafAutohost)

        if state.PathToScenarioFile and state.PlayerOptions then
            local ok, msg = pcall(self.UpdateScenario, self, state.PathToScenarioFile, state.PlayerOptions)
            if not ok then
                WARN(msg)
            end
        end

        if state.Connections then
            local ok, msg = pcall(self.UpdateConnections, self, state.Connections)
            if not ok then
                WARN(msg)
            end
        end

        if state.Statuses then
            local ok, msg = pcall(self.UpdateLaunchStatuses, self, state.Statuses)
            if not ok then
                WARN(msg)
            end
        end

        if state.ConnectionDeadlineSeconds then
            self:StartConnectionCountdown(math.max(0.001,
                state.ConnectionDeadlineSeconds - GetSystemTimeSeconds()))
        end
    end,

    --#endregion
}

--- A trashbag that should be destroyed upon reload.
local ModuleTrash = TrashBag()

---@type UIAutolobbyInterface | false
local AutolobbyInterfaceInstance = false

---@param playerCount? number
---@return UIAutolobbyInterface
GetSingleton = function(playerCount)
    if AutolobbyInterfaceInstance then
        return AutolobbyInterfaceInstance
    end

    -- default
    playerCount = playerCount or 8

    AutolobbyInterfaceInstance = AutolobbyInterface(GetFrame(0), playerCount)
    ModuleTrash:Add(AutolobbyInterfaceInstance)
    return AutolobbyInterfaceInstance
end

---@param playerCount? number
---@return UIAutolobbyInterface
SetupSingleton = function(playerCount)
    if AutolobbyInterfaceInstance then
        AutolobbyInterfaceInstance:Destroy()
    end

    -- default
    playerCount = playerCount or tonumber(GetCommandLineArg("/players", 1)[1]) or 8

    AutolobbyInterfaceInstance = AutolobbyInterface(GetFrame(0), playerCount)
    ModuleTrash:Add(AutolobbyInterfaceInstance)
    return AutolobbyInterfaceInstance
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if AutolobbyInterfaceInstance then
        local handle = newModule.SetupSingleton(AutolobbyInterfaceInstance.State.PlayerCount)
        handle:RestoreState(AutolobbyInterfaceInstance.State)
    end
end

--- Called by the module manager when this module becomes dirty
function __moduleinfo.OnDirty()
    ModuleTrash:Destroy()
    import(__moduleinfo.name)
end

--#endregionGetSingleton
