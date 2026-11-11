Places = { blips = {}, zones = {}, signs = {}, mloPoints = {}, garagePoints = {}, agencyBlip = nil }

local SIGN_MODEL = 'prop_forsale_sign_01'
local MAILBOX_MODEL = 'prop_letterbox_01'

local function vec(p) return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0) end

local function hasInterior(p)
    return p.interior and (p.interior.kind == 'shell' or p.interior.kind == 'ipl')
end

local function isMlo(p)
    return p.type == 'mlo' or (p.interior and p.interior.kind == 'mlo')
end

local function openHouse(p)
    return p.openHouse ~= nil and tonumber(p.openHouse) ~= nil and tonumber(p.openHouse) > Util.Now()
end

local function canBreakIn(p)
    local B = Config.BreakIns
    if not B.enabled or not p.security or not p.security.breakIns then return false end
    if p.status == 'sale' or Housing.Role(p.id) then return false end
    if B.item and B.item ~= '' and Inventory.Count(B.item) < 1 then return false end
    return true
end

local function canRaid(p)
    if not Config.Raids.enabled or not p.security or not p.security.raids then return false end
    if p.status == 'sale' then return false end
    return Framework.IsCopLocal()
end

function Places.Enter(p)
    if isMlo(p) then
        Util.Notify(Text('err_walk_in'), 'inform')
        return
    end
    if Config.Entering.doorAnim then
        local ped = PlayerPedId()
        if Util.LoadDict('anim@heists@keycard@') then
            TaskPlayAnim(ped, 'anim@heists@keycard@', 'exit', 8.0, -8.0, 900, 48, 0.0, false, false, false)
            Wait(700)
        end
    end
    Util.Result(Housing.Call('enter', p.id))
end

function Places.ToggleLock(p)
    local locked = not p.locked
    local ok = Util.Result(Housing.Call('lock', p.id, locked))
    if ok then
        if locked then PlaySoundFrontend(-1, 'Generic_Door_Closed', 'GTAO_Script_Doors_Sounds', true) else PlaySoundFrontend(-1, 'door_unlocked', 'dlc_sum20_factory_raid_sounds', true) end
        Util.Notify(locked and Text('locked') or Text('unlocked'), 'success')
    end
end

local function doorOptions(p)
    local opts = {}
    local function add(label, icon, fn, can, distance)
        opts[#opts + 1] = { label = label, icon = icon, distance = distance or 2.0, canInteract = can, onSelect = function() fn(Housing.Prop(p.id) or p) end }
    end
    local get = function() return Housing.Prop(p.id) or p end

    if p.type == 'building' then
        add(Text('opt_lobby'), 'fas fa-building', function(cur) Places.Lobby(cur) end, function() return true end)
        return opts
    end

    add(Text('opt_enter'), 'fas fa-door-open', Places.Enter, function()
        local cur = get()
        if not hasInterior(cur) then return false end
        if Housing.Role(cur.id) then return true end
        if cur.open then return true end
        return cur.status ~= 'sale' and not cur.locked and Config.Entering.unlockedLetsAnyoneIn
    end)
    add(Text('opt_open_house'), 'fas fa-house-circle-check', Places.Enter, function()
        local cur = get()
        return hasInterior(cur) and openHouse(cur) and not Housing.Role(cur.id)
    end)
    add(Text('opt_lock'), 'fas fa-lock', Places.ToggleLock, function()
        local cur = get()
        local role = Housing.Role(cur.id)
        return role ~= nil and role ~= 'guest' and not cur.locked
    end)
    add(Text('opt_unlock'), 'fas fa-lock-open', Places.ToggleLock, function()
        local cur = get()
        local role = Housing.Role(cur.id)
        return role ~= nil and role ~= 'guest' and cur.locked
    end)
    add(Text('opt_panel'), 'fas fa-tablet-screen-button', function(cur) Panel.Open(cur.id) end, function()
        local role = Housing.Role(p.id)
        return role ~= nil and role ~= 'guest' and Config.Panel.lock
    end)
    add(Text('opt_ring'), 'fas fa-bell', function(cur) Util.Result(Housing.Call('ring', cur.id, false)) end, function()
        local cur = get()
        return Config.Doorbell.enabled and cur.status ~= 'sale' and not Housing.Role(cur.id)
    end)
    add(Text('opt_knock'), 'fas fa-hand-back-fist', function(cur)
        local ped = PlayerPedId()
        if Util.LoadDict('timetable@jimmy@doorknock@') then
            TaskPlayAnim(ped, 'timetable@jimmy@doorknock@', 'knockdoor_idle', 8.0, -8.0, 2500, 48, 0.0, false, false, false)
        end
        Util.Result(Housing.Call('ring', cur.id, true))
    end, function()
        local cur = get()
        return Config.Entering.knock and cur.status ~= 'sale' and not Housing.Role(cur.id)
    end)
    add(Text('opt_listing'), 'fas fa-sign-hanging', function(cur) Listing.Open(cur.id) end, function() return get().forSale == true end)
    add(Text('opt_tour'), 'fas fa-eye', function(cur) Util.Result(Housing.Call('tour', cur.id)) end, function()
        local cur = get()
        return cur.forSale == true and Config.Buying.tours and hasInterior(cur)
    end)
    add(Text('opt_breakin'), 'fas fa-user-secret', function(cur) Security.BreakIn(cur) end, function() return canBreakIn(get()) end)
    add(Text('opt_raid'), 'fas fa-shield-halved', function(cur) Security.Raid(cur) end, function()
        local cur = get()
        return canRaid(cur) and not cur.open
    end)
    add(Text('opt_inspect_lock'), 'fas fa-magnifying-glass', function(cur) Security.InspectLock(cur) end, function()
        local cur = get()
        return tonumber(cur.forced) ~= nil and Framework.IsCopLocal()
    end)
    add(Text('opt_secure'), 'fas fa-door-closed', function(cur) Util.Result(Housing.Call('closeUp', cur.id)) end, function()
        local cur = get()
        return cur.open == true and (Framework.IsCopLocal() or Housing.Role(cur.id) ~= nil)
    end)
    return opts
end

function Places.Lobby(b)
    local menu = { id = 'xsh_lobby', title = b.label, options = {} }
    local units = b.units or {}
    if #units == 0 then
        menu.options[#menu.options + 1] = { title = Text('lobby_empty'), disabled = true }
    end
    for _, u in ipairs(units) do
        local p = Housing.Prop(u.id)
        if p then
            local role = Housing.Role(u.id)
            local status = role and Text('role_' .. role) or (u.forSale and Text('status_sale_price', { price = Util.Money(u.price) }) or Text('status_' .. u.status))
            local sub = { id = 'xsh_unit_' .. u.id, title = p.label, menu = 'xsh_lobby', options = {} }
            local function opt(title, icon, fn, show)
                if show then sub.options[#sub.options + 1] = { title = title, icon = icon, onSelect = function() CreateThread(function() fn(Housing.Prop(u.id)) end) end } end
            end
            local cur = p
            opt(Text('opt_enter'), 'door-open', Places.Enter, hasInterior(cur) and (role ~= nil or cur.open or (cur.status ~= 'sale' and not cur.locked and Config.Entering.unlockedLetsAnyoneIn)))
            opt(Text('opt_open_house'), 'house-circle-check', Places.Enter, hasInterior(cur) and openHouse(cur) and not role)
            opt(cur.locked and Text('opt_unlock') or Text('opt_lock'), cur.locked and 'lock-open' or 'lock', Places.ToggleLock, role ~= nil and role ~= 'guest')
            opt(Text('opt_panel'), 'tablet-screen-button', function(x) Panel.Open(x.id) end, role ~= nil and role ~= 'guest')
            opt(Text('opt_buzz'), 'bell', function(x) Util.Result(Housing.Call('ring', x.id, false)) end, Config.Doorbell.enabled and not role and cur.status ~= 'sale')
            opt(Text('opt_listing'), 'sign-hanging', function(x) Listing.Open(x.id) end, cur.forSale == true)
            opt(Text('opt_tour'), 'eye', function(x) Util.Result(Housing.Call('tour', x.id)) end, cur.forSale == true and Config.Buying.tours and hasInterior(cur))
            opt(Text('opt_breakin'), 'user-secret', function(x) Security.BreakIn(x) end, canBreakIn(cur))
            opt(Text('opt_raid'), 'shield-halved', function(x) Security.Raid(x) end, canRaid(cur) and not cur.open)
            if #sub.options == 0 then sub.options[1] = { title = Text('lobby_nothing'), disabled = true } end
            lib.registerContext(sub)
            menu.options[#menu.options + 1] = { title = p.label, description = status, icon = role and 'key' or (u.forSale and 'sign-hanging' or 'door-closed'), menu = sub.id }
        end
    end
    lib.registerContext(menu)
    lib.showContext(menu.id)
end

local function blipStyle(p)
    if p.type == 'building' then return Config.Blips.building end
    local role = Housing.Role(p.id)
    if role == 'owner' then return Config.Blips.owned end
    if role then return Config.Blips.keys end
    if p.forSale then
        local B = Config.Blips.forSale
        if B.agentsOnly then
            local job = Framework.Job()
            if not job or job.name ~= Config.Agency.job then return nil end
        end
        return B
    end
    return nil
end

local function clearBlip(id)
    local b = Places.blips[id]
    if b and DoesBlipExist(b) then RemoveBlip(b) end
    Places.blips[id] = nil
end

local function makeBlip(p)
    clearBlip(p.id)
    if not p.enabled or (p.blip and p.blip.show == false) then return end
    if p.type == 'unit' then return end
    local style = blipStyle(p)
    if not style or not style.show then return end
    local door = Housing.DoorOf(p)
    if not door then return end
    local blip = AddBlipForCoord(door.x + 0.0, door.y + 0.0, door.z + 0.0)
    SetBlipSprite(blip, (p.blip and p.blip.sprite or 0) > 0 and p.blip.sprite or style.sprite or 40)
    SetBlipColour(blip, (p.blip and (p.blip.colour or -1) >= 0) and p.blip.colour or style.colour or 0)
    SetBlipScale(blip, style.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    local label = (p.blip and p.blip.label ~= '' and p.blip.label) or (p.houseName ~= '' and p.houseName) or p.label
    if p.forSale and not Housing.Role(p.id) and p.type ~= 'building' then label = Text('blip_for_sale', { name = p.label }) end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    Places.blips[p.id] = blip
end

local function agencyBlip()
    if Places.agencyBlip and DoesBlipExist(Places.agencyBlip) then RemoveBlip(Places.agencyBlip) end
    Places.agencyBlip = nil
    local a = Housing.agency or {}
    local B = Config.Blips.agency
    if not a.enabled or not a.office or not B.show or a.blip == false then return end
    local blip = AddBlipForCoord(a.office.x + 0.0, a.office.y + 0.0, a.office.z + 0.0)
    SetBlipSprite(blip, B.sprite or 375)
    SetBlipColour(blip, B.colour or 2)
    SetBlipScale(blip, B.scale or 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(a.label or Text('agency_name'))
    EndTextCommandSetBlipName(blip)
    Places.agencyBlip = blip
end

local function clearZone(id)
    Target.Remove('door_' .. id)
    for i = 1, 8 do Target.Remove(('xdoor_%d_%d'):format(id, i)) end
    Places.zones[id] = nil
end

local function makeZone(p)
    clearZone(p.id)
    if not p.enabled or p.type == 'unit' then return end
    local door = p.door
    if not door then return end
    local opts = doorOptions(p)
    Target.AddPoint('door_' .. p.id, vec(door), 1.1, opts)
    for i, d in ipairs(p.extraDoors or {}) do
        Target.AddPoint(('xdoor_%d_%d'):format(p.id, i), vec(d), 1.0, opts)
    end
    Places.zones[p.id] = true
end

local function refresh(p)
    if not p then return end
    makeZone(p)
    makeBlip(p)
end

local function removeAll(id)
    clearZone(id)
    clearBlip(id)
    Places.ClearPoints(id)
end

function Places.RefreshAll()
    for id in pairs(Places.zones) do removeAll(id) end
    for id in pairs(Places.blips) do clearBlip(id) end
    for _, p in pairs(Housing.props) do refresh(p) end
    agencyBlip()
end

Housing.On('all', Places.RefreshAll)
Housing.On('access', Places.RefreshAll)
Housing.On('agency', agencyBlip)
Housing.On('prop', function(id, data)
    if data then
        refresh(data)
        if data.type == 'unit' and data.building and data.building > 0 then
            local b = Housing.Prop(data.building)
            if b then refresh(b) end
        end
    else
        removeAll(tonumber(id))
    end
end)

local function spawnLocal(model, at, heading)
    if not Util.LoadModel(model) then return nil end
    local obj = CreateObjectNoOffset(joaat(model), at.x + 0.0, at.y + 0.0, at.z + 0.0, false, false, false)
    SetEntityHeading(obj, (heading or 0.0) + 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(joaat(model))
    return obj
end

local function signSpot(p)
    if p.points and p.points.sign and p.points.sign[1] then return p.points.sign[1], p.points.sign[1].w end
    local d = p.door
    if not d then return nil end
    local h = math.rad(d.w or 0.0)
    return { x = d.x - math.sin(h) * -2.2 + math.cos(h) * 1.4, y = d.y + math.cos(h) * -2.2 + math.sin(h) * 1.4, z = d.z - 1.0 }, (d.w or 0.0) + 180.0
end

local function mailboxSpot(p)
    if p.points and p.points.mailbox and p.points.mailbox[1] then return p.points.mailbox[1] end
    return nil
end

Places.panelSigs = {}

local function panelScreens(p, signs, near)
    local model = Config.Panel.prop
    local list = (near and model and model ~= '' and isMlo(p) and p.points and p.points.panel) or {}
    local sig = ''
    for _, pt in ipairs(list) do sig = sig .. ('%.2f,%.2f,%.2f,%.1f;'):format(pt.x, pt.y, pt.z, pt.w or 0.0) end
    if (Places.panelSigs[p.id] or '') == sig then return end
    for key, obj in pairs(signs) do
        if key:sub(1, 6) == 'panel_' then
            if DoesEntityExist(obj) then DeleteEntity(obj) end
            signs[key] = nil
        end
    end
    Places.panelSigs[p.id] = sig
    for i, pt in ipairs(list) do
        signs['panel_' .. i] = Housing.WallProp(model, pt, pt.w)
    end
end

function Places.ClearPoints(id)
    Places.panelSigs[id] = nil
    local list = Places.mloPoints[id]
    if list then
        for _, key in ipairs(list) do Target.Remove(key) end
    end
    Places.mloPoints[id] = nil
    local g = Places.garagePoints[id]
    if g then for _, key in ipairs(g) do Target.Remove(key) end end
    Places.garagePoints[id] = nil
    local s = Places.signs[id]
    if s then
        for _, obj in pairs(s) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
    end
    Places.signs[id] = nil
end

local function mloPoints(p)
    if Places.mloPoints[p.id] then return end
    local keys = {}
    local function add(kind, i, pt, label, icon, fn, can)
        local key = ('mlo_%d_%s_%d'):format(p.id, kind, i)
        Target.AddPoint(key, vec(pt), 0.9, { { label = label, icon = icon, onSelect = fn, canInteract = can } })
        keys[#keys + 1] = key
    end
    local function member() return Housing.Role(p.id) ~= nil end
    local function storageCan()
        local cur = Housing.Prop(p.id) or p
        return member() or cur.open == true
    end
    for i, pt in ipairs(p.points.storage or {}) do
        add('storage', i, pt, pt.label ~= '' and pt.label or Text('opt_storage'), 'fas fa-box-open', function() Storage.Open(p.id, 'storage', i) end, storageCan)
    end
    for i, pt in ipairs(p.points.safe or {}) do
        add('safe', i, pt, Text('opt_safe'), 'fas fa-vault', function() Storage.Open(p.id, 'safe', i) end, storageCan)
    end
    for i, pt in ipairs(p.points.wardrobe or {}) do
        add('wardrobe', i, pt, Text('opt_wardrobe'), 'fas fa-shirt', function() Clothing.OpenOutfits() end, member)
    end
    for i, pt in ipairs(p.points.panel or {}) do
        add('panel', i, pt, Text('opt_panel'), 'fas fa-tablet-screen-button', function() Panel.Open(p.id) end, function()
            local role = Housing.Role(p.id)
            return role ~= nil and role ~= 'guest'
        end)
    end
    Places.mloPoints[p.id] = keys
end

local function garagePoints(p)
    if Places.garagePoints[p.id] or not Garage.OwnPrompts() then return end
    if not p.garage or not p.garage.enabled then return end
    local keys = {}
    for i, spot in ipairs(p.garage.spots or {}) do
        local key = ('garage_%d_%d'):format(p.id, i)
        Target.AddPoint(key, vec(spot), 2.5, {
            { label = Text('opt_garage_open'), icon = 'fas fa-warehouse', onSelect = function() Garage.Open(spot) end, canInteract = function()
                local role = Housing.Role(p.id)
                return role ~= nil and role ~= 'guest' and not IsPedInAnyVehicle(PlayerPedId(), false)
            end },
            { label = Text('opt_garage_store'), icon = 'fas fa-square-parking', onSelect = function() Garage.Store() end, canInteract = function()
                local role = Housing.Role(p.id)
                return role ~= nil and role ~= 'guest' and IsPedInAnyVehicle(PlayerPedId(), false)
            end, distance = 5.0 },
        })
        keys[#keys + 1] = key
    end
    Places.garagePoints[p.id] = keys
end

local function stream()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local signRange = Config.Performance.signDistance or 40.0
    local near = {}
    for _, p in pairs(Housing.props) do
        local door = Housing.DoorOf(p)
        if door and p.enabled then
            local d = #(pos - vec(door))
            if d < (Config.Performance.drawDistance or 60.0) + 40.0 then near[#near + 1] = p.id end
            local signs = Places.signs[p.id] or {}
            if p.forSale and p.type ~= 'unit' and d < signRange then
                if not signs.sign then
                    local at, h = signSpot(p)
                    if at then signs.sign = spawnLocal(SIGN_MODEL, at, h) end
                    if signs.sign then
                        Target.AddEntity('sign_' .. p.id, signs.sign, { { label = Text('opt_listing'), icon = 'fas fa-sign-hanging', onSelect = function() Listing.Open(p.id) end } })
                    end
                end
            elseif signs.sign then
                Target.RemoveEntity('sign_' .. p.id)
                if DoesEntityExist(signs.sign) then DeleteEntity(signs.sign) end
                signs.sign = nil
            end
            local box = mailboxSpot(p)
            if box and d < signRange then
                if not signs.mailbox then signs.mailbox = spawnLocal(MAILBOX_MODEL, box, box.w) end
            elseif signs.mailbox then
                if DoesEntityExist(signs.mailbox) then DeleteEntity(signs.mailbox) end
                signs.mailbox = nil
            end
            panelScreens(p, signs, d < signRange)
            Places.signs[p.id] = signs
            if d < 45.0 then
                if isMlo(p) then mloPoints(p) end
                if p.garage and p.garage.enabled then garagePoints(p) end
            elseif d > 60.0 then
                if Places.mloPoints[p.id] then
                    for _, key in ipairs(Places.mloPoints[p.id]) do Target.Remove(key) end
                    Places.mloPoints[p.id] = nil
                end
                if Places.garagePoints[p.id] then
                    for _, key in ipairs(Places.garagePoints[p.id]) do Target.Remove(key) end
                    Places.garagePoints[p.id] = nil
                end
            end
        end
    end
    Furn.Stream(near)
end

CreateThread(function()
    while not Housing.ready do Wait(500) end
    while true do
        local ok, err = pcall(stream)
        if not ok then print(('^1[XS-Housing]^0 stream failed: %s'):format(tostring(err))) end
        Wait(1500)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if Config.Entering.markers and Housing.ready then
            local pos = GetEntityCoords(PlayerPedId())
            for _, p in pairs(Housing.props) do
                local door = p.door
                if door and p.enabled and #(pos - vec(door)) < 15.0 then
                    sleep = 0
                    DrawMarker(1, door.x, door.y, door.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.3, 45, 212, 191, 90, false, false, 2, false)
                end
            end
        end
        Wait(sleep)
    end
end)

Places.openBlips = {}

CreateThread(function()
    while true do
        Wait(2000)
        local want = {}
        if (Config.OpenHouse or {}).enabled and Config.OpenHouse.blip and Housing.ready then
            for _, p in pairs(Housing.props) do
                local door = Housing.DoorOf(p)
                if door and openHouse(p) then want[p.id] = door end
            end
        end
        for id, blip in pairs(Places.openBlips) do
            if not want[id] then
                RemoveBlip(blip)
                Places.openBlips[id] = nil
            end
        end
        for id, door in pairs(want) do
            if not Places.openBlips[id] then
                local blip = AddBlipForCoord(door.x + 0.0, door.y + 0.0, door.z + 0.0)
                SetBlipSprite(blip, 40)
                SetBlipColour(blip, 5)
                SetBlipScale(blip, 0.9)
                SetBlipAsShortRange(blip, false)
                SetBlipFlashTimer(blip, 8000)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(Text('openhouse_blip'))
                EndTextCommandSetBlipName(blip)
                Places.openBlips[id] = blip
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(Places.signs) do Places.ClearPoints(id) end
end)
