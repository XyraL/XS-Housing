Clothing = { name = nil }

if IsDuplicityVersion() or not Config then return end

local SUPPORTED = { 'XS-Appearance', 'illenium-appearance', 'qb-clothing' }

local function detect()
    local forced = Config.Bridges and Config.Bridges.clothing or 'auto'
    if forced == 'none' then return nil end
    if forced ~= 'auto' then return forced end
    for _, resource in ipairs(SUPPORTED) do
        if GetResourceState(resource) == 'started' then return resource end
    end
    return nil
end

function Clothing.OpenOutfits()
    Clothing.name = detect()
    if Clothing.name == 'XS-Appearance' then
        local ok = pcall(function() exports['XS-Appearance']:OpenWardrobe() end)
        if ok then return true end
    end
    if Clothing.name == 'illenium-appearance' then
        TriggerEvent('illenium-appearance:client:openOutfitMenu')
        return true
    end
    if Clothing.name == 'qb-clothing' then
        TriggerEvent('qb-clothing:client:openOutfitMenu')
        return true
    end
    return false
end


