local _, addon = ...

local WINDOW_SECONDS = 60
local MIN_LENGTH = 24
local RECENT_LIMIT = 512

-- Keep a bounded sliding window across senders. Entries are appended in the
-- order in which the chat filter accepts their unique line IDs.
function addon.NewRepetitionTracker()
    local queue, counts = {}, {}
    local head, size = 1, 0

    return function(senderKey, text, now)
        local _, length = text:gsub("[^\128-\191]", "")
        if length < MIN_LENGTH then return nil end

        while size > 0 and (size == RECENT_LIMIT or now - queue[head].time > WINDOW_SECONDS) do
            local key = queue[head].key
            local count = counts[key] - 1
            counts[key] = count > 0 and count or nil
            queue[head] = nil
            head = head % RECENT_LIMIT + 1
            size = size - 1
        end

        local key = senderKey .. "\0" .. text
        queue[(head + size - 1) % RECENT_LIMIT + 1] = { key = key, time = now }
        size = size + 1
        local count = (counts[key] or 0) + 1
        counts[key] = count
        if count >= 3 then return { reason = "repetition", count = count } end
    end
end
