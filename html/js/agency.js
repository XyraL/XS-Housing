(() => {
    const root = document.getElementById('xsh-agency');
    const t = XS.t;
    const esc = XS.esc;
    const I = (n, s) => XS.icon(n, s || 16);
    const money = (n) => XS.money(n);

    const S = { open: false, d: null, page: 'listings', filter: 'sale', q: '', sel: null, photos: {}, price: '', rent: '', target: null, mode: 'buy', term: 0, depositPct: 0, busy: false };
    const STATUS = { sale: 'For sale', owned: 'Owned', rented: 'Rented', mortgage: 'Mortgage', starter: 'Starter' };
    const TYPE = { house: 'House', mlo: 'House', unit: 'Apartment', office: 'Office', motel: 'Motel room', garage: 'Garage' };

    const can = (r) => !!(S.d && S.d.rights && S.d.rights[r]);
    const list = () => XS.list(S.d && S.d.list);
    const cur = () => list().find((p) => p.id === S.sel);

    function filtered() {
        const q = S.q.trim().toLowerCase();
        return list().filter((p) => {
            if (S.filter === 'sale' && !(p.status === 'sale' && p.listed !== false && p.enabled !== false)) return false;
            if (S.filter === 'unlisted' && !(p.status === 'sale' && (p.listed === false || p.enabled === false))) return false;
            if (S.filter === 'taken' && p.status === 'sale') return false;
            if (S.filter === 'late' && !(p.owner && p.owner.missed > 0)) return false;
            if (!q) return true;
            return `${p.id} ${p.label} ${(p.address || {}).street || ''} ${(p.address || {}).area || ''} ${(p.owner || {}).name || ''}`.toLowerCase().includes(q);
        });
    }

    function stats() {
        const all = list();
        const sales = XS.list(S.d.sales);
        const week = Date.now() / 1000 - 7 * 86400;
        return {
            sale: all.filter((p) => p.status === 'sale' && p.listed !== false && p.enabled !== false).length,
            taken: all.filter((p) => p.status !== 'sale').length,
            late: all.filter((p) => p.owner && p.owner.missed > 0).length,
            earned: sales.filter((s) => Number(s.at) > week).reduce((n, s) => n + (Number(s.amount) || 0), 0),
        };
    }

    function openHouseLeft(p) {
        const until = Number(p.openHouse) || 0;
        if (!until) return 0;
        const now = (Number(S.d.now) || 0) + (Date.now() - (S.loadedAt || Date.now())) / 1000;
        return Math.max(0, Math.ceil((until - now) / 60));
    }

    function openHouseCard(p) {
        const left = openHouseLeft(p);
        return `<div class="bx-card"><div class="bx-cardbody"><div class="bx-rowline"><div><b>${esc(t('ag_open_house', null, 'Open house'))}</b><div class="bx-hint">${esc(left > 0 ? t('ag_open_left', { m: left }, `Open now · ${left} min left. Anyone can walk in.`) : t('ag_open_hint', { m: S.d.openHouseMinutes }, `Open the door for ${S.d.openHouseMinutes} min so anyone can walk through.`))}</div></div><span class="bx-switch ${left > 0 ? 'on' : ''}" data-act="openhouse"></span></div></div></div>`;
    }

    function detail() {
        const p = cur();
        if (!p) return `<div class="bx-empty" style="height:100%">${I('home', 30)}<b>${esc(t('ag_pick', null, 'Pick a place'))}</b><p>${esc(t('ag_pick_hint', null, 'Change its price, list it, or offer it to someone standing next to you.'))}</p></div>`;
        const photo = p.photo === 'stored' ? S.photos[p.id] : p.photo;
        const range = Number(S.d.rangePct) || 0;
        const base = Number(p.basePrice) || Number(p.price) || 0;
        const nearby = XS.list(S.d.nearby);
        const forSale = p.status === 'sale' && p.enabled !== false;
        const modes = [];
        if (p.canBuy && can('sell')) modes.push('buy');
        if (p.canMortgage && p.canBuy && can('sell')) modes.push('mortgage');
        if (p.canRent && can('rent')) modes.push('rent');
        if (!modes.includes(S.mode)) S.mode = modes[0] || 'buy';
        return `<div class="ag-photo">${photo ? `<img src="${esc(photo)}" alt="">` : I('home', 40)}<span class="bx-chip ${p.status === 'sale' ? 'blue' : 'ok'}">${esc(t(`hb_status_${p.status}`, null, STATUS[p.status] || p.status))}</span></div>
<h2 class="ag-title">${esc(p.label)}</h2><div class="bx-hint">#${esc(p.id)} · ${esc(t(`hb_type_${p.type}`, null, TYPE[p.type] || p.type))} · ${esc([(p.address || {}).street, (p.address || {}).area].filter(Boolean).join(', '))}</div>
<div class="ag-facts"><div><span>${esc(t('ag_price', null, 'Price'))}</span><b>${esc(p.canBuy ? money(p.price) : '—')}</b></div><div><span>${esc(t('ag_rent', null, 'Rent'))}</span><b>${esc(p.canRent ? money(p.rentPrice) : '—')}</b></div><div><span>${esc(t('ag_commission', null, 'Your cut'))}</span><b>${esc(S.d.commissionPct)}%</b></div></div>
${p.owner ? `<div class="bx-card ag-owner"><div class="bx-cardbody"><div class="bx-rowline"><div><b>${esc(p.owner.name)}</b><div class="bx-hint">${esc(t(`hb_status_${p.owner.kind}`, null, STATUS[p.owner.kind] || p.owner.kind))} · ${esc(t('ag_since', { d: XS.date(p.owner.since).slice(0, 10) }, `since ${XS.date(p.owner.since).slice(0, 10)}`))}</div></div>${p.owner.missed ? `<span class="bx-chip bad">${esc(t('ag_missed', { n: p.owner.missed }, `${p.owner.missed} missed`))}</span>` : ''}</div>
  ${can('evict') && (p.owner.kind === 'rented' || p.owner.kind === 'mortgage') ? `<button class="bx-btn sm danger" data-act="evict">${I('door', 14)}${esc(t('ag_evict', null, 'Evict'))}</button>` : ''}</div></div>` : ''}
${forSale && can('price') ? `<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('ag_set_price', null, 'Price'))}</h3><small>${esc(t('ag_range', { pct: range }, `up to ${range}% either way`))}</small></div><div class="bx-cardbody">
  <div class="bx-cols2">${p.canBuy ? `<div class="bx-field"><label class="bx-label">${esc(t('ag_price', null, 'Price'))}</label><div class="bx-unit"><input type="number" id="ag-price" value="${esc(S.price !== '' ? S.price : p.price)}" min="${Math.floor(base * (1 - range / 100))}" max="${Math.floor(base * (1 + range / 100))}"><em>$</em></div><div class="bx-hint">${esc(money(base * (1 - range / 100)))} – ${esc(money(base * (1 + range / 100)))}</div></div>` : '<div></div>'}
  ${p.canRent ? `<div class="bx-field"><label class="bx-label">${esc(t('ag_rent', null, 'Rent'))}</label><div class="bx-unit"><input type="number" id="ag-rent" value="${esc(S.rent !== '' ? S.rent : p.rentPrice)}"><em>$</em></div></div>` : '<div></div>'}</div>
  <button class="bx-btn sm primary" data-act="price">${I('check', 14)}${esc(S.d.approval ? t('ag_send_price', null, 'Send for approval') : t('ag_save_price', null, 'Save price'))}</button></div></div>` : ''}
${p.status === 'sale' && can('list') ? `<div class="bx-card"><div class="bx-cardbody"><div class="bx-rowline"><div><b>${esc(t('ag_listed', null, 'On the market'))}</b><div class="bx-hint">${esc(t('ag_listed_hint', null, 'Off hides the sign and the listing.'))}</div></div><span class="bx-switch ${p.listed !== false ? 'on' : ''}" data-act="listed"></span></div></div></div>` : ''}
${p.canOpenHouse ? openHouseCard(p) : ''}
${forSale && modes.length ? `<div class="bx-card"><div class="bx-cardhead"><h3>${esc(t('ag_offer', null, 'Offer it to someone'))}</h3><button class="bx-btn xs ghost" data-act="nearby">${I('refresh', 12)}</button></div><div class="bx-cardbody">
  ${nearby.length ? `<div class="ag-people">${nearby.map((n) => `<button class="ag-person ${String(S.target) === String(n.id) ? 'on' : ''}" data-act="target" data-id="${esc(n.id)}"><b>${esc(n.name)}</b><small>#${esc(n.id)}</small></button>`).join('')}</div>` : `<div class="bx-hint">${esc(t('ag_nobody', null, 'Stand next to the buyer, then look again.'))}</div>`}
  <div class="ag-modes">${modes.map((m) => `<button class="bx-btn xs ${S.mode === m ? 'primary' : 'ghost'}" data-act="mode" data-v="${m}">${esc(t(`lt_mode_${m}`, null, ({ buy: 'Buy', rent: 'Rent', mortgage: 'Mortgage' })[m]))}</button>`).join('')}</div>
  ${S.mode === 'mortgage' ? `<div class="bx-cols2"><div class="bx-field"><label class="bx-label">${esc(t('ag_deposit', null, 'Deposit %'))}</label><input class="bx-input" type="number" id="ag-dep" value="${esc(S.depositPct || '')}" placeholder="${esc(t('ag_lowest', null, 'lowest allowed'))}"></div><div class="bx-field"><label class="bx-label">${esc(t('ag_payments', null, 'Payments'))}</label><input class="bx-input" type="number" id="ag-term" value="${esc(S.term || '')}" placeholder="8"></div></div>` : ''}
  <button class="bx-btn primary" data-act="offer" ${S.target ? '' : 'disabled'}>${I('paper', 15)}${esc(t('ag_send_offer', null, 'Send the offer'))}</button>
  <div class="bx-hint" style="margin-top:6px">${esc(t('ag_offer_hint', null, 'They see the listing and sign on their side. Your cut lands in your bank.'))}</div></div></div>` : ''}
<button class="bx-btn ghost" data-act="waypoint">${I('pin', 15)}${esc(t('ag_gps', null, 'Mark on GPS'))}</button>`;
    }

    function listingsPage() {
        const rows = filtered();
        const st = stats();
        const chip = (id, label, n) => `<button class="bx-btn xs ${S.filter === id ? 'primary' : 'ghost'}" data-act="filter" data-v="${id}">${esc(label)}${n !== undefined ? ` <em>${n}</em>` : ''}</button>`;
        return `<div class="ag-split"><div class="ag-listcol">
  <div class="bx-stats ag-stats">
    <div class="bx-stat">${I('sign', 18)}<b>${st.sale}</b><span>${esc(t('ag_st_sale', null, 'For sale'))}</span></div>
    <div class="bx-stat green">${I('key', 18)}<b>${st.taken}</b><span>${esc(t('ag_st_taken', null, 'Lived in'))}</span></div>
    <div class="bx-stat red">${I('alert', 18)}<b>${st.late}</b><span>${esc(t('ag_st_late', null, 'Behind on payments'))}</span></div>
    <div class="bx-stat amber">${I('cash', 18)}<b>${esc(money(st.earned))}</b><span>${esc(t('ag_st_earned', null, 'Your cut, 7 days'))}</span></div>
  </div>
  <div class="bx-listbar"><div class="bx-filter">${I('search', 15)}<input class="bx-input" id="ag-q" value="${esc(S.q)}" placeholder="${esc(t('ag_search', null, 'Street, area, owner or #id'))}"></div>
    ${chip('sale', t('ag_f_sale', null, 'For sale'))}${chip('taken', t('ag_f_taken', null, 'Lived in'))}${chip('late', t('ag_f_late', null, 'Late'))}${can('list') ? chip('unlisted', t('ag_f_unlisted', null, 'Off market')) : ''}${chip('all', t('ag_f_all', null, 'All'))}</div>
  <div class="bx-card ag-table xsp-scroll"><table class="bx-table"><thead><tr><th>#</th><th>${esc(t('ag_place', null, 'Place'))}</th><th>${esc(t('ag_status', null, 'Status'))}</th><th class="r">${esc(t('ag_price', null, 'Price'))}</th><th class="r">${esc(t('ag_rent', null, 'Rent'))}</th></tr></thead><tbody>
  ${rows.map((p) => `<tr class="click ${S.sel === p.id ? 'sel' : ''}" data-act="sel" data-id="${p.id}"><td class="bx-mono">${p.id}</td><td><b>${esc(p.label)}</b><div class="bx-hint">${esc([(p.address || {}).street, (p.address || {}).area].filter(Boolean).join(' · '))}</div></td><td><span class="bx-chip ${p.status === 'sale' ? (p.listed === false ? 'off' : 'blue') : 'ok'}">${esc(p.status === 'sale' && p.listed === false ? t('ag_unlisted', null, 'Off market') : t(`hb_status_${p.status}`, null, STATUS[p.status] || p.status))}</span>${p.owner ? `<div class="bx-hint">${esc(p.owner.name)}</div>` : ''}</td><td class="r bx-mono">${p.canBuy ? esc(money(p.price)) : '—'}</td><td class="r bx-mono">${p.canRent ? esc(money(p.rentPrice)) : '—'}</td></tr>`).join('') || `<tr><td colspan="5"><div class="bx-hint" style="padding:14px">${esc(t('ag_none', null, 'Nothing here.'))}</div></td></tr>`}
  </tbody></table></div></div>
<aside class="ag-detail xsp-scroll">${detail()}</aside></div>`;
    }

    function salesPage() {
        const sales = XS.list(S.d.sales);
        const total = sales.reduce((n, s) => n + (Number(s.amount) || 0), 0);
        return `<div class="bx-pagehead"><div><h1>${esc(t('ag_my_sales', null, 'My sales'))}</h1><p>${esc(t('ag_my_sales_sub', { amount: money(total) }, `${money(total)} earned from the last ${sales.length} deals.`))}</p></div></div>
<div class="bx-card"><table class="bx-table"><thead><tr><th>${esc(t('hb_when', null, 'When'))}</th><th>${esc(t('ag_place', null, 'Place'))}</th><th>${esc(t('hb_detail', null, 'Detail'))}</th><th class="r">${esc(t('ag_cut', null, 'Your cut'))}</th></tr></thead><tbody>
${sales.map((s) => { const p = list().find((x) => x.id === Number(s.property_id)); return `<tr><td class="bx-mono">${esc(XS.date(s.at))}</td><td>${esc(p ? p.label : `#${s.property_id}`)}</td><td class="bx-hint">${esc(s.detail || '')}</td><td class="r bx-mono">${esc(money(s.amount))}</td></tr>`; }).join('') || `<tr><td colspan="4"><div class="bx-hint" style="padding:14px">${esc(t('ag_no_sales', null, 'No deals yet.'))}</div></td></tr>`}
</tbody></table></div>`;
    }

    function render() {
        const d = S.d;
        const job = d.job || {};
        root.innerHTML = `<div class="xsp-stage"><div class="ag-tablet"><div class="bx ag-screen">
  <div class="bx-lightbar"></div>
  <div class="bx-top">
    <div class="bx-logo"><span class="bx-kindico">${I('tag', 18)}</span><div class="bx-word"><b>XS-<span>Housing</span></b><small>${esc(t('ag_title', null, 'Estate agent'))}</small></div></div>
    <div class="ag-navtabs"><button class="${S.page === 'listings' ? 'on' : ''}" data-act="page" data-v="listings">${I('home', 15)}${esc(t('ag_listings', null, 'Listings'))}</button><button class="${S.page === 'sales' ? 'on' : ''}" data-act="page" data-v="sales">${I('chart', 15)}${esc(t('ag_my_sales', null, 'My sales'))}</button></div>
    <span class="bx-sp"></span>
    <div class="bx-me ag-me"><div class="bx-avatar">${esc((job.name || 'A').slice(0, 1).toUpperCase())}</div><div><b>${esc(job.label || job.name || '')}</b><small>${esc(job.gradeLabel || '')}</small></div></div>
    <button class="bx-iconbtn" data-act="refresh" title="${esc(t('hb_refresh', null, 'Refresh'))}">${I('refresh', 15)}</button>
    <button class="bx-iconbtn close" data-act="close">${I('close', 16)}</button>
  </div>
  <div class="ag-body">${S.page === 'sales' ? salesPage() : listingsPage()}</div>
</div></div></div>`;
    }

    async function select(id) {
        S.sel = id;
        S.price = '';
        S.rent = '';
        S.target = null;
        render();
        const p = cur();
        if (p && p.photo === 'stored' && !S.photos[id]) {
            const res = await XS.rpc('agency:photo', { id });
            if (res.ok) { S.photos[id] = res.data; if (S.sel === id) render(); }
        }
    }

    async function refresh() {
        const res = await XS.rpc('agency:refresh');
        if (res.ok) { load(res.data); render(); }
    }

    async function run(name, payload, okText) {
        if (S.busy) return null;
        S.busy = true;
        const res = await XS.rpc(name, payload);
        S.busy = false;
        if (!res.ok) { XS.toast(res.error, 'error'); return null; }
        if (okText) XS.toast(okText, 'ok');
        await refresh();
        return res;
    }

    async function onClick(e) {
        const el = e.target.closest('[data-act]');
        if (!el) return;
        const act = el.dataset.act;
        const p = cur();
        switch (act) {
            case 'close': XS.close('agency'); break;
            case 'refresh': refresh(); break;
            case 'page': S.page = el.dataset.v; render(); break;
            case 'filter': S.filter = el.dataset.v; render(); break;
            case 'sel': select(Number(el.dataset.id)); break;
            case 'listed': if (p) run('agency:listed', { id: p.id, listed: p.listed === false }); break;
            case 'openhouse': if (p) run('agency:openHouse', { id: p.id, on: openHouseLeft(p) <= 0 }, openHouseLeft(p) <= 0 ? t('ag_open_started', null, 'Open house started. It is on the map.') : t('ag_open_stopped', null, 'Open house ended.')); break;
            case 'price': {
                if (!p) break;
                const price = root.querySelector('#ag-price');
                const rent = root.querySelector('#ag-rent');
                const res = await run('agency:price', { id: p.id, price: price ? Number(price.value) : null, rent: rent ? Number(rent.value) : null });
                if (res) XS.toast(res.data === 'pending' ? t('ag_price_sent', null, 'Sent to staff for approval.') : t('ag_price_saved', null, 'Price saved.'), 'ok');
                S.price = '';
                S.rent = '';
                break;
            }
            case 'nearby': refresh(); break;
            case 'target': S.target = el.dataset.id; render(); break;
            case 'mode': S.mode = el.dataset.v; render(); break;
            case 'offer': if (p && S.target) run('agency:offer', { id: p.id, target: Number(S.target), mode: S.mode, opts: { depositPct: S.depositPct || null, term: S.term || null } }, t('ag_offer_sent', null, 'Offer sent.')); break;
            case 'evict': if (p) run('agency:evict', { id: p.id }, t('ag_evicted', null, 'Evicted.')); break;
            case 'waypoint': if (p) { XS.rpc('agency:waypoint', { id: p.id }); XS.toast(t('lt_gps_set', null, 'Waypoint set.'), 'ok'); } break;
            default: break;
        }
    }

    function onInput(e) {
        const el = e.target;
        if (el.id === 'ag-q') {
            S.q = el.value;
            render();
            const i = root.querySelector('#ag-q');
            if (i) { i.focus(); i.setSelectionRange(i.value.length, i.value.length); }
        }
        if (el.id === 'ag-price') S.price = el.value;
        if (el.id === 'ag-rent') S.rent = el.value;
        if (el.id === 'ag-dep') S.depositPct = Number(el.value) || 0;
        if (el.id === 'ag-term') S.term = Number(el.value) || 0;
    }

    function load(data) {
        S.d = data;
        S.loadedAt = Date.now();
        S.d.list = XS.list(data.list);
        S.d.sales = XS.list(data.sales);
        S.d.nearby = XS.list(data.nearby);
        S.d.rights = data.rights || {};
    }

    XS.apps.agency = {
        isOpen: () => S.open,
        escape() { XS.close('agency'); },
        on(action, data) {
            if (action === 'open') {
                load(data);
                S.open = true;
                S.page = 'listings';
                XS.show('xsh-agency', true);
                render();
            } else if (action === 'close') {
                S.open = false;
                XS.show('xsh-agency', false);
            }
        },
    };

    root.addEventListener('click', onClick);
    root.addEventListener('input', onInput);
})();
