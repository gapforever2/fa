-- Gap Engine's shared-start panel. The native waiting loop refreshes it using
-- real time, since simulation-time threads have not started yet.
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local GamePanel = import('/lua/gapengine/ui/controls/game_panel.lua')

local dialog = false
local colors = {ready = 'FF88CC88', waiting = 'FFCCAA44', disconnected = 'FFCC4444'}
local labels = {
    ready = LOC('<LOC gap_loading_ready>Ready'),
    waiting = LOC('<LOC gap_loading_waiting>Loading...'),
    disconnected = LOC('<LOC gap_loading_disconnected>Disconnected'),
}

local function Clients()
    local clients = {}
    local read = rawget(_G, 'GetSessionClientsLive') or GetSessionClients
    for index, client in read() or {} do
        table.insert(clients, {index = index, client = client})
    end
    table.sort(clients, function(a, b) return a.index < b.index end)
    return clients
end

local function CreateRows(panel, clients)
    if panel.body then panel.body:Destroy() end
    panel.body = Group(panel)
    LayoutHelpers.FillParent(panel.body, panel)
    panel.rows = {}
    local maxRows = math.max(1, math.floor((panel:GetParent().Height() - 110) / 22))
    local columns = math.max(1, math.ceil(table.getn(clients) / maxRows))
    local rowWidth = math.min(360, (panel:GetParent().Width() - 60) / columns)
    local rowCount = math.min(maxRows, table.getn(clients))
    panel.Width:Set(columns * rowWidth + 32)
    panel.Height:Set(76 + rowCount * 22)
    for number, entry in clients do
        local index = entry.index
        local column = math.floor((number - 1) / maxRows)
        local line = math.mod(number - 1, maxRows)
        local row = Group(panel.body)
        row.Width:Set(rowWidth)
        row.Height:Set(18)
        row.Left:Set(function() return panel.Left() + 16 + column * rowWidth end)
        row.Top:Set(function() return panel.Top() + 64 + line * 22 end)
        row.indicator = Bitmap(row)
        row.indicator.Width:Set(10)
        row.indicator.Height:Set(10)
        LayoutHelpers.AtLeftIn(row.indicator, row, 4)
        LayoutHelpers.AtVerticalCenterIn(row.indicator, row)
        row.status = UIUtil.CreateText(row, '', 12, UIUtil.bodyFont)
        LayoutHelpers.AtRightIn(row.status, row, 8)
        LayoutHelpers.AtVerticalCenterIn(row.status, row)
        row.name = UIUtil.CreateText(row, '', 13, UIUtil.bodyFont)
        LayoutHelpers.RightOf(row.name, row.indicator, 6)
        LayoutHelpers.AtVerticalCenterIn(row.name, row)
        row.name:SetClipToWidth(true)
        row.name.Right:Set(function() return row.status.Left() - 8 end)
        row.name:SetColor('FFDDDDDD')
        panel.rows[index] = row
    end
end

function Update(force)
    local panel = dialog
    if not panel then return end
    local now = GetSystemTimeSeconds()
    if not force and now - panel.lastRefresh < 0.25 then return end
    panel.lastRefresh = now
    local clients = Clients()
    local signature = ''
    for _, entry in clients do
        signature = signature .. tostring(entry.index) .. ':' .. tostring(entry.client.uid) .. ';'
    end
    if signature ~= panel.roster then
        panel.roster = signature
        CreateRows(panel, clients)
    end
    local ready = 0
    for _, entry in clients do
        local client = entry.client
        local row = panel.rows[entry.index]
        local status = client.connected == false and 'disconnected' or (client.ready and 'ready' or 'waiting')
        if status == 'ready' then ready = ready + 1 end
        if row.state ~= status then
            row.state = status
            row.status:SetText(labels[status])
            row.status:SetColor(colors[status])
            row.indicator:SetSolidColor(colors[status])
        end
        local name = client.name or ('Player ' .. tostring(entry.index))
        if client['local'] then name = name .. ' (' .. LOC('<LOC gap_loading_you>You') .. ')' end
        if row.name:GetText() ~= name then row.name:SetText(name) end
    end
    local seconds = math.max(0, math.floor(now - panel.started))
    local summary = string.format('%d / %d    %dm %02ds', ready, table.getn(clients), math.floor(seconds / 60), math.mod(seconds, 60))
    if panel.elapsed:GetText() ~= summary then panel.elapsed:SetText(summary) end
end

function Stop()
    if dialog then
        local panel = dialog
        dialog = false
        panel:Destroy()
    end
end

function Start()
    if dialog then return end
    local frame = GetFrame(0)
    local panel = Group(frame, 'GapWaitingPlayers')
    dialog = panel
    panel.started = GetSystemTimeSeconds()
    panel.lastRefresh = -1
    panel.roster = false
    panel.Width:Set(400)
    panel.Height:Set(76)
    LayoutHelpers.AtCenterIn(panel, frame)
    panel.Depth:Set(frame:GetTopmostDepth() + 100)
    GamePanel.Frame(panel)
    local title = UIUtil.CreateText(panel, LOC('<LOC gamemain_0001>Waiting For Other Players...'), 16, UIUtil.titleFont)
    title:SetColor('FFCCCCCC')
    LayoutHelpers.AtTopIn(title, panel, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, panel)
    panel.elapsed = UIUtil.CreateText(panel, '', 12, UIUtil.bodyFont)
    panel.elapsed:SetColor('FFAAAAAA')
    LayoutHelpers.Below(panel.elapsed, title, 4)
    LayoutHelpers.AtHorizontalCenterIn(panel.elapsed, panel)
    panel.OnDestroy = function(self)
        if dialog == self then dialog = false end
    end
    Update(true)
end

function GetDialog()
    return dialog
end
