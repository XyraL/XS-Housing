Seasons = { current = nil }

function Seasons.List()
    local out = {}
    for _, s in ipairs((Config.Seasons or {}).list or {}) do
        if type(s) == 'table' and type(s.id) == 'string' then out[#out + 1] = { id = s.id, label = s.label or s.id, from = s.from, to = s.to } end
    end
    return out
end

local function dayOf(text)
    local m, d = tostring(text or ''):match('^(%d%d?)%-(%d%d?)$')
    m, d = tonumber(m), tonumber(d)
    if not m or not d then return nil end
    return m * 100 + d
end

function Seasons.ByDate(month, day)
    local today = month * 100 + day
    for _, s in ipairs(Seasons.List()) do
        local from, to = dayOf(s.from), dayOf(s.to)
        if from and to then
            if from <= to and today >= from and today <= to then return s.id end
            if from > to and (today >= from or today <= to) then return s.id end
        end
    end
    return nil
end

function Seasons.Resolve(now)
    local mode = (Config.Seasons or {}).active or 'auto'
    if mode == 'none' or mode == '' then return nil end
    if mode ~= 'auto' then
        for _, s in ipairs(Seasons.List()) do
            if s.id == mode then return s.id end
        end
        return nil
    end
    local t = os.date('*t', now or os.time())
    return Seasons.ByDate(t.month, t.day)
end

function Seasons.Label(id)
    for _, s in ipairs(Seasons.List()) do
        if s.id == id then return s.label end
    end
    return nil
end

function Seasons.Refresh()
    local now = Seasons.Resolve()
    local hide = (Config.Seasons or {}).hideOffSeason ~= false
    if now == Seasons.current and GlobalState.xshSeasonHide == hide then return false end
    Seasons.current = now
    GlobalState.xshSeason = now or false
    GlobalState.xshSeasonHide = hide
    TriggerClientEvent('XS-Housing:client:catalogue', -1, Furniture.Live())
    return true
end

CreateThread(function()
    Seasons.current = Seasons.Resolve()
    GlobalState.xshSeason = Seasons.current or false
    GlobalState.xshSeasonHide = (Config.Seasons or {}).hideOffSeason ~= false
    while true do
        Wait(15000)
        pcall(Seasons.Refresh)
    end
end)
