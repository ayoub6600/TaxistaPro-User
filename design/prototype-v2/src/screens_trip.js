/* Screens: driver found, on trip, cancel, SOS, chat, call, invoice, rating. SAMPLE DATA. */
'use strict';
const DR = () => DRIVERS[P.driver||'a'];

function driverCard(d){
  return `<div class="driver"><div style="position:relative"><span class="avatar lg"><img src="${IMG.driverAvatar}" alt=""></span><span class="tag" style="position:absolute;bottom:-6px;right:50%;transform:translateX(50%);background:var(--surface);box-shadow:var(--sh-1)">${I('star','xs')}<span class="num">${d.rating}</span></span></div>
    <div class="grow"><div class="bold" style="font-size:17px">${d.full} ${P.driver==='a'?`<span class="tag green">${I('heart','xs')} من سواقيني</span>`:''}</div><div class="small muted">${d.car} · ${d.color} · <span class="num">${d.rides}</span> رحلة</div>
      <div class="plate mt8"><span class="tiny muted">ليبيا</span><span class="num">${d.plate}</span></div></div></div>`;
}
function tripActions(){
  return `<div class="actions4">
    <button class="act" data-go="call" data-p='{"who":"driver"}'><span class="ib">${I('phone')}</span>اتصال مجاني</button>
    <button class="act" data-go="tripChat"><span class="ib" style="position:relative">${I('msg')}</span>رسالة</button>
    <button class="act" data-act="shareTrip"><span class="ib">${I('share')}</span>شارك الرحلة</button>
    <button class="act sos" data-sheet="tripSos"><span class="ib">${I('shield')}</span>طوارئ</button></div>`;
}
function tripDetails(open){
  return `<details class="card mt12" style="box-shadow:none;background:var(--surface-2);border:0" ${open?'open':''}><summary class="flex between bold small" style="list-style:none;cursor:pointer">تفاصيل الرحلة <span class="flex tiny muted">${({cash:'نقدًا',wallet:'المحفظة',mix:'محفظة + نقدًا'})[B().pay]} · <span class="num bold" style="color:var(--ink)">${(B().mode==='offer'?B().offer:finalFare()).toFixed(2)}</span> د.ل ${I('chevD','xs')}</span></summary>
    <div class="timeline mt12"><div class="tl done"><div class="t">${pickName()}</div><div class="s">نقطة اللقاء</div></div><div class="tl"><div class="t">${dropName()}</div><div class="s">الوجهة</div></div></div>
    <div class="flex between small"><span class="muted">رقم الطلب</span><span class="num">R-2042</span></div></details>`;
}
ACTS.shareTrip = () => toast('نسخنا رابط تتبّع الرحلة — أرسله لمن تحب', 'share');

screen('found', { title:'السائق في الطريق', group:'trip', states:['arrived'],
  render:() => { const d = DR(); const arrived = P.sim==='arrived';
    return `${mapHTML({center:[285,585], oy:200, approach:!arrived, car:true, pins:[['me','pick']]})}
      <div class="map-top"><span></span><div class="status-pill" id="fPill"><span class="live"></span><span class="small">${arrived?`${d.name} وصل — اطلعله`:`${d.name} في الطريق · <span class="num" id="eta">4</span> د`}</span></div><span style="width:42px"></span></div>
      <div class="dock" style="max-height:68%"><div class="grab"></div><div class="scroll">
        ${arrived?`<div class="banner success" style="margin-bottom:12px">${I('check','sm')}<div class="grow"><b>السائق وصل لنقطة اللقاء.</b> عندك <span class="num">3:00</span> دقائق انتظار مجانًا، بعدها يُحسب وقت الانتظار.</div></div>`:
          `<div class="flex between" style="margin-bottom:10px"><div><div class="xbold" style="font-size:19px;color:var(--navy)">يوصلك خلال <span class="num" id="eta2">4</span> دقائق</div><div class="small muted">سيصل السائق خلال دقائق كن جاهز للركوب معه</div></div><div class="tag brand"><span class="num">1.3</span> كم</div></div>
           <div class="bar-h" style="margin-bottom:14px"><i id="apBar" style="width:8%"></i></div>`}
        ${driverCard(d)}
        ${tripActions()}
        ${tripDetails(false)}
        <div class="demo-ctl"><div class="tiny">محاكاة العرض</div><div class="flex"><button class="chip" data-act="simArrive">السائق وصل</button><button class="chip" data-act="startTrip">بدء الرحلة</button></div></div>
        <button class="btn ghost mt8" data-sheet="cancel">إلغاء الرحلة</button></div></div>`; },
  mount:(el) => {
    if (P.sim==='arrived'){ const c = $('#mycar', el); c && c.setAttribute('transform','translate(205 555) rotate(-110)'); return; }
    animateCar(el, 'ap', 9000, false, () => { if (P.screen==='found'){ P.sim='arrived'; refresh(); pushNotif('السائق وصل', `${DR().name} في نقطة اللقاء — ${DR().car}`); } });
    let k = 0; const step = () => { k++; const b = $('#apBar', el); if (!b) return; b.style.width = Math.min(100, 8 + k*11) + '%'; const e = $('#eta', el), e2 = $('#eta2', el); const v = Math.max(1, 4 - Math.floor(k/2)); if (e) e.textContent = v; if (e2) e2.textContent = v; if (k < 8) later(step, 1100); }; later(step, 900);
  }
});
ACTS.simArrive = () => { P.sim='arrived'; refresh(); };
ACTS.startTrip = () => { P.sim='default'; go('ontrip', {}, {replace:true}); later(() => toast('بدأت الرحلة — رحلة سعيدة', 'route'), 300); };

screen('ontrip', { title:'أثناء الرحلة', group:'trip',
  render:() => { const d = DR(); const to = B().noDest ? 'square' : placeById(B().drop||'square').pt;
    return `${mapHTML({center:[228,480], oy:180, zoom:.95, route:['me', to], car:true, pins:[[to,'drop']]})}
      <div class="map-top"><span></span><div class="status-pill"><span class="live"></span><span class="small">في الطريق ${B().noDest?'':'إلى '+dropName()} · <span class="num" id="eta">12</span> د</span></div><button class="icon-btn" data-sheet="tripSos" style="color:var(--danger)" aria-label="طوارئ">${I('shield')}</button></div>
      <div class="dock" style="max-height:62%"><div class="grab"></div><div class="scroll">
        <div class="flex between"><div><div class="tiny muted">الوصول المتوقع</div><div class="bold" style="font-size:22px"><span class="num">08:31</span></div></div>
          <div class="center"><div class="tiny muted">المتبقي</div><div class="bold"><span class="num">3.1</span> كم</div></div>
          <div style="text-align:end"><div class="tiny muted">الأجرة</div><div class="bold">${B().noDest?'بالعداد':`<span class="num">${(B().mode==='offer'?B().offer:finalFare()).toFixed(2)}</span> د.ل`}</div></div></div>
        <div class="bar-h mt12"><i id="trBar" style="width:5%"></i></div>
        <div class="flex mt12" style="padding:10px;border-radius:var(--r-sm);background:var(--surface-2)"><span class="avatar" style="width:36px;height:36px"><img src="${IMG.driverAvatar}" alt=""></span><span class="grow small"><b>${d.full}</b> · ${d.car} · <span class="num">${d.plate}</span></span><button class="icon-btn" style="width:36px;height:36px" data-go="tripChat">${I('msg','sm')}</button></div>
        <div class="opts">
          <button class="opt" data-sheet="changeDest">${I('edit','sm')}<span class="grow"><span class="k">الوجهة</span>تعديل الوجهة</span></button>
          <button class="opt" data-act="shareTrip">${I('share','sm')}<span class="grow"><span class="k">الأمان</span>شارك الرحلة</span></button>
        </div>
        <div class="demo-ctl"><div class="tiny">محاكاة العرض</div><div class="flex"><button class="chip" data-act="endTrip">إنهاء الرحلة</button></div></div>
      </div></div>`; },
  mount:(el) => { animateCar(el, 'rt', 12000, false, () => { if (P.screen==='ontrip') ACTS.endTrip(); });
    let k=0; const step = () => { k++; const b = $('#trBar', el); if (!b) return; b.style.width = Math.min(100, 5+k*9)+'%'; const e = $('#eta', el); if (e) e.textContent = Math.max(1, 12-k); if (k<11) later(step, 1100); }; later(step, 1000); }
});
ACTS.endTrip = () => { go('invoice', {}, {replace:true}); later(() => pushNotif('وصلت بالسلامة', 'راجع الفاتورة وقيّم رحلتك'), 400); };
SHEETS.changeDest = () => openSheet(`<h3>تعديل الوجهة</h3><p class="sheet-sub">اختار الوجهة الجديدة. نحسبلك السعر الجديد ونرسله للسائق للموافقة.</p>
  <div class="input">${I('search','sm')}<input placeholder="ابحث عن الوجهة الجديدة"></div>
  <div class="list mt12">${['hospital','corniche','oldmarket'].map(id => { const pl = placeById(id); return `<button class="li" data-act="destChanged" data-id="${id}"><span class="ic">${I('pin','sm')}</span><span class="tx"><span class="t" style="display:block">${pl.name}</span><span class="s" style="display:block">السعر الجديد التقديري ${(9+pl.name.length%6).toFixed(2)} د.ل</span></span></button>`; }).join('')}</div>
  <div class="banner warn mt12">${I('info','sm')}<span><b>ميزة مقترحة:</b> لم نجدها في كود التطبيق الحالي أثناء الرحلة. تحتاج دعم من الخادم قبل التنفيذ (مذكورة في قرارات المالك).</span></div>`);
ACTS.destChanged = (t) => { B().drop = t.dataset.id; closeSheet(); toast('أرسلنا الوجهة الجديدة للسائق — بانتظار موافقته', 'send'); };

SHEETS.cancel = () => { const arrived = P.sim==='arrived';
  openSheet(`<h3>ليش تبي تلغي؟</h3><p class="sheet-sub">اختيارك يساعدنا نحسّن الخدمة.</p>
    <div class="list">${CANCEL_REASONS.map((r,i) => `<button class="li" data-act="reason" data-i="${i}"><span class="radio ${i===0?'on':''}"></span><span class="tx"><span class="t">${r}</span></span></button>`).join('')}</div>
    <div class="input mt8" id="otherR" style="display:none">${I('edit','sm')}<input placeholder="اكتب السبب"></div>
    ${arrived?`<div class="banner warn mt12">${I('alert','sm')}<span>السائق وصل لنقطة اللقاء، لذلك تُطبّق <b>رسوم إلغاء 2.50 د.ل</b> حسب سياسة الإلغاء.</span></div>`:`<div class="banner info mt12">${I('info','sm')}<span>ما فيش رسوم إلغاء الآن. لو وصل السائق لنقطة اللقاء ممكن تُطبّق رسوم.</span></div>`}
    <div class="col mt12" style="gap:8px"><button class="btn danger" data-act="doCancel">تأكيد الإلغاء</button><button class="btn primary" onclick="closeSheet()">لا، كمّل الرحلة</button></div>`); };
ACTS.reason = (t) => { $$('.sheet .li .radio').forEach(r => r.classList.remove('on')); t.querySelector('.radio').classList.add('on'); $('#otherR').style.display = (+t.dataset.i === CANCEL_REASONS.length-1) ? 'flex' : 'none'; };
ACTS.doCancel = async (t) => { t.innerHTML = '<span class="spinner" style="border-top-color:var(--danger)"></span>'; await wait(600); P.sim='default'; go('home', {}, {root:true, fade:true}); later(() => toast('ألغينا الرحلة. نتمنى نخدمك المرة الجاية.'), 300); };

SHEETS.tripSos = () => openSheet(`<div class="flex"><span class="ic" style="width:48px;height:48px;border-radius:16px;background:var(--danger-bg);color:var(--danger);display:flex;align-items:center;justify-content:center">${I('shield','lg')}</span><div><h3>الطوارئ</h3><div class="small muted">اضغط مطوّلًا للتأكيد حتى ما يصير ضغط بالغلط</div></div></div>
  <button class="btn mt16" style="background:var(--danger);color:#fff;height:60px;font-size:17px" data-act="holdSos">${I('phone','sm')} اتصل بالطوارئ</button>
  <div class="list mt12">
    <button class="li" data-act="notifyAdmin"><span class="ic red">${I('headset','sm')}</span><span class="tx"><span class="t" style="display:block">خبّر إدارة تاكسيستا</span><span class="s" style="display:block">نوصلهم موقعك وتفاصيل الرحلة فورًا</span></span></button>
    <button class="li" data-act="shareTrip"><span class="ic">${I('share','sm')}</span><span class="tx"><span class="t" style="display:block">شارك موقعك المباشر</span><span class="s" style="display:block">مع جهات الثقة: ${TRUSTED.map(t=>t.n).join('، ')}</span></span></button>
    <button class="li" data-go="sos"><span class="ic">${I('users','sm')}</span><span class="tx"><span class="t" style="display:block">جهات الثقة</span><span class="s" style="display:block">أضف حتى 4 أشخاص</span></span>${I('chevL','sm')}</button></div>`);
ACTS.holdSos = () => toast('في التطبيق: يُضغط مطوّلًا ثانيتين ثم يفتح الاتصال', 'shield');
ACTS.notifyAdmin = () => { closeSheet(); toast('وصلت رسالتك للإدارة، بنتواصلوا معاك الآن', 'shield'); };

screen('tripChat', { title:'محادثة السائق', group:'trip', states:['error'],
  render:() => { const d = DR(); return `${appbar(d.full, {sub:'سائق رحلتك · '+d.car, right:`<button class="icon-btn" data-go="call" data-p='{"who":"driver"}' aria-label="اتصال">${I('phone')}</button>`})}
    <div class="banner info" style="margin:0 12px">${I('lock','sm')}<span class="small">الاتصال المجاني والرسائل متاحة أثناء الرحلة ولين 24 ساعة بعدها. رقمك ما يظهرش للسائق.</span></div>
    <div class="chat"><div class="day-sep">اليوم</div>
      <div class="msg them">السلام عليكم، أنا جاي في الطريق<div class="meta">08:01</div></div>
      <div class="msg me">وعليكم السلام، قدام جامع الزروق<div class="meta">08:02 · ✓✓</div></div>
      <div class="msg them"><div class="voice">${I('play','sm')}<span class="wave">${Array.from({length:22}).map((_,i)=>`<i style="height:${6+((i*7)%14)}px"></i>`).join('')}</span><span class="tiny num">0:07</span></div><div class="meta">08:03</div></div>
      ${P.sim==='error'?`<div class="msg me" style="opacity:.7">وصلت؟<div class="meta" style="color:#FFD2CC">لم تُرسل · اضغط لإعادة المحاولة</div></div>`:''}
    </div>
    <div class="chips" style="padding:6px 12px">${['أنا طالع','وين أنت؟','قدام الباب','نتأخر دقيقتين'].map(q=>`<button class="chip" data-act="quick">${q}</button>`).join('')}</div>
    <div class="composer"><button class="icon-btn" style="box-shadow:none" aria-label="رسالة صوتية">${I('mic')}</button><div class="input"><input placeholder="اكتب رسالة للسائق…"></div><button class="icon-btn" style="background:var(--brand);color:#fff" data-act="sendChat" aria-label="إرسال">${I('send')}</button></div>`; }
});
ACTS.quick = (t) => { const c = $('.page:last-child .chat'); c.insertAdjacentHTML('beforeend', `<div class="msg me" style="animation:offerIn .25s var(--ease-spring)">${t.textContent}<div class="meta">الآن · ✓</div></div>`); c.scrollTop = c.scrollHeight; };
ACTS.sendChat = () => { const inp = $('.page:last-child .composer input'); if (!inp || !inp.value.trim()) return; ACTS.quick({textContent: inp.value}); inp.value=''; };

screen('call', { title:'مكالمة مجانية (داخل التطبيق)', group:'trip', statusLight:true,
  render:(p) => { const sup = p.who==='support'; const d = DR(); return `<div class="call-screen">
    <div class="tag" style="background:rgba(255,255,255,.12);color:#fff">${I('lock','xs')} مكالمة تاكسيستا · مشفّرة · مجانية</div>
    <div style="position:relative;margin-top:40px;display:flex;align-items:center;justify-content:center"><span class="ring-wave"></span><span class="ring-wave" style="animation-delay:1s"></span><span class="avatar lg" style="width:96px;height:96px;background:#fff">${sup?`<img src="${IMG.support}" alt="">`:`<img src="${IMG.driverAvatar}" alt="">`}</span></div>
    <h2 style="margin:16px 0 4px">${sup?'دعم تاكسيستا':d.full}</h2><div style="opacity:.75" id="cst">جارٍ الاتصال…</div>
    <div style="flex:1"></div>
    <div class="flex" style="gap:22px"><button class="cbtn" data-act="tgl" aria-label="كتم">${I('mic')}</button><button class="cbtn" data-act="tgl" aria-label="مكبر الصوت">${I('volume')}</button>${sup?'':`<button class="cbtn" data-go="tripChat" aria-label="الدردشة">${I('msg')}</button>`}</div>
    <button class="cbtn end mt24" data-back aria-label="إنهاء">${I('phone')}</button><div class="tiny mt8" style="opacity:.7">إنهاء</div></div>`; },
  mount:(el) => later(() => { const c = $('#cst', el); if (c) c.innerHTML = '<span class="num">00:04</span> · الجودة ممتازة'; }, 1500)
});
ACTS.tgl = (t) => { t.style.background = t.style.background ? '' : 'rgba(255,255,255,.4)'; };

screen('invoice', { title:'الفاتورة والدفع', group:'trip', states:['success'],
  render:() => { const fare = B().noDest ? 14.6 : (B().mode==='offer'?B().offer:fareOf(B().veh)); const disc = couponValue(); const pay = B().pay; const net = Math.max(0, fare-disc);
    const walletPart = pay==='cash'?0:pay==='wallet'?net:Math.min(net, 10);
    return `${appbar('وصلت بالسلامة', {noBack:true, hero:true, sub:'الثلاثاء · R-2042'})}
    <div class="scroll"><div class="sec">
      <div class="card center" style="padding:20px">
        <div class="small muted">${pay==='cash'?'ادفع للسائق نقدًا':pay==='wallet'?'دُفع من محفظتك':'من المحفظة والباقي نقدًا'}</div>
        <div style="display:flex;justify-content:center;margin-top:-4px">${checkAnim(64)}</div><div style="font-size:42px;font-weight:800" class="mt8">${cnt(net-walletPart,2)} <span style="font-size:18px">دينار</span></div>
        ${walletPart?`<div class="tag green mt8">${I('wallet','xs')} خصمنا ${walletPart.toFixed(2)} د.ل من محفظتك</div>`:''}
        ${disc?`<div class="tag gold mt8">${I('tag','xs')} وفّرت ${disc.toFixed(2)} د.ل بالكوبون</div>`:''}
      </div>
      <div class="card"><div class="flex"><span class="avatar"><img src="${IMG.driverAvatar}" alt=""></span><div class="grow"><div class="bold">${DR().full}</div><div class="tiny muted">${DR().car} · <span class="num">${DR().plate}</span></div></div></div>
        <div class="timeline mt12"><div class="tl done"><div class="t">${pickName()}</div><div class="s"><span class="num">08:19</span></div></div><div class="tl done"><div class="t">${dropName()}</div><div class="s"><span class="num">08:31</span> · <span class="num">4.2</span> كم · <span class="num">12</span> د</div></div></div></div>
      <details class="card" open><summary class="bold small" style="list-style:none;cursor:pointer">تفاصيل الأجرة</summary>
        <div class="col mt8 small" style="gap:6px">
        <div class="flex between"><span class="muted">${B().mode==='offer'?'السعر المتفق عليه':'الأجرة الأساسية'}</span><span class="num">${fare.toFixed(2)}</span></div>
        <div class="flex between"><span class="muted">رسوم الخدمة</span><span class="num">0.00</span></div>
        ${disc?`<div class="flex between"><span class="muted">خصم الكوبون</span><span class="num" style="color:var(--success)">-${disc.toFixed(2)}</span></div>`:''}
        <div class="hr" style="margin:4px 0"></div><div class="flex between bold"><span>الإجمالي</span><span class="num">${net.toFixed(2)} د.ل</span></div></div></details>
      <div class="flex mt12 small"><button class="link small" data-go="complaint">${I('file','xs')} مشكلة في الرحلة؟</button><span class="grow"></span><button class="link small" data-go="supportChat">تواصل مع الدعم</button></div>
    </div></div>
    <div class="sticky-cta"><button class="btn primary" data-go="rate" data-replace="1">${pay==='cash'?'دفعت للسائق — التالي':'التالي — قيّم رحلتك'}</button></div>`; }
});

screen('rate', { title:'تقييم الرحلة + سواقيني', group:'trip',
  render:(p) => { const s = p.s||0; const d = DR(); const lbl = ['','سيئة','مقبولة','جيدة','رائعة','ممتازة'][s];
    return `${appbar('', {noBack:true, right:`<button class="link" data-act="rateSkip">تخطي</button>`})}
    <div class="scroll" style="padding:0 20px 20px;text-align:center">
      <span class="avatar lg" style="margin:0 auto;width:84px;height:84px"><img src="${IMG.driverAvatar}" alt=""></span>
      <h2 style="margin:12px 0 4px">كيف كان ${d.name}؟</h2><div class="muted small">رحلة الزروق ← ${dropName()}</div>
      <div class="stars mt16">${[1,2,3,4,5].map(k=>`<button data-act="star" data-v="${k}" class="${k<=s?'on':''}" aria-label="${k} نجوم">${I('star','lg')}</button>`).join('')}</div>
      <div class="bold mt8" style="height:22px;color:var(--brand)">${lbl}</div>
      ${s?`<div class="sec-title" style="margin:16px 0 8px;justify-content:center">${s>=4?'وش عجبك؟':'وش اللي ما عجبكش؟'} (اختياري)</div>
        <div class="flex" style="flex-wrap:wrap;justify-content:center;gap:8px">${(s>=4?['سواقة آمنة','نظيفة','في الموعد','محترم','يعرف الطريق']:['تأخّر','سواقة سريعة','السيارة مش نظيفة','طريق أطول','سلوك']).map(b=>`<button class="chip" data-act="chipT">${b}</button>`).join('')}</div>
        <div class="input mt16" style="height:auto;padding:10px 14px"><textarea rows="2" style="border:0;outline:0;background:transparent;width:100%;resize:none;font-size:15px" placeholder="${s>=4?'كلمة لطيفة تظهر في صفحته بعد المراجعة (اختياري)':'ملاحظتك تصل لفريق تاكسيستا فقط'}"></textarea></div>
        ${s>=4?`<button class="card flex mt12 press" style="width:100%;text-align:start" data-act="favToggle"><span class="ic" style="width:40px;height:40px;border-radius:12px;background:var(--danger-bg);color:var(--danger);display:flex;align-items:center;justify-content:center">${I('heart','sm')}</span><span class="grow"><span class="bold small" style="display:block">أضف ${d.name} إلى «سواقيني»</span><span class="tiny muted" style="display:block">لما يكون قريب ومتاح نخبرك وتقدر تطلبه أولًا.</span></span><span class="toggle ${P.favAdd?'on':''}"></span></button>
          <button class="card flex press" style="width:100%;text-align:start;background:var(--gold-bg);border:0" data-act="goldGift"><span class="ic" style="width:40px;height:40px;border-radius:12px;background:#fff;color:var(--gold);display:flex;align-items:center;justify-content:center">${I('coins','sm')}</span><span class="grow"><span class="bold small" style="display:block">أهدِ ${d.name} 20 عملة ذهبية</span><span class="tiny muted" style="display:block">قيمتها 1.00 د.ل وتدفعها تاكسيستا، لا يُخصم منك شيء.</span></span></button>`:''}`:''}
    </div>
    <div class="sticky-cta"><button class="btn primary ${s?'':'disabled'}" data-act="rateSend">إرسال</button></div>`; }
});
ACTS.star = (t) => { const v = +t.dataset.v; P.params.s = v; refresh(); $$('.stars button').forEach((b,i) => { if (i < v){ b.style.animationDelay = (i*45)+'ms'; b.classList.add('pop'); } }); if (navigator.vibrate) try{navigator.vibrate(10);}catch(e){} };
ACTS.chipT = (t) => t.classList.toggle('on');
ACTS.favToggle = (t) => { P.favAdd = !P.favAdd; t.querySelector('.toggle').classList.toggle('on', P.favAdd); toast(P.favAdd?'أضفنا عبدالسلام إلى «سواقيني»':'أزلناه من «سواقيني»', 'heart'); };
ACTS.goldGift = (t) => { t.innerHTML = `<span class="grow center bold small" style="color:var(--gold)">${I('check','sm')} وصلت هديتك الذهبية، شكرًا لك</span>`; };
ACTS.rateSkip = () => ACTS.rateSend();
ACTS.rateSend = () => { P.rewards.done = Math.min(P.rewards.target, P.rewards.done + 1); Object.assign(B(), {coupon:null, mode:'fixed', noDest:false, when:'now'}); go('home', {}, {root:true, fade:true});
  later(() => toast(`شكرًا لك! رحلتك تنحسب نحو مكافأة 100 رحلة (${P.rewards.done}/100) إذا استوفت الشروط`, 'trophy'), 350); };
