/**
 * Machine layouts. Each layout builds its own machine front inside `root` and drives
 * its own purchase flow, using the shared components below.
 *
 *   Layouts[name](root, machine, ctx) -> { updateStock?, updateBalance?, onKey? }
 */
const Layouts = {};

/* ───────────────────────────── shared components ───────────────────────────── */

function Lcd(extra = '') {
    const el = h('div', `lcd ${extra}`, '<div class="lcd-glass"><div class="lcd-line l1"></div><div class="lcd-line l2"></div></div>');
    const l1 = el.querySelector('.l1');
    const l2 = el.querySelector('.l2');
    let timer = null;

    const set = (a = '', b = '', mode = '') => {
        clearTimeout(timer);
        l1.textContent = a;
        l2.textContent = b;
        el.dataset.mode = mode;
    };
    const flash = (a, b, mode, ms, after) => {
        set(a, b, mode);
        timer = setTimeout(() => after && after(), ms);
    };
    return { el, set, flash };
}

function Payment(ctx, onPay) {
    const { t, money } = ctx;
    const S = ctx.state;
    const el = h('div', 'payment');
    const mods = {};

    if (S.payment.cash) {
        mods.cash = h('button', 'pay-mod pay-cash', `
            <div class="bill-slot"><span class="bill-arrows">&#9654;&#9654;&#9654;</span><i class="bill"></i></div>
            <div class="coin-slot"><i></i></div>
            <div class="pay-label">${esc(t('insert_cash'))}</div>
            <div class="pay-balance"></div>`);
    }
    if (S.payment.bank) {
        mods.bank = h('button', 'pay-mod pay-card', `
            <div class="nfc"><i></i><i></i><i></i></div>
            <div class="leds"><i></i><i></i><i></i><i></i></div>
            <div class="pay-label">${esc(t('tap_card'))}</div>
            <div class="pay-balance"></div>`);
    }

    for (const [key, mod] of Object.entries(mods)) {
        mod.addEventListener('click', () => {
            if (el.classList.contains('disabled') || ctx.isLocked()) return;
            onPay(key, mod);
        });
        el.appendChild(mod);
    }
    el.style.setProperty('--n', Object.keys(mods).length || 1);

    const updateBalance = () => {
        for (const [key, mod] of Object.entries(mods)) {
            const v = S.balance ? S.balance[key] : null;
            mod.querySelector('.pay-balance').textContent = S.ui.showBalance && v != null ? money(v) : '';
        }
    };
    updateBalance();

    const processing = (key) => {
        const mod = mods[key];
        if (!mod) return;
        mod.classList.remove('ok', 'fail');
        mod.classList.add('busy');
        key === 'cash' ? ctx.sfx.bill() : ctx.sfx.beep();
    };

    const result = (key, ok) => {
        const mod = mods[key];
        if (!mod) return;
        mod.classList.remove('busy');
        mod.classList.add(ok ? 'ok' : 'fail');
        if (ok) key === 'cash' ? ctx.sfx.coin() : ctx.sfx.card();
        setTimeout(() => mod.classList.remove('ok', 'fail'), 1600);
    };

    return { el, mods, updateBalance, processing, result };
}

function Tray(ctx, extra = '') {
    const el = h('div', `tray ${extra}`, `
        <div class="tray-opening"><div class="tray-item"></div></div>
        <div class="tray-flap"><span>${esc(ctx.t('push'))}</span></div>`);
    const slot = el.querySelector('.tray-item');

    el.addEventListener('click', () => {
        if (!el.classList.contains('ready')) return;
        el.classList.add('taken');
        ctx.take();
    });

    const drop = async (item) => {
        slot.innerHTML = '';
        const p = Product(item, ctx);
        p.classList.add('dropping');
        slot.appendChild(p);
        await wait(470);
        ctx.sfx.thunk();
        await wait(320);
        el.classList.add('ready');
    };
    return { el, drop };
}

/** Payment -> server -> LCD feedback. Resolves with the server result or null on failure. */
async function transact(ctx, { lcd, payment, item, key, size, onFail }) {
    const price = ctx.money(ctx.priceOf(item, size));
    payment.processing(key);
    lcd.set(item.label.toUpperCase(), key === 'bank' ? `${price}  · · ·` : price, 'busy');

    const [res] = await Promise.all([ctx.buy(item, key, size), wait(key === 'bank' ? 950 : 750)]);
    payment.result(key, !!res.ok);

    if (!res.ok) {
        lcd.flash(ctx.t(res.reason || 'failed'), price, 'error', 2200, onFail);
        return null;
    }
    lcd.set(ctx.t('approved'), item.label.toUpperCase(), 'ok');
    await wait(550);
    return res;
}

function returnRow(ctx) {
    const row = h('div', 'return-row', `<button class="coin-return">${esc(ctx.t('coin_return'))}</button><i class="return-cup"></i>`);
    row.querySelector('.coin-return').addEventListener('click', () => { ctx.sfx.click(); ctx.close(); });
    return row;
}

function serial(m) {
    let n = 0;
    for (const c of m.id) n = (n * 31 + c.charCodeAt(0)) % 9000;
    return `KD-${m.layout.toUpperCase().slice(0, 2)}${1000 + n}`;
}

/* ───────────────────────────── SODA (eCola / Sprunk / Raine) ───────────────────────────── */

Layouts.soda = (root, m, ctx) => {
    const { t, money } = ctx;
    let selected = null;

    root.innerHTML = `
    <div class="cabinet">
        <section class="front">
            <header class="marquee">
                <div class="logo">${esc(m.brand)}</div>
                <div class="tagline">${esc(m.tagline || '')}</div>
                <i class="swoosh"></i><i class="swoosh s2"></i>
            </header>
            <div class="showcase"><div class="samples"></div><i class="shelf"></i><i class="showcase-light"></i><i class="glare"></i></div>
            <div class="art">
                <div class="bubbles"></div>
                <div class="art-logo">${esc(m.brand)}</div>
                <div class="art-sub">${m.theme === 'raine' ? 'PURE &middot; FRESH &middot; CLEAR' : 'ICE COLD &middot; ICE COLD &middot; ICE COLD'}</div>
            </div>
            <div class="port-wrap"></div>
        </section>
        <aside class="controls">
            <div class="slot-lcd"></div>
            <div class="selections"></div>
            <div class="slot-pay"></div>
            <div class="slot-return"></div>
            <div class="plate">${serial(m)} &middot; SERVICE 1-800-KD-VEND</div>
        </aside>
    </div>`;

    const $ = (s) => root.querySelector(s);

    // bubbles / droplets
    const bubbles = $('.bubbles');
    for (let i = 0; i < 16; i++) {
        const b = h('i');
        const size = 6 + Math.random() * 22;
        b.style.cssText = `left:${Math.random() * 100}%;width:${size}px;height:${size}px;animation-duration:${4 + Math.random() * 6}s;animation-delay:-${Math.random() * 8}s`;
        bubbles.appendChild(b);
    }

    // showcase samples
    const samples = $('.samples');
    m.items.forEach((item) => {
        const s = h('div', 'sample', `<div class="sample-tag">${esc(item.label)}</div>`);
        s.prepend(Product(item, ctx));
        samples.appendChild(s);
    });

    const lcd = Lcd();
    $('.slot-lcd').appendChild(lcd.el);
    const idle = () => (selected ? showSelected() : lcd.set(m.brand.toUpperCase(), t('select')));

    const tray = Tray(ctx, 'port');
    $('.port-wrap').appendChild(tray.el);

    // selection buttons
    const list = $('.selections');
    const buttons = m.items.map((item, i) => {
        const b = h('button', 'sel', `<i class="led"></i><span class="name">${esc(item.label)}</span><span class="price">${money(item.price)}</span><span class="so">${esc(t('sold_out'))}</span>`);
        b.addEventListener('click', () => select(i));
        list.appendChild(b);
        return b;
    });

    function showSelected() {
        const item = m.items[selected];
        lcd.set(item.label.toUpperCase(), `${money(item.price)} · ${t('pay_now')}`);
    }

    function select(i) {
        if (ctx.isLocked()) return;
        const item = m.items[i];
        ctx.sfx.click();
        if (item.stock === 0) {
            ctx.sfx.error();
            return lcd.flash(t('sold_out'), item.label.toUpperCase(), 'error', 1500, idle);
        }
        selected = i;
        buttons.forEach((b, j) => b.classList.toggle('selected', j === i));
        showSelected();
    }

    const payment = Payment(ctx, async (key) => {
        if (selected == null) {
            ctx.sfx.error();
            return lcd.flash(t('select'), '', 'warn', 1400, idle);
        }
        const item = m.items[selected];
        const res = await transact(ctx, { lcd, payment, item, key, onFail: idle });
        if (!res) return;

        lcd.set(t('vending'), '', 'busy');
        root.classList.add('vending');
        ctx.sfx.motor(1.1);
        await wait(1100);
        await tray.drop(item);
        lcd.set(t('take_drink'), t('thank_you'), 'ok');
        ctx.armTake();
    });
    $('.slot-pay').appendChild(payment.el);
    $('.slot-return').appendChild(returnRow(ctx));

    const updateStock = () => buttons.forEach((b, i) => b.classList.toggle('soldout', m.items[i].stock === 0));
    updateStock();
    idle();

    return { updateStock, updateBalance: payment.updateBalance };
};

/* ───────────────────────────── GLASS FRONT (snacks) ───────────────────────────── */

Layouts.glass = (root, m, ctx) => {
    const { t, money } = ctx;
    const LETTERS = 'ABCD';
    const n = m.items.length;
    const cols = Math.min(6, Math.max(3, Math.ceil(n / 4)));
    const rows = Math.min(4, Math.ceil(n / cols));
    let code = '';
    let selected = null;

    root.innerHTML = `
    <div class="cabinet">
        <header class="header">
            <div class="neon">${esc(m.brand)}</div>
            <div class="tagline">${esc(m.tagline || '')}</div>
        </header>
        <div class="main">
            <div class="glass" style="--rows:${rows};--cols:${cols}"><i class="glass-light"></i><i class="glare"></i></div>
            <aside class="panel">
                <div class="slot-lcd"></div>
                <div class="keypad"></div>
                <div class="slot-pay"></div>
                <div class="slot-return"></div>
            </aside>
        </div>
        <div class="slot-tray"></div>
    </div>`;

    const $ = (s) => root.querySelector(s);
    const glass = $('.glass');
    const slots = [];

    for (let r = 0; r < rows; r++) {
        const row = h('div', 'shelf-row');
        for (let c = 0; c < cols; c++) {
            const idx = r * cols + c;
            const item = m.items[idx];
            const slotCode = `${LETTERS[r]}${c + 1}`;
            const slot = h('div', `slot${item ? '' : ' empty'}`, `
                <div class="product-wrap"></div>
                <i class="coil"></i>
                <div class="tag"><b>${slotCode}</b>${item ? `<span>${money(item.price)}</span>` : ''}</div>`);
            if (item) {
                slot.querySelector('.product-wrap').appendChild(Product(item, ctx));
                slot.title = item.label;
                slot.addEventListener('click', () => {
                    if (ctx.isLocked()) return;
                    code = slotCode;
                    ctx.sfx.key();
                    resolve();
                });
            }
            slots[idx] = slot;
            row.appendChild(slot);
        }
        glass.appendChild(row);
    }

    const lcd = Lcd();
    $('.slot-lcd').appendChild(lcd.el);

    const idle = () => {
        if (selected != null) return showSelected();
        lcd.set(code ? code : t('enter_code'), code ? '' : t('select'));
    };

    function showSelected() {
        const item = m.items[selected];
        lcd.set(`${code} ${item.label.toUpperCase()}`, `${money(item.price)} · ${t('pay_now')}`);
    }

    function highlight() {
        slots.forEach((s, i) => s && s.classList.toggle('selected', i === selected));
    }

    function reset() {
        code = '';
        selected = null;
        highlight();
        idle();
    }

    function resolve() {
        const r = LETTERS.indexOf(code[0]);
        const c = parseInt(code.slice(1), 10) - 1;
        const idx = r * cols + c;
        const item = r >= 0 && c >= 0 && c < cols ? m.items[idx] : null;

        if (!item) {
            ctx.sfx.error();
            const bad = code;
            code = '';
            selected = null;
            highlight();
            return lcd.flash(t('invalid'), bad, 'error', 1500, idle);
        }
        if (item.stock === 0) {
            ctx.sfx.error();
            const bad = code;
            code = '';
            selected = null;
            highlight();
            return lcd.flash(t('sold_out'), `${bad} ${item.label.toUpperCase()}`, 'error', 1500, idle);
        }
        selected = idx;
        highlight();
        showSelected();
    }

    function press(k) {
        if (ctx.isLocked()) return;
        ctx.sfx.key();
        if (k === 'CLR') return reset();
        if (k === 'OK') return code.length >= 2 ? resolve() : (ctx.sfx.error(), lcd.flash(t('enter_code'), '', 'warn', 1000, idle));

        if (LETTERS.includes(k)) {
            code = k;
            selected = null;
            highlight();
            return idle();
        }
        if (/^[0-9]$/.test(k)) {
            if (!code || code.length >= 2) {
                ctx.sfx.error();
                return lcd.flash(t('enter_code'), 'A-D', 'warn', 1000, idle);
            }
            code += k;
            resolve();
        }
    }

    // keypad
    const keypad = $('.keypad');
    ['A', 'B', 'C', 'D', '1', '2', '3', '4', '5', '6', 'CLR', 'OK'].forEach((k) => {
        const cls = LETTERS.includes(k) ? 'letter' : k === 'CLR' ? 'clr' : k === 'OK' ? 'ok' : 'digit';
        const label = k === 'CLR' ? t('clear') : k === 'OK' ? t('ok') : k;
        const b = h('button', `key ${cls}`, esc(label));
        b.addEventListener('click', () => press(k));
        keypad.appendChild(b);
    });

    const tray = Tray(ctx, 'wide');
    $('.slot-tray').appendChild(tray.el);

    const payment = Payment(ctx, async (key) => {
        if (selected == null) {
            ctx.sfx.error();
            return lcd.flash(t('enter_code'), t('select'), 'warn', 1400, idle);
        }
        const idx = selected;
        const item = m.items[idx];
        const res = await transact(ctx, { lcd, payment, item, key, onFail: idle });
        if (!res) return;

        lcd.set(t('vending'), `${code} ${item.label.toUpperCase()}`, 'busy');
        const slot = slots[idx];
        slot.classList.add('vending');
        ctx.sfx.motor(1.3);
        await wait(1250);
        await tray.drop(item);
        lcd.set(t('take'), t('thank_you'), 'ok');
        ctx.armTake();
        setTimeout(() => { slot.classList.remove('vending'); updateStock(); }, 900);
    });
    $('.slot-pay').appendChild(payment.el);
    $('.slot-return').appendChild(returnRow(ctx));

    const updateStock = () => m.items.forEach((item, i) => {
        if (slots[i] && !slots[i].classList.contains('vending')) slots[i].classList.toggle('soldout', item.stock === 0);
    });
    updateStock();
    idle();

    const onKey = (e) => {
        const k = e.key.toUpperCase();
        if (LETTERS.includes(k) || /^[1-6]$/.test(k)) press(k);
        else if (e.key === 'Backspace') press('CLR');
        else if (e.key === 'Enter') press('OK');
    };

    return { updateStock, updateBalance: payment.updateBalance, onKey };
};

/* ───────────────────────────── COFFEE (touchscreen) ───────────────────────────── */

Layouts.coffee = (root, m, ctx) => {
    const { t, money } = ctx;
    const sizes = m.sizes && m.sizes.length ? m.sizes : null;
    let selected = null;
    let size = sizes ? Math.min(2, sizes.length) : 1;
    let sugar = 1;
    let strength = 3;

    root.innerHTML = `
    <div class="cabinet">
        <section class="left">
            <header class="coffee-header">
                <div class="bean"></div>
                <div>
                    <div class="logo">${esc(m.brand)}</div>
                    <div class="tagline">${esc(m.tagline || '')}</div>
                </div>
            </header>
            <div class="screen">
                <div class="screen-top"><h2>${esc(t('choose_drink'))}</h2><span class="clock"></span></div>
                <div class="drinks"></div>
                <div class="opts">
                    <div class="opt opt-size"><label>${esc(t('size'))}</label><div class="seg"></div></div>
                    <div class="opt"><label>${esc(t('sugar'))}</label><div class="stepper" data-k="sugar"><button class="stp">&minus;</button><div class="dots"></div><button class="stp">+</button></div></div>
                    <div class="opt"><label>${esc(t('strength'))}</label><div class="stepper" data-k="strength"><button class="stp">&minus;</button><div class="dots beans"></div><button class="stp">+</button></div></div>
                </div>
                <div class="paybar"><div><div class="sel-name">&mdash;</div><div class="total">${money(0)}</div></div><div class="pay-hint">${esc(t('pay_now'))} &rarr;</div></div>
                <div class="brew"><div class="ring"><span>0%</span></div><div class="brew-label">${esc(t('brewing'))}</div><div class="brew-name"></div></div>
                <i class="screen-glare"></i>
            </div>
        </section>
        <aside class="right">
            <div class="slot-lcd"></div>
            <div class="cup-bay">
                <i class="bay-light"></i><i class="nozzle"></i><i class="stream"></i>
                <div class="cup-slot"></div>
                <div class="steam"><i></i><i></i><i></i></div>
                <i class="grill"></i>
                <div class="bay-label">${esc(t('take_coffee'))}</div>
            </div>
            <div class="slot-pay"></div>
            <div class="slot-return"></div>
        </aside>
    </div>`;

    const $ = (s) => root.querySelector(s);

    const clock = $('.clock');
    const tick = () => { clock.textContent = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }); };
    tick();
    ctx.interval(tick, 10000);

    const lcd = Lcd('small');
    $('.slot-lcd').appendChild(lcd.el);
    const idle = () => lcd.set(m.brand.toUpperCase(), selected != null ? `${money(ctx.priceOf(m.items[selected], size))} · ${t('pay_now')}` : t('select'));

    // drinks
    const drinksEl = $('.drinks');
    const cards = m.items.map((item, i) => {
        const card = h('button', 'drink', `
            <span class="ico" style="--c1:${esc(item.color)};--c2:${esc(item.accent)}">${esc(item.icon || '☕')}</span>
            <span><span class="nm">${esc(item.label)}</span><span class="pr">${money(ctx.priceOf(item, 1))}</span></span>
            <span class="so">${esc(t('sold_out'))}</span>`);
        card.addEventListener('click', () => {
            if (ctx.isLocked() || item.stock === 0) return;
            ctx.sfx.beep();
            selected = i;
            render();
        });
        drinksEl.appendChild(card);
        return card;
    });

    // sizes
    const seg = $('.seg');
    if (sizes) {
        sizes.forEach((s, i) => {
            const b = h('button', '', esc(s.label));
            b.title = s.name;
            b.addEventListener('click', () => { if (ctx.isLocked()) return; ctx.sfx.beep(); size = i + 1; render(); });
            seg.appendChild(b);
        });
    } else {
        $('.opt-size').style.visibility = 'hidden';
    }

    // steppers (cosmetic, but it's a coffee machine - people expect them)
    const steppers = { sugar: { el: root.querySelector('[data-k=sugar]'), max: 4 }, strength: { el: root.querySelector('[data-k=strength]'), max: 5 } };
    for (const [k, s] of Object.entries(steppers)) {
        const [minus, plus] = s.el.querySelectorAll('.stp');
        const dots = s.el.querySelector('.dots');
        for (let i = 0; i < s.max; i++) dots.appendChild(h('i'));
        const change = (d) => {
            if (ctx.isLocked()) return;
            ctx.sfx.beep();
            if (k === 'sugar') sugar = Math.max(0, Math.min(s.max, sugar + d));
            else strength = Math.max(1, Math.min(s.max, strength + d));
            render();
        };
        minus.addEventListener('click', () => change(-1));
        plus.addEventListener('click', () => change(1));
    }

    function render() {
        cards.forEach((c, i) => {
            c.classList.toggle('active', i === selected);
            c.classList.toggle('soldout', m.items[i].stock === 0);
            c.querySelector('.pr').textContent = money(ctx.priceOf(m.items[i], size));
        });
        seg.querySelectorAll('button').forEach((b, i) => b.classList.toggle('on', i + 1 === size));
        steppers.sugar.el.querySelectorAll('.dots i').forEach((d, i) => d.classList.toggle('on', i < sugar));
        steppers.strength.el.querySelectorAll('.dots i').forEach((d, i) => d.classList.toggle('on', i < strength));

        const item = selected != null ? m.items[selected] : null;
        $('.sel-name').textContent = item ? `${item.label}${sizes ? ` · ${sizes[size - 1].name}` : ''}` : '—';
        $('.total').textContent = money(item ? ctx.priceOf(item, size) : 0);
        root.querySelector('.paybar').classList.toggle('ready', !!item);
        idle();
    }

    const bay = $('.cup-bay');
    const cupSlot = $('.cup-slot');
    bay.addEventListener('click', () => {
        if (!bay.classList.contains('ready')) return;
        bay.classList.add('taken');
        ctx.take();
    });

    function brew(item) {
        return new Promise((done) => {
            const overlay = $('.brew');
            const ring = $('.ring');
            const pct = ring.querySelector('span');
            $('.brew-name').textContent = `${item.label}${sizes ? ` · ${sizes[size - 1].name}` : ''}`;
            overlay.classList.add('on');

            cupSlot.innerHTML = '';
            const cup = Product(item, ctx);
            cup.classList.add('cup-drop');
            cupSlot.appendChild(cup);
            setTimeout(() => ctx.sfx.soft(), 380);

            const duration = 3600;
            const start = performance.now();
            let pouring = false;
            ctx.sfx.brew(duration / 1000 - 0.4);

            const frame = (now) => {
                const p = Math.min(1, (now - start) / duration);
                ring.style.setProperty('--p', (p * 100).toFixed(1));
                pct.textContent = `${Math.floor(p * 100)}%`;
                if (!pouring && p > 0.14) { pouring = true; bay.classList.add('pouring'); }
                if (pouring && p > 0.9) bay.classList.remove('pouring');
                if (p < 1) return requestAnimationFrame(frame);
                overlay.classList.remove('on');
                bay.classList.add('steaming', 'ready');
                done();
            };
            requestAnimationFrame(frame);
        });
    }

    const payment = Payment(ctx, async (key) => {
        if (selected == null) {
            ctx.sfx.error();
            return lcd.flash(t('choose_drink').toUpperCase(), '', 'warn', 1400, idle);
        }
        const item = m.items[selected];
        const res = await transact(ctx, { lcd, payment, item, key, size, onFail: idle });
        if (!res) return;
        lcd.set(t('brewing'), item.label.toUpperCase(), 'busy');
        await brew(item);
        lcd.set(t('take_coffee'), t('thank_you'), 'ok');
        ctx.armTake();
    });
    $('.slot-pay').appendChild(payment.el);
    $('.slot-return').appendChild(returnRow(ctx));

    render();
    return { updateStock: render, updateBalance: payment.updateBalance };
};

/* ───────────────────────────── RETRO (pull-knob cigarette machine) ───────────────────────────── */

Layouts.retro = (root, m, ctx) => {
    const { t, money } = ctx;
    let armed = null;

    root.innerHTML = `
    <div class="cabinet">
        <div class="face">
            <header class="marquee-r">
                <div class="bulbs top"></div>
                <div class="brand-r">${esc(m.brand)}</div>
                <div class="sub-r">${esc(m.tagline || '')}</div>
                <div class="bulbs bottom"></div>
            </header>
            <div class="windows" style="--n:${m.items.length}"></div>
            <div class="knobs" style="--n:${m.items.length}"></div>
            <div class="mech">
                <div class="slot-lcd"></div>
                <div class="slot-pay"></div>
                <div class="slot-return"></div>
            </div>
            <div class="slot-tray"></div>
        </div>
    </div>`;

    const $ = (s) => root.querySelector(s);

    root.querySelectorAll('.bulbs').forEach((row) => { for (let i = 0; i < 18; i++) row.appendChild(h('i')); });

    const lcd = Lcd('retro');
    $('.slot-lcd').appendChild(lcd.el);
    const idle = () => (armed ? lcd.set(t('credit_ready'), t(armed === 'bank' ? 'card' : 'cash')) : lcd.set(t('insert_coins'), t('exact_change')));

    const windowsEl = $('.windows');
    const knobsEl = $('.knobs');

    const wins = m.items.map((item) => {
        const w = h('div', 'win', `<div class="plate">${esc(item.label)}<b>${money(item.price)}</b></div><i class="glare"></i>`);
        w.dataset.so = t('sold_out');
        w.prepend(Product(item, ctx));
        windowsEl.appendChild(w);
        return w;
    });

    const knobs = m.items.map((item, i) => {
        const k = h('button', 'knob', '<i class="base"></i><i class="cap"></i>');
        k.addEventListener('click', () => pull(i, k));
        knobsEl.appendChild(k);
        return k;
    });

    const tray = Tray(ctx, 'chrome');
    $('.slot-tray').appendChild(tray.el);

    const disarm = () => {
        armed = null;
        knobsEl.classList.remove('armed');
        Object.values(payment.mods).forEach((mod) => mod.classList.remove('armed'));
    };

    const payment = Payment(ctx, (key, mod) => {
        if (armed === key) return;
        disarm();
        payment.processing(key);
        setTimeout(() => {
            payment.result(key, true);
            armed = key;
            mod.classList.add('armed');
            knobsEl.classList.add('armed');
            idle();
        }, 650);
    });
    $('.slot-pay').appendChild(payment.el);
    $('.slot-return').appendChild(returnRow(ctx));

    async function pull(i, knob) {
        if (ctx.isLocked()) return;
        const item = m.items[i];

        if (!armed) {
            ctx.sfx.error();
            return lcd.flash(t('insert_coins'), money(item.price), 'error', 1500, idle);
        }
        if (item.stock === 0) {
            ctx.sfx.error();
            return lcd.flash(t('sold_out'), item.label.toUpperCase(), 'error', 1500, idle);
        }

        knob.classList.remove('pulling');
        void knob.offsetWidth;
        knob.classList.add('pulling');
        ctx.sfx.knob();

        const key = armed;
        const [res] = await Promise.all([ctx.buy(item, key), wait(650)]);
        if (!res.ok) {
            disarm();
            return lcd.flash(t(res.reason || 'failed'), money(item.price), 'error', 2200, idle);
        }

        disarm();
        lcd.set(t('thank_you'), item.label.toUpperCase(), 'ok');
        await wait(350);
        await tray.drop(item);
        lcd.set(t('take'), t('thank_you'), 'ok');
        ctx.armTake();
    }

    const updateStock = () => wins.forEach((w, i) => {
        const out = m.items[i].stock === 0;
        w.classList.toggle('soldout', out);
        knobs[i].classList.toggle('soldout', out);
    });
    updateStock();
    idle();

    return { updateStock, updateBalance: payment.updateBalance };
};
