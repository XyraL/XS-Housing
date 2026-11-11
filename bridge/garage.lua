Garage = { name = nil, registered = {} }

if not Config then return end

local ORDER = { 'XS-Garages', 'jg-advancedgarages', 'qbx_garages', 'qb-garages', 'cd_garage', 'okokGarage' }

local function detect()
    local forced = Config.Bridges and Config.Bridges.garage or 'auto'
    if forced == 'none' then return nil end
    if forced ~= 'auto' then return GetResourceState(forced) == 'started' and forced or nil end
    for _, name in ipairs(ORDER) do
        if GetResourceState(name) == 'started' then return name end
    end
    return nil
end

Garage.name = detect()

function Garage.Key(id)
    return ('xsh_%d'):format(id)
end

function Garage.OwnPrompts()
    return Garage.name == 'cd_garage' or Garage.name == 'okokGarage'
end

if IsDuplicityVersion() then
    local function spots(p)
        local out = {}
        for _, s in ipairs(p.data.garage.spots or {}) do out[#out + 1] = s end
        return out
    end

    local function enabled(p)
        return p and p.data.enabled and p.data.garage.enabled and #(p.data.garage.spots or {}) > 0
    end

    local function label(p)
        local l = p.data.garage.label
        if l and l ~= '' then return l end
        return Text('garage_label', { place = p.data.label })
    end

    local function canUse(id)
        return function(src)
            local p = Props.Get(id)
            if not enabled(p) then return false end
            return Access.Can(src, id, 'garage') == true
        end
    end

    local Adapters = {}

    Adapters['jg-advancedgarages'] = {
        register = function(p)
            local s = spots(p)
            local first = s[1]
            local spawns = {}
            for _, sp in ipairs(s) do spawns[#spawns + 1] = vector4(sp.x, sp.y, sp.z, sp.w or 0.0) end
            local opts = {
                id = Garage.Key(p.id), name = label(p), access = canUse(p.id), coords = vector3(first.x, first.y, first.z),
                spawnPoints = spawns, vehicleType = 'car',
            }
            local key = Garage.registered[p.id]
            if key then
                exports['jg-advancedgarages']:updateGarage(key, opts)
            else
                local id, err = exports['jg-advancedgarages']:registerGarage(opts)
                if id then Garage.registered[p.id] = id elseif err then print(('^3[XS-Housing]^0 jg-advancedgarages refused garage %d: %s'):format(p.id, tostring(err))) end
            end
        end,
        unregister = function(p)
            local key = Garage.registered[p.id]
            if key then pcall(function() exports['jg-advancedgarages']:unregisterGarage(key) end) end
            Garage.registered[p.id] = nil
        end,
        refresh = function(p)
            local key = Garage.registered[p.id]
            if key then pcall(function() exports['jg-advancedgarages']:refreshGarageAccess(key) end) end
        end,
    }

    Adapters['XS-Garages'] = {
        register = function(p)
            local points = {}
            for _, sp in ipairs(spots(p)) do
                local v = vector4(sp.x, sp.y, sp.z, sp.w or 0.0)
                points[#points + 1] = { coords = v, spawn = v }
            end
            exports['XS-Garages']:RegisterGarage(Garage.Key(p.id), {
                label = label(p), vehicleType = 'car', accessPoints = points, canAccess = canUse(p.id), shared = p.data.garage.shared == true,
            })
            Garage.registered[p.id] = Garage.Key(p.id)
        end,
        unregister = function(p)
            pcall(function() exports['XS-Garages']:UnregisterGarage(Garage.Key(p.id)) end)
            Garage.registered[p.id] = nil
        end,
        refresh = function() pcall(function() exports['XS-Garages']:RefreshGarages() end) end,
    }

    Adapters['qbx_garages'] = {
        register = function(p)
            local points = {}
            for _, sp in ipairs(spots(p)) do
                local v = vector4(sp.x, sp.y, sp.z, sp.w or 0.0)
                points[#points + 1] = { coords = v, spawn = v }
            end
            exports.qbx_garages:RegisterGarage(Garage.Key(p.id), {
                label = label(p), vehicleType = 'car', accessPoints = points, canAccess = canUse(p.id), shared = p.data.garage.shared == true,
            })
            Garage.registered[p.id] = Garage.Key(p.id)
        end,
        unregister = function(p) Garage.registered[p.id] = nil end,
        refresh = function() end,
    }

    local qbConfig = {}

    local function qbEntry(p)
        local first = spots(p)[1]
        return { label = label(p), takeVehicle = { x = first.x, y = first.y, z = first.z, w = first.w or 0.0 } }
    end

    local function qbPushKeys(id, target)
        local p = Props.Get(id)
        local key = Garage.Key(id)
        local players = target and { target } or Framework.Players()
        for _, src in ipairs(players) do
            local has = enabled(p) and Access.Can(src, id, 'garage') == true
            TriggerClientEvent('qb-garages:client:setHouseGarage', src, key, has)
        end
    end

    Adapters['qb-garages'] = {
        register = function(p)
            qbConfig[Garage.Key(p.id)] = qbEntry(p)
            TriggerClientEvent('qb-garages:client:addHouseGarage', -1, Garage.Key(p.id), qbConfig[Garage.Key(p.id)])
            Garage.registered[p.id] = Garage.Key(p.id)
            qbPushKeys(p.id)
        end,
        unregister = function(p)
            qbConfig[Garage.Key(p.id)] = nil
            Garage.registered[p.id] = nil
            qbPushKeys(p.id)
        end,
        refresh = function(p) qbPushKeys(p.id) end,
        load = function(src)
            for key, entry in pairs(qbConfig) do
                TriggerClientEvent('qb-garages:client:addHouseGarage', src, key, entry)
            end
            for id in pairs(Garage.registered) do qbPushKeys(id, src) end
        end,
    }

    local function adapter()
        return Garage.name and Adapters[Garage.name] or nil
    end

    function Garage.Sync(id)
        local p = Props.Get(id)
        local a = adapter()
        if not a then return end
        local ok, err = pcall(function()
            if enabled(p) then a.register(p) elseif Garage.registered[id] then a.unregister(p or { id = id, data = { garage = { spots = {} } } }) end
        end)
        if not ok then print(('^3[XS-Housing]^0 %s garage sync failed for %s: %s'):format(Garage.name, tostring(id), tostring(err))) end
    end

    function Garage.Refresh(id)
        local a = adapter()
        local p = Props.Get(id)
        if not a or not p then return end
        if a.refresh then pcall(a.refresh, p) end
    end

    function Garage.SyncAll()
        Garage.name = detect()
        Garage.registered = {}
        for id in pairs(Props.list) do Garage.Sync(id) end
    end

    AddEventHandler('onResourceStart', function(resource)
        for _, name in ipairs(ORDER) do
            if name == resource then
                SetTimeout(2000, function()
                    if Props.ready then Garage.SyncAll() end
                end)
                return
            end
        end
    end)

    Framework.OnLoaded(function(src)
        local a = adapter()
        if a and a.load then SetTimeout(3000, function() a.load(src) end) end
    end)

    if GetResourceState('qb-houses') ~= 'started' then
        AddEventHandler('__cfx_export_qb-houses_hasKey', function(setCB)
            setCB(function(_, cid, house)
                local id = tostring(house or ''):match('^xsh_(%d+)$')
                id = tonumber(id)
                if not id then return false end
                return Access.Can(cid, id, 'garage') == true
            end)
        end)
    end
else
    function Garage.Open(spot)
        if Garage.name == 'cd_garage' then
            TriggerEvent('cd_garage:PropertyGarage:Open', vector4(spot.x, spot.y, spot.z, spot.w or 0.0))
        elseif Garage.name == 'okokGarage' then
            TriggerEvent('okokGarage:OpenPrivateGarageMenu', vector3(spot.x, spot.y, spot.z), spot.w or 0.0)
        end
    end

    function Garage.Store()
        if Garage.name == 'cd_garage' then
            TriggerEvent('cd_garage:PropertyGarage:StoreVehicle')
        elseif Garage.name == 'okokGarage' then
            TriggerEvent('okokGarage:StoreVehiclePrivate')
        end
    end
end
