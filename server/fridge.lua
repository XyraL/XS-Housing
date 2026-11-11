Fridge = { ids = {} }

function Fridge.Factor()
    return math.max(1, tonumber((Config.Fridge or {}).keepsFresh) or 1)
end

function Fridge.Track(stashId)
    Fridge.ids[stashId] = true
end

function Fridge.Is(inv)
    return type(inv) == 'string' and Fridge.ids[inv] == true
end

function Fridge.Chill(m, k, now)
    if type(m) ~= 'table' or m.xsh_cold then return nil end
    local degrade, expires = tonumber(m.degrade), tonumber(m.durability)
    if not degrade or not expires or expires <= 100 or k <= 1 then return nil end
    local left = expires - now
    if left <= 0 then return nil end
    local out = Util.Copy(m)
    out.xsh_cold = k
    out.degrade = degrade * k
    out.durability = math.floor(now + left * k)
    return out
end

function Fridge.Warm(m, now)
    if type(m) ~= 'table' then return nil end
    local k = tonumber(m.xsh_cold)
    if not k then return nil end
    local out = Util.Copy(m)
    out.xsh_cold = nil
    if tonumber(m.degrade) then out.degrade = m.degrade / k end
    local expires = tonumber(m.durability)
    if expires and expires > 100 then out.durability = math.floor(now + math.max(0, expires - now) / k) end
    return out
end

local function sweep(inv)
    if inv == nil or inv == '' then return end
    local ok, items = pcall(function() return exports.ox_inventory:GetInventoryItems(inv) end)
    if not ok or type(items) ~= 'table' then return end
    local cold, k, now = Fridge.Is(inv), Fridge.Factor(), os.time()
    for _, item in pairs(items) do
        if type(item) == 'table' and item.slot then
            local fresh
            if cold then fresh = Fridge.Chill(item.metadata, k, now) else fresh = Fridge.Warm(item.metadata, now) end
            if fresh then pcall(function() exports.ox_inventory:SetMetadata(inv, item.slot, fresh) end) end
        end
    end
end

function Fridge.Moved(payload)
    if type(payload) ~= 'table' then return end
    local from, to = payload.fromInventory, payload.toInventory
    if to == 'newdrop' then to = payload.dropId end
    if not Fridge.Is(from) and not Fridge.Is(to) then return end
    sweep(from)
    if to ~= from then sweep(to) end
end

CreateThread(function()
    if Inventory.name ~= 'ox_inventory' then return end
    local untilAt = GetGameTimer() + 30000
    while GetResourceState('ox_inventory') ~= 'started' and GetGameTimer() < untilAt do Wait(500) end
    local ok, hookId = pcall(function()
        return exports.ox_inventory:registerHook('swapItems', function() return true end, { inventoryFilter = { '^xsh_' } })
    end)
    if not ok or type(hookId) ~= 'string' then return end
    AddEventHandler(hookId, function(success, payload)
        if success then Fridge.Moved(payload) end
    end)
end)
