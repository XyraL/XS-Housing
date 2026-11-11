Furniture = { overrides = {}, custom = {}, multiplier = 1.0 }

local function decodeRow(row)
    row.data = Db.Decode(row.data, {}) or {}
    if type(row.data) ~= 'table' then row.data = {} end
    return row
end

local function publicRow(row)
    return { id = row.id, item = row.item, model = row.model, place = row.place, x = row.x, y = row.y, z = row.z, rx = row.rx, ry = row.ry, rz = row.rz, data = row.data }
end

function Furniture.LoadCatalogue()
    local row = MySQL.single.await('SELECT data FROM xs_housing_settings WHERE name = ?', { 'catalogue' })
    local data = row and Db.Decode(row.data, {}) or {}
    Furniture.overrides = type(data.overrides) == 'table' and data.overrides or {}
    Furniture.custom = type(data.custom) == 'table' and data.custom or {}
    Furniture.multiplier = tonumber(data.multiplier) or 1.0
end

function Furniture.SaveCatalogue(payload)
    payload = type(payload) == 'table' and payload or {}
    local overrides, custom = {}, {}
    for id, o in pairs(type(payload.overrides) == 'table' and payload.overrides or {}) do
        if Catalogue.Map[id] and type(o) == 'table' then
            overrides[id] = {
                price = tonumber(o.price) and math.floor(Util.Clamp(o.price, 0, 100000000)) or nil,
                hidden = o.hidden == true or nil,
                label = o.label and Util.Text(o.label, 48) or nil,
                job = o.job and Util.Text(o.job, 48) or nil,
                limit = tonumber(o.limit) and math.floor(Util.Clamp(o.limit, 0, 500)) or nil,
            }
        end
    end
    for _, c in ipairs(type(payload.custom) == 'table' and payload.custom or {}) do
        local model = Util.Text(c.model, 80)
        if model ~= '' and #custom < 300 then
            local id = Util.Text(c.id, 40):gsub('[^%w_]', '')
            if id == '' then id = 'c' .. (#custom + 1) .. '_' .. model:gsub('[^%w_]', ''):sub(1, 20) end
            custom[#custom + 1] = {
                id = id, label = Util.Text(c.label, 48) ~= '' and Util.Text(c.label, 48) or model, model = model,
                category = Util.Text(c.category, 24) ~= '' and Util.Text(c.category, 24) or 'decor',
                price = math.floor(Util.Clamp(c.price or 0, 0, 100000000)),
                where = (c.where == 'inside' or c.where == 'yard') and c.where or 'both',
                use = ({ storage = true, safe = true, fridge = true, sit = true, lie = true, wardrobe = true, light = true, music = true, tv = true })[c.use] and c.use or nil,
                slots = math.floor(Util.Clamp(c.slots or 0, 0, 200)), weight = math.floor(Util.Clamp(c.weight or 0, 0, 5000000)),
                job = Util.Text(c.job, 48), hidden = c.hidden == true, limit = math.floor(Util.Clamp(c.limit or 0, 0, 500)),
                season = (type(c.season) == 'string' and c.season:match('^[%w_]+$') and c.season ~= '') and c.season or nil,
            }
        end
    end
    Furniture.overrides, Furniture.custom = overrides, custom
    Furniture.multiplier = Util.Clamp(tonumber(payload.multiplier) or 1.0, 0.05, 20.0)
    MySQL.query.await('INSERT INTO xs_housing_settings (name, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
        'catalogue', Db.Json({ overrides = overrides, custom = custom, multiplier = Furniture.multiplier }),
    })
    TriggerClientEvent('XS-Housing:client:catalogue', -1, Furniture.Live())
    return true
end

function Furniture.Live()
    local out = {}
    for _, item in ipairs(Catalogue.Items) do
        local o = Furniture.overrides[item.id] or {}
        out[#out + 1] = {
            id = item.id, label = o.label or item.label, model = item.model, category = item.category,
            price = math.floor((o.price or item.price) * Furniture.multiplier), where = item.where, use = item.use,
            slots = item.slots, weight = item.weight, hidden = o.hidden == true, job = o.job or '', limit = o.limit or 0, custom = false,
            season = item.season, offSeason = item.season ~= nil and item.season ~= (Seasons and Seasons.current),
        }
    end
    for _, c in ipairs(Furniture.custom) do
        local copy = Util.Copy(c)
        copy.price = math.floor((c.price or 0) * Furniture.multiplier)
        copy.custom = true
        copy.offSeason = c.season ~= nil and c.season ~= (Seasons and Seasons.current)
        out[#out + 1] = copy
    end
    return out
end

function Furniture.Item(id)
    for _, item in ipairs(Furniture.Live()) do
        if item.id == id then return item end
    end
    return nil
end

local function worldKind(p)
    return p.data.interior.kind == 'mlo' or p.data.type == 'mlo'
end

function Furniture.Inside(id)
    local rows = MySQL.query.await('SELECT * FROM xs_housing_furniture WHERE property_id = ? AND place = ?', { id, 'inside' }) or {}
    local out = {}
    for _, row in ipairs(rows) do out[#out + 1] = publicRow(decodeRow(row)) end
    return out
end

function Furniture.World(id)
    local p = Props.Get(id)
    if not p then return {} end
    local rows
    if worldKind(p) then
        rows = MySQL.query.await('SELECT * FROM xs_housing_furniture WHERE property_id = ?', { id }) or {}
    else
        rows = MySQL.query.await('SELECT * FROM xs_housing_furniture WHERE property_id = ? AND place = ?', { id, 'yard' }) or {}
    end
    local out = {}
    for _, row in ipairs(rows) do out[#out + 1] = publicRow(decodeRow(row)) end
    return out
end

function Furniture.StorageItems(id)
    local rows = MySQL.query.await('SELECT id, item, data FROM xs_housing_furniture WHERE property_id = ?', { id }) or {}
    local out = {}
    for _, row in ipairs(rows) do
        local item = Furniture.Item(row.item)
        if item and (item.use == 'storage' or item.use == 'safe' or item.use == 'fridge') then
            out[#out + 1] = { id = row.id, label = item.label, slots = item.slots or 20, weight = item.weight or 50000, safe = item.use == 'safe', fridge = item.use == 'fridge' }
        end
    end
    return out
end

function Furniture.StorageItem(id, rowId)
    for _, s in ipairs(Furniture.StorageItems(id)) do
        if s.id == rowId then return s end
    end
    return nil
end

local function count(id, place)
    return MySQL.scalar.await('SELECT COUNT(*) FROM xs_housing_furniture WHERE property_id = ? AND place = ?', { id, place }) or 0
end

local function categoryOk(list, category)
    if type(list) ~= 'table' or #list == 0 then return true end
    for _, c in ipairs(list) do if c == category then return true end end
    return false
end

local function within(p, place, pos)
    if place == 'yard' then
        if not p.data.yard.enabled or #p.data.yard.poly < 3 then return false, Text('err_no_yard') end
        if not Util.InPoly(pos, p.data.yard.poly) then return false, Text('err_outside_yard') end
        local base = p.data.door and p.data.door.z or pos.z
        if pos.z > base + (Config.Yards.heightLimit or 6.0) or pos.z < base - 8.0 then return false, Text('err_too_high') end
        return true
    end
    local kind = p.data.interior.kind
    if kind == 'shell' then
        if math.sqrt(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z) > 45.0 then return false, Text('err_outside_house') end
        return true
    elseif kind == 'ipl' then
        local ipl = Interiors.Ipl(p.data.interior.ipl)
        local anchor = ipl and ipl.spawn or p.data.interior.exit
        if not anchor or Util.Distance(pos, anchor) > 60.0 then return false, Text('err_outside_house') end
        return true
    else
        if #p.data.area.poly >= 3 then
            if not Util.InPoly(pos, p.data.area.poly) then return false, Text('err_outside_house') end
            if p.data.area.minZ and pos.z < p.data.area.minZ then return false, Text('err_outside_house') end
            if p.data.area.maxZ and pos.z > p.data.area.maxZ then return false, Text('err_outside_house') end
            return true
        end
        if not p.data.door or Util.Distance(pos, p.data.door) > 30.0 then return false, Text('err_outside_house') end
        return true
    end
end

local function canFurnish(src, p)
    if not Config.Furniture.enabled or p.data.furniture.allowed == false then return false, Text('err_furniture_off') end
    if not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, p.id, 'furniture') then return false, Text('err_no_rights') end
    return true
end

local function broadcast(p, place, action, row)
    if place == 'inside' and not worldKind(p) then
        for _, other in ipairs(Enter.Who(p.id)) do
            TriggerClientEvent('XS-Housing:client:furniture', other, p.id, action, row)
        end
    else
        TriggerClientEvent('XS-Housing:client:worldFurniture', -1, p.id, action, row)
    end
end

function Furniture.Place(src, id, itemId, place, pos, rot)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local ok, why = canFurnish(src, p)
    if not ok then return false, why end
    local item = Furniture.Item(itemId)
    if not item or item.hidden then return false, Text('err_no_item') end
    if item.offSeason then return false, Text('err_off_season') end
    if item.job and item.job ~= '' then
        local job = Framework.GetJob(src)
        if not job or job.name ~= item.job then return false, Text('err_job_item') end
    end
    place = place == 'yard' and 'yard' or 'inside'
    if place == 'yard' and not Config.Yards.enabled then return false, Text('err_no_yard') end
    if item.where ~= 'both' and item.where ~= place then return false, Text(place == 'yard' and 'err_inside_only_item' or 'err_yard_only_item') end
    local cats = place == 'yard' and p.data.yard.categories or p.data.furniture.categories
    if not categoryOk(cats, item.category) then return false, Text('err_category') end
    pos = Util.Vec(pos)
    if not pos then return false, Text('err_failed') end
    local fine, reason = within(p, place, pos)
    if not fine then return false, reason end
    local limit = place == 'yard' and ((p.data.yard.limit or 0) > 0 and p.data.yard.limit or Config.Yards.limit) or ((p.data.furniture.limit or 0) > 0 and p.data.furniture.limit or Config.Furniture.limit)
    if count(id, place) >= (limit or 100) then return false, Text('err_furniture_limit', { n = limit }) end
    if (item.limit or 0) > 0 then
        local n = MySQL.scalar.await('SELECT COUNT(*) FROM xs_housing_furniture WHERE property_id = ? AND item = ?', { id, item.id }) or 0
        if n >= item.limit then return false, Text('err_item_limit', { n = item.limit }) end
    end
    if not Framework.Charge(src, item.price, 'bank', 'xs-housing-furniture') then return false, Text('err_money', { amount = Util.Money(item.price) }) end
    rot = type(rot) == 'table' and rot or {}
    local row = {
        property_id = id, item = item.id, model = item.model, place = place,
        x = Util.Round(pos.x, 3), y = Util.Round(pos.y, 3), z = Util.Round(pos.z, 3),
        rx = Util.Round(tonumber(rot.x) or 0, 2), ry = Util.Round(tonumber(rot.y) or 0, 2), rz = Util.Round(tonumber(rot.z) or 0, 2),
        price = item.price, data = {},
    }
    row.id = MySQL.insert.await('INSERT INTO xs_housing_furniture (property_id, item, model, place, x, y, z, rx, ry, rz, price, data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        id, row.item, row.model, place, row.x, row.y, row.z, row.rx, row.ry, row.rz, row.price, '{}',
    })
    if not row.id then return false, Text('err_failed') end
    p.furnitureCount = (p.furnitureCount or 0) + 1
    broadcast(p, place, 'add', publicRow(row))
    return true, publicRow(row)
end

local function rowOf(id, rowId)
    local row = MySQL.single.await('SELECT * FROM xs_housing_furniture WHERE id = ? AND property_id = ?', { tonumber(rowId) or 0, id })
    return row and decodeRow(row) or nil
end

function Furniture.Move(src, id, rowId, pos, rot)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local ok, why = canFurnish(src, p)
    if not ok then return false, why end
    local row = rowOf(id, rowId)
    if not row then return false, Text('err_failed') end
    pos = Util.Vec(pos)
    if not pos then return false, Text('err_failed') end
    local fine, reason = within(p, row.place, pos)
    if not fine then return false, reason end
    rot = type(rot) == 'table' and rot or {}
    row.x, row.y, row.z = Util.Round(pos.x, 3), Util.Round(pos.y, 3), Util.Round(pos.z, 3)
    row.rx, row.ry, row.rz = Util.Round(tonumber(rot.x) or 0, 2), Util.Round(tonumber(rot.y) or 0, 2), Util.Round(tonumber(rot.z) or 0, 2)
    MySQL.update.await('UPDATE xs_housing_furniture SET x = ?, y = ?, z = ?, rx = ?, ry = ?, rz = ? WHERE id = ?', { row.x, row.y, row.z, row.rx, row.ry, row.rz, row.id })
    broadcast(p, row.place, 'update', publicRow(row))
    return true, publicRow(row)
end

function Furniture.Remove(src, id, rowId)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local ok, why = canFurnish(src, p)
    if not ok then return false, why end
    local row = rowOf(id, rowId)
    if not row then return false, Text('err_failed') end
    MySQL.query.await('DELETE FROM xs_housing_furniture WHERE id = ?', { row.id })
    p.furnitureCount = math.max(0, (p.furnitureCount or 1) - 1)
    local refund = math.floor((row.price or 0) * (Config.Furniture.refundPct or 0) / 100)
    if refund > 0 then Framework.AddMoney(src, 'bank', refund, 'xs-housing-furniture-refund') end
    broadcast(p, row.place, 'remove', { id = row.id })
    return true, refund
end

function Furniture.SetData(src, id, rowId, patch)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local role = Access.Role(src, id)
    if not role then return false, Text('err_no_rights') end
    local row = rowOf(id, rowId)
    if not row then return false, Text('err_failed') end
    local item = Furniture.Item(row.item)
    patch = type(patch) == 'table' and patch or {}
    if item and item.use == 'light' and patch.on ~= nil then row.data.on = patch.on == true end
    if item and (item.use == 'music' or item.use == 'tv') then
        local now = os.time()
        local before = row.data.url
        if patch.playing ~= nil then row.data.playing = patch.playing == true end
        Util.Media(row.data, { url = patch.url, paused = patch.paused, seek = patch.seek, volume = patch.volume }, now)
        if patch.playing == true and patch.url == nil and row.data.url == before then row.data.at, row.data.paused, row.data.pos = now, false, 0 end
    end
    MySQL.update.await('UPDATE xs_housing_furniture SET data = ? WHERE id = ?', { Db.Json(row.data), row.id })
    broadcast(p, row.place, 'update', publicRow(row))
    return true, publicRow(row)
end

function Furniture.Wipe(id, withRefund)
    local total = 0
    if withRefund then
        total = MySQL.scalar.await('SELECT COALESCE(SUM(price), 0) FROM xs_housing_furniture WHERE property_id = ?', { id }) or 0
        total = math.floor(total * (Config.Furniture.refundPct or 0) / 100)
    end
    MySQL.query.await('DELETE FROM xs_housing_furniture WHERE property_id = ?', { id })
    local p = Props.Get(id)
    if p then p.furnitureCount = 0 end
    TriggerClientEvent('XS-Housing:client:worldFurniture', -1, id, 'reset', nil)
    for _, other in ipairs(Enter.Who(id)) do TriggerClientEvent('XS-Housing:client:furniture', other, id, 'reset', nil) end
    return total
end

function Furniture.Prefurnish(id, set)
    local p = Props.Get(id)
    if not p or type(set) ~= 'table' then return end
    for _, f in ipairs(set) do
        local item = Furniture.Item(f.item)
        if item then
            MySQL.insert.await('INSERT INTO xs_housing_furniture (property_id, item, model, place, x, y, z, rx, ry, rz, price, data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                id, item.id, item.model, f.place == 'yard' and 'yard' or 'inside', tonumber(f.x) or 0, tonumber(f.y) or 0, tonumber(f.z) or 0,
                tonumber(f.rx) or 0, tonumber(f.ry) or 0, tonumber(f.rz) or 0, 0, '{}',
            })
        end
    end
end
