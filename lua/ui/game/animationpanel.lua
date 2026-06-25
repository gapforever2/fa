local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Text = import("/lua/maui/text.lua").Text

local panel = nil
local panelVisible = false

local GROUP_DEV_ROLES = {
    mod = true,
    bal = true,
    admin = true,
    yt = true,
    bs = true,
}
local canUseCached = nil

local function CanUse()
    if canUseCached == nil then
        local arg = GetCommandLineArg("/group", 1)
        if not arg or not arg[1] then
            canUseCached = false
        else
            local role = string.lower(tostring(arg[1]))
            canUseCached = GROUP_DEV_ROLES[role] == true
        end
    end
    return canUseCached
end


local function getPrimaryKeyForAction(actionName)
    local keymapper = import("/lua/keymap/keymapper.lua")
    local lookup = keymapper.GetKeyLookup()
    local binding = lookup and lookup[actionName]
    if not binding or type(binding) ~= "string" then
        return nil
    end
    local last = binding:match("([^-]+)$")
    return last or binding
end

local RADIUS = 150
local RING_SIZE = 350

local ANGLE_OFFSET = 20
local OVERLAY_INDEX_REVERSED = false
local OVERLAY_INDEX_SHIFT = -5

local ANIMATION_OPTIONS = {
    { key = nil,                 label = "<LOC tooltipui0910>Action", enabled = false },
    { key = nil,                 label = "<LOC tooltipui0910>Action", enabled = false },
    { key = nil,                 label = "<LOC tooltipui0910>Action", enabled = false },
    { key = nil,                 label = "<LOC tooltipui0910>Action", enabled = false },
    { key = nil,                 label = "<LOC tooltipui0910>Action", enabled = false },
    { key = nil,                 label = "<LOC tooltipui0910>Action", enabled = false },
    { key = nil,                 label = "<LOC tooltipui0910>Action", enabled = false },
    { key = "AnimationAction",   label = "<LOC tooltipui0910>Action", enabled = true },
}

local COLOR_NORMAL = 'ffaaaaaa'
local COLOR_SELECTED = 'ffffff00'
local COLOR_DISABLED = 'ff666666'
local ENTRY_ALPHA_NORMAL = 0.75
local ENTRY_ALPHA_SELECTED = 1
local ENTRY_ALPHA_DISABLED = 0.35
local SEGMENT_HOVER_ALPHA_SELECTED = 0.9
local SEGMENT_ALPHA_NORMAL = 0
local SEGMENT_ALPHA_DISABLED = 0.2
local AnimationPanelCooldownSeconds = 10
local nextAllowedAt = 0
local SEGMENT_HOVER_TEXTURES = {
    "/game/marker/ellips1.dds",
    "/game/marker/ellips2.dds",
    "/game/marker/ellips3.dds",
    "/game/marker/ellips4.dds",
    "/game/marker/ellips5.dds",
    "/game/marker/ellips6.dds",
    "/game/marker/ellips7.dds",
    "/game/marker/ellips8.dds",
}

local function WrapSegmentIndex(index, count)
    if count <= 0 then
        return 1
    end

    while index < 1 do
        index = index + count
    end
    while index > count do
        index = index - count
    end

    return index
end

local function SetEntryState(entry, state)
    if not entry or IsDestroyed(entry) then
        return
    end

    if state == "selected" then
        entry:SetAlpha(ENTRY_ALPHA_SELECTED)
    elseif state == "disabled" then
        entry:SetAlpha(ENTRY_ALPHA_DISABLED)
    else
        entry:SetAlpha(ENTRY_ALPHA_NORMAL)
    end
end

local function IsSegmentEnabled(seg)
    local opt = ANIMATION_OPTIONS[seg]
    if not opt then
        return false
    end
    if opt.enabled == false then
        return false
    end
    return type(opt.key) == "string" and opt.key ~= ""
end

local function RefreshEntriesVisualState(self, cooldownActive)
    for i = 1, table.getn(ANIMATION_OPTIONS) do
        if self._segmentOverlays and self._segmentOverlays[i] and not IsDestroyed(self._segmentOverlays[i]) then
            self._segmentOverlays[i]:SetAlpha(cooldownActive and SEGMENT_ALPHA_DISABLED or SEGMENT_ALPHA_NORMAL)
        end
    end

    if cooldownActive then
        for i = 1, table.getn(ANIMATION_OPTIONS) do
            if self._entries[i] then
                SetEntryState(self._entries[i], "disabled")
            end
        end
        self._centerLabel:SetColor(COLOR_DISABLED)
        return
    end

    for i = 1, table.getn(ANIMATION_OPTIONS) do
        if self._entries[i] then
            SetEntryState(self._entries[i], "normal")
        end
    end
    if self._entries[self._segment] then
        SetEntryState(self._entries[self._segment], "selected")
    end
    local overlayCount = table.getn(self._segmentOverlays or {})
    local overlayIndex = self._segment
    if OVERLAY_INDEX_REVERSED then
        overlayIndex = overlayCount - overlayIndex + 1
    end
    overlayIndex = WrapSegmentIndex(overlayIndex + OVERLAY_INDEX_SHIFT, overlayCount)
    if self._segmentOverlays and self._segmentOverlays[overlayIndex] and not IsDestroyed(self._segmentOverlays[overlayIndex]) then
        self._segmentOverlays[overlayIndex]:SetAlpha(SEGMENT_HOVER_ALPHA_SELECTED)
    end
    self._centerLabel:SetColor('ffffffff')
end

local function IsCooldownActive()
    return (nextAllowedAt - GetGameTimeSeconds()) > 0
end

local function UpdateCooldownLabel()
    if not panel or IsDestroyed(panel) or not panel._cooldownLabel then
        return
    end

    local remaining = math.max(0, nextAllowedAt - GetGameTimeSeconds())
    if remaining > 0 then
        panel._cooldownLabel:SetText(string.format("Next animation in: %.1fs", remaining))
    else
        panel._cooldownLabel:SetText("Animation ready")
    end
end

local function Hide()
    if panel and not IsDestroyed(panel) then
        panel:Hide()
        panelVisible = false
    end
end

local function playSelectedAndHide()
    if panel and not IsDestroyed(panel) and panelVisible then
        local seg = panel._segment
        if not (seg and IsSegmentEnabled(seg)) then
            return
        end

        if IsCooldownActive() then
            Hide()
            return
        end

        local opt = ANIMATION_OPTIONS[seg]
        SimCallback({ Func = 'PlayUnitAnimation', Args = { Animation = opt.key } }, true)
        nextAllowedAt = GetGameTimeSeconds() + AnimationPanelCooldownSeconds
        Hide()
    end
end

local function calcNearest(mx, my, cx, cy, n, angleOffset)
    angleOffset = angleOffset or 0
    local mouseVecX = mx - cx
    local mouseVecY = my - cy
    local len = math.sqrt(mouseVecX * mouseVecX + mouseVecY * mouseVecY)
    if len < 1 then
        return 1
    end
    local bestDot = -1e9
    local target = 1
    local angleStep = 360 / n
    for i = 1, n do

        local degree = (i - 1) * angleStep + angleOffset
        local rad = math.rad(degree)
        local dx = math.cos(rad)
        local dy = math.sin(rad)
        local dot = (mouseVecX * dx + mouseVecY * dy) / len
        if dot > bestDot then
            bestDot = dot
            target = i
        end
    end
    return target
end

local function CreatePanel(parent)
    if panel and not IsDestroyed(panel) then
        return panel
    end

    local bg = Bitmap(parent)
    panel = bg
    LayoutHelpers.FillParent(bg, parent)
    LayoutHelpers.ResetWidth(bg)
    LayoutHelpers.ResetHeight(bg)
    bg.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
    bg:SetAlpha(0.4)
    bg:SetSolidColor('ff000000')

    bg.MouseX = nil
    bg.MouseY = nil
    bg._segment = 1
    bg._prevSegment = nil
    bg._entries = {}
    bg._segmentOverlays = {}

    local ring = Bitmap(bg, UIUtil.UIFile('/game/marker/ellips.dds'))
    LayoutHelpers.SetDimensions(ring, RING_SIZE, RING_SIZE)
    LayoutHelpers.AtCenterIn(ring, bg)
    ring:DisableHitTest()

    for i = 1, table.getn(ANIMATION_OPTIONS) do
        local overlay = Bitmap(bg)
        LayoutHelpers.SetDimensions(overlay, RING_SIZE, RING_SIZE)
        LayoutHelpers.AtCenterIn(overlay, bg)
        overlay:SetAlpha(SEGMENT_ALPHA_NORMAL)
        overlay:DisableHitTest()
        bg._segmentOverlays[i] = overlay
    end

    ForkThread(function()
        for i = 1, table.getn(ANIMATION_OPTIONS) do
            if IsDestroyed(bg) then
                return
            end
            local overlay = bg._segmentOverlays[i]
            if overlay and not IsDestroyed(overlay) then
                local segmentTexture = SEGMENT_HOVER_TEXTURES[i] or SEGMENT_HOVER_TEXTURES[1]
                overlay:SetTexture(UIUtil.UIFile(segmentTexture))
            end
            WaitSeconds(0.03)
        end
    end)

    local n = table.getn(ANIMATION_OPTIONS)
    local angleStep = 360 / n
    for i = 1, n do
        local opt = ANIMATION_OPTIONS[i]
        if opt.icon and opt.icon ~= "" then
            local entry = Bitmap(bg, UIUtil.UIFile(opt.icon))
            LayoutHelpers.SetDimensions(entry, 36, 36)
            SetEntryState(entry, "normal")
            entry:DisableHitTest()
            local degree = (i - 1) * angleStep + ANGLE_OFFSET
            local posX = RADIUS * math.cos(math.rad(degree))
            local posY = RADIUS * math.sin(math.rad(degree))
            LayoutHelpers.AtCenterIn(entry, bg, posY, posX)
            bg._entries[i] = entry
        else
            bg._entries[i] = false
        end
    end

    local centerLabel = UIUtil.CreateText(bg, LOC(ANIMATION_OPTIONS[1].label), 18, UIUtil.titleFont)
    centerLabel:SetColor('ffffffff')
    LayoutHelpers.AtCenterIn(centerLabel, bg)
    centerLabel:DisableHitTest()
    bg._centerLabel = centerLabel

    local closeHint = UIUtil.CreateText(bg, LOC("<LOC tooltipui0907>Release key to play, right-click to cancel"), 12, UIUtil.bodyFont)
    closeHint:SetColor('ffaaaaaa')
    LayoutHelpers.AtBottomIn(closeHint, bg, -30)
    LayoutHelpers.AtHorizontalCenterIn(closeHint, bg)
    closeHint:DisableHitTest()

    local cooldownLabel = UIUtil.CreateText(bg, "Animation ready", 12, UIUtil.bodyFont)
    cooldownLabel:SetColor('ffcccccc')
    LayoutHelpers.Below(cooldownLabel, centerLabel, 12)
    LayoutHelpers.AtHorizontalCenterIn(cooldownLabel, bg)
    cooldownLabel:DisableHitTest()
    bg._cooldownLabel = cooldownLabel

    bg.GetCenter = function(self)
        return self.Left() + self.Width() / 2, self.Top() + self.Height() / 2
    end

    bg:SetNeedsFrameUpdate(true)
    bg.OnFrame = function(self, delta)
        local cooldownActive = IsCooldownActive()
        RefreshEntriesVisualState(self, cooldownActive)
        if self.MouseX == nil or self.MouseY == nil then
            UpdateCooldownLabel()
            return
        end
        local cx, cy = self:GetCenter()
        local numOpts = table.getn(ANIMATION_OPTIONS)
        self._segment = calcNearest(self.MouseX, self.MouseY, cx, cy, numOpts, ANGLE_OFFSET)
        if self._segment ~= self._prevSegment and not cooldownActive then
            self._centerLabel:SetText(LOC(ANIMATION_OPTIONS[self._segment].label))
            self._prevSegment = self._segment
        end
        RefreshEntriesVisualState(self, cooldownActive)
        UpdateCooldownLabel()
    end

    bg.HandleEvent = function(self, event)
        if event.Type == 'MouseMotion' or event.Type == 'MouseMove' then
            self.MouseX = event.MouseX
            self.MouseY = event.MouseY
        elseif event.Type == 'ButtonPress' then
            if event.Modifiers and event.Modifiers.Left then
                if IsCooldownActive() then
                    return true
                end
                playSelectedAndHide()
                return true
            elseif event.Modifiers and event.Modifiers.Right then
                Hide()
                return true
            end
        elseif event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE then
                Hide()
                return true
            end
        end
        return false
    end

    bg:Hide()
    return bg
end

function Toggle()
    if not CanUse() then
        return
    end

    local parent = GetFrame(0)
    if not parent or IsDestroyed(parent) then
        return
    end

    if panel and not IsDestroyed(panel) and panelVisible then
        Hide()
        return
    end

    local selection = GetSelectedUnits()
    if not selection or table.getn(selection) ~= 1 then
        return
    end
    if not EntityCategoryContains(categories.COMMAND, selection[1]) then
        return
    end

    CreatePanel(parent)
    if IsDestroyed(panel) then
        return
    end

    panel._segment = 1
    panel._prevSegment = 1
    panel.MouseX = nil
    panel.MouseY = nil
    local cooldownActive = IsCooldownActive()
    RefreshEntriesVisualState(panel, cooldownActive)
    panel._centerLabel:SetText(LOC(ANIMATION_OPTIONS[1].label))
    UpdateCooldownLabel()
    panel:Show()
    panelVisible = true
end

return {
    Toggle = Toggle,
    CanUse = CanUse,
}
