Listing = { id = nil, offer = nil }
Agency = { zones = {} }

function Listing.Open(id, offer)
    local ok, data = Housing.Call('listing', id)
    if not ok then return Util.Notify(data or Text('err_failed'), 'error') end
    Listing.id = id
    Listing.offer = offer
    data.offer = offer
    UI.Send('listing', 'open', data)
    UI.Focus('listing', true)
end

function Listing.Close()
    Listing.id = nil
    UI.Send('listing', 'close', {})
    UI.Focus('listing', false)
end

UI.OnClose('listing', function()
    if Listing.offer then Housing.Call('agencyAccept', Listing.offer.offer, false) end
    Listing.offer = nil
    Listing.Close()
end)

UI.Handle('listing:quote', function(p)
    return Housing.Call('quote', Listing.id, p.mode, p.opts)
end)

UI.Handle('listing:acquire', function(p)
    local id = Listing.id
    local ok, result
    if Listing.offer then
        ok, result = Housing.Call('agencyAccept', Listing.offer.offer, true)
        Listing.offer = nil
    else
        ok, result = Housing.Call('acquire', id, p.mode, p.opts)
    end
    if not ok then return false, result end
    Listing.Close()
    PlaySoundFrontend(-1, 'PROPERTY_PURCHASE', 'HUD_AWARDS', true)
    Util.Notify(Text('welcome_home'), 'success')
    return true, result
end)

UI.Handle('listing:tour', function()
    local id = Listing.id
    Listing.Close()
    CreateThread(function() Util.Result(Housing.Call('tour', id)) end)
    return true
end)

UI.Handle('listing:photo', function()
    return Housing.Call('photo', Listing.id)
end)

UI.Handle('agency:photo', function(p)
    return Housing.Call('photo', p.id)
end)

UI.Handle('listing:waypoint', function()
    local p = Housing.Prop(Listing.id)
    local door = p and Housing.DoorOf(p)
    if door then SetNewWaypoint(door.x + 0.0, door.y + 0.0) end
    return true
end)

RegisterNetEvent('XS-Housing:client:offer', function(data)
    if type(data) ~= 'table' or not data.property then return end
    Util.Notify(Text('offer_received', { agent = data.agent, place = data.property.label }), 'inform')
    Listing.Open(data.property.id, { offer = data.offer, agent = data.agent, mode = data.mode, quote = data.quote })
end)

local function agencyOpen()
    local ok, data = Housing.Call('agency')
    if not ok then return Util.Notify(data or Text('err_failed'), 'error') end
    data.nearby = Panel.Nearby(8.0)
    UI.Send('agency', 'open', data)
    UI.Focus('agency', true)
end

UI.OnClose('agency', function()
    UI.Send('agency', 'close', {})
    UI.Focus('agency', false)
end)

UI.Handle('agency:refresh', function()
    local ok, data = Housing.Call('agency')
    if ok then data.nearby = Panel.Nearby(8.0) end
    return ok, data
end)
UI.Handle('agency:listed', function(p) return Housing.Call('agencyListed', p.id, p.listed == true) end)
UI.Handle('agency:openHouse', function(p) return Housing.Call('openHouse', p.id, p.on == true) end)
UI.Handle('agency:price', function(p) return Housing.Call('agencyPrice', p.id, p.price, p.rent) end)
UI.Handle('agency:offer', function(p) return Housing.Call('agencyOffer', p.id, p.target, p.mode, p.opts) end)
UI.Handle('agency:evict', function(p) return Housing.Call('agencyEvict', p.id) end)
UI.Handle('agency:waypoint', function(p)
    local prop = Housing.Prop(p.id)
    local door = prop and Housing.DoorOf(prop)
    if door then SetNewWaypoint(door.x + 0.0, door.y + 0.0) end
    return true
end)

local function claimsMenu()
    local ok, list = Housing.Call('claims')
    if not ok then return Util.Notify(list or Text('err_failed'), 'error') end
    if type(list) ~= 'table' or #list == 0 then return Util.Notify(Text('no_claims'), 'inform') end
    local options = {}
    for _, claim in ipairs(list) do
        for _, s in ipairs(claim.stashes or {}) do
            options[#options + 1] = {
                title = ('%s · %s'):format(claim.label, s.label),
                description = Text('claim_until', { days = math.max(0, math.ceil(((claim['until'] or 0) - Util.Now()) / 86400)) }),
                icon = 'box-open',
                onSelect = function()
                    local okOpen, data = Housing.Call('openClaim', claim.id, s.id)
                    if not okOpen then return Util.Notify(data or Text('err_failed'), 'error') end
                    if data.mode ~= 'server' then Inventory.OpenStash(data.mode, data.id, data.label, data.slots, data.weight) end
                end,
            }
        end
    end
    lib.registerContext({ id = 'xsh_claims', title = Text('claims_title'), options = options })
    lib.showContext('xsh_claims')
end

local function refreshAgency()
    for key in pairs(Agency.zones) do Target.Remove(key) end
    Agency.zones = {}
    local a = Housing.agency or {}
    if not a.enabled then return end
    if a.office then
        Target.AddPoint('agency_office', vector3(a.office.x + 0.0, a.office.y + 0.0, a.office.z + 0.0), 1.2, {
            { label = Text('opt_agency_tablet'), icon = 'fas fa-tablet', onSelect = agencyOpen, canInteract = function()
                local job = Framework.Job()
                return job ~= nil and job.name == a.job and job.onDuty
            end },
            { label = Text('opt_claims'), icon = 'fas fa-box-open', onSelect = claimsMenu },
        })
        Agency.zones.agency_office = true
    end
    if a.desk then
        Target.AddPoint('agency_desk', vector3(a.desk.x + 0.0, a.desk.y + 0.0, a.desk.z + 0.0), 1.2, {
            { label = Text('opt_claims'), icon = 'fas fa-box-open', onSelect = claimsMenu },
        })
        Agency.zones.agency_desk = true
    end
end

Housing.On('agency', refreshAgency)
Housing.On('all', refreshAgency)

RegisterCommand('housetablet', function()
    local job = Framework.Job()
    if not job or job.name ~= (Housing.agency or {}).job or not job.onDuty then
        return Util.Notify(Text('err_not_agent'), 'error')
    end
    agencyOpen()
end, false)
