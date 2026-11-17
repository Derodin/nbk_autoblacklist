local _, addon = ...
local NBK = _G.NBK

-- The interface check also covers Forever builds without a Camelot project ID.
local isForever = NBK:IsForever() or select(4, GetBuildInfo()) == 16001

function addon.IsReadableString(value)
    return not (issecretvalue and issecretvalue(value))
        and type(value) == "string" and value:find("%S") ~= nil
end

function addon.ResolveChatSender(sender)
    if not addon.IsReadableString(sender) then return nil end

    local name, suffix = strsplit("-", sender, 2)
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return nil end

    local realm = suffix and suffix:match("^%s*(.-)%s*$")
    if realm == "" then realm = nil end

    if isForever then
        -- In Camelot a hyphen may separate two character names. The technical
        -- server identifier contains digits and stays in the realm slot.
        if realm and not realm:find("%d") then
            name = name .. " " .. realm
            realm = nil
        end
        name = name:gsub("%s+", " ")
        if not name:find(" ", 1, true) then return nil end
    end

    if not realm then
        realm = GetNormalizedRealmName and GetNormalizedRealmName()
        if not realm or realm == "" then
            realm = GetRealmName and GetRealmName()
        end
    end
    if not realm or not realm:find("%S") then return nil end

    return NBK:NormalizeKey(name, realm)
end
