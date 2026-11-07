/* Taxista Rider prototype — core: icons, map, router, sheets, toasts, studio panel.
   All data is SAMPLE data. Nothing here talks to a server. */
'use strict';

/* ---------------- icons ---------------- */
const ICONS = {
  menu:'<path d="M4 6h16M4 12h16M4 18h16"/>',
  bell:'<path d="M6 9a6 6 0 1 1 12 0c0 6 2.5 8 2.5 8h-17S6 15 6 9z"/><path d="M10.3 20.5a2 2 0 0 0 3.4 0"/>',
  search:'<circle cx="11" cy="11" r="7"/><path d="M20.5 20.5l-4.2-4.2"/>',
  pin:'<path d="M12 21s-7-6.2-7-11a7 7 0 0 1 14 0c0 4.8-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/>',
  home:'<path d="M3 10.5 12 3l9 7.5V21h-6v-6H9v6H3z"/>',
  work:'<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M3 13h18"/>',
  clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  x:'<path d="M6 6l12 12M18 6 6 18"/>',
  chevL:'<path d="M15 6l-6 6 6 6"/>', chevR:'<path d="M9 6l6 6-6 6"/>', chevD:'<path d="M6 9l6 6 6-6"/>', chevU:'<path d="M6 15l6-6 6 6"/>',
  back:'<path d="M5 12h14M13 6l6 6-6 6"/>',
  car:'<path d="M4 16v-4l2-5h12l2 5v4"/><path d="M3 16h18v3h-3v-1H6v1H3z"/><path d="M7 12.5h.01M17 12.5h.01"/>',
  wallet:'<rect x="3" y="6" width="18" height="14" rx="2.5"/><path d="M3 10h18M16 15h2M6 6l9-3 1.5 3"/>',
  gift:'<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8S10.5 3.5 7.8 4.6C6 5.4 7.5 8 12 8zm0 0s1.5-4.5 4.2-3.4C18 5.4 16.5 8 12 8z"/>',
  star:'<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8-5.2-2.8-5.2 2.8 1-5.8L3.5 9.7l5.9-.8z"/>',
  heart:'<path d="M12 20s-8-4.9-8-10.5A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 8 2.5C20 15.1 12 20 12 20z"/>',
  user:'<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  settings:'<circle cx="12" cy="12" r="3"/><path d="M12 2.5v2.2M12 19.3v2.2M4.6 4.6l1.6 1.6M17.8 17.8l1.6 1.6M2.5 12h2.2M19.3 12h2.2M4.6 19.4l1.6-1.6M17.8 6.2l1.6-1.6"/><circle cx="12" cy="12" r="7"/>',
  globe:'<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3z"/>',
  phone:'<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2"/>',
  msg:'<path d="M4 5h16v11H9l-5 4z"/>',
  mic:'<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
  shield:'<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M12 8v5M12 16h.01"/>',
  alert:'<path d="M12 3.5 2.5 20h19z"/><path d="M12 10v4M12 17h.01"/>',
  check:'<path d="M5 12.5l4.5 4.5L19 7"/>',
  plus:'<path d="M12 5v14M5 12h14"/>', minus:'<path d="M5 12h14"/>',
  cal:'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  repeat:'<path d="M17 2l3 3-3 3"/><path d="M4 11V9a4 4 0 0 1 4-4h12"/><path d="M7 22l-3-3 3-3"/><path d="M20 13v2a4 4 0 0 1-4 4H4"/>',
  pause:'<path d="M8 5v14M16 5v14"/>', play:'<path d="M7 4l13 8-13 8z"/>',
  skip:'<path d="M5 5l10 7-10 7zM19 5v14"/>',
  edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
  trash:'<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>',
  share:'<circle cx="18" cy="5" r="2.5"/><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="19" r="2.5"/><path d="M8.2 10.8l7.6-4.5M8.2 13.2l7.6 4.5"/>',
  locate:'<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
  map:'<path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2z"/><path d="M9 4v14M15 6v14"/>',
  tag:'<path d="M3 12V4h8l10 10-8 8z"/><circle cx="7.5" cy="7.5" r="1.5"/>',
  cash:'<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M6 9v.01M18 15v.01"/>',
  card:'<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20M6 15h4"/>',
  history:'<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5M12 7v5l3 2"/>',
  help:'<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6V14M12 17h.01"/>',
  logout:'<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
  trophy:'<path d="M7 4h10v4a5 5 0 0 1-10 0z"/><path d="M7 6H4v1a3 3 0 0 0 3 3M17 6h3v1a3 3 0 0 1-3 3M12 13v4M8.5 20h7M9.5 17h5"/>',
  coins:'<ellipse cx="9" cy="7" rx="6" ry="3"/><path d="M3 7v4c0 1.7 2.7 3 6 3s6-1.3 6-3V7"/><path d="M9 14v3c0 1.7 2.7 3 6 3s6-1.3 6-3v-4c0-1.7-2.7-3-6-3"/>',
  wifiOff:'<path d="M2 2l20 20M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 5.2-2.8M19 13a10 10 0 0 0-2.2-1.6M12 20h.01"/>',
  lock:'<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
  send:'<path d="M21 3 10 14"/><path d="M21 3l-7 18-4-7-7-4z"/>',
  smile:'<circle cx="12" cy="12" r="9"/><path d="M8 14s1.5 2 4 2 4-2 4-2M9 9.5h.01M15 9.5h.01"/>',
  info:'<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
  route:'<circle cx="6" cy="19" r="2.5"/><circle cx="18" cy="5" r="2.5"/><path d="M8.5 19H16a3.5 3.5 0 0 0 0-7H8a3.5 3.5 0 0 1 0-7h7.5"/>',
  flag:'<path d="M5 21V4M5 4h12l-2 4 2 4H5"/>',
  sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
  moon:'<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
  sparkle:'<path d="M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2z"/>',
  headset:'<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="3" y="14" width="4" height="6" rx="1.5"/><rect x="17" y="14" width="4" height="6" rx="1.5"/>',
  list:'<path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01"/>',
  file:'<path d="M6 3h9l4 4v14H6z"/><path d="M12 10v4M12 17h.01"/>',
  nav:'<path d="M12 2.5l7 18-7-4-7 4z"/>',
  swap:'<path d="M7 4v16M3 8l4-4 4 4M17 20V4M13 16l4 4 4-4"/>',
  luggage:'<rect x="6" y="7" width="12" height="13" rx="2"/><path d="M9 7V4h6v3M9 11v5M15 11v5"/>',
  paw:'<circle cx="6.5" cy="10" r="1.6"/><circle cx="10" cy="6" r="1.6"/><circle cx="14" cy="6" r="1.6"/><circle cx="17.5" cy="10" r="1.6"/><path d="M8 17.5c0-2.5 1.8-4.5 4-4.5s4 2 4 4.5c0 1.6-1.4 2.5-4 2.5s-4-.9-4-2.5z"/>',
  volume:'<path d="M4 9h4l5-4v14l-5-4H4z"/><path d="M17 9a4 4 0 0 1 0 6"/>',
  users:'<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 14a6 6 0 0 1 3.5 6"/>',
  sliders:'<path d="M4 6h9M17 6h3M4 12h3M11 12h9M4 18h11M19 18h1"/><circle cx="15" cy="6" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="18" r="2"/>',
  copy:'<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h3"/>',
  ticket:'<path d="M3 8a2 2 0 0 0 0 4v0a2 2 0 0 1 0 4v2h18v-2a2 2 0 0 1 0-4 2 2 0 0 1 0-4V6H3z"/><path d="M14 6v12" stroke-dasharray="2 2"/>',
  download:'<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>',
  refresh:'<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>',
  dots:'<path d="M12 6h.01M12 12h.01M12 18h.01"/>',
  eye:'<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  palette:'<path d="M12 3a9 9 0 1 0 0 18c1.5 0 2-1 2-2s-1-1.5-1-2.5S14 15 15 15h2a4 4 0 0 0 4-4c0-4.4-4-8-9-8z"/><path d="M7.5 11h.01M10 7.5h.01M15 7.5h.01"/>',
  layers:'<path d="M12 3 2 8l10 5 10-5z"/><path d="M2 13l10 5 10-5"/>'
};
function I(n, cls){ return `<svg class="i ${cls||''}" viewBox="0 0 24 24" aria-hidden="true">${ICONS[n]||''}</svg>`; }

/* ---------------- helpers ---------------- */
const $ = (s, el=document) => el.querySelector(s);
const $$ = (s, el=document) => [...el.querySelectorAll(s)];
const money = v => `<span class="num">${Number(v).toFixed(2)}</span> د.ل`;
const esc = s => String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const reduced = () => document.documentElement.dataset.reduced === '1';
function wait(ms){ return new Promise(r => setTimeout(r, reduced()? Math.min(ms,30) : ms)); }

/* ---------------- map ---------------- */
// Stylised, not-to-scale sample map of Misrata (coast to the north-east). Coordinates 0..400 x 0..860.
const MAP_PTS = {
  me:[205,555], home:[205,555], work:[120,250], hospital:[285,330], square:[250,400], corniche:[330,250],
  airport:[70,760], port:[360,140], oldmarket:[262,452], ghiran:[110,470], zarrouq:[230,600], tripoli:[150,640],
  uni:[120,250], mall:[300,520], stadium:[180,380], driver:[372,616]
};
function buildBaseMap(){
  // Extended canvas (-300..700 x -300..1160) so zoomed-out maps never show an edge. Blocks are a cheap SVG pattern.
  const LAND = 'M-300 -300 H170 L215 0 C250 60 300 150 345 210 C380 260 430 300 700 330 V1160 H-300 Z';
  let s = `<defs><clipPath id="land"><path d="${LAND}"/></clipPath>
        <pattern id="blocks" width="34" height="30" patternUnits="userSpaceOnUse" patternTransform="rotate(-18 200 430)"><rect x="3" y="3" width="28" height="24" rx="3" fill="var(--map-block)"/></pattern>
        <filter id="soft" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="0" dy="1.5" stdDeviation="1.5" flood-opacity=".25"/></filter></defs>`;
  s += `<rect x="-300" y="-300" width="1000" height="1460" fill="var(--map-sea)"/>`;
  s += `<path d="${LAND}" fill="var(--map-road)"/>`;
  s += `<g clip-path="url(#land)"><rect x="-300" y="-300" width="1000" height="1460" fill="url(#blocks)"/>`;
  s += `<path d="M150 360 l46 -10 l12 40 l-48 12z" fill="var(--map-park)"/><circle cx="300" cy="470" r="22" fill="var(--map-park)"/><path d="M30 520 l60 -6 l6 48 l-62 6z" fill="var(--map-park)"/><path d="M-120 300 l70 -10 l10 60 l-75 8z" fill="var(--map-park)"/>`;
  const majors = ['M-300 900 L-10 640 L205 470 L250 400 L340 120 L360 -10','M-300 330 L180 330 L285 330 L700 280','M120 250 L180 330 L250 400 L300 520 L360 1160','M205 555 L205 470','M-100 1000 L60 760 L150 640 L205 555 L320 600 L700 660','M-300 470 L110 470 L205 470','M120 250 L60 120 L40 -300','M285 330 L330 250 L345 210','M300 520 L520 470'];
  majors.forEach(d => s += `<path d="${d}" fill="none" stroke="var(--map-case)" stroke-width="11" stroke-linecap="round" stroke-linejoin="round"/>`);
  majors.forEach(d => s += `<path d="${d}" fill="none" stroke="var(--map-major)" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"/>`);
  s += `</g>`;
  s += `<rect x="30" y="770" width="110" height="10" rx="4" transform="rotate(-25 85 775)" fill="var(--map-case)"/>`;
  const labels = [[78,340,'شارع طرابلس'],[300,95,'ميناء قصر أحمد'],[352,240,'الكورنيش'],[228,392,'ميدان النصر'],[82,240,'جامعة مصراتة'],[262,322,'المستشفى المركزي'],[60,800,'مطار مصراتة'],[92,462,'الغيران'],[236,612,'الزروق'],[300,540,'المجمع التجاري'],[430,40,'البحر المتوسط'],[-120,560,'طمينة'],[520,520,'الرملة']];
  labels.forEach(([x,y,t]) => s += `<text x="${x}" y="${y}" class="label" text-anchor="middle">${t}</text>`);
  return s;
}
let BASE_MAP = '';
function routePath(a, b){
  const A = MAP_PTS[a]||a, B = MAP_PTS[b]||b;
  if (a==='home' && b==='work') return 'M205 555 L205 470 L250 400 L180 330 L120 250';
  if (a==='driver') return 'M372 616 L320 600 L205 555';
  return `M${A[0]} ${A[1]} L205 470 L250 400 L${B[0]} ${B[1]}`;
}
/* opts: {route:[a,b], car:'approach'|'trip'|null, radar:bool, pins:[[pt,'pick'|'drop']], zoom, center:[x,y]} */
function mapHTML(opts={}){
  if (!BASE_MAP) BASE_MAP = buildBaseMap();
  const c = opts.center || MAP_PTS.me;
  const z = opts.zoom || 1;
  // translate so that center point sits at screen middle (svg 640x1376 rendering of 400x860 => scale 1.6)
  const tx = (200 - c[0]) * 1.6 * z, ty = (430 - c[1]) * 1.6 * z - (opts.oy||0);
  let over = '';
  if (opts.route){
    const d = typeof opts.route === 'string' ? opts.route : routePath(opts.route[0], opts.route[1]);
    over += `<path d="${d}" class="route-case"/><path id="rt" d="${d}" class="route draw"/>`;
  }
  if (opts.approach){
    over += `<path id="ap" d="${routePath('driver','me')}" fill="none" stroke="var(--ink-3)" stroke-width="4" stroke-dasharray="2 7" stroke-linecap="round"/>`;
  }
  if (opts.radar){
    const [x,y] = MAP_PTS.me;
    over += `<circle cx="${x}" cy="${y}" r="22" fill="var(--brand)" class="pulse"/><circle cx="${x}" cy="${y}" r="22" fill="var(--brand)" class="pulse d2"/><circle cx="${x}" cy="${y}" r="22" fill="var(--brand)" class="pulse d3"/>`;
    // idle nearby cars
    [[150,500,30],[262,600,-60],[240,470,110],[160,610,10],[300,560,80],[120,420,45]].forEach(([x,y,r]) => over += carSVG(x,y,r,.75));
  }
  (opts.pins||[]).forEach(([p,k], i) => {
    const [x,y] = MAP_PTS[p]||p;
    over += k==='dot'
      ? `<g filter="url(#soft)"><circle cx="${x}" cy="${y}" r="9" fill="var(--brand)" stroke="#fff" stroke-width="3.5"/></g>`
      : `<g class="pin-drop ${i?'d2':''}" style="transform-box:fill-box;transform-origin:bottom"><ellipse cx="${x}" cy="${y}" rx="4" ry="1.6" fill="rgba(0,0,0,.25)"/><image href="${k==='drop'?IMG.dropMarker:IMG.pickMarker}" x="${x-9}" y="${y-26}" width="18" height="26" preserveAspectRatio="xMidYMax meet"/></g>`;
  });
  if (opts.car) over += `<g id="mycar" transform="translate(-500 -500)"><circle r="15" fill="var(--brand)" opacity=".16"/><image href="${IMG.carTop}" x="-7" y="-13" width="14" height="26"/></g>`;
  if (opts.idleCars) [[150,500,30],[262,600,-60],[240,470,110],[300,560,80]].forEach(([x,y,r]) => over += carSVG(x,y,r,.75));
  return `<div class="map" data-map="1"><svg class="base" viewBox="-300 -300 1000 1460" style="transform:translate(calc(-50% + ${tx}px),calc(-50% + ${ty}px)) scale(${z})">${BASE_MAP}${over}</svg>
    ${opts.me!==false && !opts.centerPin ? `` : ''}</div>`;
}
function carSVG(x,y,r,s){
  return `<g transform="translate(${x} ${y}) rotate(${r}) scale(${(s||1)*.85})"><image href="${IMG.carTop}" x="-7" y="-13" width="14" height="26"/></g>`;
}
let carAnim = null;
function animateCar(root, pathId, ms, loop, onEnd){
  cancelAnimationFrame(carAnim);
  const path = root.querySelector('#'+pathId), car = root.querySelector('#mycar');
  if (!path || !car) return;
  const L = path.getTotalLength(); const t0 = performance.now();
  if (reduced()){ // no movement: park the car part-way along its path, and let the person move on by hand
    const p = path.getPointAtLength(L*.55), q = path.getPointAtLength(L*.55+1);
    car.setAttribute('transform', `translate(${p.x} ${p.y}) rotate(${Math.atan2(q.y-p.y, q.x-p.x)*180/Math.PI+90})`); return; }
  const step = now => {
    let k = Math.min(1, (now - t0) / (reduced()? 1 : ms));
    const p = path.getPointAtLength(L*k), q = path.getPointAtLength(Math.min(L, L*k+1));
    const ang = Math.atan2(q.y-p.y, q.x-p.x) * 180/Math.PI + 90;
    car.setAttribute('transform', `translate(${p.x} ${p.y}) rotate(${ang})`);
    if (k < 1) carAnim = requestAnimationFrame(step);
    else if (loop) { animateCar(root, pathId, ms, loop, onEnd); }
    else if (onEnd) onEnd();
  };
  carAnim = requestAnimationFrame(step);
}

/* ---------------- app state ---------------- */
const P = {
  theme: 'auto', sim: 'default', view: 'after',
  stack: [], screen: null, params: {},
  booking: { pick:'me', drop:null, mode:'fixed', veh:'eco', offer:12.5, coupon:null, pay:'cash', when:'now', prefs:[], forOther:null, noDest:false },
  rewards: { done:63, target:100, phase:'progress' }, // progress | pending | credited
  wallet: { own:32.25, credit:15.00 },
  notifUnread: 3, chatUnread: 1,
  rec: { status:'active' }, recAwait: true
};
function sampleBadge(){ return `<span class="tag warn" title="بيانات تجريبية">عيّنة</span>`; }

/* ---------------- router ---------------- */
const SCREENS = {};       // id -> {title, group, render(params) -> html, mount(el, params), states:[], dark?, statusLight?}
function screen(id, def){ SCREENS[id] = def; }
function pagesEl(){ return $('#pages'); }
function render(id, params){
  const def = SCREENS[id];
  if (!def) return `<div class="pad">Missing screen ${id}</div>`;
  if (P.view==='before' && def.before) return def.before(params||{}) + `<div class="ba-flag">التصميم الحالي (من الكود)</div>`;
  return def.render(params||{});
}
const TIMERS = [];
function later(fn, ms){ const t = setTimeout(fn, reduced()? Math.min(ms, 400) : ms); TIMERS.push(t); return t; }
function clearLater(){ while (TIMERS.length) clearTimeout(TIMERS.pop()); cancelAnimationFrame(carAnim); }
function go(id, params={}, opts={}){
  clearLater(); closeSheet(true); closeDrawer(true);
  const host = pagesEl();
  const prev = host.lastElementChild;
  if (opts.replace || opts.root){
    if (opts.root) P.stack = [];
    else P.stack.pop();
  }
  P.stack.push({id, params});
  const el = document.createElement('div');
  el.className = 'page ' + (opts.fade || !prev ? 'fade' : 'enter');
  el.dataset.screen = id;
  el.innerHTML = render(id, params);
  host.appendChild(el);
  if (prev){
    if (opts.replace || opts.root){ if (!opts.fade) el.className = 'page fade'; setTimeout(() => prev.remove(), 260); [...host.children].forEach(c => { if (c!==el && c!==prev) c.remove(); }); }
    else { prev.classList.remove('back-in','fade','enter'); prev.classList.add('under'); }
  }
  if (!(SCREENS[id]||{}).before && P.view==='before') P.view='after';
  // keep at most 2 rendered pages under the top for back animation
  while (host.children.length > 3) host.firstElementChild.remove();
  P.screen = id; P.params = params;
  afterNav(el, id, params);
}
function back(){
  if (closeSheet()) return;
  clearLater();
  if (closeDrawer()) return;
  if (P.stack.length <= 1){ if (P.screen !== 'home') go('home', {}, {root:true, fade:true}); return; }
  const host = pagesEl();
  const top = host.lastElementChild;
  P.stack.pop();
  const {id, params} = P.stack[P.stack.length-1];
  let under = top.previousElementSibling;
  if (!under || under.dataset.screen !== id){
    under = document.createElement('div'); under.className='page'; under.dataset.screen=id; under.innerHTML = render(id, params);
    host.insertBefore(under, top);
  } else { under.innerHTML = render(id, params); }
  under.classList.remove('under','enter','fade'); under.style.transform=''; void under.offsetWidth; under.classList.add('back-in');
  top.classList.remove('enter','fade','under'); top.classList.add('leave-back');
  setTimeout(() => top.remove(), 250);
  P.screen = id; P.params = params;
  afterNav(under, id, params);
}
function refresh(){
  clearLater();
  const top = pagesEl().lastElementChild; if (!top) return;
  const st = top.querySelector('.scroll')?.scrollTop || 0;
  top.innerHTML = render(P.screen, P.params);
  const sc = top.querySelector('.scroll'); if (sc) sc.scrollTop = st;
  afterNav(top, P.screen, P.params, true);
}
function afterNav(el, id, params, isRefresh){
  const def = SCREENS[id];
  const sb = $('#statusbar'); sb.classList.toggle('light', !!(def && def.statusLight && (def.statusLight===true || def.statusLight())));
  if (def && def.mount) def.mount(el, params, isRefresh);
  $$('.dock', el).forEach(enableDock);
  countUps(el);
  const ba = $('#baToggle'); if (ba){ ba.hidden = !(def && def.before); ba.querySelectorAll('button').forEach(b => b.classList.toggle('on', b.dataset.view===P.view)); }
  Studio.sync();
  try { history.replaceState(null, '', '#' + id); } catch(e){}
}

/* ---------------- sheets & dialogs ---------------- */
let sheetOpen = null;
function openSheet(html, opts={}){
  closeSheet(true);
  const layer = $('#sheets');
  layer.innerHTML = `<div class="scrim"></div><div class="${opts.dialog?'dialog':'sheet'}" role="dialog">${opts.dialog?'':'<div class="grab" aria-label="اسحب للإغلاق"></div>'}${html}</div>`;
  const scrim = layer.firstElementChild, sh = layer.lastElementChild;
  scrim.onclick = () => { if (!opts.sticky) closeSheet(); };
  requestAnimationFrame(() => { scrim.classList.add('on'); sh.classList.add('on'); });
  sheetOpen = {el: sh, onClose: opts.onClose};
  if (!opts.dialog) enableDrag(sh);
  if (opts.mount) opts.mount(sh);
  return sh;
}
function closeSheet(instant){
  if (!sheetOpen) return false;
  const layer = $('#sheets'); const s = sheetOpen; sheetOpen = null;
  const scrim = layer.querySelector('.scrim'); scrim && scrim.classList.remove('on');
  s.el.classList.remove('on'); s.el.style.transform = '';
  if (s.onClose) s.onClose();
  if (instant) layer.innerHTML = '';
  else setTimeout(() => { if (!sheetOpen) layer.innerHTML = ''; }, 300);
  return true;
}
function enableDrag(sh){
  // drag down from the handle or the title to close; a quick flick closes too; otherwise it springs back
  let y0 = null, dy = 0, t0 = 0;
  sh.addEventListener('pointerdown', e => { if (e.target.closest('.scroll,input,textarea,button:not(.grab),.chips,.list,.week')) return; y0 = e.clientY; t0 = performance.now(); dy = 0; sh.classList.add('dragging'); try{ sh.setPointerCapture(e.pointerId); }catch(_){} });
  sh.addEventListener('pointermove', e => { if (y0===null) return; const d = e.clientY - y0; dy = d > 0 ? d : d/5; sh.style.transform = `translateY(${dy}px)`; });
  const up = () => { if (y0===null) return; const v = dy / Math.max(1, performance.now()-t0); sh.classList.remove('dragging'); y0 = null; if (dy > 110 || (dy > 30 && v > .6)) closeSheet(); else sh.style.transform = ''; dy = 0; };
  sh.addEventListener('pointerup', up); sh.addEventListener('pointercancel', up);
}
function enableDock(dk){
  // page docks snap between open and a peek; tap the handle to toggle
  const grab = dk.querySelector('.grab'); if (!grab || dk.dataset.dock) return; dk.dataset.dock = '1';
  let y0 = null, dy = 0, base = 0, moved = false;
  const peek = () => Math.max(0, dk.offsetHeight - 150);
  const isCollapsed = () => dk.dataset.collapsed === '1';
  const setC = c => { dk.dataset.collapsed = c ? '1' : '0'; dk.style.transform = c ? `translateY(${peek()}px)` : ''; };
  grab.addEventListener('pointerdown', e => { y0 = e.clientY; base = isCollapsed() ? peek() : 0; moved = false; dk.classList.add('dragging'); try{ grab.setPointerCapture(e.pointerId); }catch(_){} });
  grab.addEventListener('pointermove', e => { if (y0===null) return; dy = e.clientY - y0; if (Math.abs(dy) > 4) moved = true; dk.style.transform = `translateY(${Math.min(peek(), Math.max(-20, base + dy))}px)`; });
  const up = () => { if (y0===null) return; dk.classList.remove('dragging'); y0 = null; if (!moved) setC(!isCollapsed()); else setC(base + dy > peek()/2); dy = 0; };
  grab.addEventListener('pointerup', up); grab.addEventListener('pointercancel', up);
}
function dialog({icon, tone, title, text, ok='تمام', cancel, onOk, danger}){
  window.__dlgOk = () => { closeSheet(); onOk && onOk(); };
  return openSheet(`<div class="state" style="padding:0">${icon?`<div class="art ${tone||''}" style="width:64px;height:64px;border-radius:22px;margin:0">${I(icon,'lg')}</div>`:''}</div>
    <h3>${title}</h3><p>${text||''}</p>
    <div class="col" style="gap:8px"><button class="btn ${danger?'danger':'primary'}" onclick="__dlgOk()">${ok}</button>${cancel?`<button class="btn ghost" onclick="closeSheet()">${cancel}</button>`:''}</div>`, {dialog:true});
}

/* ---------------- toasts ---------------- */
function dismissToast(t){ if (!t.isConnected || t.classList.contains('out')) return; t.classList.add('out'); setTimeout(() => t.remove(), 240); }
function swipeUpToDismiss(t){
  let y0 = null, dy = 0;
  t.addEventListener('pointerdown', e => { y0 = e.clientY; t.style.transition = 'none'; });
  t.addEventListener('pointermove', e => { if (y0===null) return; dy = Math.min(0, e.clientY - y0); t.style.transform = `translateY(${dy}px)`; t.style.opacity = 1 + dy/120; });
  const up = () => { if (y0===null) return; y0 = null; t.style.transition = 'transform .25s, opacity .25s'; if (dy < -40){ t.style.transform = 'translateY(-130%)'; t.style.opacity = 0; setTimeout(() => t.remove(), 250); } else { t.style.transform = ''; t.style.opacity = ''; } dy = 0; };
  t.addEventListener('pointerup', up); t.addEventListener('pointercancel', up);
}
function toast(text, icon='check', cls=''){
  const t = document.createElement('div'); t.className = 'toast ' + cls; t.innerHTML = I(icon,'sm') + `<span>${text}</span>`;
  $('#toasts').appendChild(t); swipeUpToDismiss(t);
  setTimeout(() => dismissToast(t), 2800);
}
function pushNotif(title, body, opts={}){
  const t = document.createElement('div'); t.className = 'toast push'; t.style.flexDirection = 'column'; t.style.alignItems = 'stretch';
  t.innerHTML = `<div class="flex" style="align-items:flex-start"><div class="logo" style="width:38px;height:38px;border-radius:11px;box-shadow:none;flex:0 0 auto"><img src="${IMG.logo}" alt=""></div><div class="grow"><div class="flex between"><b class="small">تاكسيستا</b><span class="tiny muted">الآن</span></div><div class="bold small">${title}</div><div class="tiny muted" style="line-height:1.6">${body}</div></div></div>
    ${opts.actions?`<div class="acts">${opts.actions.map((a,i) => `<button data-i="${i}" class="${a.ok?'ok':''}">${a.t}</button>`).join('')}</div>`:''}`;
  t.addEventListener('click', e => { const b = e.target.closest('.acts button'); if (b){ const a = opts.actions[+b.dataset.i]; dismissToast(t); a.fn && a.fn(); return; } if (opts.go){ dismissToast(t); go(opts.go); } });
  $('#toasts').appendChild(t); swipeUpToDismiss(t);
  if (navigator.vibrate) try{ navigator.vibrate(20); }catch(_){}
  setTimeout(() => dismissToast(t), opts.actions ? 7000 : 4200);
}

/* ---------------- drawer ---------------- */
function openDrawer(){
  const layer = $('#drawer');
  layer.innerHTML = `<div class="scrim"></div><nav class="drawer">${SCREENS.drawer.render()}</nav>`;
  const scrim = layer.firstElementChild, d = layer.lastElementChild;
  scrim.onclick = closeDrawer;
  requestAnimationFrame(() => { scrim.classList.add('on'); d.classList.add('on'); }); countUps(d);
  // swipe to close (towards the right edge in RTL)
  let x0=null, dx=0;
  d.addEventListener('pointerdown', e => { x0 = e.clientX; });
  d.addEventListener('pointermove', e => { if (x0===null) return; dx = Math.max(0, e.clientX - x0); if (dx>8){ d.style.transition='none'; d.style.transform=`translateX(${dx}px)`; }});
  const up = () => { if (x0===null) return; d.style.transition=''; x0=null; if (dx>80) closeDrawer(); else d.style.transform=''; dx=0; };
  d.addEventListener('pointerup', up); d.addEventListener('pointerleave', up);
  Studio.sync('drawer');
}
function closeDrawer(instant){
  const layer = $('#drawer'); if (!layer || !layer.innerHTML) return false;
  const d = layer.querySelector('.drawer'), s = layer.querySelector('.scrim');
  if (!d) return false;
  d.classList.remove('on'); d.style.transform=''; s.classList.remove('on');
  if (instant) layer.innerHTML=''; else setTimeout(() => layer.innerHTML='', 300);
  return true;
}
function drawerGo(id, params){ closeDrawer(true); go(id, params); }

/* ---------------- global click delegation ---------------- */
document.addEventListener('click', e => {
  const t = e.target.closest('[data-go],[data-back],[data-sheet],[data-act]');
  if (!t) return;
  if (t.dataset.back !== undefined){ back(); return; }
  if (t.dataset.go){ const p = t.dataset.p ? JSON.parse(t.dataset.p) : {}; if (t.closest('.drawer')) drawerGo(t.dataset.go, p); else go(t.dataset.go, p, t.dataset.replace?{replace:true}:{}); return; }
  if (t.dataset.sheet){ const fn = SHEETS[t.dataset.sheet]; fn && fn(t.dataset.p ? JSON.parse(t.dataset.p) : {}); return; }
  if (t.dataset.act){ const fn = ACTS[t.dataset.act]; fn && fn(t, e); }
});
const SHEETS = {}; const ACTS = {};

/* edge-swipe back (RTL: from the right edge towards the left) */
(function(){
  // iOS-style interactive back: drag from the right edge (RTL); the page under follows
  let x0=null, el=null, under=null, W=390;
  document.addEventListener('pointerdown', e => {
    const scr = $('#screen'); if (!scr) return; const r = scr.getBoundingClientRect(); W = r.width;
    if (e.clientX > r.right - 26 && e.clientX <= r.right && P.stack.length > 1 && !sheetOpen && !$('#drawer').innerHTML){ x0 = e.clientX; el = pagesEl().lastElementChild; under = el && el.previousElementSibling; if (el){ el.style.transition='none'; el.style.animation='none'; } if (under){ under.style.transition='none'; } }
  });
  document.addEventListener('pointermove', e => { if (x0===null||!el) return; const dx = Math.max(0, x0 - e.clientX); el.style.transform = `translateX(${-dx}px)`; if (under) under.style.transform = `translateX(${18*(1-dx/W)}%)`; });
  const up = e => { if (x0===null||!el) return; const dx = x0 - e.clientX; x0=null;
    if (dx > W*.28){ el.style.setProperty('--from', `translateX(${-dx}px)`); el.style.animation=''; el.style.transition=''; el.style.transform=''; if (under){ under.style.transition=''; } back(); }
    else { el.style.transition='transform .25s var(--ease-out)'; el.style.transform=''; el.style.animation=''; if (under){ under.style.transition='transform .25s var(--ease-out)'; under.style.transform=''; } setTimeout(() => { if (el){ el.style.transition=''; } if (under) under.style.transition=''; }, 260); }
    el=null; under=null; };
  document.addEventListener('pointerup', up); document.addEventListener('pointercancel', up);
})();

/* press feedback: a small scale-down plus a ripple from the touch point */
(function(){
  const SEL = '.btn,.li,.chip,.qd,.veh,.opt,.act .ib,.where,.nodest,.promo-card,.booking-card,.icon-btn,.card.press,.mini,.profile-card,.qa .ib,.stepper button,.action-card .f button,.call-screen .cbtn,.tabs button,.reward-hero,.bal3 .b';
  let cur = null;
  document.addEventListener('pointerdown', e => {
    const t = e.target.closest(SEL); if (!t || !t.closest('.app')) return;
    cur = t; t.classList.add('pressing');
    if (reduced()) return;
    const r = t.getBoundingClientRect(); const d = Math.max(r.width, r.height) * 2.2;
    const s = document.createElement('span'); s.className = 'rip'; s.style.width = s.style.height = d+'px';
    s.style.left = (e.clientX - r.left - d/2)+'px'; s.style.top = (e.clientY - r.top - d/2)+'px';
    if (getComputedStyle(t).position === 'static') t.style.position = 'relative';
    t.style.overflow = t.style.overflow || 'hidden';
    t.appendChild(s); setTimeout(() => s.remove(), 560);
  }, {passive:true});
  const end = () => { if (cur){ cur.classList.remove('pressing'); cur = null; } };
  document.addEventListener('pointerup', end); document.addEventListener('pointercancel', end); document.addEventListener('pointerleave', end);
})();

/* ---------------- studio panel ---------------- */
const GROUPS = [
  ['start','البداية والدخول'],['home','الرئيسية والبحث'],['book','طلب الرحلة'],['trip','أثناء الرحلة وبعدها'],
  ['future','الرحلات القادمة والمتكررة'],['rewards','المكافآت والولاء'],['wallet','المحفظة والدفع'],
  ['account','الحساب والقائمة'],['support','الدعم والأمان'],['review','المراجعة والنظام']
];
const SIM_LABELS = {default:'افتراضي',loading:'تحميل',empty:'فارغ',error:'خطأ',offline:'بدون إنترنت',denied:'رفض الإذن',weak:'إنترنت ضعيف',nodriver:'لا يوجد سائق',arrived:'السائق وصل',paused:'موقوف',awaiting:'بانتظار تأكيدك',pending:'في الطريق',credited:'تم الاعتماد',budget:'الميزانية انتهت',ended:'انتهت الحملة',earned:'حصلت عليها',disabled:'غير متاح',failed:'فشل',success:'نجاح',noresults:'لا نتائج',results:'نتائج',recovery:'عرض استرجاع رحلة',ongoing:'رحلة جارية'};
const Studio = {
  init(){
    const nav = $('#nav');
    nav.innerHTML = GROUPS.map(([g,t]) => {
      const items = Object.entries(SCREENS).filter(([,d]) => d.group===g && !d.hidden);
      return `<details class="nav-group" ${['home','book','future','rewards'].includes(g)?'open':''}><summary>${t}<span class="tiny" style="color:#8A95A8">${items.length}</span></summary><div class="items">${items.map(([id,d]) => `<button data-nav="${id}">${d.title}</button>`).join('')}</div></details>`;
    }).join('');
    nav.addEventListener('click', e => { const b = e.target.closest('[data-nav]'); if (!b) return; P.sim='default'; const id=b.dataset.nav; if (id==='drawer'){ go('home',{},{root:true,fade:true}); setTimeout(openDrawer,60);} else go(id, {}, {root: id==='home', fade:true}); if (innerWidth<=820) Studio.toggle(false); });
    $$('[data-set]').forEach(b => b.addEventListener('click', () => { Studio.set(b.dataset.set, b.dataset.v); }));
    $('#states').addEventListener('click', e => { const b = e.target.closest('[data-sim]'); if (!b) return; P.sim = b.dataset.sim; refresh(); });
    $('#noteSave').onclick = Notes.save; $('#noteCopy').onclick = Notes.copy; $('#noteClear').onclick = Notes.clear;
    $('#baToggle').addEventListener('click', e => { const b = e.target.closest('[data-view]'); if (!b) return; P.view = b.dataset.view; refresh(); const d = $('#drawer .drawer'); if (d){ d.innerHTML = SCREENS.drawer.render(); countUps(d); } });
    $('#fab').onclick = () => Studio.toggle(true); $('#scrimP').onclick = () => Studio.toggle(false);
    Notes.list();
    const total = Object.values(SCREENS).filter(d => !d.hidden).length; $('#count').textContent = total;
  },
  toggle(on){ $('#panel').classList.toggle('open', on); $('#scrimP').classList.toggle('on', on); },
  set(k, v){
    if (k==='theme'){ P.theme=v; if (v==='auto') delete document.documentElement.dataset.theme; else document.documentElement.dataset.theme=v; }
    if (k==='reduced'){ document.documentElement.dataset.reduced = v; }
    $$(`[data-set="${k}"]`).forEach(b => b.classList.toggle('on', b.dataset.v===v));
    try { localStorage.setItem('tx-'+k, v); } catch(e){}
    refresh();
  },
  sync(over){
    const id = over || P.screen;
    $$('#nav [data-nav]').forEach(b => b.classList.toggle('cur', b.dataset.nav===id));
    const def = SCREENS[id] || {};
    $('#curName').textContent = def.title || id;
    const st = ['default', ...(def.states||[])];
    $('#curName2') && ($('#curName2').textContent = def.title || id);
    $('#states').innerHTML = st.map(s => `<button data-sim="${s}" class="${P.sim===s?'on':''}">${SIM_LABELS[s]||s}</button>`).join('');
    $('#statesWrap').style.display = st.length > 1 ? '' : 'none';
  }
};
const Notes = {
  key:'taxista-ux-notes',
  all(){ try { return JSON.parse(localStorage.getItem(this.key)||'[]'); } catch(e){ return []; } },
  put(a){ try { localStorage.setItem(this.key, JSON.stringify(a)); } catch(e){} },
  save(){ const t = $('#noteText').value.trim(); if (!t) return; const a = Notes.all(); a.push({screen:P.screen, title:(SCREENS[P.screen]||{}).title||P.screen, view:P.view==='before'?'الحالي':'المطوّر', theme:P.theme, text:t, at:new Date().toLocaleString('ar-LY')}); Notes.put(a); $('#noteText').value=''; Notes.list(); toast('حُفظت الملاحظة'); },
  list(){ const a = Notes.all(); $('#notes').innerHTML = a.length ? a.slice().reverse().map(n => `<div><b>${esc(n.title)}</b> · ${esc(n.view||'')}<br>${esc(n.text)}</div>`).join('') : '<div style="opacity:.7">لا توجد ملاحظات بعد. اكتب مثل: «هذا الزر مش عاجبني».</div>'; },
  text(){ return Notes.all().map((n,i) => `${i+1}. [${n.title} | شاشة ${n.screen} | ${n.view||''} | ${n.theme}] ${n.text}`).join('\n'); },
  copy(){ const t = Notes.text(); if (!t) return; const fallback = () => { const ta = $('#noteText'); ta.value = t; ta.focus(); ta.select(); toast('حدّدنا الملاحظات في الصندوق — انسخها يدويًا', 'copy'); };
    try { navigator.clipboard.writeText(t).then(() => toast('نُسخت الملاحظات — الصقها في المحادثة', 'copy'), fallback); } catch(e){ fallback(); } },
  clear(){ const b = $('#noteClear'); if (b.dataset.arm !== '1'){ b.dataset.arm = '1'; b.textContent = 'اضغط مرة ثانية للمسح'; setTimeout(() => { b.dataset.arm = ''; b.textContent = 'مسح'; }, 2500); return; } b.dataset.arm=''; b.textContent='مسح'; Notes.put([]); Notes.list(); }
};

/* ---------------- shared UI bits ---------------- */
function appbar(title, opts={}){
  return `<header class="appbar ${opts.hero?'hero':''}">
    ${opts.noBack?'':`<button class="icon-btn" data-back aria-label="رجوع">${I('back')}</button>`}
    <div class="grow"><h2>${title}</h2>${opts.sub?`<div class="sub">${opts.sub}</div>`:''}</div>
    ${opts.right||''}</header>`;
}
function offlineBar(){ return P.sim==='offline' ? `<div class="offline-bar">${I('wifiOff','sm')} لا يوجد اتصال بالإنترنت — نعرض آخر بيانات محفوظة</div>` : ''; }
function skeletonList(n=4){ return `<div class="sec">${Array.from({length:n}).map(() => `<div class="card flex" style="margin-bottom:10px"><div class="sk" style="width:42px;height:42px;border-radius:12px"></div><div class="grow"><div class="sk" style="height:13px;width:60%"></div><div class="sk mt8" style="height:11px;width:40%"></div></div></div>`).join('')}</div>`; }
function stateBlock({icon='info', tone='', title, text, cta, ctaAct, ctaGo, ctaSheet}){
  const attr = ctaAct?`data-act="${ctaAct}"`:ctaGo?`data-go="${ctaGo}"`:ctaSheet?`data-sheet="${ctaSheet}"`:'';
  return `<div class="state"><div class="art ${tone}">${I(icon,'xl')}</div><h3>${title}</h3><p>${text||''}</p>${cta?`<button class="btn primary mt12" style="width:auto;padding:0 22px" ${attr}>${cta}</button>`:''}</div>`;
}
function simStates(opts){ // generic state handler: returns html for loading/empty/error/offline or null
  if (P.sim==='loading') return skeletonList(5);
  if (P.sim==='empty' && opts.empty) return stateBlock(opts.empty);
  if (P.sim==='error') return stateBlock({icon:'alert', tone:'red', title:'تعذّر التحميل', text:'صار خلل مؤقت من جهتنا أو في الشبكة. بياناتك ما تضررتش.', cta:'إعادة المحاولة', ctaAct:'retry'});
  return null;
}
ACTS.retry = async () => { P.sim='loading'; refresh(); await wait(900); P.sim='default'; refresh(); toast('تم التحديث'); };
function ring(pct, size=120, stroke=10, color='var(--brand)', inner=''){
  const r = (size - stroke)/2, C = 2*Math.PI*r, off = C*(1-Math.max(0,Math.min(1,pct)));
  return `<div class="ring" style="width:${size}px;height:${size}px"><svg width="${size}" height="${size}"><defs><linearGradient id="rg${size}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0873FF"/><stop offset="1" stop-color="#17C3E8"/></linearGradient><linearGradient id="gg${size}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E0A526"/><stop offset="1" stop-color="#F7D774"/></linearGradient></defs>
    <circle class="track" cx="${size/2}" cy="${size/2}" r="${r}" stroke-width="${stroke}"/>
    <circle class="bar" cx="${size/2}" cy="${size/2}" r="${r}" stroke-width="${stroke}" stroke="${color==='grad'?`url(#rg${size})`:color==='gold'?`url(#gg${size})`:color}" stroke-dasharray="${C}" stroke-dashoffset="${C}" data-off="${off}"/></svg><div class="lbl">${inner}</div></div>`;
}
function animateRings(el){ requestAnimationFrame(() => requestAnimationFrame(() => $$('.ring .bar', el).forEach(b => b.style.strokeDashoffset = b.dataset.off))); }
function vehicleArt(color){ // side-view car illustration
  return `<svg class="car" viewBox="0 0 62 40"><ellipse cx="31" cy="36" rx="26" ry="3" fill="rgba(0,0,0,.12)"/><path d="M6 26c0-4 2-6 6-7l8-7c2-2 4-3 7-3h10c3 0 5 1 7 3l6 7c4 1 6 3 6 7v4H6z" fill="${color}"/><path d="M22 13h8v7H15zM33 13h6c2 0 3 1 4 2l4 5H33z" fill="#D7E9FF" opacity=".95"/><circle cx="17" cy="31" r="5" fill="#1F2A3B"/><circle cx="17" cy="31" r="2" fill="#B8C2D1"/><circle cx="46" cy="31" r="5" fill="#1F2A3B"/><circle cx="46" cy="31" r="2" fill="#B8C2D1"/></svg>`;
}
function countUps(root){
  $$('[data-count]', root).forEach(el => {
    const to = parseFloat(el.dataset.count), dec = +(el.dataset.dec || 0), from = parseFloat(el.dataset.from || 0);
    if (reduced() || isNaN(to)){ el.textContent = to.toFixed(dec); return; }
    const t0 = performance.now(), ms = +(el.dataset.ms || 800);
    const step = now => { const k = Math.min(1, (now - t0)/ms), e = 1 - Math.pow(1-k, 3); el.textContent = (from + (to-from)*e).toFixed(dec); if (k < 1) requestAnimationFrame(step); };
    el.textContent = from.toFixed(dec); requestAnimationFrame(step);
  });
}
const cnt = (v, dec=2, from=0) => `<span class="num" data-count="${v}" data-dec="${dec}" data-from="${from}">${Number(v).toFixed(dec)}</span>`;
function checkAnim(size=96){ return `<svg class="check-anim" viewBox="0 0 100 100" style="width:${size}px;height:${size}px"><circle cx="50" cy="50" r="45"/><path d="M30 52 l14 14 l27 -30"/></svg>`; }
function confetti(host){
  if (reduced()) return;
  const c = document.createElement('div'); c.className='confetti';
  const colors = ['#0873FF','#3D8BFF','#F6D365','#D69E2E','#14A47B','#FFFFFF'];
  for (let i=0;i<44;i++){ const s = document.createElement('i'); s.style.left = Math.random()*100+'%'; s.style.background = colors[i%colors.length]; s.style.animationDelay = (Math.random()*300)+'ms'; s.style.transform = `rotate(${Math.random()*180}deg)`; c.appendChild(s); }
  host.appendChild(c); setTimeout(() => c.remove(), 1900);
}
