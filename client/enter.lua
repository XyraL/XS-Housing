Inside = { state = nil, restoring = false }
Storage = {}

local function v3(p) return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0) end

function Inside.ToWorld(rel)
    local st = Inside.state
    if not st or not rel then return rel end
    if st.kind == 'shell' and st.shell and DoesEntityExist(st.shell) then
        local w = GetOffsetFromEntityInWorldCoords(st.shell, rel.x + 0.0, rel.y + 0.0, rel.z + 0.0)
        return { x = w.x, y = w.y, z = w.z, w = rel.w }
    end
    return rel
end

function Inside.ToLocal(world)
    local st = Inside.state
    if not st or not world then return world end
    if st.kind == 'shell' and st.shell and DoesEntityExist(st.shell) then
        local l = GetOffsetFromEntityGivenWorldCoords(st.shell, world.x + 0.0, world.y + 0.0, world.z + 0.0)
        return { x = l.x, y = l.y, z = l.z, w = world.w }
    end
    return world
end

function Storage.Open(id, kind, index)
    local ok, data = Housing.Call('openStorage', id, kind, index)
    if not ok then Util.Notify(data or Text('err_failed'), 'error') return end
    if type(data) == 'table' and data.mode ~= 'server' then
        Inventory.OpenStash(data.mode, data.id, data.label, data.slots, data.weight)
    end
end

local function addTarget(st, key, at, radius, options)
    Target.AddPoint(key, v3(at), radius, options)
    st.targets[#st.targets + 1] = key
end

local function lightsMode(mode, utilitiesOff)
    if utilitiesOff then mode = 'off' end
    ClearTimecycleModifier()
    SetArtificialLightsState(false)
    if mode == 'dim' then
        SetTimecycleModifier('v_dark')
        SetTimecycleModifierStrength(0.55)
    elseif mode == 'off' then
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(false)
    end
end

function Inside.Lights(mode)
    local st = Inside.state
    if not st then return end
    st.lights = mode
    lightsMode(mode, st.utilitiesOff)
end

local function areaCentre(poly, z)
    local x, y = 0.0, 0.0
    for _, pt in ipairs(poly) do x, y = x + pt.x, y + pt.y end
    return { x = x / #poly, y = y / #poly, z = z }
end

local function homeMusicSpot(p, pos)
    local st = Inside.state
    if st and st.id == p.id then return st.musicSpot or st.anchor or st.spawn end
    local mlo = p.type == 'mlo' or (p.interior and p.interior.kind == 'mlo')
    if not mlo then return nil end
    local poly = p.area and p.area.poly
    local inArea = poly and #poly >= 3 and Util.InPoly({ x = pos.x, y = pos.y }, poly)
    local door = Housing.DoorOf(p)
    if not inArea and not (door and #(pos - v3(door)) < 12.0) then return nil end
    local panel = p.points and p.points.panel and p.points.panel[1]
    if panel then return panel end
    if poly and #poly >= 3 then return areaCentre(poly, door and door.z or pos.z) end
    return door
end

local function homeMusic()
    local pos = GetEntityCoords(PlayerPedId())
    local music = Config.Music or {}
    local seen = {}
    for _, p in pairs(Housing.props) do
        local m = p.music
        if type(m) == 'table' and type(m.url) == 'string' and m.url ~= '' then
            local spot = homeMusicSpot(p, pos)
            if spot then
                local name = 'home_' .. p.id
                seen[name] = true
                Sound.Set(name, {
                    url = m.url, at = m.at, paused = m.paused == true, offset = m.pos, pos = spot,
                    range = music.houseRange or 25.0, volume = tonumber(m.volume) or music.houseVolume or 0.4,
                })
            end
        end
    end
    for name in pairs(Sound.sources) do
        if name:sub(1, 5) == 'home_' and not seen[name] then Sound.Set(name, nil) end
    end
end

CreateThread(function()
    while true do
        Wait(1000)
        local ok, err = pcall(homeMusic)
        if not ok then print(('^1[XS-Housing]^0 house music failed: %s'):format(tostring(err))) end
    end
end)

local function setupPoints(st, pack)
    local P = pack.points or {}
    local role = pack.role
    local member = role ~= nil
    local function canStorage()
        return member or pack.mode == 'police' or pack.mode == 'burglar' or Inside.state and Inside.state.storageOpen
    end
    addTarget(st, 'in_exit', st.spawn, 1.2, {
        { label = Text('opt_leave'), icon = 'fas fa-door-open', onSelect = function() Housing.Call('exit') end },
        { label = Text('opt_panel'), icon = 'fas fa-tablet-screen-button', onSelect = function() Panel.Open(st.id) end, canInteract = function() return member and role ~= 'guest' end },
    })
    for i, pt in ipairs(P.storage or {}) do
        addTarget(st, 'in_storage_' .. i, Inside.ToWorld(pt), 0.9, {
            { label = (pt.label and pt.label ~= '') and pt.label or Text('opt_storage'), icon = 'fas fa-box-open', onSelect = function() Storage.Open(st.id, 'storage', i) end, canInteract = canStorage },
        })
    end
    for i, pt in ipairs(P.safe or {}) do
        addTarget(st, 'in_safe_' .. i, Inside.ToWorld(pt), 0.8, {
            { label = Text('opt_safe'), icon = 'fas fa-vault', onSelect = function() Storage.Open(st.id, 'safe', i) end, canInteract = canStorage },
        })
    end
    if Config.Wardrobe.enabled then
        for i, pt in ipairs(P.wardrobe or {}) do
            addTarget(st, 'in_wardrobe_' .. i, Inside.ToWorld(pt), 0.9, {
                { label = Text('opt_wardrobe'), icon = 'fas fa-shirt', onSelect = function() Clothing.OpenOutfits() end, canInteract = function() return member end },
            })
        end
    end
    for i, pt in ipairs(P.panel or {}) do
        local at = Inside.ToWorld(pt)
        local screen = Housing.WallProp(Config.Panel.prop, at, pt.w)
        if screen then st.objects[#st.objects + 1] = screen end
        if i == 1 then st.musicSpot = { x = at.x, y = at.y, z = at.z } end
        addTarget(st, 'in_panel_' .. i, at, 0.7, {
            { label = Text('opt_panel'), icon = 'fas fa-tablet-screen-button', onSelect = function() Panel.Open(st.id) end, canInteract = function() return member and role ~= 'guest' end },
        })
    end
    for i, pt in ipairs(P.bed or {}) do
        addTarget(st, 'in_bed_' .. i, Inside.ToWorld(pt), 1.2, {
            { label = Text('opt_sleep'), icon = 'fas fa-bed', onSelect = function() Inside.Sleep() end, canInteract = function() return member and Config.Spawn.logoutInBed end },
        })
    end
end

local function enterPack(pack)
    if Inside.state then Inside.Cleanup(false) end
    local ped = PlayerPedId()
    Util.Fade(true)
    local interior = pack.interior or {}
    local p = Housing.Prop(pack.id) or {}
    local door = pack.door or Housing.DoorOf(p) or Housing.DoorOf({ building = p.building })
    local st = { id = pack.id, kind = interior.kind, mode = pack.mode, role = pack.role, targets = {}, objects = {}, lights = pack.lights, utilitiesOff = pack.utilitiesOff, storageOpen = pack.storageOpen, tourEnds = pack.tourEnds, door = door }

    if interior.kind == 'shell' then
        local origin = Interiors.ShellOrigin(door or { x = 0.0, y = 0.0, z = 0.0 }, pack.id)
        local model = interior.shell ~= '' and interior.shell or (Interiors.Shells[1] and Interiors.Shells[1].model)
        if not model or not Util.LoadModel(model, 10000) then
            Util.Fade(false)
            Util.Notify(Text('err_shell_missing', { model = tostring(model) }), 'error')
            Housing.Call('exit')
            return
        end
        st.origin = origin
        st.shell = CreateObjectNoOffset(joaat(model), origin.x + 0.0, origin.y + 0.0, origin.z + 0.0, false, false, false)
        FreezeEntityPosition(st.shell, true)
        SetEntityHeading(st.shell, 0.0)
        SetModelAsNoLongerNeeded(joaat(model))
        local exit = Interiors.ShellExit(interior)
        local world = GetOffsetFromEntityInWorldCoords(st.shell, exit.x + 0.0, exit.y + 0.0, exit.z + 0.0)
        st.spawn = { x = world.x, y = world.y, z = world.z + 1.0, w = exit.w or 0.0 }
        local mn, mx = GetModelDimensions(joaat(model))
        local centre = GetOffsetFromEntityInWorldCoords(st.shell, (mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z + 1.6)
        st.anchor = { x = centre.x, y = centre.y, z = centre.z }
    elseif interior.kind == 'ipl' then
        local entry = Interiors.Ipl(interior.ipl)
        if not entry then
            Util.Fade(false)
            Util.Notify(Text('err_ipl_missing'), 'error')
            Housing.Call('exit')
            return
        end
        Ipl.Apply(entry, pack.style)
        st.ipl = entry
        st.spawn = Ipl.Spawn(entry, interior.exit)
        st.anchor = entry.center or entry.spawn
    end

    if not st.spawn then
        Util.Fade(false)
        Housing.Call('exit')
        return
    end

    Inside.state = st
    Housing.inside = st
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, st.spawn.x + 0.0, st.spawn.y + 0.0, st.spawn.z + 0.0, false, false, false, false)
    SetEntityHeading(ped, (st.spawn.w or 0.0) + 0.0)
    local untilAt = GetGameTimer() + 2500
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < untilAt do Wait(25) end
    Wait(150)
    FreezeEntityPosition(ped, false)
    Weather.Freeze()
    lightsMode(st.lights, st.utilitiesOff)
    Furn.LoadInside(pack.furniture or {})
    setupPoints(st, pack)
    pcall(homeMusic)
    Inside.restoring = false
    Util.Fade(false)
    Housing.Emit('entered', st)
    if pack.mode == 'tour' then Util.Notify(Text('tour_started', { m = Config.Buying.tourMinutes }), 'inform') end
    if pack.mode == 'burglar' then Util.Notify(Text('burglar_inside'), 'inform') end
end

function Inside.Cleanup(teleportTo)
    local st = Inside.state
    if not st then return end
    for _, key in ipairs(st.targets) do Target.Remove(key) end
    for _, obj in ipairs(st.objects or {}) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    Furn.ClearInside()
    if st.shell and DoesEntityExist(st.shell) then DeleteEntity(st.shell) end
    if st.ipl then Ipl.Release() end
    ClearTimecycleModifier()
    SetArtificialLightsState(false)
    Weather.Resume()
    Inside.state = nil
    Housing.inside = nil
    Housing.Emit('left', st)
    lib.hideTextUI()
    if teleportTo then
        local h = math.rad(teleportTo.w or 0.0)
        local out = { x = teleportTo.x - math.sin(h) * 0.6, y = teleportTo.y + math.cos(h) * 0.6, z = teleportTo.z }
        Util.Teleport(out, ((teleportTo.w or 0.0) + 180.0) % 360)
    end
end

RegisterNetEvent('XS-Housing:client:enter', function(pack)
    CreateThread(function()
        local ok, err = pcall(enterPack, pack)
        if not ok then
            print(('^1[XS-Housing]^0 entering failed: %s'):format(tostring(err)))
            FreezeEntityPosition(PlayerPedId(), false)
            Util.Fade(false)
        end
    end)
end)

RegisterNetEvent('XS-Housing:client:leave', function(door)
    CreateThread(function()
        Inside.restoring = false
        Util.Fade(true)
        Inside.Cleanup(door)
        FreezeEntityPosition(PlayerPedId(), false)
        Util.Fade(false)
    end)
end)

RegisterNetEvent('XS-Housing:client:prefs', function(id, prefs)
    local st = Inside.state
    if not st or st.id ~= id then return end
    if prefs.lights then Inside.Lights(prefs.lights) end
end)

RegisterNetEvent('XS-Housing:client:style', function(id, style)
    local st = Inside.state
    if not st or st.id ~= id or not st.ipl then return end
    Util.Fade(true)
    Ipl.Apply(st.ipl, style)
    Util.Fade(false)
end)

function Inside.Sleep()
    if not Config.Spawn.logoutInBed then return end
    local ok = lib.alertDialog({ header = Text('sleep_title'), content = Text('sleep_body'), centered = true, cancel = true })
    if ok ~= 'confirm' then return end
    Util.Fade(true)
    TriggerServerEvent('XS-Housing:server:logout')
end

CreateThread(function()
    while true do
        local st = Inside.state
        if st then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if st.spawn and pos.z < st.spawn.z - 25.0 then
                SetEntityCoords(ped, st.spawn.x + 0.0, st.spawn.y + 0.0, st.spawn.z + 0.0, false, false, false, false)
            end
            if st.tourEnds then
                local left = st.tourEnds - Util.Now()
                if left >= 0 then lib.showTextUI(Text('tour_left', { t = Util.Clock(left) }), { position = 'top-center' }) end
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

Framework.OnLoaded(function()
    local data = Framework.PlayerData()
    local md = data and data.metadata or {}
    if md.xs_housing_inside then
        Inside.restoring = true
        DoScreenFadeOut(0)
        FreezeEntityPosition(PlayerPedId(), true)
        SetTimeout(9000, function()
            if Inside.restoring then
                Inside.restoring = false
                FreezeEntityPosition(PlayerPedId(), false)
                DoScreenFadeIn(500)
            end
        end)
    end
end)

Framework.OnUnloaded(function()
    if Inside.state then Inside.Cleanup(nil) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Inside.state then
        local door = Inside.state.door
        Inside.Cleanup(nil)
        if door then SetEntityCoords(PlayerPedId(), door.x + 0.0, door.y + 0.0, door.z + 0.0, false, false, false, false) end
    end
end)
