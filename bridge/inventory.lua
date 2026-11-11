Inventory = { name = nil }

if not Config then return end

local CANDIDATES = { 'ox_inventory', 'qb-inventory', 'qs-inventory', 'ps-inventory', 'codem-inventory', 'core_inventory' }

local function running(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

do
    local forced = Config.Bridges and Config.Bridges.inventory or 'auto'
    if forced ~= 'auto' then
        Inventory.name = forced
    else
        for _, res in ipairs(CANDIDATES) do
            if running(res) then Inventory.name = res break end
        end
    end
end

local function frameworkItems()
    if Framework.name == 'qbox' then return {} end
    return Framework.core and Framework.core.Shared and Framework.core.Shared.Items or {}
end

function Inventory.Label(item)
    if not item then return '' end
    if Inventory.name == 'ox_inventory' then
        local ok, items = pcall(function() return exports.ox_inventory:Items(item) end)
        if ok and type(items) == 'table' and items.label then return items.label end
    end
    local def = frameworkItems()[item]
    return def and def.label or item
end

local IMAGE_FOLDERS = {
    ['qb-inventory'] = 'nui://qb-inventory/html/images/',
    ['ps-inventory'] = 'nui://ps-inventory/html/images/',
    ['qs-inventory'] = 'nui://qs-inventory/web/dist/images/',
    ['codem-inventory'] = 'nui://codem-inventory/html/itemimages/',
    ['core_inventory'] = 'nui://core_inventory/html/img/',
}

local function imageFolder()
    if Inventory.name == 'codem-inventory' and running('codem-inventory-images') then return 'nui://codem-inventory-images/images/' end
    return IMAGE_FOLDERS[Inventory.name]
end

function Inventory.Image(item)
    if not item or item == '' then return '' end
    local custom = (Config.Armory or {}).images
    if type(custom) == 'string' and custom ~= '' and custom ~= 'auto' then
        if custom:find('%%s') then return custom:format(item) end
        return custom .. item .. '.png'
    end
    if Inventory.name == 'ox_inventory' then
        local ok, def = pcall(function() return exports.ox_inventory:Items(item) end)
        local image = ok and type(def) == 'table' and type(def.client) == 'table' and def.client.image or nil
        if type(image) == 'string' and image:find('://') then return image end
        local name = ok and type(def) == 'table' and type(def.name) == 'string' and def.name or item
        local folder = GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images')
        return ('%s/%s'):format(folder, type(image) == 'string' and image ~= '' and image or (name .. '.png'))
    end
    local folder = imageFolder()
    if not folder then return '' end
    local def = frameworkItems()[item]
    local file = def and type(def.image) == 'string' and def.image ~= '' and def.image or (item .. '.png')
    if file:find('://') then return file end
    return folder .. file
end

if IsDuplicityVersion() then
    function Inventory.Count(src, item)
        if not item or item == '' then return 0 end
        if Inventory.name == 'ox_inventory' then
            return exports.ox_inventory:Search(src, 'count', item) or 0
        end
        if Inventory.name == 'qs-inventory' then
            local ok, total = pcall(function() return exports['qs-inventory']:GetItemTotalAmount(src, item) end)
            if ok then return tonumber(total) or 0 end
        end
        local player = Framework.GetPlayer(src)
        if not player then return 0 end
        local found = player.Functions.GetItemByName(item)
        return found and (found.amount or found.count) or 0
    end

    function Inventory.Remove(src, item, amount, metadata)
        amount = amount or 1
        if not item then return false end
        if Inventory.name == 'ox_inventory' then
            return exports.ox_inventory:RemoveItem(src, item, amount, metadata) and true or false
        end
        if Inventory.name == 'qb-inventory' then
            local ok, removed = pcall(function() return exports['qb-inventory']:RemoveItem(src, item, amount, false, 'XS-Housing') end)
            if ok then
                if removed then TriggerClientEvent('qb-inventory:client:ItemBox', src, frameworkItems()[item] or { name = item, label = item }, 'remove', amount) end
                return removed and true or false
            end
        end
        local player = Framework.GetPlayer(src)
        if not player then return false end
        return player.Functions.RemoveItem(item, amount) and true or false
    end

    function Inventory.OpenStash(src, id, label, slots, weight, groups, coords)
        if Inventory.name == 'ox_inventory' then
            exports.ox_inventory:RegisterStash(id, label, slots, weight, false, groups, coords)
            return 'client'
        end
        if Inventory.name == 'qb-inventory' then
            local ok = pcall(function()
                exports['qb-inventory']:OpenInventory(src, id, { label = label, maxweight = weight, slots = slots })
            end)
            if ok then return 'server' end
        end
        return 'legacy'
    end

    local function trimPlate(plate)
        return (tostring(plate or ''):gsub('^%s+', ''):gsub('%s+$', ''))
    end

    local function addNames(out, items)
        for _, slot in pairs(type(items) == 'table' and items or {}) do
            if type(slot) == 'table' and slot.name and (slot.count or slot.amount or 1) > 0 then out[#out + 1] = slot.name end
        end
    end

    lib.callback.register('XS-Housing:server:itemCount', function(src, item)
        return Inventory.Count(src, tostring(item or ''))
    end)

    local hotbarHook
    if Inventory.name == 'qb-inventory' then
        CreateThread(function()
            local untilAt = GetGameTimer() + 30000
            while GetResourceState('qb-inventory') ~= 'started' and GetGameTimer() < untilAt do Wait(500) end
            pcall(function()
                hotbarHook = exports['qb-inventory']:AddHook('ItemUsed', function(_, data)
                    local src = type(data) == 'table' and tonumber(data.source)
                    if src and Player(src).state.xspHotbarOff then return false end
                end)
            end)
        end)
    end

    AddEventHandler('onResourceStop', function(name)
        if name ~= GetCurrentResourceName() or not hotbarHook then return end
        pcall(function() exports['qb-inventory']:RemoveHook('ItemUsed', hotbarHook) end)
    end)
else
    local holds, saved = 0, nil

    function Inventory.HoldHotbar(on)
        local bag = LocalPlayer.state
        if on then
            holds = holds + 1
            if holds > 1 then return end
            saved = { hotkeys = bag.invHotkeys, busy = bag.inv_busy }
            bag:set('invHotkeys', false, false)
            bag:set('inv_busy', true, false)
            bag:set('xspHotbarOff', true, true)
            return
        end
        if holds == 0 then return end
        holds = holds - 1
        if holds > 0 then return end
        local was = saved or {}
        saved = nil
        if bag.invHotkeys == false then bag:set('invHotkeys', was.hotkeys, false) end
        if bag.inv_busy == true then bag:set('inv_busy', was.busy, false) end
        bag:set('xspHotbarOff', false, true)
    end

    AddEventHandler('onResourceStop', function(name)
        if name ~= GetCurrentResourceName() or holds == 0 then return end
        holds = 1
        Inventory.HoldHotbar(false)
    end)

    local cache, cacheAt = {}, {}

    function Inventory.Count(item)
        if not item or item == '' then return 0 end
        if Inventory.name == 'ox_inventory' then
            return exports.ox_inventory:Search('count', item) or 0
        end
        local now = GetGameTimer()
        if cacheAt[item] and now - cacheAt[item] < 1500 then return cache[item] or 0 end
        local count = lib.callback.await('XS-Housing:server:itemCount', false, item) or 0
        cache[item], cacheAt[item] = count, now
        return count
    end

    function Inventory.Invalidate()
        cache, cacheAt = {}, {}
    end

    function Inventory.OpenStash(mode, id, label, slots, weight)
        if mode == 'client' then
            exports.ox_inventory:openInventory('stash', id)
        elseif mode == 'legacy' then
            if Inventory.name == 'qs-inventory' then
                pcall(function() exports['qs-inventory']:RegisterStash(id, slots, weight) end)
            end
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, { maxweight = weight, slots = slots })
            TriggerEvent('inventory:client:SetCurrentStash', id)
        end
    end

    RegisterNetEvent('XS-Housing:client:invalidateInventory', function()
        Inventory.Invalidate()
    end)

    RegisterNetEvent('XS-Housing:client:openVehicleInventory', function(kind, plate, size)
        size = size or {}
        TriggerServerEvent('inventory:server:OpenInventory', kind, plate, { maxweight = size.weight, slots = size.slots })
        TriggerEvent('inventory:client:SetCurrentStash', plate)
    end)

    RegisterNetEvent('XS-Housing:client:openPlayerInventory', function(target)
        TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', target)
    end)
end
