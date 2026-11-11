Furn = { inside = {}, world = {}, insideRows = {}, placing = false, lights = {}, sitting = false, tv = nil }

local function v3(p) return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0) end

local function itemOf(id)
    for _, it in ipairs(Housing.catalogue or {}) do
        if it.id == id then return it end
    end
    return nil
end

function Furn.InSeason(row)
    local item = row and itemOf(row.item)
    if not item or not item.season then return true end
    if GlobalState.xshSeasonHide == false then return true end
    return GlobalState.xshSeason == item.season
end

local function spawnObject(model, pos, rot)
    if not Util.LoadModel(model, 6000) then return nil end
    local hash = joaat(model)
    local obj = CreateObjectNoOffset(hash, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, false, false, false)
    SetEntityRotation(obj, (rot.x or 0.0) + 0.0, (rot.y or 0.0) + 0.0, (rot.z or 0.0) + 0.0, 2, true)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

local function canFurnish(id)
    local role = Housing.Role(id)
    if not role or role == 'guest' or role == 'group' then return false end
    if role == 'owner' then return true end
    return Config.Keys.tenantsFurnish
end

local function stand()
    Furn.sitting = false
    ClearPedTasks(PlayerPedId())
end

local function sit(obj, lie)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(obj)
    local heading = (GetEntityHeading(obj) + 180.0) % 360
    if lie then
        TaskStartScenarioAtPosition(ped, 'WORLD_HUMAN_SUNBATHE_BACK', pos.x, pos.y, pos.z + 0.55, heading, 0, true, true)
    else
        local fwd = GetEntityForwardVector(obj)
        TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', pos.x + fwd.x * 0.05, pos.y + fwd.y * 0.05, pos.z + 0.5, heading, 0, true, true)
    end
    Furn.sitting = true
    lib.showTextUI(Text('stand_hint'), { position = 'right-center' })
    CreateThread(function()
        while Furn.sitting do
            Wait(0)
            if IsControlJustPressed(0, 73) or IsControlJustPressed(0, 32) then
                stand()
                break
            end
        end
        lib.hideTextUI()
    end)
end

local function setData(propId, rowId, patch)
    Util.Result(Housing.Call('furnitureData', propId, rowId, patch))
end

local function entityOptions(propId, row, obj)
    local item = itemOf(row.item) or {}
    local use = item.use
    local opts = {}
    local function add(label, icon, fn, can) opts[#opts + 1] = { label = label, icon = icon, onSelect = function() fn() end, canInteract = can } end
    local member = function() return Housing.Role(propId) ~= nil end
    if use == 'storage' or use == 'safe' or use == 'fridge' then
        local label = use == 'safe' and Text('opt_safe') or (use == 'fridge' and Text('opt_fridge') or Text('opt_storage'))
        local icon = use == 'safe' and 'fas fa-vault' or (use == 'fridge' and 'fas fa-snowflake' or 'fas fa-box-open')
        add(label, icon, function() Storage.Open(propId, 'furniture', row.id) end, function()
            local p = Housing.Prop(propId)
            return member() or (p and p.open == true)
        end)
    elseif use == 'sit' then
        add(Text('opt_sit'), 'fas fa-chair', function() sit(obj, false) end)
    elseif use == 'lie' then
        add(Text('opt_lie'), 'fas fa-bed', function() sit(obj, true) end)
    elseif use == 'wardrobe' then
        add(Text('opt_wardrobe'), 'fas fa-shirt', function() Clothing.OpenOutfits() end, member)
    elseif use == 'light' then
        add(Text('opt_light'), 'fas fa-lightbulb', function() setData(propId, row.id, { on = not (row.data and row.data.on) }) end, member)
    elseif use == 'music' or use == 'tv' then
        add(use == 'tv' and Text('opt_tv') or Text('opt_music'), use == 'tv' and 'fas fa-tv' or 'fas fa-music', function()
            local input = lib.inputDialog(use == 'tv' and Text('tv_title') or Text('music_title'), {
                { type = 'input', label = Text('url_label'), description = use == 'tv' and Text('tv_link_hint') or Text('music_link_hint'), default = row.data and row.data.url or '', placeholder = 'https://' },
                { type = 'slider', label = Text('volume_label'), default = math.floor(((row.data and row.data.volume) or 0.5) * 100), min = 0, max = 100 },
            })
            if not input then return end
            local url = tostring(input[1] or '')
            setData(propId, row.id, { url = url, playing = url ~= '', volume = (tonumber(input[2]) or 50) / 100 })
        end, member)
        local function live() return Furn.Row(propId, row.id) or row end
        add(Text('opt_pause'), 'fas fa-pause', function() setData(propId, row.id, { paused = true }) end, function()
            local d = live().data or {}
            return member() and d.playing == true and d.paused ~= true
        end)
        add(Text('opt_resume'), 'fas fa-play', function() setData(propId, row.id, { paused = false }) end, function()
            local d = live().data or {}
            return member() and d.playing == true and d.paused == true
        end)
        add(Text('opt_volume'), 'fas fa-volume-high', function()
            local d = live().data or {}
            local input = lib.inputDialog(Text('volume_label'), {
                { type = 'slider', label = Text('volume_label'), default = math.floor((d.volume or 0.5) * 100), min = 0, max = 100 },
            })
            if input then setData(propId, row.id, { volume = (tonumber(input[1]) or 50) / 100 }) end
        end, function() return member() and (live().data or {}).playing == true end)
        add(Text('opt_stop'), 'fas fa-stop', function() setData(propId, row.id, { playing = false }) end, function()
            return member() and (live().data or {}).playing == true
        end)
    end
    add(Text('opt_move'), 'fas fa-arrows-up-down-left-right', function() Furn.Move(propId, row) end, function() return canFurnish(propId) end)
    add(Text('opt_remove'), 'fas fa-trash', function()
        local ok = lib.alertDialog({ header = Text('remove_title'), content = Text('remove_body', { pct = Config.Furniture.refundPct }), centered = true, cancel = true })
        if ok == 'confirm' then
            local done, refund = Util.Result(Housing.Call('removeFurniture', propId, row.id))
            if done and (refund or 0) > 0 then Util.Notify(Text('refunded', { amount = Util.Money(refund) }), 'success') end
        end
    end, function() return canFurnish(propId) end)
    return opts
end

local function rowWorldPos(row, inside)
    if inside and Inside.state and Inside.state.kind == 'shell' then
        return Inside.ToWorld({ x = row.x, y = row.y, z = row.z })
    end
    return { x = row.x, y = row.y, z = row.z }
end

local function place(store, propId, row, inside)
    if not Furn.InSeason(row) then return end
    local pos = rowWorldPos(row, inside)
    local obj = spawnObject(row.model, pos, { x = row.rx, y = row.ry, z = row.rz })
    if not obj then return end
    store[row.id] = { row = row, obj = obj, prop = propId }
    Target.AddEntity('furn_' .. row.id, obj, entityOptions(propId, row, obj))
end

local function unplace(store, rowId)
    local e = store[rowId]
    if not e then return end
    Target.RemoveEntity('furn_' .. rowId)
    if e.obj and DoesEntityExist(e.obj) then DeleteEntity(e.obj) end
    store[rowId] = nil
end

function Furn.LoadInside(rows)
    Furn.ClearInside()
    Furn.insideRows = {}
    local id = Inside.state and Inside.state.id
    for _, row in ipairs(rows or {}) do
        Furn.insideRows[row.id] = row
        place(Furn.inside, id, row, true)
    end
end

function Furn.ClearInside()
    for rowId in pairs(Furn.inside) do unplace(Furn.inside, rowId) end
    Furn.inside = {}
end

RegisterNetEvent('XS-Housing:client:furniture', function(propId, action, row)
    if not Inside.state or Inside.state.id ~= propId then return end
    if action == 'reset' then
        Furn.ClearInside()
        Furn.insideRows = {}
    elseif action == 'add' then
        Furn.insideRows[row.id] = row
        place(Furn.inside, propId, row, true)
    elseif action == 'update' then
        Furn.insideRows[row.id] = row
        unplace(Furn.inside, row.id)
        place(Furn.inside, propId, row, true)
    elseif action == 'remove' then
        Furn.insideRows[row.id] = nil
        unplace(Furn.inside, row.id)
    end
end)

local function clearWorld(propId)
    local w = Furn.world[propId]
    if not w then return end
    for rowId in pairs(w.objs) do unplace(w.objs, rowId) end
    Furn.world[propId] = nil
end

RegisterNetEvent('XS-Housing:client:worldFurniture', function(propId, action, row)
    local w = Furn.world[propId]
    if not w then return end
    if action == 'reset' then
        for rowId in pairs(w.objs) do unplace(w.objs, rowId) end
    elseif action == 'add' then
        place(w.objs, propId, row, false)
    elseif action == 'update' then
        unplace(w.objs, row.id)
        place(w.objs, propId, row, false)
    elseif action == 'remove' then
        unplace(w.objs, row.id)
    end
end)

local pending = false

function Furn.Stream(near)
    local wanted = {}
    local ask = {}
    for _, id in ipairs(near) do
        local p = Housing.Prop(id)
        if p and ((p.yard and p.yard.enabled) or p.type == 'mlo' or (p.interior and p.interior.kind == 'mlo')) then
            wanted[id] = true
            if not Furn.world[id] then ask[#ask + 1] = id end
        end
    end
    for id in pairs(Furn.world) do
        if not wanted[id] then clearWorld(id) end
    end
    if #ask > 0 and not pending then
        pending = true
        CreateThread(function()
            local ok, data = Housing.Call('worldFurniture', ask)
            pending = false
            if not ok or type(data) ~= 'table' then return end
            for key, rows in pairs(data) do
                local id = tonumber(key)
                if id and not Furn.world[id] then
                    Furn.world[id] = { objs = {} }
                    for _, row in ipairs(rows) do place(Furn.world[id].objs, id, row, false) end
                end
            end
        end)
    end
end

local function inYard(p, pos)
    if not p.yard or not p.yard.enabled or not p.yard.poly or #p.yard.poly < 3 then return false end
    return Util.InPoly(pos, p.yard.poly) and math.abs(pos.z - (p.door and p.door.z or pos.z)) < (Config.Yards.heightLimit or 6.0) + 2.0
end

local function insideOk(p, pos)
    local st = Inside.state
    if st and st.id == p.id then
        if st.kind == 'shell' then return #(v3(pos) - v3(st.origin)) < 45.0 end
        if st.kind == 'ipl' then return #(v3(pos) - v3(st.anchor or st.spawn)) < 60.0 end
    end
    if p.area and p.area.poly and #p.area.poly >= 3 then return Util.InPoly(pos, p.area.poly) end
    return p.door ~= nil and #(v3(pos) - v3(p.door)) < 30.0
end

local function camRay(distance)
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(z) * math.abs(math.cos(x)), math.cos(z) * math.abs(math.cos(x)), math.sin(x))
    local to = cam + dir * distance
    local ray = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, to.x, to.y, to.z, 1 + 16, PlayerPedId(), 4)
    local _, hit, coords = GetShapeTestResult(ray)
    if hit == true or hit == 1 then return coords end
    return nil
end

local KEYS = { place = 191, cancel = 194, left = 174, right = 175, up = 172, down = 173, fine = 21, ground = 47, pitch = 44 }

local function gizmo(propId, model, where, start)
    if Furn.placing then return nil end
    local p = Housing.Prop(propId)
    if not p then return nil end
    if not Util.LoadModel(model, 8000) then
        Util.Notify(Text('err_model', { model = model }), 'error')
        return nil
    end
    Furn.placing = true
    local hash = joaat(model)
    local ghost = CreateObjectNoOffset(hash, 0.0, 0.0, 0.0, false, false, false)
    SetEntityCollision(ghost, false, false)
    SetEntityAlpha(ghost, 190, false)
    FreezeEntityPosition(ghost, true)
    local rot = { x = start and start.rx or 0.0, y = start and start.ry or 0.0, z = start and start.rz or GetEntityHeading(PlayerPedId()) }
    local lift = 0.0
    local result = nil
    local range = Config.Furniture.placeRange or 10.0
    lib.showTextUI(Text('place_hint'), { position = 'left-center' })
    while Furn.placing do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, KEYS.ground, true)
        DisableControlAction(0, KEYS.pitch, true)
        local hit = camRay(range)
        if hit then
            local step = IsControlPressed(0, KEYS.fine) and 0.5 or 2.0
            if IsControlPressed(0, KEYS.left) then rot.z = rot.z + step end
            if IsControlPressed(0, KEYS.right) then rot.z = rot.z - step end
            if IsControlPressed(0, KEYS.up) then lift = lift + (IsControlPressed(0, KEYS.fine) and 0.005 or 0.02) end
            if IsControlPressed(0, KEYS.down) then lift = lift - (IsControlPressed(0, KEYS.fine) and 0.005 or 0.02) end
            if IsDisabledControlJustPressed(0, KEYS.ground) then lift = 0.0 rot.x, rot.y = 0.0, 0.0 end
            if IsDisabledControlJustPressed(0, KEYS.pitch) then rot.x = (rot.x + (Config.Furniture.rotateStep or 15)) % 360 end
            local grid = Config.Furniture.gridSize or 0.25
            local pos = { x = hit.x, y = hit.y, z = hit.z + lift }
            if IsControlPressed(0, 36) and grid > 0 then
                pos.x = math.floor(pos.x / grid + 0.5) * grid
                pos.y = math.floor(pos.y / grid + 0.5) * grid
            end
            SetEntityCoordsNoOffset(ghost, pos.x, pos.y, pos.z, false, false, false)
            SetEntityRotation(ghost, rot.x, rot.y, rot.z, 2, true)
            local ok = where == 'yard' and inYard(p, pos) or (where ~= 'yard' and insideOk(p, pos))
            local min, max = GetModelDimensions(hash)
            local c = ok and { 45, 212, 191 } or { 240, 82, 95 }
            DrawMarker(43, pos.x, pos.y, pos.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, rot.z, (max.x - min.x) + 0.1, (max.y - min.y) + 0.1, 0.02, c[1], c[2], c[3], 70, false, false, 2, false)
            if where == 'yard' then Furn.DrawYard(p) end
            if IsControlJustPressed(0, KEYS.place) then
                if ok then
                    result = { pos = pos, rot = rot }
                    break
                end
                Util.Notify(where == 'yard' and Text('err_outside_yard') or Text('err_outside_house'), 'error')
            end
        end
        if IsControlJustPressed(0, KEYS.cancel) then break end
    end
    lib.hideTextUI()
    if DoesEntityExist(ghost) then DeleteEntity(ghost) end
    SetModelAsNoLongerNeeded(hash)
    Furn.placing = false
    return result
end

function Furn.DrawYard(p)
    local poly = p.yard and p.yard.poly
    if not poly or #poly < 3 then return end
    local z = (p.door and p.door.z or 0.0) - 0.9
    for i = 1, #poly do
        local a, b = poly[i], poly[i % #poly + 1]
        DrawLine(a.x, a.y, z, b.x, b.y, z, 45, 212, 191, 220)
        DrawLine(a.x, a.y, z + 2.0, b.x, b.y, z + 2.0, 45, 212, 191, 90)
        DrawLine(a.x, a.y, z, a.x, a.y, z + 2.0, 45, 212, 191, 90)
    end
end

function Furn.Buy(propId, itemId, where)
    local item = itemOf(itemId)
    if not item then return end
    local res = gizmo(propId, item.model, where)
    if not res then return end
    local pos = res.pos
    if where ~= 'yard' and Inside.state and Inside.state.kind == 'shell' and Inside.state.id == propId then pos = Inside.ToLocal(pos) end
    local ok, data = Housing.Call('placeFurniture', propId, itemId, where == 'yard' and 'yard' or 'inside', pos, res.rot)
    if ok then
        PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        Util.Notify(Text('placed', { item = item.label, amount = Util.Money(item.price) }), 'success')
    else
        Util.Notify(data or Text('err_failed'), 'error')
    end
end

function Furn.Move(propId, row)
    local store = Furn.inside[row.id] and Furn.inside or (Furn.world[propId] and Furn.world[propId].objs)
    local e = store and store[row.id]
    if e and e.obj and DoesEntityExist(e.obj) then SetEntityVisible(e.obj, false, false) end
    local res = gizmo(propId, row.model, row.place, row)
    if e and e.obj and DoesEntityExist(e.obj) then SetEntityVisible(e.obj, true, false) end
    if not res then return end
    local pos = res.pos
    if row.place == 'inside' and Inside.state and Inside.state.kind == 'shell' and Inside.state.id == propId then pos = Inside.ToLocal(pos) end
    Util.Result(Housing.Call('moveFurniture', propId, row.id, pos, res.rot))
end

function Furn.List(propId)
    local out = {}
    local function collect(store)
        for _, e in pairs(store or {}) do
            if e.prop == propId then
                local item = itemOf(e.row.item) or {}
                out[#out + 1] = { id = e.row.id, item = e.row.item, label = item.label or e.row.model, place = e.row.place, use = item.use }
            end
        end
    end
    collect(Furn.inside)
    if Furn.world[propId] then collect(Furn.world[propId].objs) end
    table.sort(out, function(a, b) return a.id > b.id end)
    return out
end

function Furn.Row(propId, rowId)
    local e = Furn.inside[rowId] or (Furn.world[propId] and Furn.world[propId].objs[rowId])
    return e and e.row or nil
end

local function liveRows()
    local list = {}
    for _, e in pairs(Furn.inside) do list[#list + 1] = e end
    for _, w in pairs(Furn.world) do
        for _, e in pairs(w.objs) do list[#list + 1] = e end
    end
    return list
end

CreateThread(function()
    while true do
        local sleep = 500
        local lights = 0
        for _, e in ipairs(liveRows()) do
            local item = itemOf(e.row.item)
            if item and item.use == 'light' and e.row.data and e.row.data.on and DoesEntityExist(e.obj) then
                local pos = GetEntityCoords(e.obj)
                if #(pos - GetEntityCoords(PlayerPedId())) < 40.0 then
                    sleep = 0
                    lights = lights + 1
                    DrawLightWithRange(pos.x, pos.y, pos.z + 0.6, 255, 214, 160, 5.0, 2.0)
                end
            end
        end
        Wait(sleep)
    end
end)

local function urlEncode(s)
    return (tostring(s):gsub('[^%w%-%._~]', function(c) return ('%%%02X'):format(c:byte()) end))
end

local function tvVolume(e)
    if IsPauseMenuActive() or not DoesEntityExist(e.obj) then return 0.0 end
    local gap = #(GetEntityCoords(e.obj) - GetEntityCoords(PlayerPedId()))
    return ((e.row.data and e.row.data.volume) or 0.5) * Sound.Falloff(gap, (Config.Music or {}).tvRange or 15.0)
end

function Furn.TvPage(url, offset, volume, paused)
    return ('https://cfx-nui-%s/html/tv.html?src=%s&t=%d&v=%.2f&p=%d'):format(GetCurrentResourceName(), urlEncode(url), math.max(0, math.floor(offset or 0)), volume or 0.5, paused and 1 or 0)
end

local function tvOffset(d)
    if d.paused then return tonumber(d.pos) or 0 end
    return d.at and math.max(0, Util.Now() - d.at) or 0
end

local function stopTv()
    local t = Furn.tv
    Furn.tv = nil
    if not t then return end
    if t.dui then DestroyDui(t.dui) end
    if t.target then ReleaseNamedRendertarget('tvscreen') end
end

local function startTv(e)
    stopTv()
    local d = e.row.data
    local volume = tvVolume(e)
    local dui = CreateDui(Furn.TvPage(d.url, tvOffset(d), volume, d.paused == true), 1280, 720)
    local txd = CreateRuntimeTxd('xsh_tv_txd')
    CreateRuntimeTextureFromDuiHandle(txd, 'xsh_tv_tex', GetDuiHandle(dui))
    if not IsNamedRendertargetRegistered('tvscreen') then RegisterNamedRendertarget('tvscreen', false) end
    LinkNamedRendertarget(GetEntityModel(e.obj))
    Furn.tv = {
        dui = dui, row = e.row.id, url = d.url, at = d.at, paused = d.paused == true, pos = d.pos, target = true,
        rt = GetNamedRendertargetRenderId('tvscreen'), obj = e.obj, entry = e, volume = volume, nextVolume = 0,
    }
end

local function syncTv(d)
    local t = Furn.tv
    if not t or (t.at == d.at and t.paused == (d.paused == true) and t.pos == d.pos) then return end
    t.at, t.paused, t.pos = d.at, d.paused == true, d.pos
    SendDuiMessage(t.dui, json.encode({ type = 'sync', paused = t.paused, offset = tvOffset(d) }))
end

local function tvVolumeTick()
    local t = Furn.tv
    if not t or GetGameTimer() < t.nextVolume then return end
    t.nextVolume = GetGameTimer() + 250
    local volume = tvVolume(t.entry)
    if math.abs(volume - t.volume) > 0.01 then
        t.volume = volume
        SendDuiMessage(t.dui, json.encode({ type = 'volume', volume = volume }))
    end
end

CreateThread(function()
    while true do
        local sleep = 1000
        local best, bestGap = nil, 15.0
        local pos = GetEntityCoords(PlayerPedId())
        for _, e in ipairs(liveRows()) do
            local item = itemOf(e.row.item)
            if item and item.use == 'tv' and e.row.data and e.row.data.playing and e.row.data.url and e.row.data.url ~= '' and DoesEntityExist(e.obj) then
                local gap = #(GetEntityCoords(e.obj) - pos)
                if gap < bestGap then best, bestGap = e, gap end
            end
        end
        if best and (not Furn.tv or Furn.tv.row ~= best.row.id or Furn.tv.url ~= best.row.data.url) then
            local ok, err = pcall(startTv, best)
            if not ok then print(('^1[XS-Housing]^0 TV failed: %s'):format(tostring(err))) end
        elseif best and Furn.tv then
            syncTv(best.row.data)
        elseif not best and Furn.tv then
            stopTv()
        end
        if Furn.tv and best and Furn.tv.row == best.row.id then Furn.tv.entry = best end
        local untilAt = GetGameTimer() + 1000
        while Furn.tv and GetGameTimer() < untilAt do
            tvVolumeTick()
            SetTextRenderId(Furn.tv.rt)
            SetScriptGfxDrawOrder(4)
            SetScriptGfxDrawBehindPausemenu(true)
            DrawSprite('xsh_tv_txd', 'xsh_tv_tex', 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
            SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            Wait(0)
        end
        if Furn.tv then sleep = 0 end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local seen = {}
        for _, e in ipairs(liveRows()) do
            local item = itemOf(e.row.item)
            local d = e.row.data or {}
            if item and item.use == 'music' and d.playing and d.url and d.url ~= '' and DoesEntityExist(e.obj) then
                local name = 'furn_' .. e.row.id
                local c = GetEntityCoords(e.obj)
                seen[name] = true
                Sound.Set(name, {
                    url = d.url, at = d.at, paused = d.paused == true, offset = d.pos, pos = { x = c.x, y = c.y, z = c.z },
                    range = (Config.Music or {}).speakerRange or 20.0, volume = d.volume or 0.5,
                })
            end
        end
        for name in pairs(Sound.sources) do
            if name:sub(1, 5) == 'furn_' and not seen[name] then Sound.Set(name, nil) end
        end
    end
end)

function Furn.Reseason()
    local st = Inside.state
    if st then
        Furn.ClearInside()
        for _, row in pairs(Furn.insideRows) do place(Furn.inside, st.id, row, true) end
    end
    for id in pairs(Furn.world) do clearWorld(id) end
end

AddStateBagChangeHandler('xshSeason', 'global', function() SetTimeout(500, Furn.Reseason) end)
AddStateBagChangeHandler('xshSeasonHide', 'global', function() SetTimeout(500, Furn.Reseason) end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Furn.ClearInside()
    for id in pairs(Furn.world) do clearWorld(id) end
    stopTv()
end)
