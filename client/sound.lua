Sound = { sources = {}, sent = {} }

function Sound.Set(name, src)
    if type(src) == 'table' and type(src.url) == 'string' and src.url ~= '' then
        Sound.sources[name] = src
    else
        Sound.sources[name] = nil
    end
end

function Sound.Get(name)
    return Sound.sources[name]
end

function Sound.Falloff(dist, range)
    if dist >= range then return 0.0 end
    local t = 1.0 - dist / range
    return t * t
end

local function stop(name)
    if not Sound.sent[name] then return end
    Sound.sent[name] = nil
    UI.Send('sound', 'stop', { name = name })
end

local function tick()
    local pos = GetEntityCoords(PlayerPedId())
    local now = Util.Now()
    local paused = IsPauseMenuActive()
    for name, src in pairs(Sound.sources) do
        local range = src.range or 20.0
        local at = src.pos
        local dist = at and #(pos - vector3(at.x + 0.0, at.y + 0.0, at.z + 0.0)) or 0.0
        local vol = paused and 0.0 or (src.volume or 0.5) * Sound.Falloff(dist, range)
        local sent = Sound.sent[name]
        local paused = src.paused == true
        if dist > range + 15.0 then
            stop(name)
        elseif not sent or sent.url ~= src.url or sent.at ~= src.at or sent.paused ~= paused or (paused and sent.offset ~= src.offset) then
            local offset = paused and (tonumber(src.offset) or 0) or (src.at and math.max(0, now - src.at) or 0)
            UI.Send('sound', 'play', { name = name, url = src.url, at = src.at or 0, paused = paused, offset = offset, volume = vol })
            Sound.sent[name] = { url = src.url, at = src.at, paused = paused, offset = src.offset, volume = vol }
        elseif math.abs(sent.volume - vol) > 0.01 then
            UI.Send('sound', 'volume', { name = name, volume = vol })
            sent.volume = vol
        end
    end
    for name in pairs(Sound.sent) do
        if not Sound.sources[name] then stop(name) end
    end
end

CreateThread(function()
    while true do
        local ok, err = pcall(tick)
        if not ok then print(('^1[XS-Housing]^0 sound failed: %s'):format(tostring(err))) end
        Wait(next(Sound.sources) and 200 or 1000)
    end
end)
