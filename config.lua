Config = {}

Config.Locale = 'en'
Config.Debug = false

-- Leave on 'auto' unless you run two of the same kind of script.
Config.Bridges = {
    framework = 'auto',  -- 'qbox' | 'qbcore'
    target = 'auto',     -- 'ox_target' | 'qb-target' | 'none' (E prompts)
    inventory = 'auto',  -- 'ox_inventory' | 'qb-inventory' | 'qs-inventory' | 'ps-inventory' | 'codem-inventory' | 'core_inventory'
    clothing = 'auto',   -- 'XS-Appearance' | 'illenium-appearance' | 'qb-clothing'
    banking = 'auto',    -- society accounts for the real estate agency
    dispatch = 'auto',   -- alarm calls to police
    doorlock = 'auto',   -- 'XS-DoorLock' | 'ox_doorlock' | 'mri_Qdoorlock' | 'qb-doorlock' | 'rcore_doorlock' | 'qs-doorlock-creator' | 'doors_creator' | 'cd_doorlock' | 'none'
    garage = 'auto',     -- 'jg-advancedgarages' | 'qbx_garages' | 'qb-garages' | 'cd_garage' | 'okokGarage' | 'none'
    weather = 'auto',    -- paused while you are inside a house
    phone = 'auto',      -- doorbell and alarm notifications
}

-- Who can open /housebuilder. add_ace group.admin xs.housing.admin allow
Config.Admin = {
    acePermission = 'xs.housing.admin',
    licenses = {},
    groups = { 'god', 'admin' },
    -- Builder rights beyond opening it. Everyone with access gets the ones set to true.
    rights = { prices = true, delete = true, evict = true, catalogue = true, import = true },
}

Config.Commands = {
    builder = 'housebuilder',
    panel = 'house',
    diag = 'housediag',
}

Config.Ownership = {
    maxProperties = 3,       -- places one character can own or rent in total
    maxHouses = 2,
    maxApartments = 2,
    maxOffices = 1,
    sellBackPct = 70,        -- paid back when an owner sells to the market
    inactiveDays = 0,        -- take a place back after this many days offline. 0 = never
    claimDays = 7,           -- days to collect your storage after you leave a place
}

Config.Starter = {
    enabled = true,
    onFirstSpawn = true,     -- a new character gets a free starter apartment
    removeOnPurchase = true, -- the starter apartment goes when you buy or rent somewhere else
}

Config.Buying = {
    selfServe = 'no_agents', -- 'always' | 'no_agents' (only when no agent is on duty) | 'never'
    taxPct = 0,              -- added on top of the price
    tours = true,            -- look around inside before buying
    tourMinutes = 3,
    demand = false,          -- prices rise in areas where places sell
    demandStepPct = 2,
    demandMaxPct = 30,
}

Config.Rent = {
    enabled = true,
    periodDays = 7,
    autoPay = true,          -- taken from the bank when due (or when you next log in)
    graceDays = 2,
    lateFeePct = 10,
    evictAfter = 2,          -- missed payments before eviction
    deposit = 1,             -- payments taken up front as a deposit (given back when you move out)
}

Config.Mortgage = {
    enabled = true,
    minDepositPct = 20,
    terms = { 8, 16, 24 },   -- number of payments to choose from
    interestPct = 8,
    periodDays = 7,
    missedLimit = 3,         -- missed payments before the bank takes it back
    payOffEarly = true,
}

Config.Bills = {
    tax = false, taxPct = 0.5, taxDays = 7,
    utilities = false, utilitiesPrice = 150, utilitiesDays = 7,
    insurance = false, insurancePrice = 500, insuranceDays = 7, insurancePayout = 5000,
}

Config.Keys = {
    max = 6,
    guestHours = { 1, 6, 24, 72 },
    changeLocksPrice = 500,
    coOwnersSell = false,    -- co-owners can sell the place
    tenantsFurnish = true,   -- tenants and co-owners can move furniture
}

Config.Entering = {
    fadeMs = 400,
    doorAnim = true,
    knock = true,
    doorbell = true,
    unlockedLetsAnyoneIn = true,
    markers = false,         -- draw a marker on doors as well as the target
    useKey = 'E',            -- E prompt when no target script runs
}

Config.Interiors = {
    shellPlacement = 'sky',  -- 'sky' | 'underground'
    shellHeight = 450.0,
    undergroundDepth = 60.0,
    freezeTime = true,
    hour = 13,
    freezeWeather = true,
    weather = 'EXTRASUNNY',
    styleChanges = true,
    styleCost = 2500,
    instanced = true,        -- each place gets its own private copy of the inside
}

Config.Furniture = {
    enabled = true,
    limit = 120,             -- per place, unless the place sets its own
    gridSize = 0.25,
    rotateStep = 15,
    refundPct = 50,
    placeRange = 10.0,
}

Config.Yards = {
    enabled = true,
    limit = 40,
    heightLimit = 6.0,
    drawDistance = 90.0,
    everyoneSees = true,
    defaultSize = 12.0,
}

Config.Storage = {
    enabled = true,
    slots = 40,
    weight = 200000,
    keyHolders = true,
    upgrades = {
        { slots = 60, weight = 300000, price = 6000 },
        { slots = 80, weight = 450000, price = 15000 },
        { slots = 120, weight = 700000, price = 40000 },
    },
}

Config.Wardrobe = {
    enabled = true,
}

-- The smart-home panel: which tiles owners see.
Config.Panel = {
    lock = true, lights = true, music = true, cameras = true, keys = true, bills = true,
    visitors = true, furniture = true, security = true, style = true, storage = true, settings = true,
    fromAnywhere = true,     -- /house opens the panel away from home too. Furnishing still needs you there
    prop = 'hei_prop_hei_securitypanel', -- the screen on the wall at every panel point. false for none
    propTurn = 0.0,          -- starting turn when staff place a panel point. Use 180 if your prop faces into the wall
}

-- Owners, or agents for places on the market, open the door for a while so anyone can walk in.
Config.OpenHouse = {
    enabled = true,
    minutes = 15,
    blip = true,             -- a map blip while it is open
}

-- Holiday decorations. A season's items can be bought and show in homes and yards only while it is on.
-- active: 'auto' follows the dates below, 'none' turns them all off, or a season id keeps that one on.
-- Pumpkins and bats need game build 2944 or newer, the snow fort 3095 or newer.
Config.Seasons = {
    active = 'auto',
    hideOffSeason = true,    -- placed decorations hide until their season comes round again
    list = {
        { id = 'halloween', label = 'Halloween', from = '10-01', to = '11-05' },
        { id = 'winter', label = 'Winter holidays', from = '12-01', to = '01-07' },
        { id = 'july4', label = 'Fourth of July', from = '06-28', to = '07-07' },
    },
}

-- Fridges are storage that keeps food fresh: it goes off this many times slower inside.
-- Needs ox_inventory items with degrade. 1 makes a fridge plain storage.
Config.Fridge = {
    keepsFresh = 4,
}

-- Music from the panel and from speakers, and the sound of TVs. No other resource needed.
Config.Music = {
    houseVolume = 0.4,
    houseRange = 25.0,
    speakerRange = 20.0,
    tvRange = 15.0,
}

Config.Doorbell = {
    enabled = true,
    phone = true,
    letInRemotely = true,
    camera = true,
    cooldown = 8,
}

Config.Security = {
    alarm = true,
    alarmLevels = {
        { label = 'Alarm', price = 5000 },
        { label = 'Monitored alarm', price = 15000 },
    },
    alarmCallsPolice = true,
    alarmCallsOwner = true,
    silentAlarm = false,
    cameras = true,
    cameraPrice = 2500,
    maxCameras = 4,
    locks = {
        { label = 'Standard lock', price = 0 },
        { label = 'Deadbolt', price = 4000 },
        { label = 'Reinforced door', price = 12000 },
    },
}

Config.BreakIns = {
    enabled = true,
    item = 'lockpick',
    removeItemChance = 30,
    difficulty = {
        { 'easy', 'easy', 'medium' },
        { 'easy', 'medium', 'medium', 'hard' },
        { 'medium', 'hard', 'hard', 'hard' },
    },
    policeChance = 60,
    alertDelay = 10,
    nightOnly = false,
    nightStart = 21,
    nightEnd = 5,
    cooldownMinutes = 60,
    ownerOnline = true,      -- no break-ins while every key holder is offline
    minPolice = 0,
    openMinutes = 5,
    storage = true,          -- burglars can open storage
    safesProtected = true,   -- but never a safe
    evidence = true,         -- a lockpick without gloves leaves a fingerprint at the door (XS-PoliceSystem, or qb-policejob evidence)
    brokenLock = true,       -- a picked lock stays forced: police can see it, and it picks like the cheapest lock until repaired
    repairPrice = 750,
}

Config.Raids = {
    enabled = true,
    jobs = { 'police', 'lspd', 'bcso', 'sasp', 'sast', 'ranger' },
    types = { 'leo' },
    minGrade = 0,
    needWarrant = false,     -- needs an active warrant on the owner in XS-MDT
    ramItem = '',
    openMinutes = 10,
    notifyOwner = true,
    search = true,
}

Config.Spawn = {
    atHome = true,
    logoutInBed = true,
}

Config.Phone = {
    notify = true,
}

Config.Agency = {
    enabled = true,
    job = 'realestate',
    commissionPct = 5,
    priceRangePct = 20,      -- how far agents can move a price, up or down
    account = 'realestate',  -- society account that gets a share of every agent sale
    societyPct = 5,
    approval = false,        -- staff approve agents' price changes
    grades = { list = 0, sell = 0, rent = 0, price = 2, evict = 3 },
}

Config.Blips = {
    owned = { show = true, sprite = 40, colour = 2, scale = 0.75 },
    keys = { show = true, sprite = 40, colour = 3, scale = 0.7 },
    forSale = { show = true, sprite = 350, colour = 0, scale = 0.6, agentsOnly = false },
    building = { show = true, sprite = 475, colour = 0, scale = 0.7 },
    agency = { show = true, sprite = 375, colour = 2, scale = 0.8 },
}

Config.Performance = {
    drawDistance = 60.0,
    signDistance = 40.0,
}

Config.Builder = {
    showExisting = true,
    cameraSpeed = { normal = 6.0, fast = 18.0, slow = 1.5 },
    quickType = 'house',
    quickInterior = 'shell',
    quickYard = true,
    quickBlip = true,
    priceByArea = true,
}

Config.Logs = {
    keepDays = 30,
    webhooks = { sales = '', rent = '', keys = '', breakins = '', raids = '', admin = '' },
}

-- Starting prices by GTA area code (GetNameOfZone). Quick place uses these.
Config.AreaPrices = {
    default = 180000,
    RICHM = 1650000, ROCKF = 1400000, PBLUFF = 950000, BHAMCA = 1200000, CHIL = 1900000, TONGVAH = 1100000,
    VINE = 520000, WVINE = 610000, DTVINE = 480000, HORS = 650000, DELPE = 560000, DELSOL = 390000,
    MIRR = 420000, EAST_V = 260000, MORN = 700000, BURTON = 680000, HAWICK = 340000, ALTA = 450000,
    KOREAT = 300000, LMESA = 210000, MURRI = 230000, VESP = 280000, BEACH = 300000, VCANA = 360000,
    DAVIS = 120000, STRAW = 110000, CHAMH = 105000, RANCHO = 115000, CYPRE = 130000, ELYSIAN = 140000,
    SANDY = 90000, GRAPES = 95000, PALETO = 140000, HARMO = 85000, ZANCUDO = 80000, MTCHIL = 160000,
    CHU = 520000, BANHAMC = 700000, NCHU = 450000,
}

-- Shells used when importing from qb-houses, by its tier number.
Config.ImportTiers = { 'shell_v16low', 'shell_v16mid', 'shell_trevor', 'shell_trailer', 'shell_lester', 'shell_ranch', 'shell_michael' }
