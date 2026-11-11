(() => {
    const root = document.getElementById('xsh-catalogue');
    const t = XS.t;
    const esc = XS.esc;
    const I = (n, s) => XS.icon(n, s || 16);
    const money = (n) => XS.money(n);

    const S = { open: false, d: null, where: 'inside', cat: 'all', q: '', sort: 'popular', pick: null, again: true, tab: 'shop', busy: false };
    const CAT_TONE = { living: '#d97757', bedroom: '#7c8cd9', kitchen: '#e0a33a', bathroom: '#4fb3c8', office: '#8a8f98', storage: '#a07a52', lighting: '#f2c94c', electronics: '#5b6ee1', decor: '#6fbf73', gym: '#e05d5d', outdoor: '#e9a23b', garden: '#4caf6a', fences: '#9b7b5b', seasonal: '#c86dd7' };
    const USE_LABEL = { storage: 'Storage', safe: 'Safe', fridge: 'Fridge', sit: 'Seat', lie: 'Bed', wardrobe: 'Wardrobe', light: 'Light', music: 'Speaker', tv: 'Screen' };

    const items = () => XS.list(S.d && S.d.items).filter((i) => !i.hidden && !i.offSeason && (i.where === 'both' || i.where === S.where));
    const cats = () => XS.list(S.d && S.d.categories).filter((c) => items().some((i) => i.category === c.id));
    const catName = (id) => t(`hb_cat_${id}`, null, id.charAt(0).toUpperCase() + id.slice(1));

    function shown() {
        const q = S.q.trim().toLowerCase();
        const list = items().filter((i) => (S.cat === 'all' || i.category === S.cat) && (!q || `${i.label} ${i.category} ${i.use || ''}`.toLowerCase().includes(q)));
        if (S.sort === 'low') list.sort((a, b) => a.price - b.price);
        if (S.sort === 'high') list.sort((a, b) => b.price - a.price);
        if (S.sort === 'name') list.sort((a, b) => String(a.label).localeCompare(String(b.label)));
        return list;
    }

    function useBadge(i) {
        if (!i.use) return '';
        const extra = (i.use === 'storage' || i.use === 'safe' || i.use === 'fridge') && i.slots ? ` · ${i.slots}` : '';
        return `<span class="ct-use">${esc(t(`hb_use_${i.use}`, null, USE_LABEL[i.use] || i.use))}${esc(extra)}</span>`;
    }

    function card(i) {
        const tone = CAT_TONE[i.category] || '#8a8f98';
        const cat = XS.list(S.d.categories).find((c) => c.id === i.category) || {};
        return `<button class="ct-card ${S.pick === i.id ? 'on' : ''}" data-act="pick" data-id="${esc(i.id)}">
            <span class="ct-swatch" style="--tone:${tone}">${I(cat.icon || 'box', 34)}</span>
            <span class="ct-ctext"><b>${esc(i.label)}</b><small>${esc(catName(i.category))}</small></span>
            <span class="ct-pricetag">${esc(money(i.price))}</span>${useBadge(i)}${i.job ? `<span class="ct-job">${I('badge', 11)}${esc(i.job)}</span>` : ''}</button>`;
    }

    function shopPage() {
        const list = shown();
        const pick = items().find((i) => i.id === S.pick);
        const bank = (S.d.money || {}).bank || 0;
        return `<div class="ct-shop">
  <aside class="ct-cats">
    <button class="${S.cat === 'all' ? 'on' : ''}" data-act="cat" data-v="all">${I('grid', 17)}<span>${esc(t('ct_everything', null, 'Everything'))}</span><em>${items().length}</em></button>
    ${cats().map((c) => `<button class="${S.cat === c.id ? 'on' : ''}" data-act="cat" data-v="${esc(c.id)}"><i style="background:${CAT_TONE[c.id] || '#8a8f98'}">${I(c.icon, 14)}</i><span>${esc(catName(c.id))}</span><em>${items().filter((i) => i.category === c.id).length}</em></button>`).join('')}
  </aside>
  <section class="ct-list">
    <div class="ct-bar"><div class="ct-search">${I('search', 16)}<input id="ct-q" value="${esc(S.q)}" placeholder="${esc(t('ct_search', null, 'Search the catalogue'))}"></div>
      <select id="ct-sort"><option value="popular" ${S.sort === 'popular' ? 'selected' : ''}>${esc(t('ct_sort_default', null, 'Featured'))}</option><option value="low" ${S.sort === 'low' ? 'selected' : ''}>${esc(t('ct_sort_low', null, 'Price, low to high'))}</option><option value="high" ${S.sort === 'high' ? 'selected' : ''}>${esc(t('ct_sort_high', null, 'Price, high to low'))}</option><option value="name" ${S.sort === 'name' ? 'selected' : ''}>${esc(t('ct_sort_name', null, 'A to Z'))}</option></select></div>
    <div class="ct-grid xsp-scroll">${list.length ? list.map(card).join('') : `<div class="ct-empty">${I('search', 30)}<b>${esc(t('ct_nothing', null, 'Nothing matches'))}</b></div>`}</div>
  </section>
  <aside class="ct-buy">
    ${pick ? `<span class="ct-swatch big" style="--tone:${CAT_TONE[pick.category] || '#8a8f98'}">${I((XS.list(S.d.categories).find((c) => c.id === pick.category) || {}).icon || 'box', 56)}</span>
      <h3>${esc(pick.label)}</h3><small>${esc(catName(pick.category))}${pick.use ? ` · ${esc(t(`hb_use_${pick.use}`, null, USE_LABEL[pick.use] || pick.use))}` : ''}</small>
      <div class="ct-bigprice">${esc(money(pick.price))}</div>
      ${pick.use === 'storage' || pick.use === 'safe' ? `<div class="ct-spec">${I('box', 14)}${esc(t('ct_holds', { n: pick.slots, kg: Math.round((pick.weight || 0) / 1000) }, `Holds ${pick.slots} slots, ${Math.round((pick.weight || 0) / 1000)} kg`))}</div>` : ''}
      ${pick.use === 'music' ? `<div class="ct-spec">${I('music', 14)}${esc(t('ct_spec_music', null, 'Plays a link for the room'))}</div>` : ''}
      ${pick.use === 'tv' ? `<div class="ct-spec">${I('tv', 14)}${esc(t('ct_spec_tv', null, 'Shows a link on the screen'))}</div>` : ''}
      ${pick.use === 'light' ? `<div class="ct-spec">${I('bulb', 14)}${esc(t('ct_spec_light', null, 'Switches on and off'))}</div>` : ''}
      ${pick.use === 'sit' || pick.use === 'lie' ? `<div class="ct-spec">${I('sofa', 14)}${esc(t(`ct_spec_${pick.use}`, null, pick.use === 'sit' ? 'You can sit on it' : 'You can lie on it'))}</div>` : ''}
      <label class="ct-again"><input type="checkbox" id="ct-again" ${S.again ? 'checked' : ''}><span>${esc(t('ct_again', null, 'Come back here after placing'))}</span></label>
      <button class="ct-btn primary" data-act="place" ${pick.price > bank ? 'disabled' : ''}>${I('plus', 16)}${esc(t('ct_place', null, 'Place it'))}</button>
      ${pick.price > bank ? `<div class="ct-short">${esc(t('ct_short', null, 'Not enough in your bank.'))}</div>` : ''}
      <div class="ct-how"><div><span>${esc(t('ct_k_move', null, 'Mouse'))}</span>${esc(t('ct_k_move_t', null, 'aim'))}</div><div><span>←→</span>${esc(t('ct_k_turn', null, 'turn'))}</div><div><span>↑↓</span>${esc(t('ct_k_raise', null, 'raise'))}</div><div><span>Enter</span>${esc(t('ct_k_done', null, 'buy'))}</div></div>`
        : `<div class="ct-empty">${I('sofa', 34)}<b>${esc(t('ct_pick', null, 'Pick something'))}</b><span>${esc(t('ct_pick_hint', null, 'You pay when you put it down.'))}</span></div>`}
  </aside>
</div>`;
    }

    function placedPage() {
        const list = XS.list(S.d.placed).filter((p) => p.place === S.where || (S.where === 'inside' && p.place !== 'yard'));
        return `<div class="ct-placed xsp-scroll">${list.length ? `<table><thead><tr><th>${esc(t('ct_item', null, 'Item'))}</th><th>${esc(t('ct_does', null, 'Does'))}</th><th></th></tr></thead><tbody>${list.map((p) => `<tr><td><b>${esc(p.label)}</b></td><td>${p.use ? esc(t(`hb_use_${p.use}`, null, USE_LABEL[p.use] || p.use)) : '—'}</td><td class="r"><button class="ct-btn sm" data-act="move" data-row="${esc(p.id)}">${I('crosshair', 14)}${esc(t('ct_move', null, 'Move'))}</button><button class="ct-btn sm danger" data-act="remove" data-row="${esc(p.id)}">${I('remove', 14)}${esc(t('ct_remove', null, 'Remove'))}</button></td></tr>`).join('')}</tbody></table>`
            : `<div class="ct-empty">${I('sofa', 34)}<b>${esc(t('ct_none_placed', null, 'Nothing placed here yet'))}</b></div>`}</div>`;
    }

    function render() {
        const d = S.d;
        const placed = XS.list(d.placed);
        root.innerHTML = `<div class="xsp-stage"><div class="ct-book ${S.fresh ? 'in' : ''}">
<header class="ct-head">
  <div class="ct-brand"><b>XS-Housing</b><span>${esc(t('ct_title', null, 'Home & Garden'))}</span></div>
  <div class="ct-for">${I('home', 15)}${esc(d.label)}</div>
  <span class="ct-sp"></span>
  <div class="ct-where">${d.canInside ? `<button class="${S.where === 'inside' ? 'on' : ''}" data-act="where" data-v="inside">${I('sofa', 15)}${esc(t('ct_inside', null, 'Inside'))}</button>` : ''}${d.canYard ? `<button class="${S.where === 'yard' ? 'on' : ''}" data-act="where" data-v="yard">${I('tree', 15)}${esc(t('ct_yard', null, 'Yard'))}</button>` : ''}</div>
  <div class="ct-tabs"><button class="${S.tab === 'shop' ? 'on' : ''}" data-act="tab" data-v="shop">${esc(t('ct_shop', null, 'Shop'))}</button><button class="${S.tab === 'placed' ? 'on' : ''}" data-act="tab" data-v="placed">${esc(t('ct_placed', null, 'Placed'))}<em>${placed.length}</em></button></div>
  ${S.where === 'yard' ? `<button class="ct-btn ghost sm" data-act="showyard">${I('eye', 14)}${esc(t('ct_show_yard', null, 'Show the yard'))}</button>` : ''}
  <div class="ct-bank">${I('cash', 15)}${esc(money((d.money || {}).bank || 0))}</div>
  <button class="ct-x" data-act="close">${I('close', 18)}</button>
</header>
${S.tab === 'shop' ? shopPage() : placedPage()}
</div></div>`;
        S.fresh = false;
    }

    async function onClick(e) {
        const el = e.target.closest('[data-act]');
        if (!el) return;
        const act = el.dataset.act;
        switch (act) {
            case 'close': XS.close('catalogue'); break;
            case 'where': S.where = el.dataset.v; S.cat = 'all'; S.pick = null; render(); break;
            case 'tab': S.tab = el.dataset.v; render(); break;
            case 'cat': S.cat = el.dataset.v; render(); break;
            case 'pick': S.pick = el.dataset.id; render(); break;
            case 'place': if (S.pick) XS.rpc('catalogue:pick', { id: S.d.id, item: S.pick, where: S.where, again: S.again }); break;
            case 'move': XS.rpc('catalogue:move', { id: S.d.id, row: Number(el.dataset.row) }); break;
            case 'remove': {
                if (S.busy) break;
                S.busy = true;
                const res = await XS.rpc('catalogue:remove', { id: S.d.id, row: Number(el.dataset.row) });
                S.busy = false;
                if (!res.ok) { XS.toast(res.error, 'error'); break; }
                S.d.placed = XS.list(res.data && res.data.placed);
                XS.toast(res.data && res.data.refund ? t('ct_refund', { amount: money(res.data.refund) }, `Removed. ${money(res.data.refund)} back.`) : t('ct_removed', null, 'Removed.'), 'ok');
                render();
                break;
            }
            case 'showyard': XS.rpc('catalogue:yard', { id: S.d.id }); break;
            default: break;
        }
    }

    function onInput(e) {
        if (e.target.id === 'ct-q') {
            S.q = e.target.value;
            render();
            const i = root.querySelector('#ct-q');
            if (i) { i.focus(); i.setSelectionRange(i.value.length, i.value.length); }
        }
    }

    function onChange(e) {
        if (e.target.id === 'ct-sort') { S.sort = e.target.value; render(); }
        if (e.target.id === 'ct-again') S.again = e.target.checked;
    }

    XS.apps.catalogue = {
        isOpen: () => S.open,
        escape() { XS.close('catalogue'); },
        on(action, data) {
            if (action === 'open') {
                const same = S.d && S.d.id === data.id;
                S.d = data;
                S.d.items = XS.list(data.items);
                S.d.categories = XS.list(data.categories);
                S.d.placed = XS.list(data.placed);
                S.where = data.where || (data.canInside ? 'inside' : 'yard');
                if (!same) { S.cat = 'all'; S.q = ''; S.pick = null; S.tab = 'shop'; }
                S.open = true;
                S.fresh = true;
                XS.show('xsh-catalogue', true);
                render();
            } else if (action === 'close') {
                S.open = false;
                XS.show('xsh-catalogue', false);
            }
        },
    };

    root.addEventListener('click', onClick);
    root.addEventListener('input', onInput);
    root.addEventListener('change', onChange);
})();
