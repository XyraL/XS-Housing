Interiors = { Shells = Interiors and Interiors.Shells or {}, Ipls = Interiors and Interiors.Ipls or {}, shellMap = {}, iplMap = {} }

function Interiors.Index()
    Interiors.shellMap, Interiors.iplMap = {}, {}
    for _, s in ipairs(Interiors.Shells) do Interiors.shellMap[s.model] = s end
    for _, i in ipairs(Interiors.Ipls) do Interiors.iplMap[i.id] = i end
end

function Interiors.Shell(model)
    if not next(Interiors.shellMap) then Interiors.Index() end
    return Interiors.shellMap[model]
end

function Interiors.Ipl(id)
    if not next(Interiors.iplMap) then Interiors.Index() end
    return Interiors.iplMap[id]
end

function Interiors.ShellOrigin(door, id)
    if not door then return nil end
    local I = Config.Interiors
    local slot = (not I.instanced and tonumber(id)) and (math.floor(tonumber(id)) % 16) or 0
    if I.shellPlacement == 'underground' then
        return { x = door.x, y = door.y, z = door.z - (I.undergroundDepth or 60.0) - slot * 12.0 }
    end
    return { x = door.x + (slot % 4) * 45.0, y = door.y + math.floor(slot / 4) * 45.0, z = door.z + (I.shellHeight or 450.0) }
end

function Interiors.ShellExit(interior)
    if interior and interior.exit then return interior.exit end
    local s = interior and Interiors.Shell(interior.shell)
    if s and s.door then return { x = s.door.x, y = s.door.y, z = s.door.z, w = ((s.door.w or 0.0) + (s.faces_out and 180.0 or 0.0)) % 360 } end
    return { x = 0.0, y = 0.0, z = 1.0, w = 0.0 }
end

function Interiors.IplSpawn(interior)
    if interior and interior.exit then return interior.exit end
    local i = interior and Interiors.Ipl(interior.ipl)
    if i and i.spawn then return { x = i.spawn.x, y = i.spawn.y, z = i.spawn.z, w = i.spawn.w or 0.0 } end
    return nil
end

function Interiors.Public()
    local shells, ipls = {}, {}
    for _, s in ipairs(Interiors.Shells) do
        shells[#shells + 1] = { model = s.model, label = s.label, pack = s.pack, free = s.free == true, door = s.door, facesOut = s.faces_out == true, guess = s.guess == true }
    end
    for _, i in ipairs(Interiors.Ipls) do
        local styles = {}
        for _, st in ipairs(i.styles or {}) do styles[#styles + 1] = { id = st.id, label = st.label } end
        ipls[#ipls + 1] = { id = i.id, label = i.label, kind = i.kind, spawn = i.spawn, needs = i.needs, styles = styles, build = i.build, unverified = i.unverified == true }
    end
    return { shells = shells, ipls = ipls }
end
