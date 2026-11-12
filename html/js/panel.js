(() => {
    const root = document.getElementById('xsh-panel');
    const t = XS.t;
    const esc = XS.esc;
    const I = (n, s) => XS.icon(n, s || 18);
    const money = (n) => XS.money(n);

    const S = { open: false, page: 'home', d: null, busy: false, modal: null, clock: null, giveTo: null, role: 'guest', hours: 0, music: '', name: '', camLabel: '', vol: null, loadedAt: Date.now() };
    const PAGES = [
        { id: 'home', icon: 'home' }, { id: 'people', icon: 'people' }, { id: 'money', icon: 'cash' },
        { id: 'security', icon: 'shield' }, { id: 'rooms', icon: 'sofa' }, { id: 'settings', icon: 'gear' },
    ];
    const PAGE_LABEL = { home: 'Home', people: 'People', money: 'Payments', security: 'Security', rooms: 'Rooms', settings: 'Settings' };
    const KIND_LABEL = { owned: 'Owned', rented: 'Renting', mortgage: 'Mortgage', starter: 'Starter apartment' };
    const ROLE_LABEL = { owner: 'Owner', coowner: 'Co-owner', tenant: 'Tenant', guest: 'Guest' };

    const tiles = () => (S.d && S.d.tiles) || {};
    const can = (r) => !!(S.d && S.d.rights && S.d.rights[r]);
    const isOwner = () => S.d && S.d.role === 'owner';
    const prop = () => (S.d && S.d.property) || {};
    const st = () => (S.d && S.d.statement) || {};
    const sec = () => (S.d && S.d.security) || {};

    const THEMES = ['light', 'dark', 'night'];
    const THEME_KEY = 'xsh-panel-theme';
    function themePick() {
        try {
            const v = localStorage.getItem(THEME_KEY);
            if (THEMES.includes(v)) return v;
        } catch (e) {}
        const d = tiles().theme;
        return THEMES.includes(d) ? d : 'night';
    }
    function isDark() {
        const th = themePick();
        if (th !== 'night') return th === 'dark';
        const h = S.clock ? S.clock.h : 12;
        return h >= 20 || h < 6;
    }
    function applyTheme() {
        const el = root.querySelector('#ph-screen');
        if (el) el.classList.toggle('dark', isDark());
    }

    function days(ts) {
        if (!ts) return '—';
        const diff = Number(ts) - Date.now() / 1000;
        if (diff <= 0) return t('ph_due_now', null, 'due now');
        const d = Math.floor(diff / 86400);
        const h = Math.floor((diff % 86400) / 3600);
        return d > 0 ? t('ph_in_days', { d, h }, `in ${d}d ${h}h`) : t('ph_in_hours', { h: Math.max(1, h) }, `in ${Math.max(1, h)}h`);
    }

    function clockText() {
        const c = S.clock || { h: 12, m: 0 };
        return `${String(c.h).padStart(2, '0')}:${String(c.m).padStart(2, '0')}`;
    }

    function greeting() {
        const h = (S.clock || {}).h || 12;
        if (h < 5) return t('ph_night', null, 'Good night');
        if (h < 12) return t('ph_morning', null, 'Good morning');
        if (h < 18) return t('ph_afternoon', null, 'Good afternoon');
        return t('ph_evening', null, 'Good evening');
    }

    function tile(opts) {
        return `<button class="ph-tile ${opts.on ? 'on' : ''} ${opts.tone || ''} ${opts.wide ? 'wide' : ''} ${opts.disabled ? 'dis' : ''}" data-act="${opts.disabled ? '' : opts.act}" ${opts.attr || ''}>
            <span class="ph-tico">${I(opts.icon, 20)}</span>
            <span class="ph-ttext"><b>${esc(opts.title)}</b><small>${esc(opts.state)}</small></span>
            ${opts.extra || ''}</button>`;
    }

    function shell() {
        root.innerHTML = `<div class="xsp-stage"><div class="ph-wall"><div class="ph-device"><div class="ph-lens"></div><div class="ph-screen" id="ph-screen"></div></div><div class="ph-shadow"></div></div></div>`;
    }

    function render() {
        const el = root.querySelector('#ph-screen');
        if (!el || !S.d) return;
        const p = prop();
        const s = st();
        const lights = (S.d.prefs || {}).lights || 'on';
        const name = (S.d.prefs && S.d.prefs.houseName) || p.label;
        const T = tiles();
        const show = { security: T.security !== false, people: T.keys !== false || T.visitors !== false, money: T.bills !== false, settings: T.settings !== false };
        const pages = PAGES.filter((x) => show[x.id] !== false);
        if (!pages.some((x) => x.id === S.page)) S.page = 'home';
        const pageFns = { home, people, money: moneyPage, security, rooms, settings };
        el.innerHTML = `
<div class="ph-wallpaper l-${esc(lights)}"></div>
<header class="ph-top">
  <div class="ph-place"><small>${esc(greeting())}</small><h1>${esc(name)}</h1><span>${esc([p.address && p.address.number, p.address && p.address.street, p.address && p.address.area].filter(Boolean).join(' · '))}</span></div>
  <span class="ph-sp"></span>
  <div class="ph-status">
    <span class="ph-chip ${S.d.locked ? 'ok' : 'warn'}">${I(S.d.locked ? 'lock' : 'unlock', 14)}${esc(S.d.locked ? t('ph_locked', null, 'Locked') : t('ph_unlocked', null, 'Unlocked'))}</span>
    ${sec().alarm > 0 ? `<span class="ph-chip ${sec().armed ? 'ok' : ''}">${I('bell', 14)}${esc(sec().armed ? t('ph_armed', null, 'Armed') : t('ph_disarmed', null, 'Disarmed'))}</span>` : ''}
    ${s.utilitiesOff ? `<span class="ph-chip bad">${I('bolt', 14)}${esc(t('ph_power_off', null, 'Power off'))}</span>` : ''}
    ${s.arrears > 0 ? `<span class="ph-chip bad">${I('alert', 14)}${esc(t('ph_overdue', null, 'Payment overdue'))}</span>` : ''}
  </div>
  <div class="ph-clock"><b>${esc(clockText())}</b><small>${esc(t(`ph_role_${S.d.role}`, null, ROLE_LABEL[S.d.role] || S.d.role))}</small></div>
  <button class="ph-theme" data-act="theme">${I(({ light: 'sun', dark: 'moon', night: 'clock' })[themePick()], 16)}<span>${esc(t(`ph_theme_${themePick()}`, null, ({ light: 'Light', dark: 'Dark', night: 'Auto' })[themePick()]))}</span></button>
  <button class="ph-x" data-act="close">${I('close', 18)}</button>
</header>
<div class="ph-body">
  <nav class="ph-nav">${pages.map((x) => `<button class="${S.page === x.id ? 'on' : ''}" data-act="page" data-page="${x.id}">${I(x.icon, 21)}<span>${esc(t(`ph_page_${x.id}`, null, PAGE_LABEL[x.id]))}</span>${x.id === 'money' && s.arrears > 0 ? '<i class="ph-dot"></i>' : ''}</button>`).join('')}</nav>
  <main class="ph-main xsp-scroll">${(pageFns[S.page] || home)()}</main>
</div>
${S.d.open ? `<div class="ph-banner">${I('alert', 16)}${esc(t('ph_forced', null, 'The front door was forced open. It shuts again soon.'))}</div>` : ''}
${S.modal ? modalHtml() : ''}`;
        applyTheme();
        if (S.modal && S.modal.input) {
            const i = el.querySelector('#ph-modalin');
            if (i) i.focus();
        }
        if (S.page === 'rooms') tickMusic();
    }

    function home() {
        const d = S.d;
        const s = st();
        const se = sec();
        const lights = (d.prefs || {}).lights || 'on';
        const playing = !!(d.prefs || {}).music;
        const musicPaused = playing && !!(d.prefs || {}).musicPaused;
        const visitors = XS.list(d.visitors);
        const last = visitors[0];
        const T = tiles();
        const out = [];
        if (T.lock !== false) out.push(tile({ act: 'lock', icon: d.locked ? 'lock' : 'unlock', title: t('ph_front_door', null, 'Front door'), state: d.locked ? t('ph_locked', null, 'Locked') : t('ph_unlocked', null, 'Unlocked'), on: d.locked, tone: 'teal', wide: true, disabled: !can('lock'), extra: `<span class="ph-switch ${d.locked ? 'on' : ''}"></span>` }));
        if (T.lights !== false) out.push(`<div class="ph-tile wide ${lights !== 'off' ? 'on' : ''} amber ${s.utilitiesOff ? 'dis' : ''}"><span class="ph-tico">${I('bulb', 20)}</span><span class="ph-ttext"><b>${esc(t('ph_lights', null, 'Lights'))}</b><small>${esc(s.utilitiesOff ? t('ph_power_off', null, 'Power off') : t(`ph_lights_${lights}`, null, ({ on: 'On', dim: 'Dimmed', off: 'Off' })[lights]))}</small></span>
            <div class="ph-seg">${['on', 'dim', 'off'].map((x) => `<button class="${lights === x ? 'on' : ''}" data-act="lights" data-v="${x}" ${!can('panel') || s.utilitiesOff ? 'disabled' : ''}>${esc(t(`ph_lights_${x}`, null, ({ on: 'On', dim: 'Dim', off: 'Off' })[x]))}</button>`).join('')}</div></div>`);
        if (se.alarm > 0) out.push(tile({ act: 'arm', icon: 'bell', title: t('ph_alarm', null, 'Alarm'), state: se.armed ? t('ph_armed', null, 'Armed') : t('ph_disarmed', null, 'Disarmed'), on: se.armed, tone: 'red', disabled: !can('security') }));
        if (T.visitors !== false) out.push(tile({ act: 'doorbell', icon: 'bell', title: t('ph_doorbell', null, 'Doorbell'), state: (d.prefs || {}).doorbell ? t('ph_ringing_on', null, 'Rings your phone') : t('ph_silent', null, 'Silent'), on: (d.prefs || {}).doorbell, tone: 'teal', disabled: !can('panel') }));
        if (T.music !== false) out.push(tile({ act: 'page', attr: 'data-page="rooms"', icon: 'music', title: t('ph_music', null, 'Music'), state: playing ? (musicPaused ? t('ph_paused', null, 'Paused') : t('ph_playing', null, 'Playing')) : t('ph_quiet', null, 'Quiet'), on: playing && !musicPaused, tone: 'violet' }));
        if (T.cameras !== false && (XS.list(se.cameras).length || XS.list(se.builtinCameras).length)) out.push(tile({ act: 'cameras', icon: 'camera', title: t('ph_cameras', null, 'Cameras'), state: t('ph_n_cams', { n: XS.list(se.cameras).length + XS.list(se.builtinCameras).length }, `${XS.list(se.cameras).length + XS.list(se.builtinCameras).length} live`), tone: 'teal', disabled: !can('cameras') }));
        if (T.furniture !== false && can('furniture')) out.push(tile({ act: 'furnish', icon: 'sofa', title: t('ph_furnish', null, 'Furnish'), state: t('ph_n_items', { n: d.furniture.count, m: d.furniture.limit }, `${d.furniture.count} / ${d.furniture.limit} items`), tone: 'amber' }));
        if (T.storage !== false) out.push(tile({ act: 'page', attr: 'data-page="rooms"', icon: 'box', title: t('ph_storage', null, 'Storage'), state: t('ph_slots', { n: d.storage.slots }, `${d.storage.slots} slots`), tone: 'teal' }));
        if (d.canOpenHouse) {
            const left = openHouseLeft();
            out.push(tile({ act: 'openhouse', icon: 'door', title: t('ph_open_house', null, 'Open house'), state: left > 0 ? t('ph_open_left', { m: left }, `Open · ${left} min left`) : t('ph_open_off', { m: d.openHouseMinutes }, `Let anyone walk in for ${d.openHouseMinutes} min`), on: left > 0, tone: 'amber' }));
        }
        out.push(tile({ act: 'waypoint', icon: 'pin', title: t('ph_gps', null, 'Mark on GPS'), state: t('ph_gps_sub', null, 'Sets a waypoint'), tone: '' }));
        const pay = s.kind === 'rented' || s.kind === 'mortgage';
        return `<div class="ph-grid">${out.join('')}</div>
<div class="ph-cards">
  ${pay ? `<div class="ph-card ${s.arrears > 0 ? 'bad' : ''}" data-act="page" data-page="money"><small>${esc(s.kind === 'rented' ? t('ph_next_rent', null, 'Next rent') : t('ph_next_mortgage', null, 'Next mortgage payment'))}</small><b>${esc(money(s.amount))}</b><span>${esc(s.arrears > 0 ? t('ph_owe', { amount: money(s.arrears) }, `${money(s.arrears)} overdue`) : days(s.next_due))}</span></div>` : `<div class="ph-card"><small>${esc(t('ph_status', null, 'Status'))}</small><b>${esc(t(`ph_kind_${s.kind}`, null, KIND_LABEL[s.kind] || s.kind || ''))}</b><span>${esc(d.owner && d.owner.since ? t('ph_since', { d: XS.date(d.owner.since).slice(0, 10) }, `since ${XS.date(d.owner.since).slice(0, 10)}`) : '')}</span></div>`}
  <div class="ph-card" data-act="page" data-page="people"><small>${esc(t('ph_keys', null, 'Keys out'))}</small><b>${XS.list(d.keys).length}<em>/${esc(d.maxKeys)}</em></b><span>${esc(XS.list(d.keys).filter((k) => k.online).length ? t('ph_n_online', { n: XS.list(d.keys).filter((k) => k.online).length }, `${XS.list(d.keys).filter((k) => k.online).length} in town`) : t('ph_none_online', null, 'nobody in town'))}</span></div>
  <div class="ph-card" data-act="page" data-page="people"><small>${esc(t('ph_last_visitor', null, 'Last at the door'))}</small><b class="sm">${esc(last ? last.name : t('ph_nobody', null, 'Nobody yet'))}</b><span>${esc(last ? `${last.knock ? t('ph_knocked', null, 'knocked') : t('ph_rang', null, 'rang')} · ${XS.ago(last.at)}` : '')}</span></div>
  <div class="ph-card" data-act="page" data-page="security"><small>${esc(t('ph_lock_level', null, 'Door lock'))}</small><b class="sm">${esc(((XS.list(se.locks)[(se.lock || 1) - 1]) || {}).label || '')}</b><span>${esc(se.lastBreakIn ? t('ph_last_break', { when: XS.date(se.lastBreakIn) }, `break-in ${XS.date(se.lastBreakIn)}`) : t('ph_no_breaks', null, 'no break-ins'))}</span></div>
</div>`;
    }

    function people() {
        const d = S.d;
        const keys = XS.list(d.keys);
        const nearby = XS.list(d.nearby);
        const visitors = XS.list(d.visitors);
        const hours = XS.list(d.guestHours);
        const T = tiles();
        return `<div class="ph-cols">
${T.keys !== false ? `<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_key_holders', null, 'Who has keys'))}</h2><small>${keys.length} / ${esc(d.maxKeys)}</small></div>
  ${can('keys') ? (keys.length ? keys.map((k) => `<div class="ph-row"><span class="ph-av ${k.online ? 'online' : ''}">${esc((k.name || '?').slice(0, 1))}</span><div class="ph-rowt"><b>${esc(k.name || k.citizenid)}</b><small>${esc(t(`ph_role_${k.role}`, null, ROLE_LABEL[k.role] || k.role))}${k.expires ? ` · ${esc(t('ph_until', { when: days(k.expires) }, `ends ${days(k.expires)}`))}` : ''}</small></div><button class="ph-btn ghost sm" data-act="takekey" data-cid="${esc(k.citizenid)}" ${k.role === 'coowner' && !isOwner() ? 'disabled' : ''}>${esc(t('ph_take_key', null, 'Take back'))}</button></div>`).join('') : `<div class="ph-empty">${I('key', 26)}<span>${esc(t('ph_no_keys', null, 'Only you have a key.'))}</span></div>`) : `<div class="ph-empty">${esc(t('ph_no_key_right', null, 'You cannot hand out keys here.'))}</div>`}
  ${isOwner() ? `<button class="ph-btn ghost" data-act="changelocks" style="margin-top:12px">${I('lock', 16)}${esc(t('ph_change_locks', { price: money(d.changeLocksPrice) }, `Change every lock · ${money(d.changeLocksPrice)}`))}</button>` : ''}
</section>` : ''}
${T.keys !== false && can('keys') ? `<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_give_key', null, 'Give a key'))}</h2><button class="ph-btn ghost sm" data-act="nearby">${I('refresh', 14)}${esc(t('ph_look', null, 'Look again'))}</button></div>
  ${nearby.length ? `<div class="ph-people">${nearby.map((n) => `<button class="ph-person ${String(S.giveTo) === String(n.id) ? 'on' : ''}" data-act="giveto" data-id="${esc(n.id)}"><span class="ph-av">${esc((n.name || '?').slice(0, 1))}</span><b>${esc(n.name)}</b><small>#${esc(n.id)}</small></button>`).join('')}</div>` : `<div class="ph-empty">${I('people', 26)}<span>${esc(t('ph_nobody_near', null, 'Nobody is standing near you.'))}</span></div>`}
  ${S.giveTo ? `<div class="ph-form"><label>${esc(t('ph_as', null, 'As'))}</label><div class="ph-seg wide">${['guest', 'tenant'].concat(isOwner() ? ['coowner'] : []).map((r) => `<button class="${S.role === r ? 'on' : ''}" data-act="role" data-v="${r}">${esc(t(`ph_role_${r}`, null, ROLE_LABEL[r]))}</button>`).join('')}</div>
    ${S.role === 'guest' ? `<label>${esc(t('ph_for', null, 'For'))}</label><div class="ph-seg wide">${hours.map((h) => `<button class="${Number(S.hours) === Number(h) ? 'on' : ''}" data-act="hours" data-v="${esc(h)}">${esc(h < 24 ? `${h}h` : `${Math.round(h / 24)}d`)}</button>`).join('')}<button class="${!S.hours ? 'on' : ''}" data-act="hours" data-v="0">${esc(t('ph_forever', null, 'Always'))}</button></div>` : ''}
    <div class="ph-hint">${esc(t(`ph_role_${S.role}_hint`, null, ({ guest: 'Can come in and lock the door.', tenant: 'Can use storage and the wardrobe too.', coowner: 'Can do almost everything you can, except sell.' })[S.role]))}</div>
    <button class="ph-btn primary" data-act="givekey" ${S.busy ? 'disabled' : ''}>${I('key', 16)}${esc(t('ph_hand_key', null, 'Hand over the key'))}</button></div>` : ''}
</section>` : ''}
${T.visitors !== false ? `<section class="ph-panel full"><div class="ph-ph"><h2>${esc(t('ph_visitors', null, 'At the door'))}</h2>${visitors.length && can('panel') ? `<button class="ph-btn ghost sm" data-act="clearvisitors">${esc(t('ph_clear', null, 'Clear'))}</button>` : ''}</div>
  ${visitors.length ? `<div class="ph-log">${visitors.map((v) => `<div class="ph-logrow">${I(v.knock ? 'door' : 'bell', 16)}<b>${esc(v.name)}</b><span>${esc(v.knock ? t('ph_knocked', null, 'knocked') : t('ph_rang', null, 'rang the bell'))}</span><em>${esc(XS.date(v.at))}</em></div>`).join('')}</div>` : `<div class="ph-empty">${esc(t('ph_no_visitors', null, 'Nobody has come by.'))}</div>`}
</section>` : ''}</div>`;
    }

    function moneyPage() {
        const d = S.d;
        const s = st();
        const bills = s.bills || {};
        const ins = d.insurance;
        const kind = s.kind;
        const row = (k, v, cls) => `<div class="ph-fact ${cls || ''}"><span>${esc(k)}</span><b>${esc(v)}</b></div>`;
        let plan = '';
        if (kind === 'rented') {
            plan = `${row(t('ph_rent', null, 'Rent'), `${money(s.amount)} / ${s.rentDays} ${t('ph_days', null, 'days')}`)}${row(t('ph_next_payment', null, 'Next payment'), days(s.next_due))}${row(t('ph_missed', null, 'Missed payments'), `${s.missed || 0} / ${s.evictAfter}`, s.missed ? 'warn' : '')}${s.deposit ? row(t('ph_deposit', null, 'Deposit held'), money(s.deposit)) : ''}`;
        } else if (kind === 'mortgage') {
            plan = `${row(t('ph_payment', null, 'Payment'), `${money(s.amount)} / ${s.mortgageDays} ${t('ph_days', null, 'days')}`)}${row(t('ph_next_payment', null, 'Next payment'), days(s.next_due))}${row(t('ph_left', null, 'Left to pay'), money(s.balance))}${row(t('ph_payments_left', null, 'Payments left'), s.payments_left || 0)}${row(t('ph_missed', null, 'Missed payments'), `${s.missed || 0} / ${s.missedLimit}`, s.missed ? 'warn' : '')}`;
        } else {
            plan = row(t('ph_status', null, 'Status'), t(`ph_kind_${kind}`, null, KIND_LABEL[kind] || kind || ''));
        }

        return `<div class="ph-cols">
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_plan', null, 'Your plan'))}</h2><span class="ph-chip">${esc(t(`ph_kind_${kind}`, null, KIND_LABEL[kind] || kind || ''))}</span></div>
  <div class="ph-facts">${plan}</div>
  ${s.arrears > 0 ? `<div class="ph-alert">${I('alert', 18)}<div><b>${esc(t('ph_overdue_amount', { amount: money(s.arrears) }, `${money(s.arrears)} is overdue`))}</b><small>${esc(kind === 'rented' ? t('ph_overdue_rent', { n: s.evictAfter }, `After ${s.evictAfter} missed payments you are evicted.`) : t('ph_overdue_mortgage', { n: s.missedLimit }, `After ${s.missedLimit} missed payments the bank takes the place back.`))}</small></div><button class="ph-btn primary sm" data-act="pay" ${can('bills') ? '' : 'disabled'}>${esc(t('ph_pay_now', null, 'Pay now'))}</button></div>` : ''}
  ${kind === 'mortgage' && s.payOff ? `<button class="ph-btn" data-act="payoff" ${can('bills') ? '' : 'disabled'}>${I('check', 16)}${esc(t('ph_pay_off', { amount: money(s.balance) }, `Pay it all off · ${money(s.balance)}`))}</button>` : ''}
  ${kind === 'rented' || kind === 'mortgage' ? `<div class="ph-hint">${esc(s.autoPay ? t('ph_autopay', null, 'Payments come out of your bank on their own when you are in town.') : t('ph_manual', null, 'Pay from here before the date.'))}</div>` : ''}

</section>
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_bills', null, 'Bills'))}</h2></div>
  ${s.owed > 0 ? `<div class="ph-alert">${I('alert', 18)}<div><b>${esc(t('ph_bills_owed', { amount: money(s.owed) }, `${money(s.owed)} in unpaid bills`))}</b><small>${esc(s.utilitiesOff ? t('ph_power_cut', null, 'The power is off until you pay.') : t('ph_bills_soon', null, 'Pay before it adds up.'))}</small></div><button class="ph-btn primary sm" data-act="pay" ${can('bills') ? '' : 'disabled'}>${esc(t('ph_pay_now', null, 'Pay now'))}</button></div>` : ''}
  <div class="ph-facts">
    ${bills.tax ? row(t('ph_bill_tax', null, 'Property tax'), days(bills.tax)) : ''}
    ${bills.utilities ? row(t('ph_bill_utilities', null, 'Power and water'), days(bills.utilities)) : ''}
    ${!bills.tax && !bills.utilities ? `<div class="ph-empty">${esc(t('ph_no_bills', null, 'No bills on this place.'))}</div>` : ''}
  </div>
  ${ins ? `<div class="ph-ins"><span class="ph-tico">${I('shield', 20)}</span><div><b>${esc(t('ph_insurance', null, 'Home insurance'))}</b><small>${esc(t('ph_insurance_sub', { price: money(ins.price), days: ins.days, payout: money(ins.payout) }, `${money(ins.price)} every ${ins.days} days. Pays up to ${money(ins.payout)} after a break-in.`))}</small></div><span class="ph-switch ${s.insured ? 'on' : ''} ${can('bills') ? '' : 'dis'}" data-act="${can('bills') ? 'insure' : ''}"></span></div>` : ''}
</section>
<section class="ph-panel full"><div class="ph-ph"><h2>${esc(t('ph_leaving', null, 'Leaving'))}</h2></div>
  ${kind === 'owned' || kind === 'mortgage' ? `<div class="ph-row"><span class="ph-tico">${I('tag', 18)}</span><div class="ph-rowt"><b>${esc(t('ph_sell_back', null, 'Sell it back to the market'))}</b><small>${esc(t('ph_sell_back_sub', { amount: money(s.sellValue), pct: d.sellBackPct }, `You get ${money(s.sellValue)} after what you still owe. Storage waits for you at the agency.`))}</small></div><button class="ph-btn danger sm" data-act="sell" ${can('sell') ? '' : 'disabled'}>${esc(t('ph_sell', null, 'Sell'))}</button></div>` : ''}
  ${kind === 'rented' || kind === 'starter' ? `<div class="ph-row"><span class="ph-tico">${I('door', 18)}</span><div class="ph-rowt"><b>${esc(t('ph_move_out', null, 'Move out'))}</b><small>${esc(kind === 'rented' ? t('ph_move_out_sub', null, 'You get your deposit back if nothing is owed. Storage waits for you at the agency.') : t('ph_move_out_starter', null, 'You give up the free apartment. Storage waits for you at the agency.'))}</small></div><button class="ph-btn danger sm" data-act="moveout" ${isOwner() ? '' : 'disabled'}>${esc(t('ph_move_out_btn', null, 'Move out'))}</button></div>` : ''}
</section></div>`;
    }

    function security() {
        const se = sec();
        const locks = XS.list(se.locks);
        const alarms = XS.list(se.alarms);
        const cams = XS.list(se.cameras);
        const builtin = XS.list(se.builtinCameras);
        const nextLock = locks[se.lock] && se.lock < se.maxLock ? locks[se.lock] : null;
        const nextAlarm = alarms[se.alarm] || null;
        return `<div class="ph-cols">
${se.forced ? `<section class="ph-panel full ph-alert"><div class="ph-ph"><h2>${esc(t('ph_lock_forced', null, 'The front door lock was forced'))}</h2><small>${esc(XS.ago(se.forced))}</small></div>
  <div class="ph-hint">${esc(t('ph_lock_forced_hint', null, 'Someone picked it. Until it is repaired it is as easy to pick as the cheapest lock, and police can see the marks.'))}</div>
  <button class="ph-btn danger ph-mt" data-act="repairlock" ${can('security') ? '' : 'disabled'}>${I('lock', 16)}${esc(Number(se.repairPrice) > 0 ? t('ph_repair_lock', { price: money(se.repairPrice) }, `Repair the lock · ${money(se.repairPrice)}`) : t('ph_repair_lock_free', null, 'Repair the lock'))}</button>
</section>` : ''}
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_door_lock', null, 'Door lock'))}</h2></div>
  <div class="ph-ladder">${locks.slice(0, se.maxLock).map((l, i) => `<div class="ph-step ${i + 1 <= se.lock ? 'done' : ''} ${i + 1 === se.lock ? 'cur' : ''}"><i>${i + 1}</i><div><b>${esc(l.label)}</b><small>${esc(i + 1 <= se.lock ? t('ph_fitted', null, 'Fitted') : money(l.price))}</small></div></div>`).join('')}</div>
  ${nextLock ? `<button class="ph-btn primary" data-act="buylock" ${can('security') ? '' : 'disabled'}>${I('lock', 16)}${esc(t('ph_upgrade_to', { label: nextLock.label, price: money(nextLock.price) }, `Fit a ${nextLock.label} · ${money(nextLock.price)}`))}</button>` : `<div class="ph-hint">${esc(t('ph_best_lock', null, 'This is the best lock this place takes.'))}</div>`}
  <div class="ph-hint">${esc(t('ph_lock_hint', null, 'A better lock makes the lockpick harder and slower.'))}</div>
</section>
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_alarm', null, 'Alarm'))}</h2>${se.alarm > 0 ? `<span class="ph-switch ${se.armed ? 'on' : ''} ${can('security') ? '' : 'dis'}" data-act="${can('security') ? 'arm' : ''}"></span>` : ''}</div>
  ${se.alarmAllowed ? `${se.alarm > 0 ? `<div class="ph-fact"><span>${esc(t('ph_fitted', null, 'Fitted'))}</span><b>${esc((alarms[se.alarm - 1] || {}).label || '')}</b></div><div class="ph-fact"><span>${esc(t('ph_state', null, 'State'))}</span><b>${esc(se.armed ? t('ph_armed', null, 'Armed') : t('ph_disarmed', null, 'Disarmed'))}</b></div>` : `<div class="ph-empty">${I('bell', 26)}<span>${esc(t('ph_no_alarm', null, 'No alarm fitted.'))}</span></div>`}
  ${nextAlarm ? `<button class="ph-btn primary" data-act="buyalarm" ${can('security') ? '' : 'disabled'}>${I('bell', 16)}${esc(t('ph_fit_alarm', { label: nextAlarm.label, price: money(nextAlarm.price) }, `Fit a ${nextAlarm.label} · ${money(nextAlarm.price)}`))}</button>` : ''}
  <div class="ph-hint">${esc(t('ph_alarm_hint', null, 'An armed alarm rings when someone breaks in, tells you, and can call the police.'))}</div>` : `<div class="ph-empty">${esc(t('ph_alarm_not_allowed', null, 'This place cannot take an alarm.'))}</div>`}
</section>
<section class="ph-panel full"><div class="ph-ph"><h2>${esc(t('ph_cameras', null, 'Cameras'))}</h2><small>${cams.length} / ${esc(se.maxCameras)}</small><span class="ph-sp"></span>${cams.length + builtin.length && can('cameras') ? `<button class="ph-btn sm" data-act="cameras">${I('eye', 14)}${esc(t('ph_watch', null, 'Watch'))}</button>` : ''}</div>
  <div class="ph-camgrid">
    ${builtin.map((c, i) => `<div class="ph-cam"><div class="ph-camview">${I('camera', 22)}<span class="ph-rec">LIVE</span></div><b>${esc(c.label || t('ph_cam_n', { n: i + 1 }, `Camera ${i + 1}`))}</b><small>${esc(t('ph_builtin', null, 'Came with the place'))}</small></div>`).join('')}
    ${cams.map((c, i) => `<div class="ph-cam"><div class="ph-camview">${I('camera', 22)}<span class="ph-rec">LIVE</span></div><b>${esc(c.label)}</b>${can('security') ? `<button class="ph-btn ghost sm" data-act="removecam" data-i="${i + 1}">${esc(t('ph_remove', null, 'Remove'))}</button>` : ''}</div>`).join('')}
    ${se.camerasAllowed && cams.length < se.maxCameras && can('security') ? `<button class="ph-cam add" data-act="addcam">${I('plus', 24)}<b>${esc(t('ph_add_cam', null, 'Add a camera'))}</b><small>${esc(money(se.cameraPrice))}</small></button>` : ''}
  </div>
  ${!se.camerasAllowed && !builtin.length ? `<div class="ph-empty">${esc(t('ph_cams_not_allowed', null, 'This place cannot take cameras.'))}</div>` : ''}
</section></div>`;
    }

    function openHouseLeft() {
        const until = Number(S.d && S.d.openHouse) || 0;
        if (!until) return 0;
        const now = (Number(S.d.time) || 0) + (Date.now() - S.loadedAt) / 1000;
        return Math.max(0, Math.ceil((until - now) / 60));
    }

    function clockOf(sec) {
        const s = Math.max(0, Math.floor(Number(sec) || 0));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const r = String(s % 60).padStart(2, '0');
        return h > 0 ? `${h}:${String(m).padStart(2, '0')}:${r}` : `${m}:${r}`;
    }

    function sourceName(url) {
        const k = window.XSMedia ? window.XSMedia.kindOf(url).kind : '';
        if (k === 'youtube') return 'YouTube';
        if (k === 'twitch') return 'Twitch';
        try { return new URL(url).hostname.replace(/^www\./, ''); } catch (err) { return ''; }
    }

    function fallbackTitle(url) {
        const info = window.XSMedia ? window.XSMedia.kindOf(url) : {};
        if (info.kind === 'twitch') return info.channel || t('ph_twitch', null, 'Twitch stream');
        if (info.kind === 'file') return window.XSMedia.fileName(url) || t('ph_song', null, 'Song');
        if (info.kind === 'youtube') return t('ph_yt_video', null, 'YouTube video');
        return sourceName(url) || t('ph_song', null, 'Song');
    }

    const titles = {};
    function lookUpTitle(url) {
        if (!url || titles[url] !== undefined) return;
        titles[url] = '';
        const info = window.XSMedia ? window.XSMedia.kindOf(url) : {};
        if (info.kind !== 'youtube') return;
        fetch(`https://www.youtube.com/oembed?format=json&url=${encodeURIComponent(`https://www.youtube.com/watch?v=${info.id}`)}`)
            .then((r) => (r.ok ? r.json() : null))
            .then((j) => {
                if (!j || !j.title) return;
                titles[url] = String(j.title);
                const el = root.querySelector('#ph-np-title');
                if (el && S.d && (S.d.prefs || {}).music === url) el.textContent = titles[url];
            })
            .catch(() => { });
    }

    function musicCard(music) {
        const p = S.d.prefs || {};
        const ok = can('panel');
        const dis = ok ? '' : 'disabled';
        const paused = !!p.musicPaused;
        const vol = S.vol !== null ? S.vol : Math.max(0, Math.min(100, Number(p.musicVolume) || 0));
        const info = music && window.XSMedia ? window.XSMedia.kindOf(music) : {};
        const art = info.kind === 'youtube' ? `<img src="https://i.ytimg.com/vi/${esc(info.id)}/mqdefault.jpg" alt="">` : I('music', 26);
        if (music) lookUpTitle(music);
        const title = titles[music] || fallbackTitle(music);
        return `<section class="ph-panel ph-music"><div class="ph-ph"><h2>${esc(t('ph_music', null, 'Music'))}</h2>${music && !paused ? '<span class="ph-eq"><i></i><i></i><i></i><i></i></span>' : ''}</div>
  ${music ? `<div class="ph-np">
    <div class="ph-np-art ${info.kind === 'youtube' ? 'img' : ''}">${art}</div>
    <div class="ph-np-text"><b id="ph-np-title">${esc(title)}</b><small>${esc(sourceName(music))} · ${esc(paused ? t('ph_paused', null, 'Paused') : t('ph_playing', null, 'Playing'))}</small></div>
  </div>
  <div class="ph-prog ${ok ? 'can' : ''}" data-act="seek"><i id="ph-np-bar"></i></div>
  <div class="ph-times"><span id="ph-np-cur">0:00</span><span id="ph-np-len"></span></div>
  <div class="ph-np-ctrl">
    <button class="ph-round" data-act="restart" title="${esc(t('ph_restart', null, 'From the start'))}" ${dis}>${I('refresh', 18)}</button>
    <button class="ph-round big" data-act="${paused ? 'resume' : 'pause'}" title="${esc(paused ? t('ph_play', null, 'Play') : t('ph_pause', null, 'Pause'))}" ${dis}>${I(paused ? 'play' : 'pause', 22)}</button>
    <button class="ph-round" data-act="stop" title="${esc(t('ph_stop', null, 'Stop'))}" ${dis}>${I('stopsq', 16)}</button>
    <label class="ph-vol">${I(vol > 0 ? 'volume' : 'mute', 18)}<input type="range" id="ph-vol" min="0" max="100" step="1" value="${vol}" style="--v:${vol}%" ${dis}><em id="ph-vol-n">${vol}</em></label>
  </div>` : `<div class="ph-empty">${I('music', 26)}${esc(t('ph_nothing_on', null, 'Nothing playing'))}</div>`}
  <div class="ph-inrow ph-mt"><input class="ph-input" id="ph-music" value="${esc(S.music)}" placeholder="${esc(t('ph_music_ph', null, 'Paste a YouTube or music link'))}" ${dis}><button class="ph-btn primary" data-act="play" ${dis}>${I('music', 16)}${esc(music ? t('ph_play_this', null, 'Play this') : t('ph_play', null, 'Play'))}</button></div>
  <div class="ph-hint">${esc(t('ph_music_hint', null, 'Plays from the panel on the wall. Everyone inside hears the same song.'))}</div>
</section>`;
    }

    function liveMusic() {
        const p = (S.d && S.d.prefs) || {};
        if (!p.music) return null;
        const live = XS.apps.sound && XS.apps.sound.status(`home_${prop().id}`);
        if (live && live.url === p.music && (live.ready || live.duration > 0)) return live;
        const now = (Number(S.d.time) || 0) + (Date.now() - S.loadedAt) / 1000;
        return { time: p.musicPaused ? Number(p.musicPos) || 0 : Math.max(0, now - (Number(p.musicAt) || now)), duration: 0, title: '', paused: !!p.musicPaused };
    }

    function tickMusic() {
        if (!S.open || S.page !== 'rooms') return;
        const live = liveMusic();
        if (!live) return;
        const len = Number(live.duration) || 0;
        const time = len > 0 ? (Number(live.time) || 0) % len : Number(live.time) || 0;
        const cur = root.querySelector('#ph-np-cur');
        const total = root.querySelector('#ph-np-len');
        const bar = root.querySelector('#ph-np-bar');
        if (cur) cur.textContent = clockOf(time);
        if (total) total.textContent = len > 0 ? clockOf(len) : '';
        if (bar) bar.style.width = len > 0 ? `${Math.min(100, (time / len) * 100)}%` : '0%';
        const music = S.d.prefs.music;
        if (live.title && titles[music] !== live.title) {
            titles[music] = live.title;
            const el = root.querySelector('#ph-np-title');
            if (el) el.textContent = live.title;
        }
    }

    function rooms() {
        const d = S.d;
        const st0 = d.storage || {};
        const up = st0.nextUp;
        const styles = XS.list(d.styles);
        const music = (d.prefs || {}).music || '';
        return `<div class="ph-cols">
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_storage', null, 'Storage'))}</h2><span class="ph-chip">${esc(t('ph_level', { n: (st0.level || 0) + 1 }, `Level ${(st0.level || 0) + 1}`))}</span></div>
  <div class="ph-facts"><div class="ph-fact"><span>${esc(t('ph_slots_t', null, 'Slots'))}</span><b>${esc(st0.slots)}</b></div><div class="ph-fact"><span>${esc(t('ph_weight', null, 'Weight'))}</span><b>${esc(Math.round((st0.weight || 0) / 1000))} kg</b></div><div class="ph-fact"><span>${esc(t('ph_spots', null, 'Storage spots'))}</span><b>${esc(st0.points || 0)}${st0.safes ? ` + ${esc(st0.safes)} ${esc(t('ph_safes', null, 'safe'))}` : ''}</b></div></div>
  ${up ? `<button class="ph-btn primary" data-act="storageup" ${can('security') ? '' : 'disabled'}>${I('box', 16)}${esc(t('ph_storage_up', { slots: up.slots, price: money(up.price) }, `Bigger storage, ${up.slots} slots · ${money(up.price)}`))}</button>` : `<div class="ph-hint">${esc(t('ph_storage_max', null, 'Storage is as big as it gets.'))}</div>`}
</section>
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_furniture', null, 'Furniture'))}</h2><small>${esc(d.furniture.count)} / ${esc(d.furniture.limit)}</small></div>
  <div class="ph-meter"><i style="width:${Math.min(100, (d.furniture.count / Math.max(1, d.furniture.limit)) * 100)}%"></i></div>
  <div class="ph-btnrow">${can('furniture') ? `<button class="ph-btn primary" data-act="furnish" data-where="inside">${I('sofa', 16)}${esc(t('ph_furnish_inside', null, 'Furnish inside'))}</button>${d.furniture.yard ? `<button class="ph-btn" data-act="furnish" data-where="yard">${I('tree', 16)}${esc(t('ph_decorate_yard', null, 'Decorate the yard'))}</button>` : ''}` : `<div class="ph-hint">${esc(t('ph_no_furnish', null, 'You cannot move furniture here.'))}</div>`}</div>
  <div class="ph-hint">${esc(t('ph_furnish_hint', null, 'Inside furniture is placed while you are inside. Storage, safes, lamps, speakers and TVs work once placed.'))}</div>
</section>
${tiles().music !== false ? musicCard(music) : ''}
${styles.length && tiles().style !== false ? `<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_style', null, 'Décor'))}</h2>${d.styleCost ? `<small>${esc(money(d.styleCost))}</small>` : ''}</div>
  <div class="ph-styles">${styles.map((s) => `<button class="ph-style ${d.style === s.id ? 'on' : ''}" data-act="style" data-v="${esc(s.id)}" ${can('style') ? '' : 'disabled'}><i></i><b>${esc(s.label)}</b></button>`).join('')}</div>
  <div class="ph-hint">${esc(t('ph_style_hint', null, 'Changes how the whole place looks for everyone who comes in.'))}</div>
</section>` : ''}
</div>`;
    }

    function settings() {
        const d = S.d;
        return `<div class="ph-cols">
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_name_place', null, 'Name your place'))}</h2></div>
  <div class="ph-inrow"><input class="ph-input" id="ph-name" maxlength="40" value="${esc(S.name || (d.prefs || {}).houseName || '')}" placeholder="${esc(prop().label)}" ${isOwner() ? '' : 'disabled'}><button class="ph-btn primary" data-act="rename" ${isOwner() ? '' : 'disabled'}>${esc(t('ph_save', null, 'Save'))}</button></div>
  <div class="ph-hint">${esc(t('ph_name_hint', null, 'Shown on this screen and on the map for people with keys.'))}</div>
</section>
<section class="ph-panel"><div class="ph-ph"><h2>${esc(t('ph_this_place', null, 'This place'))}</h2></div>
  <div class="ph-facts">
    <div class="ph-fact"><span>${esc(t('ph_address', null, 'Address'))}</span><b>${esc([prop().address && prop().address.number, prop().address && prop().address.street].filter(Boolean).join(' ') || prop().label)}</b></div>
    <div class="ph-fact"><span>${esc(t('ph_owner', null, 'Owner'))}</span><b>${esc((d.owner || {}).name || '')}</b></div>
    <div class="ph-fact"><span>${esc(t('ph_you_are', null, 'You are'))}</span><b>${esc(t(`ph_role_${d.role}`, null, ROLE_LABEL[d.role] || d.role))}</b></div>
    <div class="ph-fact"><span>${esc(t('ph_place_id', null, 'Place number'))}</span><b>#${esc(prop().id)}</b></div>
  </div>
  <button class="ph-btn ghost" data-act="waypoint">${I('pin', 16)}${esc(t('ph_gps', null, 'Mark on GPS'))}</button>
</section></div>`;
    }

    function modalHtml() {
        const m = S.modal;
        return `<div class="ph-modal" data-act="modalno"><div class="ph-mbox" data-stop="1"><span class="ph-mico ${m.danger ? 'bad' : ''}">${I(m.icon || 'info', 22)}</span><h3>${esc(m.title)}</h3><p>${esc(m.text)}</p>${m.input ? `<input class="ph-input" id="ph-modalin" maxlength="32" placeholder="${esc(m.placeholder || '')}">` : ''}<div class="ph-macts"><button class="ph-btn ghost" data-act="modalno">${esc(t('ph_cancel', null, 'Cancel'))}</button><button class="ph-btn ${m.danger ? 'danger' : 'primary'}" data-act="modalyes">${esc(m.ok || t('ph_ok', null, 'OK'))}</button></div></div></div>`;
    }

    function ask(opts) {
        return new Promise((resolve) => { S.modal = Object.assign({}, opts, { resolve }); render(); });
    }

    function answer(v) {
        const m = S.modal;
        S.modal = null;
        render();
        if (m && m.resolve) m.resolve(v);
    }

    async function call(name, payload, okText) {
        if (S.busy) return null;
        S.busy = true;
        const res = await XS.rpc(name, payload);
        S.busy = false;
        if (!res.ok) { XS.toast(res.error, 'error'); render(); return null; }
        if (okText) XS.toast(okText, 'ok');
        return res;
    }

    async function onClick(e) {
        const el = e.target.closest('[data-act]');
        if (!el || !el.dataset.act) return;
        if (el.classList.contains('ph-modal') && e.target !== el) return;
        const act = el.dataset.act;
        const d = S.d;
        switch (act) {
            case 'close': XS.close('panel'); break;
            case 'page': S.page = el.dataset.page; render(); break;
            case 'theme': {
                const next = THEMES[(THEMES.indexOf(themePick()) + 1) % THEMES.length];
                try { localStorage.setItem(THEME_KEY, next); } catch (e) {}
                render();
                break;
            }
            case 'modalno': answer(false); break;
            case 'modalyes': { const i = root.querySelector('#ph-modalin'); answer(i ? (i.value || ' ') : true); break; }
            case 'lock': call('panel:lock', { locked: !d.locked }); break;
            case 'lights': call('panel:pref', { lights: el.dataset.v }); break;
            case 'doorbell': call('panel:pref', { doorbell: !(d.prefs || {}).doorbell }); break;
            case 'arm': call('panel:arm', { on: !sec().armed }); break;
            case 'cameras': call('panel:cameras'); break;
            case 'furnish': call('panel:furnish', { where: el.dataset.where }); break;
            case 'waypoint': call('panel:waypoint', null, t('ph_gps_set', null, 'Waypoint set.')); break;
            case 'nearby': { const res = await XS.rpc('panel:nearby'); if (res.ok) { S.d.nearby = XS.list(res.data); render(); } break; }
            case 'giveto': S.giveTo = el.dataset.id; render(); break;
            case 'role': S.role = el.dataset.v; render(); break;
            case 'hours': S.hours = Number(el.dataset.v) || 0; render(); break;
            case 'givekey': {
                if (!S.giveTo) break;
                const res = await call('panel:giveKey', { target: Number(S.giveTo), role: S.role, hours: S.role === 'guest' ? S.hours : 0 }, t('ph_key_given', null, 'Key handed over.'));
                if (res) S.giveTo = null;
                break;
            }
            case 'takekey': call('panel:takeKey', { citizenid: el.dataset.cid }, t('ph_key_taken', null, 'Key taken back.')); break;
            case 'changelocks': if (await ask({ title: t('ph_q_locks', null, 'Change every lock?'), text: t('ph_q_locks_text', { price: money(d.changeLocksPrice) }, `Everyone else loses their key. Costs ${money(d.changeLocksPrice)}.`), icon: 'lock', ok: t('ph_change', null, 'Change'), danger: true })) call('panel:changeLocks', null, t('ph_locks_changed', null, 'Locks changed.')); break;
            case 'clearvisitors': call('panel:pref', { clearVisitors: true }); break;
            case 'pay': call('panel:pay', null, t('ph_paid', null, 'Paid.')); break;
            case 'payoff': if (await ask({ title: t('ph_q_payoff', null, 'Pay off the mortgage?'), text: t('ph_q_payoff_text', { amount: money(st().balance) }, `${money(st().balance)} comes out of your bank and the place is yours.`), icon: 'cash', ok: t('ph_pay', null, 'Pay') })) call('panel:payOff', null, t('ph_paid_off', null, 'It is all yours now.')); break;
            case 'insure': call('panel:insure', { on: !st().insured }); break;
            case 'sell': if (await ask({ title: t('ph_q_sell', null, 'Sell this place?'), text: t('ph_q_sell_text', { amount: money(st().sellValue) }, `You get ${money(st().sellValue)}. Everyone loses their keys. This cannot be undone.`), icon: 'tag', ok: t('ph_sell', null, 'Sell'), danger: true })) call('panel:sell'); break;
            case 'moveout': if (await ask({ title: t('ph_q_moveout', null, 'Move out?'), text: t('ph_q_moveout_text', null, 'You give the place up. Anything left in storage waits for you at the agency.'), icon: 'door', ok: t('ph_move_out_btn', null, 'Move out'), danger: true })) call('panel:moveOut'); break;
            case 'repairlock': call('panel:repairLock', null, t('ph_lock_repaired', null, 'Lock repaired.')); break;
            case 'buylock': call('panel:buyLock', null, t('ph_lock_fitted', null, 'New lock fitted.')); break;
            case 'buyalarm': call('panel:buyAlarm', null, t('ph_alarm_fitted', null, 'Alarm fitted.')); break;
            case 'addcam': {
                const label = await ask({ title: t('ph_q_cam', null, 'Name the camera'), text: t('ph_q_cam_text', { price: money(sec().cameraPrice) }, `Then aim it where you want it. Costs ${money(sec().cameraPrice)}.`), icon: 'camera', input: true, placeholder: t('ph_cam_ph', null, 'Driveway'), ok: t('ph_place_it', null, 'Place it') });
                if (label) call('panel:addCamera', { label: String(label).trim() });
                break;
            }
            case 'removecam': if (await ask({ title: t('ph_q_removecam', null, 'Remove this camera?'), text: t('ph_q_removecam_text', null, 'You do not get the money back.'), icon: 'camera', ok: t('ph_remove', null, 'Remove'), danger: true })) call('panel:removeCamera', { index: Number(el.dataset.i) }); break;
            case 'storageup': call('panel:storageUpgrade', null, t('ph_storage_bigger', null, 'Storage made bigger.')); break;
            case 'play': {
                const v = ((root.querySelector('#ph-music') || {}).value || '').trim();
                if (!v) break;
                const res = await call('panel:pref', { music: v });
                if (res) { S.music = ''; render(); }
                break;
            }
            case 'stop': call('panel:pref', { music: '' }); break;
            case 'pause': call('panel:pref', { musicPaused: true }); break;
            case 'resume': call('panel:pref', { musicPaused: false }); break;
            case 'restart': call('panel:pref', { musicSeek: 0 }); break;
            case 'openhouse': call('panel:openHouse', { on: openHouseLeft() <= 0 }, openHouseLeft() <= 0 ? t('ph_open_started', null, 'The door is open. Anyone can walk in.') : t('ph_open_stopped', null, 'Open house ended.')); break;
            case 'seek': {
                if (!can('panel')) break;
                const live = liveMusic();
                const len = live ? Number(live.duration) || 0 : 0;
                if (!(len > 0)) break;
                const r = el.getBoundingClientRect();
                const f = Math.max(0, Math.min(1, (e.clientX - r.left) / Math.max(1, r.width)));
                call('panel:pref', { musicSeek: Math.floor(f * len) });
                break;
            }
            case 'style': if (await ask({ title: t('ph_q_style', null, 'Change the décor?'), text: d.styleCost ? t('ph_q_style_text', { price: money(d.styleCost) }, `Costs ${money(d.styleCost)}.`) : t('ph_q_style_free', null, 'It changes right away.'), icon: 'sofa', ok: t('ph_change', null, 'Change') })) call('panel:style', { style: el.dataset.v }, t('ph_style_done', null, 'Décor changed.')); break;
            case 'rename': { const v = (root.querySelector('#ph-name') || {}).value || ''; S.name = v; call('panel:pref', { houseName: v.trim() }, t('ph_renamed', null, 'Name saved.')); break; }
            default: break;
        }
    }


    function onInput(e) {
        if (e.target.id === 'ph-music') S.music = e.target.value;
        if (e.target.id === 'ph-vol') {
            S.vol = Number(e.target.value) || 0;
            e.target.style.setProperty('--v', `${S.vol}%`);
            const n = root.querySelector('#ph-vol-n');
            if (n) n.textContent = String(S.vol);
        }
        if (e.target.id === 'ph-name') S.name = e.target.value;
    }

    async function onChange(e) {
        if (e.target.id !== 'ph-vol') return;
        const v = Number(e.target.value) || 0;
        const res = await call('panel:pref', { musicVolume: v });
        if (!res) { S.vol = null; render(); }
    }

    function onKey(e) {
        if (e.key === 'Enter' && S.modal) { const i = root.querySelector('#ph-modalin'); answer(i ? (i.value || ' ') : true); e.preventDefault(); }
    }

    let timer = null;
    let musicTimer = null;

    function tickClock() {
        clearInterval(timer);
        timer = setInterval(() => {
            if (!S.open || !S.clock) return;
            S.clock.m += 1;
            if (S.clock.m >= 60) { S.clock.m = 0; S.clock.h = (S.clock.h + 1) % 24; }
            const c = root.querySelector('.ph-clock b');
            if (c) c.textContent = clockText();
            applyTheme();
        }, 2000);
    }

    function load(data, keep) {
        S.d = data;
        S.d.keys = XS.list(data.keys);
        S.d.nearby = XS.list(data.nearby);
        S.d.visitors = XS.list(data.visitors);
        S.d.styles = XS.list(data.styles);
        S.d.guestHours = XS.list(data.guestHours);
        S.d.prefs = data.prefs || {};
        S.d.furniture = data.furniture || { count: 0, limit: 0 };
        S.d.storage = data.storage || {};
        S.loadedAt = Date.now();
        S.vol = null;
        if (data.hour !== undefined) S.clock = { h: Number(data.hour) || 0, m: Number(data.minute) || 0 };
        if (!keep) { S.page = 'home'; S.giveTo = null; S.role = 'guest'; S.hours = 0; S.music = ''; S.name = ''; S.modal = null; }
    }

    XS.apps.panel = {
        isOpen: () => S.open,
        escape() {
            if (S.modal) return answer(false);
            XS.close('panel');
        },
        on(action, data) {
            if (action === 'open') {
                load(data, false);
                S.open = true;
                shell();
                XS.show('xsh-panel', true);
                render();
                tickClock();
                clearInterval(musicTimer);
                musicTimer = setInterval(tickMusic, 500);
            } else if (action === 'update') {
                load(data, true);
                render();
            } else if (action === 'close') {
                S.open = false;
                S.modal = null;
                clearInterval(timer);
                clearInterval(musicTimer);
                XS.show('xsh-panel', false);
            }
        },
    };

    root.addEventListener('click', onClick);
    root.addEventListener('input', onInput);
    root.addEventListener('change', onChange);
    root.addEventListener('keydown', onKey);
})();
