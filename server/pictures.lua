Pictures = { list = {} }

local KINDS = { shell = true, ipl = true }
local MAX = 200000

function Pictures.Key(kind, value)
    if not KINDS[kind] or type(value) ~= 'string' or value == '' or #value > 80 or not value:match('^[%w_%-%.]+$') then return nil end
    return kind .. ':' .. value
end

function Pictures.Load()
    Pictures.list = {}
    local ok, rows = pcall(MySQL.query.await, 'SELECT `id`, `data` FROM `xs_housing_pictures`')
    if not ok or type(rows) ~= 'table' then return end
    for _, r in ipairs(rows) do
        if type(r.id) == 'string' and type(r.data) == 'string' then Pictures.list[r.id] = r.data end
    end
end

function Pictures.Keys()
    local out = {}
    for k in pairs(Pictures.list) do out[#out + 1] = k end
    table.sort(out)
    return out
end

function Pictures.Get(kind, value)
    local key = Pictures.Key(kind, value)
    return key and Pictures.list[key] or nil
end

function Pictures.Save(kind, value, data)
    local key = Pictures.Key(kind, value)
    if not key then return false, Text('err_photo') end
    if type(data) ~= 'string' or not data:match('^data:image/jpeg;base64,') or #data > MAX then return false, Text('err_photo') end
    local ok = pcall(MySQL.query.await, 'REPLACE INTO `xs_housing_pictures` (`id`, `data`, `updated_at`) VALUES (?, ?, ?)', { key, data, os.time() })
    if not ok then return false, Text('err_failed') end
    Pictures.list[key] = data
    return true
end
