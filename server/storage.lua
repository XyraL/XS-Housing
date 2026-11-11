Storage = {}

local function level(p)
    return math.floor(tonumber(p.owner and p.owner.storage_level) or 0)
end

function Storage.Size(p, point, kind)
    local S = Config.Storage
    local slots, weight = S.slots or 40, S.weight or 200000
    if (p.data.storage.slots or 0) > 0 then slots = p.data.storage.slots end
    if (p.data.storage.weight or 0) > 0 then weight = p.data.storage.weight end
    local lv = level(p)
    local up = lv > 0 and S.upgrades and S.upgrades[lv]
    if up then slots, weight = math.max(slots, up.slots or slots), math.max(weight, up.weight or weight) end
    if point and (point.slots or 0) > 0 then slots = point.slots end
    if point and (point.weight or 0) > 0 then weight = point.weight end
    if kind == 'safe' then
        slots = (point and (point.slots or 0) > 0) and point.slots or 10
        weight = (point and (point.weight or 0) > 0) and point.weight or 50000
    end
    return slots, weight
end

function Storage.Id(p, ownerKey, kind, index)
    local tag = kind == 'safe' and 'v' or (kind == 'furniture' and 'f' or 's')
    return ('xsh_%d_%s_%s%s'):format(p.id, tostring(ownerKey):gsub('[^%w]', ''), tag, tostring(index))
end

function Storage.OwnerStashes(p)
    local out = {}
    if not p.owner then return out end
    local key = p.owner.citizenid
    for i, pt in ipairs(p.data.points.storage or {}) do
        local slots, weight = Storage.Size(p, pt, 'storage')
        out[#out + 1] = { id = Storage.Id(p, key, 'storage', i), label = pt.label ~= '' and pt.label or Text('storage_label', { n = i }), slots = slots, weight = weight }
    end
    for i, pt in ipairs(p.data.points.safe or {}) do
        local slots, weight = Storage.Size(p, pt, 'safe')
        out[#out + 1] = { id = Storage.Id(p, key, 'safe', i), label = Text('safe_label', { n = i }), slots = slots, weight = weight }
    end
    for _, f in ipairs(Furniture and Furniture.StorageItems(p.id) or {}) do
        out[#out + 1] = { id = Storage.Id(p, key, 'furniture', f.id), label = f.label, slots = f.slots, weight = f.weight }
    end
    return out
end

local function insideOrNear(src, p)
    local st = Enter.Of(src)
    if st and st.id == p.id then return true end
    if p.data.interior.kind == 'mlo' or p.data.type == 'mlo' then
        local ped = GetPlayerPed(src)
        local pos = GetEntityCoords(ped)
        if Util.InPoly({ x = pos.x, y = pos.y }, p.data.area.poly) then return true end
        if p.data.door and Util.Distance({ x = pos.x, y = pos.y, z = pos.z }, p.data.door) < 40.0 then return true end
    end
    return false
end

function Storage.CanOpen(src, p, kind)
    if not Config.Storage.enabled then return false, Text('err_storage_off') end
    if not p.owner then return false, Text('err_not_owned') end
    if not insideOrNear(src, p) then return false, Text('err_too_far') end
    if Access.Can(src, p.id, 'storage') then return true end
    if Security and Security.StorageOpen(src, p.id) then
        if kind == 'safe' and Config.BreakIns.safesProtected and Security.ModeFor(src, p.id) == 'burglar' then return false, Text('err_safe_locked') end
        return true
    end
    return false, Text('err_no_rights')
end

function Storage.Open(src, id, kind, index)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local ok, why = Storage.CanOpen(src, p, kind)
    if not ok then return false, why end
    local list = kind == 'safe' and p.data.points.safe or p.data.points.storage
    local pt, label, stashId, slots, weight
    if kind == 'furniture' then
        local item = Furniture.StorageItem(id, tonumber(index))
        if not item then return false, Text('err_failed') end
        slots, weight = item.slots, item.weight
        label = item.label
        stashId = Storage.Id(p, p.owner.citizenid, 'furniture', item.id)
        if item.fridge and Fridge then Fridge.Track(stashId) end
    else
        pt = list and list[tonumber(index) or 0]
        if not pt then return false, Text('err_failed') end
        slots, weight = Storage.Size(p, pt, kind)
        label = kind == 'safe' and Text('safe_label', { n = index }) or (pt.label ~= '' and pt.label or Text('storage_label', { n = index }))
        stashId = Storage.Id(p, p.owner.citizenid, kind, index)
    end
    label = ('%s · %s'):format(p.data.label, label)
    local mode = Inventory.OpenStash(src, stashId, label, slots, weight)
    if Security then Security.NoteStorage(src, p.id) end
    return true, { mode = mode, id = stashId, label = label, slots = slots, weight = weight }
end

function Storage.Upgrade(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, id, 'security') then return false, Text('err_no_rights') end
    local nextLevel = level(p) + 1
    local up = Config.Storage.upgrades and Config.Storage.upgrades[nextLevel]
    if not up then return false, Text('err_max_level') end
    if not Framework.Charge(src, up.price or 0, 'bank', 'xs-housing-storage') then return false, Text('err_money', { amount = Util.Money(up.price) }) end
    Props.UpdateOwner(id, { storage_level = nextLevel })
    Logs.Add('admin', id, Logs.Who(src), Text('log_storage_upgrade', { n = nextLevel }), up.price or 0)
    return true, nextLevel
end

function Storage.Claims(src)
    local cid = Framework.GetCitizenId(src)
    if not cid then return {} end
    local rows = MySQL.query.await('SELECT id, property_id, label, `until`, stashes FROM xs_housing_claims WHERE citizenid = ? AND `until` > ? ORDER BY id DESC', { cid, os.time() }) or {}
    for _, r in ipairs(rows) do r.stashes = Db.Decode(r.stashes, {}) end
    return rows
end

function Storage.OpenClaim(src, claimId, stashId)
    local cid = Framework.GetCitizenId(src)
    local row = MySQL.single.await('SELECT id, stashes, label FROM xs_housing_claims WHERE id = ? AND citizenid = ? AND `until` > ?', { tonumber(claimId) or 0, cid, os.time() })
    if not row then return false, Text('err_failed') end
    for _, s in ipairs(Db.Decode(row.stashes, {}) or {}) do
        if s.id == stashId then
            local mode = Inventory.OpenStash(src, s.id, ('%s · %s'):format(row.label, s.label), s.slots, s.weight)
            return true, { mode = mode, id = s.id, label = s.label, slots = s.slots, weight = s.weight }
        end
    end
    return false, Text('err_failed')
end
