Compat = {}

function Compat.Homes(src)
    local cid = Framework.GetCitizenId(src)
    local out = {}
    if not cid then return out end
    for pid, role in pairs(Access.MapFor(cid)) do
        local p = Props.Get(tonumber(pid))
        if p then
            local door = p.data.door
            if not door and p.data.building > 0 then
                local b = Props.Get(p.data.building)
                door = b and b.data.door
            end
            local keys = {}
            if role == 'owner' then
                for kcid in pairs(p.keys) do keys[#keys + 1] = kcid end
            end
            out[#out + 1] = {
                id = tostring(p.id), label = (p.owner.house_name ~= '' and p.owner.house_name) or p.data.label, owner = role == 'owner', role = role,
                x = door and door.x, y = door and door.y, z = door and door.z, w = door and door.w,
                canLock = Access.Can(src, p.id, 'lock') == true, canKeys = Access.Can(src, p.id, 'keys') == true, keys = keys,
                locked = p.owner.locked == 1, type = p.data.type, kind = p.owner.kind,
                interior = p.data.interior.kind,
            }
        end
    end
    table.sort(out, function(a, b) return tonumber(a.id) < tonumber(b.id) end)
    return out
end

exports('GetHomes', function(src) return Compat.Homes(src) end)

exports('HasKey', function(who, pid)
    return Access.Role(who, tonumber(pid)) ~= nil
end)

exports('GetRole', function(who, pid)
    return Access.Role(who, tonumber(pid))
end)

exports('GetProperty', function(pid)
    local p = Props.Get(tonumber(pid))
    return p and Props.Public(p) or nil
end)

exports('GetPlayerProperties', function(cid)
    local out = {}
    for _, p in ipairs(Props.OwnedBy(cid)) do out[#out + 1] = Props.Public(p) end
    return out
end)

exports('IsInside', function(src)
    return Enter.Of(src) ~= nil
end)

exports('GetInside', function(src)
    local st = Enter.Of(src)
    return st and st.id or nil
end)

exports('SetLocked', function(src, pid, locked)
    return Enter.SetLock(src, tonumber(pid), locked == true)
end)

exports('SetKeys', function(src, pid, added, removed)
    pid = tonumber(pid)
    if not Access.Can(src, pid, 'keys') then return false, 'not_owner' end
    if type(added) == 'string' then added = { added } end
    if type(removed) == 'string' then removed = { removed } end
    for _, cid in ipairs(type(added) == 'table' and added or {}) do
        local holder = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', { cid })
        local ci = holder and Db.Decode(holder.charinfo, {}) or {}
        Access.GiveKey(pid, cid, Framework.FullName(ci), 'tenant', 0, Framework.GetCitizenId(src))
    end
    for _, cid in ipairs(type(removed) == 'table' and removed or {}) do
        Access.TakeKey(pid, cid, Framework.GetCitizenId(src))
    end
    return true
end)

exports('Spawns', function(src)
    if not Config.Spawn.atHome then return {} end
    local out = {}
    for _, h in ipairs(Compat.Homes(src)) do
        if h.x then out[#out + 1] = { id = h.id, label = h.label, coords = vector4(h.x, h.y, h.z, h.w or 0.0), inside = h.interior == 'shell' or h.interior == 'ipl' } end
    end
    return out
end)

exports('EnterProperty', function(src, pid)
    local p = Props.Get(tonumber(pid))
    if not p or not Access.Role(src, p.id) then return false end
    if p.data.interior.kind ~= 'shell' and p.data.interior.kind ~= 'ipl' then return false end
    Enter.Put(src, p, 'member')
    return true
end)
