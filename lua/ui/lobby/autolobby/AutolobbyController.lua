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

local Utils = import("/lua/system/utils.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local GameColors = import("/lua/gamecolors.lua")
-- Rating defaults (single place to tweak, can be overridden by defining globals in init).
local NEW_PLAYER_GAMES_THRESHOLD = rawget(_G, 'NEW_PLAYER_GAMES_THRESHOLD') or 10
local NEW_PLAYER_DISPLAY_RATING = rawget(_G, 'NEW_PLAYER_DISPLAY_RATING') or 100

--- Decodes the server's ASCII-safe UTF-8 roster representation. Command-line
--- parsing is allowed to alter backslashes, therefore the payload is plain hex.
---@param playerName string
---@return string
local function DecodeExpectedPlayerName(playerName)
    if string.sub(playerName, 1, 8) != "GAFUTF8_" then
        return playerName
    end

    local encodedName = string.sub(playerName, 9)
    if encodedName == "" or math.mod(string.len(encodedName), 2) != 0 then
        return playerName
    end

    local bytes = {}
    for index = 1, string.len(encodedName), 2 do
        local byte = tonumber(string.sub(encodedName, index, index + 1), 16)
        if not byte then
            return playerName
        end
        table.insert(bytes, string.char(byte))
    end
    return table.concat(bytes)
end

local MohoLobbyMethods = moho.lobby_methods
local DebugComponent = import("/lua/shared/components/debugcomponent.lua").DebugComponent
local AutolobbyServerCommunicationsComponent = import("/lua/ui/lobby/autolobby/components/autolobbyservercommunicationscomponent.lua")
    .AutolobbyServerCommunicationsComponent

local AutolobbyArgumentsComponent = import("/lua/ui/lobby/autolobby/components/autolobbyarguments.lua").AutolobbyArgumentsComponent

local AutolobbyMessages = import("/lua/ui/lobby/autolobby/autolobbymessages.lua").AutolobbyMessages

local AutolobbyEngineStrings = {
    --  General info strings
    ['Connecting'] = "<LOC lobui_0083>Connecting to Game",
    ['AbortConnect'] = "<LOC lobui_0204>Abort Connect",
    ['TryingToConnect'] = "<LOC lobui_0331>Connecting...",
    ['TimedOut'] = "<LOC lobui_0205>%s timed out.",
    ['TimedOutToHost'] = "<LOC lobui_0206>Timed out to host.",
    ['Ejected'] = "<LOC lob_0000>You have been ejected: %s",
    ['ConnectionFailed'] = "<LOC lob_0001>Connection failed: %s",
    ['LaunchFailed'] = "<LOC lobui_0207>Launch failed: %s",
    ['LobbyFull'] = "<LOC lobui_0279>The game lobby is full.",

    --  Error reasons
    ['StartSpots'] = "<LOC lob_0002>The map does not support this number of players.",
    ['NoConfig'] = "<LOC lob_0003>No valid game configurations found.",
    ['NoObservers'] = "<LOC lob_0004>Observers not allowed.",
    ['KickedByHost'] = "<LOC lob_0005>Kicked by host.",
    ['GameLaunched'] = "<LOC lob_0008>Game was launched.",
    ['NoLaunchLimbo'] = "<LOC lob_0006>No clients allowed in limbo at launch",
    ['HostLeft'] = "<LOC lob_0007>Host abandoned lobby",
    ['LaunchRejected'] = "<LOC lob_0009>Some players are using an incompatible client version.",
}

-- associated textures are in `/textures/divisions/<division> <subdivision>.png` 
-- Make note of the space, which isn't there for "grandmaster" and "unlisted" divisions

---@alias Division
---| "bronze"
---| "silver"
---| "gold"
---| "diamond"
---| "master"
---| "grandmaster"
---| "unlisted"

---@alias Subdivision
---| "I"
---| "II"
---| "III"
---| "IV"
---| "V"
---| "" # when Division is grandmaster or unlisted

---@class UIAutolobbyPlayer: UILobbyLaunchPlayerConfiguration
---@field StartSpot number
---@field DEV number    # Related to rating/divisions
---@field MEAN number   # Related to rating/divisions
---@field NG number     # Related to rating/divisions
---@field DIV Division    # Related to rating/divisions
---@field SUBDIV Subdivision # Related to rating/divisions
---@field PL number     # Related to rating/divisions
---@field PlayerClan string
---@field GroupRole string|boolean
---@field Avatar string|boolean

---@alias UIAutolobbyConnections boolean[][]
---@alias UIAutolobbyStatus UIPeerLaunchStatus[]

---@class UIAutolobbyParameters
---@field Protocol UILobbyProtocol
---@field LocalPort number
---@field MaxConnections number
---@field DesiredPlayerName string
---@field LocalPlayerPeerId UILobbyPeerId
---@field NatTraversalProvider any

---@class UIAutolobbyHostParameters
---@field GameName string
---@field ScenarioFile string   # path to the _scenario.lua file
---@field SinglePlayer boolean

---@class UIAutolobbyJoinParameters
---@field Address GPGNetAddress
---@field AsObserver boolean
---@field DesiredPlayerName string
---@field DesiredPeerId UILobbyPeerId

--- Responsible for the behavior of the automated lobby.
---@class UIAutolobbyCommunications : moho.lobby_methods, DebugComponent, UIAutolobbyServerCommunicationsComponent, UIAutolobbyArgumentsComponent
---@field Trash TrashBag
---@field LocalPeerId UILobbyPeerId                             # a number that is stringified
---@field LocalPlayerName string                            # nickname
---@field HostID UILobbyPeerId
---@field PlayerCount number                                        # Originates from the command line
---@field GameMods UILobbyLaunchGameModsConfiguration[]
---@field GameOptions UILobbyLaunchGameOptionsConfiguration         # Is synced from the host via `SendData` or `BroadcastData`.
---@field PlayerOptions UIAutolobbyPlayer[]                         # Is synced from the host via `SendData` or `BroadcastData`.
---@field ConnectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>    # Is synced between players via `EstablishedPeers`
---@field LaunchStatutes table<UILobbyPeerId, UIPeerLaunchStatus>  # Is synced between players via `BroadcastData`
---@field ConnectionTimeoutSeconds? number
---@field IsGafAutohost boolean
---@field LobbyParameters? UIAutolobbyParameters                # Used for rejoining functionality
---@field HostParameters? UIAutolobbyHostParameters             # Used for rejoining functionality
---@field JoinParameters? UIAutolobbyJoinParameters             # Used for rejoining functionality
AutolobbyCommunications = Class(MohoLobbyMethods, AutolobbyServerCommunicationsComponent, AutolobbyArgumentsComponent, DebugComponent) {

    ---@param self UIAutolobbyCommunications
    __init = function(self)
        self.Trash = TrashBag()

        self.LocalPeerId = "-2"
        self.LocalPlayerName = "Charlie"
        self.PlayerCount = self:GetCommandLineArgumentNumber("/players", 2)
        self.HostID = "-2"

        self.GameMods = {}
        self.GameOptions = self:CreateLocalGameOptions()
        self.IsGafAutohost = self.GameOptions.GAFExpectedPlayer1 != nil
        self.ControlPrefix = self.GameOptions.GAFControlPrefix
        self.GameOptions.GAFControlPrefix = nil
        if self.ControlPrefix then
            self.ControlPrefix = string.gsub(self.ControlPrefix, '%x%x', function(hex)
                return string.char(tonumber(hex, 16))
            end)
        end
        self.ConnectionTimeoutSeconds = tonumber(self.GameOptions.GAFAutolobbyConnectTimeout)
            or (self.GameOptions.GAFExpectedPlayer1 and 90)
        self.ConnectionDeadlineSeconds = self.ConnectionTimeoutSeconds
            and (GetSystemTimeSeconds() + self.ConnectionTimeoutSeconds)
        self.GameOptions.GAFAutolobbyConnectTimeout = nil
        self.PlayerOptions = self:CreateExpectedPlayers(self.GameOptions)
        self.LaunchStatutes = {}
        self.ConnectionMatrix = {}
    end,

    ---@param self UIAutolobbyCommunications
    __post_init = function(self)
        -- The server launch snapshot is available before ICE peers connect.
        -- Render those names immediately so a missing client is visible instead
        -- of looking like an empty row in the connection matrix.
        local interface = import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
        interface:SetGafAutohostMode(self.IsGafAutohost)
        interface:UpdateScenario(nil, self.PlayerOptions)
        if self.ConnectionTimeoutSeconds then
            interface:StartConnectionCountdown(self.ConnectionTimeoutSeconds)
        end
        if self.IsGafAutohost and self.ControlPrefix then
            LOG('[GAF-AUTOLOBBY] control prefix=', self.ControlPrefix)
            self.Trash:Add(ForkThread(function()
                -- Native lobby creation has not finished during __post_init.
                WaitSeconds(0.1)
                while not IsDestroyed(self) do
                    -- This file is created before FA starts, and contains only
                    -- an integer written by the client after a server decision.
                    local state = {}
                    local ok = pcall(doscript, self.ControlPrefix .. 'state.lua', state)
                    local spot = ok and tonumber(state.declinedSpot)
                    if spot and self.PlayerOptions[spot] then
                        local options = self.PlayerOptions[spot]
                        self.ReturnDeclined = true
                        LOG('[GAF-AUTOLOBBY] return declined, spot=', spot)
                        options.ReturnDeclined = true
                        interface:UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)
                        interface:StartConnectionCountdown(5)
                        return
                    end
                    WaitSeconds(0.5)
                end
            end))
        end
    end,

    --- Creates a table that represents the local player settings. This represents the initial player. It can be edited by the host accordingly.
    ---@param self UIAutolobbyCommunications
    ---@return UIAutolobbyPlayer
    CreateLocalPlayer = function(self)
        ---@type UIAutolobbyPlayer
        local info = {}

        info.Human = true
        info.Civilian = false

        -- determine player name
        info.PlayerName = self.LocalPlayerName or self:GetLocalPlayerName() or "player"

        -- retrieve faction
        info.Faction = 1
        local factionData = import("/lua/factions.lua")
        if HasCommandLineArg("/random") then
            -- Resolve random as soon as this FA process joins the autolobby.
            -- The host then broadcasts the concrete faction to every peer, so
            -- the versus screen and the eventual game configuration agree.
            info.Faction = Random(1, table.getn(factionData.Factions))
        else
            for index, tbl in factionData.Factions do
                if HasCommandLineArg("/" .. tbl.Key) then
                    info.Faction = index
                    break
                end
            end
        end

        -- retrieve team and start spot
        info.Team = self:GetCommandLineArgumentNumber("/team", -1)
        info.StartSpot = self:GetCommandLineArgumentNumber("/startspot", -1)

        local rawColorArgs = GetCommandLineArg("/color", 1)
        local colorArg = self:GetCommandLineArgumentNumber("/color", 0)
        LOG("[GAF-COLOR] CreateLocalPlayer: raw /color args=", repr(rawColorArgs),
            " parsed colorArg=", tostring(colorArg), " startspot=", tostring(info.StartSpot))
        if colorArg and colorArg > 0 then
            info.PlayerColor = colorArg
            info.ArmyColor = colorArg
            LOG("[GAF-COLOR] using player-chosen color index=", colorArg)
        else
            info.PlayerColor = GameColors.MapToWarmCold(info.StartSpot)
            info.ArmyColor = GameColors.MapToWarmCold(info.StartSpot)
            LOG("[GAF-COLOR] /color absent or <=0 — FALLBACK to MapToWarmCold(startspot)=",
                tostring(info.PlayerColor))
        end

        -- retrieve rating
        info.DEV = self:GetCommandLineArgumentNumber("/deviation", 500)
        info.MEAN = self:GetCommandLineArgumentNumber("/mean", 1500)
        info.NG = self:GetCommandLineArgumentNumber("/numgames", 0)
        info.DIV = self:GetCommandLineArgumentString("/division", "")
        info.SUBDIV = self:GetCommandLineArgumentString("/subdivision", "")
        info.PL = math.floor(info.MEAN - 3 * info.DEV)
        -- For new / low-games players force a minimal visible rating in lobby
        if type(info.NG) == 'number' and info.NG < NEW_PLAYER_GAMES_THRESHOLD then
            info.PL = NEW_PLAYER_DISPLAY_RATING
        end
        info.PlayerClan = self:GetCommandLineArgumentString("/clan", "")
        if self.IsGafAutohost then
            local avatar = self:GetCommandLineArgumentString("/avatarurl", "")
            info.Avatar = avatar != "" and avatar or false
            local expected = self.PlayerOptions[info.StartSpot]
            if expected and expected.Avatar and (not info.Avatar or info.Avatar == 'none.png') then
                info.Avatar = expected.Avatar
            end
        end

        -- Preserve the role in the synchronized launch configuration. The SIM
        -- uses this immutable match-start snapshot as a second authorization
        -- barrier for privileged callbacks.
        local groupRole = self:GetCommandLineArgumentString("/group", "")
        if groupRole != "" then
            info.GroupRole = string.lower(groupRole)
        else
            info.GroupRole = false
        end

        return info
    end,

    --- Creates a table that represents the local game options.
    ---@param self UIAutolobbyCommunications
    ---@return UILobbyLaunchGameOptionsConfiguration
    CreateLocalGameOptions = function(self)
        ---@type UILobbyLaunchGameOptionsConfiguration
        local options = {
            Score = 'no',
            TeamSpawn = 'balanced_reveal_mirrored',
            AutoTeams = 'none',
            CommonArmy = 'UnionWhenDisconnected',
            Victory = 'demoralization',
            Timeouts = '3',
            CheatsEnabled = 'false',
            CivilianAlliance = 'enemy',
            RevealCivilians = 'Yes',
            GameSpeed = 'normal',
            FogOfWar = 'explored',
            UnitCap = '1500',
            PrebuiltUnits = 'Off',
            Share = 'FullShare',
            ShareUnitCap = 'allies',
            DisconnectionDelay02 = '90',
            DisconnectShare = 'SameAsShare',
            DisconnectShareCommanders = 'Explode',
            TeamShareOverflow = "enabled",

            -- yep, great
            Ranked = true,
            Unranked = 'No',
        }

        -- process game options from the command line
        for name, value in self:GetCommandLineArgumentArray("/gameoptions") do
            if name and value then
                options[name] = value
            else
                LOG("Malformed gameoption. ignoring name: " .. repr(name) .. " and value: " .. repr(value))
            end
        end

        return options
    end,

    --- Builds temporary rows for every player selected by the server. A real
    --- AddPlayer message replaces the row in the same start spot as soon as
    --- that peer connects. The metadata is removed from GameOptions so it is
    --- never copied into the final simulation configuration.
    ---@param self UIAutolobbyCommunications
    ---@param gameOptions UILobbyLaunchGameOptionsConfiguration
    ---@return UIAutolobbyPlayer[]
    CreateExpectedPlayers = function(self, gameOptions)
        local players = {}

        for spot = 1, self.PlayerCount do
            local playerKey = "GAFExpectedPlayer" .. spot
            local factionKey = "GAFExpectedFaction" .. spot
            local teamKey = "GAFExpectedTeam" .. spot
            local colorKey = "GAFExpectedColor" .. spot
            local avatarKey = "GAFExpectedAvatar" .. spot
            local playerName = gameOptions[playerKey]

            if playerName and playerName ~= "" then
                LOG("[GAF-AUTOLOBBY-ROSTER] spot=", tostring(spot),
                    " encoded=", tostring(playerName))
                playerName = DecodeExpectedPlayerName(playerName)
                LOG("[GAF-AUTOLOBBY-ROSTER] spot=", tostring(spot),
                    " decoded=", tostring(playerName))
                local color = tonumber(gameOptions[colorKey]) or spot
                players[spot] = {
                    Human = true,
                    Civilian = false,
                    PlayerName = playerName,
                    Faction = tonumber(gameOptions[factionKey]) or 1,
                    Team = tonumber(gameOptions[teamKey]) or 1,
                    StartSpot = spot,
                    PlayerColor = color,
                    ArmyColor = color,
                    Avatar = gameOptions[avatarKey] or false,
                    Expected = true,
                }
            end

            gameOptions[playerKey] = nil
            gameOptions[factionKey] = nil
            gameOptions[teamKey] = nil
            gameOptions[colorKey] = nil
            gameOptions[avatarKey] = nil
        end

        return players
    end,

    ---------------------------------------------------------------------------
    --#region Utilities

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@param connectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>
    ---@return UIAutolobbyConnections
    CreateConnectionsMatrix = function(self, playerOptions, connectionMatrix)
        ---@type UIAutolobbyConnections
        local connections = {}

        -- initial setup
        for y = 1, self.PlayerCount do
            connections[y] = {}
            for x = 1, self.PlayerCount do
                connections[y][x] = false
            end
        end

        -- populate the matrix
        for peerId, establishedPeers in connectionMatrix do
            for _, peerConnectedToId in establishedPeers do
                local peerIdNumber = self:PeerIdToIndex(playerOptions, peerId)
                local peerConnectedToIdNumber = self:PeerIdToIndex(playerOptions, peerConnectedToId)

                -- connection works both ways
                if peerIdNumber and peerConnectedToIdNumber then
                    if peerIdNumber > self.PlayerCount or peerConnectedToIdNumber > self.PlayerCount then
                        self:DebugWarn("Invalid peer id", peerIdNumber, peerConnectedToIdNumber)
                    else
                        connections[peerIdNumber][peerConnectedToIdNumber] = true
                        connections[peerConnectedToIdNumber][peerIdNumber] = true
                    end
                end
            end
        end

        return connections
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@param statuses table<UILobbyPeerId, UIPeerLaunchStatus>
    ---@return UIAutolobbyStatus
    CreateConnectionStatuses = function(self, playerOptions, statuses)
        local output = {}
        for peerId, launchStatus in statuses do
            local peerIdNumber = self:PeerIdToIndex(playerOptions, peerId)
            if peerIdNumber then
                output[peerIdNumber] = launchStatus
            end
        end

        return output
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerCount number
    ---@param localIndex number
    ---@return boolean[][]
    CreateOwnershipMatrix = function(self, playerCount, localIndex)
        local output = {}
        for y = 1, playerCount do
            output[y] = {}
            for x = 1, playerCount do
                output[y][x] = false
            end
        end

        for k = 1, playerCount do
            output[localIndex][k] = true
            output[k][localIndex] = true
        end
        return output
    end,

    --- Determines the launch status of the local peer.
    ---@param self UIAutolobbyCommunications
    ---@param connectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>
    ---@return UIPeerLaunchStatus
    CreateLaunchStatus = function(self, connectionMatrix)
        -- check number of peers
        local validPeerCount = self.PlayerCount - 1
        if table.getsize(connectionMatrix) < validPeerCount then
            return 'Missing local peers'
        end

        return 'Ready'
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, number>
    CreateRatingsTable = function(self, playerOptions)
        ---@type table<string, number>
        local allRatings = {}

        for slot, options in pairs(playerOptions) do
            if options.Human then
                -- For new / low-games players force a minimal visible rating in lobby
                if type(options.NG) == 'number' and options.NG < NEW_PLAYER_GAMES_THRESHOLD then
                    allRatings[options.PlayerName] = NEW_PLAYER_DISPLAY_RATING
                else
                    allRatings[options.PlayerName] = options.PL or 0
                end
            end
        end

        return allRatings
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, string>
    CreateDivisionsTable = function(self, playerOptions)
        ---@type table<string, string>
        local allDivisions = {}

        for slot, options in pairs(playerOptions) do
            if options.Human then
                if options.DIV ~= "unlisted" then
                    local division = options.DIV
                    if options.SUBDIV and options.SUBDIV ~= "" then
                        division = division .. ' ' .. options.SUBDIV
                    end
                    allDivisions[options.PlayerName] = division
                end
            end
        end

        return allDivisions
    end,

    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, string>
    CreateClanTagsTable = function(self, playerOptions)
        local allClanTags = {}

        for slot, options in pairs(playerOptions) do
            if options.PlayerClan then
                allClanTags[options.PlayerName] = options.PlayerClan
            end
        end

        return allClanTags
    end,

    --- Creates the immutable SIM-side allowlist for the privileged AiBot
    --- callback. Player names are unique in the launch configuration.
    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, boolean>
    CreateAiBotAdminPlayersTable = function(self, playerOptions)
        local adminPlayers = {}

        for _, options in pairs(playerOptions) do
            if options.Human
                and type(options.GroupRole) == 'string'
                and string.lower(options.GroupRole) == 'admin'
            then
                adminPlayers[options.PlayerName] = true
            end
        end

        return adminPlayers
    end,

    --- Verifies whether we can launch the game.
    ---@param self UIAutolobbyCommunications
    ---@param peerStatus UIAutolobbyStatus
    ---@return boolean
    CanLaunch = function(self, peerStatus)
        if self.ReturnDeclined then
            return false
        end
        -- Placeholder rows make the complete roster visible, but they must
        -- never be mistaken for peers that actually connected.
        local connectedPlayerCount = 0
        for _, playerOptions in pairs(self.PlayerOptions) do
            if type(playerOptions.OwnerID) == 'string' then
                connectedPlayerCount = connectedPlayerCount + 1
            end
        end
        if connectedPlayerCount ~= self.PlayerCount then
            return false
        end

        -- check if we know of all peers
        if table.getsize(peerStatus) ~= self.PlayerCount then
            return false
        end

        -- check if all peers are ready for launch
        for k, launchStatus in peerStatus do
            if launchStatus ~= 'Ready' then
                return false
            end
        end

        return true
    end,

    --- Maps a peer id to an index that can be used in the interface. In
    --- practice the peer id can be all over the place, ranging from -1
    --- to numbers such as 35240. With this function we map it to a sane
    --- index that we can use in the interface.
    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@param peerId UILobbyPeerId
    ---@return number | false
    PeerIdToIndex = function(self, playerOptions, peerId)
        if type(peerId) ~= 'string' then
            self:DebugWarn("Invalid peer id", peerId)
            return false
        end

        -- try to find matching player options
        if playerOptions then
            for k, options in playerOptions do
                if options.OwnerID == peerId then
                    if options.StartSpot then
                        return options.StartSpot
                    end
                end
            end
        end

        return false
    end,

    --- Prefetches a scenario to try and reduce the loading screen time.
    ---@param self UIAutolobbyCommunications
    ---@param gameOptions UILobbyLaunchGameOptionsConfiguration
    ---@param gameMods UILobbyLaunchGameModsConfiguration[]
    Prefetch = function(self, gameOptions, gameMods)
        local scenarioPath = gameOptions.ScenarioFile
        if not scenarioPath then
            return
        end

        local scenarioFile = MapUtil.LoadScenario(gameOptions.ScenarioFile)
        if not scenarioFile then
            -- ???
            return
        end

        PrefetchSession(scenarioFile.map, gameMods, true)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param lobbyParameters UIAutolobbyParameters
    ---@param joinParameters UIAutolobbyJoinParameters
    Rejoin = function(self, lobbyParameters, joinParameters)
        if self.RejoinPending or self.ReturnDeclined then
            return
        end
        self.RejoinPending = true
        local deadline = self.ConnectionDeadlineSeconds
        local autolobbyModule = import("/lua/ui/lobby/autolobby.lua")

        -- start disposing threads to prevent race conditions
        self.Trash:Destroy()

        ForkThread(
            function()
                self:SendLaunchStatusToServer('Rejoining')

                -- prevent race condition on network
                WaitSeconds(1.0)

                -- inform peers and server that we're rejoining
                self:BroadcastData({ Type = "UpdateLaunchStatus", LaunchStatus = 'Rejoining' })

                -- prevent race condition on network
                WaitSeconds(1.0)

                -- create a new lobby
                self:Destroy()

                -- prevent race conditions
                WaitSeconds(1.0)
                local newLobby
                for attempt = 1, 5 do
                    newLobby = autolobbyModule.CreateLobby(
                        lobbyParameters.Protocol,
                        lobbyParameters.LocalPort,
                        lobbyParameters.DesiredPlayerName,
                        lobbyParameters.LocalPlayerPeerId,
                        lobbyParameters.NatTraversalProvider
                    )
                    if newLobby then
                        break
                    end
                    WaitSeconds(1)
                end
                if not newLobby then
                    return
                end
                if deadline then
                    newLobby.ConnectionDeadlineSeconds = deadline
                    import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                        :StartConnectionCountdown(math.max(0.001, deadline - GetSystemTimeSeconds()))
                end

                -- wait a bit before we join
                WaitSeconds(1.0)

                autolobbyModule.JoinGame(joinParameters.Address, joinParameters.AsObserver,
                    joinParameters.DesiredPlayerName,
                    joinParameters.DesiredPeerId)
            end
        )
    end,

    ---------------------------------------------------------------------------
    --#region Threads

    ---@param self UIAutolobbyCommunications
    CheckForRejoinThread = function(self)

        local rejoinThreshold = 3
        local rejoinCount = 0

        while not IsDestroyed(self) do

            -- check if we're ready to launch
            if self.LaunchStatutes[self.LocalPeerId] ~= 'Ready' then

                -- if we're not, check the status of peers
                local onePeerIsRejoining = false
                local onePeerIsReady = false
                for k, launchStatus in self.LaunchStatutes do
                    onePeerIsReady = onePeerIsReady or (launchStatus == 'Ready')
                    onePeerIsRejoining = onePeerIsRejoining or (launchStatus == 'Rejoining')
                end

                if onePeerIsReady then
                    rejoinCount = rejoinCount + 1
                end

                -- try to not rejoin at the same time
                if onePeerIsRejoining then
                    rejoinCount = 0
                end
            else
                rejoinCount = 0
            end

            -- if we reached the threshold, time to rejoin!
            if rejoinCount > rejoinThreshold then
                self:Rejoin(self.LobbyParameters, self.JoinParameters)
            end

            WaitSeconds(1.0 + 1 * Random())
        end
    end,

    --- Passes the local launch status to all peers.
    ---@param self UIAutolobbyCommunications
    ShareLaunchStatusThread = function(self)
        while not IsDestroyed(self) do
            local launchStatus = self:CreateLaunchStatus(self.ConnectionMatrix)
            self.LaunchStatutes[self.LocalPeerId] = launchStatus

            -- update peers
            self:BroadcastData({ Type = "UpdateLaunchStatus", LaunchStatus = launchStatus })

            -- update server
            self:SendLaunchStatusToServer(launchStatus)

            -- update UI for launch statuses
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateLaunchStatuses(self:CreateConnectionStatuses(self.PlayerOptions, self.LaunchStatutes))

            WaitSeconds(2.0)
        end
    end,

    ---@param self UIAutolobbyCommunications
    LaunchThread = function(self)
        while not IsDestroyed(self) do
            if self:CanLaunch(self.LaunchStatutes) then

                WaitSeconds(5.0)
                if (not IsDestroyed(self)) and self:CanLaunch(self.LaunchStatutes) then

                    -- Army numbers need to be calculated: they are numbered incrementally in slot order.
                    local slots = {}
                    for slotIndex, _ in pairs(self.PlayerOptions) do
                        table.insert(slots, slotIndex)
                    end
                    table.sort(slots)

                    -- send player options to the server
                    for armyIndex, slotIndex in ipairs(slots) do
                        local playerOptions = self.PlayerOptions[slotIndex]
                        local ownerId = playerOptions.OwnerID
                        self:SendPlayerOptionToServer(ownerId, 'Team', playerOptions.Team)
                        self:SendPlayerOptionToServer(ownerId, 'Army', armyIndex)
                        self:SendPlayerOptionToServer(ownerId, 'StartSpot', playerOptions.StartSpot)
                        self:SendPlayerOptionToServer(ownerId, 'Faction', playerOptions.Faction)
                        LOG("[GAF-COLOR] LaunchThread slot=", slotIndex, " army=", armyIndex,
                            " name=", tostring(playerOptions.PlayerName),
                            " PlayerColor=", tostring(playerOptions.PlayerColor),
                            " ArmyColor=", tostring(playerOptions.ArmyColor),
                            " StartSpot=", tostring(playerOptions.StartSpot),
                            " Team=", tostring(playerOptions.Team))
                    end

                    -- tuck them into the game options. By all means a hack, but
                    -- this way they are available in both the sim and the UI
                    self.GameOptions.Ratings = self:CreateRatingsTable(self.PlayerOptions)
                    self.GameOptions.Divisions = self:CreateDivisionsTable(self.PlayerOptions)
                    self.GameOptions.ClanTags = self:CreateClanTagsTable(self.PlayerOptions)
                    self.GameOptions.AiBotAdminPlayers = self:CreateAiBotAdminPlayersTable(self.PlayerOptions)

                    -- create game configuration
                    local gameConfiguration = {
                        GameMods = self.GameMods,
                        GameOptions = self.GameOptions,
                        PlayerOptions = self.PlayerOptions,
                        Observers = {},
                    }

                    -- send it to all players and tell them to launch with the configuration
                    self:BroadcastData({ Type = "Launch", GameConfig = gameConfiguration })
                    self:LaunchGame(gameConfiguration)
                end
            end

            WaitSeconds(1.0)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Message Handlers
    --
    -- All the message functions in this section run asynchroniously on each
    -- client. They are responsible for processing the data received from
    -- other peers. Validation is done in `AutolobbyMessages` before the message
    -- processed.

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyAddPlayerMessage
    ProcessAddPlayerMessage = function(self, data)
        ---@type UIAutolobbyPlayer
        local playerOptions = data.PlayerOptions

        LOG("[GAF-COLOR] ProcessAddPlayerMessage: sender=", tostring(data.SenderID),
            " name=", tostring(playerOptions.PlayerName),
            " Faction=", tostring(playerOptions.Faction),
            " Avatar=", tostring(playerOptions.Avatar),
            " PlayerColor=", tostring(playerOptions.PlayerColor),
            " ArmyColor=", tostring(playerOptions.ArmyColor),
            " StartSpot=", tostring(playerOptions.StartSpot))

        -- override some data
        playerOptions.OwnerID = data.SenderID
        playerOptions.PlayerName = self:MakeValidPlayerName(playerOptions.OwnerID, playerOptions.PlayerName)

        local expected = self.PlayerOptions[playerOptions.StartSpot]
        if self.IsGafAutohost and expected and expected.Avatar and
            (not playerOptions.Avatar or playerOptions.Avatar == 'none.png') then
            playerOptions.Avatar = expected.Avatar
        end

        -- TODO: verify that the StartSpot is not occupied
        -- put the player where it belongs
        self.PlayerOptions[playerOptions.StartSpot] = playerOptions

        -- sync game options with the connected peer
        self:SendData(data.SenderID, { Type = "UpdateGameOptions", GameOptions = self.GameOptions })

        -- sync player options to all connected peers
        self:BroadcastData({ Type = "UpdatePlayerOptions", PlayerOptions = self.PlayerOptions })

        -- update UI for player options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)

        local localIndex = self:PeerIdToIndex(self.PlayerOptions, self.LocalPeerId)
        if localIndex then
            local ownershipMatrix = self:CreateOwnershipMatrix(self.PlayerCount, localIndex)
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateOwnership(ownershipMatrix)
        end
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdatePlayerOptionsMessage
    ProcessUpdatePlayerOptionsMessage = function(self, data)
        self.PlayerOptions = data.PlayerOptions

        for slotIndex, opts in pairs(self.PlayerOptions) do
            LOG("[GAF-COLOR] ProcessUpdatePlayerOptions: slot=", tostring(slotIndex),
                " name=", tostring(opts.PlayerName),
                " Faction=", tostring(opts.Faction),
                " Avatar=", tostring(opts.Avatar),
                " PlayerColor=", tostring(opts.PlayerColor),
                " ArmyColor=", tostring(opts.ArmyColor),
                " StartSpot=", tostring(opts.StartSpot))
        end

        -- update UI for player options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)

        local localIndex = self:PeerIdToIndex(self.PlayerOptions, self.LocalPeerId)
        if localIndex then
            local ownershipMatrix = self:CreateOwnershipMatrix(self.PlayerCount, localIndex)
            -- update UI for player options
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateOwnership(ownershipMatrix)
        end
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdateGameOptionsMessage
    ProcessUpdateGameOptionsMessage = function(self, data)
        self.GameOptions = data.GameOptions

        self:Prefetch(self.GameOptions, self.GameMods)

        -- update UI for game options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyLaunchMessage
    ProcessLaunchMessage = function(self, data)
        self:LaunchGame(data.GameConfig)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param data UIAutolobbyUpdateLaunchStatusMessage
    ProcessUpdateLaunchStatusMessage = function(self, data)
        self.LaunchStatutes[data.SenderID] = data.LaunchStatus

        -- update UI for launch statuses
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateLaunchStatuses(self:CreateConnectionStatuses(self.PlayerOptions, self.LaunchStatutes))
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Engine interface

    --- Broadcasts data to all (connected) peers.
    ---@param self UIAutolobbyCommunications
    ---@param data UILobbyData
    BroadcastData = function(self, data)
        self:DebugSpew("BroadcastData", data.Type)

        -- validate message type
        local message = AutolobbyMessages[data.Type]
        if not message then
            self:DebugWarn("Blocked broadcasting unknown message type", data.Type)
            return
        end

        -- validate message format
        if not message.Validate(self, data) then
            self:DebugWarn("Blocked broadcasting malformed message of type", data.Type)
            return
        end

        return MohoLobbyMethods.BroadcastData(self, data)
    end,

    --- (Re)Connects to a peer.
    ---@param self any
    ---@param address any
    ---@param name any
    ---@param peerId UILobbyPeerId
    ---@return nil
    ConnectToPeer = function(self, address, name, peerId)
        self:DebugSpew("ConnectToPeer", address, name, peerId)
        return MohoLobbyMethods.ConnectToPeer(self, address, name, peerId)
    end,

    --- ???
    ---@param self UIAutolobbyCommunications
    ---@return nil
    DebugDump = function(self)
        self:DebugSpew("DebugDump")
        return MohoLobbyMethods.DebugDump(self)
    end,

    --- Destroys the C-object and all the (UI) entities in the trash bag.
    ---@param self UIAutolobbyCommunications
    ---@return nil
    Destroy = function(self)
        self:DebugSpew("Destroy")

        self.Trash:Destroy()
        return MohoLobbyMethods.Destroy(self)
    end,

    --- Disconnects from a peer.
    --- See also `ConnectToPeer` to connect
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@return nil
    DisconnectFromPeer = function(self, peerId)
        self:DebugSpew("DisconnectFromPeer", peerId)

        return MohoLobbyMethods.DisconnectFromPeer(self, peerId)
    end,

    --- Ejects a peer from the lobby.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param reason string
    ---@return nil
    EjectPeer = function(self, peerId, reason)
        self:DebugSpew("EjectPeer", peerId, reason)
        return MohoLobbyMethods.EjectPeer(self, peerId, reason)
    end,

    --- Retrieves the local identifier.
    ---@param self UIAutolobbyCommunications
    ---@return UILobbyPeerId
    GetLocalPlayerID = function(self)
        self:DebugSpew("GetLocalPlayerID")
        return MohoLobbyMethods.GetLocalPlayerID(self)
    end,

    --- Retrieves the local name. Note that this name can be overwritten by the host via `MakeValidPlayerName`
    ---@param self UIAutolobbyCommunications
    ---@return string
    GetLocalPlayerName = function(self)
        self:DebugSpew("GetLocalPlayerName")
        return MohoLobbyMethods.GetLocalPlayerName(self)
    end,

    --- Retrieves the local port.
    ---@param self any
    ---@return number|nil
    GetLocalPort = function(self)
        self:DebugSpew("GetLocalPort")
        return MohoLobbyMethods.GetLocalPort(self)
    end,

    --- Retrieves information about a peer. See `GetPeers` to get the same information for all connected peers.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@return Peer
    GetPeer = function(self, peerId)
        self:DebugSpew("GetPeer", peerId)
        return MohoLobbyMethods.GetPeer(self, peerId)
    end,

    --- Retrieves information about all connected peers. See `GetPeer` to get information for a specific peer.
    ---@param self UIAutolobbyCommunications
    GetPeers = function(self)
        -- self:DebugSpew("GetPeers")
        return MohoLobbyMethods.GetPeers(self)
    end,

    --- Transforms the lobby to be discoveryable and joinable for other players.
    ---@param self UIAutolobbyCommunications
    ---@return nil
    HostGame = function(self)
        self:DebugSpew("HostGame")
        return MohoLobbyMethods.HostGame(self)
    end,

    --- Retrieves whether the local client is the host.
    ---@param self any
    ---@return boolean
    IsHost = function(self)
        self:DebugSpew("IsHost")
        return MohoLobbyMethods.IsHost(self)
    end,

    --- Join a lobby that is set to be a host.
    ---@param self UIAutolobbyCommunications
    ---@param address GPGNetAddress
    ---@param remotePlayerName string
    ---@param remotePlayerPeerId UILobbyPeerId
    ---@return nil
    JoinGame = function(self, address, remotePlayerName, remotePlayerPeerId)
        self:DebugSpew("JoinGame", address, remotePlayerName, remotePlayerPeerId)
        return MohoLobbyMethods.JoinGame(self, address, remotePlayerName, remotePlayerPeerId)
    end,

    --- Launches the game for the local client. The game configuration that is passed in should originate from the host.
    ---@param self UIAutolobbyCommunications
    ---@param gameConfig UILobbyLaunchConfiguration
    ---@return nil
    LaunchGame = function(self, gameConfig)
        self:DebugSpew("LaunchGame")
        self:DebugSpew(reprs(gameConfig, { depth = 10 }))

        return MohoLobbyMethods.LaunchGame(self, gameConfig)
    end,

    --- Returns a valid game name.
    ---@param self UIAutolobbyCommunications
    ---@param name string
    ---@return string
    MakeValidGameName = function(self, name)

        self:DebugSpew("MakeValidGameName", name)
        return MohoLobbyMethods.MakeValidGameName(self, name)
    end,

    --- Returns a valid player name.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param name string
    ---@return string
    MakeValidPlayerName = function(self, peerId, name)
        self:DebugSpew("MakeValidPlayerName", peerId, name)
        return MohoLobbyMethods.MakeValidPlayerName(self, peerId, name)
    end,

    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param data UILobbyData
    ---@return nil
    SendData = function(self, peerId, data)
        self:DebugSpew("SendData", peerId, data.Type)

        -- validate message type
        local message = AutolobbyMessages[data.Type]
        if not message then
            self:DebugWarn("Blocked sending unknown message type", data.Type, "to", peerId)
            return
        end

        -- validate message type
        if not message.Validate(self, data) then
            self:DebugWarn("Blocked sending malformed message of type", data.Type, "to", peerId)
            return
        end

        return MohoLobbyMethods.SendData(self, peerId, data)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Connection events

    --- Called by the engine as we're trying to host a lobby.
    ---@param self UIAutolobbyCommunications
    Hosting = function(self)
        self:DebugSpew("Hosting")

        self.LocalPeerId = self:GetLocalPlayerID()
        self.LocalPlayerName = self:GetLocalPlayerName()
        self.HostID = self:GetLocalPlayerID()

        -- give ourself a seat at the table
        local hostPlayerOptions = self:CreateLocalPlayer()
        hostPlayerOptions.OwnerID = self.LocalPeerId
        hostPlayerOptions.PlayerName = self:MakeValidPlayerName(self.LocalPeerId, self.LocalPlayerName)
        self.PlayerOptions[hostPlayerOptions.StartSpot] = hostPlayerOptions

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.ShareLaunchStatusThread, self))
        self.Trash:Add(ForkThread(self.LaunchThread, self))

        -- start prefetching the scenario
        self:Prefetch(self.GameOptions, self.GameMods)

        self:SendLaunchStatusToServer('Hosting')

        -- update UI for game options
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)
    end,

    --- Called by the engine as we're trying to join a lobby.
    ---@param self UIAutolobbyCommunications
    Connecting = function(self)
        self:DebugSpew("Connecting")
        self:SendLaunchStatusToServer('Connecting')
    end,

    --- Called by the engine when the connection fails.
    ---@param self UIAutolobbyCommunications
    ---@param reason string     # reason for connection failure, populated by the engine
    ConnectionFailed = function(self, reason)
        self:DebugSpew("ConnectionFailed", reason)

        -- try to rejoin
        self:Rejoin(self.LobbyParameters, self.JoinParameters)
    end,

    --- Called by the engine when the connection succeeds with the host.
    ---@param self UIAutolobbyCommunications
    ---@param localPeerId UILobbyPeerId
    ---@param hostPeerId string
    ConnectionToHostEstablished = function(self, localPeerId, newLocalName, hostPeerId)
        self:DebugSpew("ConnectionToHostEstablished", localPeerId, newLocalName, hostPeerId)
        self.LocalPlayerName = newLocalName
        self.LocalPeerId = localPeerId
        self.HostID = hostPeerId

        -- occasionally send data over the network to create pings on screen
        self.Trash:Add(ForkThread(self.ShareLaunchStatusThread, self))
        -- self.Trash:Add(ForkThread(self.CheckForRejoinThread, self)) -- disabled, for now

        self:SendData(self.HostID, { Type = "AddPlayer", PlayerOptions = self:CreateLocalPlayer() })
    end,

    --- Called by the engine when a peer establishes a connection.
    ---@param self UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param peerConnectedTo UILobbyPeerId[]    # all established conenctions for the given player
    EstablishedPeers = function(self, peerId, peerConnectedTo)
        self:DebugSpew("EstablishedPeers", peerId, reprs(peerConnectedTo))

        -- update server
        self:SendEstablishedPeer(peerId)

        self.LaunchStatutes[peerId] = self.LaunchStatutes[peerId] or 'Unknown'
        -- update UI for launch statuses
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateLaunchStatuses(self:CreateConnectionStatuses(self.PlayerOptions, self.LaunchStatutes))

        -- update the matrix and the UI
        self.ConnectionMatrix[peerId] = peerConnectedTo
        local connections = self:CreateConnectionsMatrix(self.PlayerOptions, self.ConnectionMatrix)
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
            :UpdateConnections(connections)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Lobby events

    --- Called by the engine when you are ejected from a lobby.
    ---@param self UIAutolobbyCommunications
    ---@param reason string     # reason for disconnection, populated by the host
    Ejected = function(self, reason)
        self:DebugSpew("Ejected", reason)
        self:SendLaunchStatusToServer('Ejected')
    end,

    --- ???
    ---@param self UIAutolobbyCommunications
    ---@param text string
    SystemMessage = function(self, text)
        self:DebugSpew("SystemMessage", text)
    end,

    --- Called by the engine when we receive data from other players. There is no checking to see if the data is legitimate, these need to be done in Lua.
    ---
    --- Data can be send via `BroadcastData` and/or `SendData`.
    ---@param self UIAutolobbyCommunications
    ---@param data UILobbyReceivedMessage
    DataReceived = function(self, data)
        -- make it more convenient to debug malicious traffic
        SPEW(string.format("Received data of type %s from %s (%s)", tostring(data.Type), tostring(data.SenderID), tostring(data.SenderName)))

        -- signal UI that we received something
        local peerIndex = self:PeerIdToIndex(self.PlayerOptions, data.SenderID)
        if peerIndex then
            import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
                :UpdateIsAliveStamp(peerIndex)
        end

        -- validate message type
        local message = AutolobbyMessages[data.Type]
        if not message then
            self:DebugWarn("Ignoring unknown message type", data.Type, "from", data.SenderID)
            return
        end

        -- validate message data
        if not message.Validate(self, data) then
            self:DebugWarn("Ignoring malformed message of type", data.Type, "from", data.SenderID)
            return
        end

        -- validate message source
        if not message.Accept(self, data) then
            self:DebugWarn("Message rejected: ", data.Type)
            return
        end

        -- handle the message
        message.Handler(self, data)
    end,

    --- Called by the engine when the game configuration is requested by the discovery service.
    ---@param self UIAutolobbyCommunications
    GameConfigRequested = function(self)
        self:DebugSpew("GameConfigRequested")
    end,

    --- Called by the engine when a peer disconnects.
    ---@param self UIAutolobbyCommunications
    ---@param peerName string
    ---@param peerId UILobbyPeerId
    PeerDisconnected = function(self, peerName, peerId)
        self:DebugSpew("PeerDisconnected", peerName, peerId)
        self:SendDisconnectedPeer(peerId)

        if not self.IsGafAutohost then
            return
        end

        -- Keep the server-selected roster row so a failed player remains
        -- identifiable and can rejoin, but clear all peer-owned state. Without
        -- this, the last received Ready value remained visible indefinitely.
        local disconnectedSpot = self:PeerIdToIndex(self.PlayerOptions, peerId)
        self.LaunchStatutes[peerId] = nil
        self.ConnectionMatrix[peerId] = nil

        if disconnectedSpot and self.PlayerOptions[disconnectedSpot] then
            local playerOptions = self.PlayerOptions[disconnectedSpot]
            playerOptions.OwnerID = nil
            playerOptions.Expected = true
        end

        local interface = import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton()
        interface:UpdateScenario(self.GameOptions.ScenarioFile, self.PlayerOptions)
        interface:UpdateLaunchStatuses(
            self:CreateConnectionStatuses(self.PlayerOptions, self.LaunchStatutes)
        )

        if self:IsHost() then
            self:BroadcastData({ Type = "UpdatePlayerOptions", PlayerOptions = self.PlayerOptions })
        end
    end,

    --- Called by the engine when the game is launched.
    ---@param self UIAutolobbyCommunications
    GameLaunched = function(self)
        self:DebugSpew("GameLaunched")

        -- clear out the interface
        import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").GetSingleton():Destroy()

        -- destroy ourselves, the game takes over the management of peers
        self:Destroy()

        self:SendGameStateToServer('Launching')
    end,

    --- Called by the engine when the launch failed.
    ---@param self UIAutolobbyCommunications
    ---@param reasonKey string
    LaunchFailed = function(self, reasonKey)
        self:DebugSpew("LaunchFailed", LOC(reasonKey))
        self:SendLaunchStatusToServer('Failed')
    end,

    --#endregion

    --#region Debugging

    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugSpew = function(self, ...)
        if not self.EnabledSpewing then
            return
        end

        SPEW("Autolobby communications", unpack(arg))
    end,


    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugLog = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        LOG("Autolobby communications", unpack(arg))
    end,

    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugWarn = function(self, ...)
        if not self.EnabledWarnings then
            return
        end

        WARN("Autolobby communications", unpack(arg))
    end,

    ---@param self UIAutolobbyCommunications
    ---@param ... any
    DebugError = function(self, ...)
        if not self.EnabledErrors then
            return
        end

        local message = "Autolobby communications"
        for _, arg in ipairs(arg) do
            message = message .. "\t" .. tostring(arg)
        end

        error(message)
    end,

    --#endregion
}
