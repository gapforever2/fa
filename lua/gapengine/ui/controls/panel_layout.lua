local Base = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Prefs = import('/lua/user/prefs.lua')

local optionNames = {replay = 'gap_replay_panel_scale', lag = 'gap_lag_panel_scale'}
local appliedScales = {}

local function Clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function Scale(key)
    local percent = appliedScales[key] or tonumber(Prefs.GetFromCurrentProfile('options.' .. optionNames[key])) or 100
    if percent ~= percent then percent = 100 end
    return Clamp(percent, 70, 120) / 100
end

function FontSize(key, size)
    return math.max(9, size * Scale(key))
end

function LayoutFor(key)
    local layout = {}
    setmetatable(layout, {__index = Base})
    for _, name in {'ScaleNumber', 'SetWidth', 'SetHeight', 'SetDimensions',
        'AtLeftIn', 'AtRightIn', 'AtTopIn', 'AtBottomIn', 'AtLeftTopIn', 'AtRightTopIn',
        'AtCenterIn', 'AtHorizontalCenterIn', 'LeftOf', 'RightOf', 'Below'} do
        local method = Base[name]
        layout[name] = function(...)
            for i = 1, arg.n do
                if type(arg[i]) == 'number' then arg[i] = arg[i] * Scale(key) end
            end
            return method(unpack(arg))
        end
    end
    return layout
end

function Changed(key, percent)
    -- Options invoke their callbacks before saving the new preference table.
    if percent then appliedScales[key] = Clamp(percent, 70, 120) end
    import('/lua/ui/game/tooltip.lua').DestroyMouseoverDisplay()
    if key == 'replay' then
        import('/lua/gapengine/replay/timeline.lua').RefreshLayout()
    elseif key == 'lag' then
        import('/lua/gapengine/ui/game/lag_warning.lua').RefreshLayout()
    end
end

function SetScale(key, percent)
    percent = Clamp(percent, 70, 120)
    if math.abs(Scale(key) * 100 - percent) < 0.01 then return false end
    Prefs.SetOption(optionNames[key], percent)
    return true
end

local function Saved(key)
    local layouts = Prefs.GetFromCurrentProfile('GapPanelLayouts')
    local value = type(layouts) == 'table' and layouts[key]
    return type(value) == 'table' and value or {}
end

function Attach(panel, key, settings)
    panel.gapScaleKey = key
    local controller = {drag = false, preview = false, lastLeft = false, lastTop = false}
    panel.gapLayout = controller
    local handle = Group(panel, 'GapPanelMoveHandle')
    controller.handle = handle
    handle.Left:Set(panel.Left)
    handle.Top:Set(panel.Top)
    handle.Width:Set(function() return math.max(1, panel.Width() - Base.ScaleNumber((settings.excludeRight or 0) * Scale(key))) end)
    handle.Height:Set(function() return Base.ScaleNumber(math.max(18, 24 * Scale(key))) end)
    handle.Depth:Set(function() return panel.Depth() + 3 end)
    handle:EnableHitTest()

    local function CanMove()
        return not settings.canMove or settings.canMove()
    end
    -- Detach the old bottom/right anchors before moving a fixed-size panel.
    -- Otherwise a bottom-anchored frame stretches between its old and new edge.
    if CanMove() then
        panel.Right:Set(function() return panel.Left() + panel.Width() end)
        panel.Bottom:Set(function() return panel.Top() + panel.Height() end)
    end
    local function Bounds()
        local frame = GetFrame(0)
        local margin = Base.ScaleNumber(8)
        return frame.Left() + margin, frame.Top() + margin,
            math.max(0, frame.Width() - panel.Width() - 2 * margin),
            math.max(0, frame.Height() - panel.Height() - 2 * margin)
    end
    function controller:Update()
        if not CanMove() then return end
        local minX, minY, rangeX, rangeY = Bounds()
        local saved = Saved(key)
        local left, top = settings.defaultPosition()
        if type(saved.x) == 'number' and saved.x == saved.x then left = minX + Clamp(saved.x, 0, 1) * rangeX end
        if type(saved.y) == 'number' and saved.y == saved.y then top = minY + Clamp(saved.y, 0, 1) * rangeY end
        if self.preview then left, top = self.preview.x, self.preview.y end
        left, top = Clamp(left, minX, minX + rangeX), Clamp(top, minY, minY + rangeY)
        if left ~= self.lastLeft then panel.Left:Set(left); self.lastLeft = left end
        if top ~= self.lastTop then panel.Top:Set(top); self.lastTop = top end
    end
    function controller:Reset()
        local layouts = Prefs.GetFromCurrentProfile('GapPanelLayouts') or {}
        layouts[key] = nil
        Prefs.SetToCurrentProfile('GapPanelLayouts', layouts)
        SavePreferences()
        if not SetScale(key, 100) then Changed(key) end
    end
    local function SavePosition()
        local minX, minY, rangeX, rangeY = Bounds()
        local layouts = Prefs.GetFromCurrentProfile('GapPanelLayouts') or {}
        layouts[key] = {x = rangeX > 0 and (panel.Left() - minX) / rangeX or 0,
            y = rangeY > 0 and (panel.Top() - minY) / rangeY or 0}
        Prefs.SetToCurrentProfile('GapPanelLayouts', layouts)
        SavePreferences()
    end
    handle.HandleEvent = function(self, event)
        local modifiers = event.Modifiers or {}
        if event.Type == 'WheelRotation' and modifiers.Ctrl then
            if (event.WheelRotation or 0) ~= 0 then SetScale(key, Scale(key) * 100 + (event.WheelRotation > 0 and 5 or -5)) end
            return true
        elseif event.Type == 'ButtonPress' and modifiers.Right then
            controller:Reset()
            return true
        elseif event.Type == 'ButtonPress' and modifiers.Left and CanMove() and not controller.drag then
            import('/lua/ui/game/tooltip.lua').DestroyMouseoverDisplay()
            local offsetX, offsetY = event.MouseX - panel.Left(), event.MouseY - panel.Top()
            local dragger = Dragger()
            controller.drag = dragger
            local function Finish(commit, x, y)
                if commit then
                    controller.preview = {x = x - offsetX, y = y - offsetY}
                    controller:Update()
                    SavePosition()
                end
                controller.preview = false
                controller.drag = false
                controller:Update()
                dragger:Destroy()
            end
            dragger.OnMove = function(self, x, y)
                controller.preview = {x = x - offsetX, y = y - offsetY}
                controller:Update()
            end
            dragger.OnRelease = function(self, x, y) Finish(true, x, y) end
            dragger.OnCancel = function() Finish(false, 0, 0) end
            PostDragger(panel:GetRootFrame(), event.KeyCode, dragger)
            return true
        end
        return false
    end
    local russian = string.lower(__language or '') == 'ru'
    import('/lua/ui/game/tooltip.lua').AddControlTooltip(handle, {
        text = russian and 'Положение и размер панели' or 'Panel position and size',
        body = russian and 'Перетащите заголовок. Ctrl+колесо — размер. ПКМ — сброс. Встроенная перемотка перемещается со скорбордом.'
            or 'Drag the heading. Ctrl+wheel changes size. Right-click resets. Embedded replay controls move with the scoreboard.',
    })
    local beforeDestroy = panel.OnDestroy
    panel.OnDestroy = function(self)
        if controller.drag then controller.drag:Destroy(); controller.drag = false end
        if beforeDestroy then beforeDestroy(self) end
    end
    controller:Update()
    return controller
end
