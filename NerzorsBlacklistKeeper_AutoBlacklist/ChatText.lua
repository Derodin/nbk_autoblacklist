local _, addon = ...

local replacements = {
    [" "] = " ", -- no-break space
    [" "] = " ", -- narrow no-break space
    ["　"] = " ", -- ideographic space
    ["–"] = "-",
    ["—"] = "-",
    ["‑"] = "-",
    ["−"] = "-",
    ["。"] = ".",
    ["、"] = ",",
}

-- Lowercase the supported scripts without feeding multibyte UTF-8 to Lua's
-- locale-dependent string.lower. Fold fullwidth ASCII used in CJK chat too.
local upper = "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞŸŒẞАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
local lower = "àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿœßабвгдеёжзийклмнопрстуфхцчшщъыьэюя"
local multibyte = "[\194-\244][\128-\191]+"
local nextLower = lower:gmatch(multibyte)
for char in upper:gmatch(multibyte) do
    replacements[char] = nextLower()
end
for code = 33, 126 do
    local ascii = string.char(code)
    local folded = ascii
    if code >= 65 and code <= 90 then
        folded = string.char(code + 32)
        replacements[ascii] = folded
    end
    local fullwidth = code + 0xFEE0
    replacements[string.char(0xEF, 0x80 + math.floor(fullwidth / 64) % 64, 0x80 + fullwidth % 64)] = folded
end

local function stripMarkup(text)
    local parts = {}
    local cursor = 1
    while true do
        local pipe = text:find("|", cursor, true)
        if not pipe then
            parts[#parts + 1] = text:sub(cursor)
            return table.concat(parts)
        end

        parts[#parts + 1] = text:sub(cursor, pipe - 1)
        local marker = text:sub(pipe + 1, pipe + 1)
        local markupEnd, visibleText
        if marker == "H" then
            markupEnd, visibleText = select(2, text:find("^|H[^|]*|h(.-)|h", pipe))
        elseif marker == "T" or marker == "A" then
            markupEnd = select(2, text:find("^|" .. marker .. "[^|]*|" .. marker:lower(), pipe))
            visibleText = " "
        elseif marker == "c" then
            markupEnd = select(2, text:find("^|c%x%x%x%x%x%x%x%x", pipe))
            if not markupEnd then
                markupEnd = select(2, text:find("^|cn[%w_]+:", pipe))
            end
        elseif marker == "r" or marker == "|" then
            markupEnd = pipe + 1
            if marker == "|" then visibleText = "|" end
        end

        if visibleText and markupEnd then
            parts[#parts + 1] = marker == "H" and stripMarkup(visibleText) or visibleText
        elseif not markupEnd then
            parts[#parts + 1] = "|"
        end
        cursor = (markupEnd or pipe) + 1
    end
end

function addon.NormalizeChatText(text)
    text = stripMarkup(text):gsub("[A-Z\194-\244][\128-\191]*", replacements)
    -- Locale-dependent %s can match a UTF-8 continuation byte on Windows.
    return (text:gsub("[ \t\n\r\f\v]+", " "):match("^ *(.-) *$"))
end
