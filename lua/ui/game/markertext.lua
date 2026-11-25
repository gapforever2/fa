-- Marker names use the same local display policy as incoming chat. Keep the
-- synced name intact so every viewer can use their own censorship preference.
local Prefs = import('/lua/user/prefs.lua')
local MaskProfanity = import('/lua/ui/chat/autoreplace.lua').MaskProfanity

function Refresh(marker)
    local name = marker.data.Name
    local option = Prefs.GetOption('chat_censorship')
    local enabled = option ~= false and option ~= 'false'
    if marker.displayNameSource == name and marker.displayNameCensorship == enabled then
        return
    end

    marker.Name:SetText(MaskProfanity(name))
    marker.displayNameSource = name
    marker.displayNameCensorship = enabled
end

-- Reuse the marker's existing frame callback. Only check preferences four
-- times a second, and only filter/set text when its name or preference changes.
function OnFrame(marker, deltaTime)
    marker.nameRefreshTime = (marker.nameRefreshTime or 0) + deltaTime
    if marker.nameRefreshTime >= 0.25 then
        marker.nameRefreshTime = 0
        Refresh(marker)
    end
end
