(() => {
    if (typeof GetParentResourceName === 'function') return;
    if (location.hostname.toLowerCase() === RESOURCE.toLowerCase()) return;

    const send = (app, action, data) => window.dispatchEvent(new MessageEvent('message', { data: { app, action, data } }));
    const params = new URLSearchParams(location.search);
    const view = params.get('view') || 'builder';
    if (params.get('bg') !== 'none') document.documentElement.style.background = 'linear-gradient(160deg,#7d8a80 0%,#4a5650 45%,#252b28 100%)';
    const now = Math.floor(Date.now() / 1000);
    const day = 86400;

    const CATEGORIES = [
        { id: 'living', icon: 'sofa' }, { id: 'bedroom', icon: 'bed' }, { id: 'kitchen', icon: 'food' }, { id: 'bathroom', icon: 'drop' },
        { id: 'office', icon: 'laptop' }, { id: 'storage', icon: 'locker' }, { id: 'lighting', icon: 'bulb' }, { id: 'electronics', icon: 'tv' },
        { id: 'decor', icon: 'plant' }, { id: 'gym', icon: 'dumbbell' }, { id: 'outdoor', icon: 'sun' }, { id: 'garden', icon: 'tree' },
        { id: 'fences', icon: 'fence' }, { id: 'seasonal', icon: 'star' },
    ];
    const CATALOGUE = [
        ['sofa_l', 'Corner sofa', 'living', 2400, 'inside', 'sit'], ['armchair', 'Leather armchair', 'living', 900, 'inside', 'sit'], ['coffee', 'Oak coffee table', 'living', 450, 'inside'],
        ['bed_dbl', 'Double bed', 'bedroom', 1800, 'inside', 'lie'], ['wardrobe', 'Tall wardrobe', 'bedroom', 1200, 'inside', 'wardrobe'], ['fridge', 'Steel fridge', 'kitchen', 1500, 'inside', 'fridge', 30],
        ['stove', 'Gas stove', 'kitchen', 1100, 'inside'], ['bath', 'Clawfoot bath', 'bathroom', 2200, 'inside'], ['desk', 'Office desk', 'office', 800, 'inside'],
        ['crate', 'Storage crate', 'storage', 350, 'both', 'storage', 20], ['safe', 'Wall safe', 'storage', 6000, 'inside', 'safe', 10], ['lamp', 'Floor lamp', 'lighting', 220, 'inside', 'light'],
        ['tv', 'Flat TV 65"', 'electronics', 3200, 'inside', 'tv'], ['speaker', 'Hi-fi speaker', 'electronics', 1400, 'both', 'music'], ['plant', 'Potted palm', 'decor', 160, 'both'],
        ['bench', 'Weight bench', 'gym', 700, 'both'], ['bbq', 'Gas barbecue', 'outdoor', 1300, 'yard'], ['lounger', 'Sun lounger', 'outdoor', 380, 'yard', 'lie'],
        ['hedge', 'Box hedge', 'garden', 120, 'yard'], ['fence', 'Picket fence', 'fences', 90, 'yard'], ['tree', 'Christmas tree', 'seasonal', 600, 'both'], ['pumpkins', 'Pumpkin stack', 'seasonal', 250, 'both'], ['gravestone', 'Gravestone', 'seasonal', 220, 'yard'],
    ].map((r) => ({ id: r[0], label: r[1], model: `prop_${r[0]}_01`, category: r[2], price: r[3], where: r[4], use: r[5] || null, slots: r[6] || 0, weight: (r[6] || 0) * 5000, hidden: false, job: r[0] === 'safe' ? '' : '', custom: false, season: r[0] === 'tree' ? 'winter' : (r[0] === 'pumpkins' || r[0] === 'gravestone' ? 'halloween' : undefined), offSeason: r[0] === 'tree' }));

    const SHELLS = [
        { model: 'shell_v16low', label: 'Low-end flat', pack: 'K4MB1 starter', free: true, facesOut: true }, { model: 'shell_v16mid', label: 'Mid flat', pack: 'K4MB1 starter', free: true, facesOut: true },
        { model: 'shell_trevor', label: 'Trailer', pack: 'K4MB1 starter', free: true }, { model: 'shell_michael', label: 'Family house', pack: 'K4MB1 starter', free: true },
        { model: 'shell_highend', label: 'High-end house', pack: 'K4MB1 deluxe', free: false }, { model: 'shell_garagem', label: 'Medium garage', pack: 'K4MB1 garages', free: false },
        { model: 'shell_office1', label: 'Small office', pack: 'K4MB1 offices', free: false }, { model: 'shell_ranch', label: 'Ranch house', pack: 'K4MB1 deluxe', free: false },
    ];
    const IPLS = [
        { id: 'eclipse_modern', label: 'Eclipse Towers, Modern', kind: 'apartment', styles: [{ id: 'modern', label: 'Modern' }, { id: 'moody', label: 'Moody' }, { id: 'vibrant', label: 'Vibrant' }], needs: 'bob74_ipl' },
        { id: 'richard_majestic', label: 'Richard Majestic', kind: 'apartment', styles: [] }, { id: 'low_end', label: 'Low-end apartment', kind: 'apartment', styles: [] },
        { id: 'exec_office', label: 'Executive office', kind: 'office', styles: [{ id: 'warm', label: 'Old Spice Warm' }, { id: 'cool', label: 'Executive Cool' }, { id: 'contrast', label: 'Power Broker' }], needs: 'bob74_ipl' },
        { id: 'franklin', label: 'Franklin’s house', kind: 'house', styles: [], unverified: true }, { id: 'garage_10', label: '10-car garage', kind: 'garage', styles: [], build: 2060 },
    ];

    const mk = (id, type, label, extra) => Object.assign({
        type, label, address: { street: 'Mirror Park Blvd', number: String(id + 10), zone: 'MIRR', area: 'Mirror Park' }, tags: [], description: '', photo: '', enabled: true, listed: true,
        group: { kind: 'none', name: '', access: false, grade: 0 }, maxCoOwners: 3, building: 0, unit: '', floor: 0,
        door: { x: 1100 + id * 12, y: -420 - id * 4, z: 66.5, w: 90 }, enterMode: 'both', extraDoors: [],
        interior: { kind: 'shell', shell: 'shell_michael', ipl: '', exit: null, styles: [], defaultStyle: '' }, doors: [], area: { poly: [] },
        yard: { enabled: true, shape: 'hexagon', size: 14, heading: 20, center: { x: 1100 + id * 12, y: -428 - id * 4, z: 66.5 }, poly: [], limit: 0, categories: [] },
        garage: { enabled: true, spots: [{ x: 1104 + id * 12, y: -410, z: 66.4, w: 0 }], max: 2, shared: true, label: '' },
        points: { storage: [{ x: 1.2, y: 2.4, z: 0.5 }], safe: [], wardrobe: [{ x: -2, y: 3, z: 0.5 }], panel: [{ x: 0.4, y: -1, z: 1.4 }], bed: [], cameras: [], mailbox: [], sign: [] },
        money: { buy: true, price: 285000, rent: true, rentPrice: 2850, rentDays: 0, mortgage: true, minDepositPct: 0, interestPct: -1, sellBackPct: -1, commissionPct: -1, renterDeposit: -1 },
        security: { lockLevel: 1, maxLevel: 3, alarm: true, cameras: true, breakIns: true, raids: true, cooldown: 0, stealPct: 100 },
        furniture: { limit: 0, categories: [], allowed: true }, blip: { show: true, sprite: 0, colour: -1, label: '' }, storage: { slots: 0, weight: 0 }, markers: false, notes: '',
    }, extra || {});

    const PROPS = [
        { id: 1, data: mk(1, 'house', 'Mirror Park 11', { tags: ['family'], description: 'A bright corner house by the lake with a big back garden and room for two cars.' }), owner: { citizenid: 'XYR10001', name: 'Vincent Valentine', kind: 'mortgage', since: now - 9 * day, next_due: now + 2 * day, amount: 31500, balance: 189000, missed: 0, paid: 94500, locked: true }, keys: [{ citizenid: 'XYR10002', name: 'Isabel Ferreira', role: 'coowner' }], furniture: 24, created: now - 20 * day },
        { id: 2, data: mk(2, 'house', 'Mirror Park 12', { yard: { enabled: true, shape: 'square', size: 12, heading: 0, center: { x: 1124, y: -436, z: 66.5 }, poly: [], limit: 0, categories: [] } }), owner: null, keys: [], furniture: 0, created: now - 18 * day },
        { id: 3, data: mk(3, 'mlo', 'Vinewood Hills Villa', { address: { street: 'Didion Dr', number: '3', zone: 'CHIL', area: 'Vinewood Hills' }, interior: { kind: 'mlo', shell: '', ipl: '', exit: null, styles: [] }, doors: [{ x: 1, y: 2, z: 3, w: 0, id: '41', label: 'Front' }], area: { poly: [] }, money: Object.assign(mk(0, 'h', '').money, { price: 1450000, rentPrice: 14500 }) }), owner: { citizenid: 'XYR10009', name: 'Byron Whitfield', kind: 'owned', since: now - 40 * day, paid: 1450000, locked: false }, keys: [], furniture: 61, created: now - 50 * day },
        { id: 4, data: mk(4, 'building', 'Eclipse Towers', { address: { street: 'Eclipse Blvd', number: '', zone: 'WVINE', area: 'West Vinewood' }, tags: ['starter'], interior: { kind: 'none' }, yard: { enabled: false, shape: 'square', size: 10, heading: 0, center: null, poly: [] }, garage: { enabled: false, spots: [] } }), owner: null, keys: [], created: now - 30 * day },
        { id: 5, data: mk(5, 'unit', 'Eclipse Towers 1', { building: 4, unit: '1', floor: 1, door: null, interior: { kind: 'ipl', ipl: 'eclipse_modern', styles: [], defaultStyle: 'modern' }, yard: { enabled: false, shape: 'square', size: 10, heading: 0, center: null, poly: [] }, garage: { enabled: false, spots: [] }, money: Object.assign(mk(0, 'h', '').money, { price: 420000, rentPrice: 4200 }) }), owner: { citizenid: 'XYR10003', name: 'Terrence Obi', kind: 'rented', since: now - 5 * day, next_due: now - day, amount: 4200, missed: 1, paid: 8400, locked: true }, keys: [], furniture: 9, created: now - 30 * day },
        { id: 6, data: mk(6, 'unit', 'Eclipse Towers 2', { building: 4, unit: '2', floor: 1, door: null, interior: { kind: 'ipl', ipl: 'eclipse_modern' }, yard: { enabled: false, shape: 'square', size: 10, heading: 0, center: null, poly: [] }, garage: { enabled: false, spots: [] } }), owner: { citizenid: 'XYR10004', name: 'Nadia Kowalski', kind: 'starter', since: now - 2 * day, locked: true }, keys: [], created: now - 30 * day },
        { id: 7, data: mk(7, 'office', 'Arcadius Suite 4', { address: { street: 'Power St', number: '4', zone: 'DOWNT', area: 'Downtown' }, interior: { kind: 'ipl', ipl: 'exec_office' }, group: { kind: 'job', name: 'realestate', access: true, grade: 0 }, yard: { enabled: false, shape: 'square', size: 10, heading: 0, center: null, poly: [] }, garage: { enabled: false, spots: [] }, money: Object.assign(mk(0, 'h', '').money, { price: 950000, rent: false, mortgage: true }) }), owner: null, keys: [], created: now - 7 * day },
        { id: 8, data: mk(8, 'motel', 'Pink Cage 3', { door: null, enabled: false, interior: { kind: 'shell', shell: '' }, money: Object.assign(mk(0, 'h', '').money, { buy: false, mortgage: false, rentPrice: 350 }), yard: { enabled: false, shape: 'square', size: 10, heading: 0, center: null, poly: [] }, garage: { enabled: true, spots: [] } }), owner: null, keys: [], created: now - day },
    ];

    const SETTINGS = {
        sections: [
            { id: 'ownership', icon: 'key', fields: [{ key: 'Ownership.maxProperties', type: 'int', min: 1, max: 50 }, { key: 'Ownership.sellBackPct', type: 'pct' }, { key: 'Starter.enabled', type: 'bool' }, { key: 'Starter.onFirstSpawn', type: 'bool', needs: 'Starter.enabled' }] },
            { id: 'buying', icon: 'cash', fields: [{ key: 'Buying.selfServe', type: 'select', options: ['always', 'no_agents', 'never'] }, { key: 'Buying.taxPct', type: 'pct' }, { key: 'Buying.tours', type: 'bool' }, { key: 'Buying.tourMinutes', type: 'int', min: 1, max: 30, unit: 'min', needs: 'Buying.tours' }, { key: 'OpenHouse.enabled', type: 'bool' }, { key: 'OpenHouse.minutes', type: 'int', min: 5, max: 120, unit: 'min', needs: 'OpenHouse.enabled' }, { key: 'OpenHouse.blip', type: 'bool', needs: 'OpenHouse.enabled' }] },
            { id: 'furniture', icon: 'sofa', fields: [{ key: 'Furniture.enabled', type: 'bool' }, { key: 'Fridge.keepsFresh', type: 'int', min: 1, max: 20, unit: 'x', needs: 'Furniture.enabled' }, { key: 'Seasons.active', type: 'select', options: ['auto', 'none', 'halloween', 'winter', 'july4'], needs: 'Furniture.enabled' }, { key: 'Seasons.hideOffSeason', type: 'bool', needs: 'Furniture.enabled' }] },
            { id: 'breakins', icon: 'crowbar', fields: [{ key: 'BreakIns.enabled', type: 'bool' }, { key: 'BreakIns.evidence', type: 'bool', needs: 'BreakIns.enabled' }, { key: 'BreakIns.brokenLock', type: 'bool', needs: 'BreakIns.enabled' }, { key: 'BreakIns.repairPrice', type: 'int', min: 0, max: 1000000, step: 50, unit: '$', needs: 'BreakIns.brokenLock' }] },
            { id: 'rent', icon: 'clock', fields: [{ key: 'Rent.enabled', type: 'bool' }, { key: 'Rent.periodDays', type: 'num', min: 0.5, max: 60, step: 0.5, unit: 'days', needs: 'Rent.enabled' }, { key: 'Rent.evictAfter', type: 'int', min: 1, max: 20, needs: 'Rent.enabled' }] },
        ],
        values: { 'Ownership.maxProperties': 3, 'Ownership.sellBackPct': 70, 'Starter.enabled': true, 'Starter.onFirstSpawn': true, 'Buying.selfServe': 'no_agents', 'Buying.taxPct': 0, 'Buying.tours': true, 'Buying.tourMinutes': 3, 'Rent.enabled': true, 'Rent.periodDays': 7, 'Rent.evictAfter': 2, 'OpenHouse.enabled': true, 'OpenHouse.minutes': 15, 'OpenHouse.blip': true, 'Furniture.enabled': true, 'Fridge.keepsFresh': 4, 'Seasons.active': 'auto', 'Seasons.hideOffSeason': true, 'BreakIns.enabled': true, 'BreakIns.evidence': true, 'BreakIns.brokenLock': true, 'BreakIns.repairPrice': 750 },
        defaults: { 'Ownership.maxProperties': 3, 'Ownership.sellBackPct': 70, 'Starter.enabled': true, 'Starter.onFirstSpawn': true, 'Buying.selfServe': 'no_agents', 'Buying.taxPct': 0, 'Buying.tours': true, 'Buying.tourMinutes': 3, 'Rent.enabled': true, 'Rent.periodDays': 7, 'Rent.evictAfter': 2, 'OpenHouse.enabled': true, 'OpenHouse.minutes': 15, 'OpenHouse.blip': true, 'Furniture.enabled': true, 'Fridge.keepsFresh': 4, 'Seasons.active': 'auto', 'Seasons.hideOffSeason': true, 'BreakIns.enabled': true, 'BreakIns.evidence': true, 'BreakIns.brokenLock': true, 'BreakIns.repairPrice': 750 },
        boot: {},
    };

    function builderData() {
        return {
            properties: PROPS.map((p) => Object.assign({}, p, { data: JSON.parse(JSON.stringify(p.data)) })),
            interiors: { shells: SHELLS, ipls: IPLS }, catalogue: CATALOGUE, categories: CATEGORIES, catalogueMultiplier: 1, catalogueOverrides: {}, catalogueCustom: [],
            seasons: [{ id: 'halloween', label: 'Halloween' }, { id: 'winter', label: 'Winter holidays' }, { id: 'july4', label: 'Fourth of July' }], season: 'halloween',
            settings: SETTINGS, jobs: [{ name: 'realestate', label: 'Real Estate' }, { name: 'police', label: 'Police' }], gangs: [{ name: 'ballas', label: 'Ballas' }],
            agency: { enabled: true, job: 'realestate', office: { x: -706.1, y: 268.9, z: 83.1 }, desk: null }, pending: [{ id: 2, price: 299000, rent: null, by: 'Priya Chandran', at: now - 3600 }],
            problems: { 8: [{ key: 'no_door', level: 'bad' }] },
            stats: { owned: 2, sale: 3, rented: 1, mortgage: 1, starter: 1, disabled: 1, buildings: 1, units: 2, weekIncome: 184300, weekSales: 3, furniture: 94 },
            rights: { prices: true, delete: true, evict: true, catalogue: true, import: true },
            system: { framework: 'qbx_core', target: 'ox_target', inventory: 'ox_inventory', doorlock: 'XS-DoorLock', garage: 'jg-advancedgarages', dispatch: 'ps-dispatch', banking: 'Renewed-Banking', phone: 'XS-Phone', mdt: true, bob74: true, screenshot: true },
            areaPrices: { MIRR: 285000, CHIL: 1400000, DOWNT: 650000, default: 150000 }, me: { name: 'XyraL' }, here: { x: 1100, y: -420, z: 66.5, w: 90, street: 'Mirror Park Blvd', zone: 'MIRR', area: 'Mirror Park' },
        };
    }

    const MUSIC = { music: 'https://cdn.example.com/music/late-night-drive.mp3', musicAt: Math.floor(Date.now() / 1000) - 83, musicPaused: false, musicPos: 0, musicVolume: 45 };
    const SONG_LENGTH = 214;
    const OPEN = { until: null };

    function panelData() {
        return {
            property: { id: 1, type: 'house', label: 'Mirror Park 11', address: { street: 'Mirror Park Blvd', number: '11', area: 'Mirror Park' }, photo: '' },
            role: 'owner', rights: { lock: true, storage: true, furniture: true, keys: true, sell: true, bills: true, security: true, style: true, cameras: true, letin: true, panel: true },
            owner: { name: 'Vincent Valentine', kind: 'mortgage', since: now - 9 * day, me: true },
            statement: { kind: 'mortgage', amount: 31500, next_due: now + 2 * day + 7200, balance: 189000, payments_left: 6, missed: 1, arrears: 31500, owed: 300, bills: { tax: now + 4 * day, utilities: now + day }, insured: true, rentDays: 7, mortgageDays: 7, autoPay: true, payOff: true, evictAfter: 2, missedLimit: 3, sellValue: 10500, utilitiesOff: false },
            keys: [{ citizenid: 'XYR10002', name: 'Isabel Ferreira', role: 'coowner', online: true }, { citizenid: 'XYR10005', name: 'Junko Ito', role: 'guest', expires: now + 5 * 3600, online: false }],
            maxKeys: 6, guestHours: [1, 6, 24, 72], changeLocksPrice: 500,
            security: { forced: Math.floor(Date.now() / 1000) - 1500, repairPrice: 750, lock: 2, maxLock: 3, locks: [{ label: 'Standard lock', price: 0 }, { label: 'Deadbolt', price: 4000 }, { label: 'Reinforced door', price: 12000 }], alarm: 1, alarms: [{ label: 'Alarm', price: 5000 }, { label: 'Monitored alarm', price: 15000 }], alarmAllowed: true, armed: true, cameras: [{ label: 'Driveway' }], cameraPrice: 2500, maxCameras: 4, camerasAllowed: true, builtinCameras: [{ label: 'Front porch' }], lastBreakIn: now - 3 * day },
            visitors: [{ name: 'Priya Chandran', at: now - 600, knock: false }, { name: 'Hollis Barnes', at: now - 7200, knock: true }],
            prefs: Object.assign({ doorbell: true, lights: 'on', houseName: 'The Lake House' }, MUSIC), locked: true, time: Math.floor(Date.now() / 1000),
            styles: [{ id: 'modern', label: 'Modern' }, { id: 'moody', label: 'Moody' }, { id: 'vibrant', label: 'Vibrant' }], style: 'modern', styleCost: 2500,
            storage: { level: 1, slots: 60, weight: 300000, nextUp: { slots: 80, weight: 450000, price: 15000 }, points: 1, safes: 1 },
            furniture: { count: 24, limit: 150, yard: true }, tiles: { lock: true, lights: true, music: true, cameras: true, keys: true, bills: true, visitors: true, furniture: true, security: true, style: true, storage: true, settings: true },
            openHouse: OPEN.until, canOpenHouse: true, openHouseMinutes: 15,
            insurance: { price: 500, payout: 5000, days: 7 }, rentEnabled: true, sellBackPct: 70, inside: true, open: null,
            hour: 20, minute: 42, nearby: [{ id: 14, name: 'Rafael Duarte' }, { id: 22, name: 'Wesley Grant' }],
        };
    }

    function listingData() {
        const p = PROPS[1];
        return {
            property: Object.assign({ id: 2, forSale: true, status: 'sale', security: { lockLevel: 1 }, points: p.data.points, price: 285000, rentPrice: 2850 }, p.data, { tags: ['lake view', 'garden'], photo: '' }),
            description: 'A tidy two-bed by the Mirror Park lake. New kitchen, big hexagon garden, a driveway for two and a quiet street.',
            quotes: { buy: { mode: 'buy', price: 285000, tax: 0, total: 285000 }, rent: { mode: 'rent', rent: 2850, deposit: 2850, total: 5700, days: 7 }, mortgage: { mode: 'mortgage', price: 285000, tax: 0, depositPct: 20, minDepositPct: 20, deposit: 57000, owed: 246240, term: 8, terms: [8, 16, 24], each: 30780, interest: 8, days: 7, total: 57000 } },
            selfServe: true, agentsOnDuty: 0, canOwnMore: true, tours: true, tourMinutes: 3, role: null, owned: false, money: { cash: 1200, bank: 312000 }, taxPct: 0,
            offer: params.get('offer') ? { offer: 1, agent: 'Priya Chandran', mode: 'mortgage', quote: { mode: 'mortgage', price: 285000, tax: 0, depositPct: 25, deposit: 71250, term: 16, each: 14400, interest: 8, days: 7, total: 71250 } } : null,
        };
    }

    function catalogueData() {
        return { id: 1, label: 'Mirror Park 11', items: CATALOGUE, categories: CATEGORIES, where: params.get('where') || 'inside', canInside: true, canYard: true, placed: [{ id: 41, item: 'sofa_l', label: 'Corner sofa', place: 'inside', use: 'sit' }, { id: 40, item: 'tv', label: 'Flat TV 65"', place: 'inside', use: 'tv' }, { id: 39, item: 'bbq', label: 'Gas barbecue', place: 'yard' }], money: { cash: 800, bank: 18400 } };
    }

    function agencyData() {
        return {
            list: PROPS.filter((p) => p.data.type !== 'building').map((p) => ({ id: p.id, label: p.data.label, type: p.data.type, address: p.data.address, status: p.owner ? (p.owner.kind === 'owned' ? 'owned' : p.owner.kind) : 'sale', listed: p.data.listed, price: p.data.money.price, basePrice: p.data.money.price, rentPrice: p.data.money.rentPrice, canBuy: p.data.money.buy, canRent: p.data.money.rent, canMortgage: p.data.money.mortgage, owner: p.owner ? { name: p.owner.name, kind: p.owner.kind, since: p.owner.since, missed: p.owner.missed || 0 } : null, photo: '', enabled: p.data.enabled, openHouse: p.id === 2 ? Math.floor(Date.now() / 1000) + 9 * 60 : null, canOpenHouse: !p.owner })),
            now: Math.floor(Date.now() / 1000), openHouseMinutes: 15,
            rights: { list: true, sell: true, rent: true, price: true, evict: true }, job: { name: 'realestate', label: 'Real Estate', gradeLabel: 'Broker' }, commissionPct: 5, rangePct: 20, approval: false,
            sales: [{ property_id: 1, kind: 'agent_sale', amount: 14250, at: now - 2 * day, detail: 'Vincent Valentine, mortgage' }, { property_id: 5, kind: 'agent_sale', amount: 210, at: now - 4 * day, detail: 'Terrence Obi, rent' }],
            pending: [], nearby: [{ id: 14, name: 'Rafael Duarte' }],
        };
    }

    const reply = (data) => ({ ok: true, data });
    const RPC = {
        'b:here': () => reply(builderData().here), 'b:refresh': () => reply(builderData()), 'b:players': () => reply([{ citizenid: 'XYR10007', name: 'Rafael Duarte', online: true }, { citizenid: 'XYR10008', name: 'Delia Moss', online: false }]),
        'b:logs': () => reply([{ id: 3, property_id: 1, kind: 'mortgage', name: 'Vincent Valentine', citizenid: 'XYR10001', detail: '8 payments', amount: 57000, at: now - 9 * day }, { id: 4, property_id: 5, kind: 'breakin', name: 'Unknown', detail: 'Lockpicked the door', amount: 0, at: now - 3 * day }, { id: 5, property_id: 1, kind: 'key_give', name: 'Vincent Valentine', detail: 'Isabel Ferreira (coowner)', amount: 0, at: now - 8 * day }]),
        'b:import': (p) => reply({ total: 42, owned: 17, keys: 9, noDoor: 2, made: p.commit ? 40 : undefined }), 'b:problems': () => reply({}),
        'b:save': (p) => reply({ id: p.id || 99, data: p.data, owner: null, keys: [], created: now }),
        'panel:nearby': () => reply(panelData().nearby),
        'panel:openHouse': (p) => { OPEN.until = p.on ? Math.floor(Date.now() / 1000) + 15 * 60 : null; send('panel', 'update', panelData()); return reply(true); },
        'panel:repairLock': () => reply(true),
        'panel:pref': (p) => {
            const at = Math.floor(Date.now() / 1000);
            if (p.music !== undefined) Object.assign(MUSIC, { music: p.music, musicAt: at, musicPaused: false, musicPos: 0 });
            if (p.musicVolume !== undefined) MUSIC.musicVolume = p.musicVolume;
            if (p.musicPaused === true && !MUSIC.musicPaused) Object.assign(MUSIC, { musicPaused: true, musicPos: at - MUSIC.musicAt });
            if (p.musicPaused === false && MUSIC.musicPaused) Object.assign(MUSIC, { musicPaused: false, musicAt: at - MUSIC.musicPos });
            if (p.musicSeek !== undefined) { if (MUSIC.musicPaused) MUSIC.musicPos = p.musicSeek; else MUSIC.musicAt = at - p.musicSeek; }
            send('panel', 'update', panelData());
            return reply(true);
        }, 'listing:quote': (p) => reply(Object.assign({}, listingData().quotes[p.mode], p.mode === 'mortgage' ? { depositPct: p.opts.depositPct || 20, term: p.opts.term || 8 } : {})),
        'agency:refresh': () => reply(agencyData()),
    };

    XS.post = async (endpoint, payload) => {
        if (endpoint === 'close') { send(payload.app, 'close', {}); return { ok: true }; }
        if (endpoint !== 'rpc') return { ok: true };
        const fn = RPC[payload.name];
        await new Promise((r) => setTimeout(r, 60));
        return fn ? fn(payload.payload || {}) : { ok: true, data: null };
    };

    if (XS.apps.sound) {
        const realStatus = XS.apps.sound.status;
        XS.apps.sound.status = (name) => {
            if (name !== 'home_1' || !MUSIC.music) return realStatus(name);
            const at = Date.now() / 1000;
            const time = MUSIC.musicPaused ? MUSIC.musicPos : at - MUSIC.musicAt;
            return { url: MUSIC.music, title: 'Late Night Drive', time, duration: SONG_LENGTH, paused: MUSIC.musicPaused, ready: true };
        };
    }

    window.addEventListener('load', () => {
        send('core', 'boot', { locale: window.XSH_LOCALE || {}, config: {} });
        if (view === 'builder') {
            send('builder', 'open', builderData());
            const page = params.get('page');
            const edit = params.get('edit');
            setTimeout(() => {
                if (edit) {
                    const row = document.querySelector(`[data-act="nav"][data-page="places"]`);
                    if (row) row.click();
                    setTimeout(() => {
                        const r = document.querySelector(`tr[data-act="edit"][data-id="${edit}"]`);
                        if (r) r.click();
                        const tab = params.get('tab');
                        if (tab) setTimeout(() => { const b = document.querySelector(`[data-act="tab"][data-tab="${tab}"]`); if (b) b.click(); }, 60);
                    }, 60);
                } else if (page) {
                    const b = document.querySelector(`[data-act="nav"][data-page="${page}"]`);
                    if (b) b.click();
                }
            }, 80);
        }
        if (view === 'panel') {
            send('panel', 'open', panelData());
            const page = params.get('page');
            if (page) setTimeout(() => { const b = document.querySelector(`#xsh-panel [data-page="${page}"]`); if (b) b.click(); }, 80);
        }
        if (view === 'listing') send('listing', 'open', listingData());
        if (view === 'catalogue') send('catalogue', 'open', catalogueData());
        if (view === 'agency') send('agency', 'open', agencyData());
    });
})();
