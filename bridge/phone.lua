Phone = { name = 'none' }

local ORDER = {
    'XS-Phone', 'lb-phone', 'qs-smartphone-pro', 'qs-smartphone', 'npwd', 'gksphone', 'okokPhone',
    'yseries', 'high-phone', 'roadphone', '17mov_Phone', 'qb-phone',
}

local function detect()
    local forced = Config.Bridges and Config.Bridges.phone
    if forced and forced ~= 'auto' then return forced end
    for _, name in ipairs(ORDER) do
        if GetResourceState(name) == 'started' then return name end
    end
    return 'none'
end

Phone.name = detect()

AddEventHandler('onResourceStart', function(resource)
    if Phone.name ~= 'none' then return end
    for _, name in ipairs(ORDER) do
        if name == resource then
            Phone.name = resource
            return
        end
    end
end)

if IsDuplicityVersion() then
    local function app()
        return nil
    end

    local NOTIFY = {
        ['XS-Phone'] = function(src, title, body)
            return exports['XS-Phone']:Notify(src, { app = 'home', title = title, body = body })
        end,
        ['lb-phone'] = function(src, title, body)
            exports['lb-phone']:SendNotification(src, { app = app(), title = title, content = body })
            return true
        end,
        ['qs-smartphone'] = function(src, title, body)
            local ok, sent = pcall(function()
                return exports['qs-smartphone']:sendPhoneNotification(src, { appId = app(), title = title, text = body, closeTimeout = 6000 })
            end)
            if not ok or sent == false then
                TriggerClientEvent('qs-smartphone:client:notify', src, { title = title, text = body, timeout = 6000 })
            end
            return true
        end,
        ['gksphone'] = function(src, title, body)
            exports.gksphone:sendNotification(src, { title = title, message = body, icon = 'fas fa-house', duration = 6000 })
            return true
        end,
        ['okokPhone'] = function(src, title, body)
            exports.okokPhone:notifyDI(src, { title = title, text = body, app = app(), duration = 6000 })
            return true
        end,
        ['yseries'] = function(src, title, body)
            exports.yseries:SendNotification({ app = app() or 'messages', title = title, text = body, timeout = 6000 }, 'source', src)
            return true
        end,
        ['high-phone'] = function(src, title, body)
            exports['high-phone']:sendNotification(src, { title = title, content = body, application = { name = 'Home' }, duration = 6000 })
            return true
        end,
        ['roadphone'] = function(src, title, body)
            TriggerClientEvent('roadphone:sendNotification', src, { apptitle = 'Home', title = title, message = body })
            return true
        end,
        ['17mov_Phone'] = function(src, title, body)
            exports['17mov_Phone']:SendNotificationToSrc(src, { app = 'Home', title = title, message = body })
            return true
        end,
        ['qb-phone'] = function(src, title, body)
            TriggerClientEvent('qb-phone:client:CustomNotification', src, title, body, 'fas fa-house', '#2dd4bf', 6000)
            return true
        end,
        ['qs-smartphone-pro'] = function(src, title, body)
            TriggerClientEvent('XS-Housing:client:phoneNotify', src, title, body)
            return true
        end,
        ['npwd'] = function(src, title, body)
            TriggerClientEvent('XS-Housing:client:phoneNotify', src, title, body)
            return true
        end,
    }

    function Phone.Notify(src, title, body)
        if not src or src <= 0 then return end
        if Config.Phone and Config.Phone.notify == false then
            Framework.Notify(src, ('%s: %s'):format(title, body), 'inform')
            return
        end
        local send = NOTIFY[Phone.name]

        if send then
            local ok, sent = pcall(send, src, title, body)
            if ok and sent ~= false then return end
            if Config.Debug and not ok then
                print(('^1[XS-Housing]^0 %s notification failed: %s'):format(Phone.name, tostring(sent)))
            end
        end

        Framework.Notify(src, ('%s: %s'):format(title, body), 'inform')
    end
end

if not IsDuplicityVersion() then
    RegisterNetEvent('XS-Housing:client:phoneNotify', function(title, body)
        if Phone.name == 'qs-smartphone-pro' then
            local ok = pcall(function() exports['qs-smartphone-pro']:SendTempNotification({ title = title, text = body, app = 'settings', timeout = 6000 }) end)
            if ok then return end
        elseif Phone.name == 'npwd' then
            local ok = pcall(function() exports.npwd:createNotification({ notisId = 'xs-housing', appId = 'HOME', content = body, secondaryTitle = title, keepOpen = false, duration = 6000 }) end)
            if ok then return end
        end
        lib.notify({ title = title, description = body, type = 'inform' })
    end)
end
