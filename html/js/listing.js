(() => {
    const root = document.getElementById('xsh-listing');
    const t = XS.t;
    const esc = XS.esc;
    const I = (n, s) => XS.icon(n, s || 16);
    const money = (n) => XS.money(n);

    const S = { open: false, d: null, mode: 'buy', quote: null, depositPct: 0, term: 0, photo: null, busy: false, confirm: false };
    const TYPE = { house: 'House', mlo: 'House', unit: 'Apartment', office: 'Office', motel: 'Motel room', garage: 'Garage', building: 'Apartment building' };
    const MODE = { buy: 'Buy', rent: 'Rent', mortgage: 'Mortgage' };

    const prop = () => (S.d && S.d.property) || {};
    const quotes = () => (S.d && S.d.quotes) || {};

    function modes() {
        const q = quotes();
        return ['buy', 'mortgage', 'rent'].filter((m) => q[m]);
    }

    function blocked() {
        const d = S.d;
        if (d.offer) return null;
        if (d.owned) return d.role ? t('lt_yours', null, 'You already live here.') : t('lt_taken', null, 'Someone already lives here.');
        if (!prop().forSale) return t('lt_off_market', null, 'This place is off the market.');
        if (!d.canOwnMore) return d.limitReason || t('lt_limit', null, 'You own as many places as you can.');
        if (!d.selfServe) return t('lt_agents', { n: d.agentsOnDuty }, `${d.agentsOnDuty} estate agents are working. Ask one of them to sell it to you.`);
        return null;
    }

    function facts() {
        const p = prop();
        const pts = p.points || {};
        const out = [];
        const kindLabel = { shell: t('lt_inside_shell', null, 'Interior'), ipl: t('lt_inside_ipl', null, 'Interior'), mlo: t('lt_inside_mlo', null, 'Walk-in'), none: t('lt_inside_none', null, 'Plot only') };
        out.push([I('home', 18), t(`lt_type_${p.type}`, null, TYPE[p.type] || p.type), kindLabel[(p.interior || {}).kind] || '']);
        if (p.yard && p.yard.enabled) out.push([I('tree', 18), t('lt_yard', null, 'Yard'), t(`lt_shape_${p.yard.shape}`, null, p.yard.shape === 'custom' ? 'Garden' : `${Math.round(p.yard.size || 0)} m`)]);
        if (p.garage && p.garage.enabled) out.push([I('garage', 18), t('lt_garage', null, 'Garage'), t('lt_cars', { n: p.garage.max || XS.list(p.garage.spots).length }, `${p.garage.max || XS.list(p.garage.spots).length} cars`)]);
        if (XS.list(pts.storage).length) out.push([I('box', 18), t('lt_storage', null, 'Storage'), t(XS.list(pts.storage).length === 1 ? 'lt_one_spot' : 'lt_n_spots', { n: XS.list(pts.storage).length }, XS.list(pts.storage).length === 1 ? '1 spot' : `${XS.list(pts.storage).length} spots`)]);
        if (XS.list(pts.safe).length) out.push([I('safe', 18), t('lt_safe', null, 'Safe'), t('lt_built_in', null, 'Built in')]);
        if (XS.list(pts.wardrobe).length) out.push([I('shirt', 18), t('lt_wardrobe', null, 'Wardrobe'), t('lt_built_in', null, 'Built in')]);
        if (XS.list(pts.cameras).length) out.push([I('camera', 18), t('lt_cameras', null, 'Cameras'), String(XS.list(pts.cameras).length)]);
        out.push([I('lock', 18), t('lt_lock', null, 'Lock'), t(`lt_lock_${(p.security || {}).lockLevel || 1}`, null, ({ 1: 'Standard', 2: 'Deadbolt', 3: 'Reinforced' })[(p.security || {}).lockLevel || 1])]);
        return out;
    }

    function offerBlock() {
        const o = S.d.offer;
        const q = o.quote || {};
        return `<div class="lt-offer"><div class="lt-stamp">${esc(t('lt_offer', null, 'Offer'))}</div><p>${esc(t('lt_offer_from', { agent: o.agent }, `${o.agent} is offering you this place.`))}</p>
            ${quoteBlock(o.mode, q)}
            <div class="lt-acts"><button class="lt-btn ghost" data-act="decline">${esc(t('lt_decline', null, 'No thanks'))}</button><button class="lt-btn primary" data-act="accept" ${S.busy ? 'disabled' : ''}>${I('check', 16)}${esc(t('lt_accept', null, 'Sign'))}</button></div></div>`;
    }

    function quoteBlock(mode, q) {
        if (!q) return '';
        const row = (k, v, strong) => `<div class="lt-qrow ${strong ? 'strong' : ''}"><span>${esc(k)}</span><b>${esc(v)}</b></div>`;
        if (mode === 'buy') return `<div class="lt-quote">${row(t('lt_price', null, 'Price'), money(q.price))}${q.tax ? row(t('lt_tax', null, 'Tax'), money(q.tax)) : ''}${row(t('lt_pay_today', null, 'You pay today'), money(q.total), true)}</div>`;
        if (mode === 'rent') return `<div class="lt-quote">${row(t('lt_rent', null, 'Rent'), `${money(q.rent)} / ${q.days} ${t('lt_days', null, 'days')}`)}${q.deposit ? row(t('lt_deposit', null, 'Deposit, given back'), money(q.deposit)) : ''}${row(t('lt_pay_today', null, 'You pay today'), money(q.total), true)}</div>`;
        return `<div class="lt-quote">${row(t('lt_price', null, 'Price'), money(q.price))}${row(t('lt_down', { pct: q.depositPct }, `Deposit (${q.depositPct}%)`), money(q.deposit))}${q.tax ? row(t('lt_tax', null, 'Tax'), money(q.tax)) : ''}${row(t('lt_interest', null, 'Interest'), `${q.interest}%`)}${row(t('lt_payments', { n: q.term, days: q.days }, `${q.term} payments, every ${q.days} days`), money(q.each))}${row(t('lt_pay_today', null, 'You pay today'), money(q.total), true)}</div>`;
    }

    function buyBlock() {
        const list = modes();
        const why = blocked();
        if (!list.length) return `<div class="lt-note">${esc(t('lt_not_selling', null, 'Not for sale or rent right now.'))}</div>`;
        if (!list.includes(S.mode)) S.mode = list[0];
        const q = S.quote || quotes()[S.mode];
        const bank = (S.d.money || {}).bank || 0;
        const short = q && q.total > bank;
        let calc = '';
        if (S.mode === 'mortgage' && q) {
            const terms = XS.list(q.terms);
            calc = `<div class="lt-calc"><label>${esc(t('lt_deposit_pick', null, 'Deposit'))}<b>${esc(q.depositPct)}%</b></label><input type="range" id="lt-dep" min="${esc(q.minDepositPct)}" max="100" step="5" value="${esc(q.depositPct)}">
                <label>${esc(t('lt_term', null, 'Payments'))}</label><div class="lt-terms">${terms.map((n) => `<button class="${Number(q.term) === Number(n) ? 'on' : ''}" data-act="term" data-v="${esc(n)}">${esc(n)}</button>`).join('')}</div></div>`;
        }
        return `<div class="lt-modes">${list.map((m) => `<button class="${S.mode === m ? 'on' : ''}" data-act="mode" data-v="${m}">${esc(t(`lt_mode_${m}`, null, MODE[m]))}</button>`).join('')}</div>
            ${calc}${quoteBlock(S.mode, q)}
            <div class="lt-bank">${I('cash', 14)}${esc(t('lt_bank', { amount: money(bank) }, `In your bank: ${money(bank)}`))}${short ? `<em>${esc(t('lt_short', null, 'not enough'))}</em>` : ''}</div>
            ${why ? `<div class="lt-note">${I('info', 16)}${esc(why)}</div>` : (S.confirm ? `<div class="lt-sure"><p>${esc(t(`lt_sure_${S.mode}`, { amount: money(q.total) }, `Pay ${money(q.total)} from your bank?`))}</p><div class="lt-acts"><button class="lt-btn ghost" data-act="nosure">${esc(t('lt_back', null, 'Back'))}</button><button class="lt-btn primary" data-act="acquire" ${S.busy ? 'disabled' : ''}>${I('key', 16)}${esc(t('lt_sign', null, 'Sign and get the keys'))}</button></div></div>`
            : `<button class="lt-btn primary big" data-act="sure" ${short ? 'disabled' : ''}>${I('key', 17)}${esc(t(`lt_go_${S.mode}`, null, ({ buy: 'Buy it', rent: 'Rent it', mortgage: 'Get a mortgage' })[S.mode]))}</button>`)}`;
    }

    function render() {
        const p = prop();
        const d = S.d;
        const addr = [p.address && p.address.number, p.address && p.address.street].filter(Boolean).join(' ');
        const area = p.address && p.address.area;
        const photo = p.photo === 'stored' ? S.photo : p.photo;
        const headline = quotes().buy ? money(quotes().buy.price) : (quotes().rent ? `${money(quotes().rent.rent)}<small> / ${esc(quotes().rent.days)} ${esc(t('lt_days', null, 'days'))}</small>` : '');
        const ribbon = d.owned ? t('lt_sold', null, 'Sold') : (quotes().buy ? t('lt_for_sale', null, 'For sale') : t('lt_to_let', null, 'To let'));
        root.innerHTML = `<div class="xsp-stage"><div class="lt-sheet ${S.fresh ? 'in' : ''}">
<button class="lt-x" data-act="close">${I('close', 18)}</button>
<div class="lt-photo">${photo ? `<img src="${esc(photo)}" alt="">` : `<div class="lt-nophoto">${I('home', 54)}</div>`}<span class="lt-ribbon ${d.owned ? 'sold' : ''}">${esc(ribbon)}</span><div class="lt-tags">${XS.list(p.tags).filter((x) => x !== 'starter').slice(0, 4).map((x) => `<span class="lt-tagp">${esc(x)}</span>`).join('')}</div></div>
<div class="lt-body">
  <div class="lt-left">
    <div class="lt-agency">XS-Housing<span>${esc(t('lt_listing_no', { id: p.id }, `Listing no. ${p.id}`))}</span></div>
    <h1>${esc(p.label)}</h1>
    <div class="lt-addr">${I('pin', 14)}${esc([addr, area].filter(Boolean).join(', '))}</div>
    <div class="lt-price">${headline}</div>
    ${d.description ? `<p class="lt-desc">${esc(d.description)}</p>` : ''}
    <div class="lt-facts">${facts().map((f) => `<div>${f[0]}<b>${esc(f[1])}</b><small>${esc(f[2])}</small></div>`).join('')}</div>
    <div class="lt-acts left">${d.tours && !d.owned && p.forSale ? `<button class="lt-btn" data-act="tour">${I('eye', 16)}${esc(t('lt_tour', { n: d.tourMinutes }, `Look inside · ${d.tourMinutes} min`))}</button>` : ''}<button class="lt-btn ghost" data-act="waypoint">${I('pin', 16)}${esc(t('lt_gps', null, 'GPS'))}</button></div>
  </div>
  <div class="lt-right">${d.offer ? offerBlock() : buyBlock()}</div>
</div></div></div>`;
        S.fresh = false;
    }

    let quoteTimer = null;

    function requote() {
        clearTimeout(quoteTimer);
        quoteTimer = setTimeout(async () => {
            const res = await XS.rpc('listing:quote', { mode: S.mode, opts: { depositPct: S.depositPct, term: S.term } });
            if (res.ok && res.data) { S.quote = res.data; render(); }
        }, 120);
    }

    async function onClick(e) {
        const el = e.target.closest('[data-act]');
        if (!el) return;
        const act = el.dataset.act;
        switch (act) {
            case 'close': XS.close('listing'); break;
            case 'mode': S.mode = el.dataset.v; S.quote = null; S.confirm = false; render(); if (S.mode === 'mortgage') requote(); break;
            case 'term': S.term = Number(el.dataset.v); requote(); break;
            case 'sure': S.confirm = true; render(); break;
            case 'nosure': S.confirm = false; render(); break;
            case 'acquire': case 'accept': {
                if (S.busy) break;
                S.busy = true;
                render();
                const res = await XS.rpc('listing:acquire', { mode: S.mode, opts: { depositPct: S.depositPct, term: S.term } });
                S.busy = false;
                if (!res.ok) { XS.toast(res.error, 'error'); S.confirm = false; render(); }
                break;
            }
            case 'decline': XS.close('listing'); break;
            case 'tour': XS.rpc('listing:tour'); break;
            case 'waypoint': XS.rpc('listing:waypoint'); XS.toast(t('lt_gps_set', null, 'Waypoint set.'), 'ok'); break;
            default: break;
        }
    }

    function onInput(e) {
        if (e.target.id === 'lt-dep') {
            S.depositPct = Number(e.target.value);
            const lbl = e.target.previousElementSibling && e.target.previousElementSibling.querySelector('b');
            if (lbl) lbl.textContent = `${S.depositPct}%`;
            requote();
        }
    }

    XS.apps.listing = {
        isOpen: () => S.open,
        escape() { XS.close('listing'); },
        async on(action, data) {
            if (action === 'open') {
                S.d = data;
                S.d.quotes = data.quotes || {};
                S.mode = data.offer ? data.offer.mode : (modes()[0] || 'buy');
                S.quote = null;
                S.confirm = false;
                S.busy = false;
                S.photo = null;
                const m = S.d.quotes.mortgage;
                S.depositPct = m ? m.depositPct : 0;
                S.term = m ? m.term : 0;
                S.open = true;
                S.fresh = true;
                XS.show('xsh-listing', true);
                render();
                if (prop().photo === 'stored') {
                    const res = await XS.rpc('listing:photo');
                    if (res.ok && S.open) { S.photo = res.data; render(); }
                }
            } else if (action === 'close') {
                S.open = false;
                XS.show('xsh-listing', false);
            }
        },
    };

    root.addEventListener('click', onClick);
    root.addEventListener('input', onInput);
})();
