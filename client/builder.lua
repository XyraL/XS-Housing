Builder = { open = false, preview = nil, quick = false }

local function v3(p) return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0) end

local function here()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
    local zone = GetNameOfZone(pos.x, pos.y, pos.z)
    return {
        x = Util.Round(pos.x, 3), y = Util.Round(pos.y, 3), z = Util.Round(pos.z - 0.98, 3), w = Util.Round(GetEntityHeading(ped), 2),
        street = GetStreetNameFromHashKey(streetHash), zone = zone, area = GetLabelText(zone),
    }
end

local function show(on)
    Builder.open = on
    UI.Focus('builder', on)
    UI.Send('builder', on and 'show' or 'hide', {})
end

local function load()
    local ok, data = Housing.Call('builderData')
    if not ok then return false, data end
    data.here = here()
    return true, data
end

function Builder.Open()
    local ok, data = load()
    if not ok then return Util.Notify(data or Text('err_not_admin'), 'error') end
    UI.Send('builder', 'open', data)
    Builder.open = true
    UI.Focus('builder', true)
end

function Builder.EndPreview()
    local pv = Builder.preview
    if not pv then return end
    Builder.preview = nil
    if pv.shell and DoesEntityExist(pv.shell) then DeleteEntity(pv.shell) end
    if pv.ipl then Ipl.Release() end
    Housing.Call('builderPreview', false)
    Weather.Resume()
    if pv.back then
        SetEntityCoords(PlayerPedId(), pv.back.x + 0.0, pv.back.y + 0.0, pv.back.z + 0.0, false, false, false, false)
    end
end

local function startPreview(prop)
    local interior = prop.interior or {}
    if Builder.preview and Builder.preview.key == (prop.id or 'new') .. ':' .. (interior.kind or '') .. ':' .. (interior.shell or interior.ipl or '') then return Builder.preview end
    Builder.EndPreview()
    if interior.kind ~= 'shell' and interior.kind ~= 'ipl' then return nil end
    local ped = PlayerPedId()
    local back = GetEntityCoords(ped)
    local door = prop.door or Housing.DoorOf({ building = prop.building }) or { x = back.x, y = back.y, z = back.z }
    local pv = { key = (prop.id or 'new') .. ':' .. interior.kind .. ':' .. (interior.shell or interior.ipl or ''), kind = interior.kind, back = { x = back.x, y = back.y, z = back.z } }
    Housing.Call('builderPreview', true)
    Util.Fade(true, 250)
    if interior.kind == 'shell' then
        if not Util.LoadModel(interior.shell, 10000) then
            Util.Fade(false, 250)
            Housing.Call('builderPreview', false)
            Util.Notify(Text('err_shell_missing', { model = tostring(interior.shell) }), 'error')
            return nil
        end
        local origin = Interiors.ShellOrigin(door)
        pv.origin = origin
        pv.shell = CreateObjectNoOffset(joaat(interior.shell), origin.x + 0.0, origin.y + 0.0, origin.z + 0.0, false, false, false)
        FreezeEntityPosition(pv.shell, true)
        local exit = Interiors.ShellExit(interior)
        local w = GetOffsetFromEntityInWorldCoords(pv.shell, exit.x + 0.0, exit.y + 0.0, exit.z + 0.0)
        pv.spawn = { x = w.x, y = w.y, z = w.z + 1.0, w = exit.w }
    else
        local entry = Interiors.Ipl(interior.ipl)
        if not entry then
            Util.Fade(false, 250)
            Housing.Call('builderPreview', false)
            return nil
        end
        Ipl.Apply(entry, interior.defaultStyle)
        pv.ipl = entry
        pv.spawn = Ipl.Spawn(entry, interior.exit)
    end
    Builder.preview = pv
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, pv.spawn.x + 0.0, pv.spawn.y + 0.0, pv.spawn.z + 0.0, false, false, false, false)
    SetEntityHeading(ped, (pv.spawn.w or 0.0) + 0.0)
    local untilAt = GetGameTimer() + 2500
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < untilAt do Wait(25) end
    FreezeEntityPosition(ped, false)
    Weather.Freeze()
    Util.Fade(false, 250)
    return pv
end

local function toLocal(world)
    local pv = Builder.preview
    if pv and pv.shell and DoesEntityExist(pv.shell) then
        local l = GetOffsetFromEntityGivenWorldCoords(pv.shell, world.x + 0.0, world.y + 0.0, world.z + 0.0)
        return { x = Util.Round(l.x, 3), y = Util.Round(l.y, 3), z = Util.Round(l.z, 3), w = Util.Round(world.w or 0.0, 2) }
    end
    return { x = Util.Round(world.x, 3), y = Util.Round(world.y, 3), z = Util.Round(world.z, 3), w = Util.Round(world.w or 0.0, 2) }
end

local INSIDE_KINDS = { storage = true, safe = true, wardrobe = true, panel = true, bed = true, exit = true }

UI.Handle('b:refresh', function() return load() end)
UI.Handle('b:here', function() return true, here() end)

UI.Handle('b:place', function(p)
    p = p or {}
    local prop = p.property or {}
    local inside = INSIDE_KINDS[p.kind] and prop.interior and (prop.interior.kind == 'shell' or prop.interior.kind == 'ipl')
    show(false)
    local ok, result = pcall(function()
        if inside then
            if not startPreview(prop) then return nil end
        else
            Builder.EndPreview()
        end
        local panelProp = p.kind == 'panel' and Config.Panel.prop or nil
        local at = Placement.Start({
            label = p.label, mode = p.mode or 'point', previewModel = panelProp or p.model, previewVehicle = p.vehicle,
            origin = p.origin, existing = p.existing, faceWall = p.kind == 'panel', turn = panelProp and (Config.Panel.propTurn or 0.0) or 0.0,
        })
        if not at then return nil end
        if inside then return toLocal(at) end
        return { x = Util.Round(at.x, 3), y = Util.Round(at.y, 3), z = Util.Round(at.z, 3), w = Util.Round(at.w or 0.0, 2) }
    end)
    show(true)
    if not ok then
        print(('^1[XS-Housing]^0 placing failed: %s'):format(tostring(result)))
        return false, Text('err_failed')
    end
    if not result then return false, Text('cancelled') end
    if not inside and p.kind == 'door' then
        local street = GetStreetNameAtCoord(result.x, result.y, result.z)
        local zone = GetNameOfZone(result.x, result.y, result.z)
        result.street, result.zone, result.area = GetStreetNameFromHashKey(street), zone, GetLabelText(zone)
    end
    return true, result
end)

UI.Handle('b:polygon', function(p)
    p = p or {}
    show(false)
    local ok, result = pcall(Polygon.Draw, { label = p.label, start = p.start, origin = p.origin and v3(p.origin) or nil, height = p.height })
    show(true)
    if not ok then return false, Text('err_failed') end
    if not result then return false, Text('cancelled') end
    return true, result
end)

UI.Handle('b:showShape', function(p)
    show(false)
    CreateThread(function()
        local untilAt = GetGameTimer() + 9000
        lib.showTextUI(Text('builder_showing'), { position = 'top-center' })
        while GetGameTimer() < untilAt do
            Wait(0)
            if IsControlJustPressed(0, 194) then break end
            Polygon.DrawOutline(p.poly or {}, (p.z or 0.0), 45, 212, 191, p.height or 2.0)
        end
        lib.hideTextUI()
        show(true)
    end)
    return true
end)

UI.Handle('b:pickDoor', function()
    show(false)
    local picked = nil
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    SetCamCoord(cam, pos.x, pos.y, pos.z + 0.7)
    SetCamRot(cam, 0.0, 0.0, GetEntityHeading(ped), 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 250, true, true)
    FreezeEntityPosition(ped, true)
    lib.showTextUI(Text('pick_door_hint'), { position = 'left-center' })
    while true do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 191, true)
        EnableControlAction(0, 194, true)
        local c = GetCamCoord(cam)
        local rot = GetCamRot(cam, 2)
        SetCamRot(cam, math.max(-89.0, math.min(89.0, rot.x - GetDisabledControlNormal(0, 2) * 6.0)), 0.0, rot.z - GetDisabledControlNormal(0, 1) * 6.0, 2)
        local move = vector3(0.0, 0.0, 0.0)
        local r = math.rad(rot.z)
        local fwd = vector3(-math.sin(r), math.cos(r), 0.0)
        local right = vector3(fwd.y, -fwd.x, 0.0)
        if IsDisabledControlPressed(0, 32) then move = move + fwd end
        if IsDisabledControlPressed(0, 33) then move = move - fwd end
        if IsDisabledControlPressed(0, 35) then move = move + right end
        if IsDisabledControlPressed(0, 34) then move = move - right end
        if IsDisabledControlPressed(0, 22) then move = move + vector3(0.0, 0.0, 1.0) end
        if IsDisabledControlPressed(0, 36) then move = move - vector3(0.0, 0.0, 1.0) end
        if #move > 0 then
            c = c + move * 4.0 * GetFrameTime()
            SetCamCoord(cam, c.x, c.y, c.z)
        end
        SetFocusPosAndVel(c.x, c.y, c.z, 0.0, 0.0, 0.0)
        local rx = math.rad(GetCamRot(cam, 2).x)
        local dir = vector3(-math.sin(r) * math.abs(math.cos(rx)), math.cos(r) * math.abs(math.cos(rx)), math.sin(rx))
        local to = c + dir * 12.0
        local ray = StartExpensiveSynchronousShapeTestLosProbe(c.x, c.y, c.z, to.x, to.y, to.z, 16, ped, 4)
        local _, hit, at, _, entity = GetShapeTestResult(ray)
        local isDoor = (hit == true or hit == 1) and entity and entity ~= 0 and GetEntityType(entity) == 3
        if isDoor then
            local min, max = GetModelDimensions(GetEntityModel(entity))
            local e = GetEntityCoords(entity)
            DrawMarker(43, e.x, e.y, e.z + (min.z + max.z) / 2, 0.0, 0.0, 0.0, 0.0, 0.0, GetEntityHeading(entity), max.x - min.x + 0.1, max.y - min.y + 0.1, max.z - min.z + 0.1, 45, 212, 191, 70, false, false, 2, false)
        elseif hit == true or hit == 1 then
            DrawMarker(28, at.x, at.y, at.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, 0.1, 240, 82, 95, 200, false, false, 2, false)
        end
        if IsDisabledControlJustPressed(0, 191) and isDoor then
            local e = GetEntityCoords(entity)
            local id, provider = DoorsClient.Identify(entity)
            picked = { x = Util.Round(e.x, 3), y = Util.Round(e.y, 3), z = Util.Round(e.z, 3), w = Util.Round(GetEntityHeading(entity), 2), model = GetEntityModel(entity), id = id and tostring(id) or nil, provider = provider }
            break
        end
        if IsDisabledControlJustPressed(0, 194) then break end
    end
    lib.hideTextUI()
    RenderScriptCams(false, true, 250, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    ClearFocus()
    FreezeEntityPosition(ped, false)
    show(true)
    if not picked then return false, Text('cancelled') end
    return true, picked
end)

UI.Handle('b:preview', function(p)
    show(false)
    local pv = startPreview(p.property or {})
    if not pv then
        show(true)
        return false, Text('err_preview')
    end
    lib.showTextUI(Text('preview_hint'), { position = 'top-center' })
    CreateThread(function()
        while Builder.preview == pv do
            Wait(0)
            if IsControlJustPressed(0, 194) then break end
        end
        lib.hideTextUI()
        if Builder.preview == pv then Builder.EndPreview() end
        show(true)
    end)
    return true
end)

UI.Handle('b:endPreview', function()
    Builder.EndPreview()
    return true
end)

UI.Handle('b:teleport', function(p)
    if not p or not p.x then return false end
    Builder.EndPreview()
    Util.Teleport({ x = p.x, y = p.y, z = p.z + 1.0 }, p.w)
    return true
end)

UI.Handle('b:walk', function(p)
    show(false)
    local labels = p.labels or {}
    CreateThread(function()
        lib.showTextUI(Text('walk_hint'), { position = 'top-center' })
        while true do
            Wait(0)
            if IsControlJustPressed(0, 194) then break end
            local pos = GetEntityCoords(PlayerPedId())
            for _, l in ipairs(labels) do
                local at = v3(l)
                if #(pos - at) < 60.0 then
                    DrawMarker(28, at.x, at.y, at.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18, 0.18, 0.18, 45, 212, 191, 160, false, false, 2, false)
                    local onScreen, sx, sy = World3dToScreen2d(at.x, at.y, at.z + 0.5)
                    if onScreen then
                        SetTextScale(0.0, 0.32)
                        SetTextFont(4)
                        SetTextColour(255, 255, 255, 230)
                        SetTextOutline()
                        SetTextCentre(true)
                        BeginTextCommandDisplayText('STRING')
                        AddTextComponentSubstringPlayerName(l.label or '')
                        EndTextCommandDisplayText(sx, sy)
                    end
                end
            end
            for _, poly in ipairs(p.polys or {}) do Polygon.DrawOutline(poly.poly, poly.z, 45, 212, 191, poly.height or 2.0) end
        end
        lib.hideTextUI()
        show(true)
    end)
    return true
end)

UI.Handle('b:photo', function()
    if GetResourceState('screenshot-basic') ~= 'started' then return false, Text('err_no_screenshot') end
    show(false)
    Wait(400)
    local done = promise.new()
    exports['screenshot-basic']:requestScreenshot({ encoding = 'jpg', quality = 0.7 }, function(data) done:resolve(data) end)
    local data = Citizen.Await(done)
    show(true)
    if type(data) ~= 'string' then return false, Text('err_photo') end
    return true, data
end)

UI.Handle('b:savePhoto', function(p)
    return Housing.Call('builderPhoto', p.id, p.data)
end)

UI.Handle('b:save', function(p) return Housing.Call('builderSave', p.id, p.data) end)
UI.Handle('b:delete', function(p) return Housing.Call('builderDelete', p.id) end)
UI.Handle('b:bulk', function(p) return Housing.Call('builderBulk', p.ids, p.patch) end)
UI.Handle('b:units', function(p) return Housing.Call('builderUnits', p.building, p.template, p.count, p.startAt, p.perFloor) end)
UI.Handle('b:players', function(p) return Housing.Call('builderPlayers', p.q) end)
UI.Handle('b:owner', function(p) return Housing.Call('builderOwner', p.id, p.action, p.payload) end)
UI.Handle('b:logs', function(p) return Housing.Call('builderLogs', p) end)
UI.Handle('b:catalogue', function(p) return Housing.Call('builderCatalogue', p) end)
UI.Handle('b:agency', function(p) return Housing.Call('builderAgency', p) end)
UI.Handle('b:approve', function(p) return Housing.Call('builderApprove', p.index, p.approve) end)
UI.Handle('b:import', function(p) return Housing.Call('builderImport', p.from, p.commit) end)
UI.Handle('b:problems', function() return Housing.Call('builderProblems') end)
UI.Handle('b:settings', function(p) return Housing.Call('builderSettingsSave', p) end)
UI.Handle('b:photoOf', function(p) return Housing.Call('photo', p.id) end)

UI.Handle('b:quick', function(p)
    show(false)
    CreateThread(function() Builder.Quick(p or {}) end)
    return true
end)

UI.OnClose('builder', function()
    Builder.EndPreview()
    Builder.open = false
    UI.Send('builder', 'close', {})
    UI.Focus('builder', false)
end)

local counters = {}

local function zonePrice(zone)
    local prices = Config.AreaPrices or {}
    return prices[zone] or prices.default or 150000
end

function Builder.Quick(opts)
    Builder.quick = true
    local made = 0
    local shell = opts.shell or ((Interiors.Shells[1] or {}).model or '')
    local ipl = opts.ipl
    lib.showTextUI(Text('quick_hint'), { position = 'left-center' })
    while Builder.quick do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        local cam = GetGameplayCamCoord()
        local rot = GetGameplayCamRot(2)
        local x, z = math.rad(rot.x), math.rad(rot.z)
        local dir = vector3(-math.sin(z) * math.abs(math.cos(x)), math.cos(z) * math.abs(math.cos(x)), math.sin(x))
        local to = cam + dir * 20.0
        local ray = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, to.x, to.y, to.z, 1 + 16, PlayerPedId(), 4)
        local _, hit, at = GetShapeTestResult(ray)
        if hit == true or hit == 1 then
            DrawMarker(28, at.x, at.y, at.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 45, 212, 191, 200, false, false, 2, false)
            for _, p in pairs(Housing.props) do
                if p.door and #(vector3(p.door.x, p.door.y, p.door.z) - at) < 30.0 then
                    DrawMarker(28, p.door.x, p.door.y, p.door.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 120, 160, 140, 140, false, false, 2, false)
                end
            end
            if IsControlJustPressed(0, 191) then
                local ped = PlayerPedId()
                local heading = (GetEntityHeading(ped) + 180.0) % 360
                local streetHash = GetStreetNameAtCoord(at.x, at.y, at.z)
                local street = GetStreetNameFromHashKey(streetHash)
                local zone = GetNameOfZone(at.x, at.y, at.z)
                counters[street] = (counters[street] or 0) + 1
                local number = tostring(counters[street])
                local input = lib.inputDialog(Text('quick_title'), {
                    { type = 'input', label = Text('quick_label'), default = ('%s %s'):format(street, number), required = true },
                    { type = 'number', label = Text('quick_price'), default = Config.Builder.priceByArea and zonePrice(zone) or 150000, min = 0 },
                    { type = 'number', label = Text('quick_rent'), default = math.floor((Config.Builder.priceByArea and zonePrice(zone) or 150000) / 100), min = 0 },
                })
                if input then
                    local door = { x = Util.Round(at.x, 3), y = Util.Round(at.y, 3), z = Util.Round(at.z, 3), w = Util.Round(heading, 2) }
                    local h = math.rad(heading)
                    local size = Config.Yards.defaultSize or 12.0
                    local data = {
                        type = Config.Builder.quickType or 'house', label = input[1],
                        address = { street = street, number = number, zone = zone, area = GetLabelText(zone) },
                        door = door,
                        interior = { kind = Config.Builder.quickInterior or 'shell', shell = shell, ipl = ipl or '' },
                        money = { buy = true, price = tonumber(input[2]) or 150000, rent = true, rentPrice = tonumber(input[3]) or 1500, mortgage = true },
                        yard = Config.Builder.quickYard and { enabled = true, shape = 'square', size = size, heading = heading, center = { x = door.x - math.sin(h) * (size / 2 + 1.0), y = door.y + math.cos(h) * (size / 2 + 1.0), z = door.z } } or nil,
                        blip = { show = Config.Builder.quickBlip ~= false },
                    }
                    local ok, res = Housing.Call('builderSave', nil, data)
                    if ok then
                        made = made + 1
                        Util.Notify(Text('quick_made', { label = input[1], id = res and res.id or '?' }), 'success')
                    else
                        Util.Notify(res or Text('err_failed'), 'error')
                    end
                end
            end
        end
        if IsControlJustPressed(0, 194) then break end
    end
    Builder.quick = false
    lib.hideTextUI()
    if made > 0 then Util.Notify(Text('quick_done', { n = made }), 'success') end
    local ok, data = load()
    if ok then UI.Send('builder', 'reload', data) end
    show(true)
end

RegisterCommand(Config.Commands.builder, function()
    Builder.Open()
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Builder.EndPreview() end
end)
