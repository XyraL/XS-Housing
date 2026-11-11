Agency = { offers = {}, place = {}, pending = {} }

local offerSeq = 0

function Agency.Load()
    local row = MySQL.single.await('SELECT data FROM xs_housing_settings WHERE name = ?', { 'agency' })
    local data = row and Db.Decode(row.data, {}) or {}
    Agency.place = type(data.place) == 'table' and data.place or {}
    Agency.pending = type(data.pending) == 'table' and data.pending or {}
end

local function persist()
    MySQL.query.await('INSERT INTO xs_housing_settings (name, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
        'agency', Db.Json({ place = Agency.place, pending = Agency.pending }),
    })
end

function Agency.SavePlace(raw)
    raw = type(raw) == 'table' and raw or {}
    Agency.place = {
        office = Util.Point(raw.office), desk = Util.Point(raw.desk), label = Util.Text(raw.label, 48),
        blip = raw.blip ~= false,
    }
    persist()
    TriggerClientEvent('XS-Housing:client:agency', -1, Agency.Public())
    return true
end

function Agency.Public()
    return { office = Agency.place.office, desk = Agency.place.desk, label = Agency.place.label ~= '' and Agency.place.label or nil, blip = Agency.place.blip ~= false, enabled = Config.Agency.enabled, job = Config.Agency.job }
end

function Agency.Agent(src)
    if not Config.Agency.enabled then return nil end
    local job = Framework.GetJob(src)
    if not job or job.name ~= Config.Agency.job or not job.onDuty then return nil end
    return job
end

function Agency.Can(src, right)
    local job = Agency.Agent(src)
    if not job then return false end
    if job.isBoss then return true end
    return (job.grade or 0) >= ((Config.Agency.grades or {})[right] or 0)
end

local function commission(p)
    local v = tonumber(p.data.money.commissionPct) or -1
    if v >= 0 then return v end
    return Config.Agency.commissionPct or 0
end

function Agency.Data(src)
    if not Agency.Agent(src) then return false, Text('err_not_agent') end
    local list = {}
    for _, p in ipairs(Props.All()) do
        if p.data.type ~= 'building' then
            list[#list + 1] = {
                id = p.id, label = p.data.label, type = p.data.type, address = p.data.address, status = Props.Status(p), listed = p.data.listed,
                price = Props.Price(p), basePrice = p.data.money.basePrice or p.data.money.price, rentPrice = p.data.money.rentPrice,
                canBuy = p.data.money.buy, canRent = p.data.money.rent, canMortgage = p.data.money.mortgage,
                owner = p.owner and { name = p.owner.name, kind = p.owner.kind, since = p.owner.since, missed = p.owner.missed } or nil,
                door = p.data.door, photo = Props.PhotoRef(p.data), enabled = p.data.enabled,
                openHouse = Enter.OpenHouseUntil(p.id), canOpenHouse = (Config.OpenHouse or {}).enabled == true and not p.owner and Enter.CanHostOpenHouse(src, p),
            }
        end
    end
    local job = Agency.Agent(src)
    local rights = {}
    for k in pairs(Config.Agency.grades or {}) do rights[k] = Agency.Can(src, k) end
    local cid = Framework.GetCitizenId(src)
    local sales = MySQL.query.await("SELECT property_id, kind, name, amount, at, detail FROM xs_housing_logs WHERE kind = 'agent_sale' AND citizenid = ? ORDER BY id DESC LIMIT 30", { cid }) or {}
    return true, { list = list, rights = rights, job = job, now = os.time(), openHouseMinutes = (Config.OpenHouse or {}).minutes or 15, commissionPct = Config.Agency.commissionPct, rangePct = Config.Agency.priceRangePct, approval = Config.Agency.approval, sales = sales, pending = Agency.pending }
end

function Agency.SetListed(src, id, listed)
    if not Agency.Can(src, 'list') then return false, Text('err_no_rights') end
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local data = Util.Copy(p.data)
    data.listed = listed == true
    Props.Save(id, data)
    Logs.Add('admin', id, Logs.Who(src), listed and Text('log_listed') or Text('log_unlisted'), 0)
    return true
end

local function applyPrice(p, price, rent)
    local data = Util.Copy(p.data)
    data.money.basePrice = data.money.basePrice or data.money.price
    data.money.baseRent = data.money.baseRent or data.money.rentPrice
    if price then data.money.price = price end
    if rent then data.money.rentPrice = rent end
    Props.Save(p.id, data)
end

function Agency.SetPrice(src, id, price, rent)
    if not Agency.Can(src, 'price') then return false, Text('err_no_rights') end
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local base = p.data.money.basePrice or p.data.money.price
    local baseRent = p.data.money.baseRent or p.data.money.rentPrice
    local range = (Config.Agency.priceRangePct or 20) / 100
    price = tonumber(price) and math.floor(Util.Clamp(price, base * (1 - range), base * (1 + range))) or nil
    rent = tonumber(rent) and math.floor(Util.Clamp(rent, baseRent * (1 - range), baseRent * (1 + range))) or nil
    if Config.Agency.approval then
        Agency.pending[#Agency.pending + 1] = { id = id, price = price, rent = rent, by = Framework.GetName(src) or '', cid = Framework.GetCitizenId(src), at = os.time() }
        persist()
        return true, 'pending'
    end
    applyPrice(p, price, rent)
    Logs.Add('admin', id, Logs.Who(src), Text('log_price', { price = Util.Money(price or p.data.money.price), rent = Util.Money(rent or p.data.money.rentPrice) }), 0)
    return true, 'done'
end

function Agency.Approve(index, approve)
    local item = Agency.pending[tonumber(index) or 0]
    if not item then return false end
    table.remove(Agency.pending, tonumber(index))
    persist()
    if approve then
        local p = Props.Get(item.id)
        if p then applyPrice(p, item.price, item.rent) end
    end
    return true
end

function Agency.Offer(src, id, target, mode, opts)
    local right = mode == 'rent' and 'rent' or 'sell'
    if not Agency.Can(src, right) then return false, Text('err_no_rights') end
    local p = Props.Get(id)
    if not p or not Props.ForSale(p) and not (p and not p.owner and p.data.enabled) then return false, Text('err_not_for_sale') end
    target = tonumber(target)
    if not target or not GetPlayerName(target) or target == src then return false, Text('err_no_player') end
    local a, b = GetEntityCoords(GetPlayerPed(src)), GetEntityCoords(GetPlayerPed(target))
    if #(a - b) > 8.0 then return false, Text('err_too_far') end
    local quote = Ownership.Quote(p, mode, opts)
    if not quote then return false, Text('err_failed') end
    offerSeq = offerSeq + 1
    Agency.offers[offerSeq] = { id = offerSeq, property = id, agent = src, target = target, mode = mode, opts = opts, at = os.time() }
    TriggerClientEvent('XS-Housing:client:offer', target, {
        offer = offerSeq, agent = Framework.GetName(src) or '', property = Props.Public(p), mode = mode, quote = quote,
    })
    return true
end

function Agency.Accept(src, offerId, accept)
    local o = Agency.offers[tonumber(offerId) or 0]
    if not o or o.target ~= src then return false, Text('err_offer_gone') end
    Agency.offers[o.id] = nil
    if os.time() - o.at > 180 then return false, Text('err_offer_gone') end
    if not accept then
        if GetPlayerName(o.agent) then Framework.Notify(o.agent, Text('offer_declined'), 'inform') end
        return true
    end
    local agentName = Framework.GetName(o.agent) or ''
    local ok, result = Ownership.Acquire(src, o.property, o.mode, { term = o.opts and o.opts.term, depositPct = o.opts and o.opts.depositPct, agent = agentName })
    if not ok then return false, result end
    local p = Props.Get(o.property)
    local base = o.mode == 'rent' and (result.rent or 0) or (result.price or 0)
    local cut = math.floor(base * commission(p) / 100)
    if cut > 0 and GetPlayerName(o.agent) then
        Framework.AddMoney(o.agent, 'bank', cut, 'xs-housing-commission')
        Framework.Notify(o.agent, Text('commission', { amount = Util.Money(cut) }), 'success')
    end
    local share = math.floor(base * (tonumber(Config.Agency.societyPct) or 0) / 100)
    if share > 0 and (Config.Agency.account or '') ~= '' then Banking.Deposit(Config.Agency.account, share, 'xs-housing-agency') end
    Logs.Add('agent_sale', o.property, Logs.Who(o.agent), Text('log_agent_sale', { buyer = Framework.GetName(src) or '', mode = o.mode }), cut)
    return true, result
end

function Agency.Evict(src, id)
    if not Agency.Can(src, 'evict') then return false, Text('err_no_rights') end
    return Ownership.Evict(id, Logs.Who(src), Text('log_evicted_by_agent'))
end

CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for id, o in pairs(Agency.offers) do
            if now - o.at > 180 then Agency.offers[id] = nil end
        end
    end
end)
