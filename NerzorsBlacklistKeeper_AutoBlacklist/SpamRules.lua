local _, addon = ...

-- Treat adjacent non-ASCII letters as word bytes for Latin and Cyrillic rules.
-- CJK packs search for whole phrases inside unsegmented text instead.
local wordCharacters = "a-z0-9\128-\255"
local wordStart = "%f[" .. wordCharacters .. "]"
local wordEnd = "%f[^" .. wordCharacters .. "]"
local messageStart = "^[^" .. wordCharacters .. "]*"
local prices = { "%d[%d.,]*%s*k", "%d[%d.,]*%s*g" }
local priceAfterService = "[%]%s]*[:=]%s*%d[%d.,]*%s*[kmg]"
local mythicKey = "m%+%s*%d+"
local pricedBoosts = {
    wordStart .. mythicKey .. priceAfterService .. wordEnd,
    wordStart .. "%d+x%s*" .. mythicKey .. priceAfterService .. wordEnd,
}
local pricedLevels = wordStart .. "afk%s+%d+%s*%-%s*%d+" .. priceAfterService .. wordEnd

local function appendPatterns(target, patterns, prefix, suffix)
    if not patterns then return end
    for _, pattern in ipairs(patterns) do
        target[#target + 1] = prefix .. pattern .. suffix
    end
end

local function findSignal(text, patterns)
    for _, pattern in ipairs(patterns) do
        local hit = text:match(pattern)
        if hit then return hit end
    end
end

function addon.NewAdvertisementMatcher(settings)
    local rules = { offers = {}, leveling = {}, boosting = {}, terms = {}, payment = {} }
    local requests = {}
    appendPatterns(rules.terms, prices, wordStart, wordEnd)
    for _, language in ipairs(addon.DetectionLanguages) do
        local enabled = settings and settings[language.key]
        if enabled == nil then enabled = language.enabledByDefault end
        if enabled then
            local prefix = language.phrases and "" or wordStart
            local suffix = language.phrases and "" or wordEnd
            for group, patterns in pairs(rules) do
                appendPatterns(patterns, language[group], prefix, suffix)
            end
            appendPatterns(requests, language.requests, messageStart, suffix)
        end
    end
    appendPatterns(rules.boosting, { mythicKey }, wordStart, wordEnd)

    return function(text)
        if findSignal(text, requests) then return nil end

        local offer = findSignal(text, rules.offers)
        if offer then
            local deal = findSignal(text, rules.terms)
            if deal then
                local service = findSignal(text, rules.leveling)
                if service then return { reason = "leveling", offer = offer, service = service, deal = deal } end
                service = findSignal(text, rules.boosting)
                if service then return { reason = "boosting", offer = offer, service = service, deal = deal } end
            end
        end

        -- Some ads skip WTS and just post payment instructions and a price list.
        local payment = findSignal(text, rules.payment)
        if not payment then return nil end
        local item = findSignal(text, pricedBoosts)
        if item then return { reason = "boosting", offer = payment, service = item } end
        item = text:match(pricedLevels)
        if item then return { reason = "leveling", offer = payment, service = item } end
    end
end
