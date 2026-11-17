local addonName, addon = ...
local NBK = _G.NBK
local MODULE_KEY = "AutoBlacklist"
-- CHAT_MSG_CHANNEL arg7 is the built-in channel ID, independent of the /n slot.
local TRADE_SERVICES_CHANNEL_ID = 42
local RECENT_LINE_LIMIT = 128
local HIT_LIMIT = 10
local filteredEvents = {
    CHAT_MSG_CHANNEL = "public", CHAT_MSG_SAY = "public", CHAT_MSG_YELL = "public",
    CHAT_MSG_WHISPER = "hideWhispers",
    CHAT_MSG_PARTY = "hideGroup", CHAT_MSG_PARTY_LEADER = "hideGroup",
    CHAT_MSG_RAID = "hideGroup", CHAT_MSG_RAID_LEADER = "hideGroup", CHAT_MSG_RAID_WARNING = "hideGroup",
    CHAT_MSG_INSTANCE_CHAT = "hideGroup", CHAT_MSG_INSTANCE_CHAT_LEADER = "hideGroup",
    CHAT_MSG_GUILD = "hideGuild", CHAT_MSG_OFFICER = "hideGuild",
}

local reasonLabels = {
    boosting = "AutoBlacklist: Boosting advertisement",
    leveling = "AutoBlacklist: Leveling advertisement",
    repetition = "AutoBlacklist: Repetition (%d in 60 seconds)",
}

NBK:RegisterLocaleStrings("enUS", {
    ["AutoBlacklist"] = "AutoBlacklist",
    ["AutoBlacklist: Enable sender diagnostics"] = "Enable sender diagnostics",
    ["AutoBlacklist: Enable sender diagnostics in NBK settings first."] = "AutoBlacklist: Enable sender diagnostics in NBK settings first.",
    ["AutoBlacklist: Waiting for a public chat message."] = "AutoBlacklist: Waiting for a public chat message.",
    ["AutoBlacklist: %s → %s (server: %s, key: %s)"] = "AutoBlacklist: %s → %s (server: %s, key: %s)",
    ["AutoBlacklist: Cannot resolve sender %s."] = "AutoBlacklist: Cannot resolve sender %s.",
    ["AutoBlacklist: Include Trade (Services)"] = "Include Trade (Services)",
    ["AutoBlacklist: Include my messages in TradeTest"] = "Include my messages in TradeTest",
    ["AutoBlacklist: Own test message included."] = "AutoBlacklist: Own test message included.",
    ["AutoBlacklist: Channel %s (ID: %s), line %d, observed: %d"] = "AutoBlacklist: Channel %s (ID: %s), line %d, observed: %d",
    ["AutoBlacklist: Original: %s"] = "Original: %s",
    ["AutoBlacklist: Normalized: %s"] = "Normalized: %s",
    ["AutoBlacklist: Boosting advertisement"] = "Boosting advertisement",
    ["AutoBlacklist: Leveling advertisement"] = "Leveling advertisement",
    ["AutoBlacklist: Repetition (%d in 60 seconds)"] = "Repetition (%d in 60 seconds)",
    ["AutoBlacklist: No match."] = "AutoBlacklist: No match.",
    ["AutoBlacklist: Match: %s"] = "AutoBlacklist: Match: %s",
    ["AutoBlacklist: Matched signals: %s"] = "AutoBlacklist: Matched signals: %s",
    ["AutoBlacklist: No matches in this session."] = "AutoBlacklist: No matches in this session.",
    ["AutoBlacklist: Line %d [%s] %s: %s"] = "AutoBlacklist: Line %d [%s] %s: %s",
    ["AutoBlacklist: Enable Auto-Hide"] = "Enable Auto-Hide",
    ["AutoBlacklist: Detection languages"] = "Detection languages",
    ["AutoBlacklist: Hide blocked senders in whispers"] = "Hide blocked senders in whispers",
    ["AutoBlacklist: Hide blocked senders in group chat"] = "Hide blocked senders in group chat",
    ["AutoBlacklist: Hide blocked senders in guild chat"] = "Hide blocked senders in guild chat",
    ["AutoBlacklist: Local sender rules"] = "Local sender rules",
    ["AutoBlacklist: No local sender rules"] = "No local sender rules",
    ["AutoBlacklist: Unblock"] = "Unblock",
    ["AutoBlacklist: Remove exception"] = "Remove exception",
    ["AutoBlacklist: Exception"] = "Exception",
    ["AutoBlacklist: Message hidden."] = "AutoBlacklist: Message hidden.",
    ["AutoBlacklist: Sender blocked."] = "AutoBlacklist: Sender blocked.",
    ["AutoBlacklist: Hidden by sender block."] = "AutoBlacklist: Hidden by sender block.",
    ["AutoBlacklist: TradeTest blocks and pending hits cleared."] = "AutoBlacklist: TradeTest blocks and pending hits cleared.",
}, true)

NBK:RegisterLocaleStrings("deDE", {
    ["AutoBlacklist"] = "AutoBlacklist",
    ["AutoBlacklist: Enable sender diagnostics"] = "Absenderdiagnose aktivieren",
    ["AutoBlacklist: Enable sender diagnostics in NBK settings first."] = "AutoBlacklist: Aktiviere zuerst die Absenderdiagnose in den NBK-Einstellungen.",
    ["AutoBlacklist: Waiting for a public chat message."] = "AutoBlacklist: Warte auf eine öffentliche Chatnachricht.",
    ["AutoBlacklist: %s → %s (server: %s, key: %s)"] = "AutoBlacklist: %s → %s (Server: %s, Schlüssel: %s)",
    ["AutoBlacklist: Cannot resolve sender %s."] = "AutoBlacklist: Absender %s konnte nicht aufgelöst werden.",
    ["AutoBlacklist: Include Trade (Services)"] = "Handel (Dienste) einbeziehen",
    ["AutoBlacklist: Include my messages in TradeTest"] = "Eigene Nachrichten in TradeTest erfassen",
    ["AutoBlacklist: Own test message included."] = "AutoBlacklist: Eigene Testnachricht erfasst.",
    ["AutoBlacklist: Channel %s (ID: %s), line %d, observed: %d"] = "AutoBlacklist: Kanal %s (ID: %s), Zeile %d, erfasst: %d",
    ["AutoBlacklist: Original: %s"] = "Original: %s",
    ["AutoBlacklist: Normalized: %s"] = "Normalisiert: %s",
    ["AutoBlacklist: Boosting advertisement"] = "Boosting-Werbung",
    ["AutoBlacklist: Leveling advertisement"] = "Levelservice-Werbung",
    ["AutoBlacklist: Repetition (%d in 60 seconds)"] = "Wiederholung (%d in 60 Sekunden)",
    ["AutoBlacklist: No match."] = "AutoBlacklist: Kein Treffer.",
    ["AutoBlacklist: Match: %s"] = "AutoBlacklist: Treffer: %s",
    ["AutoBlacklist: Matched signals: %s"] = "AutoBlacklist: Erkannte Signale: %s",
    ["AutoBlacklist: No matches in this session."] = "AutoBlacklist: Keine Treffer in dieser Sitzung.",
    ["AutoBlacklist: Line %d [%s] %s: %s"] = "AutoBlacklist: Zeile %d [%s] %s: %s",
    ["AutoBlacklist: Enable Auto-Hide"] = "Auto-Hide aktivieren",
    ["AutoBlacklist: Detection languages"] = "Erkennungssprachen",
    ["AutoBlacklist: Hide blocked senders in whispers"] = "Gesperrte Absender im Flüsterchat ausblenden",
    ["AutoBlacklist: Hide blocked senders in group chat"] = "Gesperrte Absender im Gruppenchat ausblenden",
    ["AutoBlacklist: Hide blocked senders in guild chat"] = "Gesperrte Absender im Gildenchat ausblenden",
    ["AutoBlacklist: Local sender rules"] = "Lokale Sperren und Ausnahmen",
    ["AutoBlacklist: No local sender rules"] = "Keine lokalen Sperren oder Ausnahmen",
    ["AutoBlacklist: Unblock"] = "Freigeben",
    ["AutoBlacklist: Remove exception"] = "Ausnahme entfernen",
    ["AutoBlacklist: Exception"] = "Ausnahme",
    ["AutoBlacklist: Message hidden."] = "AutoBlacklist: Nachricht ausgeblendet.",
    ["AutoBlacklist: Sender blocked."] = "AutoBlacklist: Absender gesperrt.",
    ["AutoBlacklist: Hidden by sender block."] = "AutoBlacklist: Durch Absendersperre ausgeblendet.",
    ["AutoBlacklist: TradeTest blocks and pending hits cleared."] = "AutoBlacklist: TradeTest-Sperren und offene Treffer zurückgesetzt.",
})

local defaultDetectionLanguages = {}
for _, language in ipairs(addon.DetectionLanguages) do
    defaultDetectionLanguages[language.key] = language.enabledByDefault == true
end

NBK:RegisterAddonDB({
    addonName = addonName,
    key = MODULE_KEY,
    svName = "NerzorsBlacklistKeeperAutoBlacklistDB",
    version = 1,
    defaults = {
        senderDiagnostics = false, includeTradeServices = false, testOwnTradeTestMessages = false,
        autoHide = false, hideWhispers = false, hideGroup = false, hideGuild = false,
        blocks = {}, exceptions = {}, testBlocks = {},
        detectionLanguages = defaultDetectionLanguages,
    },
})

local lastLine
local recentLines, lineDecisions = {}, {}
local nextSlot, observedCount = 1, 0
local hits = {}
local trackRepetition = addon.NewRepetitionTracker()
local trackTestRepetition = addon.NewRepetitionTracker()
local trackAdvertisement = addon.NewAdvertisementTracker()
local trackTestAdvertisement = addon.NewAdvertisementTracker()
local matchAdvertisement
local refreshSenderList

local function resetObservation()
    lastLine = nil
    observedCount = 0
    hits = {}
end

local function rememberDecision(lineKey, hidden)
    if not lineKey then return end
    local previous = recentLines[nextSlot]
    if previous then lineDecisions[previous] = nil end
    recentLines[nextSlot] = lineKey
    lineDecisions[lineKey] = hidden
    nextSlot = nextSlot % RECENT_LINE_LIMIT + 1
end

local function isOwnMessage(key, senderGUID)
    if addon.IsReadableString(senderGUID) then
        local playerGUID = UnitGUID("player")
        if addon.IsReadableString(playerGUID) then return senderGUID == playerGUID end
    end
    return key ~= nil and key == addon.ResolveChatSender(NBK:PlayerFullName())
end

-- Chat filter callbacks can repeat for the same chat line in multiple frames.
local function filterLine(_, event, text, sender, ...)
    local db = NBK:GetAddonDB(MODULE_KEY)
    if not db then return false end
    local isChannel = event == "CHAT_MSG_CHANNEL"
    local diagnostics = db.senderDiagnostics and isChannel
    local scope = filteredEvents[event]
    local autoHide = db.autoHide and (scope == "public" or db[scope])
    if not autoHide and not diagnostics then return false end

    local zoneChannelID, _, channelName, _, lineID, senderGUID = select(5, ...)
    if issecretvalue and issecretvalue(lineID) then lineID = nil end
    local lineKey = type(lineID) == "number" and lineID > 0 and (event .. ":" .. lineID) or nil
    local cached = lineDecisions[lineKey]
    if cached ~= nil then return cached end
    if isChannel then
        if issecretvalue and issecretvalue(zoneChannelID) then return false end
        if zoneChannelID == TRADE_SERVICES_CHANNEL_ID and not db.includeTradeServices then return false end
    end
    if not addon.IsReadableString(sender) then return false end

    local key, name, realm = addon.ResolveChatSender(sender)
    local ownMessage = isOwnMessage(key, senderGUID)
    local testChannel = isChannel and db.testOwnTradeTestMessages and zoneChannelID == 0
        and addon.IsReadableString(channelName) and channelName:lower() == "tradetest"
    if ownMessage and not testChannel then return false end

    local ownTestMessage = ownMessage and testChannel
    local blocks = ownTestMessage and db.testBlocks or db.blocks
    local excepted = not ownTestMessage and db.exceptions[key] ~= nil
    local wasBlocked = autoHide and not excepted and blocks[key] ~= nil
    local hidden, newBlock = wasBlocked == true, false
    local normalized, match

    if not wasBlocked then
        if not isChannel or not lineKey or not addon.IsReadableString(text) then return false end
        normalized = addon.NormalizeChatText(text)
        if key and normalized ~= "" then
            local now = GetTime()
            local repeatTracker = ownTestMessage and trackTestRepetition or trackRepetition
            local repetition = repeatTracker(key, normalized, now)
            if not matchAdvertisement then
                matchAdvertisement = addon.NewAdvertisementMatcher(db.detectionLanguages)
            end
            local advertisement = matchAdvertisement(normalized)
            match = advertisement or repetition
            if autoHide and not excepted and match then
                hidden = true
                local track = ownTestMessage and trackTestAdvertisement or trackAdvertisement
                if advertisement and track(key, now) then
                    blocks[key] = { name = name, realm = realm, reason = match.reason, addedAt = time() }
                    newBlock = true
                end
            end
        end
    end

    rememberDecision(lineKey, hidden)
    if diagnostics and lineKey then
        if key and (wasBlocked or normalized ~= "") then observedCount = observedCount + 1 end
        lastLine = {
            sender = sender, key = key, name = name, realm = realm,
            text = normalized and text, normalized = normalized,
            id = lineID, channelID = zoneChannelID,
            channelName = addon.IsReadableString(channelName) and channelName or "-",
            ownTestMessage = ownTestMessage, match = match,
            hidden = hidden, newBlock = newBlock, wasBlocked = wasBlocked,
        }
        if match then
            table.insert(hits, 1, { id = lineID, sender = sender, channelName = lastLine.channelName, match = match })
            if #hits > HIT_LIMIT then table.remove(hits) end
        end
    end
    if newBlock and not ownTestMessage and refreshSenderList then
        C_Timer.After(0, refreshSenderList)
    end
    return hidden
end

local function escapeChatMarkup(text)
    return (text:gsub("|", "||"))
end

local function describeMatch(match)
    local label = NBK.L[reasonLabels[match.reason]]
    if match.count then return label:format(match.count) end
    return label
end

local function printHits()
    local L = NBK.L
    if #hits == 0 then
        NBK:Print(L["AutoBlacklist: No matches in this session."])
        return
    end
    for _, hit in ipairs(hits) do
        NBK:Print(L["AutoBlacklist: Line %d [%s] %s: %s"]:format(hit.id, hit.channelName, hit.sender, describeMatch(hit.match)))
    end
end

local function printLine(arguments)
    local db = NBK:GetAddonDB(MODULE_KEY)
    local L = NBK.L
    if db and arguments and arguments:match("^%s*resettest%s*$") then
        db.testBlocks = {}
        trackTestAdvertisement = addon.NewAdvertisementTracker()
        trackTestRepetition = addon.NewRepetitionTracker()
        resetObservation()
        NBK:Print(L["AutoBlacklist: TradeTest blocks and pending hits cleared."])
        return
    end
    if not db or not db.senderDiagnostics then
        NBK:Print(L["AutoBlacklist: Enable sender diagnostics in NBK settings first."])
        return
    end
    if arguments and arguments:match("^%s*hits%s*$") then
        printHits()
        return
    end
    local line = lastLine
    if not line then
        NBK:Print(L["AutoBlacklist: Waiting for a public chat message."])
        return
    end

    if line.key then
        NBK:Print(L["AutoBlacklist: %s → %s (server: %s, key: %s)"]:format(line.sender, line.name, line.realm, line.key))
    else
        NBK:Print(L["AutoBlacklist: Cannot resolve sender %s."]:format(line.sender))
    end
    NBK:Print(L["AutoBlacklist: Channel %s (ID: %s), line %d, observed: %d"]
        :format(line.channelName, tostring(line.channelID or "-"), line.id, observedCount))
    if line.ownTestMessage then
        NBK:Print(L["AutoBlacklist: Own test message included."])
    end
    if line.wasBlocked then
        NBK:Print(L["AutoBlacklist: Hidden by sender block."])
        return
    end
    if line.hidden then
        NBK:Print(line.newBlock and L["AutoBlacklist: Sender blocked."] or L["AutoBlacklist: Message hidden."])
    end
    NBK:Print(L["AutoBlacklist: Original: %s"]:format(escapeChatMarkup(line.text)))
    NBK:Print(L["AutoBlacklist: Normalized: %s"]:format(escapeChatMarkup(line.normalized)))
    local match = line.match
    if not match then
        NBK:Print(L["AutoBlacklist: No match."])
        return
    end
    NBK:Print(L["AutoBlacklist: Match: %s"]:format(describeMatch(match)))
    if match.offer then
        local signals = table.concat({ match.offer, match.service, match.deal }, " / ")
        NBK:Print(L["AutoBlacklist: Matched signals: %s"]:format(escapeChatMarkup(signals)))
    end
end

local function buildSenderList(panel, y, db, NUL)
    local L = NBK.L
    local title = NUL:CreateLabel(panel, { text = L["AutoBlacklist: Local sender rules"] })
    title:SetPoint("TOPLEFT", 0, y)
    local list, refresh
    list = NUL:ScrollList(panel, {
        rowHeight = 30,
        emptyText = L["AutoBlacklist: No local sender rules"],
        rowBuilder = function(row)
            local label = NUL:CreateLabel(row, { text = "", wrap = false, justifyH = "LEFT" })
            label:SetPoint("LEFT", 6, 0)
            label:SetPoint("RIGHT", -142, 0)
            local button = NUL:Button(row, {
                width = 134, height = 24, fit = false,
                onClick = function()
                    local entry = row.senderRule
                    if entry.exception then
                        db.exceptions[entry.key] = nil
                    elseif db.blocks[entry.key] then
                        db.exceptions[entry.key] = { name = entry.name, realm = entry.realm }
                        db.blocks[entry.key] = nil
                    end
                    refresh()
                end,
            })
            button:SetPoint("RIGHT", -4, 0)
            return function(r, entry)
                r.senderRule = entry
                local reason = entry.exception and L["AutoBlacklist: Exception"] or L[reasonLabels[entry.reason]]
                label:SetText(escapeChatMarkup(entry.name .. "-" .. entry.realm) .. " · " .. reason)
                button.label:SetText(entry.exception and L["AutoBlacklist: Remove exception"] or L["AutoBlacklist: Unblock"])
            end
        end,
    })
    list.container:SetPoint("TOPLEFT", 0, y - 20)
    list.container:SetPoint("TOPRIGHT", 0, y - 20)
    list.container:SetHeight(142)

    refresh = function()
        local entries = {}
        for key, entry in pairs(db.blocks) do
            entries[#entries + 1] = { key = key, name = entry.name, realm = entry.realm, reason = entry.reason }
        end
        for key, entry in pairs(db.exceptions) do
            entries[#entries + 1] = { key = key, name = entry.name, realm = entry.realm, exception = true }
        end
        table.sort(entries, function(a, b) return a.key < b.key end)
        list:SetData(entries)
    end
    panel:HookScript("OnShow", refresh)
    refreshSenderList = function()
        if panel:IsVisible() then refresh() end
    end
    refresh()
end

local function buildLanguageOptions(panel, y, db, NUL)
    local label = NUL:CreateLabel(panel, { text = NBK.L["AutoBlacklist: Detection languages"] })
    label:SetPoint("TOPLEFT", 0, y)
    y = y - 24

    for index, language in ipairs(addon.DetectionLanguages) do
        local key = language.key
        local checkbox = NUL:Checkbox(panel, {
            label = language.label, checked = db.detectionLanguages[key] == true,
            onChange = function(enabled)
                db.detectionLanguages[key] = enabled
                matchAdvertisement = nil
                trackAdvertisement = addon.NewAdvertisementTracker()
                trackTestAdvertisement = addon.NewAdvertisementTracker()
                resetObservation()
            end,
        })
        local column = (index - 1) % 2
        checkbox:SetPoint("TOPLEFT", column * 220, y - math.floor((index - 1) / 2) * 26)
    end
    return y - math.ceil(#addon.DetectionLanguages / 2) * 26
end

local function buildConfigTab(parent)
    local NUL = LibStub("NerzorsUILib-1.0")
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local db = NBK:GetAddonDB(MODULE_KEY)
    local checkbox = NUL:Checkbox(panel, {
        label = NBK.L["AutoBlacklist: Enable sender diagnostics"],
        checked = db.senderDiagnostics == true,
        onChange = function(enabled)
            db.senderDiagnostics = enabled
            if not db.autoHide then
                trackRepetition = addon.NewRepetitionTracker()
                trackTestRepetition = addon.NewRepetitionTracker()
            end
            resetObservation()
        end,
    })
    checkbox:SetPoint("TOPLEFT")

    local services = NUL:Checkbox(panel, {
        label = NBK.L["AutoBlacklist: Include Trade (Services)"],
        checked = db.includeTradeServices == true,
        onChange = function(enabled)
            db.includeTradeServices = enabled
            resetObservation()
        end,
    })
    services:SetPoint("TOPLEFT", 0, -26)

    local testOwnMessages = NUL:Checkbox(panel, {
        label = NBK.L["AutoBlacklist: Include my messages in TradeTest"],
        checked = db.testOwnTradeTestMessages == true,
        onChange = function(enabled)
            db.testOwnTradeTestMessages = enabled
            trackTestAdvertisement = addon.NewAdvertisementTracker()
            trackTestRepetition = addon.NewRepetitionTracker()
            resetObservation()
        end,
    })
    testOwnMessages:SetPoint("TOPLEFT", 0, -52)

    local autoHide = NUL:Checkbox(panel, {
        label = NBK.L["AutoBlacklist: Enable Auto-Hide"],
        checked = db.autoHide == true,
        onChange = function(enabled)
            db.autoHide = enabled
            trackAdvertisement = addon.NewAdvertisementTracker()
            trackTestAdvertisement = addon.NewAdvertisementTracker()
            trackRepetition = addon.NewRepetitionTracker()
            trackTestRepetition = addon.NewRepetitionTracker()
            resetObservation()
        end,
    })
    autoHide:SetPoint("TOPLEFT", 0, -78)

    local channels = {
        { key = "hideWhispers", label = "AutoBlacklist: Hide blocked senders in whispers" },
        { key = "hideGroup", label = "AutoBlacklist: Hide blocked senders in group chat" },
        { key = "hideGuild", label = "AutoBlacklist: Hide blocked senders in guild chat" },
    }
    local y = -104
    for _, option in ipairs(channels) do
        local key = option.key
        local channel = NUL:Checkbox(panel, {
            label = NBK.L[option.label], checked = db[key] == true,
            onChange = function(enabled) db[key] = enabled end,
        })
        channel:SetPoint("TOPLEFT", 0, y)
        y = y - 26
    end
    y = buildLanguageOptions(panel, y - 6, db, NUL)
    local hint = NUL:CreateLabel(panel, { text = "/nbkauto · /nbkauto hits" })
    hint:SetPoint("TOPLEFT", 0, y)
    buildSenderList(panel, y - 30, db, NUL)
    panel.lastY = y - 195
    return panel
end

local module = {}

function module:OnEnable()
    local config = NBK:GetModule("Config")
    config:RegisterTab({
        key = MODULE_KEY,
        labelKey = "AutoBlacklist",
        build = buildConfigTab,
        order = 23,
        category = "modules",
    })

    local addFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
    for event in pairs(filteredEvents) do
        addFilter(event, filterLine)
    end
    SLASH_NBKAUTOBLACKLIST1 = "/nbkauto"
    SlashCmdList.NBKAUTOBLACKLIST = printLine
end

NBK:RegisterModule(MODULE_KEY, module)
