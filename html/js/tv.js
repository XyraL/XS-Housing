(function () {
    const q = new URLSearchParams(window.location.search);
    const url = q.get('src') || '';
    const offset = Number(q.get('t')) || 0;
    const start = Number(q.get('v'));
    const paused = q.get('p') === '1';
    const screen = document.getElementById('screen');
    const note = document.getElementById('note');
    const noSignal = () => { note.style.display = 'flex'; };

    const info = window.XSMedia.kindOf(url);
    if (info.kind === 'page') {
        window.location.replace(url);
        return;
    }
    const handle = info.kind === 'none' ? null : window.XSMedia.play(screen, {
        url, offset, paused, volume: Number.isFinite(start) ? start : 0.5, video: true, onError: noSignal,
    });
    if (!handle) noSignal();

    window.addEventListener('message', (e) => {
        let d = e.data;
        if (typeof d === 'string') {
            try { d = JSON.parse(d); } catch (err) { return; }
        }
        if (!d || typeof d !== 'object' || !handle) return;
        if (d.type === 'volume') handle.setVolume(d.volume);
        if (d.type === 'sync') handle.sync(d.offset, !!d.paused);
    });
})();
