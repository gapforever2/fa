local Group = import('/lua/maui/group.lua').Group
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Layout = import('/lua/gapengine/ui/controls/panel_layout.lua').LayoutFor('replay')
local UIUtil = import('/lua/ui/uiutil.lua')
local GamePanel = import('/lua/gapengine/ui/controls/game_panel.lua')

local russian = string.lower(__language or '') == 'ru'
local words = russian and {
    title = 'РЕПЛЕЙ', back = '−10 с', forward = '+10 с',
    release = 'Отпустите кнопку для перехода',
    indexing = 'Чтение длительности реплея…',
    unavailable = 'Шкала времени недоступна',
    seeking = 'Переход к %s · %d%%',
    restoring = 'Восстановление %s…',
    graphics = 'Восстановление изображения…',
    paused = 'Пауза', playing = 'Воспроизведение',
    cancel = 'Отмена', pause = 'Пауза', play = 'Продолжить',
    prepareOn = 'Предрасчёт: вкл', prepareOff = 'Предрасчёт: выкл',
    prepare = 'Эксперимент · фон', ready = 'Готово до %s', failed = 'Фон недоступен',
} or {
    title = 'REPLAY', back = '−10 s', forward = '+10 s',
    release = 'Release to seek',
    indexing = 'Reading replay duration…',
    unavailable = 'Timeline unavailable',
    seeking = 'Seeking to %s · %d%%',
    restoring = 'Restoring %s…',
    graphics = 'Restoring view…',
    paused = 'Paused', playing = 'Playing',
    cancel = 'Cancel', pause = 'Pause', play = 'Play',
    prepareOn = 'Precompute: on', prepareOff = 'Precompute: off',
    prepare = 'Experimental · background', ready = 'Ready to %s', failed = 'Background unavailable',
}

local function Clock(seconds)
    local total = math.max(0, math.floor(seconds or 0))
    if total >= 3600 then
        return string.format('%d:%02d:%02d', math.floor(total / 3600), math.mod(math.floor(total / 60), 60), math.mod(total, 60))
    end
    return string.format('%02d:%02d', math.floor(total / 60), math.mod(total, 60))
end

local currentPanel = false

function Create(parent)
    if currentPanel then return currentPanel end
    local score = import('/lua/ui/game/score.lua')
    local panel = Group(parent, 'ReplayTimeline')
    panel.gapScaleKey = 'replay'
    currentPanel = panel
    panel.integrated = false
    Layout.SetHeight(panel, 118)
    local accent = GamePanel.AccentColor()
    local restoreLayout = false
    panel.Width:Set(function() return math.min(Layout.ScaleNumber(340), parent.Width() - Layout.ScaleNumber(30)) end)
    Layout.AtHorizontalCenterIn(panel, parent)
    Layout.AtBottomIn(panel, parent, 12)
    panel.Depth:Set(160)

    local frame = GamePanel.Frame(panel)

    local title = UIUtil.CreateText(panel, words.title, GamePanel.FontSize('replay', 11), UIUtil.bodyFont)
    Layout.AtLeftTopIn(title, panel, 4, 7)
    title:SetColor('ffffffff')
    title:DisableHitTest()

    local time = UIUtil.CreateText(panel, '00:00 / --:--', GamePanel.FontSize('replay', 13), UIUtil.bodyFont)
    Layout.AtRightTopIn(time, panel, 32, 6)
    time:SetColor(accent)
    time:DisableHitTest()

    local status = UIUtil.CreateText(panel, '', GamePanel.FontSize('replay', 11), UIUtil.bodyFont)
    Layout.AtLeftTopIn(status, panel, 4, 25)
    status:SetColor('ffb8c4cc')
    status:DisableHitTest()

    local slider = IntegerSlider(panel, false, 0, 1, 1,
        UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
        UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
        UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
        UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))
    Layout.AtLeftTopIn(slider, panel, 8, 42)
    Layout.AtRightIn(slider, panel, 8)
    slider.Width:Set(function() return slider.Right() - slider.Left() end)
    Layout.SetHeight(slider, 20)
    GamePanel.ScaleSlider(slider, 'replay')
    slider._background.Left:Set(slider.Left)
    slider._background.Right:Set(slider.Right)
    slider._background.Top:Set(function() return slider.Top() + Layout.ScaleNumber(8) end)
    slider._background.Bottom:Set(function() return slider.Top() + Layout.ScaleNumber(12) end)
    slider._background.Width:Set(slider.Width)
    slider._background.Height:Set(function() return slider._background.Bottom() - slider._background.Top() end)
    slider._thumb.Depth:Set(function() return panel.Depth() + 5 end)
    slider._background.Depth:Set(function() return panel.Depth() + 2 end)

    local function Button(label, width)
        local button = GamePanel.Button(panel, label, width, 22)
        Layout.AtTopIn(button, panel, 67)
        return button
    end
    local action = Button(words.pause, 104)
    Layout.AtHorizontalCenterIn(action, panel)
    local actionText = action.text
    local back = Button(words.back, 60)
    Layout.LeftOf(back, action, 6)
    local forward = Button(words.forward, 60)
    Layout.RightOf(forward, action, 6)
    local prepare = Button(words.prepareOff, 138)
    Layout.AtLeftTopIn(prepare, panel, 4, 93)
    local prepared = UIUtil.CreateText(panel, words.prepare, GamePanel.FontSize('replay', 10), UIUtil.bodyFont)
    Layout.AtRightTopIn(prepared, panel, 4, 99)
    prepared:SetColor('ffb8c4cc')
    prepared:DisableHitTest()
    import('/lua/ui/game/tooltip.lua').AddControlTooltip(prepare, {
        text = russian and 'Экспериментальный предрасчёт' or 'Experimental precomputation',
        body = russian and 'Готовит будущие снимки отдельным процессом. Требует дополнительной памяти и процессора. Выключение останавливает фон; готовые снимки остаются.'
            or 'Prepares future snapshots in a separate process. Uses extra memory and CPU. Turning off stops preparation and keeps ready snapshots.',
    })

    local dragging = false
    local alive = true
    local activeDragger = false
    local info = {}
    local durationTicks = 1
    local enabled = false
    panel.controls = { slider = slider, action = action, back = back, forward = forward, time = time, status = status,
        prepare = prepare, prepared = prepared }
    local function AttachToScoreboard()
        -- GAF creates its scoreboard on the first update, after CreateUI.
        -- Reparent the existing controls when it arrives, preserving their state.
        local board = score.controls
        if panel.integrated or not (board and board.bg and board.bgTop and board.bgBottom and board.armyGroup) then return end
        panel:SetParent(board.bg)
        panel:ResetLayout()
        Layout.SetHeight(panel, 118)
        panel.Left:Set(board.armyGroup.Left)
        panel.Right:Set(board.armyGroup.Right)
        panel.Top:Set(function() return board.armyGroup.Bottom() + Layout.ScaleNumber(6) end)
        panel.Depth:Set(function() return board.bg.Depth() + 20 end)
        panel.integrated = true
        frame:Hide() -- The scoreboard already supplies the surrounding frame.
        accent = board.time and board.time._color and board.time._color() or accent
        time:SetColor(accent)
        local function ExtendBoard()
            board.bgBottom.Top:Set(function()
                return math.max(panel.Bottom() - Layout.ScaleNumber(14), board.bgTop.Bottom())
            end)
        end
        local previousLayout = score.SetLayout
        local function TimelineLayout()
            previousLayout()
            ExtendBoard()
        end
        score.SetLayout = TimelineLayout
        restoreLayout = function()
            if score.SetLayout == TimelineLayout then score.SetLayout = previousLayout end
        end
        ExtendBoard()
    end
    local function Refresh()
        AttachToScoreboard()
        if panel.gapLayout then panel.gapLayout:Update() end
        info = GetReplaySeekInfo()
        prepare.text:SetText(info.precompute_enabled and words.prepareOn or words.prepareOff)
        prepared:SetText(info.precomputeError and words.failed
            or ((info.precomputed or 0) > 0 and string.format(words.ready, Clock(info.precomputed)) or words.prepare))
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
        back:SetAlpha(enabled and 1 or 0.4, true)
        forward:SetAlpha(enabled and 1 or 0.4, true)
        if not dragging then
            time:SetText(Clock(info.current) .. ' / ' .. (duration and Clock(duration) or '--:--'))
        end
        actionText:SetText(info.busy and words.cancel or (info.paused and words.play or words.pause))
        if dragging then
            status:SetText(words.release)
        elseif info.busy then
            local target = info.target or 0
            local start = info.start or 0
            local progress = target > start and math.max(0, math.min(1, ((info.current or 0) - start) / (target - start))) or 0
            status:SetText(info.restoring and string.format(words.restoring, Clock(target))
                or string.format(words.seeking, Clock(target), math.floor(progress * 100)))
        elseif (info.graphicsPending or 0) > 0 then
            status:SetText(words.graphics)
        else
            status:SetText(duration and (info.paused and words.paused or words.playing)
                or (info.indexing and words.indexing or words.unavailable))
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
    -- Keep the full-height slider easy to click around its thin visual track.
    slider:EnableHitTest()
    slider.HandleEvent = SliderEvent
    prepare.OnClick = function(self)
        local current = GetReplaySeekInfo()
        if current.available then ConExecute('replay_Precompute ' .. (current.precompute_enabled and 'false' or 'true')) end
    end
    action.OnClick = function(self)
        local current = GetReplaySeekInfo()
        if current.available then ConExecute(current.busy and 'replay_seek_cancel' or 'replay_seek_toggle_pause') end
    end
    local function StepButton(button, seconds)
        button.OnClick = function(self)
            local current = GetReplaySeekInfo()
            if current.available and current.duration then
                local origin = current.busy and current.target or current.current
                local target = math.max(0, math.min(current.duration, origin + seconds))
                ConExecute('replay_seek ' .. string.format('%.1f', target))
            end
        end
    end
    StepButton(back, -10)
    StepButton(forward, 10)

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
        currentPanel = false
        if restoreLayout then restoreLayout() end
        if activeDragger then
            activeDragger:Destroy()
            activeDragger = false
        end
    end
    GamePanel.Attach(panel, 'replay', {excludeRight = 32, canMove = function() return not panel.integrated end,
        defaultPosition = function()
            return parent.Left() + (parent.Width() - panel.Width()) / 2, parent.Bottom() - panel.Height() - Layout.ScaleNumber(12)
        end})
    Refresh()
    return panel
end
