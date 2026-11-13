/**
 * Procedural machine sounds (Web Audio). No audio files needed.
 */
const Sfx = (() => {
    let ac = null;
    let master = null;
    let enabled = true;
    let volume = 0.35;

    function audio() {
        if (!ac) {
            ac = new (window.AudioContext || window.webkitAudioContext)();
            master = ac.createGain();
            master.gain.value = volume;
            master.connect(ac.destination);
        }
        if (ac.state === 'suspended') ac.resume();
        return ac;
    }

    function tone(freq, dur, type = 'sine', gain = 0.3, when = 0, slideTo = null) {
        if (!enabled) return;
        const c = audio();
        const t = c.currentTime + when;
        const osc = c.createOscillator();
        const g = c.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, t);
        if (slideTo) osc.frequency.exponentialRampToValueAtTime(slideTo, t + dur);
        g.gain.setValueAtTime(0.0001, t);
        g.gain.exponentialRampToValueAtTime(gain, t + 0.008);
        g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
        osc.connect(g).connect(master);
        osc.start(t);
        osc.stop(t + dur + 0.05);
    }

    function noise(dur, gain = 0.2, when = 0, freq = 1200, type = 'lowpass') {
        if (!enabled) return;
        const c = audio();
        const t = c.currentTime + when;
        const len = Math.max(1, Math.floor(c.sampleRate * dur));
        const buffer = c.createBuffer(1, len, c.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;

        const src = c.createBufferSource();
        src.buffer = buffer;
        const filter = c.createBiquadFilter();
        filter.type = type;
        filter.frequency.value = freq;
        const g = c.createGain();
        g.gain.setValueAtTime(0.0001, t);
        g.gain.exponentialRampToValueAtTime(gain, t + 0.01);
        g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
        src.connect(filter).connect(g).connect(master);
        src.start(t);
        src.stop(t + dur + 0.05);
    }

    return {
        configure(opts = {}) {
            enabled = opts.sound !== false;
            volume = typeof opts.volume === 'number' ? opts.volume : 0.35;
            if (master) master.gain.value = volume;
        },
        beep:  () => tone(1320, 0.07, 'square', 0.1),
        key:   () => { tone(1480, 0.05, 'square', 0.08); noise(0.02, 0.15, 0, 3500, 'highpass'); },
        click: () => { noise(0.03, 0.25, 0, 3000, 'highpass'); tone(240, 0.05, 'sine', 0.12); },
        coin:  () => { tone(2093, 0.12, 'triangle', 0.16); tone(2637, 0.2, 'triangle', 0.12, 0.06); noise(0.1, 0.08, 0.16, 5000, 'highpass'); },
        bill:  () => { noise(0.55, 0.1, 0, 900, 'bandpass'); tone(85, 0.55, 'sawtooth', 0.04); },
        card:  () => { tone(1568, 0.09, 'sine', 0.18); tone(2093, 0.14, 'sine', 0.18, 0.12); },
        error: () => { tone(170, 0.28, 'square', 0.1); tone(125, 0.32, 'square', 0.08, 0.06); },
        motor: (d = 1.2) => { tone(68, d, 'sawtooth', 0.07); tone(136, d, 'square', 0.015); noise(d, 0.05, 0, 500); },
        thunk: () => { tone(170, 0.28, 'sine', 0.45, 0, 45); noise(0.14, 0.35, 0, 700); },
        soft:  () => { tone(320, 0.12, 'sine', 0.18, 0, 140); noise(0.06, 0.15, 0, 1500); },
        flap:  () => { noise(0.09, 0.22, 0, 1600); tone(140, 0.08, 'sine', 0.1); },
        knob:  () => { for (let i = 0; i < 7; i++) noise(0.018, 0.25, i * 0.045, 2600, 'highpass'); tone(110, 0.35, 'triangle', 0.08, 0.3, 70); },
        brew:  (d = 3) => {
            noise(d, 0.07, 0, 450, 'lowpass');
            for (let i = 0; i < d * 9; i++) tone(260 + Math.random() * 380, 0.05, 'sine', 0.035, Math.random() * d);
        },
    };
})();
