-- Local outgoing chat wording policy shared by lobby and game chat.
-- Keeps gaf-chat's whole-word/case rules, plus local obfuscation.
-- Outgoing: FAF/фаф is always replaced. Profanity masking is incoming-only and
-- gated by the "Цензура" Interface option.
local Prefs = import and import("/lua/user/prefs.lua") or nil
local censorshipEnabled = true

local function refreshCensorship()
    if not Prefs then return end
    local value = Prefs.GetOption('chat_censorship')
    censorshipEnabled = value ~= false and value ~= 'false'
end

local replacements = {
    [''] = 'другой сервер',
    ['а'] = 'другого сервера',
    ['у'] = 'другому серверу',
    ['е'] = 'другом сервере',
    ['ом'] = 'другим сервером',
    ['ы'] = 'другие серверы',
    ['ов'] = 'других серверов',
    ['ам'] = 'другим серверам',
    ['ами'] = 'другими серверами',
    ['ах'] = 'других серверах',
}
local endings = { 'ами', 'ам', 'ах', 'ом', 'ов', 'а', 'у', 'е', 'ы', '' }
local canonicalEndings = {
    ['ами'] = 'ami', ['ам'] = 'am', ['ах'] = 'ah', ['ом'] = 'om', ['ов'] = 'ov',
    ['а'] = 'a', ['у'] = 'u', ['е'] = 'e', ['ы'] = 'y', [''] = '',
}
-- Canonical Latin roots (see canonicalize) compiled from open Russian
-- profanity/insult dictionaries: Wikipedia "Русский мат", russki-mat.net,
-- Wiktionary "Russian swear words" and the public multi-storey mat dictionary.
local profanityRoots = {
    -- хуй / нахуй / похуй / охуеть
    'huy', 'hue', 'huyo', 'huli', 'hyy', 'nah', 'poh', 'doh', 'ohu', 'ahu',
    -- пизда / пиздец / обходы
    'pizd', 'pezd', 'pzdc', 'pied',
    -- ебать / ёб / заебал / уебать / ибаный / епаный
    'ebat', 'ebal', 'eban', 'ebu', 'ebi', 'ebl', 'ebly', 'ebun', 'ebash',
    'eby', 'ebos', 'ebanat', 'yob', 'iban', 'ipat', 'epat', 'epan',
    'zaeb', 'zayob', 'zaib', 'zaep', 'naeb', 'ueb', 'uyob', 'doeb', 'proeb',
    'vyeb', 'obeb', 'podeb', 'prieb', 'seb', 'nebich', 'zlyoeb',
    -- блядь
    'blya',
    -- сука / сцука / сучара
    'suka', 'suki', 'suku', 'suky', 'suke', 'suko', 'sukam', 'scuk', 'such',
    'cyka', 'syka',
    -- гнида / гавно / гандон / манда / залупа / дрочить / минет
    'gnid', 'gavn', 'govn', 'gamn', 'gandon', 'gondon', 'mand', 'zalup',
    'droch', 'minet',
    -- мудак / мудоеб
    'mudak', 'mudag', 'mude', 'mudil', 'mudny', 'mudo', 'mudoz', 'dolbo',
    'dolba',
    -- пидор / педераст / пидарас
    'pido', 'pida', 'pidr', 'pede', 'pedi', 'pedr',
    -- сволочь / мразь / подонок / мерзавец / подлец / гадина / скотина
    'svol', 'mraz', 'podon', 'merz', 'podlec', 'gadin', 'skotin',
    -- падла / паскуда / потаскуха / шалава / шлюха / чмо
    'padl', 'paskud', 'potask', 'shalav', 'shlyuh', 'shlyushk', 'chmo',
    -- ублюдок / выродок / отродье / погань / урод / тварь / гнида
    'ublyud', 'vyrod', 'otrod', 'pogan', 'urod', 'tvar',
    -- дурак / дебил / придурок / раздолбай / лох / даун / козёл / осёл
    'durak', 'debil', 'dibil', 'pridur', 'razdol', 'loh', 'loshar',
    'daun', 'kozyol', 'kozel', 'osyol', 'osel', 'pidrila',
    -- гей (как оскорбление) и англоязычные ругательства
    'gey', 'gei', 'gay', 'homo', 'fag', 'fuck', 'fuk', 'fck', 'fkin', 'fack',
    'shit', 'sht', 'bitch', 'cunt', 'dick', 'cock', 'cok', 'pussy', 'pusy',
    'whore', 'asshole', 'ashole', 'motherfucker', 'retard', 'nigger', 'niger',
    'bastard', 'slut',
}
local textCommands = {
    send = true, me = true, plain = true, html = true,
    w = true, whisper = true, private = true, pm = true,
}

local cyrillic = {
    ['\208\176'] = 'a', ['\208\144'] = 'a',
    ['\208\177'] = 'b', ['\208\145'] = 'b',
    ['\208\178'] = 'v', ['\208\146'] = 'v',
    ['\208\179'] = 'g', ['\208\147'] = 'g',
    ['\208\180'] = 'd', ['\208\148'] = 'd',
    ['\208\181'] = 'e', ['\208\149'] = 'e',
    ['\209\145'] = 'yo', ['\208\129'] = 'yo',
    ['\208\182'] = 'zh', ['\208\150'] = 'zh',
    ['\208\183'] = 'z', ['\208\151'] = 'z',
    ['\208\184'] = 'i', ['\208\152'] = 'i',
    ['\208\185'] = 'y', ['\208\153'] = 'y',
    ['\208\186'] = 'k', ['\208\154'] = 'k',
    ['\208\187'] = 'l', ['\208\155'] = 'l',
    ['\208\188'] = 'm', ['\208\156'] = 'm',
    ['\208\189'] = 'n', ['\208\157'] = 'n',
    ['\208\190'] = 'o', ['\208\158'] = 'o',
    ['\208\191'] = 'p', ['\208\159'] = 'p',
    ['\209\128'] = 'r', ['\208\160'] = 'r',
    ['\209\129'] = 's', ['\208\161'] = 's',
    ['\209\130'] = 't', ['\208\162'] = 't',
    ['\209\131'] = 'u', ['\208\163'] = 'u',
    ['\209\132'] = 'f', ['\208\164'] = 'f',
    ['\209\133'] = 'h', ['\208\165'] = 'h',
    ['\209\134'] = 'c', ['\208\166'] = 'c',
    ['\209\135'] = 'ch', ['\208\167'] = 'ch',
    ['\209\136'] = 'sh', ['\208\168'] = 'sh',
    ['\209\137'] = 'sch', ['\208\169'] = 'sch',
    ['\209\138'] = '', ['\208\170'] = '',
    ['\209\139'] = 'y', ['\208\171'] = 'y',
    ['\209\140'] = '', ['\208\172'] = '',
    ['\209\141'] = 'e', ['\208\173'] = 'e',
    ['\209\142'] = 'yu', ['\208\174'] = 'yu',
    ['\209\143'] = 'ya', ['\208\175'] = 'ya',
}

local function isWordByte(byte)
    return byte == 95
        or (byte >= 48 and byte <= 57)
        or (byte >= 65 and byte <= 90)
        or (byte >= 97 and byte <= 122)
        or byte >= 128
end

local function coreBounds(token)
    local length = string.len(token)
    local first, last = nil, nil
    for i = 1, length do
        if isWordByte(string.byte(token, i)) then
            if not first then first = i end
            last = i
        end
    end
    return first, last
end

local function collapseRepeats(text)
    local pieces, i = {}, 1
    local length = string.len(text)
    while i <= length do
        local char = string.sub(text, i, i)
        table.insert(pieces, char)
        local letter = string.find(char, '%a') ~= nil and char ~= 'y'
        while letter and i < length and string.sub(text, i + 1, i + 1) == char do
            i = i + 1
        end
        i = i + 1
    end
    return table.concat(pieces)
end

local function canonicalize(text)
    local pieces, i = {}, 1
    local length = string.len(text)
    while i <= length do
        local byte = string.byte(text, i)
        local nextByte = i < length and string.byte(text, i + 1) or nil
        if (byte == 112 or byte == 80) and (nextByte == 104 or nextByte == 72) then
            table.insert(pieces, 'f')
            i = i + 2
        elseif byte == 52 or byte == 64 then -- 4, @
            table.insert(pieces, 'a')
            i = i + 1
        elseif byte == 48 then -- 0
            table.insert(pieces, 'o')
            i = i + 1
        elseif byte == 51 then -- 3
            table.insert(pieces, 'e')
            i = i + 1
        elseif byte == 49 then -- 1
            table.insert(pieces, 'i')
            i = i + 1
        elseif byte == 54 then -- 6 as б
            table.insert(pieces, 'b')
            i = i + 1
        elseif byte == 120 or byte == 88 then -- x as х
            table.insert(pieces, 'h')
            i = i + 1
        elseif byte == 46 or byte == 95 or byte == 45 then -- . _ -
            i = i + 1
        elseif byte == 194 and nextByte == 173 then -- soft hyphen
            i = i + 2
        elseif byte == 226 then -- Unicode hyphens, zero-width chars, joiners
            i = i + 3
        elseif byte >= 240 then -- emoji and other 4-byte characters
            i = i + 4
        else
            local mapped = cyrillic[string.sub(text, i, i + 1)]
            if mapped then
                table.insert(pieces, mapped)
                i = i + 2
            elseif byte >= 224 then -- keep unknown letters as blockers
                table.insert(pieces, string.sub(text, i, i + 2))
                i = i + 3
            elseif byte >= 192 then -- keep unknown letters as blockers
                table.insert(pieces, string.sub(text, i, i + 1))
                i = i + 2
            elseif byte >= 65 and byte <= 90 then
                table.insert(pieces, string.char(byte + 32))
                i = i + 1
            elseif (byte >= 97 and byte <= 122) or (byte >= 48 and byte <= 57) then
                table.insert(pieces, string.char(byte))
                i = i + 1
            else
                i = i + 1
            end
        end
    end
    local result = table.concat(pieces)
    return collapseRepeats(result)
end

local function fafReplacement(canonical)
    for _, ending in ipairs(endings) do
        if canonical == 'faf' .. canonicalEndings[ending] then
            return replacements[ending]
        end
    end
    return nil
end

local function utf8Length(text)
    local count, i = 0, 1
    local length = string.len(text)
    while i <= length do
        local byte = string.byte(text, i)
        if byte >= 240 then i = i + 4
        elseif byte >= 224 then i = i + 3
        elseif byte >= 192 then i = i + 2
        else i = i + 1 end
        count = count + 1
    end
    return count
end

local function profanityReplacement(canonical, core)
    for _, root in ipairs(profanityRoots) do
        local at = string.find(canonical, root, 1, true)
        if at then
            local previous = at > 1 and string.sub(canonical, at - 1, at - 1) or ''
            if at == 1 or not string.find(previous, '%a') then
                return string.rep('*', utf8Length(core))
            end
        end
    end
    return nil
end

local function replaceToken(token)
    local first, last = coreBounds(token)
    if not first then return token end
    if first > 1 then
        local prefix = string.sub(token, 1, 1)
        if prefix == '@' or prefix == '#' or prefix == '!' then return token end
    end
    local core = string.sub(token, first, last)
    local canonical = canonicalize(core)

    local faf = fafReplacement(canonical)
    if faf then
        return string.sub(token, 1, first - 1) .. faf .. string.sub(token, last + 1)
    end
    if string.find(token, '://', 1, true)
        or string.find(token, 'matrix:', 1, true)
        or string.find(token, 'www.', 1, true)
        or string.find(token, '@', 1, true) then
        return token
    end
    return token
end

-- Incoming chat: mask profanity only, never touch FAF/фаф or markup tokens.
local function maskProfanityToken(token)
    if string.find(token, '[<>]') then return token end
    if string.find(token, '://', 1, true)
        or string.find(token, 'matrix:', 1, true)
        or string.find(token, 'www.', 1, true)
        or string.find(token, '@', 1, true) then
        return token
    end
    local first, last = coreBounds(token)
    if not first then return token end
    if first > 1 then
        local prefix = string.sub(token, 1, 1)
        if prefix == '@' or prefix == '#' or prefix == '!' then return token end
    end
    local core = string.sub(token, first, last)
    local profanity = profanityReplacement(canonicalize(core), core)
    if profanity then
        return string.sub(token, 1, first - 1) .. profanity .. string.sub(token, last + 1)
    end
    return token
end

function MaskProfanity(text)
    if type(text) ~= 'string' then return text end
    refreshCensorship()
    if not censorshipEnabled then return text end
    local result = string.gsub(text, '%S+', maskProfanityToken)
    return result
end

local function skipWhitespace(text, i)
    local textLength = string.len(text)
    while i <= textLength and string.find(string.sub(text, i, i), '%s') do
        i = i + 1
    end
    return i
end

-- import() exports globals defined in the module, not its return value.
function Replace(text)
    if type(text) ~= 'string' then return text end
    if string.sub(text, 1, 2) == '//' then
        return '/' .. string.gsub(string.sub(text, 2), '%S+', replaceToken)
    end
    if string.sub(text, 1, 1) ~= '/' then
        local result = string.gsub(text, '%S+', replaceToken)
        return result
    end
    local textLength = string.len(text)
    local spaceStart = string.find(text, '%s') or (textLength + 1)
    local command = string.lower(string.sub(text, 2, spaceStart - 1))
    if not textCommands[command] then return text end
    local bodyStart = skipWhitespace(text, spaceStart)
    if bodyStart > textLength then return text end
    return string.sub(text, 1, bodyStart - 1)
        .. string.gsub(string.sub(text, bodyStart), '%S+', replaceToken)
end

return { Replace = Replace, MaskProfanity = MaskProfanity }
