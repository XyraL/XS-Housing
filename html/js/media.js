(function () {
    const YT_RES = [
        /(?:youtube\.com|youtube-nocookie\.com)\/(?:watch\?(?:[^#]*&)?v=|embed\/|shorts\/|live\/|v\/)([\w-]{11})/i,
        /youtu\.be\/([\w-]{11})/i,
    ];
    const FILE_RE = /\.(mp3|ogg|oga|wav|m4a|aac|flac|opus|mp4|webm|ogv|mov|m4v)(?:[?#]|$)/i;
    const VIDEO_RE = /\.(mp4|webm|ogv|mov|m4v)(?:[?#]|$)/i;
    const TWITCH_SKIP = ['videos', 'directory', 'p', 'settings', 'downloads', 'jobs', 'search', 'subscriptions', 'inventory', 'wallet'];
    const DRIFT = 2.5;

    function youtubeId(url) {
        for (const re of YT_RES) {
            const m = re.exec(url);
            if (m) return m[1];
        }
        return null;
    }

    function twitchOf(url) {
        const vod = /twitch\.tv\/videos\/(\d+)/i.exec(url);
        if (vod) return { video: vod[1] };
        const ch = /(?:^|\/\/|\.)twitch\.tv\/([a-z0-9_]{3,25})(?:[/?#]|$)/i.exec(url);
        if (ch && !TWITCH_SKIP.includes(ch[1].toLowerCase())) return { channel: ch[1] };
        return null;
    }

    function kindOf(url) {
        if (typeof url !== 'string' || !/^https?:\/\//i.test(url)) return { kind: 'none' };
        const yt = youtubeId(url);
        if (yt) return { kind: 'youtube', id: yt };
        const tw = twitchOf(url);
        if (tw) return Object.assign({ kind: 'twitch' }, tw);
        if (FILE_RE.test(url)) return { kind: 'file', video: VIDEO_RE.test(url) };
        return { kind: 'page' };
    }

    function fileName(url) {
        try {
            const last = decodeURIComponent(new URL(url).pathname.split('/').pop() || '');
            return last.replace(/\.[a-z0-9]+$/i, '').replace(/[_-]+/g, ' ').trim();
        } catch (err) {
            return '';
        }
    }

    function loadScript(src, ready) {
        return new Promise((resolve) => {
            if (ready()) return resolve(true);
            const s = document.createElement('script');
            s.src = src;
            s.async = true;
            s.onload = () => resolve(ready());
            s.onerror = () => resolve(false);
            document.head.appendChild(s);
        });
    }

    let ytApi = null;
    function youtubeApi() {
        if (ytApi) return ytApi;
        ytApi = new Promise((resolve) => {
            if (window.YT && window.YT.Player) return resolve(true);
            const before = window.onYouTubeIframeAPIReady;
            window.onYouTubeIframeAPIReady = () => {
                if (typeof before === 'function') before();
                resolve(true);
            };
            loadScript('https://www.youtube.com/iframe_api', () => false).then(() => {
                setTimeout(() => resolve(!!(window.YT && window.YT.Player)), 8000);
            });
        });
        return ytApi;
    }

    function frame(src, video) {
        const f = document.createElement('iframe');
        f.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
        f.setAttribute('allow', 'autoplay; encrypted-media; picture-in-picture');
        f.setAttribute('frameborder', '0');
        f.className = video ? 'xsm-fill' : 'xsm-hidden';
        f.src = src;
        return f;
    }

    function clampVolume(v) {
        const n = Number(v);
        if (!Number.isFinite(n)) return 0;
        return Math.max(0, Math.min(1, n));
    }

    function clock(opts) {
        let base = Math.max(0, Number(opts.offset) || 0);
        let since = performance.now();
        let paused = !!opts.paused;
        return {
            get paused() { return paused; },
            at() { return paused ? base : base + (performance.now() - since) / 1000; },
            set(offset, isPaused) { base = Math.max(0, Number(offset) || 0); since = performance.now(); paused = !!isPaused; },
        };
    }

    function playYouTube(box, id, opts) {
        const want = clock(opts);
        const params = new URLSearchParams({
            autoplay: want.paused ? '0' : '1', controls: '0', disablekb: '1', enablejsapi: '1', fs: '0', iv_load_policy: '3',
            loop: '1', playlist: id, modestbranding: '1', playsinline: '1', rel: '0', origin: window.location.origin,
        });
        const f = frame(`https://www.youtube.com/embed/${id}?${params.toString()}`, opts.video);
        box.appendChild(f);
        let player = null;
        let ready = false;
        let volume = clampVolume(opts.volume);
        let dead = false;
        let title = '';
        const len = () => (ready && player.getDuration ? player.getDuration() || 0 : 0);
        const now = () => (ready && player.getCurrentTime ? player.getCurrentTime() || 0 : 0);
        const target = () => { const l = len(); return l > 0 ? want.at() % l : want.at(); };
        const apply = (force) => {
            if (!ready || dead) return;
            const l = len();
            if (l > 0 && (force || Math.abs(now() - target()) > DRIFT)) player.seekTo(target(), true);
            if (want.paused) player.pauseVideo(); else player.playVideo();
        };
        youtubeApi().then((ok) => {
            if (!ok || dead) return;
            try {
                player = new window.YT.Player(f, {
                    events: {
                        onReady: () => {
                            if (dead) return;
                            ready = true;
                            try { title = (player.getVideoData() || {}).title || ''; } catch (err) { title = ''; }
                            player.unMute();
                            player.setVolume(Math.round(volume * 100));
                            apply(want.at() > 1);
                        },
                        onStateChange: (e) => {
                            if (dead) return;
                            if (!title) { try { title = (player.getVideoData() || {}).title || ''; } catch (err) { title = ''; } }
                            if (e.data === 1 && want.paused) player.pauseVideo();
                            if (e.data === 1 && Math.abs(now() - target()) > DRIFT) player.seekTo(target(), true);
                            if (e.data === 0 && !want.paused) { player.seekTo(0, true); player.playVideo(); }
                        },
                        onError: () => { if (opts.onError) opts.onError('youtube'); },
                    },
                });
            } catch (err) {
                player = null;
            }
        });
        return {
            setVolume(v) {
                volume = clampVolume(v);
                if (ready) { try { player.setVolume(Math.round(volume * 100)); if (volume > 0) player.unMute(); } catch (err) { } }
            },
            sync(offset, paused) { want.set(offset, paused); apply(false); },
            status() { return { kind: 'youtube', id, title, time: ready ? now() : want.at(), duration: len(), paused: want.paused, ready }; },
            stop() {
                dead = true;
                try { if (player && player.destroy) player.destroy(); } catch (err) { }
                f.remove();
            },
        };
    }

    function playTwitch(box, tw, opts) {
        const want = clock(opts);
        const holder = document.createElement('div');
        holder.className = opts.video ? 'xsm-fill' : 'xsm-hidden';
        holder.id = `xsm-tw-${Math.random().toString(36).slice(2)}`;
        box.appendChild(holder);
        let player = null;
        let volume = clampVolume(opts.volume);
        let dead = false;
        const apply = () => {
            if (!player) return;
            try { if (want.paused) player.pause(); else player.play(); } catch (err) { }
        };
        loadScript('https://player.twitch.tv/js/embed/v1.js', () => !!(window.Twitch && window.Twitch.Player)).then((ok) => {
            if (dead) return;
            if (!ok) {
                const src = `https://player.twitch.tv/?${tw.video ? `video=v${tw.video}` : `channel=${encodeURIComponent(tw.channel)}`}&parent=${encodeURIComponent(window.location.hostname)}&autoplay=${want.paused ? 'false' : 'true'}&muted=false`;
                holder.appendChild(frame(src, true));
                return;
            }
            const cfg = { width: '100%', height: '100%', parent: [window.location.hostname], autoplay: !want.paused, muted: false };
            if (tw.video) cfg.video = tw.video; else cfg.channel = tw.channel;
            player = new window.Twitch.Player(holder.id, cfg);
            player.addEventListener(window.Twitch.Player.READY, () => {
                if (dead) return;
                try { player.setMuted(false); player.setVolume(volume); } catch (err) { }
                if (tw.video && want.at() > 1) { try { player.seek(want.at()); } catch (err) { } }
                apply();
            });
        });
        return {
            setVolume(v) {
                volume = clampVolume(v);
                try { if (player) { player.setVolume(volume); player.setMuted(volume <= 0); } } catch (err) { }
            },
            sync(offset, paused) {
                want.set(offset, paused);
                if (player && tw.video) { try { if (Math.abs(player.getCurrentTime() - want.at()) > DRIFT) player.seek(want.at()); } catch (err) { } }
                apply();
            },
            status() {
                let time = 0;
                let duration = 0;
                try { if (player) { time = player.getCurrentTime() || 0; duration = tw.video ? player.getDuration() || 0 : 0; } } catch (err) { }
                return { kind: 'twitch', title: tw.channel || '', time, duration, paused: want.paused, ready: !!player };
            },
            stop() { dead = true; holder.remove(); },
        };
    }

    function playFile(box, url, opts) {
        const want = clock(opts);
        const el = document.createElement(opts.video && VIDEO_RE.test(url) ? 'video' : 'audio');
        el.className = opts.video ? 'xsm-fill' : 'xsm-hidden';
        el.src = url;
        el.loop = true;
        el.autoplay = !want.paused;
        el.playsInline = true;
        el.volume = clampVolume(opts.volume);
        const target = () => { const l = el.duration; return Number.isFinite(l) && l > 0 ? want.at() % l : want.at(); };
        const apply = () => {
            const l = el.duration;
            if (Number.isFinite(l) && l > 0 && Math.abs(el.currentTime - target()) > DRIFT) el.currentTime = target();
            if (want.paused) el.pause();
            else { const p = el.play(); if (p && p.catch) p.catch(() => { }); }
        };
        el.addEventListener('loadedmetadata', apply);
        el.addEventListener('error', () => { if (opts.onError) opts.onError('file'); });
        box.appendChild(el);
        if (!want.paused) { const p = el.play(); if (p && p.catch) p.catch(() => { }); }
        return {
            setVolume(v) { el.volume = clampVolume(v); },
            sync(offset, paused) { want.set(offset, paused); apply(); },
            status() {
                const l = el.duration;
                return { kind: 'file', title: fileName(url), time: el.currentTime || 0, duration: Number.isFinite(l) ? l : 0, paused: want.paused, ready: el.readyState > 0 };
            },
            stop() { try { el.pause(); el.removeAttribute('src'); el.load(); } catch (err) { } el.remove(); },
        };
    }

    window.XSMedia = {
        kindOf,
        youtubeId,
        fileName,
        play(box, opts) {
            const info = kindOf(opts.url);
            if (info.kind === 'youtube') return playYouTube(box, info.id, opts);
            if (info.kind === 'twitch') return playTwitch(box, info, opts);
            if (info.kind === 'file' || (info.kind === 'page' && !opts.video)) return playFile(box, opts.url, opts);
            return null;
        },
    };
})();
