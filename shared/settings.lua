Settings = { fields = {}, byKey = {} }

local SELF_SERVE = { 'always', 'no_agents', 'never' }
local PLACEMENT = { 'sky', 'underground' }
local WEATHERS = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST', 'SMOG', 'FOGGY', 'RAIN', 'XMAS' }
local LEVELS = { 'easy', 'medium', 'hard' }
local SEASONS = { 'auto', 'none' }
for _, s in ipairs((Config.Seasons or {}).list or {}) do
    if type(s) == 'table' and type(s.id) == 'string' then SEASONS[#SEASONS + 1] = s.id end
end

Settings.Sections = {
    { id = 'ownership', icon = 'key', fields = {
        { 'Ownership.maxProperties', 'int', min = 1, max = 50 },
        { 'Ownership.maxHouses', 'int', min = 0, max = 50 },
        { 'Ownership.maxApartments', 'int', min = 0, max = 50 },
        { 'Ownership.maxOffices', 'int', min = 0, max = 50 },
        { 'Ownership.sellBackPct', 'pct' },
        { 'Ownership.inactiveDays', 'int', min = 0, max = 365, unit = 'days' },
        { 'Ownership.claimDays', 'int', min = 1, max = 90, unit = 'days' },
        { 'Starter.enabled', 'bool' },
        { 'Starter.onFirstSpawn', 'bool', needs = 'Starter.enabled' },
        { 'Starter.removeOnPurchase', 'bool', needs = 'Starter.enabled' },
    } },
    { id = 'buying', icon = 'cash', fields = {
        { 'Buying.selfServe', 'select', options = SELF_SERVE },
        { 'Buying.taxPct', 'pct' },
        { 'Buying.tours', 'bool' },
        { 'Buying.tourMinutes', 'int', min = 1, max = 30, unit = 'min', needs = 'Buying.tours' },
        { 'OpenHouse.enabled', 'bool' },
        { 'OpenHouse.minutes', 'int', min = 5, max = 120, unit = 'min', needs = 'OpenHouse.enabled' },
        { 'OpenHouse.blip', 'bool', needs = 'OpenHouse.enabled' },
        { 'Buying.demand', 'bool' },
        { 'Buying.demandStepPct', 'pct', needs = 'Buying.demand' },
        { 'Buying.demandMaxPct', 'pct', needs = 'Buying.demand' },
    } },
    { id = 'rent', icon = 'clock', fields = {
        { 'Rent.enabled', 'bool' },
        { 'Rent.periodDays', 'num', min = 0.5, max = 60, step = 0.5, unit = 'days', needs = 'Rent.enabled' },
        { 'Rent.autoPay', 'bool', needs = 'Rent.enabled' },
        { 'Rent.graceDays', 'num', min = 0, max = 30, step = 0.5, unit = 'days', needs = 'Rent.enabled' },
        { 'Rent.lateFeePct', 'pct', needs = 'Rent.enabled' },
        { 'Rent.evictAfter', 'int', min = 1, max = 20, needs = 'Rent.enabled' },
        { 'Rent.deposit', 'int', min = 0, max = 10, needs = 'Rent.enabled' },
    } },
    { id = 'mortgage', icon = 'building', fields = {
        { 'Mortgage.enabled', 'bool' },
        { 'Mortgage.minDepositPct', 'pct', needs = 'Mortgage.enabled' },
        { 'Mortgage.terms', 'nums', min = 2, max = 200, count = 6, needs = 'Mortgage.enabled' },
        { 'Mortgage.interestPct', 'num', min = 0, max = 100, step = 0.5, unit = '%', needs = 'Mortgage.enabled' },
        { 'Mortgage.periodDays', 'num', min = 0.5, max = 60, step = 0.5, unit = 'days', needs = 'Mortgage.enabled' },
        { 'Mortgage.missedLimit', 'int', min = 1, max = 20, needs = 'Mortgage.enabled' },
        { 'Mortgage.payOffEarly', 'bool', needs = 'Mortgage.enabled' },
    } },
    { id = 'bills', icon = 'paper', fields = {
        { 'Bills.tax', 'bool' },
        { 'Bills.taxPct', 'num', min = 0, max = 20, step = 0.1, unit = '%', needs = 'Bills.tax' },
        { 'Bills.taxDays', 'num', min = 1, max = 60, step = 0.5, unit = 'days', needs = 'Bills.tax' },
        { 'Bills.utilities', 'bool' },
        { 'Bills.utilitiesPrice', 'int', min = 0, max = 100000, step = 10, unit = '$', needs = 'Bills.utilities' },
        { 'Bills.utilitiesDays', 'num', min = 1, max = 60, step = 0.5, unit = 'days', needs = 'Bills.utilities' },
        { 'Bills.insurance', 'bool' },
        { 'Bills.insurancePrice', 'int', min = 0, max = 1000000, step = 50, unit = '$', needs = 'Bills.insurance' },
        { 'Bills.insuranceDays', 'num', min = 1, max = 60, step = 0.5, unit = 'days', needs = 'Bills.insurance' },
        { 'Bills.insurancePayout', 'int', min = 0, max = 10000000, step = 50, unit = '$', needs = 'Bills.insurance' },
    } },
    { id = 'keys', icon = 'key', fields = {
        { 'Keys.max', 'int', min = 0, max = 50 },
        { 'Keys.guestHours', 'nums', min = 1, max = 720, count = 6, unit = 'h' },
        { 'Keys.changeLocksPrice', 'int', min = 0, max = 1000000, step = 50, unit = '$' },
        { 'Keys.coOwnersSell', 'bool' },
        { 'Keys.tenantsFurnish', 'bool' },
    } },
    { id = 'entering', icon = 'door', fields = {
        { 'Entering.fadeMs', 'int', min = 0, max = 3000, step = 50, unit = 'ms' },
        { 'Entering.doorAnim', 'bool' },
        { 'Entering.knock', 'bool' },
        { 'Entering.doorbell', 'bool' },
        { 'Entering.unlockedLetsAnyoneIn', 'bool' },
        { 'Entering.markers', 'bool' },
    } },
    { id = 'interiors', icon = 'home', fields = {
        { 'Interiors.shellPlacement', 'select', options = PLACEMENT },
        { 'Interiors.shellHeight', 'num', min = 100, max = 1500, step = 10, unit = 'm' },
        { 'Interiors.undergroundDepth', 'num', min = 20, max = 300, step = 5, unit = 'm' },
        { 'Interiors.instanced', 'bool' },
        { 'Interiors.freezeTime', 'bool' },
        { 'Interiors.hour', 'int', min = 0, max = 23, unit = 'h', needs = 'Interiors.freezeTime' },
        { 'Interiors.freezeWeather', 'bool' },
        { 'Interiors.weather', 'select', options = WEATHERS, needs = 'Interiors.freezeWeather' },
        { 'Interiors.styleChanges', 'bool' },
        { 'Interiors.styleCost', 'int', min = 0, max = 1000000, step = 50, unit = '$', needs = 'Interiors.styleChanges' },
    } },
    { id = 'furniture', icon = 'sofa', fields = {
        { 'Furniture.enabled', 'bool' },
        { 'Furniture.limit', 'int', min = 1, max = 1000, needs = 'Furniture.enabled' },
        { 'Furniture.gridSize', 'num', min = 0.05, max = 2, step = 0.05, unit = 'm', needs = 'Furniture.enabled' },
        { 'Furniture.rotateStep', 'int', min = 1, max = 90, unit = '°', needs = 'Furniture.enabled' },
        { 'Furniture.refundPct', 'pct', needs = 'Furniture.enabled' },
        { 'Furniture.placeRange', 'num', min = 2, max = 40, step = 0.5, unit = 'm', needs = 'Furniture.enabled' },
        { 'Fridge.keepsFresh', 'int', min = 1, max = 20, unit = 'x', needs = 'Furniture.enabled' },
        { 'Seasons.active', 'select', options = SEASONS, needs = 'Furniture.enabled' },
        { 'Seasons.hideOffSeason', 'bool', needs = 'Furniture.enabled' },
    } },
    { id = 'yards', icon = 'tree', fields = {
        { 'Yards.enabled', 'bool' },
        { 'Yards.limit', 'int', min = 1, max = 500, needs = 'Yards.enabled' },
        { 'Yards.heightLimit', 'num', min = 1, max = 40, step = 0.5, unit = 'm', needs = 'Yards.enabled' },
        { 'Yards.drawDistance', 'num', min = 20, max = 400, step = 5, unit = 'm', needs = 'Yards.enabled' },
        { 'Yards.everyoneSees', 'bool', needs = 'Yards.enabled' },
        { 'Yards.defaultSize', 'num', min = 3, max = 60, step = 0.5, unit = 'm', needs = 'Yards.enabled' },
    } },
    { id = 'storage', icon = 'locker', fields = {
        { 'Storage.enabled', 'bool' },
        { 'Storage.slots', 'int', min = 1, max = 300, needs = 'Storage.enabled' },
        { 'Storage.weight', 'int', min = 1000, max = 10000000, step = 1000, unit = 'g', needs = 'Storage.enabled' },
        { 'Storage.keyHolders', 'bool', needs = 'Storage.enabled' },
        { 'Wardrobe.enabled', 'bool' },
    } },
    { id = 'panel', icon = 'grid', fields = {
        { 'Panel.lock', 'bool' },
        { 'Panel.lights', 'bool' },
        { 'Panel.music', 'bool' },
        { 'Panel.cameras', 'bool' },
        { 'Panel.keys', 'bool' },
        { 'Panel.bills', 'bool' },
        { 'Panel.visitors', 'bool' },
        { 'Panel.furniture', 'bool' },
        { 'Panel.security', 'bool' },
        { 'Panel.style', 'bool' },
        { 'Panel.storage', 'bool' },
        { 'Panel.settings', 'bool' },
        { 'Panel.fromAnywhere', 'bool' },
    } },
    { id = 'doorbell', icon = 'bell', fields = {
        { 'Doorbell.enabled', 'bool' },
        { 'Doorbell.phone', 'bool', needs = 'Doorbell.enabled' },
        { 'Doorbell.letInRemotely', 'bool', needs = 'Doorbell.enabled' },
        { 'Doorbell.camera', 'bool', needs = 'Doorbell.enabled' },
        { 'Doorbell.cooldown', 'int', min = 0, max = 120, unit = 's', needs = 'Doorbell.enabled' },
    } },
    { id = 'security', icon = 'shield', fields = {
        { 'Security.alarm', 'bool' },
        { 'Security.alarmCallsPolice', 'bool', needs = 'Security.alarm' },
        { 'Security.alarmCallsOwner', 'bool', needs = 'Security.alarm' },
        { 'Security.silentAlarm', 'bool', needs = 'Security.alarm' },
        { 'Security.cameras', 'bool' },
        { 'Security.cameraPrice', 'int', min = 0, max = 1000000, step = 50, unit = '$', needs = 'Security.cameras' },
        { 'Security.maxCameras', 'int', min = 1, max = 12, needs = 'Security.cameras' },
    } },
    { id = 'breakins', icon = 'crowbar', fields = {
        { 'BreakIns.enabled', 'bool' },
        { 'BreakIns.item', 'item', off = true, needs = 'BreakIns.enabled' },
        { 'BreakIns.removeItemChance', 'pct', needs = 'BreakIns.enabled' },
        { 'BreakIns.difficulty.1', 'seq', options = LEVELS, max = 6, needs = 'BreakIns.enabled' },
        { 'BreakIns.difficulty.2', 'seq', options = LEVELS, max = 6, needs = 'BreakIns.enabled' },
        { 'BreakIns.difficulty.3', 'seq', options = LEVELS, max = 6, needs = 'BreakIns.enabled' },
        { 'BreakIns.policeChance', 'pct', needs = 'BreakIns.enabled' },
        { 'BreakIns.alertDelay', 'int', min = 0, max = 300, unit = 's', needs = 'BreakIns.enabled' },
        { 'BreakIns.nightOnly', 'bool', needs = 'BreakIns.enabled' },
        { 'BreakIns.nightStart', 'int', min = 0, max = 23, unit = 'h', needs = 'BreakIns.nightOnly' },
        { 'BreakIns.nightEnd', 'int', min = 0, max = 23, unit = 'h', needs = 'BreakIns.nightOnly' },
        { 'BreakIns.cooldownMinutes', 'int', min = 0, max = 1440, unit = 'min', needs = 'BreakIns.enabled' },
        { 'BreakIns.ownerOnline', 'bool', needs = 'BreakIns.enabled' },
        { 'BreakIns.minPolice', 'int', min = 0, max = 50, needs = 'BreakIns.enabled' },
        { 'BreakIns.openMinutes', 'int', min = 1, max = 60, unit = 'min', needs = 'BreakIns.enabled' },
        { 'BreakIns.storage', 'bool', needs = 'BreakIns.enabled' },
        { 'BreakIns.safesProtected', 'bool', needs = 'BreakIns.storage' },
        { 'BreakIns.evidence', 'bool', needs = 'BreakIns.enabled' },
        { 'BreakIns.brokenLock', 'bool', needs = 'BreakIns.enabled' },
        { 'BreakIns.repairPrice', 'int', min = 0, max = 1000000, step = 50, unit = '$', needs = 'BreakIns.brokenLock' },
    } },
    { id = 'raids', icon = 'badge', fields = {
        { 'Raids.enabled', 'bool' },
        { 'Raids.jobs', 'list', max = 20, slug = true, needs = 'Raids.enabled' },
        { 'Raids.types', 'list', max = 10, slug = true, needs = 'Raids.enabled' },
        { 'Raids.minGrade', 'int', min = 0, max = 50, needs = 'Raids.enabled' },
        { 'Raids.needWarrant', 'bool', needs = 'Raids.enabled' },
        { 'Raids.ramItem', 'text', max = 48, slug = true, empty = true, needs = 'Raids.enabled' },
        { 'Raids.openMinutes', 'int', min = 1, max = 120, unit = 'min', needs = 'Raids.enabled' },
        { 'Raids.notifyOwner', 'bool', needs = 'Raids.enabled' },
        { 'Raids.search', 'bool', needs = 'Raids.enabled' },
    } },
    { id = 'agency', icon = 'tag', fields = {
        { 'Agency.enabled', 'bool' },
        { 'Agency.job', 'text', max = 48, slug = true, needs = 'Agency.enabled' },
        { 'Agency.commissionPct', 'num', min = 0, max = 50, step = 0.5, unit = '%', needs = 'Agency.enabled' },
        { 'Agency.priceRangePct', 'pct', needs = 'Agency.enabled' },
        { 'Agency.account', 'text', max = 48, slug = true, needs = 'Agency.enabled' },
        { 'Agency.societyPct', 'num', min = 0, max = 50, step = 0.5, unit = '%', needs = 'Agency.enabled' },
        { 'Agency.approval', 'bool', needs = 'Agency.enabled' },
        { 'Agency.grades.list', 'grade', needs = 'Agency.enabled' },
        { 'Agency.grades.sell', 'grade', needs = 'Agency.enabled' },
        { 'Agency.grades.rent', 'grade', needs = 'Agency.enabled' },
        { 'Agency.grades.price', 'grade', needs = 'Agency.enabled' },
        { 'Agency.grades.evict', 'grade', needs = 'Agency.enabled' },
    } },
    { id = 'spawn', icon = 'bed', fields = {
        { 'Spawn.atHome', 'bool' },
        { 'Spawn.logoutInBed', 'bool' },
        { 'Phone.notify', 'bool' },
    } },
    { id = 'map', icon = 'mapblip', fields = {
        { 'Blips.owned.show', 'bool' },
        { 'Blips.owned.sprite', 'int', min = 1, max = 900, needs = 'Blips.owned.show' },
        { 'Blips.owned.colour', 'int', min = 0, max = 85, needs = 'Blips.owned.show' },
        { 'Blips.keys.show', 'bool' },
        { 'Blips.keys.sprite', 'int', min = 1, max = 900, needs = 'Blips.keys.show' },
        { 'Blips.keys.colour', 'int', min = 0, max = 85, needs = 'Blips.keys.show' },
        { 'Blips.forSale.show', 'bool' },
        { 'Blips.forSale.sprite', 'int', min = 1, max = 900, needs = 'Blips.forSale.show' },
        { 'Blips.forSale.colour', 'int', min = 0, max = 85, needs = 'Blips.forSale.show' },
        { 'Blips.forSale.agentsOnly', 'bool', needs = 'Blips.forSale.show' },
        { 'Blips.building.show', 'bool' },
        { 'Blips.building.sprite', 'int', min = 1, max = 900, needs = 'Blips.building.show' },
        { 'Blips.building.colour', 'int', min = 0, max = 85, needs = 'Blips.building.show' },
        { 'Blips.agency.show', 'bool' },
        { 'Blips.agency.sprite', 'int', min = 1, max = 900, needs = 'Blips.agency.show' },
        { 'Blips.agency.colour', 'int', min = 0, max = 85, needs = 'Blips.agency.show' },
    } },
    { id = 'builder', icon = 'gear', fields = {
        { 'Builder.showExisting', 'bool' },
        { 'Builder.cameraSpeed.normal', 'num', min = 1, max = 30, step = 0.5, unit = 'm/s' },
        { 'Builder.cameraSpeed.fast', 'num', min = 1, max = 60, step = 0.5, unit = 'm/s' },
        { 'Builder.cameraSpeed.slow', 'num', min = 0.2, max = 10, step = 0.1, unit = 'm/s' },
        { 'Builder.quickType', 'select', options = { 'house', 'mlo', 'motel', 'office' } },
        { 'Builder.quickInterior', 'select', options = { 'shell', 'ipl', 'none' } },
        { 'Builder.quickYard', 'bool' },
        { 'Builder.quickBlip', 'bool' },
        { 'Builder.priceByArea', 'bool' },
        { 'Performance.drawDistance', 'num', min = 10, max = 300, step = 5, unit = 'm' },
        { 'Performance.signDistance', 'num', min = 5, max = 200, step = 5, unit = 'm' },
        { 'Logs.keepDays', 'int', min = 1, max = 365, unit = 'days' },
        { 'Logs.webhooks.sales', 'text', max = 200, empty = true },
        { 'Logs.webhooks.rent', 'text', max = 200, empty = true },
        { 'Logs.webhooks.keys', 'text', max = 200, empty = true },
        { 'Logs.webhooks.breakins', 'text', max = 200, empty = true },
        { 'Logs.webhooks.raids', 'text', max = 200, empty = true },
        { 'Logs.webhooks.admin', 'text', max = 200, empty = true },
    } },
}

for _, section in ipairs(Settings.Sections) do
    local list = {}
    for _, raw in ipairs(section.fields) do
        local def = { key = raw[1], type = raw[2], section = section.id }
        for k, v in pairs(raw) do
            if type(k) == 'string' then def[k] = v end
        end
        list[#list + 1] = def
        Settings.fields[#Settings.fields + 1] = def
        Settings.byKey[def.key] = def
    end
    section.fields = list
end

local function path(key)
    local parts = {}
    for part in key:gmatch('[^%.]+') do parts[#parts + 1] = tonumber(part) or part end
    return parts
end

function Settings.Read(key)
    local node = Config
    for _, part in ipairs(path(key)) do
        if type(node) ~= 'table' then return nil end
        node = node[part]
    end
    return node
end

function Settings.Write(key, value)
    local parts = path(key)
    local node = Config
    for i = 1, #parts - 1 do
        if type(node[parts[i]]) ~= 'table' then node[parts[i]] = {} end
        node = node[parts[i]]
    end
    node[parts[#parts]] = value
end

function Settings.Same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    if #a ~= #b then return false end
    for k, v in pairs(a) do
        if not Settings.Same(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function slug(value, max)
    return (tostring(value or ''):lower():gsub('[^%w_%-]', '')):sub(1, max or 48)
end

local function within(def, n)
    if def.min and n < def.min then n = def.min end
    if def.max and n > def.max then n = def.max end
    return n
end

function Settings.Clean(def, value)
    local kind = def.type
    if kind == 'bool' then
        if type(value) == 'boolean' then return value end
        if value == 1 or value == '1' or value == 'true' then return true end
        if value == 0 or value == '0' or value == 'false' then return false end
        return nil
    elseif kind == 'int' or kind == 'grade' or kind == 'pct' then
        local n = tonumber(value)
        if not n or n ~= n then return nil end
        n = math.floor(n + 0.5)
        if kind == 'grade' then return math.max(0, math.min(50, n)) end
        if kind == 'pct' then return math.max(0, math.min(100, n)) end
        return within(def, n)
    elseif kind == 'num' then
        local n = tonumber(value)
        if not n or n ~= n then return nil end
        local step = def.step or 0.1
        n = math.floor(n / step + 0.5) * step
        n = math.floor(n * 1000 + 0.5) / 1000
        return within(def, n)
    elseif kind == 'text' then
        if value == nil or type(value) == 'table' then return nil end
        local s = Util.Text(value, 220)
        if def.slug then s = slug(s, 96) end
        s = s:sub(1, def.max or 64)
        if s == '' and not def.empty then return nil end
        return s
    elseif kind == 'select' then
        for _, option in ipairs(def.options or {}) do
            if option == value then return value end
        end
        return nil
    elseif kind == 'item' then
        local s = (value == false or value == nil) and '' or slug(value, 64)
        if s ~= '' then return s end
        if def.off then return false end
        return nil
    elseif kind == 'list' then
        if type(value) ~= 'table' then return nil end
        local out, seen = {}, {}
        for _, v in ipairs(value) do
            local s = def.slug and slug(v, 48) or Util.Text(v, 48)
            if s ~= '' and not seen[s] and #out < (def.max or 20) then
                seen[s] = true
                out[#out + 1] = s
            end
        end
        return out
    elseif kind == 'nums' then
        if type(value) ~= 'table' then return nil end
        local out, seen = {}, {}
        for _, v in ipairs(value) do
            local n = tonumber(v)
            if n then
                n = within(def, math.floor(n + 0.5))
                if not seen[n] and #out < (def.count or 10) then
                    seen[n] = true
                    out[#out + 1] = n
                end
            end
        end
        table.sort(out)
        if #out == 0 then return nil end
        return out
    elseif kind == 'seq' then
        if type(value) ~= 'table' then return nil end
        local allowed = {}
        for _, option in ipairs(def.options or {}) do allowed[option] = true end
        local out = {}
        for _, v in ipairs(value) do
            if allowed[v] and #out < (def.max or 5) then out[#out + 1] = v end
        end
        if #out == 0 then return nil end
        return out
    end
    return nil
end

function Settings.Apply(values)
    if type(values) ~= 'table' then return end
    for key, value in pairs(values) do
        local def = Settings.byKey[key]
        if def then
            local clean = Settings.Clean(def, value)
            if clean ~= nil then Settings.Write(key, clean) end
        end
    end
end

function Settings.Public()
    local sections = {}
    for _, section in ipairs(Settings.Sections) do
        local fields = {}
        for _, def in ipairs(section.fields) do
            local out = {}
            for k, v in pairs(def) do out[k] = v end
            fields[#fields + 1] = out
        end
        sections[#sections + 1] = { id = section.id, icon = section.icon, fields = fields }
    end
    return sections
end
