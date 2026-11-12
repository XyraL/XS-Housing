Builder = {}

local function right(name)
    return ((Config.Admin or {}).rights or {})[name] ~= false
end

function Builder.Allowed(src)
    return Framework.IsAdmin(src)
end

function Builder.Problems()
    local out = {}
    local doors = {}
    for _, p in ipairs(Props.All()) do
        local d = p.data
        local list = {}
        local function add(level, key, vars) list[#list + 1] = { level = level, key = key, vars = vars } end
        if d.type ~= 'unit' and not d.door then add('bad', 'no_door') end
        if d.type == 'unit' and (d.building == 0 or not Props.Get(d.building)) then add('bad', 'no_building') end
        if d.type ~= 'building' then
            if d.interior.kind == 'shell' and (d.interior.shell == '' or (not Interiors.Shell(d.interior.shell) and not d.interior.exit)) then add('warn', 'shell_unknown') end            if d.interior.kind == 'ipl' and not Interiors.Ipl(d.interior.ipl) then add('bad', 'ipl_unknown') end
            if d.interior.kind == 'mlo' or d.type == 'mlo' then
                if #d.doors == 0 then add('warn', 'mlo_no_doors') end
                if #d.area.poly < 3 then add('warn', 'mlo_no_area') end
            end
            if d.money.buy and d.money.price <= 0 then add('warn', 'free_buy') end
            if not d.money.buy and not d.money.rent then add('warn', 'not_sold') end
            if Config.Storage.enabled and #d.points.storage == 0 and d.interior.kind ~= 'none' then add('info', 'no_storage') end
            if Config.Panel.lock and #d.points.panel == 0 and d.interior.kind ~= 'none' then add('info', 'no_panel') end
        end
        if d.yard.enabled and #d.yard.poly < 3 then add('bad', 'yard_shape') end
        if d.garage.enabled and #d.garage.spots == 0 then add('bad', 'garage_spots') end
        if d.door and d.type ~= 'unit' then
            for _, other in ipairs(doors) do
                if Util.Distance(other.door, d.door) < 1.0 then add('warn', 'door_overlap', { id = other.id }) end
            end
            doors[#doors + 1] = { id = p.id, door = d.door }
        end
        if #list > 0 then out[tostring(p.id)] = list end
    end
    return out
end

local function stats()
    local s = { total = 0, owned = 0, rented = 0, mortgage = 0, starter = 0, sale = 0, disabled = 0, buildings = 0, units = 0, furniture = 0 }
    for _, p in pairs(Props.list) do
        s.total = s.total + 1
        if p.data.type == 'building' then s.buildings = s.buildings + 1 end
        if p.data.type == 'unit' then s.units = s.units + 1 end
        if not p.data.enabled then s.disabled = s.disabled + 1 end
        local st = Props.Status(p)
        if p.data.type ~= 'building' then s[st] = (s[st] or 0) + 1 end
        s.furniture = s.furniture + (p.furnitureCount or 0)
    end
    local since = os.time() - 7 * 86400
    s.weekIncome = MySQL.scalar.await("SELECT COALESCE(SUM(amount), 0) FROM xs_housing_logs WHERE at > ? AND kind IN ('buy','rent','mortgage','payment','bill')", { since }) or 0
    s.weekSales = MySQL.scalar.await("SELECT COUNT(*) FROM xs_housing_logs WHERE at > ? AND kind IN ('buy','rent','mortgage','agent_sale')", { since }) or 0
    return s
end

function Builder.Data(src)
    local list = {}
    for _, p in ipairs(Props.All()) do list[#list + 1] = Props.Admin(p) end
    local rights = {}
    for k in pairs((Config.Admin or {}).rights or {}) do rights[k] = right(k) end
    return {
        properties = list,
        interiors = Interiors.Public(),
        pictures = Pictures.Keys(),
        catalogue = Furniture.Live(),
        categories = Catalogue.Categories,
        seasons = Seasons.List(), season = Seasons.current,
        catalogueMultiplier = Furniture.multiplier,
        catalogueOverrides = Furniture.overrides,
        catalogueCustom = Furniture.custom,
        settings = Settings.Builder(),
        jobs = Framework.Jobs(),
        gangs = Framework.Gangs(),
        agency = Agency.Public(),
        pending = Agency.pending,
        problems = Builder.Problems(),
        stats = stats(),
        rights = rights,
        system = {
            framework = Framework.name, target = Config.Bridges.target, inventory = Inventory.name, doorlock = Doors.name, garage = Garage.name,
            dispatch = Dispatch.name, banking = Banking.name, phone = Phone.name, mdt = GetResourceState('XS-MDT') == 'started',
            bob74 = GetResourceState('bob74_ipl') == 'started', screenshot = GetResourceState('screenshot-basic') == 'started',
        },
        areaPrices = Config.AreaPrices,
        me = { name = Framework.GetName(src) or GetPlayerName(src) },
    }
end

function Builder.Save(src, id, data)
    id = tonumber(id)
    local existing = id and Props.Get(id)
    if id and not existing then return false, Text('err_no_place') end
    data = type(data) == 'table' and data or {}
    if existing and not right('prices') then data.money = existing.data.money end
    local p = Props.Save(id, data)
    if not p then return false, Text('err_failed') end
    Garage.Sync(p.id)
    if p.data.type == 'mlo' or p.data.interior.kind == 'mlo' then
        HouseDoors.ApplyAll()
    end
    Logs.Add(existing and 'admin' or 'create', p.id, Logs.Who(src), existing and Text('log_edited') or Text('log_created'), 0)
    return true, Props.Admin(p)
end

function Builder.Delete(src, id)
    if not right('delete') then return false, Text('err_no_rights') end
    local p = Props.Get(tonumber(id))
    if not p then return false, Text('err_no_place') end
    Enter.KickAll(p.id, 'deleted')
    HouseDoors.Release(p)
    local was = Util.Copy(p)
    Props.Delete(p.id)
    Garage.Sync(p.id)
    if was.owner then Access.Push(was.owner.citizenid) end
    for cid in pairs(was.keys or {}) do Access.Push(cid) end
    Logs.Add('delete', p.id, Logs.Who(src), was.data.label, 0)
    return true
end

function Builder.Bulk(src, ids, patch)
    patch = type(patch) == 'table' and patch or {}
    local done = 0
    for _, raw in ipairs(type(ids) == 'table' and ids or {}) do
        local p = Props.Get(tonumber(raw))
        if p then
            local data = Util.Copy(p.data)
            if patch.enabled ~= nil then data.enabled = patch.enabled == true end
            if patch.listed ~= nil then data.listed = patch.listed == true end
            if right('prices') then
                if tonumber(patch.priceMul) then data.money.price = math.floor(data.money.price * Util.Clamp(patch.priceMul, 0.01, 100)) end
                if tonumber(patch.rentMul) then data.money.rentPrice = math.floor(data.money.rentPrice * Util.Clamp(patch.rentMul, 0.01, 100)) end
                if tonumber(patch.price) then data.money.price = math.floor(Util.Clamp(patch.price, 0, 1000000000)) end
                if tonumber(patch.rentPrice) then data.money.rentPrice = math.floor(Util.Clamp(patch.rentPrice, 0, 100000000)) end
                if patch.buy ~= nil then data.money.buy = patch.buy == true end
                if patch.rent ~= nil then data.money.rent = patch.rent == true end
                if patch.mortgage ~= nil then data.money.mortgage = patch.mortgage == true end
            end
            if type(patch.addTag) == 'string' and patch.addTag ~= '' then data.tags[#data.tags + 1] = patch.addTag end
            if type(patch.removeTag) == 'string' then
                for i = #data.tags, 1, -1 do if data.tags[i] == patch.removeTag then table.remove(data.tags, i) end end
            end
            if type(patch.interior) == 'table' then
                for k, v in pairs(patch.interior) do data.interior[k] = v end
            end
            if patch.breakIns ~= nil then data.security.breakIns = patch.breakIns == true end
            if patch.raids ~= nil then data.security.raids = patch.raids == true end
            if patch.blip ~= nil then data.blip.show = patch.blip == true end
            Props.Save(p.id, data)
            Garage.Sync(p.id)
            done = done + 1
        end
    end
    Logs.Add('admin', 0, Logs.Who(src), Text('log_bulk', { n = done }), 0)
    return true, done
end

function Builder.Units(src, buildingId, template, count, startAt, perFloor)
    local b = Props.Get(tonumber(buildingId))
    if not b or b.data.type ~= 'building' then return false, Text('err_no_place') end
    count = math.floor(Util.Clamp(count or 1, 1, 200))
    startAt = math.floor(Util.Clamp(startAt or 1, 0, 9999))
    perFloor = math.floor(Util.Clamp(perFloor or 0, 0, 100))
    template = type(template) == 'table' and template or {}
    local made = {}
    for n = 0, count - 1 do
        local data = Util.Copy(template)
        data.type = 'unit'
        data.building = b.id
        local number = startAt + n
        data.unit = tostring(number)
        data.floor = perFloor > 0 and (math.floor(n / perFloor) + 1) or 0
        data.label = ('%s %s'):format(b.data.label, data.unit)
        data.door = nil
        data.address = Util.Copy(b.data.address)
        data.address.number = data.unit
        local p = Props.Save(nil, data)
        if p then made[#made + 1] = p.id end
    end
    Props.RefreshUnits(b.id)
    Logs.Add('create', b.id, Logs.Who(src), Text('log_units', { n = #made }), 0)
    return true, made
end

local function playerRow(cid)
    local row = MySQL.single.await('SELECT citizenid, charinfo FROM players WHERE citizenid = ?', { cid })
    if not row then return nil end
    local ci = Db.Decode(row.charinfo, {}) or {}
    return { citizenid = row.citizenid, name = Framework.FullName(ci) }
end

function Builder.FindPlayers(q)
    q = Util.Text(q, 40)
    if #q < 2 then return {} end
    local out, seen = {}, {}
    for _, src in ipairs(Framework.Players()) do
        local name = Framework.GetName(src) or ''
        local cid = Framework.GetCitizenId(src) or ''
        if name:lower():find(q:lower(), 1, true) or cid:lower() == q:lower() or tostring(src) == q then
            out[#out + 1] = { citizenid = cid, name = name, online = true, src = src }
            seen[cid] = true
        end
    end
    local like = '%' .. q:gsub('[%%_]', '') .. '%'
    local rows = MySQL.query.await('SELECT citizenid, charinfo FROM players WHERE citizenid = ? OR charinfo LIKE ? LIMIT 25', { q, like }) or {}
    for _, row in ipairs(rows) do
        if not seen[row.citizenid] then
            local ci = Db.Decode(row.charinfo, {}) or {}
            out[#out + 1] = { citizenid = row.citizenid, name = Framework.FullName(ci), online = false }
        end
    end
    return out
end

function Builder.OwnerAction(src, id, action, payload)
    id = tonumber(id)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    payload = type(payload) == 'table' and payload or {}
    local by = Logs.Who(src)
    if action == 'transfer' then
        local who = playerRow(Util.Text(payload.citizenid, 64))
        if not who then return false, Text('err_no_player') end
        return Ownership.Transfer(id, who.citizenid, who.name, by)
    elseif action == 'evict' then
        if not right('evict') then return false, Text('err_no_rights') end
        return Ownership.Evict(id, by, Text('log_evicted_by_staff'))
    elseif action == 'reset' then
        if not right('evict') then return false, Text('err_no_rights') end
        Enter.KickAll(id, 'evicted')
        local cid = p.owner and p.owner.citizenid
        local holders = Access.Holders(id)
        Furniture.Wipe(id, false)
        Props.SetOwner(id, nil)
        for _, h in ipairs(holders) do Access.Push(h) end
        Garage.Refresh(id)
        Logs.Add('admin', id, by, Text('log_reset'), 0)
        return true, cid
    elseif action == 'wipe' then
        Furniture.Wipe(id, false)
        Logs.Add('admin', id, by, Text('log_wiped'), 0)
        return true
    elseif action == 'givekey' then
        local who = playerRow(Util.Text(payload.citizenid, 64))
        if not who then return false, Text('err_no_player') end
        local ok, err = Access.GiveKey(id, who.citizenid, who.name, payload.role, payload.hours, by.citizenid)
        if ok then Logs.Add('key_give', id, by, who.name, 0) end
        return ok, err
    elseif action == 'takekey' then
        local ok, err = Access.TakeKey(id, Util.Text(payload.citizenid, 64), by.citizenid)
        if ok then Logs.Add('key_take', id, by, payload.citizenid, 0) end
        return ok, err
    elseif action == 'unlock' then
        if p.owner then Props.UpdateOwner(id, { locked = 0 }) end
        Doors.SetLocked(p, false, src)
        return true
    elseif action == 'lock' then
        if p.owner then Props.UpdateOwner(id, { locked = 1 }) end
        Doors.SetLocked(p, true, src)
        return true
    elseif action == 'dues' then
        if not p.owner then return false, Text('err_not_owned') end
        Props.UpdateOwner(id, { missed = 0, next_due = (p.owner.kind == 'rented' or p.owner.kind == 'mortgage') and (os.time() + 86400) or 0 })
        Logs.Add('admin', id, by, Text('log_dues_cleared'), 0)
        return true
    end
    return false, Text('err_failed')
end

local function guessShell(name)
    if not name or name == '' then return nil end
    if Interiors.Shell(name) then return name end
    local low = tostring(name):lower()
    for _, s in ipairs(Interiors.Shells) do
        if (s.label or ''):lower() == low or s.model:lower() == low then return s.model end
    end
    return nil
end

local function vecFrom(t)
    if type(t) ~= 'table' then return nil end
    local x, y, z = tonumber(t.x), tonumber(t.y), tonumber(t.z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z, w = tonumber(t.w or t.h or t.heading) or 0.0 }
end

local function tableExists(name)
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', { name })
    return (tonumber(n) or 0) > 0
end

local function columnExists(tbl, col)
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?', { tbl, col })
    return (tonumber(n) or 0) > 0
end

local Importers = {}

Importers['qb-houses'] = function()
    if not tableExists('houselocations') then return nil, Text('err_import_missing', { table = 'houselocations' }) end
    local houses = MySQL.query.await('SELECT * FROM houselocations') or {}
    local owners = tableExists('player_houses') and (MySQL.query.await('SELECT * FROM player_houses') or {}) or {}
    local byHouse = {}
    for _, o in ipairs(owners) do byHouse[o.house] = o end
    local out = {}
    for _, h in ipairs(houses) do
        local coords = Db.Decode(h.coords, {}) or {}
        local door = vecFrom(coords.enter or coords)
        local tiers = Config.ImportTiers or {}
        local shell = tiers[tonumber(h.tier) or 1] or (Interiors.Shells[1] and Interiors.Shells[1].model) or ''
        local garage = Db.Decode(h.garage, nil)
        local item = {
            source = h.name,
            data = {
                type = 'house', label = h.label or h.name, door = door, interior = { kind = 'shell', shell = shell },
                money = { buy = true, price = tonumber(h.price) or 150000, rent = true, rentPrice = math.floor((tonumber(h.price) or 150000) / 100) },
                garage = garage and vecFrom(garage) and { enabled = true, spots = { vecFrom(garage) } } or nil,
            },
        }
        local o = byHouse[h.name]
        if o and o.citizenid then
            item.owner = o.citizenid
            local keys = {}
            for _, cid in ipairs(Db.Decode(o.keyholders, {}) or {}) do
                if type(cid) == 'string' and cid ~= o.citizenid then keys[#keys + 1] = cid end
            end
            item.keys = keys
        end
        out[#out + 1] = item
    end
    return out
end

Importers['qbx_properties'] = function()
    if not tableExists('properties') or not columnExists('properties', 'property_name') then return nil, Text('err_import_missing', { table = 'properties' }) end
    local rows = MySQL.query.await('SELECT * FROM properties') or {}
    local out = {}
    for _, r in ipairs(rows) do
        local door = vecFrom(Db.Decode(r.coords, {}))
        local item = {
            source = tostring(r.id),
            data = {
                type = 'house', label = r.property_name, door = door,
                interior = { kind = 'shell', shell = guessShell(r.interior) or ((Interiors.Shells[1] or {}).model or '') },
                money = { buy = true, price = tonumber(r.price) or 150000, rent = (tonumber(r.rent_interval) or 0) > 0, rentPrice = tonumber(r.price) or 1500 },
            },
        }
        if r.owner and r.owner ~= '' then
            item.owner = r.owner
            local keys = {}
            for _, cid in ipairs(Db.Decode(r.keyholders, {}) or {}) do
                if type(cid) == 'string' then keys[#keys + 1] = cid end
            end
            item.keys = keys
            item.rented = (tonumber(r.rent_interval) or 0) > 0
        end
        out[#out + 1] = item
    end
    return out
end

Importers['ps-housing'] = function()
    if not tableExists('properties') or not columnExists('properties', 'property_id') then return nil, Text('err_import_missing', { table = 'properties' }) end
    local rows = MySQL.query.await('SELECT * FROM properties') or {}
    local out = {}
    for _, r in ipairs(rows) do
        local doorData = Db.Decode(r.door_data, {}) or {}
        local door = vecFrom(doorData)
        local mlo = r.shell == 'mlo'
        local garage = vecFrom(Db.Decode(r.garage_data, nil))
        local item = {
            source = tostring(r.property_id),
            data = {
                type = r.apartment and r.apartment ~= '' and 'unit' or (mlo and 'mlo' or 'house'),
                label = r.apartment and r.apartment ~= '' and r.apartment or ((r.street or '') .. ' ' .. tostring(r.property_id)),
                address = { street = r.street or '', area = r.region or '' }, description = r.description or '',
                door = door, interior = { kind = mlo and 'mlo' or 'shell', shell = guessShell(r.shell) or ((Interiors.Shells[1] or {}).model or '') },
                money = { buy = true, price = tonumber(r.price) or 150000, rent = true, rentPrice = math.floor((tonumber(r.price) or 150000) / 100) },
                garage = garage and { enabled = true, spots = { garage } } or nil,
            },
        }
        if r.owner_citizenid and r.owner_citizenid ~= '' then
            item.owner = r.owner_citizenid
            local keys = {}
            for _, cid in ipairs(Db.Decode(r.has_access, {}) or {}) do
                if type(cid) == 'string' and cid ~= r.owner_citizenid then keys[#keys + 1] = cid end
            end
            item.keys = keys
        end
        out[#out + 1] = item
    end
    return out
end

function Builder.Import(src, from, commit)
    if not right('import') then return false, Text('err_no_rights') end
    local importer = Importers[from]
    if not importer then return false, Text('err_failed') end
    local ok, items, err = pcall(importer)
    if not ok then return false, tostring(items) end
    if not items then return false, err end
    local preview = { total = #items, owned = 0, keys = 0, noDoor = 0 }
    for _, it in ipairs(items) do
        if it.owner then preview.owned = preview.owned + 1 end
        preview.keys = preview.keys + #(it.keys or {})
        if not it.data.door then preview.noDoor = preview.noDoor + 1 end
    end
    if not commit then return true, preview end
    local made = 0
    for _, it in ipairs(items) do
        if it.data.door or it.data.type == 'unit' then
            it.data.notes = Text('imported_from', { from = from, id = it.source })
            local p = Props.Save(nil, it.data)
            if p then
                made = made + 1
                if it.owner then
                    local who = playerRow(it.owner)
                    Props.SetOwner(p.id, {
                        citizenid = it.owner, name = who and who.name or '', kind = it.rented and 'rented' or 'owned',
                        amount = it.rented and p.data.money.rentPrice or 0, next_due = it.rented and (os.time() + Util.Days(Config.Rent.periodDays)) or 0,
                        security = { lock = p.data.security.lockLevel }, prefs = { doorbell = true, lastSeen = os.time() },
                    })
                    for _, cid in ipairs(it.keys or {}) do
                        local holder = playerRow(cid)
                        Access.GiveKey(p.id, cid, holder and holder.name or '', 'coowner', 0, it.owner)
                    end
                    Access.Push(it.owner)
                end
                Garage.Sync(p.id)
            end
        end
    end
    preview.made = made
    Logs.Add('import', 0, Logs.Who(src), Text('log_import', { from = from, n = made }), 0)
    return true, preview
end
