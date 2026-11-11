Props = { list = {}, ready = false }

local TYPES = { house = true, mlo = true, building = true, unit = true, office = true, motel = true, garage = true }
local INTERIORS = { shell = true, ipl = true, mlo = true, none = true }
local SHAPES = { square = true, hexagon = true, circle = true, custom = true }
local POINT_KINDS = { 'storage', 'wardrobe', 'panel', 'bed', 'safe', 'cameras', 'mailbox', 'sign', 'exit', 'garage', 'doors' }

local function num(v, low, high, fallback)
    local n = tonumber(v)
    if not n or n ~= n then return fallback end
    if low and n < low then n = low end
    if high and n > high then n = high end
    return n
end

local function bool(v, fallback)
    if v == nil then return fallback end
    return v == true or v == 1 or v == '1' or v == 'true'
end

local function point(p)
    local out = Util.Point(p)
    if not out then return nil end
    return out
end

local function points(list, max, extra)
    local out = {}
    for _, p in ipairs(type(list) == 'table' and list or {}) do
        local pt = point(p)
        if pt then
            if extra then extra(pt, p) end
            out[#out + 1] = pt
            if #out >= (max or 40) then break end
        end
    end
    return out
end

local function poly(list, max)
    local out = {}
    for _, p in ipairs(type(list) == 'table' and list or {}) do
        local x, y = tonumber(p.x), tonumber(p.y)
        if x and y then out[#out + 1] = { x = Util.Round(x, 2), y = Util.Round(y, 2) } end
        if #out >= (max or 32) then break end
    end
    return out
end

local function strings(list, max, len)
    local out, seen = {}, {}
    for _, v in ipairs(type(list) == 'table' and list or {}) do
        local s = Util.Text(v, len or 32)
        if s ~= '' and not seen[s] then
            seen[s] = true
            out[#out + 1] = s
            if #out >= (max or 20) then break end
        end
    end
    return out
end

function Props.Clean(raw, existing)
    raw = type(raw) == 'table' and raw or {}
    local d = {}
    d.type = TYPES[raw.type] and raw.type or 'house'
    d.label = Util.Text(raw.label, 64)
    if d.label == '' then d.label = Text('default_name_' .. d.type) end
    local a = type(raw.address) == 'table' and raw.address or {}
    d.address = { street = Util.Text(a.street, 64), number = Util.Text(a.number, 12), zone = Util.Text(a.zone, 16), area = Util.Text(a.area, 48) }
    d.tags = strings(raw.tags, 8, 20)
    d.description = Util.Lines(raw.description, 600)
    if raw.photo == 'stored' and existing and type(existing.photo) == 'string' and existing.photo:sub(1, 5) == 'data:' then
        d.photo = existing.photo
    else
        d.photo = type(raw.photo) == 'string' and raw.photo:match('^data:image/jpeg;base64,') and #raw.photo <= 350000 and raw.photo or Util.Text(raw.photo, 400)
    end
    if d.photo ~= '' and not d.photo:match('^https?://') and not d.photo:match('^data:image/') and not d.photo:match('^nui://') then d.photo = '' end
    d.enabled = bool(raw.enabled, true)
    d.listed = bool(raw.listed, true)
    local g = type(raw.group) == 'table' and raw.group or {}
    d.group = { kind = (g.kind == 'job' or g.kind == 'gang') and g.kind or 'none', name = Util.Text(g.name, 48), access = bool(g.access, false), grade = math.floor(num(g.grade, 0, 50, 0)) }
    d.maxCoOwners = math.floor(num(raw.maxCoOwners, 0, 20, 3))
    d.building = math.floor(num(raw.building, 0, nil, 0))
    d.unit = Util.Text(raw.unit, 24)
    d.floor = math.floor(num(raw.floor, -10, 200, 0))
    d.door = point(raw.door)
    d.enterMode = (raw.enterMode == 'target' or raw.enterMode == 'key') and raw.enterMode or 'both'
    d.extraDoors = points(raw.extraDoors, 6, function(pt, src) pt.label = Util.Text(src.label, 32) end)

    local i = type(raw.interior) == 'table' and raw.interior or {}
    d.interior = {
        kind = INTERIORS[i.kind] and i.kind or (d.type == 'mlo' and 'mlo' or 'shell'),
        shell = Util.Text(i.shell, 64),
        ipl = Util.Text(i.ipl, 64),
        exit = point(i.exit),
        styles = strings(i.styles, 20, 48),
        defaultStyle = Util.Text(i.defaultStyle, 48),
        starter = Util.Text(i.starter, 32),
    }
    if d.type == 'building' then d.interior.kind = 'none' end

    d.doors = {}
    for _, door in ipairs(type(raw.doors) == 'table' and raw.doors or {}) do
        local pt = point(door)
        if pt then
            pt.model = tonumber(door.model) and math.floor(tonumber(door.model)) or nil
            pt.id = door.id ~= nil and Util.Text(door.id, 64) or nil
            if pt.id == '' then pt.id = nil end
            pt.label = Util.Text(door.label, 32)
            pt.main = bool(door.main, false)
            d.doors[#d.doors + 1] = pt
            if #d.doors >= 12 then break end
        end
    end

    local ar = type(raw.area) == 'table' and raw.area or {}
    d.area = { poly = poly(ar.poly, 32), minZ = num(ar.minZ, -500, 2000, nil), maxZ = num(ar.maxZ, -500, 2000, nil) }

    local y = type(raw.yard) == 'table' and raw.yard or {}
    d.yard = {
        enabled = bool(y.enabled, false),
        shape = SHAPES[y.shape] and y.shape or 'square',
        size = num(y.size, 2, 120, Config.Yards.defaultSize or 12.0),
        heading = num(y.heading, 0, 360, 0),
        center = point(y.center),
        poly = poly(y.poly, 32),
        minZ = num(y.minZ, -500, 2000, nil),
        maxZ = num(y.maxZ, -500, 2000, nil),
        limit = math.floor(num(y.limit, 0, 1000, 0)),
        categories = strings(y.categories, 30, 24),
    }
    if d.yard.shape ~= 'custom' and d.yard.center then
        d.yard.poly = poly(Util.Shape(d.yard.shape, d.yard.center, d.yard.size, d.yard.heading), 32)
    end

    local gr = type(raw.garage) == 'table' and raw.garage or {}
    d.garage = {
        enabled = bool(gr.enabled, false),
        spots = points(gr.spots, 10),
        max = math.floor(num(gr.max, 1, 50, 2)),
        shared = bool(gr.shared, true),
        label = Util.Text(gr.label, 48),
    }

    local p = type(raw.points) == 'table' and raw.points or {}
    d.points = {
        storage = points(p.storage, 12, function(pt, src)
            pt.slots = math.floor(num(src.slots, 0, 500, 0))
            pt.weight = math.floor(num(src.weight, 0, 10000000, 0))
            pt.label = Util.Text(src.label, 32)
        end),
        safe = points(p.safe, 4, function(pt, src)
            pt.slots = math.floor(num(src.slots, 0, 100, 0))
            pt.weight = math.floor(num(src.weight, 0, 5000000, 0))
        end),
        wardrobe = points(p.wardrobe, 4),
        panel = points(p.panel, 4),
        bed = points(p.bed, 6),
        cameras = points(p.cameras, 12, function(pt, src) pt.label = Util.Text(src.label, 32) end),
        mailbox = points(p.mailbox, 1),
        sign = points(p.sign, 1),
    }

    local m = type(raw.money) == 'table' and raw.money or {}
    d.money = {
        buy = bool(m.buy, d.type ~= 'motel'),
        price = math.floor(num(m.price, 0, 1000000000, 150000)),
        rent = bool(m.rent, true),
        rentPrice = math.floor(num(m.rentPrice, 0, 100000000, 1500)),
        rentDays = num(m.rentDays, 0, 60, 0),
        mortgage = bool(m.mortgage, d.type ~= 'motel'),
        minDepositPct = math.floor(num(m.minDepositPct, 0, 100, 0)),
        interestPct = num(m.interestPct, 0, 100, -1),
        sellBackPct = math.floor(num(m.sellBackPct, -1, 100, -1)),
        commissionPct = num(m.commissionPct, -1, 50, -1),
        renterDeposit = math.floor(num(m.renterDeposit, -1, 20, -1)),
        basePrice = tonumber(m.basePrice) and math.floor(num(m.basePrice, 0, 1000000000, 0)) or nil,
        baseRent = tonumber(m.baseRent) and math.floor(num(m.baseRent, 0, 100000000, 0)) or nil,
    }

    local s = type(raw.security) == 'table' and raw.security or {}
    d.security = {
        lockLevel = math.floor(num(s.lockLevel, 1, 3, 1)),
        maxLevel = math.floor(num(s.maxLevel, 1, 3, 3)),
        alarm = bool(s.alarm, true),
        cameras = bool(s.cameras, true),
        breakIns = bool(s.breakIns, true),
        raids = bool(s.raids, true),
        cooldown = math.floor(num(s.cooldown, 0, 1440, 0)),
        stealPct = math.floor(num(s.stealPct, 0, 100, 100)),
    }

    local f = type(raw.furniture) == 'table' and raw.furniture or {}
    d.furniture = { limit = math.floor(num(f.limit, 0, 2000, 0)), categories = strings(f.categories, 30, 24), allowed = bool(f.allowed, true) }

    local b = type(raw.blip) == 'table' and raw.blip or {}
    d.blip = { show = bool(b.show, true), sprite = math.floor(num(b.sprite, 0, 900, 0)), colour = math.floor(num(b.colour, -1, 85, -1)), label = Util.Text(b.label, 48) }

    d.storage = { slots = math.floor(num((raw.storage or {}).slots, 0, 500, 0)), weight = math.floor(num((raw.storage or {}).weight, 0, 10000000, 0)) }
    d.markers = bool(raw.markers, false)
    d.notes = Util.Lines(raw.notes, 500)
    if existing and existing.created then d.created = existing.created end
    return d
end

local function ownerView(o)
    if not o then return nil end
    return {
        citizenid = o.citizenid, name = o.name, kind = o.kind, since = o.since, next_due = o.next_due, amount = o.amount,
        balance = o.balance, payments_left = o.payments_left, missed = o.missed, deposit = o.deposit, locked = o.locked == 1 or o.locked == true,
        style = o.style, house_name = o.house_name, storage_level = o.storage_level, prefs = o.prefs, security = o.security, paid = o.paid,
    }
end

function Props.Get(id)
    return Props.list[tonumber(id) or -1]
end

function Props.All()
    local out = {}
    for _, p in pairs(Props.list) do out[#out + 1] = p end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

function Props.Status(p)
    if not p.owner then return 'sale' end
    if p.owner.kind == 'rented' then return 'rented' end
    if p.owner.kind == 'mortgage' then return 'mortgage' end
    if p.owner.kind == 'starter' then return 'starter' end
    return 'owned'
end

function Props.ForSale(p)
    if p.owner or not p.data.enabled or p.data.type == 'building' then return false end
    if p.data.listed == false then return false end
    return p.data.money.buy or p.data.money.rent
end

function Props.Price(p)
    local price = p.data.money.price
    if Config.Buying.demand and p.data.address.zone ~= '' then
        price = math.floor(price * (1 + (Props.Demand(p.data.address.zone) / 100)))
    end
    return price
end

local demand = {}

function Props.Demand(zone)
    return math.min(Config.Buying.demandMaxPct or 30, demand[zone] or 0)
end

function Props.Bump(zone)
    if not Config.Buying.demand or not zone or zone == '' then return end
    demand[zone] = math.min(Config.Buying.demandMaxPct or 30, (demand[zone] or 0) + (Config.Buying.demandStepPct or 2))
end

CreateThread(function()
    while true do
        Wait(3600 * 1000)
        for zone, pct in pairs(demand) do
            demand[zone] = math.max(0, pct - 1)
        end
    end
end)

function Props.Public(p)
    local d = p.data
    local o = p.owner
    return {
        id = p.id, type = d.type, label = d.label, address = d.address, tags = d.tags, photo = Props.PhotoRef(d), description = d.description,
        enabled = d.enabled, listed = d.listed, building = d.building, unit = d.unit, floor = d.floor,
        door = d.door, extraDoors = d.extraDoors, enterMode = d.enterMode, doors = d.doors,
        interior = { kind = d.interior.kind, shell = d.interior.shell, ipl = d.interior.ipl, exit = d.interior.exit },
        area = d.area, yard = d.yard, garage = d.garage, points = d.points,
        price = Props.Price(p), rentPrice = d.money.rentPrice, canBuy = d.money.buy, canRent = d.money.rent and Config.Rent.enabled,
        canMortgage = d.money.mortgage and Config.Mortgage.enabled and d.money.buy,
        group = d.group, blip = d.blip, markers = d.markers,
        status = Props.Status(p), forSale = Props.ForSale(p),
        ownerName = o and (o.house_name ~= '' and o.house_name or nil) or nil,
        houseName = o and o.house_name or '',
        style = o and o.style or '',
        locked = o and (o.locked == 1 or o.locked == true) or false,
        security = { lockLevel = (o and o.security and o.security.lock) or d.security.lockLevel, breakIns = d.security.breakIns, raids = d.security.raids },
        forced = Config.BreakIns.brokenLock and o and type(o.security) == 'table' and tonumber(o.security.forced) or nil,
        open = p.openUntil and p.openUntil > os.time() or false,
        openHouse = Enter and Enter.OpenHouseUntil and Enter.OpenHouseUntil(p.id) or nil,
        units = p.units,
        music = Config.Panel.music and o and o.prefs and type(o.prefs.music) == 'string' and o.prefs.music ~= '' and {
            url = o.prefs.music, at = o.prefs.musicAt or 0, paused = o.prefs.musicPaused == true, pos = o.prefs.musicPos or 0, volume = o.prefs.musicVolume,
        } or nil,
    }
end

function Props.PhotoRef(d)
    if type(d.photo) == 'string' and d.photo:sub(1, 5) == 'data:' then return 'stored' end
    return d.photo or ''
end

function Props.Admin(p)
    local data = Util.Copy(p.data)
    data.photo = Props.PhotoRef(p.data)
    local out = { id = p.id, data = data, owner = ownerView(p.owner), keys = {}, furniture = p.furnitureCount or 0, created = p.created, updated = p.updated }
    for cid, k in pairs(p.keys or {}) do
        out.keys[#out.keys + 1] = { citizenid = cid, name = k.name, role = k.role, expires = k.expires }
    end
    return out
end

function Props.Sync(id)
    local p = Props.Get(id)
    if p then
        TriggerClientEvent('XS-Housing:client:prop', -1, id, Props.Public(p))
        if p.data.type == 'unit' and p.data.building > 0 then Props.RefreshUnits(p.data.building) end
    else
        TriggerClientEvent('XS-Housing:client:prop', -1, id, nil)
    end
end

function Props.SyncAll(target)
    local out = {}
    for id, p in pairs(Props.list) do out[tostring(id)] = Props.Public(p) end
    TriggerClientEvent('XS-Housing:client:props', target or -1, out)
end

function Props.RefreshUnits(buildingId)
    local b = Props.Get(buildingId)
    if not b then return end
    local units = {}
    for _, p in pairs(Props.list) do
        if p.data.type == 'unit' and p.data.building == b.id then
            units[#units + 1] = { id = p.id, unit = p.data.unit, floor = p.data.floor, status = Props.Status(p), forSale = Props.ForSale(p), price = Props.Price(p), rentPrice = p.data.money.rentPrice, label = p.data.label }
        end
    end
    table.sort(units, function(a, c)
        if a.floor ~= c.floor then return a.floor < c.floor end
        return tostring(a.unit) < tostring(c.unit)
    end)
    b.units = units
    TriggerClientEvent('XS-Housing:client:prop', -1, b.id, Props.Public(b))
end

local function decodeOwner(row)
    row.prefs = Db.Decode(row.prefs, {}) or {}
    row.security = Db.Decode(row.security, {}) or {}
    if type(row.prefs) ~= 'table' then row.prefs = {} end
    if type(row.security) ~= 'table' then row.security = {} end
    return row
end

function Props.Load()
    local rows = MySQL.query.await('SELECT id, data, created_at, updated_at FROM xs_housing_properties') or {}
    Props.list = {}
    for _, row in ipairs(rows) do
        local data = Db.Decode(row.data, nil)
        if type(data) == 'table' then
            Props.list[row.id] = { id = row.id, data = Props.Clean(data), created = row.created_at, updated = row.updated_at, keys = {}, furnitureCount = 0 }
        end
    end
    for _, row in ipairs(MySQL.query.await('SELECT * FROM xs_housing_owners') or {}) do
        local p = Props.list[row.property_id]
        if p then p.owner = decodeOwner(row) end
    end
    for _, row in ipairs(MySQL.query.await('SELECT * FROM xs_housing_keys') or {}) do
        local p = Props.list[row.property_id]
        if p then p.keys[row.citizenid] = { name = row.name, role = row.role, expires = row.expires, given_by = row.given_by } end
    end
    for _, row in ipairs(MySQL.query.await('SELECT property_id, COUNT(*) AS n FROM xs_housing_furniture GROUP BY property_id') or {}) do
        local p = Props.list[row.property_id]
        if p then p.furnitureCount = tonumber(row.n) or 0 end
    end
    for id, p in pairs(Props.list) do
        if p.data.type == 'building' then Props.RefreshUnits(id) end
    end
    Props.ready = true
    local count = 0
    for _ in pairs(Props.list) do count = count + 1 end
    print(('^2[XS-Housing]^0 %d places loaded.'):format(count))
end

function Props.Save(id, data)
    local now = os.time()
    if id and Props.list[id] then
        local p = Props.list[id]
        p.data = Props.Clean(data, p.data)
        p.updated = now
        MySQL.update.await('UPDATE xs_housing_properties SET data = ?, updated_at = ? WHERE id = ?', { Db.Json(p.data), now, id })
        Props.Sync(id)
        if p.data.type == 'building' then Props.RefreshUnits(id) end
        return p
    end
    local clean = Props.Clean(data)
    local newId = MySQL.insert.await('INSERT INTO xs_housing_properties (data, created_at, updated_at) VALUES (?, ?, ?)', { Db.Json(clean), now, now })
    if not newId then return nil end
    local p = { id = newId, data = clean, created = now, updated = now, keys = {}, furnitureCount = 0 }
    Props.list[newId] = p
    Props.Sync(newId)
    if clean.type == 'building' then Props.RefreshUnits(newId) end
    return p
end

function Props.Delete(id)
    local p = Props.Get(id)
    if not p then return false end
    MySQL.query.await('DELETE FROM xs_housing_properties WHERE id = ?', { id })
    MySQL.query.await('DELETE FROM xs_housing_owners WHERE property_id = ?', { id })
    MySQL.query.await('DELETE FROM xs_housing_keys WHERE property_id = ?', { id })
    MySQL.query.await('DELETE FROM xs_housing_furniture WHERE property_id = ?', { id })
    Props.list[id] = nil
    Props.Sync(id)
    if p.data.type == 'unit' and p.data.building > 0 then Props.RefreshUnits(p.data.building) end
    if p.data.type == 'building' then
        for _, unit in pairs(Props.list) do
            if unit.data.type == 'unit' and unit.data.building == id then
                unit.data.building = 0
                MySQL.update('UPDATE xs_housing_properties SET data = ? WHERE id = ?', { Db.Json(unit.data), unit.id })
                Props.Sync(unit.id)
            end
        end
    end
    return true
end

function Props.SetOwner(id, row)
    local p = Props.Get(id)
    if not p then return end
    if row then
        row.property_id = id
        row.prefs = type(row.prefs) == 'table' and row.prefs or {}
        row.security = type(row.security) == 'table' and row.security or {}
        MySQL.query.await([[INSERT INTO xs_housing_owners (property_id, citizenid, name, kind, since, next_due, amount, balance, payments_left, missed, deposit, locked, style, house_name, storage_level, prefs, security, paid)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE citizenid = VALUES(citizenid), name = VALUES(name), kind = VALUES(kind), since = VALUES(since), next_due = VALUES(next_due),
            amount = VALUES(amount), balance = VALUES(balance), payments_left = VALUES(payments_left), missed = VALUES(missed), deposit = VALUES(deposit),
            locked = VALUES(locked), style = VALUES(style), house_name = VALUES(house_name), storage_level = VALUES(storage_level), prefs = VALUES(prefs),
            security = VALUES(security), paid = VALUES(paid)]], {
            id, row.citizenid, Util.Text(row.name, 100), row.kind or 'owned', row.since or os.time(), row.next_due or 0, row.amount or 0, row.balance or 0,
            row.payments_left or 0, row.missed or 0, row.deposit or 0, (row.locked == false or row.locked == 0) and 0 or 1, row.style or '', Util.Text(row.house_name or '', 64),
            row.storage_level or 0, Db.Json(row.prefs), Db.Json(row.security), row.paid or 0,
        })
        row.locked = (row.locked == false or row.locked == 0) and 0 or 1
        p.owner = row
    else
        MySQL.query.await('DELETE FROM xs_housing_owners WHERE property_id = ?', { id })
        MySQL.query.await('DELETE FROM xs_housing_keys WHERE property_id = ?', { id })
        p.owner = nil
        p.keys = {}
    end
    Props.Sync(id)
end

function Props.UpdateOwner(id, fields)
    local p = Props.Get(id)
    if not p or not p.owner then return false end
    local sets, args = {}, {}
    for k, v in pairs(fields) do
        p.owner[k] = v
        sets[#sets + 1] = ('`%s` = ?'):format(k)
        if k == 'prefs' or k == 'security' then args[#args + 1] = Db.Json(v) else args[#args + 1] = v end
    end
    args[#args + 1] = id
    MySQL.update.await(('UPDATE xs_housing_owners SET %s WHERE property_id = ?'):format(table.concat(sets, ', ')), args)
    Props.Sync(id)
    return true
end

function Props.OwnedBy(cid)
    local out = {}
    for _, p in pairs(Props.list) do
        if p.owner and p.owner.citizenid == cid then out[#out + 1] = p end
    end
    return out
end

function Props.Nearest(coords, maxDistance)
    local best, bestGap = nil, maxDistance or 5.0
    for _, p in pairs(Props.list) do
        local door = p.data.door
        if door then
            local gap = Util.Distance(door, coords)
            if gap < bestGap then best, bestGap = p, gap end
        end
    end
    return best
end

Props.POINT_KINDS = POINT_KINDS
