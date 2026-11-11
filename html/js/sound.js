(function () {
    const box = document.createElement('div');
    box.id = 'xsh-sound';
    document.body.appendChild(box);
    const live = new Map();

    function stop(name) {
        const s = live.get(name);
        if (!s) return;
        if (s.handle) s.handle.stop();
        live.delete(name);
    }

    XS.apps.sound = {
        on(action, d) {
            if (action === 'play') {
                const cur = live.get(d.name);
                if (cur && cur.url === d.url && cur.handle) {
                    cur.handle.setVolume(d.volume);
                    if (cur.at !== d.at || cur.paused !== !!d.paused || d.paused) cur.handle.sync(d.offset, !!d.paused);
                    cur.at = d.at;
                    cur.paused = !!d.paused;
                    return;
                }
                stop(d.name);
                const handle = window.XSMedia.play(box, { url: d.url, offset: d.offset, paused: !!d.paused, volume: d.volume, video: false });
                live.set(d.name, { url: d.url, at: d.at, paused: !!d.paused, handle });
            } else if (action === 'volume') {
                const cur = live.get(d.name);
                if (cur && cur.handle) cur.handle.setVolume(d.volume);
            } else if (action === 'stop') {
                stop(d.name);
            } else if (action === 'stopAll') {
                Array.from(live.keys()).forEach(stop);
            }
        },
        status(name) {
            const cur = live.get(name);
            if (!cur || !cur.handle) return null;
            return Object.assign({ url: cur.url }, cur.handle.status());
        },
        count() { return live.size; },
    };
})();
