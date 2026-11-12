local function reply(ok, a, b)
    if ok == false then return false, a end
    if ok == true then return true, a end
    return ok, a, b
end

local function cb(name, fn, admin)
    lib.callback.register('XS-Housing:server:' .. name, function(src, ...)
        if not Props.ready then return false, Text('err_starting') end
        if admin and not Builder.Allowed(src) then return false, Text('err_not_admin') end
        local result = table.pack(pcall(fn, src, ...))
        if not result[1] then
            print(('^1[XS-Housing]^0 %s failed: %s'):format(name, tostring(result[2])))
            return false, Text('err_failed')
        end
        return reply(result[2], result[3], result[4])
    end)
end

local function id(v) return tonumber(v) end

cb('props', function()
    local out = {}
    for pid, p in pairs(Props.list) do out[tostring(pid)] = Props.Public(p) end
    return true, out
end)

cb('access', function(src)
    local cid = Framework.GetCitizenId(src)
    local map = Access.MapFor(cid)
    for k, v in pairs(Access.GroupMap(src)) do if not map[k] then map[k] = v end end
    return true, { access = map, cid = cid, agency = Agency.Public(), catalogue = Furniture.Live(), categories = Catalogue.Categories, garage = Garage.name, admin = Builder.Allowed(src) }
end)

cb('enter', function(src, pid) return Enter.Try(src, id(pid)) end)
cb('tour', function(src, pid) return Enter.Tour(src, id(pid)) end)
cb('openHouse', function(src, pid, on) return Enter.OpenHouse(src, id(pid), on == true) end)
cb('exit', function(src) return Enter.Exit(src) end)
cb('ring', function(src, pid, knock) return Enter.Ring(src, id(pid), knock == true) end)
cb('letIn', function(src, pid, visitor) return Enter.LetIn(src, id(pid), visitor) end)
cb('lock', function(src, pid, locked) return Enter.SetLock(src, id(pid), locked == true) end)

cb('listing', function(src, pid)
    local p = Props.Get(id(pid))
    if not p then return false, Text('err_no_place') end
    local quotes = {}
    if p.data.money.buy then quotes.buy = Ownership.Quote(p, 'buy') end
    if p.data.money.rent and Config.Rent.enabled then quotes.rent = Ownership.Quote(p, 'rent') end
    if p.data.money.mortgage and p.data.money.buy and Config.Mortgage.enabled then quotes.mortgage = Ownership.Quote(p, 'mortgage') end
    local cid = Framework.GetCitizenId(src)
    local can, why = Ownership.CanOwnMore(cid, p)
    local mine = Access.Role(src, p.id)
    return true, {
        property = Props.Public(p), description = p.data.description, quotes = quotes, selfServe = Ownership.SelfServeAllowed(),
        agentsOnDuty = Config.Agency.enabled and #Framework.OnDutyJob(Config.Agency.job) or 0, canOwnMore = can, limitReason = why,
        tours = Config.Buying.tours and (p.data.interior.kind == 'shell' or p.data.interior.kind == 'ipl'), tourMinutes = Config.Buying.tourMinutes,
        role = mine, owned = p.owner ~= nil, money = Framework.GetMoney(src), taxPct = Config.Buying.taxPct,
    }
end)

cb('quote', function(_, pid, mode, opts)
    local p = Props.Get(id(pid))
    if not p then return false, Text('err_no_place') end
    return true, Ownership.Quote(p, mode, opts)
end)

cb('acquire', function(src, pid, mode, opts)
    if not Ownership.SelfServeAllowed() then return false, Text('err_agents_only') end
    return Ownership.Acquire(src, id(pid), mode, opts)
end)

cb('sellBack', function(src, pid) return Ownership.SellBack(src, id(pid)) end)
cb('moveOut', function(src, pid) return Ownership.MoveOut(src, id(pid)) end)
cb('payArrears', function(src, pid) return Ownership.PayArrears(src, id(pid)) end)
cb('payOff', function(src, pid) return Ownership.PayOff(src, id(pid)) end)
cb('insure', function(src, pid, on) return Ownership.Insure(src, id(pid), on == true) end)

local function keyList(p)
    local out = {}
    for cid, k in pairs(p.keys or {}) do
        out[#out + 1] = { citizenid = cid, name = k.name, role = k.role, expires = k.expires, online = Framework.SourceOf(cid) ~= nil }
    end
    table.sort(out, function(a, b) return (a.name or '') < (b.name or '') end)
    return out
end

cb('panel', function(src, pid)
    local p = Props.Get(id(pid))
    if not p or not p.owner then return false, Text('err_not_owned') end
    local role = Access.Role(src, p.id)
    if not role then return false, Text('err_no_rights') end
    local rights = {}
    for _, r in ipairs({ 'lock', 'storage', 'furniture', 'keys', 'sell', 'bills', 'security', 'style', 'cameras', 'letin', 'panel' }) do rights[r] = Access.Can(src, p.id, r) == true end
    local ipl = p.data.interior.kind == 'ipl' and Interiors.Ipl(p.data.interior.ipl)
    local styles = {}
    if ipl and ipl.styles and Config.Interiors.styleChanges then
        local allowed = {}
        for _, s in ipairs(p.data.interior.styles or {}) do allowed[s] = true end
        for _, s in ipairs(ipl.styles) do
            if not next(allowed) or allowed[s.id] then styles[#styles + 1] = { id = s.id, label = s.label } end
        end
    end
    local lv = p.owner.storage_level or 0
    local nextUp = Config.Storage.upgrades and Config.Storage.upgrades[lv + 1]
    local s1, w1 = Storage.Size(p, nil, 'storage')
    return true, {
        property = Props.Public(p), role = role, rights = rights, owner = { name = p.owner.name, kind = p.owner.kind, since = p.owner.since, me = p.owner.citizenid == Framework.GetCitizenId(src) },
        statement = Ownership.Statement(p), keys = rights.keys and keyList(p) or {}, maxKeys = Config.Keys.max, guestHours = Config.Keys.guestHours,
        changeLocksPrice = Config.Keys.changeLocksPrice, security = Security.State(p), visitors = (p.owner.prefs or {}).visitors or {},
        prefs = {
            doorbell = (p.owner.prefs or {}).doorbell ~= false, lights = (p.owner.prefs or {}).lights or 'on', houseName = p.owner.house_name or '',
            music = (p.owner.prefs or {}).music or '', musicAt = (p.owner.prefs or {}).musicAt or 0, musicPaused = (p.owner.prefs or {}).musicPaused == true,
            musicPos = (p.owner.prefs or {}).musicPos or 0, musicVolume = math.floor((((p.owner.prefs or {}).musicVolume) or Config.Music.houseVolume or 0.4) * 100 + 0.5),
        },
        locked = p.owner.locked == 1, styles = styles, style = p.owner.style, styleCost = Config.Interiors.styleCost,
        storage = { level = lv, slots = s1, weight = w1, nextUp = nextUp, points = #p.data.points.storage, safes = #p.data.points.safe },
        furniture = { count = p.furnitureCount or 0, limit = (p.data.furniture.limit or 0) > 0 and p.data.furniture.limit or Config.Furniture.limit, yard = p.data.yard.enabled and Config.Yards.enabled },
        tiles = Config.Panel, insurance = Config.Bills.insurance and { price = Config.Bills.insurancePrice, payout = Config.Bills.insurancePayout, days = Config.Bills.insuranceDays } or nil,
        rentEnabled = Config.Rent.enabled, sellBackPct = Config.Ownership.sellBackPct, inside = (Enter.Of(src) or {}).id == p.id,
        open = Security.open[p.id] and { mode = Security.open[p.id].mode, untilAt = Security.open[p.id].untilAt } or nil,
        openHouse = Enter.OpenHouseUntil(p.id), canOpenHouse = (Config.OpenHouse or {}).enabled == true and Enter.CanHostOpenHouse(src, p), openHouseMinutes = (Config.OpenHouse or {}).minutes or 15,
    }
end)

cb('giveKey', function(src, pid, target, role, hours)
    pid = id(pid)
    if not Access.Can(src, pid, 'keys') then return false, Text('err_no_rights') end
    local cid, name
    if tonumber(target) and GetPlayerName(tonumber(target)) then
        cid, name = Framework.GetCitizenId(tonumber(target)), Framework.GetName(tonumber(target))
    else
        cid = Util.Text(target, 64)
        local p = Props.Get(pid)
        local k = p and p.keys[cid]
        name = k and k.name or ''
    end
    if not cid then return false, Text('err_no_player') end
    local myRole = Access.Role(src, pid)
    if role == 'coowner' and myRole ~= 'owner' then return false, Text('err_owner_only') end
    local ok, err = Access.GiveKey(pid, cid, name, role, hours, Framework.GetCitizenId(src))
    if ok then
        Logs.Add('key_give', pid, Logs.Who(src), ('%s (%s)'):format(name or cid, role or 'guest'), 0)
        local target_src = Framework.SourceOf(cid)
        local p = Props.Get(pid)
        if target_src then Framework.Notify(target_src, Text('key_given', { place = p.data.label }), 'success') end
    end
    return ok, err
end)

cb('takeKey', function(src, pid, cid)
    pid = id(pid)
    if not Access.Can(src, pid, 'keys') then return false, Text('err_no_rights') end
    local p = Props.Get(pid)
    local k = p and p.keys[cid]
    if k and k.role == 'coowner' and Access.Role(src, pid) ~= 'owner' then return false, Text('err_owner_only') end
    local ok, err = Access.TakeKey(pid, cid, Framework.GetCitizenId(src))
    if ok then Logs.Add('key_take', pid, Logs.Who(src), k and k.name or cid, 0) end
    return ok, err
end)

cb('changeLocks', function(src, pid)
    pid = id(pid)
    if Access.Role(src, pid) ~= 'owner' then return false, Text('err_owner_only') end
    local price = Config.Keys.changeLocksPrice or 0
    if not Framework.Charge(src, price, 'bank', 'xs-housing-locks') then return false, Text('err_money', { amount = Util.Money(price) }) end
    Access.ClearKeys(pid)
    Logs.Add('locks', pid, Logs.Who(src), Text('log_locks_changed'), price)
    return true
end)

cb('setPrefs', function(src, pid, patch)
    pid = id(pid)
    local p = Props.Get(pid)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, pid, 'panel') then return false, Text('err_no_rights') end
    patch = type(patch) == 'table' and patch or {}
    local prefs = p.owner.prefs or {}
    local fields = {}
    if patch.doorbell ~= nil then prefs.doorbell = patch.doorbell == true end
    if patch.lights ~= nil and (patch.lights == 'on' or patch.lights == 'dim' or patch.lights == 'off') then
        if prefs.utilitiesOff and patch.lights ~= 'off' then return false, Text('err_power_off') end
        prefs.lights = patch.lights
    end
    if patch.music ~= nil or patch.musicPaused ~= nil or patch.musicSeek ~= nil or patch.musicVolume ~= nil then
        local m = Util.Media({ url = prefs.music or '', at = prefs.musicAt, paused = prefs.musicPaused == true, pos = prefs.musicPos, volume = prefs.musicVolume }, {
            url = patch.music, paused = patch.musicPaused, seek = patch.musicSeek,
            volume = patch.musicVolume ~= nil and (tonumber(patch.musicVolume) or 40) / 100 or nil,
        }, os.time())
        prefs.music, prefs.musicAt, prefs.musicPaused, prefs.musicPos, prefs.musicVolume = m.url, m.at, m.paused, m.pos, m.volume
    end
    if patch.clearVisitors then prefs.visitors = {} end
    fields.prefs = prefs
    if patch.houseName ~= nil and Access.Role(src, pid) == 'owner' then fields.house_name = Util.Text(patch.houseName, 40) end
    Props.UpdateOwner(pid, fields)
    for _, other in ipairs(Enter.Who(pid)) do
        TriggerClientEvent('XS-Housing:client:prefs', other, pid, { lights = prefs.lights, music = prefs.music })
    end
    return true
end)

cb('setStyle', function(src, pid, style)
    pid = id(pid)
    local p = Props.Get(pid)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Config.Interiors.styleChanges then return false, Text('err_failed') end
    if not Access.Can(src, pid, 'style') then return false, Text('err_no_rights') end
    local ipl = Interiors.Ipl(p.data.interior.ipl)
    local found = false
    for _, s in ipairs(ipl and ipl.styles or {}) do if s.id == style then found = true end end
    if not found then return false, Text('err_failed') end
    local cost = Config.Interiors.styleCost or 0
    if not Framework.Charge(src, cost, 'bank', 'xs-housing-style') then return false, Text('err_money', { amount = Util.Money(cost) }) end
    Props.UpdateOwner(pid, { style = style })
    for _, other in ipairs(Enter.Who(pid)) do TriggerClientEvent('XS-Housing:client:style', other, pid, style) end
    return true
end)

cb('openStorage', function(src, pid, kind, index) return Storage.Open(src, id(pid), kind, index) end)
cb('upgradeStorage', function(src, pid) return Storage.Upgrade(src, id(pid)) end)
cb('claims', function(src) return true, Storage.Claims(src) end)
cb('openClaim', function(src, claimId, stashId) return Storage.OpenClaim(src, claimId, stashId) end)

cb('worldFurniture', function(src, ids)
    local out = {}
    local everyone = Config.Yards.everyoneSees ~= false
    for _, raw in ipairs(type(ids) == 'table' and ids or {}) do
        local pid = tonumber(raw)
        if pid and Props.Get(pid) then
            local rows = Furniture.World(pid)
            if not everyone and not Access.Role(src, pid) then
                local kept = {}
                for _, r in ipairs(rows) do if r.place ~= 'yard' then kept[#kept + 1] = r end end
                rows = kept
            end
            out[tostring(pid)] = rows
        end
    end
    return true, out
end)
cb('placeFurniture', function(src, pid, item, place, pos, rot) return Furniture.Place(src, id(pid), item, place, pos, rot) end)
cb('moveFurniture', function(src, pid, row, pos, rot) return Furniture.Move(src, id(pid), row, pos, rot) end)
cb('removeFurniture', function(src, pid, row) return Furniture.Remove(src, id(pid), row) end)
cb('furnitureData', function(src, pid, row, patch) return Furniture.SetData(src, id(pid), row, patch) end)

cb('buyLock', function(src, pid) return Security.BuyLock(src, id(pid)) end)
cb('buyAlarm', function(src, pid) return Security.BuyAlarm(src, id(pid)) end)
cb('arm', function(src, pid, on) return Security.Arm(src, id(pid), on == true) end)
cb('addCamera', function(src, pid, at, label) return Security.AddCamera(src, id(pid), at, label) end)
cb('removeCamera', function(src, pid, index) return Security.RemoveCamera(src, id(pid), index) end)
cb('cameras', function(src, pid) return Security.Cameras(src, id(pid)) end)
cb('breakInCheck', function(src, pid) return Security.BreakInCheck(src, id(pid)) end)
cb('breakInResult', function(src, pid, success, bare) return Security.BreakInResult(src, id(pid), success == true, bare == true) end)
cb('repairLock', function(src, pid) return Security.RepairLock(src, id(pid)) end)
cb('raid', function(src, pid) return Security.Raid(src, id(pid)) end)
cb('closeUp', function(src, pid) return Security.Close(src, id(pid)) end)

cb('agency', function(src) return Agency.Data(src) end)
cb('agencyListed', function(src, pid, listed) return Agency.SetListed(src, id(pid), listed == true) end)
cb('agencyPrice', function(src, pid, price, rent) return Agency.SetPrice(src, id(pid), price, rent) end)
cb('agencyOffer', function(src, pid, target, mode, opts) return Agency.Offer(src, id(pid), target, mode, opts) end)
cb('agencyAccept', function(src, offer, accept) return Agency.Accept(src, offer, accept == true) end)
cb('agencyEvict', function(src, pid) return Agency.Evict(src, id(pid)) end)

cb('builderData', function(src) return true, Builder.Data(src) end, true)
cb('builderSave', function(src, pid, data) return Builder.Save(src, pid, data) end, true)
cb('builderDelete', function(src, pid) return Builder.Delete(src, pid) end, true)
cb('builderBulk', function(src, ids, patch) return Builder.Bulk(src, ids, patch) end, true)
cb('builderUnits', function(src, building, template, count, startAt, perFloor) return Builder.Units(src, building, template, count, startAt, perFloor) end, true)
cb('builderPlayers', function(_, q) return true, Builder.FindPlayers(q) end, true)
cb('builderOwner', function(src, pid, action, payload) return Builder.OwnerAction(src, pid, action, payload) end, true)
cb('builderLogs', function(_, filter) return true, Logs.Fetch(filter) end, true)
cb('builderCatalogue', function(src, payload)
    if not (((Config.Admin or {}).rights or {}).catalogue ~= false) then return false, Text('err_no_rights') end
    Furniture.SaveCatalogue(payload)
    Logs.Add('admin', 0, Logs.Who(src), Text('log_catalogue'), 0)
    return true, { catalogue = Furniture.Live(), multiplier = Furniture.multiplier }
end, true)
cb('builderAgency', function(src, place) Agency.SavePlace(place) Logs.Add('admin', 0, Logs.Who(src), Text('log_agency'), 0) return true, Agency.Public() end, true)
cb('builderApprove', function(_, index, approve) return Agency.Approve(index, approve == true), Agency.pending end, true)
cb('builderImport', function(src, from, commit) return Builder.Import(src, from, commit == true) end, true)
cb('builderProblems', function() return true, Builder.Problems() end, true)

cb('builderPreview', function(src, on)
    SetPlayerRoutingBucket(src, on and (90000 + src) or 0)
    return true
end, true)
cb('builderPhoto', function(src, pid, data)
    local p = Props.Get(id(pid))
    if not p then return false, Text('err_no_place') end
    if type(data) ~= 'string' or not data:match('^data:image/jpeg;base64,') or #data > 350000 then return false, Text('err_photo') end
    local copy = Util.Copy(p.data)
    copy.photo = data
    Props.Save(p.id, copy)
    return true
end, true)

cb('builderPicture', function(_, kind, value) return true, Pictures.Get(kind, value) or '' end, true)
cb('builderPictureSave', function(_, kind, value, data) return Pictures.Save(kind, value, data) end, true)

cb('photo', function(_, pid)
    local p = Props.Get(id(pid))
    if not p then return false end
    return true, p.data.photo or ''
end)

cb('homes', function(src) return true, Compat.Homes(src) end)

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    if not Db.Setup() then return end
    Settings.Load()
    Furniture.LoadCatalogue()
    Agency.Load()
    Pictures.Load()
    Props.Load()
    Garage.SyncAll()
    HouseDoors.ApplyAll()
    Props.SyncAll()
    Inventory.Useable(Config.Raids.ramItem, function(src) TriggerClientEvent('XS-Housing:client:raid', src) end)
    for _, src in ipairs(Framework.Players()) do
        local cid = Framework.GetCitizenId(src)
        if cid then Access.Push(cid) end
    end
    print(('^2[XS-Housing]^0 ready · doors: %s · garage: %s · inventory: %s'):format(Doors.name or 'built in', Garage.name or 'none', Inventory.name or 'none'))
end)

Framework.OnLoaded(function(src)
    local cid = Framework.GetCitizenId(src)
    if not cid then return end
    SetTimeout(1500, function()
        if not GetPlayerName(src) then return end
        Access.Push(cid)
        if Config.Starter.enabled and Config.Starter.onFirstSpawn and not Framework.GetMetaData(src, 'xs_housing_starter') then
            Framework.SetMetaData(src, 'xs_housing_starter', true)
            if #Props.OwnedBy(cid) == 0 then Ownership.Starter(src) end
        end
    end)
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(src)
    local cid = Framework.GetCitizenId(src)
    if cid then Access.Push(cid) end
end)

AddEventHandler('QBCore:Server:OnGangUpdate', function(src)
    local cid = Framework.GetCitizenId(src)
    if cid then Access.Push(cid) end
end)

RegisterCommand(Config.Commands.diag, function(src)
    local lines = {
        ('XS-Housing %s'):format(GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or ''),
        ('framework %s · inventory %s · target %s'):format(Framework.name or 'none', Inventory.name or 'none', Config.Bridges.target),
        ('doors %s · garage %s · dispatch %s · banking %s · phone %s'):format(Doors.name or 'built in', Garage.name or 'none', Dispatch.name or 'none', Banking.name or 'none', Phone.name or 'none'),
    }
    local n = 0
    for _ in pairs(Props.list) do n = n + 1 end
    lines[#lines + 1] = ('%d places · %d inside right now'):format(n, (function() local c = 0 for _ in pairs(Enter.inside) do c = c + 1 end return c end)())
    if src > 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'XS-Housing', table.concat(lines, ' | ') } })
        TriggerClientEvent('XS-Housing:client:diag', src)
    else
        lines[#lines + 1] = Text('diag_shells_console')
    end
    for _, l in ipairs(lines) do print('[XS-Housing] ' .. l) end
end, false)

RegisterNetEvent('XS-Housing:server:logout', function()
    local src = source
    local st = Enter.Of(src)
    if not Config.Spawn.logoutInBed or not st or not Access.Role(src, st.id) then return end
    if Framework.name == 'qbox' then
        local ok = pcall(function() exports.qbx_core:Logout(src) end)
        if ok then return end
    end
    if Framework.core and Framework.core.Player and Framework.core.Player.Logout then
        Framework.core.Player.Logout(src)
        TriggerClientEvent('qb-multicharacter:client:chooseChar', src)
    end
end)
