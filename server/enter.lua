Enter = { inside = {}, rings = {}, tours = {}, openHouse = {} }

local BUCKET_BASE = 70000

function Enter.Bucket(id)
    if not Config.Interiors.instanced then return 0 end
    return BUCKET_BASE + id
end

local function setBucket(src, bucket)
    SetPlayerRoutingBucket(src, bucket)
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then SetEntityRoutingBucket(veh, 0) end
    end
end

local function inPlace(p)
    return p.data.interior.kind == 'shell' or p.data.interior.kind == 'ipl'
end

function Enter.Who(id)
    local out = {}
    for src, st in pairs(Enter.inside) do
        if st.id == id then out[#out + 1] = src end
    end
    return out
end

function Enter.Of(src)
    return Enter.inside[src]
end

local function packFor(src, p, mode)
    local furniture = Furniture and Furniture.Inside(p.id) or {}
    local role = Access.Role(src, p.id)
    return {
        id = p.id, mode = mode, role = role,
        interior = p.data.interior, points = p.data.points, door = p.data.door, area = p.data.area, label = p.data.label,
        style = p.owner and p.owner.style or '',
        lights = p.owner and p.owner.prefs and p.owner.prefs.lights or 'on',
        utilitiesOff = p.owner and p.owner.prefs and p.owner.prefs.utilitiesOff == true,
        furniture = furniture,
        tourEnds = mode == 'tour' and Enter.tours[src] and Enter.tours[src].ends or nil,
        storageOpen = Security and Security.StorageOpen and Security.StorageOpen(src, p.id) or false,
        canFurnish = role and Access.Can(src, p.id, 'furniture') or false,
    }
end

function Enter.Allowed(src, p)
    if not p.data.enabled then return false, Text('err_disabled') end
    local role = Access.Role(src, p.id)
    if role then return true, 'member' end
    if Enter.OpenHouseUntil(p.id) then return true, 'visitor' end
    if Security and Security.IsOpenFor(src, p.id) then return true, Security.ModeFor(src, p.id) end
    if p.owner and (p.owner.locked == 0 or p.owner.locked == false) and Config.Entering.unlockedLetsAnyoneIn then return true, 'visitor' end
    return false, p.owner and Text('err_locked') or Text('err_not_yours')
end

function Enter.Put(src, p, mode, at)
    local ped = GetPlayerPed(src)
    local pos = ped ~= 0 and GetEntityCoords(ped) or nil
    Enter.inside[src] = { id = p.id, mode = mode, since = os.time(), from = at or (pos and { x = pos.x, y = pos.y, z = pos.z }) }
    if inPlace(p) then setBucket(src, Enter.Bucket(p.id)) end
    Player(src).state:set('xsHousingInside', p.id, true)
    Framework.SetMetaData(src, 'xs_housing_inside', p.id)
    TriggerClientEvent('XS-Housing:client:enter', src, packFor(src, p, mode))
end

function Enter.Leave(src, silent)
    local st = Enter.inside[src]
    if not st then return false end
    Enter.inside[src] = nil
    Enter.tours[src] = nil
    local p = Props.Get(st.id)
    if GetPlayerName(src) then
        setBucket(src, 0)
        Player(src).state:set('xsHousingInside', nil, true)
        Framework.SetMetaData(src, 'xs_housing_inside', nil)
        if not silent then
            local door = p and p.data.door or st.from
            TriggerClientEvent('XS-Housing:client:leave', src, door)
        end
    end
    return true
end

function Enter.KickAll(id, reason)
    for _, src in ipairs(Enter.Who(id)) do
        Enter.Leave(src)
        if reason then Framework.Notify(src, Text('kicked_' .. reason), 'inform') end
    end
end

local function nearDoor(src, p, range)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    local here = { x = pos.x, y = pos.y, z = pos.z }
    if p.data.door and Util.Distance(here, p.data.door) <= (range or 6.0) then return true end
    for _, d in ipairs(p.data.extraDoors or {}) do
        if Util.Distance(here, d) <= (range or 6.0) then return true end
    end
    local b = p.data.building > 0 and Props.Get(p.data.building)
    if b and b.data.door and Util.Distance(here, b.data.door) <= (range or 6.0) then return true end
    return false
end

function Enter.Try(src, id)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    if p.data.type == 'building' then return false, Text('err_no_place') end
    if not inPlace(p) then return false, Text('err_walk_in') end
    if not nearDoor(src, p) then return false, Text('err_too_far') end
    local ok, mode = Enter.Allowed(src, p)
    if not ok then return false, mode end
    Enter.Put(src, p, mode)
    if mode == 'visitor' and Enter.OpenHouseUntil(id) and Enter.inside[src] then Enter.inside[src].openHouse = true end
    if mode == 'member' then Logs.Add('enter', id, Logs.Who(src), '', 0) end
    return true
end

function Enter.Tour(src, id)
    if not Config.Buying.tours then return false, Text('err_failed') end
    local p = Props.Get(id)
    if not p or not Props.ForSale(p) then return false, Text('err_not_for_sale') end
    if not inPlace(p) then return false, Text('err_walk_in') end
    if not nearDoor(src, p) then return false, Text('err_too_far') end
    local ends = os.time() + (Config.Buying.tourMinutes or 3) * 60
    Enter.tours[src] = { id = id, ends = ends }
    Enter.Put(src, p, 'tour')
    return true
end

function Enter.OpenHouseUntil(id)
    local o = Enter.openHouse[id]
    if o and o.untilAt > os.time() then return o.untilAt end
    return nil
end

function Enter.CanHostOpenHouse(src, p)
    if not p or not p.data.enabled or p.data.type == 'building' then return false end
    if not inPlace(p) and p.data.interior.kind ~= 'mlo' and p.data.type ~= 'mlo' then return false end
    if p.owner then return Access.Can(src, p.id, 'letin') == true end
    return Props.ForSale(p) and Agency and Agency.Can(src, 'list') == true
end

local function endOpenHouse(id, why)
    local o = Enter.openHouse[id]
    if not o then return end
    Enter.openHouse[id] = nil
    local p = Props.Get(id)
    for src, st in pairs(Enter.inside) do
        if st.id == id and st.openHouse and not Access.Role(src, id) then
            Enter.Leave(src)
            Framework.Notify(src, Text('openhouse_over'), 'inform')
        end
    end
    if p and o.unlocked and (not p.owner or p.owner.locked == 1 or p.owner.locked == true) then Doors.SetLocked(p, true) end
    if p then Props.Sync(id) end
    if why == 'ended' and o.by then Framework.Notify(o.by, Text('openhouse_ended', { place = p and p.data.label or '' }), 'inform') end
end

function Enter.OpenHouse(src, id, on)
    if not (Config.OpenHouse or {}).enabled then return false, Text('err_failed') end
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    if not Enter.CanHostOpenHouse(src, p) then return false, Text('err_no_rights') end
    if not on then
        endOpenHouse(id, 'stopped')
        return true
    end
    local minutes = math.max(1, math.floor(tonumber(Config.OpenHouse.minutes) or 15))
    local untilAt = os.time() + minutes * 60
    local unlocked = false
    if not inPlace(p) then
        Doors.SetLocked(p, false, src)
        unlocked = true
    end
    Enter.openHouse[id] = { untilAt = untilAt, by = src, unlocked = unlocked }
    Props.Sync(id)
    Logs.Add('openhouse', id, Logs.Who(src), Text('log_openhouse', { m = minutes }), 0)
    return true, untilAt
end

function Enter.Exit(src)
    if not Enter.inside[src] then return false end
    return Enter.Leave(src)
end

function Enter.Ring(src, id, knock)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_nobody') end
    if not knock and not Config.Doorbell.enabled then return false, Text('err_failed') end
    if knock and not Config.Entering.knock then return false, Text('err_failed') end
    if not nearDoor(src, p) then return false, Text('err_too_far') end
    local now = os.time()
    local key = src .. ':' .. id
    if Enter.rings[key] and now - Enter.rings[key].at < (Config.Doorbell.cooldown or 8) then return false, Text('err_wait') end
    Enter.rings[key] = { at = now, src = src, id = id }
    local prefs = p.owner.prefs or {}
    local name = Framework.GetName(src) or Text('someone')
    local insiders = Enter.Who(id)
    for _, other in ipairs(insiders) do
        TriggerClientEvent('XS-Housing:client:ring', other, { id = id, from = src, name = name, knock = knock, inside = true, place = p.data.label })
    end
    if not knock and prefs.doorbell ~= false then
        local notified = {}
        for _, s in ipairs(insiders) do notified[s] = true end
        for _, holder in ipairs(Access.OnlineHolders(id, 'letin')) do
            if not notified[holder] then
                TriggerClientEvent('XS-Housing:client:ring', holder, { id = id, from = src, name = name, knock = false, inside = false, place = p.data.label, remote = Config.Doorbell.letInRemotely })
                if Config.Doorbell.phone then Phone.Notify(holder, Text('phone_doorbell_title'), Text('phone_doorbell', { name = name, place = p.data.label })) end
            end
        end
    end
    local visitors = prefs.visitors or {}
    table.insert(visitors, 1, { name = name, at = now, knock = knock == true })
    while #visitors > 20 do table.remove(visitors) end
    prefs.visitors = visitors
    p.owner.prefs = prefs
    MySQL.update('UPDATE xs_housing_owners SET prefs = ? WHERE property_id = ?', { Db.Json(prefs), id })
    TriggerClientEvent('XS-Housing:client:knockSound', -1, p.data.door, knock == true)
    return true
end

function Enter.LetIn(src, id, visitor)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    if not Access.Can(src, id, 'letin') then return false, Text('err_no_rights') end
    local insideHere = Enter.inside[src] and Enter.inside[src].id == id
    if not insideHere and not Config.Doorbell.letInRemotely then return false, Text('err_inside_only') end
    visitor = tonumber(visitor)
    local ring = visitor and Enter.rings[visitor .. ':' .. id]
    if not ring or os.time() - ring.at > 120 then return false, Text('err_ring_old') end
    if not GetPlayerName(visitor) or not nearDoor(visitor, p, 8.0) then return false, Text('err_visitor_left') end
    Enter.rings[visitor .. ':' .. id] = nil
    if inPlace(p) then
        Enter.Put(visitor, p, 'visitor')
    else
        Doors.SetLocked(p, false, src)
        SetTimeout(10000, function() if p.owner and (p.owner.locked == 1) then Doors.SetLocked(p, true, src) end end)
    end
    Framework.Notify(visitor, Text('let_in'), 'success')
    return true
end

function Enter.SetLock(src, id, locked)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, id, 'lock') then return false, Text('err_no_rights') end
    Props.UpdateOwner(id, { locked = locked and 1 or 0 })
    if p.data.interior.kind == 'mlo' or p.data.type == 'mlo' then Doors.SetLocked(p, locked, src) end
    return true
end

function Enter.Restore(src)
    local id = Framework.GetMetaData(src, 'xs_housing_inside')
    id = tonumber(id)
    if not id then return end
    local p = Props.Get(id)
    if not p or not inPlace(p) then
        Framework.SetMetaData(src, 'xs_housing_inside', nil)
        return
    end
    local ok = Enter.Allowed(src, p)
    if ok and Access.Role(src, id) then
        Enter.Put(src, p, 'member')
    else
        Framework.SetMetaData(src, 'xs_housing_inside', nil)
        TriggerClientEvent('XS-Housing:client:leave', src, p.data.door)
    end
end

CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()
        for src, tour in pairs(Enter.tours) do
            if tour.ends <= now then
                Enter.Leave(src)
                Framework.Notify(src, Text('tour_over'), 'inform')
            end
        end
        for src, st in pairs(Enter.inside) do
            local p = Props.Get(st.id)
            if not GetPlayerName(src) then
                Enter.inside[src] = nil
            elseif not p then
                Enter.Leave(src)
            elseif st.mode == 'member' and not Access.Role(src, st.id) then
                Enter.Leave(src)
                Framework.Notify(src, Text('kicked_no_key'), 'inform')
            end
        end
        for key, ring in pairs(Enter.rings) do
            if now - ring.at > 180 then Enter.rings[key] = nil end
        end
        for id, o in pairs(Enter.openHouse) do
            if o.untilAt <= now then endOpenHouse(id, 'ended') end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    Enter.inside[src] = nil
    Enter.tours[src] = nil
end)

Framework.OnUnloaded(function(src)
    if Enter.inside[src] then
        local st = Enter.inside[src]
        Enter.inside[src] = nil
        Enter.tours[src] = nil
        if GetPlayerName(src) then
            setBucket(src, 0)
            Player(src).state:set('xsHousingInside', nil, true)
        end
        if st.mode ~= 'member' then Framework.SetMetaData(src, 'xs_housing_inside', nil) end
    end
end)

Framework.OnLoaded(function(src)
    SetTimeout(2500, function()
        if GetPlayerName(src) then Enter.Restore(src) end
    end)
end)
