HouseDoors = {}

local function isMlo(p)
    return p.data.interior.kind == 'mlo' or p.data.type == 'mlo'
end

function Doors.SetLocked(p, locked, src)
    if not p or not isMlo(p) then return end
    for _, door in ipairs(p.data.doors or {}) do
        local done = false
        if door.id and door.id ~= '' and Doors.Available() then
            done = Doors.SetState(door.id, locked, src)
        end
        if not done and door.model and door.x then
            Doors.SetBuiltin(door, locked and 'lock' or 'unlock', nil, true)
        end
    end
end

function HouseDoors.Release(p)
    for _, door in ipairs(p and p.data.doors or {}) do
        if door.model and door.x then Doors.SetBuiltin(door, nil, nil, false) end
    end
end

function HouseDoors.ApplyAll()
    for _, p in pairs(Props.list) do
        if isMlo(p) and #(p.data.doors or {}) > 0 then
            local locked = true
            if p.owner then locked = p.owner.locked == 1 end
            if Security.open[p.id] then locked = false end
            Doors.SetLocked(p, locked)
        end
    end
end

Framework.OnLoaded(function(src)
    Doors.SyncTo(src)
end)
