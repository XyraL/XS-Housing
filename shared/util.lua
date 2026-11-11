Util = {}

function Util.Clamp(value, low, high)
    value = tonumber(value) or low
    if value < low then return low end
    if value > high then return high end
    return value
end

function Util.Round(value, places)
    local mult = 10 ^ (places or 0)
    return math.floor((tonumber(value) or 0) * mult + 0.5) / mult
end

function Util.Truthy(value)
    return value == true or value == 1 or value == '1' or value == 'true'
end

function Util.U32(hash)
    hash = tonumber(hash) or 0
    if hash < 0 then hash = hash + 4294967296 end
    return math.floor(hash)
end

function Util.Hash(name)
    return Util.U32(joaat(name))
end

function Util.Now()
    if IsDuplicityVersion() then return os.time() end
    return math.floor(GetCloudTimeAsInt())
end

function Util.Copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = Util.Copy(v) end
    return out
end

function Util.Text(value, max)
    if value == nil then return '' end
    value = tostring(value):gsub('[%c]', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if max and #value > max then value = value:sub(1, max) end
    return value
end

function Util.Media(m, patch, now)
    if patch.url ~= nil then
        local url = Util.Text(patch.url, 300)
        m.url = url:match('^https?://') and url or ''
        m.at, m.paused, m.pos = now, false, 0
    end
    if patch.volume ~= nil then m.volume = Util.Clamp(tonumber(patch.volume) or 0.5, 0, 1) end
    if (m.url or '') == '' then
        m.paused, m.pos = false, 0
        return m
    end
    if patch.paused == true and not m.paused then
        m.paused, m.pos = true, math.max(0, now - (m.at or now))
    elseif patch.paused == false and m.paused then
        m.paused, m.at = false, now - (m.pos or 0)
    end
    if patch.seek ~= nil then
        local s = math.max(0, math.floor(tonumber(patch.seek) or 0))
        if m.paused then m.pos = s else m.at = now - s end
    end
    return m
end

function Util.Lines(value, max)
    if value == nil then return '' end
    value = tostring(value):gsub('\r', ''):gsub('[\0-\9\11-\31\127]', ' ')
    if max and #value > max then value = value:sub(1, max) end
    return value
end

local idCount = 0

function Util.Id(prefix)
    local stamp
    if IsDuplicityVersion() then stamp = os.time() else stamp = math.floor(GetGameTimer() / 1000) end
    idCount = idCount + 1
    return ('%s%x%04x%x'):format(prefix or '', stamp, math.random(0, 65535), idCount)
end

function Util.Vec(value)
    if type(value) == 'vector3' or type(value) == 'vector4' then return vector3(value.x, value.y, value.z) end
    if type(value) == 'table' and value.x then return vector3(tonumber(value.x) or 0.0, tonumber(value.y) or 0.0, tonumber(value.z) or 0.0) end
    return nil
end

function Util.Point(value)
    if not value then return nil end
    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return nil end
    return { x = Util.Round(x, 3), y = Util.Round(y, 3), z = Util.Round(z, 3), w = Util.Round(tonumber(value.w or value.h) or 0.0, 2) }
end

function Util.Distance(a, b)
    if not a or not b then return math.huge end
    local dx, dy, dz = (a.x or 0) - (b.x or 0), (a.y or 0) - (b.y or 0), (a.z or 0) - (b.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Util.Clock(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return ('%d:%02d'):format(seconds // 60, seconds % 60)
end

function Util.Span(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local d, h, m = seconds // 86400, (seconds % 86400) // 3600, (seconds % 3600) // 60
    if d > 0 then return ('%dd %dh'):format(d, h) end
    if h > 0 then return ('%dh %02dm'):format(h, m) end
    if m > 0 then return ('%dm'):format(m) end
    return ('%ds'):format(seconds)
end

function Util.Escape(value)
    return (tostring(value):gsub('%%', '%%%%'))
end

function Util.IsPoliceJob(job)
    if not job or not job.name then return false end
    local R = Config.Raids or {}
    for _, name in ipairs(R.jobs or {}) do
        if name == job.name then return true end
    end
    for _, kind in ipairs(R.types or {}) do
        if kind == job.type then return true end
    end
    return false
end

function Util.Shape(shape, center, size, heading, corners)
    shape = shape or 'square'
    if shape == 'custom' then
        local out = {}
        for _, c in ipairs(corners or {}) do
            if c and c.x and c.y then out[#out + 1] = { x = Util.Round(c.x, 2), y = Util.Round(c.y, 2) } end
        end
        return out
    end
    local sides = shape == 'hexagon' and 6 or (shape == 'circle' and 16 or 4)
    local radius = (tonumber(size) or 10.0) / 2
    if shape == 'square' then radius = radius * math.sqrt(2) end
    local start = math.rad((tonumber(heading) or 0.0) + (shape == 'square' and 45.0 or 0.0))
    local out = {}
    for i = 0, sides - 1 do
        local a = start + (i / sides) * math.pi * 2
        out[#out + 1] = { x = Util.Round(center.x + math.cos(a) * radius, 2), y = Util.Round(center.y + math.sin(a) * radius, 2) }
    end
    return out
end

function Util.InPoly(point, poly)
    if not point or type(poly) ~= 'table' or #poly < 3 then return false end
    local inside, j = false, #poly
    for i = 1, #poly do
        local a, b = poly[i], poly[j]
        if ((a.y > point.y) ~= (b.y > point.y)) and (point.x < (b.x - a.x) * (point.y - a.y) / ((b.y - a.y) ~= 0 and (b.y - a.y) or 1e-9) + a.x) then
            inside = not inside
        end
        j = i
    end
    return inside
end

function Util.PolyCenter(poly)
    if type(poly) ~= 'table' or #poly == 0 then return nil end
    local x, y = 0.0, 0.0
    for _, p in ipairs(poly) do x, y = x + p.x, y + p.y end
    return { x = x / #poly, y = y / #poly }
end

function Util.PolyRadius(poly)
    local c = Util.PolyCenter(poly)
    if not c then return 0.0 end
    local r = 0.0
    for _, p in ipairs(poly) do
        local d = math.sqrt((p.x - c.x) ^ 2 + (p.y - c.y) ^ 2)
        if d > r then r = d end
    end
    return r
end

function Util.Money(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local neg = s:sub(1, 1) == '-'
    if neg then s = s:sub(2) end
    s = s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return (neg and '-$' or '$') .. s
end

function Util.Days(days)
    return math.floor((tonumber(days) or 0) * 86400 + 0.5)
end
