local UIUtil = import('/lua/ui/uiutil.lua')
local BaseLayout = import('/lua/maui/layouthelpers.lua')
local LayoutHelpers = import('/lua/gapengine/ui/controls/panel_layout.lua').LayoutFor('lag')
local Group = import('/lua/maui/group.lua').Group
local Prefs = import('/lua/user/prefs.lua')
local Logic = import('/lua/gapengine/ui/game/lag_warning_model.lua')
local GamePanel = import('/lua/gapengine/ui/controls/game_panel.lua')
local russian = string.lower(__language or '') == 'ru'
local monitor = false

local function DisplayName(client)
    local nameMode = Prefs.GetFromCurrentProfile('options.options_show_player_names') or 'on'
    local hideName = nameMode == 'off' and not client['local']
    if nameMode == 'allies-only' and not client['local'] and GetFocusArmy() > 0 then
        hideName = true
        for _, army in client.armies or {} do
            if not IsEnemy(army, GetFocusArmy()) then hideName = false; break end
        end
    end
    local fallback = (russian and 'Игрок ' or 'Player ') .. tostring(client.index)
    local name = hideName and fallback or (client.name or fallback)
    if client['local'] then name = name .. (russian and ' (вы)' or ' (you)') end
    return name
end

local function AlertText(alert)
    local reason
    if alert.reason == 'data' then
        reason = russian and 'ожидаем данные' or 'waiting for data'
    elseif alert.reason == 'ack' then
        reason = russian and 'ожидаем подтверждения' or 'waiting for acknowledgements'
    else
        reason = (russian and 'скорость симуляции ' or 'simulation speed ') .. tostring(alert.client.maxSpeed)
    end
    return DisplayName(alert.client) .. ' — ' .. reason .. string.format('   Data: %.0f   Behind: %.0f',
        alert.client.data or 0, alert.client.behind or 0)
end

function Destroy()
    if monitor then
        local old = monitor
        monitor = false
        old:Destroy()
    end
end

function Create(parent)
    if monitor then return monitor end
    if not rawget(_G, 'GetSessionNetworkStats') then return false end
    local control = Group(parent, 'GapNetworkWarnings')
    monitor = control
    control.Width:Set(1)
    control.Height:Set(1)
    control:DisableHitTest()
    control.logic = Logic.New()
    control.nextPoll = 0
    control.lines = {}
    local panel = Group(GetFrame(0), 'GapNetworkWarningPanel')
    panel.gapScaleKey = 'lag'
    control.panel = panel
    panel.OnDestroy = function() control.panel = false end
    local function RightLimit()
        local frame = GetFrame(0)
        local score = import('/lua/ui/game/score.lua').controls
        local board = score and score.bg
        if board and not board:IsHidden() and board.Left() > frame.Left() + LayoutHelpers.ScaleNumber(300) then
            return math.min(frame.Right() - 16, board.Left() - 16)
        end
        return frame.Right() - 16
    end
    local lastWidth
    local function DefaultPosition()
        local frame = GetFrame(0)
        return math.max(frame.Left() + 16, math.min(frame.Left() + (frame.Width() - panel.Width()) / 2, RightLimit() - panel.Width())),
            frame.Top() + BaseLayout.ScaleNumber(64)
    end
    local function PlacePanel()
        local frame = GetFrame(0)
        local right = RightLimit()
        local width = math.min(LayoutHelpers.ScaleNumber(620), right - frame.Left() - 32)
        if lastWidth ~= width then panel.Width:Set(width); lastWidth = width end
        if panel.gapLayout then panel.gapLayout:Update() end
    end
    PlacePanel()
    LayoutHelpers.SetHeight(panel, 58)
    LayoutHelpers.AtTopIn(panel, GetFrame(0), 64)
    panel.Depth:Set(GetFrame(0):GetTopmostDepth() + 50)
    panel:DisableHitTest()
    GamePanel.Frame(panel)
    local heading = UIUtil.CreateText(panel, russian and 'Задержка игры' or 'Game delay', GamePanel.FontSize('lag', 13), UIUtil.titleFont)
    heading:SetColor(GamePanel.AccentColor())
    heading:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(heading, panel, 12, 6)
    for i = 1, 3 do
        local line = UIUtil.CreateText(panel, '', GamePanel.FontSize('lag', 12), UIUtil.bodyFont)
        local number = i
        line:SetColor(GamePanel.TextColor())
        line:DisableHitTest()
        LayoutHelpers.AtLeftIn(line, panel, 12)
        line.Top:Set(function() return heading.Bottom() + LayoutHelpers.ScaleNumber(3 + (number - 1) * 19) end)
        line:SetClipToWidth(true)
        line.Right:Set(function() return panel.Right() - LayoutHelpers.ScaleNumber(12) end)
        control.lines[i] = line
    end
    panel:Hide()
    control.OnFrame = function(self)
        if not self.panel then self:Destroy(); return end
        local now = GetSystemTimeSeconds()
        if now < self.nextPoll then return end
        self.nextPoll = now + 0.25
        PlacePanel() -- The scoreboard may be created, moved or collapsed later.
        local option = Prefs.GetFromCurrentProfile('options.gap_network_warnings')
        local alerts
        if option == 'off' or option == false or SessionIsGameOver() then
            alerts = self.logic:Reset()
        else
            alerts = self.logic:Update(now, GetSessionNetworkStats())
        end
        local count = math.min(3, table.getn(alerts))
        if count == 0 then panel:Hide(); return end
        local title = russian and 'Задержка игры' or 'Game delay'
        if table.getn(alerts) > 3 then title = title .. string.format(' (+%d)', table.getn(alerts) - 3) end
        if heading:GetText() ~= title then heading:SetText(title) end
        panel.Height:Set(LayoutHelpers.ScaleNumber(29 + count * 19))
        panel.gapLayout:Update()
        for i, line in self.lines do
            if alerts[i] and i <= count then
                local text = AlertText(alerts[i])
                if line:GetText() ~= text then line:SetText(text) end
                line:Show()
            else line:Hide() end
        end
        panel:Show()
    end
    control.OnDestroy = function(self)
        if self.panel then self.panel:Destroy() end
        if monitor == self then monitor = false end
    end
    GamePanel.Attach(panel, 'lag', {defaultPosition = DefaultPosition})
    control:SetNeedsFrameUpdate(true)
    return control
end

function GetMonitor()
    return monitor
end

function RefreshLayout()
    if not monitor then return end
    local parent, logic = monitor:GetParent(), monitor.logic
    Destroy()
    local replacement = Create(parent)
    replacement.logic = logic
end
