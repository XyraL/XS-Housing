Access = {}

local RIGHTS = {
    owner = { enter = true, lock = true, storage = true, wardrobe = true, furniture = true, keys = true, sell = true, panel = true, bills = true, security = true, garage = true, style = true, cameras = true, letin = true },
    coowner = { enter = true, lock = true, storage = true, wardrobe = true, furniture = true, keys = true, panel = true, bills = true, security = true, garage = true, style = true, cameras = true, letin = true },
    tenant = { enter = true, lock = true, storage = true, wardrobe = true, furniture = true, panel = true, garage = true, cameras = true, letin = true },
    guest = { enter = true, wardrobe = false, panel = false, letin = false },
    group = { enter = true, lock = true, storage = true, wardrobe = true, panel = true, garage = true },
}

local function cidOf(who)
    if type(who) == 'number' then return Framework.GetCitizenId(who) end
    return who
end

function Access.Role(who, id)
    local p = Props.Get(id)
    if not p or not p.owner then return nil end
    local cid = cidOf(who)
    if not cid then return nil end
    if p.owner.citizenid == cid then return 'owner' end
    local key = p.keys[cid]
    if key then
        if key.expires and key.expires > 0 and key.expires < os.time() then
            Access.TakeKey(id, cid, nil, true)
            return nil
        end
        return key.role
    end
    local g = p.data.group
    if g and g.access and g.kind ~= 'none' and g.name ~= '' and type(who) == 'number' then
        local mine = g.kind == 'job' and Framework.GetJob(who) or Framework.GetGang(who)
        if mine and mine.name == g.name and (mine.grade or 0) >= (g.grade or 0) then return 'group' end
    end
    return nil
end

function Access.Can(who, id, right)
    local role = Access.Role(who, id)
    if not role then return false, nil end
    local rights = RIGHTS[role] or {}
    if right == 'furniture' and (role == 'tenant' or role == 'coowner') and not Config.Keys.tenantsFurnish then return false, role end
    if right == 'sell' and role == 'coowner' and Config.Keys.coOwnersSell then return true, role end
    if right == 'storage' and role ~= 'owner' and not Config.Storage.keyHolders then return false, role end
    return rights[right] == true, role
end

function Access.MapFor(cid)
    local out = {}
    if not cid then return out end
    for id, p in pairs(Props.list) do
        if p.owner then
            if p.owner.citizenid == cid then
                out[tostring(id)] = 'owner'
            elseif p.keys[cid] then
                local k = p.keys[cid]
                if not (k.expires and k.expires > 0 and k.expires < os.time()) then out[tostring(id)] = k.role end
            end
        end
    end
    return out
end

function Access.GroupMap(src)
    local out = {}
    local job, gang = Framework.GetJob(src), Framework.GetGang(src)
    for id, p in pairs(Props.list) do
        local g = p.data.group
        if p.owner and g and g.access and g.kind ~= 'none' and g.name ~= '' then
            local mine = g.kind == 'job' and job or gang
            if mine and mine.name == g.name and (mine.grade or 0) >= (g.grade or 0) then out[tostring(id)] = 'group' end
        end
    end
    return out
end

function Access.Push(cid)
    local src = cid and Framework.SourceOf(cid)
    if not src then return end
    local map = Access.MapFor(cid)
    for k, v in pairs(Access.GroupMap(src)) do
        if not map[k] then map[k] = v end
    end
    TriggerClientEvent('XS-Housing:client:access', src, map)
end

function Access.PushProperty(id)
    local p = Props.Get(id)
    if not p then return end
    if p.owner then Access.Push(p.owner.citizenid) end
    for cid in pairs(p.keys) do Access.Push(cid) end
end

function Access.Holders(id)
    local p = Props.Get(id)
    local out = {}
    if not p or not p.owner then return out end
    out[#out + 1] = p.owner.citizenid
    for cid, k in pairs(p.keys) do
        if not (k.expires and k.expires > 0 and k.expires < os.time()) then out[#out + 1] = cid end
    end
    return out
end

function Access.OnlineHolders(id, right)
    local out = {}
    for _, cid in ipairs(Access.Holders(id)) do
        local src = Framework.SourceOf(cid)
        if src and (not right or Access.Can(cid, id, right)) then out[#out + 1] = src end
    end
    return out
end

function Access.KeyCount(id)
    local p = Props.Get(id)
    local n = 0
    for _ in pairs(p and p.keys or {}) do n = n + 1 end
    return n
end

function Access.GiveKey(id, targetCid, targetName, role, hours, byCid)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if targetCid == p.owner.citizenid then return false, Text('err_already_owner') end
    role = (role == 'coowner' or role == 'tenant' or role == 'guest') and role or 'guest'
    if not p.keys[targetCid] and Access.KeyCount(id) >= (Config.Keys.max or 6) then return false, Text('err_key_limit', { n = Config.Keys.max }) end
    if role == 'coowner' then
        local co = 0
        for cid, k in pairs(p.keys) do
            if k.role == 'coowner' and cid ~= targetCid then co = co + 1 end
        end
        if co >= (p.data.maxCoOwners or 3) then return false, Text('err_coowner_limit', { n = p.data.maxCoOwners }) end
    end
    local expires = 0
    if role == 'guest' and tonumber(hours) and tonumber(hours) > 0 then expires = os.time() + math.floor(tonumber(hours) * 3600) end
    p.keys[targetCid] = { name = targetName or '', role = role, expires = expires, given_by = byCid or '' }
    MySQL.query.await([[INSERT INTO xs_housing_keys (property_id, citizenid, name, role, expires, given_by) VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), role = VALUES(role), expires = VALUES(expires), given_by = VALUES(given_by)]],
        { id, targetCid, Util.Text(targetName or '', 100), role, expires, byCid or '' })
    Access.Push(targetCid)
    Garage.Refresh(id)
    return true
end

function Access.TakeKey(id, targetCid, byCid, quiet)
    local p = Props.Get(id)
    if not p or not p.keys[targetCid] then return false, Text('err_no_key') end
    p.keys[targetCid] = nil
    MySQL.query.await('DELETE FROM xs_housing_keys WHERE property_id = ? AND citizenid = ?', { id, targetCid })
    Access.Push(targetCid)
    Garage.Refresh(id)
    if not quiet then
        local src = Framework.SourceOf(targetCid)
        if src then Framework.Notify(src, Text('key_taken', { place = p.data.label }), 'inform') end
    end
    return true
end

function Access.ClearKeys(id)
    local p = Props.Get(id)
    if not p then return end
    local had = {}
    for cid in pairs(p.keys) do had[#had + 1] = cid end
    p.keys = {}
    MySQL.query.await('DELETE FROM xs_housing_keys WHERE property_id = ?', { id })
    for _, cid in ipairs(had) do Access.Push(cid) end
    Garage.Refresh(id)
end

CreateThread(function()
    while not Props.ready do Wait(1000) end
    while true do
        Wait(60 * 1000)
        local now = os.time()
        for id, p in pairs(Props.list) do
            for cid, k in pairs(p.keys) do
                if k.expires and k.expires > 0 and k.expires < now then Access.TakeKey(id, cid, nil, false) end
            end
        end
    end
end)
