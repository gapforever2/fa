-- Display-only selection; neither history nor TrueSkill is changed here.
function Select(player, mods, knownMnbUids)
    local known = {}
    for uid in string.gmatch(knownMnbUids or '', '[^,]+') do
        known[uid] = true
    end
    for uid, enabled in pairs(mods or {}) do
        if enabled and known[uid] then
            return player.PerformanceMnb, player.PerformanceMnbGames or 0, 'M&B EXP'
        end
    end
    return player.Performance, player.PerformanceGames or 0, 'EXP'
end
