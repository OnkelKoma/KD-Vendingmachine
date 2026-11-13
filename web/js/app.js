/**
 * kd-vendingmachine NUI controller.
 * Open web/index.html directly in a browser to get a dev preview with mock data.
 */
(() => {
    const IS_GAME = typeof window.GetParentResourceName === 'function';
    const RESOURCE = IS_GAME ? window.GetParentResourceName() : 'kd-vendingmachine';

    const $app = document.getElementById('app');
    const $scaler = document.getElementById('scaler');
    const $machine = document.getElementById('machine');

    const S = {
        open: false,
        machine: null,
        payment: {},
        balance: {},
        locale: {},
        ui: { currency: '$', showBalance: true, autoTake: 8000 },
        imageTemplate: null,
        busy: false,
        purchased: false,
        taken: false,
        layout: null,
        timers: [],
    };

    /* ───────────── helpers ───────────── */

    const t = (key) => S.locale[key] || key.replace(/_/g, ' ').toUpperCase();
    const money = (n) => `${S.ui.currency || '$'}${Number(n || 0).toFixed(2)}`;

    async function post(name, data = {}) {
        if (!IS_GAME) return Mock.post(name, data);
        try {
            const res = await fetch(`https://${RESOURCE}/${name}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data),
            });
            return await res.json();
        } catch (e) {
            return { ok: false, reason: 'failed' };
        }
    }

    function applyStock(stock) {
        if (!stock || !S.machine) return;
        S.machine.items.forEach((item) => {
            if (stock[item.name] != null) item.stock = stock[item.name];
        });
        S.layout && S.layout.updateStock && S.layout.updateStock();
    }

    function fit() {
        if (!S.open) return;
        const w = $machine.offsetWidth;
        const hgt = $machine.offsetHeight;
        if (!w || !hgt) return;
        const scale = Math.min((innerWidth * 0.94) / w, (innerHeight * 0.88) / hgt, 1.4);
        $scaler.style.transform = `scale(${scale})`;
    }

    function clearTimers() {
        S.timers.forEach((id) => { clearTimeout(id); clearInterval(id); });
        S.timers = [];
    }

    /* ───────────── context handed to layouts ───────────── */

    const ctx = {
        t,
        money,
        sfx: Sfx,
        get state() { return S; },

        isLocked: () => S.busy || S.purchased,

        priceOf(item, sizeIndex) {
            let mult = 1;
            if (S.machine && S.machine.sizes) {
                const size = S.machine.sizes[(sizeIndex || 1) - 1];
                mult = size ? size.multiplier || 1 : 1;
            }
            return Math.floor(item.price * mult + 0.5);
        },

        async buy(item, payment, size) {
            if (S.busy || S.purchased) return { ok: false };
            S.busy = true;
            $machine.classList.add('locked');

            const res = (await post('purchase', { item: item.name, payment, size })) || { ok: false, reason: 'failed' };
            S.busy = false;

            if (res.balance) {
                S.balance = res.balance;
                S.layout && S.layout.updateBalance && S.layout.updateBalance();
            }
            if (res.stock) applyStock(res.stock);

            if (!res.ok) {
                $machine.classList.remove('locked');
                Sfx.error();
                return res;
            }
            S.purchased = true;
            return res;
        },

        armTake() {
            $machine.classList.add('awaiting-take');
            const ms = Number(S.ui.autoTake) || 0;
            if (ms > 0) S.timers.push(setTimeout(() => ctx.take(), ms));
        },

        take() {
            if (!S.purchased || S.taken) return;
            S.taken = true;
            Sfx.flap();
            post('take');
            setTimeout(hide, 260);
        },

        close() {
            if (S.busy) return;
            post('close');
            hide();
        },

        interval(fn, ms) {
            S.timers.push(setInterval(fn, ms));
        },
    };

    /* ───────────── open / close ───────────── */

    function open(data) {
        clearTimers();
        Object.assign(S, {
            open: true,
            machine: data.machine,
            payment: data.payment || { cash: true },
            balance: data.balance || {},
            locale: data.locale || S.locale,
            ui: Object.assign({}, S.ui, data.ui || {}),
            imageTemplate: data.imageTemplate || null,
            busy: false,
            purchased: false,
            taken: false,
        });

        Sfx.configure(S.ui);

        const layout = Layouts[S.machine.layout] || Layouts.soda;
        $machine.className = `machine layout-${S.machine.layout} theme-${S.machine.theme}`;
        $machine.innerHTML = '';
        S.layout = layout($machine, S.machine, ctx);

        document.querySelectorAll('[data-l]').forEach((el) => { el.textContent = t(el.dataset.l); });

        $app.classList.remove('hidden', 'closing');
        requestAnimationFrame(fit);
    }

    function hide() {
        if (!S.open) return;
        S.open = false;
        clearTimers();
        $app.classList.add('closing');
        setTimeout(() => {
            if (S.open) return;
            $app.classList.add('hidden');
            $app.classList.remove('closing');
            $machine.innerHTML = '';
            S.layout = null;
        }, 230);
    }

    /* ───────────── events ───────────── */

    window.addEventListener('message', (e) => {
        const d = e.data || {};
        if (d.action === 'open') open(d);
        else if (d.action === 'close') hide();
    });

    window.addEventListener('keydown', (e) => {
        if (!S.open) return;
        if (e.key === 'Escape') return ctx.close();
        if (!ctx.isLocked() && S.layout && S.layout.onKey) S.layout.onKey(e);
    });

    window.addEventListener('resize', fit);

    /* ───────────── browser dev preview ───────────── */

    const Mock = {
        balance: { cash: 250, bank: 4200 },
        post(name, data) {
            if (name !== 'purchase') {
                if (name === 'close' || name === 'take') setTimeout(() => Mock.toolbar && Mock.toolbar.classList.add('show'), 300);
                return Promise.resolve({ ok: true });
            }
            const item = S.machine.items.find((i) => i.name === data.item);
            const price = ctx.priceOf(item, data.size);
            if (item.stock === 0) return wait(200).then(() => ({ ok: false, reason: 'sold_out' }));
            if (Mock.balance[data.payment] < price) return wait(200).then(() => ({ ok: false, reason: 'no_money' }));
            Mock.balance[data.payment] -= price;
            const stock = {};
            S.machine.items.forEach((i) => { stock[i.name] = i.name === item.name ? i.stock - 1 : i.stock; });
            return wait(250).then(() => ({ ok: true, price, balance: { ...Mock.balance }, stock }));
        },
    };

    if (!IS_GAME) {
        document.body.classList.add('dev');

        const it = (name, label, price, kind, color, accent, extra = {}) => ({ name, label, price, kind, color, accent, stock: 3, ...extra });
        const machines = {
            ecola: { id: 'ecola', brand: 'eCola', tagline: 'Deliciously Infectious!', layout: 'soda', theme: 'ecola', items: [
                it('ecola', 'eCola', 4, 'can', '#c4161c', '#ffffff'), it('ecola_light', 'eCola Light', 4, 'can', '#d9d9d9', '#c4161c'),
                it('ecola_cherry', 'eCola Cherry', 5, 'can', '#6d0f2a', '#ff4d6d', { stock: 0 }), it('orangotang', 'Orang-O-Tang', 4, 'can', '#ff7a00', '#3b1d00'),
                it('junk_energy', 'Junk Energy', 6, 'can', '#1b1b1b', '#b6ff00'), it('water', 'Raine Water', 3, 'bottle', '#7cc6f2', '#ffffff')] },
            sprunk: { id: 'sprunk', brand: 'Sprunk', tagline: 'The Essence of Life', layout: 'soda', theme: 'sprunk', items: [
                it('sprunk', 'Sprunk', 4, 'can', '#2fb344', '#e9ff5c'), it('sprunk_light', 'Sprunk Light', 4, 'can', '#c9f2b0', '#1e7a2f'),
                it('sprunk_xtreme', 'Sprunk Xtreme', 5, 'can', '#0c3b16', '#7dff3a'), it('orangotang', 'Orang-O-Tang', 4, 'can', '#ff7a00', '#3b1d00'),
                it('junk_energy', 'Junk Energy', 6, 'can', '#1b1b1b', '#b6ff00'), it('water', 'Raine Water', 3, 'bottle', '#7cc6f2', '#ffffff')] },
            raine: { id: 'raine', brand: 'Raine', tagline: 'Bottled at the source. Probably.', layout: 'soda', theme: 'raine', items: [
                it('water', 'Still Water', 3, 'bottle', '#8fd3fe', '#ffffff'), it('water_sparkling', 'Sparkling Water', 3, 'bottle', '#b7e9ff', '#2b7bb9'),
                it('water_lemon', 'Lemon Water', 4, 'bottle', '#f6f1a0', '#2b7bb9'), it('sports_drink', 'Electrolyte+', 5, 'bottle', '#40a9ff', '#ffffff')] },
            snacks: { id: 'snacks', brand: 'SnackStop', tagline: 'Fuel for the streets', layout: 'glass', theme: 'snack', items: [
                it('egochaser', 'EgoChaser', 3, 'bar', '#f2c200', '#3a1f00'), it('meteorite', 'Meteorite', 3, 'bar', '#3b1f6b', '#ffcf33'),
                it('psqs', "P's & Q's", 2, 'candy', '#ff4fa3', '#ffffff'), it('sweet_nothings', 'Sweet Nothings', 2, 'candy', '#7a5cff', '#ffe066'),
                it('phat_chips', 'Phat Chips', 4, 'bag', '#e63946', '#ffd166'), it('phat_chips_bbq', 'Phat Chips BBQ', 4, 'bag', '#6a2c0b', '#ff9f1c', { stock: 0 }),
                it('big_cheese', 'Big Cheese', 4, 'bag', '#ffb703', '#023047'), it('sandwich', 'Club Sandwich', 7, 'bar', '#e9d8a6', '#386641')] },
            coffee: { id: 'coffee', brand: 'Bean Machine', tagline: 'Freshly ground · Served hot', layout: 'coffee', theme: 'coffee',
                sizes: [{ label: 'S', name: 'Small', multiplier: 1 }, { label: 'M', name: 'Medium', multiplier: 1.25 }, { label: 'L', name: 'Large', multiplier: 1.5 }],
                items: [
                    it('coffee', 'Black Coffee', 3, 'cup', '#3b2416', '#f5e6d3', { icon: '☕' }), it('espresso', 'Espresso', 3, 'cup', '#24150c', '#c58b4c', { icon: '◉' }),
                    it('cappuccino', 'Cappuccino', 4, 'cup', '#a47148', '#fff3e0', { icon: '☁' }), it('latte', 'Caffè Latte', 4, 'cup', '#c69c72', '#fffaf0', { icon: '❖' }),
                    it('hot_choco', 'Hot Chocolate', 4, 'cup', '#5a3220', '#ffd6a5', { icon: '✦' }), it('tea', 'Green Tea', 3, 'cup', '#6b8f3a', '#f1ffe0', { icon: '❦' })] },
            cigarettes: { id: 'cigarettes', brand: 'Redwood', tagline: 'Smoke like a real man', layout: 'retro', theme: 'redwood', payment: { cash: true, bank: false }, items: [
                it('redwood', 'Redwood', 9, 'pack', '#b3001b', '#ffffff'), it('redwood_gold', 'Redwood Gold', 11, 'pack', '#c9a227', '#2b1a00'),
                it('debonaire', 'Debonaire', 10, 'pack', '#13315c', '#e0e1dd'), it('cardiaque', 'Cardiaque', 10, 'pack', '#1b4332', '#d8f3dc'),
                it('lighter', 'Lighter', 2, 'pack', '#f77f00', '#003049')] },
        };

        const bar = h('div', 'dev-toolbar show');
        Mock.toolbar = bar;
        bar.innerHTML = '<b>kd-vendingmachine · dev preview</b>';
        for (const [id, m] of Object.entries(machines)) {
            const b = h('button', '', esc(m.brand));
            b.addEventListener('click', () => {
                bar.classList.remove('show');
                const copy = JSON.parse(JSON.stringify(m));
                open({
                    machine: copy,
                    payment: m.payment || { cash: true, bank: true },
                    balance: { ...Mock.balance },
                    ui: { currency: '$', sound: true, volume: 0.35, showBalance: true, autoTake: 8000 },
                    locale: {
                        close_hint: 'ESC to walk away', choose_drink: 'Choose your drink', credit_ready: 'CREDIT READY · PULL KNOB',
                        take_drink: 'TAKE YOUR DRINK', take_coffee: 'ENJOY YOUR COFFEE', take: 'TAKE YOUR ITEM',
                        no_money: 'INSUFFICIENT FUNDS', clear: 'CLR', vending: 'VENDING...', coin_return: 'COIN RETURN',
                    },
                });
            });
            bar.appendChild(b);
            if (new URLSearchParams(location.search).get('machine') === id) setTimeout(() => b.click(), 50);
        }
        document.body.appendChild(bar);
    }
})();
