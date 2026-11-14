-- Shared Supreme Commander skin for Gap's replay and status panels.
local UIUtil = import('/lua/ui/uiutil.lua')
local Layout = import('/lua/maui/layouthelpers.lua')
local Position = import('/lua/gapengine/ui/controls/panel_layout.lua')

LayoutFor = Position.LayoutFor
FontSize = Position.FontSize
Scale = Position.Scale
Attach = Position.Attach

function Frame(parent)
    local frame = UIUtil.CreateNinePatchStd(parent, '/game/chat_brd/')
    frame:Surround(parent, 4, 4)
    Layout.DepthUnderParent(frame, parent, 2)
    frame:DisableHitTest(true)
    parent.gapFrame = frame
    return frame
end

function Button(parent, label, width, height)
    local key = parent.gapScaleKey
    local button = UIUtil.CreateButtonStd(parent, '/dialogs/standard-small_btn/standard-small', label, key and FontSize(key, 12) or 12)
    local size = key and Scale(key) or 1
    Layout.SetDimensions(button, width * size, (height or 24) * size)
    button.text = button.label
    return button
end

function HideButton(parent)
    local button = UIUtil.CreateButtonStd(parent, '/dialogs/close_btn/close')
    local size = parent.gapScaleKey and Scale(parent.gapScaleKey) or 1
    Layout.SetDimensions(button, math.max(16, 20 * size), math.max(16, 20 * size))
    return button
end

function ScaleSlider(slider, key)
    slider._thumb.Width:Set(function() return Layout.ScaleNumber(slider._thumb.BitmapWidth() * Scale(key)) end)
    slider._thumb.Height:Set(function() return Layout.ScaleNumber(slider._thumb.BitmapHeight() * Scale(key)) end)
end

function TextColor()
    return UIUtil.fontColor
end

function AccentColor()
    return UIUtil.factionTextColor or UIUtil.fontColor
end
