Ipl = { active = nil, cullOn = false }

local function interiorAt(entry)
    local c = entry.center or entry.spawn
    if not c then return 0 end
    return GetInteriorAtCoords(c.x + 0.0, c.y + 0.0, c.z + 0.0)
end

local function waitReady(entry)
    local untilAt = GetGameTimer() + 4000
    local id = entry.interiorId or 0
    while GetGameTimer() < untilAt do
        if id == 0 or not IsValidInterior(id) then id = interiorAt(entry) end
        if id ~= 0 and IsValidInterior(id) then
            PinInteriorInMemory(id)
            if IsInteriorReady(id) then return id end
        end
        Wait(50)
    end
    return id
end

local function setSets(id, sets, on)
    for _, set in ipairs(sets or {}) do
        if on then
            if not IsInteriorEntitySetActive(id, set) then ActivateInteriorEntitySet(id, set) end
        else
            if IsInteriorEntitySetActive(id, set) then DeactivateInteriorEntitySet(id, set) end
        end
    end
end

local function chosenStyle(entry, styleId)
    if not entry.styles then return nil end
    for _, s in ipairs(entry.styles) do
        if s.id == styleId then return s end
    end
    return entry.styles[1]
end

function Ipl.Apply(entry, styleId)
    if not entry then return end
    for _, name in ipairs(entry.ipls or {}) do
        if not IsIplActive(name) then RequestIpl(name) end
    end
    local style = chosenStyle(entry, styleId)
    if style and style.ipl then
        for _, other in ipairs(entry.styles) do
            if other.ipl and other.ipl ~= style.ipl and IsIplActive(other.ipl) then RemoveIpl(other.ipl) end
        end
        if not IsIplActive(style.ipl) then RequestIpl(style.ipl) end
    end
    local id = waitReady({ center = entry.center, spawn = entry.spawn, interiorId = style and style.interiorId or entry.interiorId })
    if id ~= 0 then
        if style and style.sets then
            for _, other in ipairs(entry.styles) do
                if other ~= style then setSets(id, other.sets, false) end
            end
            setSets(id, style.sets, true)
            if style.color then
                for _, set in ipairs(style.sets) do SetInteriorEntitySetColor(id, set, style.color) end
            end
        end
        setSets(id, entry.extras, true)
        RefreshInterior(id)
    end
    Ipl.active = { entry = entry, interior = id, style = style }
    Ipl.StartCull(entry)
    return id
end

function Ipl.StartCull(entry)
    if not entry.cull or #entry.cull == 0 then return end
    if Ipl.cullOn then return end
    Ipl.cullOn = true
    local hashes = {}
    for _, model in ipairs(entry.cull) do hashes[#hashes + 1] = joaat(model) end
    CreateThread(function()
        while Ipl.cullOn and Ipl.active and Ipl.active.entry == entry do
            for _, h in ipairs(hashes) do EnableExteriorCullModelThisFrame(h) end
            Wait(0)
        end
        Ipl.cullOn = false
    end)
end

function Ipl.Release()
    local a = Ipl.active
    Ipl.active = nil
    Ipl.cullOn = false
    if not a then return end
    local entry = a.entry
    if a.style and a.style.ipl and entry.styles and entry.styles[1] and entry.styles[1].ipl and a.style ~= entry.styles[1] then
        RemoveIpl(a.style.ipl)
        RequestIpl(entry.styles[1].ipl)
    end
    if a.interior and a.interior ~= 0 then UnpinInterior(a.interior) end
end

function Ipl.Spawn(entry, override)
    if override and override.x then return override end
    if not entry or not entry.spawn then return nil end
    return { x = entry.spawn.x, y = entry.spawn.y, z = entry.spawn.z, w = entry.spawn.w or 0.0 }
end
