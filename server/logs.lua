Logs = {}

local HOOK_OF = {
    buy = 'sales', rent = 'sales', mortgage = 'sales', sell = 'sales', starter = 'sales', transfer = 'sales', agent_sale = 'sales', openhouse = 'sales',
    payment = 'rent', missed = 'rent', evict = 'rent', repossess = 'rent', payoff = 'rent', bill = 'rent',
    key_give = 'keys', key_take = 'keys', locks = 'keys',
    breakin = 'breakins', alarm = 'breakins', repair = 'breakins',
    raid = 'raids',
    admin = 'admin', create = 'admin', delete = 'admin', import = 'admin',
}

local COLOURS = { sales = 3066993, rent = 15844367, keys = 3447003, breakins = 15158332, raids = 10181046, admin = 9807270 }

local function webhook(kind, title, text)
    local hook = HOOK_OF[kind]
    local url = hook and ((Config.Logs or {}).webhooks or {})[hook]
    if type(url) ~= 'string' or not url:match('^https://') then return end
    local body = json.encode({
        username = 'XS-Housing',
        embeds = { { title = title, description = text, color = COLOURS[hook] or 9807270, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } },
    })
    PerformHttpRequest(url, function() end, 'POST', body, { ['Content-Type'] = 'application/json' })
end

function Logs.Add(kind, propertyId, who, detail, amount)
    if not Db.ready then return end
    who = who or {}
    local cid = who.citizenid or ''
    local name = Util.Text(who.name or '', 100)
    MySQL.insert('INSERT INTO xs_housing_logs (property_id, kind, citizenid, name, detail, amount, at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        tonumber(propertyId) or 0, kind, cid, name, Util.Text(detail or '', 255), math.floor(tonumber(amount) or 0), os.time(),
    })
    local prop = propertyId and Props and Props.Get(propertyId)
    local where = prop and ('%s (#%d)'):format(prop.data.label or '?', prop.id) or ('#' .. tostring(propertyId or 0))
    local money = (tonumber(amount) or 0) ~= 0 and (' · ' .. Util.Money(amount)) or ''
    webhook(kind, ('%s · %s'):format(Text('log_kind_' .. kind), where), ('%s%s\n%s'):format(name ~= '' and name or '—', money, Util.Text(detail or '', 255)))
end

function Logs.Who(src)
    if not src or src == 0 then return { citizenid = 'console', name = 'Console' } end
    return { citizenid = Framework.GetCitizenId(src) or '', name = Framework.GetName(src) or GetPlayerName(src) or '' }
end

function Logs.Fetch(filter)
    filter = type(filter) == 'table' and filter or {}
    local where, args = {}, {}
    if tonumber(filter.property) then where[#where + 1] = 'property_id = ?' args[#args + 1] = tonumber(filter.property) end
    if type(filter.kind) == 'string' and filter.kind ~= '' and filter.kind ~= 'all' then
        local kinds = {}
        for k, hook in pairs(HOOK_OF) do
            if hook == filter.kind or k == filter.kind then kinds[#kinds + 1] = k end
        end
        if #kinds > 0 then
            where[#where + 1] = ('kind IN (%s)'):format(('?,'):rep(#kinds):sub(1, -2))
            for _, k in ipairs(kinds) do args[#args + 1] = k end
        end
    end
    if type(filter.q) == 'string' and filter.q ~= '' then
        where[#where + 1] = '(name LIKE ? OR detail LIKE ? OR citizenid = ?)'
        local like = '%' .. Util.Text(filter.q, 40):gsub('[%%_]', '') .. '%'
        args[#args + 1], args[#args + 2], args[#args + 3] = like, like, Util.Text(filter.q, 64)
    end
    local sql = 'SELECT id, property_id, kind, citizenid, name, detail, amount, at FROM xs_housing_logs'
    if #where > 0 then sql = sql .. ' WHERE ' .. table.concat(where, ' AND ') end
    sql = sql .. ' ORDER BY id DESC LIMIT ' .. math.floor(Util.Clamp(filter.limit or 150, 1, 500))
    return MySQL.query.await(sql, args) or {}
end

CreateThread(function()
    while not Db.ready do Wait(1000) end
    while true do
        local keep = math.max(1, tonumber((Config.Logs or {}).keepDays) or 30)
        pcall(MySQL.query.await, 'DELETE FROM xs_housing_logs WHERE at < ?', { os.time() - keep * 86400 })
        pcall(MySQL.query.await, 'DELETE FROM xs_housing_claims WHERE `until` < ?', { os.time() })
        Wait(6 * 3600 * 1000)
    end
end)
