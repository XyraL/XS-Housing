Security = { open = {}, cooldowns = {}, attempts = {}, notes = {} }

local function sec(p)
    p.owner.security = type(p.owner.security) == 'table' and p.owner.security or {}
    local s = p.owner.security
    s.lock = tonumber(s.lock) or p.data.security.lockLevel or 1
    s.alarm = tonumber(s.alarm) or 0
    s.cameras = type(s.cameras) == 'table' and s.cameras or {}
    if s.armed == nil then s.armed = true end
    return s
end

function Security.State(p)
    if not p.owner then return nil end
    local s = sec(p)
    return {
        lock = s.lock, maxLock = math.min(#Config.Security.locks, p.data.security.maxLevel or 3), locks = Config.Security.locks,
        alarm = s.alarm, alarms = Config.Security.alarmLevels, alarmAllowed = Config.Security.alarm and p.data.security.alarm, armed = s.armed ~= false,
        cameras = s.cameras, cameraPrice = Config.Security.cameraPrice, maxCameras = Config.Security.maxCameras,
        camerasAllowed = Config.Security.cameras and p.data.security.cameras, builtinCameras = p.data.points.cameras,
        lastBreakIn = s.lastBreakIn,
        forced = tonumber(s.forced), repairPrice = Config.BreakIns.repairPrice or 0,
    }
end

local function saveSec(p)
    Props.UpdateOwner(p.id, { security = p.owner.security })
end

function Security.BuyLock(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, id, 'security') then return false, Text('err_no_rights') end
    local s = sec(p)
    local nextLevel = s.lock + 1
    local maxLevel = math.min(#Config.Security.locks, p.data.security.maxLevel or 3)
    local def = Config.Security.locks[nextLevel]
    if not def or nextLevel > maxLevel then return false, Text('err_max_level') end
    if not Framework.Charge(src, def.price or 0, 'bank', 'xs-housing-lock') then return false, Text('err_money', { amount = Util.Money(def.price) }) end
    s.lock = nextLevel
    s.forced = nil
    saveSec(p)
    Logs.Add('locks', id, Logs.Who(src), def.label or '', def.price or 0)
    return true, nextLevel
end

function Security.BuyAlarm(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Config.Security.alarm or not p.data.security.alarm then return false, Text('err_failed') end
    if not Access.Can(src, id, 'security') then return false, Text('err_no_rights') end
    local s = sec(p)
    local def = Config.Security.alarmLevels[s.alarm + 1]
    if not def then return false, Text('err_max_level') end
    if not Framework.Charge(src, def.price or 0, 'bank', 'xs-housing-alarm') then return false, Text('err_money', { amount = Util.Money(def.price) }) end
    s.alarm = s.alarm + 1
    s.armed = true
    saveSec(p)
    Logs.Add('alarm', id, Logs.Who(src), def.label or '', def.price or 0)
    return true, s.alarm
end

function Security.Arm(src, id, on)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, id, 'lock') then return false, Text('err_no_rights') end
    local s = sec(p)
    if s.alarm < 1 then return false, Text('err_no_alarm') end
    s.armed = on == true
    saveSec(p)
    return true
end

function Security.AddCamera(src, id, at, label)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Config.Security.cameras or not p.data.security.cameras then return false, Text('err_failed') end
    if not Access.Can(src, id, 'security') then return false, Text('err_no_rights') end
    local s = sec(p)
    if #s.cameras >= (Config.Security.maxCameras or 4) then return false, Text('err_camera_limit', { n = Config.Security.maxCameras }) end
    local pt = Util.Point(at)
    if not pt then return false, Text('err_failed') end
    local anchor = p.data.door
    if anchor and Util.Distance(pt, anchor) > 60.0 then return false, Text('err_too_far') end
    if not Framework.Charge(src, Config.Security.cameraPrice or 0, 'bank', 'xs-housing-camera') then return false, Text('err_money', { amount = Util.Money(Config.Security.cameraPrice) }) end
    pt.label = Util.Text(label, 32) ~= '' and Util.Text(label, 32) or Text('camera_n', { n = #s.cameras + 1 })
    pt.rx = Util.Round(tonumber(at.rx) or -10.0, 1)
    s.cameras[#s.cameras + 1] = pt
    saveSec(p)
    return true, s.cameras
end

function Security.RemoveCamera(src, id, index)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, id, 'security') then return false, Text('err_no_rights') end
    local s = sec(p)
    if not s.cameras[tonumber(index) or 0] then return false, Text('err_failed') end
    table.remove(s.cameras, tonumber(index))
    saveSec(p)
    return true, s.cameras
end

function Security.Cameras(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    local allowed = Access.Can(src, id, 'cameras')
    if not allowed and not (Security.open[id] and Security.open[id].mode == 'police' and Framework.IsCopSource(src)) then return false, Text('err_no_rights') end
    local list = {}
    for _, c in ipairs(p.data.points.cameras or {}) do list[#list + 1] = c end
    for _, c in ipairs(sec(p).cameras) do list[#list + 1] = c end
    if Config.Doorbell.camera and p.data.door then
        local d = p.data.door
        local h = math.rad(d.w or 0.0)
        list[#list + 1] = { x = d.x - math.sin(h) * 1.6, y = d.y + math.cos(h) * 1.6, z = d.z + 1.4, w = ((d.w or 0.0) + 180.0) % 360, rx = -12.0, label = Text('doorbell_cam'), doorbell = true }
    end
    return true, list
end

local function night()
    local B = Config.BreakIns
    local hour = tonumber(os.date('%H'))
    if B.nightStart > B.nightEnd then return hour >= B.nightStart or hour < B.nightEnd end
    return hour >= B.nightStart and hour < B.nightEnd
end

function Security.IsOpenFor(src, id)
    local o = Security.open[id]
    if not o or o.untilAt < os.time() then return false end
    if o.mode == 'police' then return Framework.IsCopSource(src) end
    return true
end

function Security.ModeFor(src, id)
    local o = Security.open[id]
    if not o then return nil end
    if o.mode == 'police' then return 'police' end
    return 'burglar'
end

function Security.StorageOpen(src, id)
    local o = Security.open[id]
    if not o or o.untilAt < os.time() then return false end
    if o.mode == 'police' then return Config.Raids.search and Framework.IsCopSource(src) end
    return Config.BreakIns.storage and o.by[src] == true
end

function Security.NoteStorage(src, id)
    local o = Security.open[id]
    if o and o.mode == 'burglar' and o.by[src] and not o.noted then
        o.noted = true
        local p = Props.Get(id)
        if p and p.owner then
            Logs.Add('breakin', id, Logs.Who(src), Text('log_storage_opened'), 0)
            if Config.Bills.insurance and p.owner.prefs and p.owner.prefs.insured and (Config.Bills.insurancePayout or 0) > 0 then
                local owner = Framework.SourceOf(p.owner.citizenid)
                if owner then
                    Framework.AddMoney(owner, 'bank', Config.Bills.insurancePayout, 'xs-housing-insurance')
                    Framework.Notify(owner, Text('insurance_paid', { amount = Util.Money(Config.Bills.insurancePayout), place = p.data.label }), 'inform')
                end
            end
        end
    end
end

local function openUp(p, mode, src, minutes)
    local o = Security.open[p.id]
    if not o or o.mode ~= mode then
        o = { mode = mode, by = {}, untilAt = 0 }
        Security.open[p.id] = o
    end
    o.by[src] = true
    o.untilAt = os.time() + minutes * 60
    Props.Sync(p.id)
    if p.data.interior.kind == 'mlo' or p.data.type == 'mlo' then
        Doors.SetLocked(p, false, src)
    end
    SetTimeout(minutes * 60 * 1000 + 500, function()
        local now = Security.open[p.id]
        if now == o and now.untilAt <= os.time() then
            Security.open[p.id] = nil
            Props.Sync(p.id)
            if p.owner and p.owner.locked == 1 and (p.data.interior.kind == 'mlo' or p.data.type == 'mlo') then Doors.SetLocked(p, true) end
        end
    end)
end

local function alarm(p, src)
    local s = sec(p)
    if s.alarm < 1 or s.armed == false or not Config.Security.alarm then return end
    local door = p.data.door
    if not Config.Security.silentAlarm then
        TriggerClientEvent('XS-Housing:client:alarm', -1, p.id, door)
    end
    if Config.Security.alarmCallsOwner then
        for _, holder in ipairs(Access.OnlineHolders(p.id)) do
            Framework.Notify(holder, Text('alarm_owner', { place = p.data.label }), 'error')
            Phone.Notify(holder, Text('phone_alarm_title'), Text('alarm_owner', { place = p.data.label }))
        end
    end
    if Config.Security.alarmCallsPolice and door then
        Dispatch.Forward({ title = Text('dispatch_alarm_title'), description = Text('dispatch_alarm', { place = p.data.label, street = p.data.address.street }), coords = door, code = '10-90', sprite = 40, colour = 1, priority = s.alarm >= 2 and 1 or 2 })
    end
    Logs.Add('alarm', p.id, Logs.Who(src), Text('log_alarm'), 0)
end

function Security.BreakInCheck(src, id)
    local B = Config.BreakIns
    if not B.enabled then return false, Text('err_breakins_off') end
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_nothing_to_steal') end
    if not p.data.security.breakIns then return false, Text('err_breakins_off') end
    if Access.Role(src, id) then return false, Text('err_its_yours') end
    if B.nightOnly and not night() then return false, Text('err_daytime') end
    local cooldown = (p.data.security.cooldown or 0) > 0 and p.data.security.cooldown or B.cooldownMinutes
    local last = Security.cooldowns[id]
    if last and os.time() - last < cooldown * 60 then return false, Text('err_cooldown') end
    if B.ownerOnline and #Access.OnlineHolders(id) == 0 then return false, Text('err_owner_offline') end
    if (B.minPolice or 0) > 0 and #Framework.Cops() < B.minPolice then return false, Text('err_min_police', { n = B.minPolice }) end
    if B.item and B.item ~= '' and Inventory.Count(src, B.item) < 1 then return false, Text('err_need_item', { item = Inventory.Label(B.item) }) end
    local lock = sec(p).lock
    if B.brokenLock and tonumber(sec(p).forced) then lock = 1 end
    local diff = B.difficulty[lock] or B.difficulty[#B.difficulty] or { 'medium' }
    Security.attempts[src] = { id = id, at = os.time() }
    return true, { difficulty = diff, lock = lock }
end

local function doorOf(p)
    if p.data.door then return p.data.door end
    local b = p.data.building > 0 and Props.Get(p.data.building)
    return b and b.data.door or nil
end

local function leavePrint(src, p, bare)
    if not Config.BreakIns.evidence or not bare or GetResourceState('XS-PoliceSystem') ~= 'started' then return false end
    local door = doorOf(p)
    local ok, added = pcall(function()
        return exports['XS-PoliceSystem']:AddEvidence('fingerprint', src, door and { x = door.x, y = door.y, z = door.z } or nil)
    end)
    return ok and added == true
end

function Security.RepairLock(src, id)
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_not_owned') end
    if not Access.Can(src, id, 'security') then return false, Text('err_no_rights') end
    local s = sec(p)
    if not tonumber(s.forced) then return false, Text('err_lock_fine') end
    local price = Config.BreakIns.repairPrice or 0
    if price > 0 and not Framework.Charge(src, price, 'bank', 'xs-housing-repair') then return false, Text('err_money', { amount = Util.Money(price) }) end
    s.forced = nil
    saveSec(p)
    Logs.Add('repair', id, Logs.Who(src), Text('log_lock_repaired'), price)
    return true
end

function Security.BreakInResult(src, id, success, bare)
    local att = Security.attempts[src]
    Security.attempts[src] = nil
    if not att or att.id ~= id or os.time() - att.at > 90 then return false, Text('err_failed') end
    local B = Config.BreakIns
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_failed') end
    if B.item and B.item ~= '' and math.random(100) <= (B.removeItemChance or 0) then
        Inventory.Remove(src, B.item, 1)
        Framework.Notify(src, Text('lockpick_broke'), 'error')
    end
    Security.cooldowns[id] = os.time()
    leavePrint(src, p, bare == true)
    if not success then
        if math.random(100) <= math.floor((B.policeChance or 0) / 2) then
            Dispatch.Forward({ title = Text('dispatch_breakin_title'), description = Text('dispatch_breakin', { street = p.data.address.street }), coords = p.data.door, code = '10-62', sprite = 40, colour = 1, priority = 2 })
        end
        return false, Text('lockpick_failed')
    end
    local s = sec(p)
    s.lastBreakIn = os.time()
    if B.brokenLock then s.forced = os.time() end
    saveSec(p)
    openUp(p, 'burglar', src, B.openMinutes or 5)
    Logs.Add('breakin', id, Logs.Who(src), '', 0)
    alarm(p, src)
    if math.random(100) <= (B.policeChance or 0) then
        SetTimeout((B.alertDelay or 0) * 1000, function()
            Dispatch.Forward({ title = Text('dispatch_breakin_title'), description = Text('dispatch_breakin', { street = p.data.address.street }), coords = p.data.door, code = '10-62', sprite = 40, colour = 1, priority = 2 })
        end)
    end
    for _, holder in ipairs(Access.OnlineHolders(id)) do
        if s.alarm < 1 then
            Framework.Notify(holder, Text('breakin_owner_quiet', { place = p.data.label }), 'error')
        end
    end
    return true
end

function Security.Warrant(cid)
    if GetResourceState('XS-MDT') ~= 'started' then return nil end
    local ok, result = pcall(function() return exports['XS-MDT']:GetActiveWarrants(cid) end)
    if ok then return (tonumber(result) or 0) > 0 end
    return nil
end

function Security.Raid(src, id)
    local R = Config.Raids
    if not R.enabled then return false, Text('err_raids_off') end
    local p = Props.Get(id)
    if not p or not p.owner then return false, Text('err_nobody') end
    if not p.data.security.raids then return false, Text('err_raids_off') end
    local job = Framework.GetJob(src)
    if not Framework.IsCop(job) then return false, Text('err_police_only') end
    if (job.grade or 0) < (R.minGrade or 0) then return false, Text('err_grade') end
    if R.needWarrant then
        local has, checked = false, false
        for _, cid in ipairs(Access.Holders(id)) do
            local w = Security.Warrant(cid)
            if w ~= nil then checked = true end
            if w then has = true break end
        end
        if checked and not has then return false, Text('err_no_warrant') end
    end
    if R.ramItem and R.ramItem ~= '' and Inventory.Count(src, R.ramItem) < 1 then return false, Text('err_need_item', { item = Inventory.Label(R.ramItem) }) end
    openUp(p, 'police', src, R.openMinutes or 10)
    Logs.Add('raid', id, Logs.Who(src), '', 0)
    if R.notifyOwner then
        for _, holder in ipairs(Access.OnlineHolders(id)) do
            Framework.Notify(holder, Text('raid_owner', { place = p.data.label }), 'error')
        end
    end
    for _, other in ipairs(Enter.Who(id)) do
        Framework.Notify(other, Text('raid_inside'), 'error')
    end
    return true
end

function Security.Close(src, id)
    local p = Props.Get(id)
    if not p then return false end
    local o = Security.open[id]
    if not o then return true end
    if o.mode == 'police' and not Framework.IsCopSource(src) and not Access.Role(src, id) then return false, Text('err_no_rights') end
    Security.open[id] = nil
    Props.Sync(id)
    if p.owner and p.owner.locked == 1 and (p.data.interior.kind == 'mlo' or p.data.type == 'mlo') then Doors.SetLocked(p, true, src) end
    return true
end

AddEventHandler('playerDropped', function()
    Security.attempts[source] = nil
end)
