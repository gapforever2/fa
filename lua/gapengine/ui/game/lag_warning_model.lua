-- Pure, wall-clock state machine. Ping and an empty command buffer alone do
-- not identify a culprit: use the native wait barrier or a speed limiter.
local Model = {}

function New()
    return setmetatable({pending = {}, alerts = {}, lastGood = false}, {__index = Model})
end

function Model:Reset()
    self.pending = {}
    self.alerts = {}
    self.lastGood = false
    return self.alerts
end

local function Reason(snapshot, client)
    if client.connected == false or not client.ready then return false end
    if client.blocking and (snapshot.kind == 'data' or snapshot.kind == 'ack')
        and ((snapshot.stallMs or 0) >= 800 or (client.behind or 0) >= 10) then
        return snapshot.kind
    end
    local target = math.min(0, snapshot.requestedSpeed or 0)
    if (snapshot.speed or 0) < target and (client.maxSpeed or 0) <= snapshot.speed
        and client.armies and table.getn(client.armies) > 0 then
        return 'sim'
    end
    return false
end

function Model:Update(now, snapshot)
    if not snapshot then
        if self.lastGood and now - self.lastGood <= 2 then return self.alerts end
        return self:Reset()
    end
    if not snapshot.ready or snapshot.replay or snapshot.paused or snapshot.gameOver then return self:Reset() end
    self.lastGood = now
    for index, client in snapshot.clients or {} do
        local reason = Reason(snapshot, client)
        if reason then
            local key = tostring(client.uid or index)
            local pending = self.pending[key]
            if not pending or now - pending.lastSeen > (pending.confirmed and 1.25 or 0.75) then
                pending = {firstSeen = now, confirmed = false}
                self.pending[key] = pending
            end
            pending.lastSeen = now
            pending.client = client
            pending.reason = reason
            if now - pending.firstSeen >= (reason == 'sim' and 4 or 1.5) then pending.confirmed = true end
        end
    end
    local alerts = {}
    for key, pending in self.pending do
        if now - pending.lastSeen > (pending.confirmed and 1.25 or 0.75) then
            self.pending[key] = nil
        elseif pending.confirmed then
            table.insert(alerts, pending)
        end
    end
    table.sort(alerts, function(a, b) return (a.client.index or 0) < (b.client.index or 0) end)
    self.alerts = alerts
    return alerts
end
