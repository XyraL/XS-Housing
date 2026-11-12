(() => {
    const root = document.getElementById('xsp-builder');
    const t = XS.t;
    const esc = XS.esc;
    const I = (name, size) => XS.icon(name, size || 16);
    const copy = (v) => JSON.parse(JSON.stringify(v === undefined ? null : v));
    const money = (n) => XS.money(n);
    const num = (v, d) => (Number.isFinite(Number(v)) ? Number(v) : d);
    const fx = (n) => (Number(n) || 0).toFixed(1);

    const TYPES = [
        { id: 'house', icon: 'home' }, { id: 'mlo', icon: 'door' }, { id: 'building', icon: 'apartment' }, { id: 'unit', icon: 'key' },
        { id: 'office', icon: 'office' }, { id: 'motel', icon: 'motel' }, { id: 'garage', icon: 'garage' },
    ];
    const TYPE_LABEL = { house: 'House', mlo: 'MLO house', building: 'Apartment building', unit: 'Apartment', office: 'Office', motel: 'Motel room', garage: 'Garage' };
    const STATUS = { sale: 'For sale', owned: 'Owned', rented: 'Rented', mortgage: 'Mortgage', starter: 'Starter' };
    const TABS = {
        default: ['general', 'entrance', 'interior', 'yard', 'garage', 'points', 'money', 'security', 'people'],
        building: ['general', 'entrance', 'units', 'security'],
        unit: ['general', 'interior', 'points', 'money', 'security', 'people'],
        mlo: ['general', 'entrance', 'interior', 'yard', 'garage', 'points', 'money', 'security', 'people'],
    };
    const TAB_LABEL = { general: 'General', entrance: 'Entrance', interior: 'Interior', yard: 'Yard', garage: 'Garage', points: 'Points', money: 'Money', security: 'Security', people: 'People', units: 'Units' };
    const TAB_ICON = { general: 'info', entrance: 'door', interior: 'home', yard: 'tree', garage: 'garage', points: 'pin', money: 'cash', security: 'shield', people: 'people', units: 'apartment' };
    const POINTS = [
        { key: 'storage', label: 'Storage', icon: 'box', inside: true, hint: 'Where owners open their storage.' },
        { key: 'safe', label: 'Safe', icon: 'safe', inside: true, hint: 'A smaller storage burglars cannot open.' },
        { key: 'wardrobe', label: 'Wardrobe', icon: 'shirt', inside: true, hint: 'Saved outfits from the clothing script.' },
        { key: 'panel', label: 'Smart-home panel', icon: 'grid', inside: true, hint: 'The wall screen owners use to run the place.' },
        { key: 'bed', label: 'Bed', icon: 'bed', inside: true, hint: 'Sleep here to log out safely.' },
        { key: 'cameras', label: 'Built-in cameras', icon: 'camera', inside: false, hint: 'Cameras every owner gets for free.' },
        { key: 'mailbox', label: 'Mailbox', icon: 'paper', inside: false, hint: 'A letterbox prop by the door.' },
        { key: 'sign', label: 'For Sale sign', icon: 'sign', inside: false, hint: 'Where the sign stands while it is for sale. Left empty, it stands next to the door.' },
    ];
    const SHAPES = ['square', 'hexagon', 'circle', 'custom'];
    const SHAPE_ICON = { square: 'square', hexagon: 'hexagon', circle: 'circle', custom: 'polygon' };
    const LOG_KINDS = ['all', 'sales', 'rent', 'keys', 'breakins', 'raids', 'admin'];

    const S = {
        open: false, page: 'overview', props: [], interiors: { shells: [], ipls: [] }, catalogue: [], categories: [], stats: {}, problems: {}, system: {},
        rights: {}, jobs: [], gangs: [], agency: {}, pending: [], areaPrices: {}, here: null, me: {}, cur: null, curId: null, tab: 'general', dirty: false,
        q: '', fType: 'all', fStatus: 'all', sel: new Set(), overlay: null, logs: [], logKind: 'all', logQ: '', catDraft: null, catQ: '', catCat: 'all',
        intTab: 'shells', intQ: '', intHave: true, have: null, busy: false, imp: {}, shellQ: '', iplQ: '', keyQ: '', keyHits: [], ownerQ: '', ownerHits: [], photo: null, unitForm: null, exportText: '',
        pics: {}, picKeys: new Set(), picErr: {}, picQ: [], picBusy: false,
    };

    const byId = (id) => S.props.find((p) => String(p.id) === String(id));
    const pageEl = () => root.querySelector('#bx-page');
    const typeName = (k) => t(`hb_type_${k}`, null, TYPE_LABEL[k] || k);
    const statusName = (k) => t(`hb_status_${k}`, null, STATUS[k] || k);
    const statusOf = (p) => (p.owner ? (p.owner.kind === 'owned' ? 'owned' : p.owner.kind) : 'sale');
    const shellOf = (model) => S.interiors.shells.find((s) => s.model === model);
    const installed = (model) => (S.have && model && Object.prototype.hasOwnProperty.call(S.have, model) ? S.have[model] : null);
    const haveCount = () => (S.have ? S.interiors.shells.filter((s) => S.have[s.model]).length : null);
    const byInstalled = (list) => (S.have ? list.slice().sort((a, b) => (S.have[b.model] ? 1 : 0) - (S.have[a.model] ? 1 : 0)) : list);
    const packLine = (s) => `${s.pack}${S.have && s.free ? ` · ${t('hb_free', null, 'free')}` : ''}`;
    function shellChip(s) {
        const have = installed(s.model);
        if (have === null) return `<span class="bx-chip ${s.free ? 'ok' : 'off'}">${esc(s.free ? t('hb_free', null, 'free') : t('hb_paid', null, 'paid'))}</span>`;
        return have ? `<span class="bx-chip ok">${esc(t('hb_installed', null, 'Installed'))}</span>` : `<span class="bx-chip off">${esc(t('hb_not_installed', null, 'Not installed'))}</span>`;
    }
    function noShells() {
        if (haveCount() !== 0) return '';
        return `<div class="bx-issue bad hb-noshells"><i>${I('alert', 13)}</i><div><b>${esc(t('hb_no_shells', null, 'Your game cannot see any shells'))}</b><span>${esc(t('hb_no_shells_sub', null, 'Start your shell pack in server.cfg, restart the server and rejoin. /housediag shows what your game can see.'))}</span></div></div>`;
    }
    const iplOf = (id) => S.interiors.ipls.find((i) => i.id === id);
    const pt = (p) => (p ? `${fx(p.x)}, ${fx(p.y)}, ${fx(p.z)}` : '—');

    function setPath(obj, path, value) {
        const parts = path.split('.');
        let node = obj;
        for (let i = 0; i < parts.length - 1; i++) {
            if (node[parts[i]] === undefined || node[parts[i]] === null || typeof node[parts[i]] !== 'object') node[parts[i]] = {};
            node = node[parts[i]];
        }
        node[parts[parts.length - 1]] = value;
    }

    function getPath(obj, path) {
        return path.split('.').reduce((n, k) => (n === undefined || n === null ? undefined : n[k]), obj);
    }

    function shape(kind, center, size, heading) {
        if (!center) return [];
        const sides = kind === 'hexagon' ? 6 : (kind === 'circle' ? 16 : 4);
        let radius = (Number(size) || 10) / 2;
        if (kind === 'square') radius *= Math.SQRT2;
        const start = ((Number(heading) || 0) + (kind === 'square' ? 45 : 0)) * Math.PI / 180;
        const out = [];
        for (let i = 0; i < sides; i++) {
            const a = start + (i / sides) * Math.PI * 2;
            out.push({ x: +(center.x + Math.cos(a) * radius).toFixed(2), y: +(center.y + Math.sin(a) * radius).toFixed(2) });
        }
        return out;
    }

    function blank(type) {
        const here = S.here || {};
        const prices = S.areaPrices || {};
        const price = prices[here.zone] || prices.default || 150000;
        return {
            type, label: '', address: { street: here.street || '', number: '', zone: here.zone || '', area: here.area || '' }, tags: [], description: '', photo: '',
            enabled: true, listed: true, group: { kind: 'none', name: '', access: false, grade: 0 }, maxCoOwners: 3, building: 0, unit: '', floor: 0,
            door: null, enterMode: 'both', extraDoors: [],
            interior: { kind: type === 'mlo' ? 'mlo' : (type === 'building' ? 'none' : 'shell'), shell: (S.interiors.shells[0] || {}).model || '', ipl: '', exit: null, styles: [], defaultStyle: '' },
            doors: [], area: { poly: [], minZ: null, maxZ: null },
            yard: { enabled: false, shape: 'square', size: 12, heading: 0, center: null, poly: [], limit: 0, categories: [] },
            garage: { enabled: false, spots: [], max: 2, shared: true, label: '' },
            points: { storage: [], safe: [], wardrobe: [], panel: [], bed: [], cameras: [], mailbox: [], sign: [] },
            money: { buy: type !== 'motel', price: type === 'motel' ? 0 : price, rent: true, rentPrice: Math.max(150, Math.floor(price / 100)), rentDays: 0, mortgage: type !== 'motel', minDepositPct: 0, interestPct: -1, sellBackPct: -1, commissionPct: -1, renterDeposit: -1 },
            security: { lockLevel: 1, maxLevel: 3, alarm: true, cameras: true, breakIns: true, raids: true, cooldown: 0, stealPct: 100 },
            furniture: { limit: 0, categories: [], allowed: true },
            blip: { show: true, sprite: 0, colour: -1, label: '' }, storage: { slots: 0, weight: 0 }, markers: false, notes: '',
        };
    }

    function normalise(d) {
        const b = blank(d.type || 'house');
        const out = Object.assign(b, d);
        ['address', 'group', 'interior', 'area', 'yard', 'garage', 'points', 'money', 'security', 'furniture', 'blip', 'storage'].forEach((k) => { out[k] = Object.assign(b[k] || {}, d[k] || {}); });
        out.tags = XS.list(out.tags);
        out.extraDoors = XS.list(out.extraDoors);
        out.doors = XS.list(out.doors);
        out.area.poly = XS.list(out.area.poly);
        out.yard.poly = XS.list(out.yard.poly);
        out.yard.categories = XS.list(out.yard.categories);
        out.garage.spots = XS.list(out.garage.spots);
        out.furniture.categories = XS.list(out.furniture.categories);
        out.interior.styles = XS.list(out.interior.styles);
        POINTS.forEach((p) => { out.points[p.key] = XS.list(out.points[p.key]); });
        return out;
    }

    function issues(d, id) {
        const list = [];
        const add = (level, text, tab) => list.push({ level, text, tab });
        if (d.type !== 'unit' && !d.door) add('bad', t('hb_iss_door', null, 'No front door placed yet'), 'entrance');
        if (d.type === 'unit' && !(Number(d.building) > 0)) add('bad', t('hb_iss_building', null, 'Not in a building yet'), 'general');
        if (d.type !== 'building') {
            const k = d.interior.kind;
            if (k === 'shell' && !d.interior.shell) add('bad', t('hb_iss_shell', null, 'No shell picked'), 'interior');
            if (k === 'shell' && d.interior.shell && installed(d.interior.shell) === false) add('bad', t('hb_iss_shell_missing', null, 'This shell is not on your server, so nobody can go inside'), 'interior');
            if (k === 'shell' && (shellOf(d.interior.shell) || {}).guess && !d.interior.exit) add('warn', t('hb_iss_door_guess', null, 'Place the inside door for this shell'), 'interior');
            if (k === 'ipl' && !iplOf(d.interior.ipl)) add('bad', t('hb_iss_ipl', null, 'No GTA interior picked'), 'interior');
            if (k === 'mlo' && !d.doors.length) add('warn', t('hb_iss_mlo_doors', null, 'No MLO doors picked, so it cannot lock'), 'interior');
            if (k === 'mlo' && d.area.poly.length < 3) add('warn', t('hb_iss_mlo_area', null, 'No inside area drawn for furniture'), 'interior');
            if (!d.money.buy && !d.money.rent) add('warn', t('hb_iss_unsold', null, 'Neither for sale nor for rent'), 'money');
            if (k !== 'none' && !d.points.storage.length) add('info', t('hb_iss_storage', null, 'No storage point'), 'points');
            if (k !== 'none' && !d.points.panel.length) add('info', t('hb_iss_panel', null, 'No smart-home panel point'), 'points');
        }
        if (d.yard.enabled && !d.yard.center && d.yard.poly.length < 3) add('bad', t('hb_iss_yard', null, 'Yard is on but has no shape'), 'yard');
        if (d.garage.enabled && !d.garage.spots.length) add('bad', t('hb_iss_garage', null, 'Garage is on but has no spot'), 'garage');
        (S.problems[String(id)] || []).forEach((pr) => {
            if (pr.key === 'door_overlap') add('warn', t('hb_iss_overlap', { id: (pr.vars || {}).id }, `Door overlaps place #${(pr.vars || {}).id}`), 'entrance');
        });
        return list;
    }

    function shell() {
        root.innerHTML = `
<div class="xsp-stage"><div class="bx bx-in">
  <div class="bx-lightbar"></div>
  <div class="bx-top">
    <div class="bx-logo"><svg class="bx-badge" viewBox="0 0 34 34"><defs><linearGradient id="hbG" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2dd4bf"/><stop offset="1" stop-color="#f5a524"/></linearGradient></defs><rect x="1" y="1" width="32" height="32" rx="9" fill="#0b1210" stroke="url(#hbG)" stroke-width="1.5"/><path d="M9 17l8-6.5 8 6.5" fill="none" stroke="url(#hbG)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M11 15.5V24h12v-8.5" fill="none" stroke="#e6ebf3" stroke-width="1.8" stroke-linejoin="round"/><path d="M15.5 24v-4h3v4" fill="none" stroke="#e6ebf3" stroke-width="1.6"/></svg>
      <div class="bx-word"><b>XS-<span>Housing</span></b><small>${esc(t('hb_builder', null, 'Housing builder'))}</small></div></div>
    <button class="bx-search" data-act="palette">${I('search', 15)}<span class="bx-stext">${esc(t('hb_search', null, 'Search places, settings and pages'))}</span><span class="bx-kbd">Ctrl</span><span class="bx-kbd">K</span></button>
    <span class="bx-sp"></span>
    <div class="bx-sys" id="bx-sys"></div>
    <button class="bx-iconbtn close" data-act="close" title="Esc">${I('close', 16)}</button>
  </div>
  <div class="bx-body">
    <nav class="bx-nav" id="bx-nav"></nav>
    <main class="bx-main"><div class="bx-page xsp-scroll" id="bx-page"></div></main>
  </div>
  <div id="bx-ov"></div>
</div></div>`;
    }

    function navItem(page, icon, label, count, warn, extra) {
        const on = S.page === page || (page === 'places' && S.page === 'edit');
        return `<button class="bx-navitem ${on ? 'on' : ''}" data-act="nav" data-page="${page}" ${extra || ''}>${I(icon, 17)}<span class="bx-navlabel">${esc(label)}</span>${count !== undefined && count !== null ? `<span class="bx-count ${warn ? 'warn' : ''}">${esc(count)}</span>` : ''}</button>`;
    }

    function renderNav() {
        const nav = root.querySelector('#bx-nav');
        if (!nav) return;
        const bad = Object.keys(S.problems).filter((k) => (S.problems[k] || []).some((p) => p.level === 'bad')).length;
        const changed = XS.BuilderSettings && XS.BuilderSettings.changedCount ? XS.BuilderSettings.changedCount() : 0;
        nav.innerHTML = `
<div class="bx-navgroup">${esc(t('hb_nav_build', null, 'Build'))}</div>
${navItem('overview', 'chart', t('hb_overview', null, 'Overview'))}
${navItem('places', 'home', t('hb_places', null, 'Places'), S.props.filter((p) => p.data.type !== 'building').length, bad > 0)}
${navItem('buildings', 'apartment', t('hb_buildings', null, 'Apartment buildings'), S.props.filter((p) => p.data.type === 'building').length)}
${navItem('quick', 'bolt', t('hb_quick', null, 'Quick place'))}
<div class="bx-navsep"></div>
<div class="bx-navgroup">${esc(t('hb_nav_library', null, 'Library'))}</div>
${navItem('interiors', 'warehouse', t('hb_interiors', null, 'Interiors'), S.interiors.shells.length + S.interiors.ipls.length)}
${navItem('furniture', 'sofa', t('hb_furniture', null, 'Furniture'), S.catalogue.length)}
<div class="bx-navsep"></div>
<div class="bx-navgroup">${esc(t('hb_nav_run', null, 'Run'))}</div>
${navItem('agency', 'tag', t('hb_agency', null, 'Real estate agency'), S.pending.length || null, S.pending.length > 0)}
${navItem('tools', 'gear', t('hb_tools', null, 'Tools'))}
${navItem('logs', 'list', t('hb_logs', null, 'Logs'))}
${navItem('settings', 'sliders', t('hb_settings', null, 'Settings'), changed || null)}
${navItem('access', 'shield', t('hb_access', null, 'Access'))}
<div class="bx-me"><div class="bx-avatar">${esc(((S.me && S.me.name) || 'A').slice(0, 1).toUpperCase())}</div><div style="min-width:0"><b>${esc((S.me && S.me.name) || '')}</b><small>${esc(t('hb_admin', null, 'Builder access'))}</small></div></div>`;
    }

    function renderSys() {
        const el = root.querySelector('#bx-sys');
        if (!el) return;
        const s = S.system || {};
        const pill = (on, label) => `<span class="bx-pill ${on ? '' : 'off'}"><i></i>${esc(label)}</span>`;
        const n = haveCount();
        el.innerHTML = `${n === null ? '' : pill(n > 0, n > 0 ? t('hb_n_shells', { n }, `${n} shells`) : t('hb_no_shells_pill', null, 'No shells'))}${pill(!!s.doorlock, s.doorlock || t('hb_builtin_doors', null, 'Built-in doors'))}${pill(!!s.garage, s.garage || t('hb_no_garage', null, 'No garage script'))}${pill(!!s.inventory, s.inventory || t('hb_no_inventory', null, 'No inventory'))}`;
    }

    function render() {
        renderNav();
        renderSys();
        const el = pageEl();
        if (!el) return;
        if (S.page !== 'settings' && XS.BuilderSettings) XS.BuilderSettings.unmount();
        const pages = { overview, places: () => placesPage(false), buildings: () => placesPage(true), edit: editor, quick: quickPage, interiors: interiorsPage, furniture: furniturePage, agency: agencyPage, tools: toolsPage, logs: logsPage, settings: settingsPage, access: accessPage };
        el.innerHTML = (pages[S.page] || overview)();
        if (S.page === 'settings') XS.BuilderSettings.mount(el.querySelector('#bx-setmount'), () => renderNav());
        renderOverlay();
    }

    function head(title, sub, actions, crumb) {
        return `${crumb ? `<div class="bx-crumb">${crumb}</div>` : ''}<div class="bx-pagehead"><div><h1>${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ''}</div><span class="bx-sp"></span>${actions || ''}</div>`;
    }

    function stat(cls, n, label, sub, icon, act) {
        return `<div class="bx-stat ${cls}" ${act || ''}>${I(icon, 18)}<b>${esc(n)}</b><span>${esc(label)}</span>${sub ? `<em>${esc(sub)}</em>` : ''}</div>`;
    }

    function overview() {
        const s = S.stats || {};
        const places = S.props.filter((p) => p.data.type !== 'building');
        const issueList = [];
        S.props.forEach((p) => issues(normalise(copy(p.data)), p.id).forEach((i) => issueList.push(Object.assign({ id: p.id, label: p.data.label }, i))));
        const ready = places.length ? Math.round((places.filter((p) => !issues(normalise(copy(p.data)), p.id).some((i) => i.level === 'bad')).length / places.length) * 100) : 0;
        const circ = 2 * Math.PI * 50;
        const sys = S.system || {};
        const sysRow = (label, value) => `<div class="bx-sysrow"><span>${esc(label)}</span><b class="${value ? '' : 'none'}">${esc(value || t('hb_none', null, 'none'))}</b></div>`;
        const order = { bad: 0, warn: 1, info: 2 };
        issueList.sort((a, b) => order[a.level] - order[b.level]);
        return `${head(t('hb_overview', null, 'Overview'), t('hb_overview_sub', null, 'Every house, apartment, office and MLO on the server, and what still needs doing.'), `<button class="bx-btn" data-act="quickgo">${I('bolt', 15)}${esc(t('hb_quick', null, 'Quick place'))}</button><button class="bx-btn primary" data-act="new" data-type="house">${I('plus', 15)}${esc(t('hb_new_place', null, 'New place'))}</button>`)}
<div class="bx-ov">
  <div class="bx-card"><div class="bx-ready">
    <div class="bx-ring"><svg width="118" height="118"><defs><linearGradient id="bxRingGrad"><stop offset="0" stop-color="#2dd4bf"/><stop offset="1" stop-color="#f5a524"/></linearGradient></defs><circle class="track" cx="59" cy="59" r="50"/><circle class="fill" cx="59" cy="59" r="50" stroke-dasharray="${circ}" stroke-dashoffset="${circ * (1 - ready / 100)}"/></svg><div><b>${ready}%</b><small>${esc(t('hb_ready', null, 'ready'))}</small></div></div>
    <div class="bx-readytext"><h2>${esc(places.length ? t('hb_ready_title', { n: places.length }, `${places.length} places`) : t('hb_ready_empty', null, 'Nothing built yet'))}</h2>
      <p>${esc(places.length ? t('hb_ready_sub', null, 'Fix the red ones first. Yellow and blue are worth a look.') : t('hb_ready_empty_sub', null, 'Start with a house, an MLO or an apartment building, or walk a street with Quick place.'))}</p>
      ${issueList.length ? `<div class="bx-issues">${issueList.slice(0, 40).map((i) => `<div class="bx-issue ${i.level}" data-act="edit" data-id="${i.id}" data-tab="${esc(i.tab)}" style="cursor:pointer"><i>${I(i.level === 'bad' ? 'alert' : 'info', 13)}</i><div><b>${esc(i.text)}</b><span>#${i.id} · ${esc(i.label)}</span></div>${I('chevron', 14)}</div>`).join('')}</div>` : (places.length ? `<div class="bx-allgood">${I('check', 16)}${esc(t('hb_all_good', null, 'Everything is set up.'))}</div>` : '')}
    </div></div></div>
  <div class="bx-stats">
    ${stat('green', s.owned || 0, t('hb_st_owned', null, 'Owned'), null, 'key', 'data-act="nav" data-page="places" data-status="owned"')}
    ${stat('', s.sale || 0, t('hb_st_sale', null, 'For sale'), null, 'sign', 'data-act="nav" data-page="places" data-status="sale"')}
    ${stat('amber', s.rented || 0, t('hb_st_rented', null, 'Rented'), null, 'clock', 'data-act="nav" data-page="places" data-status="rented"')}
    ${stat('amber', s.mortgage || 0, t('hb_st_mortgage', null, 'On a mortgage'), null, 'building', 'data-act="nav" data-page="places" data-status="mortgage"')}
    ${stat('', s.starter || 0, t('hb_st_starter', null, 'Starter apartments'), null, 'bed', 'data-act="nav" data-page="places" data-status="starter"')}
    ${stat('red', s.disabled || 0, t('hb_st_off', null, 'Switched off'), null, 'power', 'data-act="nav" data-page="places"')}
    ${stat('', `${s.buildings || 0} / ${s.units || 0}`, t('hb_st_buildings', null, 'Buildings / units'), null, 'apartment', 'data-act="nav" data-page="buildings"')}
    ${stat('green', money(s.weekIncome || 0), t('hb_st_income', null, 'Paid in, 7 days'), t('hb_st_sales', { n: s.weekSales || 0 }, `${s.weekSales || 0} sales`), 'cash', 'data-act="nav" data-page="logs"')}
    ${stat('', s.furniture || 0, t('hb_st_furniture', null, 'Furniture placed'), null, 'sofa', 'data-act="nav" data-page="furniture"')}
  </div>
</div>
<div class="bx-sec"><div class="bx-sectitle"><h2>${esc(t('hb_start', null, 'Start something'))}</h2></div>
  <div class="bx-quick">
    ${TYPES.filter((x) => x.id !== 'unit').slice(0, 4).map((x) => `<button class="bx-tpl" data-act="new" data-type="${x.id}"><span class="bx-kindico">${I(x.icon, 18)}</span><div><b>${esc(typeName(x.id))}</b><span>${esc(t(`hb_type_${x.id}_sub`, null, ({ house: 'A street house: a door, a yard and a shell or GTA interior.', mlo: 'A house built into the map. Pick its doors and draw its rooms.', building: 'One lobby door with as many apartments as you like.', office: 'A business space a job or crew can own.' })[x.id] || ''))}</span></div></button>`).join('')}
  </div></div>
<div class="bx-sec"><div class="bx-sectitle"><h2>${esc(t('hb_system', null, 'What XS-Housing found'))}</h2></div>
  <div class="bx-sysgrid">${haveCount() === null ? '' : sysRow('Shells', haveCount() ? t('hb_shells_have', { n: haveCount(), total: S.interiors.shells.length }, `${haveCount()} of ${S.interiors.shells.length} installed`) : null)}${sysRow('Framework', sys.framework)}${sysRow('Inventory', sys.inventory)}${sysRow('Door locks', sys.doorlock || t('hb_builtin', null, 'built in'))}${sysRow('Garage', sys.garage)}${sysRow('Dispatch', sys.dispatch)}${sysRow('Banking', sys.banking)}${sysRow('Phone', sys.phone)}${sysRow('XS-MDT', sys.mdt ? 'warrants on' : null)}${sysRow('bob74_ipl', sys.bob74 ? 'running' : null)}${sysRow('Screenshots', sys.screenshot ? 'screenshot-basic' : null)}</div></div>`;
    }

    function filtered(buildings) {
        const q = S.q.trim().toLowerCase();
        return S.props.filter((p) => {
            const d = p.data;
            if (buildings ? d.type !== 'building' : d.type === 'building') return false;
            if (!buildings && S.fType !== 'all' && d.type !== S.fType) return false;
            if (!buildings && S.fStatus !== 'all') {
                if (S.fStatus === 'off') { if (d.enabled !== false) return false; } else if (statusOf(p) !== S.fStatus) return false;
            }
            if (!q) return true;
            const hay = `${p.id} ${d.label} ${d.address.street} ${d.address.number} ${d.address.area} ${(p.owner && p.owner.name) || ''} ${XS.list(d.tags).join(' ')}`.toLowerCase();
            return hay.includes(q);
        });
    }

    function placesPage(buildings) {
        const list = filtered(buildings);
        const chip = (id, label, on, attr) => `<button class="bx-btn xs ${on ? 'primary' : 'ghost'}" ${attr}="${id}">${esc(label)}</button>`;
        const sel = S.sel;
        const bulk = sel.size ? `<div class="bx-bulk">${I('check', 14)}<b>${esc(t('hb_selected', { n: sel.size }, `${sel.size} selected`))}</b>
            <button class="bx-btn xs" data-act="bulk" data-p="enabled:1">${esc(t('hb_on', null, 'Switch on'))}</button><button class="bx-btn xs" data-act="bulk" data-p="enabled:0">${esc(t('hb_off', null, 'Switch off'))}</button>
            <button class="bx-btn xs" data-act="bulk" data-p="listed:1">${esc(t('hb_list', null, 'List'))}</button><button class="bx-btn xs" data-act="bulk" data-p="listed:0">${esc(t('hb_unlist', null, 'Unlist'))}</button>
            <button class="bx-btn xs" data-act="bulkprice">${I('cash', 13)}${esc(t('hb_prices', null, 'Prices'))}</button><button class="bx-btn xs" data-act="bulktag">${I('tag', 13)}${esc(t('hb_tag', null, 'Tag'))}</button>
            <button class="bx-btn xs" data-act="bulk" data-p="blip:1">${esc(t('hb_blips_on', null, 'Map icons on'))}</button><button class="bx-btn xs" data-act="bulk" data-p="blip:0">${esc(t('hb_blips_off', null, 'Map icons off'))}</button>
            <span class="bx-sp"></span><button class="bx-btn xs ghost" data-act="selnone">${esc(t('hb_clear', null, 'Clear'))}</button></div>` : '';
        const rows = list.map((p) => {
            const d = p.data;
            const st = statusOf(p);
            const iss = issues(normalise(copy(d)), p.id);
            const bad = iss.some((i) => i.level === 'bad');
            const interior = d.interior.kind === 'shell' ? ((shellOf(d.interior.shell) || {}).label || d.interior.shell) : (d.interior.kind === 'ipl' ? ((iplOf(d.interior.ipl) || {}).label || d.interior.ipl) : t(`hb_int_${d.interior.kind}`, null, d.interior.kind));
            const units = buildings ? S.props.filter((u) => u.data.type === 'unit' && Number(u.data.building) === p.id).length : null;
            return `<tr class="click ${d.enabled === false ? 'off' : ''}" data-act="edit" data-id="${p.id}">
                <td style="width:30px"><input type="checkbox" data-sel="${p.id}" ${sel.has(p.id) ? 'checked' : ''}></td>
                <td class="bx-mono" style="width:56px">#${p.id}</td>
                <td><b>${esc(d.label)}</b><div class="bx-hint">${esc([d.address.number, d.address.street, d.address.area].filter(Boolean).join(' · '))}</div></td>
                <td>${esc(typeName(d.type))}</td>
                ${buildings ? `<td>${esc(units)} ${esc(t('hb_units', null, 'units'))}</td>` : `<td class="bx-hint">${esc(interior || '—')}</td>`}
                ${buildings ? '<td></td>' : `<td><span class="bx-chip ${st === 'sale' ? 'blue' : (st === 'owned' ? 'ok' : 'warn')}">${esc(statusName(st))}</span>${p.owner ? `<div class="bx-hint">${esc(p.owner.name)}</div>` : ''}</td>`}
                <td class="r bx-mono">${d.money.buy ? money(d.money.price) : '—'}${d.money.rent ? `<div class="bx-hint">${money(d.money.rentPrice)} ${esc(t('hb_rent_short', null, 'rent'))}</div>` : ''}</td>
                <td class="r">${bad ? `<span class="bx-chip bad">${I('alert', 12)}${iss.length}</span>` : (d.enabled === false ? `<span class="bx-chip off">${esc(t('hb_off_short', null, 'Off'))}</span>` : `<span class="bx-chip ok">${I('check', 12)}</span>`)}</td>
                <td class="r" style="width:96px"><button class="bx-tool" data-act="tp" data-id="${p.id}" title="${esc(t('hb_teleport', null, 'Teleport'))}">${I('goto', 14)}</button><button class="bx-tool" data-act="dup" data-id="${p.id}" title="${esc(t('hb_duplicate', null, 'Duplicate'))}">${I('copy', 14)}</button></td>
            </tr>`;
        }).join('');
        const types = TYPES.filter((x) => x.id !== 'building');
        return `${head(buildings ? t('hb_buildings', null, 'Apartment buildings') : t('hb_places', null, 'Places'), buildings ? t('hb_buildings_sub', null, 'A building is one lobby door. Its apartments are inside, each with its own owner.') : t('hb_places_sub', null, 'Click a row to edit it. Tick rows to change many at once.'),
            `<button class="bx-btn primary" data-act="new" data-type="${buildings ? 'building' : 'house'}">${I('plus', 15)}${esc(buildings ? t('hb_new_building', null, 'New building') : t('hb_new_place', null, 'New place'))}</button>`)}
<div class="bx-listbar"><div class="bx-filter">${I('search', 15)}<input class="bx-input" id="bx-q" value="${esc(S.q)}" placeholder="${esc(t('hb_filter', null, 'Name, street, owner, tag or #id'))}"></div>
  ${buildings ? '' : `${chip('all', t('hb_all', null, 'All'), S.fType === 'all', 'data-ftype')}${types.map((x) => chip(x.id, typeName(x.id), S.fType === x.id, 'data-ftype')).join('')}
  <span class="bx-sp"></span>${['all', 'sale', 'owned', 'rented', 'mortgage', 'starter', 'off'].map((x) => chip(x, x === 'all' ? t('hb_any', null, 'Any status') : (x === 'off' ? t('hb_switched_off', null, 'Switched off') : statusName(x)), S.fStatus === x, 'data-fstatus')).join('')}`}
</div>
${bulk}
${list.length ? `<div class="bx-card"><table class="bx-table"><thead><tr><th><input type="checkbox" data-selall="1" ${list.length && list.every((p) => sel.has(p.id)) ? 'checked' : ''}></th><th>#</th><th>${esc(t('hb_name', null, 'Name'))}</th><th>${esc(t('hb_type', null, 'Type'))}</th><th>${esc(buildings ? t('hb_units', null, 'Units') : t('hb_inside', null, 'Inside'))}</th><th>${esc(buildings ? '' : t('hb_status', null, 'Status'))}</th><th class="r">${esc(t('hb_price', null, 'Price'))}</th><th class="r">${esc(t('hb_setup', null, 'Setup'))}</th><th></th></tr></thead><tbody>${rows}</tbody></table></div>`
        : `<div class="bx-empty">${I(buildings ? 'apartment' : 'home', 30)}<b>${esc(t('hb_empty', null, 'Nothing here yet'))}</b><p>${esc(buildings ? t('hb_empty_buildings', null, 'Make a building, then add its apartments on the Units tab.') : t('hb_empty_places', null, 'Make a place, or try Quick place to do a whole street.'))}</p></div>`}`;
    }

    function field(label, inner, hint) {
        return `<div class="bx-field"><label class="bx-label">${esc(label)}</label>${inner}${hint ? `<div class="bx-hint">${esc(hint)}</div>` : ''}</div>`;
    }

    function inp(path, opts) {
        opts = opts || {};
        const v = getPath(S.cur, path);
        return `<input class="bx-input ${opts.mono ? 'mono' : ''}" data-path="${path}" ${opts.type ? `type="${opts.type}"` : ''} value="${esc(v === null || v === undefined ? '' : v)}" ${opts.placeholder ? `placeholder="${esc(opts.placeholder)}"` : ''} ${opts.max ? `maxlength="${opts.max}"` : ''}>`;
    }

    function unit(path, u, opts) {
        opts = opts || {};
        const v = getPath(S.cur, path);
        return `<div class="bx-unit"><input type="number" data-path="${path}" data-num="1" value="${esc(v === null || v === undefined ? '' : v)}" ${opts.min !== undefined ? `min="${opts.min}"` : ''} ${opts.max !== undefined ? `max="${opts.max}"` : ''} step="${opts.step || 1}">${u ? `<em>${esc(u)}</em>` : ''}</div>`;
    }

    function sw(path, label, hint, disabled) {
        const v = getPath(S.cur, path);
        return `<div class="bx-rowline"><div><b>${esc(label)}</b>${hint ? `<div class="bx-hint">${esc(hint)}</div>` : ''}</div><span class="bx-switch ${v ? 'on' : ''} ${disabled ? 'dis' : ''}" data-act="${disabled ? '' : 'toggle'}" data-path="${path}"></span></div>`;
    }

    function sel(path, options) {
        const v = getPath(S.cur, path);
        return `<select class="bx-input" data-path="${path}">${options.map((o) => `<option value="${esc(o[0])}" ${String(o[0]) === String(v) ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}</select>`;
    }

    function pointBtns(kind, idx, p, opts) {
        opts = opts || {};
        return `<div class="bx-ptacts">${opts.noTp ? '' : `<button class="bx-tool" data-act="ptgo" data-kind="${kind}" data-i="${idx}" title="${esc(t('hb_teleport', null, 'Teleport'))}">${I('goto', 13)}</button>`}<button class="bx-tool" data-act="ptre" data-kind="${kind}" data-i="${idx}" title="${esc(t('hb_move', null, 'Move'))}">${I('crosshair', 13)}</button><button class="bx-tool danger" data-act="ptdel" data-kind="${kind}" data-i="${idx}" title="${esc(t('hb_remove', null, 'Remove'))}">${I('remove', 13)}</button></div>`;
    }

    function pointGroup(def, list, extra) {
        const n = list.length;
        const inside = def.inside && (S.cur.interior.kind === 'shell' || S.cur.interior.kind === 'ipl');
        return `<div class="bx-group"><div class="bx-grouph"><span class="bx-gico" style="background:${def.inside ? '#2dd4bf' : '#f5a524'}">${I(def.icon, 16)}</span><div class="bx-gtext"><b>${esc(t(`hb_pt_${def.key}`, null, def.label))} ${n ? `<span class="bx-tag ok">${n}</span>` : ''}${inside ? `<span class="bx-tag">${esc(t('hb_inside_tag', null, 'inside'))}</span>` : ''}</b><span>${esc(t(`hb_pt_${def.key}_hint`, null, def.hint))}</span></div></div>
        <div class="bx-points">${list.map((p, i) => `<div class="bx-pt"><span class="bx-ptn">${i + 1}</span><div class="bx-ptmain"><b>${esc(p.label || `${t(`hb_pt_${def.key}`, null, def.label)} ${i + 1}`)}</b><small>${esc(pt(p))}</small></div>${extra ? extra(p, i) : ''}${pointBtns(def.key, i, p, { noTp: inside })}</div>`).join('')}</div>
        <div class="bx-addrow"><button class="bx-btn sm" data-act="ptadd" data-kind="${def.key}">${I('crosshair', 14)}${esc(t('hb_place', null, 'Place'))}</button>${inside ? '' : `<button class="bx-btn sm" data-act="pthere" data-kind="${def.key}">${I('pin', 14)}${esc(t('hb_here', null, 'At my feet'))}</button>`}</div></div>`;
    }

    function tabGeneral() {
        const d = S.cur;
        const groupNames = d.group.kind === 'job' ? S.jobs : (d.group.kind === 'gang' ? S.gangs : []);
        const starter = d.tags.includes('starter');
        const photo = d.photo === 'stored' ? (S.photo || '') : d.photo;
        return `<div class="bx-layout"><div>
<div class="bx-card"><div class="bx-cardbody">
  <div class="bx-cols2">${field(t('hb_name', null, 'Name'), inp('label', { max: 64, placeholder: t('hb_name_ph', null, 'Mirror Park 12') }))}${field(t('hb_type', null, 'Type'), sel('type', TYPES.map((x) => [x.id, typeName(x.id)])))}</div>
  <div class="bx-cols3">${field(t('hb_street', null, 'Street'), inp('address.street', { max: 64 }))}${field(t('hb_number', null, 'Number'), inp('address.number', { max: 12 }))}${field(t('hb_area', null, 'Area'), inp('address.area', { max: 48 }))}</div>
  ${d.type === 'unit' ? `<div class="bx-cols3">${field(t('hb_building', null, 'Building'), `<select class="bx-input" data-path="building" data-num="1"><option value="0">—</option>${S.props.filter((p) => p.data.type === 'building').map((b) => `<option value="${b.id}" ${Number(d.building) === b.id ? 'selected' : ''}>#${b.id} ${esc(b.data.label)}</option>`).join('')}</select>`)}${field(t('hb_unit', null, 'Unit'), inp('unit', { max: 24 }))}${field(t('hb_floor', null, 'Floor'), unit('floor', '', { min: -10, max: 200 }))}</div>` : ''}
  ${field(t('hb_description', null, 'Description'), `<textarea class="bx-input" data-path="description" rows="3" style="height:auto;padding:9px 11px" maxlength="600">${esc(d.description || '')}</textarea>`, t('hb_description_hint', null, 'Shown on the listing.'))}
  ${field(t('hb_tags', null, 'Tags'), `<div class="bx-tags">${d.tags.map((x, i) => `<span class="bx-tagx">${esc(x)}<button data-act="untag" data-i="${i}">${I('close', 10)}</button></span>`).join('')}<input data-tagin="tags" placeholder="${esc(t('hb_tag_ph', null, 'luxury, beach… then Enter'))}"></div>`)}
  ${field(t('hb_notes', null, 'Staff notes'), `<textarea class="bx-input" data-path="notes" rows="2" style="height:auto;padding:9px 11px" maxlength="500">${esc(d.notes || '')}</textarea>`)}
</div></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardbody">
  ${sw('enabled', t('hb_live', null, 'Live'), t('hb_live_hint', null, 'Off hides it everywhere without deleting it.'))}
  ${sw('listed', t('hb_listed', null, 'Listed for sale'), t('hb_listed_hint', null, 'Off keeps it off the market and agents see it as unlisted.'))}
  <div class="bx-rowline"><div><b>${esc(t('hb_starter', null, 'Starter apartment'))}</b><div class="bx-hint">${esc(t('hb_starter_hint', null, 'New characters get a free one from places with this tag. On a building, every unit counts and more are made when they run out.'))}</div></div><span class="bx-switch ${starter ? 'on' : ''}" data-act="starter"></span></div>
  ${sw('markers', t('hb_markers', null, 'Marker on the door'), t('hb_markers_hint', null, 'Draws a marker as well as the target.'))}
</div></div>
</div><div>
<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_photo', null, 'Listing photo'))}</h3></div><div class="bx-cardbody">
  <div class="hb-photo">${photo ? `<img src="${esc(photo)}" alt="">` : `<div>${I('photo', 28)}<span>${esc(t('hb_no_photo', null, 'No photo yet'))}</span></div>`}</div>
  <div style="display:flex;gap:8px;margin-top:10px"><button class="bx-btn sm" data-act="photo" ${S.curId ? '' : 'disabled'}>${I('camera', 14)}${esc(t('hb_take_photo', null, 'Take photo'))}</button>${d.photo ? `<button class="bx-btn sm ghost" data-act="nophoto">${esc(t('hb_remove', null, 'Remove'))}</button>` : ''}</div>
  ${field(t('hb_photo_url', null, 'Or a link'), `<input class="bx-input mono" data-path="photo" value="${esc(d.photo === 'stored' ? '' : (d.photo || ''))}" placeholder="https://…">`, S.curId ? t('hb_photo_hint', null, 'Take photo hides the builder and snaps your screen.') : t('hb_photo_save_first', null, 'Save the place first to take a photo.'))}
</div></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_who_buys', null, 'Who can buy it'))}</h3></div><div class="bx-cardbody">
  ${field(t('hb_group', null, 'Only for'), sel('group.kind', [['none', t('hb_anyone', null, 'Anyone')], ['job', t('hb_a_job', null, 'A job')], ['gang', t('hb_a_crew', null, 'A crew')]]))}
  ${d.group.kind !== 'none' ? `<div class="bx-cols2">${field(d.group.kind === 'job' ? t('hb_job', null, 'Job') : t('hb_crew', null, 'Crew'), `<select class="bx-input" data-path="group.name"><option value="">—</option>${groupNames.map((g) => `<option value="${esc(g.name)}" ${g.name === d.group.name ? 'selected' : ''}>${esc(g.label)}</option>`).join('')}</select>`)}${field(t('hb_min_grade', null, 'Lowest rank'), unit('group.grade', '', { min: 0, max: 50 }))}</div>${sw('group.access', t('hb_group_access', null, 'Members get in'), t('hb_group_access_hint', null, 'Everyone in it at that rank or above can use the place.'))}` : ''}
  ${field(t('hb_coowners', null, 'Most co-owners'), unit('maxCoOwners', '', { min: 0, max: 20 }))}
</div></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_mapicon', null, 'Map icon'))}</h3></div><div class="bx-cardbody">
  ${sw('blip.show', t('hb_blip_show', null, 'Show on the map'), t('hb_blip_hint', null, 'Owners, key holders and buyers see it in the colours from Settings.'))}
  <div class="bx-cols3">${field(t('hb_sprite', null, 'Icon'), unit('blip.sprite', '', { min: 0, max: 900 }), t('hb_sprite_hint', null, '0 uses the default'))}${field(t('hb_colour', null, 'Colour'), unit('blip.colour', '', { min: -1, max: 85 }), t('hb_colour_hint', null, '-1 uses the default'))}${field(t('hb_label', null, 'Label'), inp('blip.label', { max: 48 }))}</div>
</div></div>
</div></div>`;
    }

    function tabEntrance() {
        const d = S.cur;
        const isBuilding = d.type === 'building';
        return `<div class="bx-layout"><div><div class="bx-groups">
<div class="bx-group ${d.door ? '' : 'need'}"><div class="bx-grouph"><span class="bx-gico" style="background:#f5a524">${I('door', 16)}</span><div class="bx-gtext"><b>${esc(isBuilding ? t('hb_lobby_door', null, 'Lobby door') : t('hb_front_door', null, 'Front door'))} ${d.door ? '<span class="bx-tag ok">1</span>' : `<span class="bx-tag req">${esc(t('hb_needed', null, 'needed'))}</span>`}</b><span>${esc(isBuilding ? t('hb_lobby_hint', null, 'Everyone uses this door to reach the apartments.') : t('hb_door_hint', null, 'Face out of the door when you place it.'))}</span></div></div>
  ${d.door ? `<div class="bx-points"><div class="bx-pt"><span class="bx-ptn">1</span><div class="bx-ptmain"><b>${esc(t('hb_front_door', null, 'Front door'))}</b><small>${esc(pt(d.door))} · ${Math.round(d.door.w || 0)}°</small></div><div class="bx-ptacts"><button class="bx-tool" data-act="doorgo">${I('goto', 13)}</button></div></div></div>` : ''}
  <div class="bx-addrow"><button class="bx-btn sm" data-act="door">${I('crosshair', 14)}${esc(d.door ? t('hb_move', null, 'Move') : t('hb_place', null, 'Place'))}</button><button class="bx-btn sm" data-act="doorhere">${I('pin', 14)}${esc(t('hb_here', null, 'At my feet'))}</button></div></div>
${isBuilding ? '' : pointGroup({ key: 'extraDoors', label: 'Extra doors', icon: 'door', hint: 'Back doors and balconies that lead to the same inside.' }, d.extraDoors)}
</div></div><div>
<div class="bx-card"><div class="bx-cardbody">
  ${field(t('hb_enter_mode', null, 'How people use the door'), sel('enterMode', [['both', t('hb_both', null, 'Target and E prompt')], ['target', t('hb_target_only', null, 'Target only')], ['key', t('hb_key_only', null, 'E prompt only')]]))}
  <div class="bx-hint">${esc(t('hb_door_opts', null, 'Owners lock, unlock and enter. Visitors ring or knock. Buyers see the listing and can take a tour. Burglars and police get their own options.'))}</div>
</div></div></div></div>`;
    }

    const picKey = (kind, v) => `${kind}:${v}`;

    function picBody(kind, v, small) {
        const k = picKey(kind, v);
        if (!v) return `<div class="hb-picmsg">${I(kind === 'ipl' ? 'building' : 'warehouse', small ? 20 : 26)}<span>${esc(t('hb_pic_pick', null, 'Pick one to see inside'))}</span></div>`;
        if (S.pics[k]) return `<img src="${esc(S.pics[k])}" alt="">`;
        if (S.pics[k] === null) return '<div class="hb-picmsg"><i class="hb-spin"></i></div>';
        if (S.picErr[k]) return `<div class="hb-picmsg bad">${I('alert', small ? 18 : 22)}<span>${esc(S.picErr[k])}</span></div>`;
        if (small) return `<div class="hb-picmsg">${I(kind === 'ipl' ? 'building' : 'warehouse', 20)}<span>${esc(t('hb_pic_none', null, 'No picture yet'))}</span></div>`;
        if (!S.system.screenshot) return `<div class="hb-picmsg">${I('camera', 26)}<span>${esc(t('hb_pic_needs', null, 'Pictures need screenshot-basic'))}</span></div>`;
        return `<div class="hb-picmsg">${I('camera', 26)}<span>${esc(t('hb_pic_none', null, 'No picture yet'))}</span><small class="hb-pichow">${esc(t('hb_pic_how', null, 'Go inside, press Enter, line up a nice view and press Enter again.'))}</small><button class="bx-btn xs primary" data-act="preview">${I('eye', 12)}${esc(t('hb_pic_go', null, 'Go inside'))}</button></div>`;
    }

    function picHtml(kind, v, small) {
        const k = picKey(kind, v);
        if (v && S.pics[k] === undefined && S.picKeys.has(k)) {
            S.pics[k] = null;
            S.picQ.push([kind, v]);
            setTimeout(pumpPics, 0);
        }
        return `<div class="hb-pic ${small ? 'sm' : ''}" data-pic="${esc(k)}" data-small="${small ? 1 : 0}">${picBody(kind, v, small)}</div>`;
    }

    function patchPic(k) {
        const at = k.indexOf(':');
        const kind = k.slice(0, at);
        const v = k.slice(at + 1);
        root.querySelectorAll('.hb-pic').forEach((el) => {
            if (el.dataset.pic !== k) return;
            const card = el.closest('.hb-insidecard');
            if (card) card.outerHTML = insideCard(kind, v);
            else el.innerHTML = picBody(kind, v, el.dataset.small === '1');
        });
    }

    async function pumpPics() {
        if (S.picBusy) return;
        S.picBusy = true;
        while (S.picQ.length) {
            const [kind, v] = S.picQ.shift();
            const k = picKey(kind, v);
            const res = await XS.rpc('b:picture', { kind, value: v });
            S.pics[k] = res.ok && res.data ? res.data : '';
            if (!S.pics[k]) S.picKeys.delete(k);
            patchPic(k);
        }
        S.picBusy = false;
    }

    async function keepPicture(kind, v, image) {
        const k = picKey(kind, v);
        const small = await downscale(image, 640, 360);
        const saved = await XS.rpc('b:savePicture', { kind, value: v, data: small });
        if (!saved.ok) { S.picErr[k] = saved.error || t('hb_pic_failed', null, 'The picture did not work.'); return false; }
        S.pics[k] = small;
        S.picKeys.add(k);
        delete S.picErr[k];
        return true;
    }

    function insideCard(kind, v) {
        const k = picKey(kind, v);
        const has = !!S.pics[k];
        return `<div class="bx-card hb-insidecard"><div class="bx-cardhead"><h3>${esc(t('hb_pic_inside', null, 'Inside'))}</h3>${has && S.system.screenshot ? `<button class="bx-btn xs ghost" data-act="preview">${I('camera', 12)}${esc(t('hb_pic_retake', null, 'Retake'))}</button>` : ''}</div><div class="bx-cardbody">${picHtml(kind, v, false)}</div></div>`;
    }

    function shellPicker() {
        const q = S.shellQ.trim().toLowerCase();
        const list = byInstalled(S.interiors.shells.filter((s) => !q || `${s.label} ${s.model} ${s.pack}`.toLowerCase().includes(q))).slice(0, 80);
        const curShell = shellOf(S.cur.interior.shell);
        const curChip = curShell && installed(curShell.model) === null ? `<span class="bx-chip ${curShell.free ? 'ok' : 'warn'}">${esc(curShell.free ? t('hb_free', null, 'free') : t('hb_paid', null, 'paid pack'))}</span>` : (curShell ? shellChip(curShell) : '');
        return `${noShells()}<div class="bx-filter" style="width:100%;margin-bottom:8px">${I('search', 15)}<input class="bx-input" id="hb-shellq" value="${esc(S.shellQ)}" placeholder="${esc(t('hb_shell_search', { n: S.interiors.shells.length }, `Search ${S.interiors.shells.length} shells`))}"></div>
        ${curShell ? `<div class="hb-cur">${I('check', 14)}<b>${esc(curShell.label)}</b><span class="bx-mono">${esc(curShell.model)}</span>${curChip}${curShell.guess ? `<span class="bx-chip warn">${esc(t('hb_door_unknown', null, 'door not known'))}</span>` : ''}</div>` : ''}
        <div class="hb-picklist xsp-scroll">${list.map((s) => `<button class="hb-pick ${s.model === S.cur.interior.shell ? 'on' : ''} ${installed(s.model) === false ? 'hb-missing' : ''}" data-act="pickshell" data-model="${esc(s.model)}"><b>${esc(s.label)}</b><small>${esc(s.model)} · ${esc(packLine(s))}</small>${shellChip(s)}</button>`).join('')}</div>
        ${field(t('hb_custom_shell', null, 'Or any model name'), inp('interior.shell', { mono: true, placeholder: 'shell_v16low' }), t('hb_custom_shell_hint', null, 'Paid shells only work when the server streams that pack.'))}
        <div id="hb-modelstate" class="hb-modelstate">${modelState()}</div>`;
    }

    let modelTimer = null;
    function modelState() {
        const m = String((S.cur && S.cur.interior.shell) || '').trim();
        if (!m || shellOf(m) || !S.have) return '';
        const have = installed(m);
        if (have === null) { checkModel(m); return ''; }
        return shellChip({ model: m });
    }

    function checkModel(m) {
        clearTimeout(modelTimer);
        modelTimer = setTimeout(async () => {
            const res = await XS.rpc('b:hasModel', { model: m });
            if (!S.have) return;
            S.have[m] = !!(res.ok && res.data);
            const el = root.querySelector('#hb-modelstate');
            if (el && String((S.cur && S.cur.interior.shell) || '').trim() === m) el.innerHTML = modelState();
        }, 400);
    }

    function iplPicker() {
        const q = S.iplQ.trim().toLowerCase();
        const list = S.interiors.ipls.filter((i) => !q || `${i.label} ${i.id} ${i.kind}`.toLowerCase().includes(q));
        const cur = iplOf(S.cur.interior.ipl);
        return `<div class="bx-filter" style="width:100%;margin-bottom:8px">${I('search', 15)}<input class="bx-input" id="hb-iplq" value="${esc(S.iplQ)}" placeholder="${esc(t('hb_ipl_search', { n: S.interiors.ipls.length }, `Search ${S.interiors.ipls.length} GTA interiors`))}"></div>
        ${cur ? `<div class="hb-cur">${I('check', 14)}<b>${esc(cur.label)}</b><span class="bx-chip">${esc(cur.kind)}</span>${cur.needs ? `<span class="bx-chip warn">${esc(t('hb_needs', { r: cur.needs }, `needs ${cur.needs}`))}</span>` : ''}${cur.build ? `<span class="bx-chip warn">${esc(t('hb_build', { n: cur.build }, `game build ${cur.build}+`))}</span>` : ''}${cur.unverified ? `<span class="bx-chip off">${esc(t('hb_check_spawn', null, 'check the spawn'))}</span>` : ''}</div>` : ''}
        <div class="hb-picklist xsp-scroll">${list.map((i) => `<button class="hb-pick ${i.id === S.cur.interior.ipl ? 'on' : ''}" data-act="pickipl" data-id="${esc(i.id)}"><b>${esc(i.label)}</b><small>${esc(i.kind)}${XS.list(i.styles).length ? ` · ${XS.list(i.styles).length} ${esc(t('hb_styles', null, 'styles'))}` : ''}</small>${i.build ? `<span class="bx-chip warn">${esc(i.build)}</span>` : ''}</button>`).join('')}</div>`;
    }

    function tabInterior() {
        const d = S.cur;
        const k = d.interior.kind;
        const kinds = [['shell', t('hb_int_shell', null, 'Shell'), 'warehouse'], ['ipl', t('hb_int_ipl', null, 'GTA interior'), 'building'], ['mlo', t('hb_int_mlo', null, 'MLO (in the map)'), 'door'], ['none', t('hb_int_none', null, 'No inside'), 'close']];
        const cur = iplOf(d.interior.ipl);
        let body = '';
        if (k === 'shell') {
            body = `<div class="bx-layout"><div><div class="bx-card"><div class="bx-cardbody">${shellPicker()}</div></div></div><div>
            ${insideCard('shell', d.interior.shell)}
            <div class="bx-groups" style="margin-top:14px">${pointGroup({ key: 'exit', label: 'Inside door', icon: 'door', inside: true, hint: (shellOf(d.interior.shell) || {}).guess ? t('hb_exit_guess', null, 'This shell has no known door yet. Place it once, or people appear in the middle of the room.') : 'Where people appear inside. Left empty, the shell’s own door is used.' }, d.interior.exit ? [d.interior.exit] : [])}</div>
            <div class="bx-card" style="margin-top:14px"><div class="bx-cardbody"><button class="bx-btn" data-act="preview">${I('eye', 15)}${esc(t('hb_preview', null, 'Go inside to look'))}</button><div class="bx-hint" style="margin-top:8px">${esc(S.system.screenshot ? t('hb_preview_hint_pic', null, 'You go in on your own. Press Enter in there to take the picture, Backspace to come back.') : t('hb_preview_hint', null, 'You go in on your own. Press Backspace to come back.'))}</div></div></div></div></div>`;
        } else if (k === 'ipl') {
            const styles = cur ? XS.list(cur.styles) : [];
            body = `<div class="bx-layout"><div><div class="bx-card"><div class="bx-cardbody">${iplPicker()}</div></div></div><div>
            ${insideCard('ipl', cur ? cur.id : '')}
            ${styles.length ? `<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_styles_title', null, 'Décor styles owners can pick'))}</h3><small>${esc(t('hb_styles_none_all', null, 'None ticked means all'))}</small></div><div class="bx-cardbody"><div class="hb-checks">${styles.map((s) => `<label class="hb-check"><input type="checkbox" data-style="${esc(s.id)}" ${d.interior.styles.includes(s.id) ? 'checked' : ''}><span>${esc(s.label)}</span><button class="bx-btn xs ${d.interior.defaultStyle === s.id ? 'primary' : 'ghost'}" data-act="defstyle" data-id="${esc(s.id)}">${esc(t('hb_default', null, 'Default'))}</button></label>`).join('')}</div></div></div>` : ''}
            <div class="bx-groups" style="margin-top:14px">${pointGroup({ key: 'exit', label: 'Inside door', icon: 'door', inside: true, hint: 'Where people appear inside. Left empty, the interior’s own spawn is used.' }, d.interior.exit ? [d.interior.exit] : [])}</div>
            <div class="bx-card" style="margin-top:14px"><div class="bx-cardbody"><button class="bx-btn" data-act="preview" ${cur ? '' : 'disabled'}>${I('eye', 15)}${esc(t('hb_preview', null, 'Go inside to look'))}</button><div class="bx-hint" style="margin-top:8px">${esc(t('hb_ipl_hint', null, 'Every owner gets their own private copy, so one interior can be used by any number of places.'))}</div></div></div></div></div>`;
        } else if (k === 'mlo') {
            body = `<div class="bx-layout"><div><div class="bx-groups">
            <div class="bx-group ${d.doors.length ? '' : 'need'}"><div class="bx-grouph"><span class="bx-gico" style="background:#f5a524">${I('lock', 16)}</span><div class="bx-gtext"><b>${esc(t('hb_mlo_doors', null, 'Doors that lock'))} ${d.doors.length ? `<span class="bx-tag ok">${d.doors.length}</span>` : ''}</b><span>${esc(t('hb_mlo_doors_hint', { s: S.system.doorlock || t('hb_builtin', null, 'built in') }, `Aim at a door to add it. Locks go through ${S.system.doorlock || 'the built-in lock'}.`))}</span></div></div>
              <div class="bx-points">${d.doors.map((door, i) => `<div class="bx-pt"><span class="bx-ptn">${i + 1}</span><div class="bx-ptmain"><input class="bx-input sm" data-path="doors.${i}.label" value="${esc(door.label || '')}" placeholder="${esc(t('hb_door_n', { n: i + 1 }, `Door ${i + 1}`))}"><small>${esc(door.id ? `${t('hb_lock_id', null, 'lock id')} ${door.id}` : t('hb_builtin_lock', null, 'built-in lock'))} · ${esc(pt(door))}</small></div><div class="bx-ptacts"><button class="bx-tool danger" data-act="doordel" data-i="${i}">${I('remove', 13)}</button></div></div>`).join('')}</div>
              <div class="bx-addrow"><button class="bx-btn sm" data-act="pickdoor">${I('crosshair', 14)}${esc(t('hb_pick_door', null, 'Pick a door'))}</button></div></div>
            <div class="bx-group ${d.area.poly.length >= 3 ? '' : 'need'}"><div class="bx-grouph"><span class="bx-gico" style="background:#2dd4bf">${I('polygon', 16)}</span><div class="bx-gtext"><b>${esc(t('hb_mlo_area', null, 'Inside area'))} ${d.area.poly.length >= 3 ? `<span class="bx-tag ok">${d.area.poly.length}</span>` : ''}</b><span>${esc(t('hb_mlo_area_hint', null, 'Click the corners of the rooms. Furniture, the panel and storage stay inside it.'))}</span></div></div>
              <div class="bx-addrow"><button class="bx-btn sm" data-act="drawarea">${I('polygon', 14)}${esc(d.area.poly.length ? t('hb_redraw', null, 'Draw again') : t('hb_draw', null, 'Draw'))}</button>${d.area.poly.length >= 3 ? `<button class="bx-btn sm" data-act="showarea">${I('eye', 14)}${esc(t('hb_show', null, 'Show'))}</button>` : ''}</div></div>
            </div></div><div><div class="bx-card"><div class="bx-cardbody"><div class="bx-hint">${esc(t('hb_mlo_hint', null, 'An MLO is walked into, so there is no teleport. Storage, wardrobe, panel and bed go on the Points tab and stand in the world.'))}</div></div></div></div></div>`;
        } else {
            body = `<div class="bx-card"><div class="bx-cardbody"><div class="bx-hint">${esc(t('hb_none_hint', null, 'No inside. Useful for a plot with only a yard and a garage.'))}</div></div></div>`;
        }
        return `<div class="hb-kinds">${kinds.map((x) => `<button class="hb-kind ${k === x[0] ? 'on' : ''}" data-act="intkind" data-kind="${x[0]}">${I(x[2], 18)}<b>${esc(x[1])}</b></button>`).join('')}</div>${body}
        <div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_furn_rules', null, 'Furniture rules'))}</h3></div><div class="bx-cardbody">${sw('furniture.allowed', t('hb_furn_allowed', null, 'Owners can furnish'), null)}<div class="bx-cols2">${field(t('hb_furn_limit', null, 'Most items inside'), unit('furniture.limit', '', { min: 0, max: 2000 }), t('hb_zero_default', null, '0 uses the setting'))}${field(t('hb_furn_cats', null, 'Allowed categories'), catChecks('furniture.categories'), t('hb_none_all', null, 'None ticked means all'))}</div></div></div>`;
    }

    function catChecks(path) {
        const list = XS.list(getPath(S.cur, path));
        return `<div class="hb-catchecks">${S.categories.map((c) => `<label class="hb-mini ${list.includes(c.id) ? 'on' : ''}"><input type="checkbox" data-cat="${path}" value="${esc(c.id)}" ${list.includes(c.id) ? 'checked' : ''}>${esc(t(`hb_cat_${c.id}`, null, c.id))}</label>`).join('')}</div>`;
    }

    function tabYard() {
        const d = S.cur;
        const y = d.yard;
        const poly = y.shape === 'custom' ? y.poly : shape(y.shape, y.center, y.size, y.heading);
        return `<div class="bx-layout"><div>
<div class="bx-card"><div class="bx-cardbody">${sw('yard.enabled', t('hb_yard_on', null, 'This place has a yard'), t('hb_yard_hint', null, 'Owners can put decorations, a barbecue, fences and more inside it.'))}</div></div>
${y.enabled ? `<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_yard_shape', null, 'Shape'))}</h3></div><div class="bx-cardbody">
  <div class="hb-kinds">${SHAPES.map((s) => `<button class="hb-kind ${y.shape === s ? 'on' : ''}" data-act="yardshape" data-shape="${s}">${I(SHAPE_ICON[s], 18)}<b>${esc(t(`hb_shape_${s}`, null, s[0].toUpperCase() + s.slice(1)))}</b></button>`).join('')}</div>
  ${y.shape === 'custom' ? `<div class="bx-addrow" style="padding:0"><button class="bx-btn" data-act="drawyard">${I('polygon', 15)}${esc(y.poly.length ? t('hb_redraw', null, 'Draw again') : t('hb_draw_corners', null, 'Click the corners'))}</button></div>` : `
  <div class="bx-cols2">${field(t('hb_size', null, 'Size'), unit('yard.size', 'm', { min: 2, max: 120, step: 0.5 }))}${field(t('hb_turn', null, 'Turn'), unit('yard.heading', '°', { min: 0, max: 360 }))}</div>
  <div class="bx-addrow" style="padding:0"><button class="bx-btn" data-act="yardcenter">${I('crosshair', 15)}${esc(y.center ? t('hb_move_centre', null, 'Move the centre') : t('hb_place_centre', null, 'Place the centre'))}</button><button class="bx-btn" data-act="yardhere">${I('pin', 15)}${esc(t('hb_here', null, 'At my feet'))}</button></div>`}
  ${poly.length >= 3 ? `<div class="bx-addrow" style="padding:10px 0 0"><button class="bx-btn ghost" data-act="showyard">${I('eye', 15)}${esc(t('hb_show_world', null, 'Show it in the world'))}</button></div>` : ''}
</div></div>` : ''}
</div><div>
${y.enabled ? `<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_yard_plan', null, 'Plan'))}</h3></div><div class="bx-cardbody">${planSvg(poly, d.door, y.center)}</div></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardbody"><div class="bx-cols2">${field(t('hb_yard_limit', null, 'Most decorations'), unit('yard.limit', '', { min: 0, max: 1000 }), t('hb_zero_default', null, '0 uses the setting'))}${field(t('hb_yard_cats', null, 'Allowed categories'), catChecks('yard.categories'), t('hb_none_all', null, 'None ticked means all'))}</div></div></div>` : ''}
</div></div>`;
    }

    function planSvg(poly, door, center) {
        const pts = XS.list(poly).slice();
        if (door) pts.push({ x: door.x, y: door.y });
        if (!pts.length) return `<div class="bx-empty" style="padding:30px">${I('polygon', 26)}<p>${esc(t('hb_no_shape', null, 'No shape yet.'))}</p></div>`;
        const xs = pts.map((p) => p.x);
        const ys = pts.map((p) => p.y);
        const minX = Math.min(...xs) - 3;
        const maxX = Math.max(...xs) + 3;
        const minY = Math.min(...ys) - 3;
        const maxY = Math.max(...ys) + 3;
        const w = 360;
        const h = 240;
        const sc = Math.min(w / (maxX - minX || 1), h / (maxY - minY || 1));
        const X = (x) => ((x - minX) * sc + (w - (maxX - minX) * sc) / 2).toFixed(1);
        const Y = (y) => (h - ((y - minY) * sc + (h - (maxY - minY) * sc) / 2)).toFixed(1);
        const path = XS.list(poly).map((p) => `${X(p.x)},${Y(p.y)}`).join(' ');
        return `<svg class="hb-plan" viewBox="0 0 ${w} ${h}"><defs><pattern id="hbGrid" width="18" height="18" patternUnits="userSpaceOnUse"><path d="M18 0H0V18" fill="none" stroke="rgba(255,255,255,.05)"/></pattern></defs><rect width="${w}" height="${h}" fill="url(#hbGrid)"/>
        ${path ? `<polygon points="${path}" fill="rgba(45,212,191,.12)" stroke="#2dd4bf" stroke-width="2"/>` : ''}
        ${XS.list(poly).map((p) => `<circle cx="${X(p.x)}" cy="${Y(p.y)}" r="3" fill="#2dd4bf"/>`).join('')}
        ${center ? `<circle cx="${X(center.x)}" cy="${Y(center.y)}" r="4" fill="none" stroke="#5eead4" stroke-width="1.5"/>` : ''}
        ${door ? `<g><circle cx="${X(door.x)}" cy="${Y(door.y)}" r="6" fill="#f5a524"/><text x="${Number(X(door.x)) + 9}" y="${Number(Y(door.y)) + 4}" fill="#f5a524" font-size="11" font-weight="700">${esc(t('hb_door', null, 'Door'))}</text></g>` : ''}</svg>`;
    }

    function tabGarage() {
        const d = S.cur;
        const own = S.system.garage === 'cd_garage' || S.system.garage === 'okokGarage';
        return `<div class="bx-layout"><div>
<div class="bx-card"><div class="bx-cardbody">${sw('garage.enabled', t('hb_garage_on', null, 'This place has a garage'), S.system.garage ? t('hb_garage_through', { s: S.system.garage }, `It is added to ${S.system.garage}.`) : t('hb_garage_none', null, 'No garage script was found, so it does nothing yet.'))}</div></div>
${d.garage.enabled ? `<div class="bx-groups" style="margin-top:14px">${pointGroup({ key: 'garageSpots', label: 'Parking spots', icon: 'car', hint: 'Where cars come out and go in.' }, d.garage.spots)}</div>` : ''}
</div><div>
${d.garage.enabled ? `<div class="bx-card"><div class="bx-cardbody">${field(t('hb_garage_label', null, 'Name'), inp('garage.label', { max: 48, placeholder: t('hb_garage_ph', null, 'Uses the place name') }))}<div class="bx-cols2">${field(t('hb_garage_max', null, 'Most cars'), unit('garage.max', '', { min: 1, max: 50 }))}<div></div></div>${sw('garage.shared', t('hb_garage_shared', null, 'Key holders share it'), t('hb_garage_shared_hint', null, 'Where the garage script allows it, everyone with keys sees the cars.'))}
${own ? `<div class="bx-hint" style="margin-top:8px">${esc(t('hb_garage_own', { s: S.system.garage }, `${S.system.garage} has no house garages of its own, so XS-Housing puts an open and store prompt on the spots for key holders.`))}</div>` : ''}</div></div>` : ''}
</div></div>`;
    }

    function tabPoints() {
        const d = S.cur;
        const storageExtra = (p, i) => `<div class="bx-ptextra"><input class="bx-input sm" style="width:64px" type="number" data-path="points.storage.${i}.slots" value="${esc(p.slots || '')}" placeholder="${esc(t('hb_slots', null, 'slots'))}"><input class="bx-input sm" style="width:82px" type="number" data-path="points.storage.${i}.weight" value="${esc(p.weight || '')}" placeholder="${esc(t('hb_weight', null, 'weight'))}"></div>`;
        const labelExtra = (kind) => (p, i) => `<div class="bx-ptextra"><input class="bx-input sm" style="width:120px" data-path="points.${kind}.${i}.label" value="${esc(p.label || '')}" placeholder="${esc(t('hb_label', null, 'Label'))}"></div>`;
        return `<div class="bx-layout"><div><div class="bx-groups">
${POINTS.filter((p) => p.inside).map((def) => pointGroup(def, d.points[def.key], def.key === 'storage' ? storageExtra : null)).join('')}
</div></div><div><div class="bx-groups">
${POINTS.filter((p) => !p.inside).map((def) => pointGroup(def, d.points[def.key], def.key === 'cameras' ? labelExtra('cameras') : null)).join('')}
</div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_storage_size', null, 'Storage size here'))}</h3></div><div class="bx-cardbody"><div class="bx-cols2">${field(t('hb_slots_t', null, 'Slots'), unit('storage.slots', '', { min: 0, max: 500 }), t('hb_zero_default', null, '0 uses the setting'))}${field(t('hb_weight_t', null, 'Weight'), unit('storage.weight', 'g', { min: 0, max: 10000000, step: 1000 }), t('hb_zero_default', null, '0 uses the setting'))}</div></div></div>
</div></div>`;
    }

    function tabMoney() {
        const d = S.cur;
        const zonePrice = (S.areaPrices || {})[d.address.zone];
        return `<div class="bx-layout"><div>
<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_buy', null, 'Buying'))}</h3></div><div class="bx-cardbody">
  ${sw('money.buy', t('hb_can_buy', null, 'Can be bought'), null, !S.rights.prices)}
  ${d.money.buy ? `${field(t('hb_price', null, 'Price'), unit('money.price', '$', { min: 0, step: 1000 }), zonePrice ? t('hb_area_price', { p: money(zonePrice) }, `Area price ${money(zonePrice)}`) : null)}${zonePrice ? `<button class="bx-btn xs ghost" data-act="areaprice">${esc(t('hb_use_area', null, 'Use the area price'))}</button>` : ''}
  ${sw('money.mortgage', t('hb_can_mortgage', null, 'Mortgage allowed'), t('hb_mortgage_hint', null, 'Deposit now, the rest in payments.'), !S.rights.prices)}
  ${d.money.mortgage ? `<div class="bx-cols2">${field(t('hb_min_deposit', null, 'Lowest deposit'), unit('money.minDepositPct', '%', { min: 0, max: 100 }), t('hb_zero_setting', null, '0 uses the setting'))}${field(t('hb_interest', null, 'Interest'), unit('money.interestPct', '%', { min: -1, max: 100, step: 0.5 }), t('hb_minus_setting', null, '-1 uses the setting'))}</div>` : ''}` : ''}
</div></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_rent_t', null, 'Renting'))}</h3></div><div class="bx-cardbody">
  ${sw('money.rent', t('hb_can_rent', null, 'Can be rented'), null, !S.rights.prices)}
  ${d.money.rent ? `<div class="bx-cols2">${field(t('hb_rent', null, 'Rent'), unit('money.rentPrice', '$', { min: 0, step: 50 }))}${field(t('hb_rent_days', null, 'Every'), unit('money.rentDays', t('hb_days', null, 'days'), { min: 0, max: 60, step: 0.5 }), t('hb_zero_setting', null, '0 uses the setting'))}</div>${field(t('hb_renter_deposit', null, 'Deposit (payments)'), unit('money.renterDeposit', '', { min: -1, max: 20 }), t('hb_minus_setting', null, '-1 uses the setting'))}` : ''}
</div></div></div><div>
<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_selling', null, 'Selling and agents'))}</h3></div><div class="bx-cardbody">
  ${field(t('hb_sellback', null, 'Paid back when sold to the market'), unit('money.sellBackPct', '%', { min: -1, max: 100 }), t('hb_minus_setting', null, '-1 uses the setting'))}
  ${field(t('hb_commission', null, 'Agent commission'), unit('money.commissionPct', '%', { min: -1, max: 50, step: 0.5 }), t('hb_minus_setting', null, '-1 uses the setting'))}
  ${!S.rights.prices ? `<div class="bx-hint">${esc(t('hb_no_price_right', null, 'You cannot change prices. Ask the server owner.'))}</div>` : ''}
</div></div></div></div>`;
    }

    function tabSecurity() {
        const d = S.cur;
        return `<div class="bx-layout"><div><div class="bx-card"><div class="bx-cardbody">
  ${sw('security.breakIns', t('hb_breakins', null, 'Can be broken into'), t('hb_breakins_hint', null, 'Lockpick the door, then open storage. Safes stay shut.'))}
  ${sw('security.raids', t('hb_raids', null, 'Police can raid it'), t('hb_raids_hint', null, 'With a warrant when that setting is on.'))}
  ${sw('security.alarm', t('hb_alarm_ok', null, 'Owners can fit an alarm'), null)}
  ${sw('security.cameras', t('hb_cams_ok', null, 'Owners can fit cameras'), null)}
</div></div></div><div><div class="bx-card"><div class="bx-cardbody">
  <div class="bx-cols2">${field(t('hb_lock_start', null, 'Lock it comes with'), sel('security.lockLevel', [[1, '1 · Standard'], [2, '2 · Deadbolt'], [3, '3 · Reinforced']]))}${field(t('hb_lock_max', null, 'Best lock allowed'), sel('security.maxLevel', [[1, '1'], [2, '2'], [3, '3']]))}</div>
  <div class="bx-cols2">${field(t('hb_cooldown', null, 'Break-in cooldown'), unit('security.cooldown', 'min', { min: 0, max: 1440 }), t('hb_zero_setting', null, '0 uses the setting'))}${field(t('hb_steal', null, 'Storage a burglar can reach'), unit('security.stealPct', '%', { min: 0, max: 100 }))}</div>
</div></div></div></div>`;
    }

    function tabPeople() {
        const p = byId(S.curId);
        if (!p) return `<div class="bx-empty">${I('people', 28)}<b>${esc(t('hb_save_first', null, 'Save the place first'))}</b></div>`;
        const o = p.owner;
        const keys = XS.list(p.keys);
        const due = o && o.next_due ? XS.date(o.next_due) : '—';
        const hits = (list, act) => list.map((h) => `<button class="bx-pickopt" data-act="${act}" data-cid="${esc(h.citizenid)}"><div style="flex:1"><b>${esc(h.name || h.citizenid)}</b><small>${esc(h.citizenid)}${h.online ? ` · ${esc(t('hb_online', null, 'online'))}` : ''}</small></div></button>`).join('');
        return `<div class="bx-layout"><div>
<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_owner', null, 'Owner'))}</h3></div><div class="bx-cardbody">
  ${o ? `<div class="hb-owner"><div class="bx-avatar">${esc((o.name || '?').slice(0, 1))}</div><div style="flex:1;min-width:0"><b>${esc(o.name || o.citizenid)}</b><small class="bx-mono">${esc(o.citizenid)}</small></div><span class="bx-chip ${o.kind === 'owned' ? 'ok' : 'warn'}">${esc(statusName(o.kind))}</span></div>
  <div class="hb-facts"><div><span>${esc(t('hb_since', null, 'Since'))}</span><b>${esc(XS.date(o.since))}</b></div><div><span>${esc(t('hb_next_due', null, 'Next payment'))}</span><b>${esc(due)}</b></div><div><span>${esc(t('hb_each', null, 'Each payment'))}</span><b>${esc(o.amount ? money(o.amount) : '—')}</b></div><div><span>${esc(t('hb_left_owed', null, 'Left to pay'))}</span><b>${esc(o.balance ? money(o.balance) : '—')}</b></div><div><span>${esc(t('hb_missed', null, 'Missed'))}</span><b>${esc(o.missed || 0)}</b></div><div><span>${esc(t('hb_paid_total', null, 'Paid in total'))}</span><b>${esc(money(o.paid || 0))}</b></div></div>
  <div class="hb-acts"><button class="bx-btn sm" data-act="own" data-a="${o.locked ? 'unlock' : 'lock'}">${I(o.locked ? 'unlock' : 'lock', 14)}${esc(o.locked ? t('hb_unlock', null, 'Unlock') : t('hb_lock', null, 'Lock'))}</button><button class="bx-btn sm" data-act="own" data-a="dues">${esc(t('hb_clear_dues', null, 'Clear missed payments'))}</button><button class="bx-btn sm" data-act="own" data-a="wipe">${esc(t('hb_wipe', null, 'Remove furniture'))}</button>${S.rights.evict ? `<button class="bx-btn sm danger" data-act="own" data-a="evict">${esc(t('hb_evict', null, 'Evict'))}</button><button class="bx-btn sm danger" data-act="own" data-a="reset">${esc(t('hb_reset', null, 'Back to market'))}</button>` : ''}</div>`
        : `<div class="bx-hint">${esc(t('hb_no_owner', null, 'Nobody owns it. It is on the market.'))}</div>`}
  <div class="bx-field" style="margin-top:14px"><label class="bx-label">${esc(o ? t('hb_transfer', null, 'Give it to someone else') : t('hb_set_owner', null, 'Give it to a player'))}</label><div class="bx-picker"><input class="bx-input" id="hb-ownerq" value="${esc(S.ownerQ)}" placeholder="${esc(t('hb_find_player', null, 'Name, citizen id or server id'))}">${S.ownerHits.length ? `<div class="bx-pickpop">${hits(S.ownerHits, 'settransfer')}</div>` : ''}</div></div>
</div></div></div><div>
<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_keys', null, 'Keys'))}</h3><small>${keys.length}</small></div><div class="bx-cardbody">
  ${keys.length ? keys.map((k) => `<div class="hb-keyrow"><div style="flex:1;min-width:0"><b>${esc(k.name || k.citizenid)}</b><small class="bx-mono">${esc(k.citizenid)}${k.expires ? ` · ${esc(t('hb_until', { d: XS.date(k.expires) }, `until ${XS.date(k.expires)}`))}` : ''}</small></div><span class="bx-chip">${esc(t(`hb_role_${k.role}`, null, ({ coowner: 'Co-owner', tenant: 'Tenant', guest: 'Guest' })[k.role] || k.role))}</span><button class="bx-tool danger" data-act="takekey" data-cid="${esc(k.citizenid)}">${I('remove', 13)}</button></div>`).join('') : `<div class="bx-hint">${esc(t('hb_no_keys', null, 'No one else has keys.'))}</div>`}
  ${o ? `<div class="bx-field" style="margin-top:12px"><label class="bx-label">${esc(t('hb_give_key', null, 'Give a key'))}</label><div style="display:flex;gap:6px"><select class="bx-input" id="hb-keyrole" style="width:140px"><option value="coowner">${esc(t('hb_role_coowner', null, 'Co-owner'))}</option><option value="tenant">${esc(t('hb_role_tenant', null, 'Tenant'))}</option><option value="guest">${esc(t('hb_role_guest', null, 'Guest'))}</option></select><div class="bx-picker" style="flex:1"><input class="bx-input" id="hb-keyq" value="${esc(S.keyQ)}" placeholder="${esc(t('hb_find_player', null, 'Name, citizen id or server id'))}">${S.keyHits.length ? `<div class="bx-pickpop">${hits(S.keyHits, 'givekey')}</div>` : ''}</div></div></div>` : ''}
</div></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardbody"><div class="hb-facts"><div><span>${esc(t('hb_furniture', null, 'Furniture'))}</span><b>${esc(p.furniture || 0)}</b></div><div><span>${esc(t('hb_created', null, 'Made'))}</span><b>${esc(XS.date(p.created))}</b></div></div><button class="bx-btn sm" style="margin-top:10px" data-act="placelogs">${I('list', 14)}${esc(t('hb_place_logs', null, 'This place in the logs'))}</button></div></div>
</div></div>`;
    }

    function tabUnits() {
        const d = S.cur;
        if (!S.curId) return `<div class="bx-empty">${I('apartment', 28)}<b>${esc(t('hb_save_first', null, 'Save the place first'))}</b><p>${esc(t('hb_units_save', null, 'Save the building, then add its apartments here.'))}</p></div>`;
        const units = S.props.filter((u) => u.data.type === 'unit' && Number(u.data.building) === S.curId);
        const f = S.unitForm || { count: 6, startAt: 1, perFloor: 0, kind: 'ipl', shell: (S.interiors.shells[0] || {}).model || '', ipl: (S.interiors.ipls.find((i) => i.kind === 'apartment') || {}).id || '', price: 250000, rentPrice: 2500 };
        S.unitForm = f;
        return `<div class="bx-layout"><div><div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_units_list', null, 'Apartments'))}</h3><small>${units.length}</small></div><div class="bx-cardbody">
  ${units.length ? `<table class="bx-table"><tbody>${units.map((u) => `<tr class="click" data-act="edit" data-id="${u.id}"><td class="bx-mono">#${u.id}</td><td><b>${esc(u.data.label)}</b><div class="bx-hint">${esc(t('hb_floor', null, 'Floor'))} ${esc(u.data.floor)}</div></td><td><span class="bx-chip ${u.owner ? 'ok' : 'blue'}">${esc(statusName(statusOf(u)))}</span></td><td class="r bx-mono">${money(u.data.money.price)}</td></tr>`).join('')}</tbody></table>` : `<div class="bx-hint">${esc(t('hb_no_units', null, 'No apartments yet.'))}</div>`}
</div></div></div><div><div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_add_units', null, 'Add apartments'))}</h3></div><div class="bx-cardbody">
  <div class="bx-cols3">${field(t('hb_how_many', null, 'How many'), `<input class="bx-input" type="number" data-uf="count" value="${f.count}" min="1" max="200">`)}${field(t('hb_first_number', null, 'First number'), `<input class="bx-input" type="number" data-uf="startAt" value="${f.startAt}" min="0">`)}${field(t('hb_per_floor', null, 'Per floor'), `<input class="bx-input" type="number" data-uf="perFloor" value="${f.perFloor}" min="0" max="100">`, t('hb_per_floor_hint', null, '0 for one floor'))}</div>
  ${field(t('hb_inside', null, 'Inside'), `<select class="bx-input" data-uf="kind"><option value="ipl" ${f.kind === 'ipl' ? 'selected' : ''}>${esc(t('hb_int_ipl', null, 'GTA interior'))}</option><option value="shell" ${f.kind === 'shell' ? 'selected' : ''}>${esc(t('hb_int_shell', null, 'Shell'))}</option></select>`)}
  ${f.kind === 'ipl' ? field(t('hb_int_ipl', null, 'GTA interior'), `<select class="bx-input" data-uf="ipl">${S.interiors.ipls.map((i) => `<option value="${esc(i.id)}" ${i.id === f.ipl ? 'selected' : ''}>${esc(i.label)}</option>`).join('')}</select>`) : field(t('hb_int_shell', null, 'Shell'), `<select class="bx-input" data-uf="shell">${S.interiors.shells.map((s) => `<option value="${esc(s.model)}" ${s.model === f.shell ? 'selected' : ''}>${esc(s.label)}</option>`).join('')}</select>`)}
  <div class="bx-cols2">${field(t('hb_price', null, 'Price'), `<input class="bx-input" type="number" data-uf="price" value="${f.price}" min="0">`)}${field(t('hb_rent', null, 'Rent'), `<input class="bx-input" type="number" data-uf="rentPrice" value="${f.rentPrice}" min="0">`)}</div>
  <button class="bx-btn primary" data-act="addunits">${I('plus', 15)}${esc(t('hb_make_units', null, 'Make them'))}</button>
  <div class="bx-hint" style="margin-top:8px">${esc(t('hb_units_hint', null, 'Each apartment gets its own owner and a private copy of the inside. Edit any of them afterwards.'))}</div>
</div></div></div></div>`;
    }

    function editor() {
        const d = S.cur;
        if (!d) return overview();
        const tabs = TABS[d.type] || TABS.default;
        if (!tabs.includes(S.tab)) S.tab = tabs[0];
        const list = issues(d, S.curId);
        const steps = [
            [t('hb_step_door', null, 'Door'), d.type === 'unit' ? Number(d.building) > 0 : !!d.door, 'entrance'],
            [t('hb_step_inside', null, 'Inside'), d.type === 'building' || d.interior.kind === 'none' || (d.interior.kind === 'shell' && !!d.interior.shell) || (d.interior.kind === 'ipl' && !!iplOf(d.interior.ipl)) || (d.interior.kind === 'mlo' && d.doors.length > 0), 'interior'],
            [t('hb_step_storage', null, 'Storage'), d.type === 'building' || d.points.storage.length > 0 || d.interior.kind === 'none', 'points'],
            [t('hb_step_price', null, 'Price'), d.type === 'building' || d.money.buy || d.money.rent, 'money'],
        ];
        const counts = { points: POINTS.reduce((n, p) => n + XS.list(d.points[p.key]).length, 0), garage: d.garage.spots.length, people: byId(S.curId) ? XS.list(byId(S.curId).keys).length + (byId(S.curId).owner ? 1 : 0) : 0, units: S.props.filter((u) => u.data.type === 'unit' && Number(u.data.building) === S.curId).length };
        const tabBody = { general: tabGeneral, entrance: tabEntrance, interior: tabInterior, yard: tabYard, garage: tabGarage, points: tabPoints, money: tabMoney, security: tabSecurity, people: tabPeople, units: tabUnits };
        return `<div class="bx-crumb"><button data-act="nav" data-page="${d.type === 'building' ? 'buildings' : 'places'}">${esc(d.type === 'building' ? t('hb_buildings', null, 'Apartment buildings') : t('hb_places', null, 'Places'))}</button>${I('chevron', 12)}<span>${esc(S.curId ? `#${S.curId}` : t('hb_new', null, 'New'))}</span></div>
<div class="bx-edhead"><input class="bx-edname" data-path="label" value="${esc(d.label)}" placeholder="${esc(t('hb_name_ph', null, 'Mirror Park 12'))}" maxlength="64"><span class="bx-sp"></span>
  ${S.curId ? `<button class="bx-btn ghost" data-act="tp" data-id="${S.curId}">${I('goto', 15)}${esc(t('hb_teleport', null, 'Teleport'))}</button><button class="bx-btn ghost" data-act="walk">${I('eye', 15)}${esc(t('hb_walk', null, 'Walk the site'))}</button>${S.rights.delete ? `<button class="bx-btn danger" data-act="delete">${I('remove', 15)}</button>` : ''}` : ''}
  <button class="bx-btn primary" data-act="save" ${S.busy ? 'disabled' : ''}>${I('check', 15)}${esc(S.dirty || !S.curId ? t('hb_save', null, 'Save') : t('hb_saved', null, 'Saved'))}<span class="bx-kbd">Ctrl S</span></button></div>
<div class="bx-edmeta"><span class="bx-chip blue">${I((TYPES.find((x) => x.id === d.type) || {}).icon || 'home', 12)}${esc(typeName(d.type))}</span>${S.curId ? `<span class="bx-chip ${byId(S.curId) && byId(S.curId).owner ? 'ok' : 'blue'}">${esc(statusName(statusOf(byId(S.curId) || {})))}</span>` : ''}${d.enabled === false ? `<span class="bx-chip off">${esc(t('hb_switched_off', null, 'Switched off'))}</span>` : ''}${list.filter((i) => i.level === 'bad').length ? `<span class="bx-chip bad">${I('alert', 12)}${esc(t('hb_n_problems', { n: list.filter((i) => i.level === 'bad').length }, `${list.filter((i) => i.level === 'bad').length} to fix`))}</span>` : ''}</div>
<div class="bx-steps">${steps.map((s) => `<span class="bx-step ${s[1] ? 'done' : 'need'}" data-act="tab" data-tab="${s[2]}" style="cursor:pointer"><i>${I(s[1] ? 'check' : 'alert', 10)}</i>${esc(s[0])}</span>`).join('')}</div>
<div class="bx-tabs">${tabs.map((x) => `<button class="bx-tab ${S.tab === x ? 'on' : ''}" data-act="tab" data-tab="${x}">${I(TAB_ICON[x], 14)}${esc(t(`hb_tab_${x}`, null, TAB_LABEL[x]))}${counts[x] ? `<em>${counts[x]}</em>` : ''}</button>`).join('')}</div>
${(tabBody[S.tab] || tabGeneral)()}
<div style="height:60px"></div>`;
    }

    function quickPage() {
        const shells = byInstalled(S.interiors.shells);
        return `${head(t('hb_quick', null, 'Quick place'), t('hb_quick_sub', null, 'Walk down a street, aim at a front door and press Enter. Each one becomes a place with a price for its area, an address and a square yard. Press Backspace when you are done.'))}
<div class="bx-layout"><div><div class="bx-card"><div class="bx-cardbody">
  ${field(t('hb_quick_shell', null, 'Shell for every house'), `<select class="bx-input" id="hb-quickshell">${shells.map((s) => `<option value="${esc(s.model)}">${esc(s.label)}${installed(s.model) === false ? ` · ${t('hb_not_installed_low', null, 'not installed')}` : (installed(s.model) === null && !s.free ? ' · paid' : '')}</option>`).join('')}</select>`, t('hb_quick_shell_hint', null, 'Change any of them afterwards.'))}
  <button class="bx-btn primary" data-act="quickstart">${I('bolt', 15)}${esc(t('hb_quick_start', null, 'Start'))}</button>
</div></div></div><div><div class="bx-card"><div class="bx-cardbody">
  <div class="hb-howto"><div><span class="bx-kbd">Enter</span><b>${esc(t('hb_qk_place', null, 'Make a place at the spot you aim at'))}</b></div><div><span class="bx-kbd">Backspace</span><b>${esc(t('hb_qk_done', null, 'Finish'))}</b></div></div>
  <div class="bx-hint" style="margin-top:10px">${esc(t('hb_quick_settings', null, 'The type, the inside and the yard come from Settings › Builder.'))}</div>
</div></div></div></div>`;
    }

    function interiorsPage() {
        const isShell = S.intTab === 'shells';
        const q = S.intQ.trim().toLowerCase();
        const n = haveCount();
        const onlyHave = isShell && n > 0 && S.intHave;
        const shells = byInstalled(S.interiors.shells.filter((s) => (!q || `${s.label} ${s.model} ${s.pack}`.toLowerCase().includes(q)) && (!onlyHave || S.have[s.model])));
        const haveBtns = isShell && n > 0 ? `<button class="bx-btn xs ${S.intHave ? 'primary' : 'ghost'}" data-act="inthave" data-v="1">${esc(t('hb_installed', null, 'Installed'))} ${n}</button><button class="bx-btn xs ${S.intHave ? 'ghost' : 'primary'}" data-act="inthave" data-v="0">${esc(t('hb_all', null, 'All'))} ${S.interiors.shells.length}</button>` : '';
        const ipls = S.interiors.ipls.filter((i) => !q || `${i.label} ${i.id} ${i.kind}`.toLowerCase().includes(q));
        const used = (key, val) => S.props.filter((p) => p.data.interior && p.data.interior[key] === val).length;
        return `${head(t('hb_interiors', null, 'Interiors'), t('hb_interiors_sub', null, 'Every shell and GTA interior you can put behind a door. Free shells come with K4MB1’s starter pack. Paid ones need the pack streamed on your server.') + (S.system.screenshot ? ` ${t('hb_interiors_pic', null, 'To give one a picture, press Look, then Enter once you are inside.')}` : ''))}
<div class="bx-listbar"><div class="bx-tabs" style="margin:0"><button class="bx-tab ${isShell ? 'on' : ''}" data-act="inttab" data-tab="shells">${I('warehouse', 14)}${esc(t('hb_shells', null, 'Shells'))}<em>${S.interiors.shells.length}</em></button><button class="bx-tab ${!isShell ? 'on' : ''}" data-act="inttab" data-tab="ipls">${I('building', 14)}${esc(t('hb_gta', null, 'GTA interiors'))}<em>${S.interiors.ipls.length}</em></button></div>
  ${haveBtns ? `<div class="hb-havebtns">${haveBtns}</div>` : ''}<div class="bx-filter">${I('search', 15)}<input class="bx-input" id="hb-intq" value="${esc(S.intQ)}" placeholder="${esc(t('hb_search_any', null, 'Search'))}"></div></div>
${isShell ? noShells() : ''}<div class="hb-cards">${isShell ? shells.map((s) => `<div class="hb-icard ${installed(s.model) === false ? 'hb-missing' : ''}">${picHtml('shell', s.model, true)}<div class="hb-icard-top">${I('warehouse', 20)}${shellChip(s)}</div><b>${esc(s.label)}</b><small class="bx-mono">${esc(s.model)}</small><small>${esc(packLine(s))}</small><div class="hb-icard-foot"><span class="bx-hint">${esc(t('hb_used', { n: used('shell', s.model) }, `used by ${used('shell', s.model)}`))}</span><span class="hb-icard-acts"><button class="bx-btn xs" data-act="intprev" data-kind="shell" data-v="${esc(s.model)}">${I('eye', 12)}${esc(t('hb_look', null, 'Look'))}</button></span></div></div>`).join('')
        : ipls.map((i) => `<div class="hb-icard">${picHtml('ipl', i.id, true)}<div class="hb-icard-top">${I(i.kind === 'office' ? 'office' : (i.kind === 'garage' ? 'garage' : (i.kind === 'house' ? 'home' : 'apartment')), 20)}${i.build ? `<span class="bx-chip warn">${esc(t('hb_build', { n: i.build }, `build ${i.build}+`))}</span>` : (i.needs ? `<span class="bx-chip warn">${esc(i.needs)}</span>` : '<span class="bx-chip ok">base game</span>')}</div><b>${esc(i.label)}</b><small>${esc(i.kind)}${XS.list(i.styles).length ? ` · ${XS.list(i.styles).length} ${esc(t('hb_styles', null, 'styles'))}` : ''}</small>${i.unverified ? `<small class="hb-warnline">${esc(t('hb_check_spawn', null, 'check the spawn'))}</small>` : ''}<div class="hb-icard-foot"><span class="bx-hint">${esc(t('hb_used', { n: used('ipl', i.id) }, `used by ${used('ipl', i.id)}`))}</span><span class="hb-icard-acts"><button class="bx-btn xs" data-act="intprev" data-kind="ipl" data-v="${esc(i.id)}">${I('eye', 12)}${esc(t('hb_look', null, 'Look'))}</button></span></div></div>`).join('')}</div>`;
    }

    function furniturePage() {
        const d = S.catDraft || { overrides: {}, custom: [], multiplier: 1 };
        S.catDraft = d;
        const q = S.catQ.trim().toLowerCase();
        const items = S.catalogue.filter((i) => (S.catCat === 'all' || i.category === S.catCat) && (!q || `${i.label} ${i.model} ${i.id}`.toLowerCase().includes(q)));
        const ov = (id) => d.overrides[id] || {};
        return `${head(t('hb_furniture', null, 'Furniture'), t('hb_furniture_sub', null, 'What owners can buy for inside and for the yard. Change prices, hide items, keep items to a job, or add any prop by its model name.'),
            S.rights.catalogue ? `<button class="bx-btn primary" data-act="catsave">${I('check', 15)}${esc(t('hb_save', null, 'Save'))}</button>` : '')}
<div class="bx-listbar"><div class="bx-filter">${I('search', 15)}<input class="bx-input" id="hb-catq" value="${esc(S.catQ)}" placeholder="${esc(t('hb_search_items', { n: S.catalogue.length }, `Search ${S.catalogue.length} items`))}"></div>
  <select class="bx-input" id="hb-catcat" style="width:180px"><option value="all">${esc(t('hb_all_cats', null, 'All categories'))}</option>${S.categories.map((c) => `<option value="${esc(c.id)}" ${S.catCat === c.id ? 'selected' : ''}>${esc(t(`hb_cat_${c.id}`, null, c.id))}</option>`).join('')}</select>
  <span class="bx-sp"></span><label class="bx-label" style="margin:0">${esc(t('hb_multiplier', null, 'Every price ×'))}</label><input class="bx-input" style="width:90px" type="number" step="0.05" id="hb-catmul" value="${esc(d.multiplier)}"></div>
<div class="bx-card"><table class="bx-table"><thead><tr><th>${esc(t('hb_item', null, 'Item'))}</th><th>${esc(t('hb_category', null, 'Category'))}</th><th>${esc(t('hb_where', null, 'Where'))}</th><th>${esc(t('hb_does', null, 'Does'))}</th><th class="r">${esc(t('hb_price', null, 'Price'))}</th><th>${esc(t('hb_job_only', null, 'Job only'))}</th><th>${esc(t('hb_hidden', null, 'Hidden'))}</th></tr></thead><tbody>
${items.map((i) => `<tr><td><b>${esc(ov(i.id).label || i.label)}</b><div class="bx-hint bx-mono">${esc(i.model)}</div></td><td>${esc(t(`hb_cat_${i.category}`, null, i.category))}</td><td>${esc(t(`hb_where_${i.where}`, null, i.where))}</td><td>${esc(i.use ? t(`hb_use_${i.use}`, null, i.use) : '—')}</td>
<td class="r">${i.custom ? esc(money(i.price)) : `<input class="bx-input sm" style="width:100px;text-align:right" type="number" data-catprice="${esc(i.id)}" value="${esc(ov(i.id).price !== undefined ? ov(i.id).price : '')}" placeholder="${esc(i.price)}">`}</td>
<td>${i.custom ? esc(i.job || '—') : `<input class="bx-input sm" style="width:110px" data-catjob="${esc(i.id)}" value="${esc(ov(i.id).job || '')}">`}</td>
<td>${i.custom ? `<button class="bx-tool danger" data-act="catdel" data-id="${esc(i.id)}">${I('remove', 13)}</button>` : `<span class="bx-switch ${ov(i.id).hidden ? 'on' : ''}" data-act="cathide" data-id="${esc(i.id)}"></span>`}</td></tr>`).join('')}
</tbody></table></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_add_item', null, 'Add your own item'))}</h3></div><div class="bx-cardbody">
  <div class="bx-cols3">${field(t('hb_model', null, 'Model'), '<input class="bx-input mono" id="hb-cm-model" placeholder="prop_couch_01">')}${field(t('hb_label', null, 'Label'), '<input class="bx-input" id="hb-cm-label">')}${field(t('hb_price', null, 'Price'), '<input class="bx-input" type="number" id="hb-cm-price" value="500">')}</div>
  <div class="bx-cols3">${field(t('hb_category', null, 'Category'), `<select class="bx-input" id="hb-cm-cat">${S.categories.map((c) => `<option value="${esc(c.id)}">${esc(t(`hb_cat_${c.id}`, null, c.id))}</option>`).join('')}</select>`)}${field(t('hb_where', null, 'Where'), `<select class="bx-input" id="hb-cm-where"><option value="both">${esc(t('hb_where_both', null, 'Inside and yard'))}</option><option value="inside">${esc(t('hb_where_inside', null, 'Inside'))}</option><option value="yard">${esc(t('hb_where_yard', null, 'Yard'))}</option></select>`)}${field(t('hb_season', null, 'Season'), `<select class="bx-input" id="hb-cm-season"><option value="">${esc(t('hb_all_year', null, 'All year'))}</option>${XS.list(S.seasons).map((s) => `<option value="${esc(s.id)}">${esc(s.label)}</option>`).join('')}</select>`)}${field(t('hb_does', null, 'Does'), `<select class="bx-input" id="hb-cm-use"><option value="">—</option>${['storage', 'safe', 'fridge', 'sit', 'lie', 'wardrobe', 'light', 'music', 'tv'].map((u) => `<option value="${u}">${esc(t(`hb_use_${u}`, null, u))}</option>`).join('')}</select>`)}</div>
  <button class="bx-btn" data-act="catadd">${I('plus', 15)}${esc(t('hb_add', null, 'Add'))}</button>
</div></div>`;
    }

    function agencyPage() {
        const a = S.agency || {};
        return `${head(t('hb_agency', null, 'Real estate agency'), t('hb_agency_sub', { job: a.job || 'realestate' }, `Agents with the ${a.job || 'realestate'} job sell and rent places for commission. Their rights, commission and price range are in Settings › Agency.`))}
<div class="bx-layout"><div><div class="bx-groups">
  <div class="bx-group"><div class="bx-grouph"><span class="bx-gico" style="background:#2dd4bf">${I('tag', 16)}</span><div class="bx-gtext"><b>${esc(t('hb_office', null, 'Office'))}</b><span>${esc(t('hb_office_hint', null, 'Agents open their tablet here. Anyone can collect their old storage here.'))}</span></div></div>
    ${a.office ? `<div class="bx-points"><div class="bx-pt"><span class="bx-ptn">1</span><div class="bx-ptmain"><b>${esc(t('hb_office', null, 'Office'))}</b><small>${esc(pt(a.office))}</small></div><div class="bx-ptacts"><button class="bx-tool" data-act="agtp" data-k="office">${I('goto', 13)}</button></div></div></div>` : ''}
    <div class="bx-addrow"><button class="bx-btn sm" data-act="agplace" data-k="office">${I('crosshair', 14)}${esc(t('hb_place', null, 'Place'))}</button></div></div>
  <div class="bx-group"><div class="bx-grouph"><span class="bx-gico" style="background:#f5a524">${I('box', 16)}</span><div class="bx-gtext"><b>${esc(t('hb_claims_desk', null, 'Storage desk'))}</b><span>${esc(t('hb_claims_hint', null, 'Extra spot for people collecting what they left in a place they lost or sold.'))}</span></div></div>
    ${a.desk ? `<div class="bx-points"><div class="bx-pt"><span class="bx-ptn">1</span><div class="bx-ptmain"><b>${esc(t('hb_claims_desk', null, 'Storage desk'))}</b><small>${esc(pt(a.desk))}</small></div></div></div>` : ''}
    <div class="bx-addrow"><button class="bx-btn sm" data-act="agplace" data-k="desk">${I('crosshair', 14)}${esc(t('hb_place', null, 'Place'))}</button></div></div>
</div></div><div>
  <div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_pending', null, 'Price changes waiting'))}</h3><small>${S.pending.length}</small></div><div class="bx-cardbody">
  ${S.pending.length ? S.pending.map((pd, i) => { const p = byId(pd.id); return `<div class="hb-keyrow"><div style="flex:1;min-width:0"><b>${esc(p ? p.data.label : `#${pd.id}`)}</b><small>${esc(pd.by)} · ${pd.price ? esc(money(pd.price)) : ''} ${pd.rent ? `· ${esc(money(pd.rent))} ${esc(t('hb_rent_short', null, 'rent'))}` : ''}</small></div><button class="bx-btn xs primary" data-act="approve" data-i="${i + 1}" data-yes="1">${esc(t('hb_approve', null, 'Approve'))}</button><button class="bx-btn xs ghost" data-act="approve" data-i="${i + 1}" data-yes="0">${esc(t('hb_decline', null, 'Decline'))}</button></div>`; }).join('') : `<div class="bx-hint">${esc(t('hb_no_pending', null, 'Nothing waiting. Turn on approvals in Settings › Agency to check agents’ price changes.'))}</div>`}
  </div></div>
  <button class="bx-btn" style="margin-top:14px" data-act="gosettings" data-key="Agency.enabled">${I('sliders', 15)}${esc(t('hb_agency_settings', null, 'Agency settings'))}</button>
</div></div>`;
    }

    function toolsPage() {
        const imp = S.imp || {};
        const source = (id, label, hint) => `<div class="hb-import"><div style="flex:1;min-width:0"><b>${esc(label)}</b><div class="bx-hint">${esc(hint)}</div>${imp[id] ? `<div class="hb-impres">${esc(t('hb_imp_found', { n: imp[id].total, o: imp[id].owned, k: imp[id].keys }, `${imp[id].total} places, ${imp[id].owned} owned, ${imp[id].keys} keys`))}${imp[id].noDoor ? ` · ${esc(t('hb_imp_nodoor', { n: imp[id].noDoor }, `${imp[id].noDoor} without a door are skipped`))}` : ''}${imp[id].made !== undefined ? ` · <b>${esc(t('hb_imp_made', { n: imp[id].made }, `${imp[id].made} imported`))}</b>` : ''}</div>` : ''}</div>
            <button class="bx-btn sm" data-act="imp" data-from="${id}">${esc(t('hb_check', null, 'Check'))}</button>${imp[id] && imp[id].made === undefined ? `<button class="bx-btn sm primary" data-act="impgo" data-from="${id}">${esc(t('hb_import', null, 'Import'))}</button>` : ''}</div>`;
        return `${head(t('hb_tools', null, 'Tools'), t('hb_tools_sub', null, 'Bring houses over from another script, find problems, and back up your work.'))}
<div class="bx-layout"><div>
<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_import_t', null, 'Import'))}</h3></div><div class="bx-cardbody">
  ${S.rights.import ? `${source('qb-houses', 'qb-houses', t('hb_imp_qb', null, 'Houses, owners and key holders. Shells follow the tier list in config.lua.'))}${source('qbx_properties', 'qbx_properties', t('hb_imp_qbx', null, 'Properties, owners, key holders and renters.'))}${source('ps-housing', 'ps-housing', t('hb_imp_ps', null, 'Properties, apartments, MLOs, owners, access lists and garages.'))}` : `<div class="bx-hint">${esc(t('hb_no_import_right', null, 'You cannot import.'))}</div>`}
  <div class="bx-hint" style="margin-top:10px">${esc(t('hb_imp_note', null, 'Importing adds new places and never changes the old script’s tables. Stop the old script before people use the new places.'))}</div>
</div></div>
<div class="bx-card" style="margin-top:14px"><div class="bx-cardhead"><h3>${esc(t('hb_backup', null, 'Backup'))}</h3></div><div class="bx-cardbody">
  <button class="bx-btn sm" data-act="export">${I('copy', 14)}${esc(t('hb_export', null, 'Copy every place as text'))}</button>
  ${S.exportText ? `<textarea class="bx-input mono" style="height:140px;margin-top:10px;padding:8px" readonly id="hb-export">${esc(S.exportText)}</textarea>` : ''}
  ${field(t('hb_paste', null, 'Paste places to add them'), '<textarea class="bx-input mono" id="hb-importtext" style="height:90px;padding:8px"></textarea>')}
  <button class="bx-btn sm" data-act="importtext">${I('upload', 14)}${esc(t('hb_add_pasted', null, 'Add these places'))}</button>
</div></div>
</div><div>
<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('hb_problems', null, 'Problems'))}</h3><button class="bx-btn xs ghost" data-act="recheck">${I('refresh', 12)}${esc(t('hb_recheck', null, 'Check again'))}</button></div><div class="bx-cardbody"><div class="bx-issues" style="max-height:520px">
  ${(() => { const out = []; S.props.forEach((p) => issues(normalise(copy(p.data)), p.id).forEach((i) => out.push(`<div class="bx-issue ${i.level}" data-act="edit" data-id="${p.id}" data-tab="${esc(i.tab)}" style="cursor:pointer"><i>${I(i.level === 'bad' ? 'alert' : 'info', 13)}</i><div><b>${esc(i.text)}</b><span>#${p.id} · ${esc(p.data.label)}</span></div></div>`))); return out.length ? out.join('') : `<div class="bx-allgood">${I('check', 16)}${esc(t('hb_all_good', null, 'Everything is set up.'))}</div>`; })()}
</div></div></div></div></div>`;
    }

    function logsPage() {
        return `${head(t('hb_logs', null, 'Logs'), t('hb_logs_sub', null, 'Sales, rent, keys, break-ins, raids and staff changes. Discord webhooks for each are in Settings › Builder.'))}
<div class="bx-listbar"><div class="bx-filter">${I('search', 15)}<input class="bx-input" id="hb-logq" value="${esc(S.logQ)}" placeholder="${esc(t('hb_log_search', null, 'Name, citizen id or text'))}"></div>
  ${LOG_KINDS.map((k) => `<button class="bx-btn xs ${S.logKind === k ? 'primary' : 'ghost'}" data-act="logkind" data-k="${k}">${esc(t(`hb_log_${k}`, null, k[0].toUpperCase() + k.slice(1)))}</button>`).join('')}
  <span class="bx-sp"></span><button class="bx-btn sm" data-act="logload">${I('refresh', 14)}${esc(t('hb_refresh', null, 'Refresh'))}</button></div>
<div class="bx-card"><table class="bx-table"><thead><tr><th>${esc(t('hb_when', null, 'When'))}</th><th>${esc(t('hb_what', null, 'What'))}</th><th>${esc(t('hb_place_col', null, 'Place'))}</th><th>${esc(t('hb_who', null, 'Who'))}</th><th>${esc(t('hb_detail', null, 'Detail'))}</th><th class="r">${esc(t('hb_amount', null, 'Amount'))}</th></tr></thead><tbody>
${S.logs.map((l) => { const p = byId(l.property_id); return `<tr><td class="bx-mono" style="white-space:nowrap">${esc(XS.date(l.at))}</td><td><span class="bx-chip">${esc(t(`hb_lk_${l.kind}`, null, l.kind))}</span></td><td>${p ? `<button class="bx-btn xs ghost" data-act="edit" data-id="${p.id}">#${p.id} ${esc(p.data.label)}</button>` : (l.property_id ? `#${esc(l.property_id)}` : '—')}</td><td>${esc(l.name || l.citizenid || '')}</td><td class="bx-hint">${esc(l.detail || '')}</td><td class="r bx-mono">${l.amount ? esc(money(l.amount)) : ''}</td></tr>`; }).join('') || `<tr><td colspan="6"><div class="bx-hint">${esc(t('hb_no_logs', null, 'Nothing yet.'))}</div></td></tr>`}
</tbody></table></div>`;
    }

    function settingsPage() {
        return '<div id="bx-setmount"></div>';
    }

    function accessPage() {
        const r = S.rights || {};
        const row = (k, label, hint) => `<div class="bx-rowline"><div><b>${esc(label)}</b><div class="bx-hint">${esc(hint)}</div></div><span class="bx-chip ${r[k] ? 'ok' : 'off'}">${esc(r[k] ? t('hb_allowed', null, 'Allowed') : t('hb_not_allowed', null, 'Not allowed'))}</span></div>`;
        return `${head(t('hb_access', null, 'Access'), t('hb_access_sub', null, 'Who can open this builder, and what they can do in it.'))}
<div class="bx-layout"><div><div class="bx-card"><div class="bx-cardbody">
  <div class="hb-code">add_ace group.admin xs.housing.admin allow</div>
  <div class="bx-hint" style="margin-top:8px">${esc(t('hb_access_how', null, 'Add that line to server.cfg for every group that should build. Config.Admin can also list licences and framework groups.'))}</div>
</div></div></div><div><div class="bx-card"><div class="bx-cardbody">
  ${row('prices', t('hb_r_prices', null, 'Change prices'), t('hb_r_prices_hint', null, 'Price, rent and mortgage switches.'))}
  ${row('delete', t('hb_r_delete', null, 'Delete places'), '')}
  ${row('evict', t('hb_r_evict', null, 'Evict and reset owners'), '')}
  ${row('catalogue', t('hb_r_catalogue', null, 'Edit the furniture catalogue'), '')}
  ${row('import', t('hb_r_import', null, 'Import from other scripts'), '')}
  <div class="bx-hint" style="margin-top:10px">${esc(t('hb_rights_where', null, 'Change these in config.lua under Config.Admin.rights.'))}</div>
</div></div></div></div>`;
    }

    function paletteItems() {
        const out = [];
        S.props.forEach((p) => out.push({ group: t('hb_places', null, 'Places'), label: `#${p.id} ${p.data.label}`, sub: [p.data.address.street, p.owner && p.owner.name].filter(Boolean).join(' · '), run: () => edit(p.id) }));
        [['overview', 'Overview'], ['places', 'Places'], ['buildings', 'Apartment buildings'], ['quick', 'Quick place'], ['interiors', 'Interiors'], ['furniture', 'Furniture'], ['agency', 'Real estate agency'], ['tools', 'Tools'], ['logs', 'Logs'], ['settings', 'Settings'], ['access', 'Access']].forEach((x) => out.push({ group: t('hb_pages', null, 'Pages'), label: t(`hb_${x[0]}`, null, x[1]), run: () => go(x[0]) }));
        if (XS.BuilderSettings) XS.BuilderSettings.fields().forEach((f) => out.push({ group: t('hb_settings', null, 'Settings'), label: XS.BuilderSettings.label(f.key), sub: XS.BuilderSettings.sectionLabel(f.section), run: () => { go('settings'); setTimeout(() => XS.BuilderSettings.focus(f.key), 30); } }));
        return out;
    }

    function renderOverlay() {
        const ov = root.querySelector('#bx-ov');
        if (!ov) return;
        const o = S.overlay;
        if (!o) { ov.innerHTML = ''; return; }
        if (o.kind === 'palette') {
            const q = (o.q || '').trim().toLowerCase();
            const all = paletteItems();
            o.list = (q ? all.filter((i) => `${i.label} ${i.sub || ''}`.toLowerCase().includes(q)) : all.slice(0, 30)).slice(0, 60);
            o.idx = Math.min(o.idx || 0, Math.max(0, o.list.length - 1));
            let lastGroup = '';
            ov.innerHTML = `<div class="bx-overlay" data-act="ovclose"><div class="bx-palette" data-stop="1"><div class="bx-palin">${I('search', 17)}<input id="hb-palq" value="${esc(o.q || '')}" placeholder="${esc(t('hb_search', null, 'Search places, settings and pages'))}" autocomplete="off"></div><div class="bx-palres xsp-scroll">${o.list.map((it, i) => { const g = it.group !== lastGroup ? `<div class="bx-palgroup">${esc(it.group)}</div>` : ''; lastGroup = it.group; return `${g}<button class="bx-palitem ${i === o.idx ? 'hl' : ''}" data-act="palrun" data-i="${i}"><b>${esc(it.label)}</b>${it.sub ? `<small>${esc(it.sub)}</small>` : ''}</button>`; }).join('') || `<div class="bx-empty" style="border:none">${esc(t('hb_nothing', null, 'Nothing matches'))}</div>`}</div><div class="bx-palfoot"><span class="bx-kbd">↑↓</span>${esc(t('hb_pal_move', null, 'move'))}<span class="bx-kbd">Enter</span>${esc(t('hb_pal_open', null, 'open'))}<span class="bx-kbd">Esc</span>${esc(t('hb_pal_close', null, 'close'))}</div></div></div>`;
            const input = ov.querySelector('#hb-palq');
            input.focus();
            input.setSelectionRange(input.value.length, input.value.length);
            return;
        }
        if (o.kind === 'modal') {
            ov.innerHTML = `<div class="bx-overlay" data-act="ovclose"><div class="bx-modal" data-stop="1"><h3>${esc(o.title)}</h3><p>${esc(o.text)}</p>${o.input ? `<input class="bx-input" id="hb-modalin" style="margin-top:12px" value="${esc(o.value || '')}" placeholder="${esc(o.placeholder || '')}">` : ''}<div class="acts"><button class="bx-btn ghost" data-act="ovclose">${esc(t('hb_cancel', null, 'Cancel'))}</button><button class="bx-btn ${o.danger ? 'danger' : 'primary'}" data-act="modalok">${esc(o.ok || t('hb_ok', null, 'OK'))}</button></div></div></div>`;
            const i = ov.querySelector('#hb-modalin');
            if (i) i.focus();
        }
    }

    function modal(opts) {
        return new Promise((resolve) => {
            S.overlay = Object.assign({ kind: 'modal' }, opts, { resolve });
            renderOverlay();
        });
    }

    function closeOverlay(result) {
        const o = S.overlay;
        S.overlay = null;
        renderOverlay();
        if (o && o.resolve) o.resolve(result);
    }

    async function confirmLeave() {
        if (!S.dirty) return true;
        const ok = await modal({ title: t('hb_unsaved', null, 'Unsaved changes'), text: t('hb_unsaved_text', null, 'Leave without saving?'), ok: t('hb_leave', null, 'Leave'), danger: true });
        if (ok) S.dirty = false;
        return !!ok;
    }

    async function go(page) {
        if (S.page === 'edit' && page !== 'edit' && !(await confirmLeave())) return;
        S.page = page;
        if (page === 'logs' && !S.logs.length) loadLogs();
        if (page === 'furniture' && !S.catDraft) S.catDraft = null;
        render();
    }

    async function edit(id, tab) {
        if (S.page === 'edit' && S.curId !== id && !(await confirmLeave())) return;
        const p = byId(id);
        if (!p) return;
        S.cur = normalise(copy(p.data));
        S.curId = p.id;
        S.tab = tab || (S.curId === id && S.page === 'edit' ? S.tab : 'general');
        S.page = 'edit';
        S.dirty = false;
        S.photo = null;
        S.keyHits = [];
        S.ownerHits = [];
        S.ownerQ = '';
        S.keyQ = '';
        render();
        if (S.cur.photo === 'stored') {
            const res = await XS.rpc('b:photoOf', { id });
            if (res.ok && S.curId === id) { S.photo = res.data; render(); }
        }
    }

    async function newPlace(type) {
        if (S.page === 'edit' && !(await confirmLeave())) return;
        const res = await XS.rpc('b:here');
        if (res.ok) S.here = res.data;
        S.cur = normalise(blank(type));
        S.curId = null;
        S.tab = 'general';
        S.page = 'edit';
        S.dirty = true;
        S.photo = null;
        render();
    }

    function upsert(rec) {
        if (!rec) return;
        const i = S.props.findIndex((p) => p.id === rec.id);
        if (i >= 0) S.props[i] = rec; else S.props.push(rec);
    }

    async function refresh() {
        const res = await XS.rpc('b:refresh');
        if (res.ok) apply(res.data, true);
    }

    async function save() {
        if (S.page === 'settings') return XS.BuilderSettings.save();
        if (S.page === 'furniture') return saveCatalogue();
        if (S.page !== 'edit' || !S.cur || S.busy) return;
        const a = document.activeElement;
        if (a && a.blur) a.blur();
        if (!S.cur.label.trim()) return XS.toast(t('hb_need_name', null, 'Give it a name first.'), 'error');
        S.busy = true;
        const data = copy(S.cur);
        if (data.yard.shape !== 'custom') data.yard.poly = shape(data.yard.shape, data.yard.center, data.yard.size, data.yard.heading);
        const res = await XS.rpc('b:save', { id: S.curId, data });
        S.busy = false;
        if (!res.ok) return XS.toast(res.error, 'error');
        upsert(res.data);
        S.curId = res.data.id;
        S.cur = normalise(copy(res.data.data));
        S.dirty = false;
        XS.toast(t('hb_saved_toast', null, 'Saved. It is live now.'), 'ok');
        refresh();
        render();
    }

    async function saveCatalogue() {
        const d = S.catDraft;
        if (!d) return;
        const res = await XS.rpc('b:catalogue', { overrides: d.overrides, custom: d.custom, multiplier: Number(d.multiplier) || 1 });
        if (!res.ok) return XS.toast(res.error, 'error');
        S.catalogue = XS.list(res.data.catalogue);
        XS.toast(t('hb_cat_saved', null, 'Catalogue saved.'), 'ok');
        render();
    }

    async function loadLogs(filter) {
        const res = await XS.rpc('b:logs', Object.assign({ kind: S.logKind, q: S.logQ }, filter || {}));
        if (res.ok) { S.logs = XS.list(res.data); if (S.page === 'logs') render(); }
    }

    function changed(redraw) {
        S.dirty = true;
        if (redraw !== false) render();
        else {
            const btn = root.querySelector('[data-act="save"]');
            if (btn) btn.innerHTML = `${I('check', 15)}${esc(t('hb_save', null, 'Save'))}<span class="bx-kbd">Ctrl S</span>`;
        }
    }

    async function place(kind, opts) {
        const res = await XS.rpc('b:place', Object.assign({ kind, property: S.cur }, opts || {}));
        if (!res.ok) { if (res.error) XS.toast(res.error, 'error'); return null; }
        return res.data;
    }

    function listFor(kind) {
        if (kind === 'extraDoors') return S.cur.extraDoors;
        if (kind === 'garageSpots') return S.cur.garage.spots;
        if (kind === 'exit') return S.cur.interior.exit ? [S.cur.interior.exit] : [];
        return S.cur.points[kind];
    }

    function setList(kind, list) {
        if (kind === 'extraDoors') S.cur.extraDoors = list;
        else if (kind === 'garageSpots') S.cur.garage.spots = list;
        else if (kind === 'exit') S.cur.interior.exit = list[0] || null;
        else S.cur.points[kind] = list;
    }

    const PT_MAX = { mailbox: 1, sign: 1, exit: 1 };

    async function onClick(e) {
        const el = e.target.closest('[data-act]');
        if (!el) return;
        if (el.classList.contains('bx-overlay') && e.target !== el) return;
        if (el.tagName === 'TR' && e.target.closest('input,select,textarea,label')) return;
        const act = el.dataset.act;
        const id = el.dataset.id ? Number(el.dataset.id) : null;
        if (el.tagName === 'INPUT' && act !== 'toggle') return;
        switch (act) {
            case 'close': if (await confirmLeave()) XS.close('builder'); break;
            case 'nav':
                if (el.dataset.status) { S.fStatus = el.dataset.status; S.fType = 'all'; }
                go(el.dataset.page);
                break;
            case 'palette': S.overlay = { kind: 'palette', q: '', idx: 0 }; renderOverlay(); break;
            case 'palrun': { const it = S.overlay && S.overlay.list[Number(el.dataset.i)]; closeOverlay(); if (it) it.run(); break; }
            case 'ovclose': closeOverlay(false); break;
            case 'modalok': { const i = root.querySelector('#hb-modalin'); closeOverlay(i ? i.value : true); break; }
            case 'new': newPlace(el.dataset.type); break;
            case 'quickgo': go('quick'); break;
            case 'edit': edit(id, el.dataset.tab); break;
            case 'tab': S.tab = el.dataset.tab; render(); break;
            case 'save': save(); break;
            case 'tp': { const p = byId(id); const door = p && (p.data.door || (byId(p.data.building) || { data: {} }).data.door); if (door) XS.rpc('b:teleport', door); break; }
            case 'doorgo': if (S.cur.door) XS.rpc('b:teleport', S.cur.door); break;
            case 'dup': {
                const p = byId(id);
                if (!p) break;
                const data = copy(p.data);
                data.label = `${data.label} (copy)`;
                data.door = null;
                data.photo = '';
                S.cur = normalise(data);
                S.curId = null;
                S.page = 'edit';
                S.tab = 'entrance';
                S.dirty = true;
                render();
                XS.toast(t('hb_dup_toast', null, 'Copied. Place its door, then save.'), 'ok');
                break;
            }
            case 'delete': {
                const ok = await modal({ title: t('hb_delete_q', null, 'Delete this place?'), text: t('hb_delete_text', null, 'Its owner, keys and furniture go too. This cannot be undone.'), ok: t('hb_delete', null, 'Delete'), danger: true });
                if (!ok) break;
                const res = await XS.rpc('b:delete', { id: S.curId });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                S.props = S.props.filter((p) => p.id !== S.curId);
                S.dirty = false;
                S.cur = null;
                S.curId = null;
                S.page = 'places';
                XS.toast(t('hb_deleted', null, 'Deleted.'), 'ok');
                render();
                break;
            }
            case 'toggle': setPath(S.cur, el.dataset.path, !getPath(S.cur, el.dataset.path)); changed(); break;
            case 'starter': {
                const i = S.cur.tags.indexOf('starter');
                if (i >= 0) S.cur.tags.splice(i, 1); else S.cur.tags.push('starter');
                changed();
                break;
            }
            case 'untag': S.cur.tags.splice(Number(el.dataset.i), 1); changed(); break;
            case 'door': case 'doorhere': {
                let at = null;
                if (act === 'doorhere') { const r = await XS.rpc('b:here'); at = r.ok ? r.data : null; } else at = await place('door', { label: t('hb_front_door', null, 'Front door'), origin: S.cur.door });
                if (!at) break;
                S.cur.door = { x: at.x, y: at.y, z: at.z, w: at.w };
                if (!S.cur.address.street && at.street) S.cur.address.street = at.street;
                if (at.zone) { S.cur.address.zone = at.zone; if (!S.cur.address.area) S.cur.address.area = at.area || ''; }
                if (!S.cur.label && at.street) S.cur.label = at.street;
                changed();
                break;
            }
            case 'ptadd': case 'pthere': {
                const kind = el.dataset.kind;
                const list = listFor(kind).slice();
                if (PT_MAX[kind] && list.length >= PT_MAX[kind]) list.length = 0;
                let at = null;
                if (act === 'pthere') { const r = await XS.rpc('b:here'); at = r.ok ? r.data : null; }
                else at = await place(kind, { label: t(`hb_pt_${kind}`, null, kind), vehicle: kind === 'garageSpots', model: kind === 'garageSpots' ? 'sultan' : (kind === 'sign' ? 'prop_forsale_sign_01' : (kind === 'mailbox' ? 'prop_letterbox_01' : null)) });
                if (!at) break;
                list.push({ x: at.x, y: at.y, z: at.z, w: at.w });
                setList(kind, list);
                changed();
                break;
            }
            case 'ptre': {
                const kind = el.dataset.kind;
                const list = listFor(kind).slice();
                const i = Number(el.dataset.i);
                const at = await place(kind, { label: t(`hb_pt_${kind}`, null, kind), origin: list[i], vehicle: kind === 'garageSpots', model: kind === 'garageSpots' ? 'sultan' : null });
                if (!at) break;
                list[i] = Object.assign(list[i], { x: at.x, y: at.y, z: at.z, w: at.w });
                setList(kind, list);
                changed();
                break;
            }
            case 'ptdel': { const kind = el.dataset.kind; const list = listFor(kind).slice(); list.splice(Number(el.dataset.i), 1); setList(kind, list); changed(); break; }
            case 'ptgo': { const p = listFor(el.dataset.kind)[Number(el.dataset.i)]; if (p) XS.rpc('b:teleport', p); break; }
            case 'intkind': S.cur.interior.kind = el.dataset.kind; if (el.dataset.kind === 'mlo' && S.cur.type === 'house') S.cur.type = 'mlo'; changed(); break;
            case 'pickshell': {
                S.cur.interior.shell = el.dataset.model;
                S.cur.interior.exit = null;
                changed();
                break;
            }
            case 'pickipl': {
                S.cur.interior.ipl = el.dataset.id;
                S.cur.interior.exit = null;
                S.cur.interior.styles = [];
                S.cur.interior.defaultStyle = '';
                changed();
                break;
            }
            case 'defstyle': S.cur.interior.defaultStyle = el.dataset.id; changed(); break;
            case 'preview': {
                const res = await XS.rpc('b:preview', { property: S.cur });
                if (!res.ok) XS.toast(res.error, 'error');
                break;
            }
            case 'intprev': {
                const r = await XS.rpc('b:here');
                const door = r.ok ? r.data : null;
                const prop = { interior: el.dataset.kind === 'shell' ? { kind: 'shell', shell: el.dataset.v } : { kind: 'ipl', ipl: el.dataset.v }, door };
                const res = await XS.rpc('b:preview', { property: prop });
                if (!res.ok) XS.toast(res.error, 'error');
                break;
            }
            case 'pickdoor': {
                const res = await XS.rpc('b:pickDoor');
                if (!res.ok) { if (res.error) XS.toast(res.error, 'error'); break; }
                const d = res.data;
                if (S.cur.doors.some((x) => Math.hypot(x.x - d.x, x.y - d.y) < 0.4)) { XS.toast(t('hb_door_dupe', null, 'That door is already on the list.'), 'error'); break; }
                S.cur.doors.push({ x: d.x, y: d.y, z: d.z, w: d.w, model: d.model, id: d.id || null, label: '' });
                XS.toast(d.id ? t('hb_door_found', { id: d.id }, `Found it in the door lock script (id ${d.id}).`) : t('hb_door_builtin', null, 'Not in a door lock script, so XS-Housing locks it itself.'), 'ok');
                changed();
                break;
            }
            case 'doordel': S.cur.doors.splice(Number(el.dataset.i), 1); changed(); break;
            case 'drawarea': {
                const res = await XS.rpc('b:polygon', { label: t('hb_mlo_area', null, 'Inside area'), origin: S.cur.door, height: 8 });
                if (!res.ok) { if (res.error) XS.toast(res.error, 'error'); break; }
                S.cur.area = { poly: res.data.poly, minZ: res.data.minZ, maxZ: res.data.maxZ };
                changed();
                break;
            }
            case 'showarea': XS.rpc('b:showShape', { poly: S.cur.area.poly, z: S.cur.area.minZ !== null && S.cur.area.minZ !== undefined ? S.cur.area.minZ + 2 : (S.cur.door ? S.cur.door.z - 1 : 0), height: 4 }); break;
            case 'yardshape': S.cur.yard.shape = el.dataset.shape; changed(); break;
            case 'yardcenter': case 'yardhere': {
                let at = null;
                if (act === 'yardhere') { const r = await XS.rpc('b:here'); at = r.ok ? r.data : null; } else at = await place('yard', { label: t('hb_yard_centre', null, 'Yard centre'), origin: S.cur.yard.center || S.cur.door });
                if (!at) break;
                S.cur.yard.center = { x: at.x, y: at.y, z: at.z };
                changed();
                break;
            }
            case 'drawyard': {
                const res = await XS.rpc('b:polygon', { label: t('hb_yard', null, 'Yard'), origin: S.cur.door, height: 2 });
                if (!res.ok) { if (res.error) XS.toast(res.error, 'error'); break; }
                S.cur.yard.poly = res.data.poly;
                S.cur.yard.minZ = res.data.minZ;
                S.cur.yard.maxZ = res.data.maxZ;
                changed();
                break;
            }
            case 'showyard': {
                const y = S.cur.yard;
                const poly = y.shape === 'custom' ? y.poly : shape(y.shape, y.center, y.size, y.heading);
                XS.rpc('b:showShape', { poly, z: ((y.center || S.cur.door || {}).z || 0) - 0.95, height: 2 });
                break;
            }
            case 'areaprice': S.cur.money.price = (S.areaPrices || {})[S.cur.address.zone] || S.cur.money.price; S.cur.money.rentPrice = Math.max(150, Math.floor(S.cur.money.price / 100)); changed(); break;
            case 'photo': {
                const res = await XS.rpc('b:photo');
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                const small = await downscale(res.data, 960, 540);
                const saved = await XS.rpc('b:savePhoto', { id: S.curId, data: small });
                if (!saved.ok) { XS.toast(saved.error, 'error'); break; }
                S.cur.photo = 'stored';
                S.photo = small;
                XS.toast(t('hb_photo_saved', null, 'Photo saved.'), 'ok');
                render();
                break;
            }
            case 'nophoto': S.cur.photo = ''; S.photo = null; changed(); break;
            case 'walk': {
                const d = S.cur;
                const labels = [];
                if (d.door) labels.push(Object.assign({ label: t('hb_front_door', null, 'Front door') }, d.door));
                d.extraDoors.forEach((x, i) => labels.push(Object.assign({ label: `${t('hb_pt_extraDoors', null, 'Extra door')} ${i + 1}` }, x)));
                d.garage.spots.forEach((x, i) => labels.push(Object.assign({ label: `${t('hb_pt_garageSpots', null, 'Parking')} ${i + 1}` }, x)));
                POINTS.filter((x) => !x.inside || d.interior.kind === 'mlo').forEach((def) => XS.list(d.points[def.key]).forEach((x, i) => labels.push(Object.assign({ label: `${t(`hb_pt_${def.key}`, null, def.label)} ${i + 1}` }, x))));
                d.doors.forEach((x, i) => labels.push(Object.assign({ label: x.label || `${t('hb_door', null, 'Door')} ${i + 1}` }, x)));
                const polys = [];
                const yp = d.yard.shape === 'custom' ? d.yard.poly : shape(d.yard.shape, d.yard.center, d.yard.size, d.yard.heading);
                if (d.yard.enabled && yp.length >= 3) polys.push({ poly: yp, z: ((d.yard.center || d.door || {}).z || 0) - 0.95, height: 2 });
                if (d.area.poly.length >= 3) polys.push({ poly: d.area.poly, z: (d.area.minZ || 0) + 2, height: 4 });
                XS.rpc('b:walk', { labels, polys });
                break;
            }
            case 'own': {
                const a = el.dataset.a;
                if (a === 'evict' || a === 'reset' || a === 'wipe') {
                    const ok = await modal({ title: t(`hb_q_${a}`, null, ({ evict: 'Evict the owner?', reset: 'Put it back on the market?', wipe: 'Remove all furniture?' })[a]), text: t(`hb_q_${a}_text`, null, ({ evict: 'They lose the place and keys. Their storage waits at the agency.', reset: 'The owner and keys go, with no storage kept and no refund.', wipe: 'Every item inside and in the yard goes, with no refund.' })[a]), ok: t('hb_yes', null, 'Yes'), danger: true });
                    if (!ok) break;
                }
                const res = await XS.rpc('b:owner', { id: S.curId, action: a });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                XS.toast(t('hb_done', null, 'Done.'), 'ok');
                await refresh();
                break;
            }
            case 'settransfer': {
                const ok = await modal({ title: t('hb_q_transfer', null, 'Give the place to this player?'), text: el.querySelector('b') ? el.querySelector('b').textContent : '', ok: t('hb_yes', null, 'Yes') });
                if (!ok) break;
                const res = await XS.rpc('b:owner', { id: S.curId, action: 'transfer', payload: { citizenid: el.dataset.cid } });
                S.ownerHits = [];
                S.ownerQ = '';
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                XS.toast(t('hb_done', null, 'Done.'), 'ok');
                await refresh();
                break;
            }
            case 'givekey': {
                const role = (root.querySelector('#hb-keyrole') || {}).value || 'guest';
                const res = await XS.rpc('b:owner', { id: S.curId, action: 'givekey', payload: { citizenid: el.dataset.cid, role } });
                S.keyHits = [];
                S.keyQ = '';
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                await refresh();
                break;
            }
            case 'takekey': {
                const res = await XS.rpc('b:owner', { id: S.curId, action: 'takekey', payload: { citizenid: el.dataset.cid } });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                await refresh();
                break;
            }
            case 'placelogs': S.logKind = 'all'; S.logQ = ''; S.page = 'logs'; loadLogs({ property: S.curId }); render(); break;
            case 'addunits': {
                const f = S.unitForm;
                const template = normalise(blank('unit'));
                template.interior = { kind: f.kind, shell: f.shell, ipl: f.ipl, styles: [], defaultStyle: '' };
                template.money.price = Number(f.price) || 0;
                template.money.rentPrice = Number(f.rentPrice) || 0;
                const res = await XS.rpc('b:units', { building: S.curId, template, count: Number(f.count) || 1, startAt: Number(f.startAt) || 1, perFloor: Number(f.perFloor) || 0 });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                XS.toast(t('hb_units_made', { n: XS.list(res.data).length }, `${XS.list(res.data).length} apartments made.`), 'ok');
                await refresh();
                break;
            }
            case 'selnone': S.sel.clear(); render(); break;
            case 'bulk': {
                const [k, v] = el.dataset.p.split(':');
                const patch = {};
                patch[k] = v === '1';
                const res = await XS.rpc('b:bulk', { ids: Array.from(S.sel), patch });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                XS.toast(t('hb_bulk_done', { n: res.data }, `${res.data} changed.`), 'ok');
                await refresh();
                break;
            }
            case 'bulkprice': {
                const v = await modal({ title: t('hb_bulk_price', null, 'Change prices'), text: t('hb_bulk_price_text', null, 'Multiply price and rent by this. 1.1 is ten percent more.'), input: true, value: '1.1', ok: t('hb_apply', null, 'Apply') });
                if (!v || !Number(v)) break;
                const res = await XS.rpc('b:bulk', { ids: Array.from(S.sel), patch: { priceMul: Number(v), rentMul: Number(v) } });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                await refresh();
                break;
            }
            case 'bulktag': {
                const v = await modal({ title: t('hb_bulk_tag', null, 'Add a tag'), text: t('hb_bulk_tag_text', null, 'Starts with a minus to take it off instead.'), input: true, value: '', ok: t('hb_apply', null, 'Apply') });
                if (!v) break;
                const patch = String(v).startsWith('-') ? { removeTag: String(v).slice(1) } : { addTag: String(v) };
                const res = await XS.rpc('b:bulk', { ids: Array.from(S.sel), patch });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                await refresh();
                break;
            }
            case 'inttab': S.intTab = el.dataset.tab; render(); break;
            case 'inthave': S.intHave = el.dataset.v === '1'; render(); break;
            case 'quickstart': XS.rpc('b:quick', { shell: (root.querySelector('#hb-quickshell') || {}).value }); break;
            case 'cathide': { const d = S.catDraft; const o = d.overrides[el.dataset.id] || {}; o.hidden = !o.hidden; d.overrides[el.dataset.id] = o; render(); break; }
            case 'catdel': { const d = S.catDraft; d.custom = d.custom.filter((c) => c.id !== el.dataset.id); S.catalogue = S.catalogue.filter((c) => c.id !== el.dataset.id); render(); break; }
            case 'catadd': {
                const model = (root.querySelector('#hb-cm-model') || {}).value || '';
                if (!model.trim()) { XS.toast(t('hb_need_model', null, 'Type a model name.'), 'error'); break; }
                const item = { id: `c_${Date.now().toString(36)}`, model: model.trim(), label: (root.querySelector('#hb-cm-label') || {}).value || model.trim(), price: Number((root.querySelector('#hb-cm-price') || {}).value) || 0, category: (root.querySelector('#hb-cm-cat') || {}).value || 'decor', where: (root.querySelector('#hb-cm-where') || {}).value || 'both', use: (root.querySelector('#hb-cm-use') || {}).value || null, season: (root.querySelector('#hb-cm-season') || {}).value || null, slots: 20, weight: 50000 };
                S.catDraft.custom.push(item);
                S.catalogue.push(Object.assign({ custom: true }, item));
                XS.toast(t('hb_item_added', null, 'Added. Save to keep it.'), 'ok');
                render();
                break;
            }
            case 'catsave': saveCatalogue(); break;
            case 'agplace': {
                const at = await place('agency', { label: el.dataset.k === 'office' ? t('hb_office', null, 'Office') : t('hb_claims_desk', null, 'Storage desk') });
                if (!at) break;
                const a = Object.assign({}, S.agency);
                a[el.dataset.k] = at;
                const res = await XS.rpc('b:agency', a);
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                S.agency = res.data;
                render();
                break;
            }
            case 'agtp': if (S.agency[el.dataset.k]) XS.rpc('b:teleport', S.agency[el.dataset.k]); break;
            case 'approve': {
                const res = await XS.rpc('b:approve', { index: Number(el.dataset.i), approve: el.dataset.yes === '1' });
                if (res.ok) { S.pending = XS.list(res.data); await refresh(); }
                break;
            }
            case 'gosettings': go('settings'); setTimeout(() => XS.BuilderSettings.focus(el.dataset.key), 40); break;
            case 'imp': case 'impgo': {
                const from = el.dataset.from;
                if (act === 'impgo') {
                    const ok = await modal({ title: t('hb_q_import', { from }, `Import from ${from}?`), text: t('hb_q_import_text', null, 'This adds every place it found. Running it twice makes copies.'), ok: t('hb_import', null, 'Import') });
                    if (!ok) break;
                }
                const res = await XS.rpc('b:import', { from, commit: act === 'impgo' });
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                S.imp[from] = res.data;
                if (act === 'impgo') await refresh(); else render();
                break;
            }
            case 'export': {
                S.exportText = JSON.stringify(S.props.map((p) => { const d = copy(p.data); d.photo = d.photo === 'stored' ? '' : d.photo; return d; }));
                render();
                const ta = root.querySelector('#hb-export');
                if (ta) { ta.select(); try { document.execCommand('copy'); XS.toast(t('hb_copied', null, 'Copied.'), 'ok'); } catch (err) { XS.toast(t('hb_copy_manual', null, 'Select the text and copy it.'), 'error'); } }
                break;
            }
            case 'importtext': {
                const raw = (root.querySelector('#hb-importtext') || {}).value || '';
                let list;
                try { list = JSON.parse(raw); } catch (err) { XS.toast(t('hb_bad_text', null, 'That is not a list of places.'), 'error'); break; }
                if (!Array.isArray(list)) { XS.toast(t('hb_bad_text', null, 'That is not a list of places.'), 'error'); break; }
                let made = 0;
                for (const d of list.slice(0, 500)) {
                    const res = await XS.rpc('b:save', { id: null, data: d });
                    if (res.ok) made++;
                }
                XS.toast(t('hb_pasted_made', { n: made }, `${made} places added.`), 'ok');
                await refresh();
                break;
            }
            case 'recheck': { const res = await XS.rpc('b:problems'); if (res.ok) S.problems = res.data || {}; render(); break; }
            case 'logkind': S.logKind = el.dataset.k; loadLogs(); render(); break;
            case 'logload': loadLogs(); break;
            default: break;
        }
    }

    function downscale(dataUri, w, h) {
        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => {
                const c = document.createElement('canvas');
                const r = Math.min(w / img.width, h / img.height, 1);
                c.width = Math.round(img.width * r);
                c.height = Math.round(img.height * r);
                c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
                resolve(c.toDataURL('image/jpeg', 0.72));
            };
            img.onerror = () => resolve(dataUri);
            img.src = dataUri;
        });
    }

    let searchTimer = null;

    function search(kind, q) {
        clearTimeout(searchTimer);
        searchTimer = setTimeout(async () => {
            if (q.trim().length < 2) { S[kind] = []; render(); return; }
            const res = await XS.rpc('b:players', { q });
            S[kind] = res.ok ? XS.list(res.data) : [];
            render();
            const input = root.querySelector(kind === 'keyHits' ? '#hb-keyq' : '#hb-ownerq');
            if (input) { input.focus(); input.setSelectionRange(input.value.length, input.value.length); }
        }, 280);
    }

    function keepFocus(sel, fn) {
        fn();
        render();
        const input = root.querySelector(sel);
        if (input) { input.focus(); input.setSelectionRange(input.value.length, input.value.length); }
    }

    function onInput(e) {
        const el = e.target;
        if (el.id === 'hb-palq') { S.overlay.q = el.value; S.overlay.idx = 0; renderOverlay(); return; }
        if (el.id === 'bx-q') return keepFocus('#bx-q', () => { S.q = el.value; });
        if (el.id === 'hb-shellq') return keepFocus('#hb-shellq', () => { S.shellQ = el.value; });
        if (el.id === 'hb-iplq') return keepFocus('#hb-iplq', () => { S.iplQ = el.value; });
        if (el.id === 'hb-intq') return keepFocus('#hb-intq', () => { S.intQ = el.value; });
        if (el.id === 'hb-catq') return keepFocus('#hb-catq', () => { S.catQ = el.value; });
        if (el.id === 'hb-logq') { S.logQ = el.value; return; }
        if (el.id === 'hb-keyq') { S.keyQ = el.value; search('keyHits', el.value); return; }
        if (el.id === 'hb-ownerq') { S.ownerQ = el.value; search('ownerHits', el.value); return; }
        if (el.dataset.catprice) { const o = S.catDraft.overrides[el.dataset.catprice] || {}; o.price = el.value === '' ? undefined : Number(el.value); S.catDraft.overrides[el.dataset.catprice] = o; return; }
        if (el.dataset.catjob) { const o = S.catDraft.overrides[el.dataset.catjob] || {}; o.job = el.value || undefined; S.catDraft.overrides[el.dataset.catjob] = o; return; }
        if (el.id === 'hb-catmul') { S.catDraft.multiplier = Number(el.value) || 1; return; }
        if (el.dataset.uf) { S.unitForm[el.dataset.uf] = el.type === 'number' ? Number(el.value) : el.value; return; }
        if (el.dataset.path && S.cur) {
            let v = el.value;
            if (el.dataset.num || el.type === 'number') v = el.value === '' ? 0 : Number(el.value);
            setPath(S.cur, el.dataset.path, v);
            changed(false);
            if (el.dataset.path === 'interior.shell') {
                const st = root.querySelector('#hb-modelstate');
                if (st) st.innerHTML = modelState();
            }
        }
    }

    function onChange(e) {
        const el = e.target;
        if (el.dataset.sel) { const n = Number(el.dataset.sel); if (el.checked) S.sel.add(n); else S.sel.delete(n); render(); return; }
        if (el.dataset.selall) { const list = filtered(S.page === 'buildings'); if (el.checked) list.forEach((p) => S.sel.add(p.id)); else list.forEach((p) => S.sel.delete(p.id)); render(); return; }
        if (el.dataset.style) {
            const list = S.cur.interior.styles;
            const i = list.indexOf(el.dataset.style);
            if (el.checked && i < 0) list.push(el.dataset.style);
            if (!el.checked && i >= 0) list.splice(i, 1);
            changed();
            return;
        }
        if (el.dataset.cat) {
            const list = XS.list(getPath(S.cur, el.dataset.cat)).slice();
            const i = list.indexOf(el.value);
            if (el.checked && i < 0) list.push(el.value);
            if (!el.checked && i >= 0) list.splice(i, 1);
            setPath(S.cur, el.dataset.cat, list);
            changed();
            return;
        }
        if (el.id === 'hb-catcat') { S.catCat = el.value; render(); return; }
        if (el.tagName === 'INPUT' && el.dataset.path && S.cur && S.page === 'edit') { render(); return; }
        if (el.id === 'hb-logq') { loadLogs(); return; }
        if (el.dataset.uf) { S.unitForm[el.dataset.uf] = el.value; render(); return; }
        if (el.tagName === 'SELECT' && el.dataset.path && S.cur) {
            let v = el.value;
            if (el.dataset.num || /^-?\d+$/.test(v) && ['security.lockLevel', 'security.maxLevel', 'building'].includes(el.dataset.path)) v = Number(v);
            setPath(S.cur, el.dataset.path, v);
            if (el.dataset.path === 'type') {
                if (v === 'mlo') S.cur.interior.kind = 'mlo';
                if (v === 'building') S.cur.interior.kind = 'none';
                if (v === 'motel') { S.cur.money.buy = false; S.cur.money.mortgage = false; }
            }
            changed();
        }
    }

    function onKey(e) {
        if (S.overlay && S.overlay.kind === 'palette') {
            const o = S.overlay;
            if (e.key === 'ArrowDown') { o.idx = Math.min((o.list || []).length - 1, (o.idx || 0) + 1); renderOverlay(); e.preventDefault(); return; }
            if (e.key === 'ArrowUp') { o.idx = Math.max(0, (o.idx || 0) - 1); renderOverlay(); e.preventDefault(); return; }
            if (e.key === 'Enter') { const it = (o.list || [])[o.idx || 0]; closeOverlay(); if (it) it.run(); e.preventDefault(); return; }
        }
        if (e.key === 'Enter' && e.target.dataset && e.target.dataset.tagin === 'tags' && S.page === 'edit') {
            const v = e.target.value.trim();
            if (v && S.cur && !S.cur.tags.includes(v) && S.cur.tags.length < 8) { S.cur.tags.push(v.slice(0, 20)); changed(); }
            e.preventDefault();
            return;
        }
        if (e.key === 'Enter' && e.target.id === 'hb-logq') { loadLogs(); return; }
        if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { S.overlay = { kind: 'palette', q: '', idx: 0 }; renderOverlay(); e.preventDefault(); return; }
        if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') { save(); e.preventDefault(); }
    }

    function apply(data, keepPage) {
        data = XS.fix(data || {});
        S.props = XS.list(data.properties).map((p) => { p.data = normalise(p.data || {}); p.keys = XS.list(p.keys); return p; });
        S.interiors = { shells: XS.list((data.interiors || {}).shells), ipls: XS.list((data.interiors || {}).ipls).map((i) => Object.assign(i, { styles: XS.list(i.styles) })) };
        S.catalogue = XS.list(data.catalogue);
        S.seasons = XS.list(data.seasons);
        S.season = data.season || null;
        S.categories = XS.list(data.categories);
        S.stats = data.stats || {};
        S.problems = data.problems || {};
        S.system = data.system || {};
        if (data.found) {
            const found = new Set(XS.list(data.found));
            S.have = {};
            S.interiors.shells.forEach((s) => { S.have[s.model] = found.has(s.model); });
            S.props.forEach((p) => { const i = p.data.interior; if (i && i.kind === 'shell' && i.shell) S.have[i.shell] = found.has(i.shell); });
        } else S.have = null;
        if (data.pictures) S.picKeys = new Set(XS.list(data.pictures));
        S.rights = data.rights || {};
        S.jobs = XS.list(data.jobs);
        S.gangs = XS.list(data.gangs);
        S.agency = data.agency || {};
        S.pending = XS.list(data.pending);
        S.areaPrices = data.areaPrices || {};
        S.me = data.me || {};
        if (data.here) S.here = data.here;
        if (!S.catDraft || !keepPage) {
            const ov = data.catalogueOverrides;
            S.catDraft = { overrides: ov && !Array.isArray(ov) ? copy(ov) : {}, custom: XS.list(data.catalogueCustom).map((c) => copy(c)), multiplier: data.catalogueMultiplier || 1 };
        }
        XS.BuilderSettings.load({ settings: data.settings || {}, jobs: S.jobs, items: [] });
        if (keepPage && S.page === 'edit' && S.curId && !S.dirty) {
            const p = byId(S.curId);
            if (p) S.cur = normalise(copy(p.data));
        }
        if (!keepPage) S.page = 'overview';
    }

    XS.apps.builder = {
        isOpen: () => S.open,
        escape() {
            if (S.overlay) return closeOverlay(false);
            confirmLeave().then((ok) => { if (ok) XS.close('builder'); });
        },
        on(action, data) {
            if (action === 'open') {
                apply(data, false);
                S.open = true;
                shell();
                XS.show('xsp-builder', true);
                render();
            } else if (action === 'reload') {
                apply(data, true);
                render();
            } else if (action === 'show') {
                S.open = true;
                XS.show('xsp-builder', true);
            } else if (action === 'hide') {
                XS.show('xsp-builder', false);
            } else if (action === 'picture') {
                if (!data.kind || !data.value || !data.image) return;
                keepPicture(data.kind, data.value, data.image).then(() => render());
            } else if (action === 'close') {
                S.open = false;
                S.overlay = null;
                XS.show('xsp-builder', false);
            }
        },
    };

    root.addEventListener('click', onClick);
    root.addEventListener('input', onInput);
    root.addEventListener('change', onChange);
    root.addEventListener('keydown', onKey);
})();
