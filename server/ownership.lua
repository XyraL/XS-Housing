Ownership = {}

local APARTMENT_TYPES = { unit = true, motel = true }
local OFFICE_TYPES = { office = true }

local function period(days)
    return math.max(3600, Util.Days(days))
end

local function rentDays(p)
    local d = tonumber(p.data.money.rentDays) or 0
    if d > 0 then return d end
    return Config.Rent.periodDays or 7
end

local function interest(p)
    local v = tonumber(p.data.money.interestPct) or -1
    if v >= 0 then return v end
    return Config.Mortgage.interestPct or 0
end

local function minDeposit(p)
    return math.max(Config.Mortgage.minDepositPct or 0, p.data.money.minDepositPct or 0)
end

local function sellBack(p)
    local v = tonumber(p.data.money.sellBackPct) or -1
    if v >= 0 then return v end
    return Config.Ownership.sellBackPct or 70
end

local function renterDeposit(p)
    local v = tonumber(p.data.money.renterDeposit) or -1
    if v < 0 then v = Config.Rent.deposit or 1 end
    return math.floor(p.data.money.rentPrice * v)
end

function Ownership.Category(p)
    if APARTMENT_TYPES[p.data.type] then return 'apartments' end
    if OFFICE_TYPES[p.data.type] then return 'offices' end
    return 'houses'
end

function Ownership.Counts(cid)
    local counts = { total = 0, houses = 0, apartments = 0, offices = 0 }
    for _, p in ipairs(Props.OwnedBy(cid)) do
        if p.owner.kind ~= 'starter' then
            counts.total = counts.total + 1
            local cat = Ownership.Category(p)
            counts[cat] = counts[cat] + 1
        end
    end
    return counts
end

function Ownership.CanOwnMore(cid, p)
    local counts = Ownership.Counts(cid)
    local O = Config.Ownership
    if counts.total >= (O.maxProperties or 3) then return false, Text('err_limit_total', { n = O.maxProperties }) end
    local cat = Ownership.Category(p)
    local limit = cat == 'apartments' and O.maxApartments or (cat == 'offices' and O.maxOffices or O.maxHouses)
    if counts[cat] >= (limit or 1) then return false, Text('err_limit_' .. cat, { n = limit }) end
    return true
end

local function groupAllows(src, p)
    local g = p.data.group
    if not g or g.kind == 'none' or g.name == '' then return true end
    local mine = g.kind == 'job' and Framework.GetJob(src) or Framework.GetGang(src)
    if mine and mine.name == g.name and (mine.grade or 0) >= (g.grade or 0) then return true end
    return false
end

function Ownership.SelfServeAllowed()
    local mode = Config.Buying.selfServe or 'no_agents'
    if mode == 'always' or not Config.Agency.enabled then return true end
    if mode == 'never' then return false end
    return #Framework.OnDutyJob(Config.Agency.job) == 0
end

function Ownership.Quote(p, mode, opts)
    opts = opts or {}
    local price = Props.Price(p)
    local tax = math.floor(price * (Config.Buying.taxPct or 0) / 100)
    if mode == 'buy' then
        return { mode = 'buy', price = price, tax = tax, total = price + tax }
    elseif mode == 'rent' then
        local rent = p.data.money.rentPrice
        local deposit = renterDeposit(p)
        return { mode = 'rent', rent = rent, deposit = deposit, total = rent + deposit, days = rentDays(p) }
    elseif mode == 'mortgage' then
        local pct = math.floor(Util.Clamp(opts.depositPct or minDeposit(p), minDeposit(p), 100))
        local terms = Config.Mortgage.terms or { 8 }
        local term = tonumber(opts.term) or terms[1]
        local valid = false
        for _, t in ipairs(terms) do if t == term then valid = true end end
        if not valid then term = terms[1] end
        local deposit = math.floor(price * pct / 100)
        local owed = math.floor((price - deposit) * (1 + interest(p) / 100) + 0.5)
        local each = term > 0 and math.ceil(owed / term) or owed
        return {
            mode = 'mortgage', price = price, tax = tax, depositPct = pct, minDepositPct = minDeposit(p), deposit = deposit, owed = owed,
            term = term, terms = terms, each = each, interest = interest(p), days = Config.Mortgage.periodDays, total = deposit + tax,
        }
    end
end

local function charge(src, amount, reason)
    if amount <= 0 then return true end
    local ok = Framework.Charge(src, amount, 'bank', reason)
    return ok
end

local function claimFor(p, cid, label)
    if not Storage or not Storage.OwnerStashes then return end
    local stashes = Storage.OwnerStashes(p)
    if #stashes == 0 then return end
    MySQL.insert.await('INSERT INTO xs_housing_claims (citizenid, property_id, owner_key, label, `until`, stashes) VALUES (?, ?, ?, ?, ?, ?)', {
        cid, p.id, p.owner.citizenid, Util.Text(label or p.data.label, 100), os.time() + (Config.Ownership.claimDays or 7) * 86400, Db.Json(stashes),
    })
end

local function clearFurniture(p, refundTo)
    local refund = 0
    if Furniture and Furniture.Wipe then refund = Furniture.Wipe(p.id, refundTo ~= nil) end
    if refundTo and refund > 0 then
        local src = Framework.SourceOf(refundTo)
        if src then Framework.AddMoney(src, 'bank', refund, 'xs-housing-furniture-refund') end
    end
    return refund
end

local function release(p, reason, opts)
    opts = opts or {}
    if not p.owner then return end
    local cid, name = p.owner.citizenid, p.owner.name
    claimFor(p, cid, p.data.label)
    clearFurniture(p, opts.refundFurniture and cid or nil)
    local holders = Access.Holders(p.id)
    Enter.KickAll(p.id, reason)
    Props.SetOwner(p.id, nil)
    for _, h in ipairs(holders) do Access.Push(h) end
    Garage.Refresh(p.id)
    Props.Bump(nil)
    return cid, name
end

function Ownership.Assign(p, src, row)
    local cid = Framework.GetCitizenId(src)
    row.citizenid = cid
    row.name = Framework.GetName(src) or ''
    row.since = os.time()
    row.locked = 1
    row.security = row.security or { lock = p.data.security.lockLevel }
    row.prefs = row.prefs or { doorbell = true, lastSeen = os.time() }
    row.style = row.style or (p.data.interior.defaultStyle or '')
    Props.SetOwner(p.id, row)
    Access.Push(cid)
    Garage.Refresh(p.id)
    if Config.Starter.enabled and Config.Starter.removeOnPurchase and row.kind ~= 'starter' then
        for _, other in ipairs(Props.OwnedBy(cid)) do
            if other.id ~= p.id and other.owner.kind == 'starter' then
                release(other, 'starter_removed', {})
                Framework.Notify(src, Text('starter_removed', { place = other.data.label }), 'inform')
            end
        end
    end
end

function Ownership.Acquire(src, id, mode, opts)
    local p = Props.Get(id)
    if not p or not p.data.enabled then return false, Text('err_no_place') end
    if p.owner then return false, Text('err_taken') end
    if p.data.type == 'building' then return false, Text('err_no_place') end
    if not groupAllows(src, p) then return false, Text('err_group_only') end
    local cid = Framework.GetCitizenId(src)
    if not cid then return false, Text('err_failed') end
    local okMore, why = Ownership.CanOwnMore(cid, p)
    if not okMore then return false, why end

    if mode == 'buy' then
        if not p.data.money.buy then return false, Text('err_not_for_sale') end
        local q = Ownership.Quote(p, 'buy')
        if not charge(src, q.total, 'xs-housing-buy') then return false, Text('err_money', { amount = Util.Money(q.total) }) end
        Ownership.Assign(p, src, { kind = 'owned', amount = 0, balance = 0, paid = q.total })
        Props.Bump(p.data.address.zone)
        Logs.Add('buy', p.id, Logs.Who(src), opts and opts.agent and Text('log_via_agent', { name = opts.agent }) or '', q.total)
        Ownership.InitBills(p)
        return true, q
    elseif mode == 'rent' then
        if not (p.data.money.rent and Config.Rent.enabled) then return false, Text('err_not_for_rent') end
        local q = Ownership.Quote(p, 'rent')
        if not charge(src, q.total, 'xs-housing-rent') then return false, Text('err_money', { amount = Util.Money(q.total) }) end
        Ownership.Assign(p, src, { kind = 'rented', amount = q.rent, deposit = q.deposit, next_due = os.time() + period(q.days), paid = q.rent })
        Logs.Add('rent', p.id, Logs.Who(src), '', q.total)
        Ownership.InitBills(p)
        return true, q
    elseif mode == 'mortgage' then
        if not (p.data.money.mortgage and p.data.money.buy and Config.Mortgage.enabled) then return false, Text('err_no_mortgage') end
        local q = Ownership.Quote(p, 'mortgage', opts)
        if not charge(src, q.total, 'xs-housing-mortgage') then return false, Text('err_money', { amount = Util.Money(q.total) }) end
        Ownership.Assign(p, src, { kind = 'mortgage', amount = q.each, balance = q.owed, payments_left = q.term, next_due = os.time() + period(q.days), paid = q.deposit })
        Props.Bump(p.data.address.zone)
        Logs.Add('mortgage', p.id, Logs.Who(src), Text('log_mortgage', { term = q.term, each = Util.Money(q.each) }), q.total)
        Ownership.InitBills(p)
        return true, q
    end
    return false, Text('err_failed')
end

function Ownership.Starter(src)
    if not Config.Starter.enabled then return false end
    local cid = Framework.GetCitizenId(src)
    if not cid then return false end
    for _, p in ipairs(Props.OwnedBy(cid)) do
        if p.owner then return false end
    end
    local free, building = nil, nil
    for _, p in pairs(Props.list) do
        local tagged = false
        for _, t in ipairs(p.data.tags or {}) do if t == 'starter' then tagged = true end end
        local parent = p.data.building > 0 and Props.Get(p.data.building)
        if parent then
            for _, t in ipairs(parent.data.tags or {}) do if t == 'starter' then tagged = true end end
        end
        if tagged and p.data.enabled and p.data.type ~= 'building' and not p.owner then
            if not free or p.id < free.id then free = p end
        end
        if p.data.type == 'building' and p.data.enabled then
            for _, t in ipairs(p.data.tags or {}) do
                if t == 'starter' and (not building or p.id < building.id) then building = p end
            end
        end
    end
    if not free and building then
        local template
        for _, p in pairs(Props.list) do
            if p.data.type == 'unit' and p.data.building == building.id and (not template or p.id < template.id) then template = p end
        end
        if template then
            local count = 0
            for _, p in pairs(Props.list) do
                if p.data.type == 'unit' and p.data.building == building.id then count = count + 1 end
            end
            local data = Util.Copy(template.data)
            data.unit = tostring(count + 1)
            data.label = ('%s %s'):format(building.data.label, data.unit)
            free = Props.Save(nil, data)
        end
    end
    if not free then return false end
    Ownership.Assign(free, src, { kind = 'starter' })
    Logs.Add('starter', free.id, Logs.Who(src), '', 0)
    Framework.Notify(src, Text('starter_given', { place = free.data.label }), 'success')
    return true, free
end

function Ownership.SellBack(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    local can = Access.Can(src, id, 'sell')
    if not can then return false, Text('err_no_rights') end
    if p.owner.kind == 'rented' or p.owner.kind == 'starter' then return false, Text('err_cant_sell_rented') end
    local value = math.floor(Props.Price(p) * sellBack(p) / 100)
    if p.owner.kind == 'mortgage' then value = math.max(0, value - (p.owner.balance or 0)) end
    local owed = (p.owner.prefs and tonumber(p.owner.prefs.owed)) or 0
    value = math.max(0, value - owed)
    local cid = p.owner.citizenid
    release(p, 'sold', { refundFurniture = true })
    local payee = Framework.SourceOf(cid) or src
    if value > 0 then Framework.AddMoney(payee, 'bank', value, 'xs-housing-sell') end
    Logs.Add('sell', id, Logs.Who(src), '', value)
    return true, value
end

function Ownership.MoveOut(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    local cid = Framework.GetCitizenId(src)
    if p.owner.citizenid ~= cid then return false, Text('err_no_rights') end
    if p.owner.kind ~= 'rented' and p.owner.kind ~= 'starter' then return false, Text('err_not_rented') end
    local refund = (p.owner.missed or 0) == 0 and (p.owner.deposit or 0) or 0
    release(p, 'moved_out', { refundFurniture = true })
    if refund > 0 then Framework.AddMoney(src, 'bank', refund, 'xs-housing-deposit') end
    Logs.Add('sell', id, Logs.Who(src), Text('log_moved_out'), refund)
    return true, refund
end

function Ownership.Evict(id, by, reason)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    local cid = p.owner.citizenid
    release(p, 'evicted', { refundFurniture = true })
    local src = Framework.SourceOf(cid)
    if src then Framework.Notify(src, Text('evicted', { place = p.data.label }), 'error') end
    Logs.Add('evict', id, by or { citizenid = 'system', name = 'System' }, reason or '', 0)
    return true
end

function Ownership.Repossess(id, reason)
    local p = Props.Get(id)
    if not p or not p.owner then return false end
    local cid = p.owner.citizenid
    release(p, 'repossessed', {})
    local src = Framework.SourceOf(cid)
    if src then Framework.Notify(src, Text('repossessed', { place = p.data.label }), 'error') end
    Logs.Add('repossess', id, { citizenid = 'system', name = 'System' }, reason or '', 0)
    return true
end

function Ownership.Transfer(id, cid, name, by)
    local p = Props.Get(id)
    if not p then return false, Text('err_no_place') end
    local previous = p.owner and p.owner.citizenid
    if p.owner then
        local row = Util.Copy(p.owner)
        row.citizenid, row.name = cid, name or ''
        row.since = os.time()
        p.keys[cid] = nil
        MySQL.query.await('DELETE FROM xs_housing_keys WHERE property_id = ? AND citizenid = ?', { id, cid })
        Props.SetOwner(id, row)
    else
        Props.SetOwner(id, { citizenid = cid, name = name or '', kind = 'owned', security = { lock = p.data.security.lockLevel }, prefs = { doorbell = true, lastSeen = os.time() } })
    end
    if previous then Access.Push(previous) end
    Access.Push(cid)
    Garage.Refresh(id)
    Logs.Add('transfer', id, by, Text('log_transfer', { name = name or cid }), 0)
    return true
end

local function arrears(p)
    local o = p.owner
    local fee = 1 + (Config.Rent.lateFeePct or 0) / 100
    local owed = math.floor((o.missed or 0) * (o.amount or 0) * (o.kind == 'rented' and fee or 1))
    return owed
end

function Ownership.Statement(p)
    local o = p.owner
    if not o then return nil end
    local prefs = o.prefs or {}
    return {
        kind = o.kind, amount = o.amount, next_due = o.next_due, balance = o.balance, payments_left = o.payments_left, missed = o.missed,
        deposit = o.deposit, arrears = arrears(p), owed = tonumber(prefs.owed) or 0, bills = prefs.bills or {}, insured = prefs.insured == true,
        rentDays = rentDays(p), mortgageDays = Config.Mortgage.periodDays, autoPay = Config.Rent.autoPay, payOff = Config.Mortgage.payOffEarly,
        evictAfter = Config.Rent.evictAfter, missedLimit = Config.Mortgage.missedLimit, lateFeePct = Config.Rent.lateFeePct,
        sellValue = math.max(0, math.floor(Props.Price(p) * sellBack(p) / 100) - ((o.kind == 'mortgage' and o.balance) or 0) - (tonumber(prefs.owed) or 0)),
        utilitiesOff = prefs.utilitiesOff == true,
    }
end

local function advance(p, succeeded)
    local o = p.owner
    local days = o.kind == 'mortgage' and (Config.Mortgage.periodDays or 7) or rentDays(p)
    local fields = { next_due = (o.next_due > 0 and o.next_due or os.time()) + period(days) }
    if succeeded then
        fields.paid = (o.paid or 0) + (o.amount or 0)
        if o.kind == 'mortgage' then
            fields.balance = math.max(0, (o.balance or 0) - (o.amount or 0))
            fields.payments_left = math.max(0, (o.payments_left or 0) - 1)
            if fields.balance <= 0 or fields.payments_left <= 0 then
                fields.kind, fields.balance, fields.payments_left, fields.amount, fields.next_due = 'owned', 0, 0, 0, 0
            end
        end
    else
        fields.missed = (o.missed or 0) + 1
    end
    Props.UpdateOwner(p.id, fields)
end

function Ownership.Settle(p, src, manual)
    local o = p.owner
    if not o or (o.kind ~= 'rented' and o.kind ~= 'mortgage') then return end
    local now = os.time()
    local guard = 0
    while p.owner and (p.owner.kind == 'rented' or p.owner.kind == 'mortgage') and p.owner.next_due > 0 and p.owner.next_due <= now and guard < 12 do
        guard = guard + 1
        local amount = p.owner.amount or 0
        local paid = false
        if manual or Config.Rent.autoPay or p.owner.kind == 'mortgage' then
            paid = charge(src, amount, p.owner.kind == 'mortgage' and 'xs-housing-mortgage' or 'xs-housing-rent')
        end
        if paid then
            advance(p, true)
            Logs.Add('payment', p.id, Logs.Who(src), p.owner and p.owner.kind or '', amount)
            Framework.Notify(src, Text('paid_due', { amount = Util.Money(amount), place = p.data.label }), 'success')
            if p.owner and p.owner.kind == 'owned' then
                Framework.Notify(src, Text('mortgage_done', { place = p.data.label }), 'success')
                Logs.Add('payoff', p.id, Logs.Who(src), '', 0)
            end
        else
            local graceEnd = p.owner.next_due + Util.Days(Config.Rent.graceDays or 0)
            if now < graceEnd then
                if not p.warned then
                    p.warned = true
                    Framework.Notify(src, Text('payment_due_soon', { amount = Util.Money(amount), place = p.data.label }), 'error')
                end
                break
            end
            p.warned = nil
            advance(p, false)
            Logs.Add('missed', p.id, Logs.Who(src), '', amount)
            Framework.Notify(src, Text('payment_missed', { place = p.data.label }), 'error')
        end
    end
    if not p.owner then return end
    if p.owner.kind == 'rented' and (p.owner.missed or 0) >= (Config.Rent.evictAfter or 2) then
        Ownership.Evict(p.id, nil, Text('log_unpaid_rent'))
    elseif p.owner.kind == 'mortgage' and (p.owner.missed or 0) >= (Config.Mortgage.missedLimit or 3) then
        Ownership.Repossess(p.id, Text('log_unpaid_mortgage'))
    end
end

function Ownership.PayArrears(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, id, 'bills') then return false, Text('err_no_rights') end
    local owedBills = tonumber((p.owner.prefs or {}).owed) or 0
    local total = arrears(p) + owedBills
    if total <= 0 then
        Ownership.Settle(p, src, true)
        return true, 0
    end
    if not charge(src, total, 'xs-housing-arrears') then return false, Text('err_money', { amount = Util.Money(total) }) end
    local prefs = p.owner.prefs or {}
    prefs.owed = 0
    prefs.utilitiesOff = false
    Props.UpdateOwner(id, { missed = 0, prefs = prefs })
    Logs.Add('payment', id, Logs.Who(src), Text('log_arrears'), total)
    return true, total
end

function Ownership.PayOff(src, id)
    local p = Props.Get(id)
    if not p or not p.owner or p.owner.kind ~= 'mortgage' then return false, Text('err_no_mortgage_here') end
    if not Config.Mortgage.payOffEarly then return false, Text('err_failed') end
    if not Access.Can(src, id, 'bills') then return false, Text('err_no_rights') end
    local total = (p.owner.balance or 0) + arrears(p)
    if not charge(src, total, 'xs-housing-payoff') then return false, Text('err_money', { amount = Util.Money(total) }) end
    Props.UpdateOwner(id, { kind = 'owned', balance = 0, payments_left = 0, amount = 0, next_due = 0, missed = 0, paid = (p.owner.paid or 0) + total })
    Logs.Add('payoff', id, Logs.Who(src), '', total)
    return true, total
end

function Ownership.InitBills(p)
    if not p.owner then return end
    local B = Config.Bills
    local prefs = p.owner.prefs or {}
    prefs.bills = prefs.bills or {}
    local now = os.time()
    if B.tax then prefs.bills.tax = prefs.bills.tax or (now + Util.Days(B.taxDays)) end
    if B.utilities then prefs.bills.utilities = prefs.bills.utilities or (now + Util.Days(B.utilitiesDays)) end
    Props.UpdateOwner(p.id, { prefs = prefs })
end

local function billDue(p, src, key, amount, days)
    local prefs = p.owner.prefs
    local due = tonumber(prefs.bills[key]) or 0
    if due == 0 then prefs.bills[key] = os.time() + Util.Days(days) return true end
    if due > os.time() then return false end
    prefs.bills[key] = due + Util.Days(days)
    if amount > 0 then
        if charge(src, amount, 'xs-housing-bill') then
            Logs.Add('bill', p.id, Logs.Who(src), key, amount)
            Framework.Notify(src, Text('bill_paid', { bill = Text('bill_' .. key), amount = Util.Money(amount), place = p.data.label }), 'inform')
        else
            prefs.owed = (tonumber(prefs.owed) or 0) + amount
            if key == 'utilities' then prefs.utilitiesOff = true end
            Framework.Notify(src, Text('bill_unpaid', { bill = Text('bill_' .. key), place = p.data.label }), 'error')
        end
    end
    return true
end

function Ownership.Bills(p, src)
    if not p.owner or p.owner.kind == 'starter' then return end
    local B = Config.Bills
    local prefs = p.owner.prefs or {}
    prefs.bills = prefs.bills or {}
    p.owner.prefs = prefs
    local changed = false
    if B.tax and p.owner.kind ~= 'rented' then
        changed = billDue(p, src, 'tax', math.floor(Props.Price(p) * (B.taxPct or 0) / 100), B.taxDays) or changed
    end
    if B.utilities then
        changed = billDue(p, src, 'utilities', B.utilitiesPrice or 0, B.utilitiesDays) or changed
    end
    if B.insurance and prefs.insured then
        changed = billDue(p, src, 'insurance', B.insurancePrice or 0, B.insuranceDays) or changed
    end
    if changed then Props.UpdateOwner(p.id, { prefs = prefs }) end
end

function Ownership.Insure(src, id, on)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Config.Bills.insurance then return false, Text('err_failed') end
    if not Access.Can(src, id, 'bills') then return false, Text('err_no_rights') end
    local prefs = p.owner.prefs or {}
    if on and not prefs.insured then
        if not charge(src, Config.Bills.insurancePrice or 0, 'xs-housing-insurance') then return false, Text('err_money', { amount = Util.Money(Config.Bills.insurancePrice) }) end
        prefs.bills = prefs.bills or {}
        prefs.bills.insurance = os.time() + Util.Days(Config.Bills.insuranceDays or 7)
    end
    prefs.insured = on == true
    Props.UpdateOwner(id, { prefs = prefs })
    return true
end

function Ownership.Touch(cid)
    for _, p in ipairs(Props.OwnedBy(cid)) do
        local prefs = p.owner.prefs or {}
        prefs.lastSeen = os.time()
        p.owner.prefs = prefs
        MySQL.update('UPDATE xs_housing_owners SET prefs = ? WHERE property_id = ?', { Db.Json(prefs), p.id })
    end
end

function Ownership.Tick(src)
    local cid = Framework.GetCitizenId(src)
    if not cid then return end
    for _, p in ipairs(Props.OwnedBy(cid)) do
        Ownership.Settle(p, src, false)
        if Props.Get(p.id) and p.owner then Ownership.Bills(p, src) end
    end
end

CreateThread(function()
    while not Props.ready do Wait(1000) end
    while true do
        Wait(60 * 1000)
        for _, src in ipairs(Framework.Players()) do
            local ok, err = pcall(Ownership.Tick, src)
            if not ok then print(('^1[XS-Housing]^0 payment check failed: %s'):format(tostring(err))) end
        end
    end
end)

CreateThread(function()
    while not Props.ready do Wait(1000) end
    while true do
        local days = tonumber(Config.Ownership.inactiveDays) or 0
        if days > 0 then
            local cutoff = os.time() - days * 86400
            for id, p in pairs(Props.list) do
                local seen = p.owner and tonumber((p.owner.prefs or {}).lastSeen) or nil
                if p.owner and seen and seen < cutoff and not Framework.SourceOf(p.owner.citizenid) then
                    Ownership.Repossess(id, Text('log_inactive', { days = days }))
                end
            end
        end
        Wait(3600 * 1000)
    end
end)

Framework.OnLoaded(function(src)
    local cid = Framework.GetCitizenId(src)
    if not cid then return end
    Ownership.Touch(cid)
    SetTimeout(4000, function()
        if GetPlayerName(src) then Ownership.Tick(src) end
    end)
end)

Framework.OnUnloaded(function(src)
    local cid = Framework.GetCitizenId(src)
    if cid then Ownership.Touch(cid) end
end)
