local _, addon = ...

local STRIKE_WINDOW = 600

function addon.NewAdvertisementTracker()
    local firstHits = {}
    local nextCleanup = 0

    return function(key, now)
        if now >= nextCleanup then
            for sender, firstHit in pairs(firstHits) do
                if now - firstHit > STRIKE_WINDOW then firstHits[sender] = nil end
            end
            nextCleanup = now + STRIKE_WINDOW
        end

        local firstHit = firstHits[key]
        if firstHit and now - firstHit <= STRIKE_WINDOW then
            firstHits[key] = nil
            return true
        end
        firstHits[key] = now
        return false
    end
end
