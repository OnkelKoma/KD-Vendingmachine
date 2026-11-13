/**
 * Shared DOM helpers + product rendering (drawn CSS products or inventory images).
 */
const h = (tag, cls, html) => {
    const el = document.createElement(tag);
    if (cls) el.className = cls;
    if (html != null) el.innerHTML = html;
    return el;
};

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const shortName = (label) => String(label || '').split(' ')[0].slice(0, 9);

/**
 * @param {object} item  product from the machine payload
 * @param {object} ctx   app context (for the image template)
 * @returns {HTMLElement}
 */
function Product(item, ctx) {
    const el = h('div', `product kind-${item.kind || 'can'}`);
    el.style.setProperty('--c1', item.color || '#888');
    el.style.setProperty('--c2', item.accent || '#fff');

    const drawn = () => {
        el.classList.remove('img');
        el.innerHTML = `<div class="shape"><i class="cap"></i><div class="body"><span class="brand">${esc(shortName(item.label))}</span></div><i class="base"></i></div>`;
    };

    const template = ctx && ctx.state.imageTemplate;
    const src = item.image || (template ? template.replace('%s', item.name) : null);

    if (src) {
        el.classList.add('img');
        const img = new Image();
        img.className = 'shape';
        img.draggable = false;
        img.alt = item.label;
        img.onerror = drawn;
        img.src = src;
        el.appendChild(img);
    } else {
        drawn();
    }
    return el;
}
