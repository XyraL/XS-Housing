Housing = {
    props = {}, access = {}, cid = nil, inside = nil, agency = {}, catalogue = {}, categories = {}, garage = nil, admin = false,
    hooks = {}, ready = false,
}

function Util.LoadModel(model, timeout)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local untilAt = GetGameTimer() + (timeout or 8000)
    while not HasModelLoaded(hash) and GetGameTimer() < untilAt do Wait(20) end
    return HasModelLoaded(hash)
end

function Util.LoadDict(dict, timeout)
    if HasAnimDictLoaded(dict) then return true end
    if not DoesAnimDictExist(dict) then return false end
    RequestAnimDict(dict)
    local untilAt = GetGameTimer() + (timeout or 5000)
    while not HasAnimDictLoaded(dict) and GetGameTimer() < untilAt do Wait(20) end
    return HasAnimDictLoaded(dict)
end

function Util.Fade(out, ms)
    ms = ms or Config.Entering.fadeMs or 400
    if ms <= 0 then return end
    if out then
        DoScreenFadeOut(ms)
        local untilAt = GetGameTimer() + ms + 1500
        while not IsScreenFadedOut() and GetGameTimer() < untilAt do Wait(10) end
    else
        DoScreenFadeIn(ms)
    end
end

function Util.Teleport(pos, heading)
    local ped = PlayerPedId()
    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    SetEntityCoordsNoOffset(ped, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, false, false, false)
    if heading then SetEntityHeading(ped, heading + 0.0) end
    local untilAt = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < untilAt do Wait(20) end
end

function Util.Notify(msg, kind)
    if not msg or msg == '' then return end
    Framework.Notify(msg, kind)
end

function Util.Result(ok, data)
    if ok == false then Util.Notify(data or Text('err_failed'), 'error') end
    return ok ~= false, data
end

function Housing.Call(name, ...)
    return UI.Await(name, ...)
end

function Housing.Prop(id)
    return Housing.props[tostring(id)]
end

function Housing.Role(id)
    return Housing.access[tostring(id)]
end

function Housing.On(name, fn)
    Housing.hooks[name] = Housing.hooks[name] or {}
    table.insert(Housing.hooks[name], fn)
end

function Housing.Emit(name, ...)
    for _, fn in ipairs(Housing.hooks[name] or {}) do
        local ok, err = pcall(fn, ...)
        if not ok then print(('^1[XS-Housing]^0 %s hook failed: %s'):format(name, tostring(err))) end
    end
end

function Housing.DoorOf(p)
    if not p then return nil end
    if p.door then return p.door end
    if p.building and p.building > 0 then
        local b = Housing.Prop(p.building)
        return b and b.door
    end
    return nil
end

function Housing.WallProp(model, at, heading)
    if not model or model == '' or not at or not Util.LoadModel(model, 5000) then return nil end
    local hash = joaat(model)
    local obj = CreateObjectNoOffset(hash, at.x + 0.0, at.y + 0.0, at.z + 0.0, false, false, false)
    SetEntityHeading(obj, (heading or 0.0) + 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityCanBeDamaged(obj, false)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

function Housing.OnProperty(p, pos)
    if not p then return false end
    local st = Inside.state
    if st and st.id == p.id then return true end
    pos = pos or GetEntityCoords(PlayerPedId())
    local flat = { x = pos.x, y = pos.y }
    if p.area and p.area.poly and #p.area.poly >= 3 and Util.InPoly(flat, p.area.poly) then return true end
    local door = Housing.DoorOf(p)
    if p.yard and p.yard.enabled and p.yard.poly and #p.yard.poly >= 3 and Util.InPoly(flat, p.yard.poly)
        and math.abs(pos.z - (door and door.z or pos.z)) < (Config.Yards.heightLimit or 6.0) + 4.0 then
        return true
    end
    return p.door ~= nil and #(pos - vector3(p.door.x + 0.0, p.door.y + 0.0, p.door.z + 0.0)) < 12.0
end

function Housing.Refresh()
    local ok, props = Housing.Call('props')
    if ok and type(props) == 'table' then Housing.props = props end
    local okA, data = Housing.Call('access')
    if okA and type(data) == 'table' then
        Housing.access = data.access or {}
        Housing.cid = data.cid
        Housing.agency = data.agency or {}
        Housing.catalogue = data.catalogue or {}
        Housing.categories = data.categories or {}
        Housing.garage = data.garage
        Housing.admin = data.admin == true
    end
    Housing.ready = true
    Housing.Emit('all')
end

RegisterNetEvent('XS-Housing:client:props', function(list)
    Housing.props = list or {}
    Housing.Emit('all')
end)

RegisterNetEvent('XS-Housing:client:prop', function(id, data)
    local key = tostring(id)
    local before = Housing.props[key]
    Housing.props[key] = data
    Housing.Emit('prop', id, data, before)
end)

RegisterNetEvent('XS-Housing:client:access', function(map)
    Housing.access = map or {}
    Housing.Emit('access')
end)

RegisterNetEvent('XS-Housing:client:catalogue', function(list)
    Housing.catalogue = list or {}
    Housing.Emit('catalogue')
end)

RegisterNetEvent('XS-Housing:client:agency', function(data)
    Housing.agency = data or {}
    Housing.Emit('agency')
end)

CreateThread(function()
    while not Framework.name do Wait(200) end
    while not Framework.Loaded() do Wait(500) end
    Wait(1000)
    Housing.Refresh()
end)

Framework.OnLoaded(function()
    SetTimeout(1500, Housing.Refresh)
end)

Framework.OnUnloaded(function()
    Housing.access = {}
    Housing.Emit('access')
end)
