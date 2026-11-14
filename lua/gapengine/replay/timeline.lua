local Group = import('/lua/maui/group.lua').Group
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Layout = import('/lua/gapengine/ui/controls/panel_layout.lua').LayoutFor('replay')
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local GamePanel = import('/lua/gapengine/ui/controls/game_panel.lua')
local Hotkeys = import('/lua/gapengine/ui/game/replay_hotkeys.lua')

local russian = string.lower(__language or '') == 'ru'
local words = russian and {
    hint = 'Перетащите ползунок, чтобы выбрать время',
    release = 'Отпустите кнопку для перехода',
    indexing = 'Чтение длительности реплея…',
    unavailable = 'Шкала времени недоступна',
    seeking = 'Переход к %s · %d%%',
    restoring = 'Восстановление %s…',
    paused = 'Пауза', playing = 'Воспроизведение',
    cancel = 'Отмена', pause = 'Пауза', play = 'Продолжить',
    hide = 'Скрыть панель перемотки',
} or {
    hint = 'Drag the timeline to choose a time',
    release = 'Release to seek',
    indexing = 'Reading replay duration…',
    unavailable = 'Timeline unavailable',
    seeking = 'Seeking to %s · %d%%',
    restoring = 'Restoring %s…',
    paused = 'Paused', playing = 'Playing',
    cancel = 'Cancel', pause = 'Pause', play = 'Play',
    hide = 'Hide replay controls',
}

local function Clock(seconds)
    local total = math.max(0, math.floor(seconds or 0))
    if total >= 3600 then
        return string.format('%d:%02d:%02d', math.floor(total / 3600), math.mod(math.floor(total / 60), 60), math.mod(total, 60))
    end
    return string.format('%02d:%02d', math.floor(total / 60), math.mod(total, 60))
end

local function CreateStandalone(parent)
    local panel = Group(parent, 'ReplayTimeline')
    panel.gapScaleKey = 'replay'
    panel.Width:Set(function() return math.min(Layout.ScaleNumber(580), parent.Width() - Layout.ScaleNumber(30)) end)
    Layout.SetHeight(panel, 86)
    Layout.AtHorizontalCenterIn(panel, parent)
    Layout.AtBottomIn(panel, parent, 12)
    panel.Depth:Set(160)

    GamePanel.Frame(panel)

    local time = UIUtil.CreateText(panel, '00:00 / --:--', GamePanel.FontSize('replay', 13), UIUtil.bodyFont)
    Layout.AtLeftTopIn(time, panel, 18, 9)
    time:SetColor(GamePanel.TextColor())
    time:DisableHitTest()

    local status = UIUtil.CreateText(panel, '', GamePanel.FontSize('replay', 11), UIUtil.bodyFont)
    Layout.AtLeftTopIn(status, panel, 180, 11)
    status:SetColor(GamePanel.AccentColor())
    status:DisableHitTest()

    local hint = UIUtil.CreateText(panel, words.indexing, GamePanel.FontSize('replay', 11), UIUtil.bodyFont)
    Layout.AtLeftTopIn(hint, panel, 18, 64)
    hint:SetColor(GamePanel.TextColor())
    hint:DisableHitTest()

    local slider = IntegerSlider(panel, false, 0, 1, 1,
        UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
        UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
        UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
        UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))
    Layout.AtLeftTopIn(slider, panel, 18, 37)
    Layout.AtRightIn(slider, panel, 18)
    slider.Width:Set(function() return slider.Right() - slider.Left() end)
    Layout.SetHeight(slider, 20)
    GamePanel.ScaleSlider(slider, 'replay')
    slider._background.Left:Set(slider.Left)
    slider._background.Right:Set(slider.Right)
    slider._background.Top:Set(slider.Top)
    slider._background.Bottom:Set(slider.Bottom)
    slider._thumb.Depth:Set(function() return panel.Depth() + 5 end)
    slider._background.Depth:Set(function() return panel.Depth() + 2 end)

    local action = GamePanel.Button(panel, words.pause, 96)
    Layout.AtRightTopIn(action, panel, 34, 6)
    local actionText = action.text
    actionText.Depth:Set(function() return action.Depth() + 1 end)

    local dragging = false
    local alive = true
    local activeDragger = false
    local info = {}
    local durationTicks = 1
    local enabled = false
    panel.controls = { slider = slider, action = action }
    local function Refresh()
        if panel.gapLayout then panel.gapLayout:Update() end
        info = GetReplaySeekInfo()
        local duration = info.duration
        enabled = info.available and duration and duration > 0
        if duration and duration > 0 then
            durationTicks = math.max(1, math.floor(duration * 10 + 0.5))
            if not dragging then
                slider:SetEndValue(durationTicks)
                slider:SetValue(math.floor((info.current or 0) * 10 + 0.5))
            end
        end
        slider:SetAlpha(enabled and 1 or 0.45, true)
        if not dragging then
            time:SetText(Clock(info.current) .. ' / ' .. (duration and Clock(duration) or '--:--'))
        end
        actionText:SetText(info.busy and words.cancel or (info.paused and words.play or words.pause))
        if dragging then
            status:SetText(words.release)
            hint:SetText(Clock(slider:GetValue() / 10) .. ' / ' .. Clock(duration))
        elseif info.busy then
            local target = info.target or 0
            local start = info.start or 0
            local progress = target > start and math.max(0, math.min(1, ((info.current or 0) - start) / (target - start))) or 0
            status:SetText(info.restoring and string.format(words.restoring, Clock(target))
                or string.format(words.seeking, Clock(target), math.floor(progress * 100)))
            hint:SetText(russian and 'Подготовка выбранного момента…' or 'Preparing the selected moment…')
        else
            status:SetText(info.paused and words.paused or words.playing)
            hint:SetText(duration and words.hint or (info.indexing and words.indexing or words.unavailable))
        end
    end

    slider.OnBeginChange = function(self) dragging = true end
    slider.OnEndChange = function(self) dragging = false end
    slider.OnValueChanged = function(self, value)
        if dragging then
            time:SetText(Clock(value / 10) .. ' / ' .. Clock(info.duration))
        end
    end
    slider.OnValueSet = function(self, value)
        dragging = false
        if enabled then
            ConExecute('replay_seek ' .. string.format('%.1f', value / 10))
        end
    end
    local function BeginDrag(event)
        if not enabled or activeDragger then return true end
        dragging = true
        slider:SetValue(slider:CalculateValueFromMouse(event.MouseX, event.MouseY))
        slider._thumb:SetTexture(slider.mThumbDown)
        local dragger = Dragger()
        activeDragger = dragger
        local function FinishDrag(commit, x, y)
            if alive then
                if commit and enabled then
                    slider:SetValue(slider:CalculateValueFromMouse(x, y))
                    slider:OnValueSet(slider:GetValue())
                end
                dragging = false
                slider._thumb:SetTexture(slider.mThumbUp)
                Refresh()
            end
            activeDragger = false
            dragger:Destroy()
        end
        dragger.OnMove = function(self, x, y)
            if alive then slider:SetValue(slider:CalculateValueFromMouse(x, y)) end
        end
        dragger.OnRelease = function(self, x, y) FinishDrag(true, x, y) end
        dragger.OnCancel = function(self) FinishDrag(false, 0, 0) end
        PostDragger(slider:GetRootFrame(), event.KeyCode, dragger)
        return true
    end
    local function SliderEvent(control, event)
        if not enabled then return true end
        if event.Type == 'ButtonPress' then
            return BeginDrag(event)
        elseif event.Type == 'MouseEnter' and not dragging then
            slider._thumb:SetTexture(slider.mThumbOver)
        elseif event.Type == 'MouseExit' and not dragging then
            slider._thumb:SetTexture(slider.mThumbUp)
        end
        return true
    end
    -- Both track clicks and thumb drags commit on release; cancelling a
    -- drag restores the current position without submitting a seek.
    slider._thumb.HandleEvent = SliderEvent
    slider._background.HandleEvent = SliderEvent
    action.OnClick = function(self)
        local current = GetReplaySeekInfo()
        if current.available then
            ConExecute(current.busy and 'replay_seek_cancel' or 'replay_seek_toggle_pause')
        end
    end

    local elapsed = 0
    panel:SetNeedsFrameUpdate(true)
    panel.OnFrame = function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.1 then
            elapsed = 0
            Refresh()
        end
    end
    panel.OnDestroy = function(self)
        alive = false
        if activeDragger then
            activeDragger:Destroy()
            activeDragger = false
        end
    end
    GamePanel.Attach(panel, 'replay', {excludeRight = 144, defaultPosition = function()
        return parent.Left() + (parent.Width() - panel.Width()) / 2, parent.Bottom() - panel.Height() - Layout.ScaleNumber(12)
    end})
    Refresh()
    return panel
end

-- Experimental presentation is opt-in. Both layouts use the same native seek
-- commands, and switching layouts only replaces controls in the current UI.
local activePanel = false
local activeParent = false
local rebuilding = false
local scoreboard = false
local visible = true
local lifetime = false

local function CreateHideButton(parent)
    local button = GamePanel.HideButton(parent)
    button._gafTimelineControl = 'ReplayTimelineHide'
    button.OnClick = function() Toggle() end
    local tooltip = {
        text = words.hide,
        body = Hotkeys.Hint(),
    }
    import('/lua/ui/game/tooltip.lua').AddControlTooltip(button, tooltip)
    local handle = button.HandleEvent
    button.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then tooltip.body = Hotkeys.Hint() end
        return handle(self, event)
    end
    return button
end

local function RestoreScoreboardLayout()
    local score = import('/lua/ui/game/score.lua')
    if score.controls and score.controls.bg then score.SetLayout() end
end

local function CreatePanel(parent)
    local panel = scoreboard and import('/lua/gapengine/replay/timeline_scoreboard.lua').Create(parent)
        or CreateStandalone(parent)
    activePanel = panel
    local hide = CreateHideButton(panel)
    Layout.AtRightTopIn(hide, panel, 4, 6)
    hide.Depth:Set(function() return panel.Depth() + 10 end)
    panel.controls.hide = hide
    local beforeDestroy = panel.OnDestroy
    panel.OnDestroy = function(self)
        if beforeDestroy then beforeDestroy(self) end
        if activePanel == self then
            activePanel = false
            if not rebuilding then activeParent = false end
        end
    end
    return panel
end

function Create(parent)
    if activeParent then return activePanel end
    activeParent = parent
    scoreboard = Prefs.GetOption('replay_timeline_scoreboard') == 'on'
    visible = Prefs.GetOption('replay_timeline_visible') != 'off'
    lifetime = Group(parent, 'ReplayTimelineLifetime')
    lifetime:DisableHitTest()
    lifetime:Hide()
    lifetime.OnDestroy = function(self)
        if lifetime == self then
            lifetime = false
            activeParent = false
        end
    end
    Hotkeys.Install()
    if visible then
        return CreatePanel(parent)
    end
    return false
end

function IsVisible()
    return activePanel != false
end

function SetVisible(enabled, persist)
    visible = enabled
    if activeParent then
        if enabled then
            if not activePanel then CreatePanel(activeParent) end
        else
            -- Destroy only presentation controls, ending a drag if necessary.
            -- Releasing an integrated footer also restores the scoreboard size.
            rebuilding = true
            if activePanel then activePanel:Destroy() end
            rebuilding = false
            RestoreScoreboardLayout()
        end
    end
    if persist then Prefs.SetOption('replay_timeline_visible', enabled and 'on' or 'off') end
end

function Toggle()
    if SessionIsReplay() and activeParent then SetVisible(not visible, true) end
end

function SetScoreboard(enabled)
    if not activeParent or scoreboard == enabled then return end
    scoreboard = enabled
    rebuilding = true
    if activePanel then activePanel:Destroy() end
    rebuilding = false
    -- Releasing the experimental footer also restores the native frame height.
    RestoreScoreboardLayout()
    if visible then return CreatePanel(activeParent) end
end

function RefreshLayout()
    if not activeParent then return end
    rebuilding = true
    if activePanel then activePanel:Destroy() end
    rebuilding = false
    RestoreScoreboardLayout()
    if visible then return CreatePanel(activeParent) end
end
