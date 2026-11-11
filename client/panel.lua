Panel = { id = nil }

local function nearbyPlayers(radius)
    local out = {}
    local me = PlayerId()
    local pos = GetEntityCoords(PlayerPedId())
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= me then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and #(GetEntityCoords(ped) - pos) <= (radius or 6.0) then
                out[#out + 1] = { id = GetPlayerServerId(pid), name = GetPlayerName(pid) }
            end
        end
    end
    return out
end

Panel.Nearby = nearbyPlayers

local function load(id)
    local ok, data = Housing.Call('panel', id)
    if not ok then return false, data end
    data.time = Util.Now()
    data.hour = GetClockHours()
    data.minute = GetClockMinutes()
    data.nearby = nearbyPlayers(8.0)
    return true, data
end

function Panel.Open(id)
    if UI.HasFocus('panel') then return end
    local ok, data = load(id)
    if not ok then return Util.Notify(data or Text('err_failed'), 'error') end
    Panel.id = id
    UI.Send('panel', 'open', data)
    UI.Focus('panel', true)
    PlaySoundFrontend(-1, 'Hack_Success', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS', true)
end

function Panel.Close()
    Panel.id = nil
    UI.Send('panel', 'close', {})
    UI.Focus('panel', false)
end

UI.OnClose('panel', Panel.Close)

local function act(name, ...)
    local ok, data = Housing.Call(name, ...)
    if not ok then return false, data end
    local okLoad, fresh = load(Panel.id)
    if okLoad then UI.Send('panel', 'update', fresh) end
    return true, data
end

UI.Handle('panel:refresh', function()
    return load(Panel.id)
end)

UI.Handle('panel:lock', function(p) return act('lock', Panel.id, p.locked == true) end)
UI.Handle('panel:pref', function(p) return act('setPrefs', Panel.id, p) end)
UI.Handle('panel:openHouse', function(p) return act('openHouse', Panel.id, p.on == true) end)
UI.Handle('panel:giveKey', function(p) return act('giveKey', Panel.id, p.target, p.role, p.hours) end)
UI.Handle('panel:takeKey', function(p) return act('takeKey', Panel.id, p.citizenid) end)
UI.Handle('panel:changeLocks', function() return act('changeLocks', Panel.id) end)
UI.Handle('panel:pay', function() return act('payArrears', Panel.id) end)
UI.Handle('panel:payOff', function() return act('payOff', Panel.id) end)
UI.Handle('panel:insure', function(p) return act('insure', Panel.id, p.on == true) end)
UI.Handle('panel:style', function(p) return act('setStyle', Panel.id, p.style) end)
UI.Handle('panel:storageUpgrade', function() return act('upgradeStorage', Panel.id) end)
UI.Handle('panel:buyLock', function() return act('buyLock', Panel.id) end)
UI.Handle('panel:repairLock', function() return act('repairLock', Panel.id) end)
UI.Handle('panel:buyAlarm', function() return act('buyAlarm', Panel.id) end)
UI.Handle('panel:arm', function(p) return act('arm', Panel.id, p.on == true) end)
UI.Handle('panel:removeCamera', function(p) return act('removeCamera', Panel.id, p.index) end)
UI.Handle('panel:nearby', function() return true, nearbyPlayers(8.0) end)

UI.Handle('panel:addCamera', function(p)
    local id = Panel.id
    if not Housing.OnProperty(Housing.Prop(id)) then return false, Text('err_be_there') end
    Panel.Close()
    CreateThread(function()
        local at = Placement.Start({ label = Text('place_camera'), mode = 'point' })
        if not at then return end
        at.rx = -12.0
        local ok, err = Housing.Call('addCamera', id, at, p.label)
        if ok then Util.Notify(Text('camera_added'), 'success') else Util.Notify(err, 'error') end
    end)
    return true
end)

UI.Handle('panel:cameras', function()
    local id = Panel.id
    Panel.Close()
    CreateThread(function() Security.Cameras(id) end)
    return true
end)

UI.Handle('panel:sell', function()
    local id = Panel.id
    local ok, value = Housing.Call('sellBack', id)
    if ok then
        Panel.Close()
        Util.Notify(Text('sold', { amount = Util.Money(value) }), 'success')
        return true
    end
    return false, value
end)

UI.Handle('panel:moveOut', function()
    local id = Panel.id
    local ok, refund = Housing.Call('moveOut', id)
    if ok then
        Panel.Close()
        Util.Notify(Text('moved_out', { amount = Util.Money(refund or 0) }), 'success')
        return true
    end
    return false, refund
end)

UI.Handle('panel:furnish', function(p)
    local id = Panel.id
    if not Catalogue.Where(id, p and p.where) then return false, Text('err_furnish_where') end
    Panel.Close()
    CreateThread(function() Catalogue.Open(id, p and p.where) end)
    return true
end)

UI.Handle('panel:waypoint', function()
    local p = Housing.Prop(Panel.id)
    local door = p and Housing.DoorOf(p)
    if door then SetNewWaypoint(door.x + 0.0, door.y + 0.0) end
    return true
end)

local function myPlaces()
    local list = {}
    for key, role in pairs(Housing.access) do
        local p = Housing.Prop(key)
        if p and role ~= 'guest' and p.type ~= 'building' then list[#list + 1] = { p = p, role = role } end
    end
    table.sort(list, function(a, b) return a.p.id < b.p.id end)
    return list
end

RegisterCommand(Config.Commands.panel, function()
    local st = Inside.state
    if st and Housing.Role(st.id) and Housing.Role(st.id) ~= 'guest' then return Panel.Open(st.id) end
    local pos = GetEntityCoords(PlayerPedId())
    local mine = myPlaces()
    local best, bestGap = nil, math.huge
    for _, entry in ipairs(mine) do
        local p = entry.p
        if Housing.OnProperty(p, pos) then
            local door = Housing.DoorOf(p)
            local gap = door and #(pos - vector3(door.x + 0.0, door.y + 0.0, door.z + 0.0)) or 0.0
            if gap < bestGap then best, bestGap = p, gap end
        end
    end
    if best then return Panel.Open(best.id) end
    if Config.Panel.fromAnywhere and #mine == 1 then return Panel.Open(mine[1].p.id) end
    if Config.Panel.fromAnywhere and #mine > 1 then
        local list = {}
        for _, entry in ipairs(mine) do
            local p = entry.p
            list[#list + 1] = { title = p.label, description = Text('role_' .. entry.role), onSelect = function() Panel.Open(p.id) end }
        end
        lib.registerContext({ id = 'xsh_mine', title = Text('my_places'), options = list })
        return lib.showContext('xsh_mine')
    end
    Util.Notify(Text(#mine == 0 and 'err_no_places' or 'err_no_home_here'), 'error')
end, false)

function Catalogue.Where(id, where)
    local p = Housing.Prop(id)
    if not p then return nil end
    local pos = GetEntityCoords(PlayerPedId())
    local inside = Inside.state and Inside.state.id == id
    local isMlo = p.type == 'mlo' or (p.interior and p.interior.kind == 'mlo')
    local onPlace = Housing.OnProperty(p, pos)
    local canInside = inside or (isMlo and onPlace)
    local canYard = p.yard and p.yard.enabled and Config.Yards.enabled and not inside and onPlace
    if not canInside and not canYard then return nil end
    if where == 'yard' and not canYard then where = nil end
    if where == 'inside' and not canInside then where = nil end
    return where or (canInside and 'inside' or 'yard'), canInside, canYard
end

function Catalogue.Open(id, where)
    local p = Housing.Prop(id)
    if not p then return end
    local canInside, canYard
    where, canInside, canYard = Catalogue.Where(id, where)
    if not where then return Util.Notify(Text('err_furnish_where'), 'error') end
    UI.Send('catalogue', 'open', {
        id = id, label = p.label, items = Housing.catalogue, categories = Housing.categories, where = where,
        canInside = canInside, canYard = canYard, placed = Furn.List(id), money = (Framework.PlayerData().money or {}),
    })
    UI.Focus('catalogue', true)
end

UI.OnClose('catalogue', function()
    UI.Send('catalogue', 'close', {})
    UI.Focus('catalogue', false)
end)

UI.Handle('catalogue:pick', function(p)
    UI.Send('catalogue', 'close', {})
    UI.Focus('catalogue', false)
    CreateThread(function()
        Furn.Buy(p.id, p.item, p.where)
        Wait(250)
        if p.again then Catalogue.Open(p.id, p.where) end
    end)
    return true
end)

UI.Handle('catalogue:move', function(p)
    local row = Furn.Row(p.id, p.row)
    if not row then return false, Text('err_failed') end
    UI.Send('catalogue', 'close', {})
    UI.Focus('catalogue', false)
    CreateThread(function() Furn.Move(p.id, row) end)
    return true
end)

UI.Handle('catalogue:remove', function(p)
    local ok, refund = Housing.Call('removeFurniture', p.id, p.row)
    if not ok then return false, refund end
    Wait(200)
    return true, { placed = Furn.List(p.id), refund = refund }
end)

UI.Handle('catalogue:yard', function(p)
    local prop = Housing.Prop(p.id)
    if not prop then return false end
    UI.Send('catalogue', 'close', {})
    UI.Focus('catalogue', false)
    CreateThread(function()
        local untilAt = GetGameTimer() + 8000
        lib.showTextUI(Text('yard_shown'), { position = 'top-center' })
        while GetGameTimer() < untilAt do
            Furn.DrawYard(prop)
            Wait(0)
        end
        lib.hideTextUI()
    end)
    return true
end)
