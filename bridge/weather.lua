Weather = { name = nil, paused = false }

if IsDuplicityVersion() or not Config then return end

local ORDER = { 'Renewed-Weathersync', 'qb-weathersync', 'cd_easytime' }

local function detect()
    local forced = Config.Bridges and Config.Bridges.weather or 'auto'
    if forced == 'none' then return nil end
    if forced ~= 'auto' then return forced end
    for _, name in ipairs(ORDER) do
        if GetResourceState(name) == 'started' then return name end
    end
    return nil
end

local function syncScripts(on)
    local name = detect()
    Weather.name = name
    if name == 'Renewed-Weathersync' then
        LocalPlayer.state:set('syncWeather', on, false)
    elseif name == 'qb-weathersync' then
        TriggerEvent(on and 'qb-weathersync:client:EnableSync' or 'qb-weathersync:client:DisableSync')
    elseif name == 'cd_easytime' then
        TriggerEvent('cd_easytime:PauseSync', not on)
    end
end

function Weather.Freeze()
    local I = Config.Interiors
    if not I.freezeTime and not I.freezeWeather then return end
    Weather.paused = true
    syncScripts(false)
    CreateThread(function()
        while Weather.paused do
            if I.freezeWeather then
                SetWeatherTypeNowPersist(I.weather or 'EXTRASUNNY')
                SetWeatherTypeNow(I.weather or 'EXTRASUNNY')
                SetOverrideWeather(I.weather or 'EXTRASUNNY')
                SetRainLevel(0.0)
            end
            if I.freezeTime then NetworkOverrideClockTime(I.hour or 13, 0, 0) end
            Wait(1000)
        end
    end)
end

function Weather.Resume()
    if not Weather.paused then return end
    Weather.paused = false
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetRainLevel(-1.0)
    NetworkClearClockTimeOverride()
    syncScripts(true)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Weather.Resume() end
end)
