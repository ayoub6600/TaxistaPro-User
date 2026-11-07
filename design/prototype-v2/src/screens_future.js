/* Screens: upcoming (scheduled + recurring days), scheduled detail, recurring rides, rewards. SAMPLE DATA. */
'use strict';
function stChip(st, label){ const s = DAY_STATE[st] || ['',''] ; return `<span class="tag ${s[1]}">${I(s[2]||'info','xs')} ${label||s[0]}</span>`; }

/* ================= UPCOMING ================= */
screen('upcoming', { title:'الرحلات القادمة (موحّدة)', group:'future', states:['loading','empty','offline'], before:() => OLD_UPCOMING(),
  render:(p) => { const f = p.f||'all'; const items = UPCOMING.filter(u => f==='all' || u.kind===f);
    const groups = {}; items.forEach(u => (groups[u.day] = groups[u.day] || []).push(u));
    return `${appbar('الرحلات القادمة', {sub:'كل مواعيدك في مكان واحد', right:`<button class="icon-btn" data-sheet="schedule" aria-label="جدولة رحلة">${I('plus')}</button>`})}
    ${offlineBar()}
    <div class="tabs"><button class="${f==='all'?'on':''}" data-go="upcoming" data-replace="1" data-p='{"f":"all"}'>الكل <span class="num">${UPCOMING.length}</span></button><button class="${f==='sched'?'on':''}" data-go="upcoming" data-replace="1" data-p='{"f":"sched"}'>مجدولة</button><button class="${f==='rec'?'on':''}" data-go="upcoming" data-replace="1" data-p='{"f":"rec"}'>مشوار الدوام</button></div>
    <div class="scroll stagger" style="padding-bottom:20px">${simStates({empty:{icon:'cal', title:'ما عندكش رحلات قادمة', text:'جدول رحلة لوقت لاحق، أو خلّي مشوار الدوام يتحجز لك تلقائيًا كل يوم.', cta:'جدول رحلة', ctaSheet:'schedule'}}) || `
      ${f!=='rec'?`<div class="sec"><button class="banner info press" style="width:100%;text-align:start" data-go="schedDetail" data-p='{"id":"S-29"}'>${I('tag','sm')}<div class="grow"><b>لديك عرض جديد لرحلتك المجدولة</b><div class="small">سالم عرض 13.00 د.ل لرحلة الأحد 06:30</div></div>${I('chevL','sm')}</button></div>`:''}
      ${Object.entries(groups).map(([day, list]) => `<div class="sec-title">${day}</div><div class="sec" style="margin-top:0">${list.map(u => upcomingCard(u)).join('')}</div>`).join('')}
      <div class="sec"><button class="card flex press" style="width:100%;text-align:start" data-go="recurring"><span class="ic" style="width:42px;height:42px;border-radius:12px;background:var(--brand-50);color:var(--brand);display:flex;align-items:center;justify-content:center">${I('repeat','sm')}</span><span class="grow"><span class="bold small" style="display:block">رحلاتي المتكررة</span><span class="tiny muted" style="display:block">إدارة مشوار الدوام: الأيام، الوقت، الإيقاف</span></span>${I('chevL','sm')}</button></div>`}
    </div>`; }
});
const OLD_UPCOMING = () => `${appbar('الرحلات القادمة')}<div class="scroll" style="padding:12px 16px 24px">
    ${UPCOMING.filter(u => u.kind==='sched').map(u => `<div class="card" style="box-shadow:none;border:1px solid var(--line);border-radius:12px;margin-bottom:10px"><div class="flex between"><b class="num">${u.date} · ${u.time}</b><span class="tag ${u.st==='offer'?'gold':'warn'}">${u.st==='offer'?'تم حجز السائق':'جاري البحث عن سائق'}</span></div>
      <div class="small mt8">${u.from} ← ${u.to}</div><div class="flex mt12" style="gap:8px"><span class="btn outline sm" style="height:36px">إعادة الجدولة</span><span class="btn danger sm" style="height:36px">إلغاء الرحلة</span></div></div>`).join('')}
    <div class="banner warn">${I('info','sm')}<span>في التطبيق الحالي: أيام «مشوار الدوام» لا تظهر هنا، و«حجوزاتك» صفحة ثانية منفصلة.</span></div></div>`;
screen('upcomingOld', { title:'حجوزاتك (الحالية)', group:'future', hidden:true, render:() => `${appbar('حجوزاتك', {sub:'رحلاتك القادمة في مكان واحد'})}<div class="scroll" style="padding:12px 16px">
    ${UPCOMING.slice(0,2).map(u => `<div class="card" style="box-shadow:none;border:1px solid var(--line);margin-bottom:10px"><div class="flex between"><b>رحلة مجدولة</b><span class="tag brand">${u.st==='offer'?'متاحة للسائقين':'السائق أكد الموعد'}</span></div><div class="small mt8">${u.day} · ${u.time} · ${u.from} ← ${u.to}</div></div>`).join('')}
    <div class="banner info">${I('info','sm')}<span>هذه الصفحة الحالية تُفتح من بطاقة الرئيسية. في التصميم المطوّر تُدمج مع «الرحلات القادمة».</span></div></div>` });
function upcomingCard(u){
  const d = u.d ? DRIVERS[u.d] : null;
  return `<button class="card press" style="width:100%;text-align:start;display:block;animation:offerIn var(--t-slow) var(--ease-out) both" data-go="${u.kind==='rec'?'recDetail':'schedDetail'}" data-p='{"id":"${u.id}"}'>
    <div class="flex between"><div class="flex" style="gap:8px"><span class="bold num" style="font-size:20px">${u.time}</span><span class="tag ${u.kind==='rec'?'brand':''}">${I(u.kind==='rec'?'repeat':'cal','xs')} ${u.kind==='rec'?'مشوار الدوام':'مجدولة'}</span></div>${stChip(u.st, u.label)}</div>
    <div class="flex mt8 small"><span class="grow">${u.from} ← ${u.to}</span><span class="num bold">${u.price.toFixed(2)}</span><span class="tiny muted">د.ل</span></div>
    ${d?`<div class="flex mt8 tiny muted"><span class="avatar" style="width:22px;height:22px;font-size:10px">${d.ini}</span>${u.offer?`${d.name} عرض ${u.price.toFixed(2)} د.ل — بانتظار ردّك`:`${d.name} · ${d.car} — سيأتي عند الموعد`}</div>`:''}
  </button>`;
}

screen('schedDetail', { title:'تفاصيل رحلة مجدولة', group:'future', states:['loading','error'],
  render:(p) => { const u = UPCOMING.find(x => x.id===p.id) || UPCOMING[1]; const d = u.d ? DRIVERS[u.d] : null; const order = ['scheduled','dispatching','reserved','driver_ready','ready'];
    const cur = u.st==='offer' ? 1 : u.st==='dispatching' ? 1 : 2;
    return `${appbar('رحلة مجدولة', {sub:`${u.day} · ${u.time}`})}
    <div class="scroll" style="padding-bottom:20px">${simStates({}) || `
      <div class="sec"><div class="card" style="padding:0;overflow:hidden"><div style="height:150px;position:relative">${mapHTML({center:[200,420], zoom:.55, route:['me', u.to.includes('مطار')?'airport':'corniche'], pins:[['me','pick'],[u.to.includes('مطار')?'airport':'corniche','drop']]})}</div>
        <div class="pad"><div class="timeline"><div class="tl done"><div class="t">${u.from}</div><div class="s">الانطلاق <span class="num">${u.time}</span></div></div><div class="tl"><div class="t">${u.to}</div><div class="s">الوجهة</div></div></div>
        <div class="flex between small"><span class="muted">السعر المرجعي</span><span class="bold num">${u.price.toFixed(2)} د.ل</span></div></div></div></div>
      ${u.offer?`<div class="sec"><div class="card" style="border:1.5px solid var(--gold-2)"><div class="flex"><span class="avatar">${d.ini}</span><div class="grow"><div class="bold">${d.name} يعرض ${u.price.toFixed(2)} د.ل</div><div class="tiny muted">${d.car} · ${I('star','xs')} ${d.rating} · السعر العادل 12.00</div></div></div>
        <div class="row-btns mt12"><button class="btn success sm" style="height:46px" data-act="schedAccept">قبول العرض</button><button class="btn outline sm" style="height:46px" data-act="schedDecline">رفض العرض</button></div></div></div>`:''}
      <div class="sec-title">حالة الحجز</div>
      <div class="sec" style="margin-top:0"><div class="card"><div class="timeline">
        ${[['تمت الجدولة','أرسلنا الموعد'],['متاحة للسائقين','إن لم يحجزها أحد، نعيد عرضها بقوة قبل الموعد بـ30 دقيقة'],['تم حجز السائق','سائق التزم بالموعد'],['السائق أكد الموعد','قبل الانطلاق بقليل'],['تبدأ قريبًا','نخبرك لما يتحرك السائق']].map(([t,s],i) => `<div class="tl ${i<cur?'done':i===cur?'now':''}"><div class="t">${t}</div><div class="s">${s}</div></div>`).join('')}
      </div></div></div>
      <div class="sec"><div class="list">
        <button class="li" data-sheet="schedule"><span class="ic">${I('clock','sm')}</span><span class="tx"><span class="t">إعادة الجدولة</span></span>${I('chevL','sm')}</button>
        ${d&&!u.offer?`<button class="li" data-go="call" data-p='{"who":"driver"}'><span class="ic">${I('phone','sm')}</span><span class="tx"><span class="t">اتصال بالسائق</span></span>${I('chevL','sm')}</button>`:''}
        <button class="li" data-act="schedCancel"><span class="ic red">${I('x','sm')}</span><span class="tx"><span class="t" style="color:var(--danger)">إلغاء الرحلة</span></span></button></div></div>`}
    </div>`; }
});
ACTS.schedAccept = () => { toast('قبلت عرض سالم — الرحلة محجوزة', 'check'); back(); };
ACTS.schedDecline = () => { toast('رفضت العرض. رحلتك تبقى متاحة للسائقين', 'x'); back(); };
ACTS.schedCancel = () => dialog({icon:'x', tone:'red', title:'نلغي الرحلة المجدولة؟', text:'ما في رسوم على الإلغاء قبل الموعد بوقت كافٍ (حسب سياسة الحجز المسبق).', ok:'إلغاء الرحلة', cancel:'رجوع', danger:true, onOk:() => { back(); later(() => toast('ألغينا الرحلة المجدولة'), 260); }});

/* ================= RECURRING ================= */
screen('recurring', { title:'رحلاتي المتكررة', group:'future', states:['loading','empty','awaiting','paused'],
  render:() => { const st = P.sim==='paused' ? 'paused' : P.sim==='awaiting' ? 'awaiting' : P.rec.status;
    return `${appbar('رحلاتي المتكررة', {sub:'مشوار الدوام وأي مشوار يتكرر', hero:true})}
    <div class="scroll" style="padding-bottom:20px">${simStates({empty:{icon:'repeat', title:'ما عندكش رحلات متكررة', text:'لو تمشي لنفس المكان كل يوم (الشغل، الجامعة، المدرسة)، نحجزولك كل يوم مسبقًا بسعر رسمي واضح.', cta:'اطلب مشوار دوام', ctaGo:'recNew'}}) || `
      ${st==='awaiting'?`<div class="sec"><div class="card" style="border:1.5px solid var(--brand)"><div class="flex"><span class="tag brand">${I('info','xs')} بانتظار تأكيدك</span></div>
        <div class="bold mt8">مشوار الدوام · البيت ← الشغل</div><div class="small muted">السبت إلى الخميس · <span class="num">07:15</span> · <span class="num">8.00</span> د.ل للمشوار</div>
        <div class="row-btns mt12"><button class="btn success sm" style="height:48px" data-go="recConfirm">✅ راجع وأكّد</button><button class="btn outline sm" style="height:48px" data-act="recDecline">❌ لا</button></div></div></div>`:''}
      <div class="sec">${recCard(st)}</div>
      <div class="sec"><div class="card" style="box-shadow:none;background:var(--surface-2);border:0"><div class="bold small">كيف يشتغل؟</div>
        <div class="col small ink2 mt8" style="gap:6px"><div class="flex" style="align-items:flex-start">${I('cal','xs')}<span>كل يوم من أيامك يتحول لرحلة مجدولة عادية تنحجز مسبقًا.</span></div>
        <div class="flex" style="align-items:flex-start">${I('car','xs')}<span>كل يوم يجيك سائق متاح؛ ما فيش سائق ثابت.</span></div>
        <div class="flex" style="align-items:flex-start">${I('tag','xs')}<span>كل مشوار بسعر يومه الرسمي. لو زاد عن التقدير أكثر من النسبة المسموحة ما نحجزوش قبل موافقتك.</span></div>
        <div class="flex" style="align-items:flex-start">${I('check','xs')}<span>لو ما لقيناش سائق ليوم ما، ما عليك أي رسوم ونخبرك.</span></div></div></div></div>
      <div class="sec"><button class="btn secondary" data-go="recNew">${I('plus','sm')} اطلب مشوار متكرر جديد</button></div>`}
    </div>`; }
});
function recCard(st){
  const lab = {active:['نشط','green'], paused:['موقوف مؤقتًا','warn'], awaiting:['بانتظار تأكيد الراكب','brand'], cancelled:['ملغي','red'], ended:['انتهى','']}[st] || ['نشط','green'];
  return `<button class="card press" style="width:100%;text-align:start;display:block;padding:0;overflow:hidden" data-go="recDetail">
    <div style="height:120px;position:relative">${mapHTML({center:[165,400], zoom:.5, route:['home','work'], pins:[['home','pick'],['work','drop']]})}<span class="tag ${lab[1]}" style="position:absolute;top:10px;right:10px">${lab[0]}</span></div>
    <div class="pad"><div class="flex between"><div class="bold" style="font-size:17px">مشوار الدوام</div><div class="bold"><span class="num">8.00</span> <span class="tiny muted">د.ل / مشوار</span></div></div>
    <div class="small muted">البيت (الزروق) ← الشغل (جامعة مصراتة)</div>
    <div class="week mt12">${['س','ح','ن','ث','ر','خ','ج'].map((d,i) => `<div class="d ${i<6?'on':''}">${d}<span class="dot ${i<6?(st==='paused'?'':'s-plan'):''}"></span></div>`).join('')}</div>
    <div class="flex mt12 small">${I('clock','xs')}<span class="grow">${st==='paused'?'موقوف لين <b>الأحد 15 نوفمبر</b>':'المشوار الجاي: <b>غدًا السبت <span class="num">07:15</span></b>'}</span>${st==='paused'?'':stChip('reserved')}</div></div></button>`;
}
ACTS.recDecline = () => dialog({icon:'x', tone:'red', title:'ما تبيش مشوار الدوام؟', text:'نسجّل ردّك «لا» ونخبر فريق الدعم. ما يتحجز أي مشوار.', ok:'نعم، لا أريده', cancel:'رجوع', danger:true, onOk:() => { P.sim='default'; P.rec.status='cancelled'; refresh(); toast('سجّلنا ردّك'); }});

screen('recConfirm', { title:'تأكيد مشوار الدوام (✅ / ❌)', group:'future', states:['error'],
  render:() => `${appbar('راجع مشوارك وأكّد', {sub:'جهّزه فريق تاكسيستا حسب طلبك'})}
    <div class="scroll" style="padding-bottom:20px">
      <div class="sec"><div class="card" style="padding:0;overflow:hidden"><div style="height:170px;position:relative">${mapHTML({center:[165,400], zoom:.55, route:['home','work'], pins:[['home','pick'],['work','drop']]})}</div>
        <div class="pad"><div class="timeline"><div class="tl done"><div class="t">البيت · الزروق</div><div class="s">الانطلاق <span class="num">07:15</span></div></div><div class="tl"><div class="t">الشغل · جامعة مصراتة</div><div class="s">الطريق الفعلي <span class="num">6.8</span> كم · ~<span class="num">14</span> د</div></div></div></div></div></div>
      <div class="sec"><div class="list">
        <div class="li"><span class="ic">${I('cal','sm')}</span><span class="tx"><span class="t" style="display:block">الأيام</span><span class="s" style="display:block">أيام العمل (السبت إلى الخميس)</span></span></div>
        <div class="li"><span class="ic">${I('clock','sm')}</span><span class="tx"><span class="t" style="display:block">وقت الركوب</span><span class="s" style="display:block"><span class="num">07:15</span> صباحًا · من 8 نوفمبر</span></span></div>
        <div class="li"><span class="ic">${I('cash','sm')}</span><span class="tx"><span class="t" style="display:block">الدفع</span><span class="s" style="display:block">نقدًا</span></span></div></div></div>
      <div class="sec"><div class="card"><div class="bold small">السعر لكل مشوار</div>
        <div class="col small mt8" style="gap:6px"><div class="flex between"><span class="muted">السعر الرسمي</span><span class="num">10.00</span></div><div class="flex between"><span class="muted">خصم تتحمله تاكسيستا</span><span class="num" style="color:var(--success)">-2.00</span></div><div class="hr" style="margin:2px 0"></div><div class="flex between bold"><span>تدفع</span><span class="num">8.00 د.ل</span></div></div>
        <div class="tiny muted mt8">كل مشوار يُحسب بسعر يومه حسب تسعير الحجز المسبق (يشمل رسم الحجز المسبق إن وُجد). فشل إيجاد سائق ما عليه أي رسوم.</div></div></div>
      ${P.sim==='error'?`<div class="sec"><div class="banner danger">${I('alert','sm')}<span>تعذّر التأكيد الآن. حاول مرة ثانية — ما تكرر شيء.</span></div></div>`:''}
    </div>
    <div class="sticky-cta"><div class="row-btns"><button class="btn success" data-act="recYes">✅ أؤكد</button><button class="btn outline" data-act="recDecline">❌ لا</button></div></div>`
});
ACTS.recYes = async (b) => { b.innerHTML = '<span class="spinner"></span>'; await wait(700); P.rec.status='active'; P.sim='default'; go('recDetail', {}, {replace:true}); later(() => { openSheet(`<div class="center"><div class="state" style="padding:4px 0">${checkAnim()}<h3>أكّدنا مشوار الدوام</h3><p>أول مشوار السبت 07:15 من البيت للشغل. نذكّرك قبل كل موعد، وتقدر تتخطى أي يوم.</p></div><button class="btn primary" onclick="closeSheet()">تمام</button></div>`); }, 350); };

screen('recDetail', { title:'تفاصيل مشوار الدوام', group:'future', states:['loading','paused','error'],
  render:() => { const paused = P.sim==='paused' || P.rec.status==='paused';
    return `${appbar('مشوار الدوام', {sub: paused?'موقوف مؤقتًا':'نشط · السبت إلى الخميس', right:`<button class="icon-btn" data-sheet="recMenu" aria-label="المزيد">${I('dots')}</button>`})}
    <div class="scroll" style="padding-bottom:20px">${simStates({}) || `
      ${paused?`<div class="sec"><div class="banner warn">${I('pause','sm')}<div class="grow"><b>موقوف لين الأحد 15 نوفمبر.</b> ما نحجزوش أي مشوار قبلها.</div><button class="link small" data-act="recResume">استئناف</button></div></div>`:''}
      <div class="sec"><div class="card" style="padding:0;overflow:hidden"><div style="height:150px;position:relative">${mapHTML({center:[165,400], zoom:.55, route:['home','work'], pins:[['home','pick'],['work','drop']]})}</div>
        <div class="pad flex between"><div><div class="bold">البيت ← الشغل</div><div class="tiny muted"><span class="num">07:15</span> · نقدًا · أي سائق متاح</div></div><div style="text-align:end"><div class="bold num">8.00</div><div class="tiny muted"><s class="num">10.00</s> خصم تاكسيستا</div></div></div></div></div>
      <div class="sec-title">هذا الأسبوع <span class="tiny muted">اضغط على أي يوم</span></div>
      <div class="sec" style="margin-top:0"><div class="list">${REC_DAYS.map((d,i) => `<button class="li" ${d.st==='off'?'disabled style="opacity:.55"':`data-sheet="recDay" data-p='{"i":${i}}'`}>
        <span class="ic ${d.st==='reserved'?'brand':''}" style="flex-direction:column;line-height:1.1"><span class="bold num" style="font-size:15px">${d.date.split(' ')[0]}</span><span class="tiny muted" style="font-size:10px">نوف</span></span>
        <span class="tx"><span class="t" style="display:block">${d.day} ${d.date}${d.time?` · <span class="num">${d.time}</span>`:''}</span><span class="s" style="display:block">${paused&&d.st!=='off'?'موقوف':d.label}</span></span>${d.st==='off'?'':stChip(paused?'skipped':d.st, paused?'موقوف':null)}</button>`).join('')}</div></div>
      <div class="sec-title">الأيام الماضية</div>
      <div class="sec" style="margin-top:0"><div class="list">${REC_PAST.map(d => `<div class="li"><span class="ic" style="flex-direction:column;line-height:1.1"><span class="bold num" style="font-size:15px">${d.date.split(' ')[0]}</span><span class="tiny muted" style="font-size:10px">نوف</span></span><span class="tx"><span class="t" style="display:block">${d.day} ${d.date}</span><span class="s" style="display:block">${d.label}</span></span>${stChip(d.st, d.st==='no_driver'?'تعذر توفير سائق':null)}</div>`).join('')}</div></div>
      <div class="sec"><div class="row-btns">${paused?`<button class="btn primary" data-act="recResume">${I('play','sm')} استئناف</button>`:`<button class="btn secondary" data-sheet="recPause">${I('pause','sm')} إيقاف مؤقت</button>`}<button class="btn danger" data-act="recCancel">${I('x','sm')} إلغاء الاتفاق</button></div></div>
      <p class="sec tiny muted">كل يوم يجيك سائق متاح؛ ما فيش سائق ثابت. تقدر تتواصل مع الدعم من <button class="link tiny" data-go="supportChat">المحادثة</button> لأي تعديل على الأيام أو المكان.</p>`}
    </div>`; }
});
SHEETS.recDay = (p) => { const d = REC_DAYS[p.i]; const booked = ['reserved','driver_ready'].includes(d.st);
  openSheet(`<h3>${d.day} ${d.date}</h3><div class="flex">${stChip(d.st)}<span class="small muted">الانطلاق <span class="num">${d.time}</span></span></div>
    ${booked?`<div class="card flex mt12" style="box-shadow:none;background:var(--surface-2);border:0"><span class="avatar">${DRIVERS.a.ini}</span><div class="grow"><div class="bold small">${DRIVERS.a.full} حجز الموعد</div><div class="tiny muted">${DRIVERS.a.car} · <span class="num">${DRIVERS.a.plate}</span></div></div></div>`:''}
    <div class="list mt12">
      ${d.st==='skipped'?`<button class="li" data-act="recUnskip"><span class="ic brand">${I('refresh','sm')}</span><span class="tx"><span class="t" style="display:block">ارجع المشوار لهذا اليوم</span></span></button>`:`
      <button class="li" data-act="recSkip" data-i="${p.i}"><span class="ic">${I('skip','sm')}</span><span class="tx"><span class="t" style="display:block">تخطي هذا اليوم فقط</span><span class="s" style="display:block">باقي الأيام تبقى كما هي</span></span></button>
      <button class="li" data-sheet="recMove" data-p='{"i":${p.i}}'><span class="ic">${I('clock','sm')}</span><span class="tx"><span class="t" style="display:block">غيّر وقت هذا اليوم</span><span class="s" style="display:block">مثلاً تبي تطلع بدري أو متأخر</span></span></button>`}
      ${booked?`<button class="li" data-go="schedDetail" data-p='{"id":"S-31"}'><span class="ic">${I('info','sm')}</span><span class="tx"><span class="t">تفاصيل الحجز</span></span>${I('chevL','sm')}</button>`:''}</div>
    ${booked?`<div class="banner info mt12">${I('info','sm')}<span>اليوم محجوز مع سائق؛ التخطي يلغي حجز هذا اليوم فقط بدون رسوم إذا كان قبل الموعد بوقت كافٍ.</span></div>`:''}`); };
ACTS.recSkip = async (t) => { const d = REC_DAYS[+t.dataset.i]; t.innerHTML = '<span class="spinner" style="border-top-color:var(--brand)"></span>'; await wait(500); d.st='skipped'; d.label='تم التخطي'; closeSheet(); refresh(); toast(`تمام، تخطينا مشوار ${d.day} ${d.date}. باقي الأيام كما هي.`, 'skip'); };
ACTS.recUnskip = () => { closeSheet(); toast('رجّعنا المشوار لهذا اليوم'); };
SHEETS.recMove = (p) => { const d = REC_DAYS[p.i]; openSheet(`<h3>وقت ${d.day} ${d.date}</h3><p class="sheet-sub">يتغير هذا اليوم فقط. الوقت المعتاد <span class="num">07:15</span>.</p>
  <div class="chips" style="margin:0 -16px;padding:0 16px">${['06:30','06:45','07:00','07:15','07:30','07:45','08:00','08:30'].map(t=>`<button class="chip ${t===d.time?'on':''}" data-act="pickTime"><span class="num">${t}</span></button>`).join('')}</div>
  <div class="banner info mt12">${I('info','sm')}<span>السعر يُحسب بسعر الوقت الجديد الرسمي. لو تغيّر كثير نسألك قبل الحجز.</span></div>
  <button class="btn primary mt12" data-act="recMoveSave" data-i="${p.i}">حفظ الوقت الجديد</button>`); };
ACTS.recMoveSave = (t) => { const d = REC_DAYS[+t.dataset.i]; const sel = $('.sheet .chip.on'); d.time = sel ? sel.textContent : d.time; d.label = 'مجدول · الوقت '+d.time; closeSheet(); refresh(); toast(`غيّرنا وقت ${d.day} إلى ${d.time}`, 'clock'); };
SHEETS.recPause = () => openSheet(`<h3>إيقاف مؤقت</h3><p class="sheet-sub">ما نحجزوش أي مشوار خلال الإيقاف، والاتفاق يبقى محفوظ.</p>
  <div class="list">${[['أسبوع','لين الأحد 15 نوفمبر'],['أسبوعين','لين الأحد 22 نوفمبر'],['لين نرجّعه بنفسي','بدون تاريخ']].map(([t,s],i)=>`<button class="li" data-act="reasonPick"><span class="radio ${i===0?'on':''}"></span><span class="tx"><span class="t" style="display:block">${t}</span><span class="s" style="display:block">${s}</span></span></button>`).join('')}</div>
  <button class="btn primary mt12" data-act="recPauseDo">${I('pause','sm')} أوقف مؤقتًا</button>`);
ACTS.reasonPick = (t) => { $$('.sheet .radio').forEach(r => r.classList.remove('on')); t.querySelector('.radio').classList.add('on'); };
ACTS.recPauseDo = () => { P.rec.status='paused'; closeSheet(); refresh(); toast('أوقفنا مشوار الدوام لين الأحد 15 نوفمبر', 'pause'); };
ACTS.recResume = () => { P.rec.status='active'; P.sim='default'; refresh(); toast('رجّعنا مشوار الدوام. أول مشوار غدًا 07:15', 'play'); };
ACTS.recCancel = () => dialog({icon:'x', tone:'red', title:'نلغي اتفاق مشوار الدوام؟', text:'تنلغى كل الأيام الجاية اللي ما بدأتش. الرحلات المكتملة تبقى في سجلك.', ok:'إلغاء الاتفاق', cancel:'رجوع', danger:true, onOk:() => { P.rec.status='cancelled'; go('recurring', {}, {replace:true}); toast('ألغينا الاتفاق'); }});
SHEETS.recMenu = () => openSheet(`<h3>خيارات</h3><div class="list">
  <button class="li" data-sheet="recPause"><span class="ic">${I('pause','sm')}</span><span class="tx"><span class="t">إيقاف مؤقت</span></span></button>
  <button class="li" data-go="supportChat"><span class="ic">${I('msg','sm')}</span><span class="tx"><span class="t" style="display:block">تعديل الأيام أو المكان</span><span class="s" style="display:block">عبر محادثة الدعم</span></span></button>
  <button class="li" data-act="recCancel"><span class="ic red">${I('x','sm')}</span><span class="tx"><span class="t" style="color:var(--danger)">إلغاء الاتفاق</span></span></button></div>`);

screen('recNew', { title:'طلب مشوار متكرر جديد (3 خطوات)', group:'future',
  render:(p) => { const st = p.st||0; return `${appbar('مشوار متكرر جديد', {sub:`الخطوة ${st+1} من 3`})}
    <div class="scroll" style="padding:0 16px 20px"><div class="steps">${[0,1,2].map(k=>`<span class="${k<=st?'done':''}"></span>`).join('')}</div>
    ${st===0?`<h3 style="margin:8px 0">من وين لوين؟</h3>
      <div class="route-fields"><div class="rf"><span class="dot"></span><input value="البيت · الزروق"></div><div class="rf"><span class="sq"></span><input value="الشغل · جامعة مصراتة"></div></div>
      <div class="card mt12" style="padding:0;overflow:hidden;height:180px;position:relative">${mapHTML({center:[165,400], zoom:.55, route:['home','work'], pins:[['home','pick'],['work','drop']]})}</div>`
    : st===1?`<h3 style="margin:8px 0">أي أيام وأي وقت؟</h3>
      <div class="chips" style="margin:0 -16px;padding:0 16px 8px"><button class="chip on">أيام العمل (السبت إلى الخميس)</button><button class="chip">يوميًا</button><button class="chip">أيام أختارها</button></div>
      <div class="week pick mt8">${['س','ح','ن','ث','ر','خ','ج'].map((d,i)=>`<button class="d ${i<6?'on':''}" data-act="tglDay">${d}</button>`).join('')}</div>
      <div class="field-label mt16">وقت الركوب</div><div class="chips" style="margin:0 -16px;padding:0 16px">${['06:45','07:00','07:15','07:30','08:00'].map(t=>`<button class="chip ${t==='07:15'?'on':''}" data-act="pickTime"><span class="num">${t}</span></button>`).join('')}</div>
      <div class="field-label mt16">يبدأ من</div><div class="input">${I('cal','sm')}<input value="السبت 7 نوفمبر"></div>`
    : `<h3 style="margin:8px 0">الدفع والسعر</h3>
      <div class="list"><button class="li"><span class="radio on"></span><span class="tx"><span class="t">نقدًا</span></span></button><button class="li"><span class="radio"></span><span class="tx"><span class="t" style="display:block">المحفظة</span><span class="s" style="display:block">نخصم كل مشوار بعد اكتماله</span></span></button></div>
      <div class="card mt12"><div class="flex between"><span class="muted small">السعر الرسمي التقديري لكل مشوار</span><span class="bold num">10.00 د.ل</span></div><div class="tiny muted mt8">يحسب الخادم السعر الرسمي لكل يوم. أي خصم من تاكسيستا يظهر هنا قبل التأكيد.</div></div>
      <div class="banner info mt12">${I('info','sm')}<span>بعد الإرسال يراجعه فريق تاكسيستا (المرحلة التجريبية)، ويوصلك طلب تأكيد بزرّين ✅ / ❌.</span></div>`}
    </div><div class="sticky-cta"><button class="btn primary" ${st<2?`data-go="recNew" data-replace="1" data-p='{"st":${st+1}}'`:'data-act="recSubmit"'}>${st<2?'التالي':'أرسل الطلب'}</button></div>`; }
});
ACTS.tglDay = (t) => t.classList.toggle('on');
ACTS.recSubmit = () => { go('recurring', {}, {replace:true}); later(() => { P.sim='awaiting'; refresh(); toast('وصل طلبك، وجهّزنا لك تأكيد'); }, 400); };

/* ================= REWARDS ================= */
const RW = () => P.rewards;
screen('rewards', { title:'مكافآتي (المركز)', group:'rewards', states:['loading','error','budget','earned'],
  render:() => { const r = RW(); const pct = r.done/r.target;
    return `${appbar('مكافآتي', {right:`<button class="icon-btn" data-sheet="rewardsHow" aria-label="كيف تعمل">${I('help')}</button>`})}
    <div class="scroll" style="padding-bottom:24px">${simStates({}) || `
      <div class="sec"><button class="reward-hero" data-go="campaign"><span class="shine"></span>${ring(pct, 112, 11, 'grad', `<div class="xbold" style="font-size:28px">${cnt(r.done,0)}</div><div class="tiny muted">من ${r.target}</div>`)}
        <div class="grow"><div class="tag" style="background:rgba(255,255,255,.16);color:#fff">${I('trophy','xs')} حملة نشطة · اضغط للتفاصيل</div>
          <div class="bold mt8" style="font-size:18px">100 رحلة = 100 دينار</div>
          <div class="small muted">${P.sim==='earned'?'حصلت على مكافأة هذه الحملة.':r.phase==='pending'?'100.00 د.ل في الطريق إليك':`باقي <b class="num">${r.target-r.done}</b> رحلة مكتملة`}</div>
          <div class="tiny muted mt8">تضاف كرصيد مشاوير · تنتهي 31 ديسمبر ${I('chevL','xs')}</div></div></button>
        ${P.sim==='budget'?`<div class="banner warn mt8">${I('info','sm')}<span>اكتملت ميزانية هذه الحملة، وقد تتأخر المكافأة.</span></div>`:''}</div>
      <div class="sec"><div class="bal3">
        <button class="b" data-sheet="balInfo" data-p='{"k":"credit"}'><div class="k">رصيد مشاوير</div><div class="v" style="color:var(--brand)">${cnt(P.wallet.credit)}</div><div class="tiny muted">للرحلات فقط</div></button>
        <button class="b" data-sheet="balInfo" data-p='{"k":"own"}'><div class="k">أموالك</div><div class="v">${cnt(P.wallet.own)}</div><div class="tiny muted">قابلة للتحويل</div></button>
        <button class="b" data-sheet="balInfo" data-p='{"k":"way"}'><div class="k">في الطريق</div><div class="v" style="color:var(--success)"><span class="num">${r.phase==='pending'?'100.00':'0.00'}</span></div><div class="tiny muted">بعد مهلة التسوية</div></button></div></div>
      <div class="sec"><button class="card press" style="width:100%;text-align:start;display:block;background:var(--gold-bg);border:0" data-sheet="gold">
        <div class="flex"><span class="ic" style="width:42px;height:42px;border-radius:50%;background:linear-gradient(135deg,#E0A526,#F7D774);color:#fff;display:flex;align-items:center;justify-content:center">${I('coins','sm')}</span><div class="grow"><div class="bold" style="color:var(--gold)">${cnt(340,0)} عملة ذهبية</div><div class="tiny muted">قيمتها 3.40 د.ل · باقي 160 عملة للتحويل</div></div>${I('chevL','sm')}</div>
        <div class="bar-h gold mt12"><i style="width:68%"></i></div></button></div>
      <div class="sec-title">حملات أخرى</div>
      <div class="sec" style="margin-top:0"><div class="list">
        <button class="li" data-sheet="campOther" data-p='{"k":"weekly"}'><span class="ic brand">${I('cal','sm')}</span><span class="tx"><span class="t" style="display:block">رحلتين زيادة هذا الأسبوع</span><span class="s" style="display:block">3 من 5 رحلات · ينتهي هذا الأسبوع</span></span><span class="end"><b class="num" style="color:var(--brand)">5.00</b></span></button>
        <button class="li" data-sheet="campOther" data-p='{"k":"return"}'><span class="ic green">${I('repeat','sm')}</span><span class="tx"><span class="t" style="display:block">رحلة العودة</span><span class="s" style="display:block">ارجع خلال 12 ساعة من نفس المكان</span></span><span class="end"><b class="num" style="color:var(--brand)">3.00</b></span></button></div></div>
      <div class="sec-title">إنجازاتك</div>
      <div class="sec" style="margin-top:0;display:flex;flex-wrap:wrap;gap:8px">${[['أول رحلة',1],['10 رحلات',1],['50 رحلة',1],['100 رحلة',0],['سواقيني',1],['تقييم 20 رحلة',0]].map(([t,ok])=>`<span class="tag ${ok?'gold':''}" style="padding:7px 11px;font-size:12.5px">${I(ok?'trophy':'lock','xs')} ${t}</span>`).join('')}</div>
      <div class="sec-title">آخر الحركات <button class="link small" data-go="transactions" data-p='{"f":"reward"}'>الكل</button></div>
      <div class="sec" style="margin-top:0"><div class="list">
        ${r.phase==='credited'?`<div class="li"><span class="ic gold">${I('trophy','sm')}</span><span class="tx"><span class="t" style="display:block">مكافأة 100 رحلة · رصيد مشاوير</span><span class="s" style="display:block">الآن</span></span><span class="amt-pos num">+100.00</span></div>`:''}
        <div class="li"><span class="ic gold">${I('coins','sm')}</span><span class="tx"><span class="t" style="display:block">عملات رحلة R-2041</span><span class="s" style="display:block">اليوم</span></span><span class="amt-pos num">+20</span></div>
        <div class="li"><span class="ic green">${I('repeat','sm')}</span><span class="tx"><span class="t" style="display:block">حملة العودة · رصيد مشاوير</span><span class="s" style="display:block">الإثنين</span></span><span class="amt-pos num">+5.00</span></div></div></div>
      <div class="sec"><div class="card flex"><div class="grow"><div class="bold small">أريد عروض تاكسيستا</div><div class="tiny muted">عند الإيقاف لا تصلك دعوات الحملات. مكافآتك الحالية تبقى كما هي.</div></div><button class="toggle on" data-act="tglSelf" aria-label="العروض"></button></div></div>`}
    </div>`; },
  mount:(el) => animateRings(el)
});
SCREENS.rewards.before = () => { const r = RW(); return `${appbar('مكافآتي')}
  <div class="scroll" style="padding:16px 16px 24px">
    <div class="bal3"><div class="b"><div class="k">رصيد مشاوير</div><div class="v" style="color:var(--brand)">${P.wallet.credit.toFixed(2)} د.ل</div><div class="tiny muted">للرحلات فقط</div></div><div class="b"><div class="k">أموالك</div><div class="v">${P.wallet.own.toFixed(2)} د.ل</div><div class="tiny muted">قابلة للتحويل</div></div><div class="b"><div class="k">في الطريق</div><div class="v" style="color:var(--success)">0.00 د.ل</div><div class="tiny muted">بعد مهلة التسوية</div></div></div>
    <div class="card mt12" style="background:var(--gold-bg);box-shadow:none"><div class="flex"><span class="ic" style="width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#D69E2E,#F6D365)"></span><div><div class="bold" style="color:var(--gold);font-size:19px">340 عملة ذهبية</div><div class="tiny muted">قيمتها 3.40 د.ل</div></div></div><div class="bar-h gold mt12"><i style="width:68%"></i></div><div class="small muted mt8">باقي 160 عملة للتحويل إلى رصيد مشاوير.</div></div>
    <div class="card mt12" style="box-shadow:none;border:1px solid var(--line)"><div class="bold">حملاتك</div>
      <div class="mt8" style="padding:12px;border-radius:12px;background:var(--surface-2)"><div class="flex between"><b>100 رحلة = 100 دينار</b><b style="color:var(--brand)">100 د.ل</b></div><div class="tiny muted">رصيد مشاوير</div><div class="bar-h mt8" style="height:7px"><i style="width:${r.done}%"></i></div><div class="small muted mt8">${r.done} من ${r.target} رحلة</div><div class="tiny muted">تنتهي الحملة 31 ديسمبر</div><div class="link small mt8">الشروط</div></div></div>
    <div class="card mt12" style="box-shadow:none;border:1px solid var(--line)"><div class="bold">إنجازاتك</div><div class="flex mt8" style="flex-wrap:wrap;gap:8px">${['أول رحلة','10 رحلات','50 رحلة'].map(t=>`<span class="tag gold" style="padding:7px 11px">${t}</span>`).join('')}<span class="tag" style="padding:7px 11px">${I('lock','xs')} 100 رحلة</span></div></div>
    <div class="card mt12" style="box-shadow:none;border:1px solid var(--line)"><div class="flex"><div class="grow"><div class="bold small">أريد عروض تاكسيستا</div><div class="tiny muted">عند الإيقاف لا تصلك دعوات الحملات. مكافآتك الحالية تبقى كما هي.</div></div><span class="toggle on"></span></div></div>
  </div>`; };
ACTS.tglSelf = (t) => t.classList.toggle('on');
SHEETS.balInfo = (p) => { const m = {credit:['رصيد مشاوير','مكافآت وهدايا من تاكسيستا. يُستخدم في رحلاتك ولا يُحوَّل ولا يُسحب.'], own:['أموالك','فلوسك اللي شحنتها بالبطاقة أو بطاقة الشحن أو التحويل. تقدر تحوّلها لشخص آخر.'], way:['في الطريق','مكافآت استحقيتها وتنتظر مهلة التسوية (مثلاً 24 ساعة) للتأكد إن الرحلات بقيت مكتملة، ثم تُضاف تلقائيًا.']}[p.k];
  openSheet(`<h3>${m[0]}</h3><p class="sheet-sub">${m[1]}</p><button class="btn secondary" data-go="wallet">افتح المحفظة</button>`); };
SHEETS.rewardsHow = () => openSheet(`<h3>كيف تشتغل مكافآتي؟</h3><div class="col small ink2" style="gap:10px;line-height:1.7">
  <div class="flex" style="align-items:flex-start">${I('car','sm')}<span><b>الحملات:</b> أكمل عدد رحلات خلال المدة واحصل على المكافأة. تُحسب الرحلات المكتملة فقط.</span></div>
  <div class="flex" style="align-items:flex-start">${I('clock','sm')}<span><b>مهلة التسوية:</b> المكافأة تظهر «في الطريق» ثم تُضاف بعد المهلة إذا بقيت الرحلات مكتملة.</span></div>
  <div class="flex" style="align-items:flex-start">${I('wallet','sm')}<span><b>رصيد مشاوير:</b> للرحلات فقط، لا يُحوَّل ولا يُسحب.</span></div>
  <div class="flex" style="align-items:flex-start">${I('coins','sm')}<span><b>العملات الذهبية:</b> تجمعها من الرحلات وتحوّلها لرصيد مشاوير لما توصل حد التحويل. بعضها له تاريخ انتهاء.</span></div></div>
  <p class="tiny muted mt12">النص الفعلي لكل حملة يجي من الخادم (الشروط) ونعرضه كما هو.</p>`);
SHEETS.gold = () => openSheet(`<div class="center"><span class="ic" style="width:64px;height:64px;border-radius:50%;background:linear-gradient(135deg,#E0A526,#F7D774);color:#fff;display:inline-flex;align-items:center;justify-content:center">${I('coins','lg')}</span>
  <h3 class="mt8"><span class="num">340</span> عملة ذهبية</h3><div class="small muted">قيمتها 3.40 د.ل</div></div>
  <div class="bar-h gold mt16"><i style="width:68%"></i></div><div class="flex between tiny muted mt8"><span>340</span><span>حد التحويل 500</span></div>
  <div class="col small mt12" style="gap:6px"><div class="flex">${I('clock','xs')} 40 عملة تصبح متاحة قريبًا.</div><div class="flex" style="color:var(--warn)">${I('alert','xs')} 60 عملة تنتهي خلال 30 يومًا.</div></div>
  <button class="btn primary mt16 disabled" style="background:linear-gradient(135deg,#E0A526,#F2C14E)">حوّل العملات إلى رصيد مشاوير</button><div class="tiny muted center mt8">يتفعّل الزر لما توصل 500 عملة</div>`);
SHEETS.campOther = (p) => openSheet(p.k==='weekly' ? `<h3>رحلتين زيادة هذا الأسبوع</h3><p class="sheet-sub">أكمل 2 رحلة أكثر من أسبوعك المعتاد واحصل على 5.00 د.ل. هدفك يظهر في بداية كل أسبوع.</p><div class="bar-h"><i style="width:60%"></i></div><div class="small mt8">3 من 5 رحلات · مكافأة واحدة في كل فترة</div>`
  : `<h3>رحلة العودة</h3><p class="sheet-sub">إذا رجعت خلال 12 ساعة من مكان قريب (حتى 500 متر) من حيث انتهت رحلتك إلى مكان قريب من حيث بدأت، تحصل على 3.00 د.ل.</p>`);

screen('campaign', { title:'بطاقة 100 رحلة (التفاصيل)', group:'rewards', states:['pending','credited','budget','ended','earned'],
  render:() => { const r = RW(); const sim = P.sim; const phase = sim==='pending'||sim==='credited' ? sim : r.phase;
    const done = phase==='progress' ? r.done : r.target; const pct = done/r.target;
    const ended = sim==='ended', earned = sim==='earned';
    return `${appbar('100 رحلة = 100 دينار', {hero:true, sub:'حملة للركاب في مصراتة'})}
    <div class="scroll" style="padding-bottom:24px">
      <div class="sec center ${phase!=='progress'?'celebrate':''}" style="padding-top:8px">${ring(pct, 188, 14, phase==='progress'?'grad':'gold', `<div class="xbold" style="font-size:46px">${cnt(done,0)}</div><div class="small muted">من ${r.target} رحلة</div>`)}
        <div class="mt12 bold" style="font-size:18px">${ended?'انتهت الحملة':earned?'حصلت على مكافأة هذه الحملة':phase==='progress'?`باقي <span class="num">${r.target-done}</span> رحلة على مكافأتك`:phase==='pending'?'استحقيت المكافأة!':'أُضيفت مكافأتك'}</div>
        <div class="small muted">${ended?'شكرًا لمشاركتك. ترقّب حملات جديدة.':phase==='progress'?'كل رحلة مكتملة تُحسب، والملغاة ما تُحسبش.':phase==='pending'?'100.00 د.ل في الطريق إليك — تُضاف بعد 24 ساعة إذا بقيت الرحلات مكتملة.':'100.00 د.ل أُضيفت إلى محفظتك كرصيد مشاوير.'}</div>
        ${phase==='credited'?`<button class="btn secondary mt12" data-go="wallet">${I('wallet','sm')} شوف المحفظة</button>`:''}
      </div>
      ${sim==='budget'?`<div class="sec"><div class="banner warn">${I('info','sm')}<span>اكتملت ميزانية هذه الحملة، وقد تتأخر المكافأة.</span></div></div>`:''}
      <div class="sec"><div class="card"><div class="flex between small"><span class="muted">${I('flag','xs')} معالم التقدّم</span><span class="tiny muted">للتحفيز فقط — المكافأة عند 100</span></div>
        <div class="flex between mt12" style="direction:ltr">${[25,50,75,100].map(m => `<div class="center" style="flex:1"><div style="width:34px;height:34px;border-radius:50%;margin:0 auto;display:flex;align-items:center;justify-content:center;${done>=m?'background:var(--brand);color:#fff':'background:var(--surface-2);color:var(--ink-3)'}">${done>=m?I('check','sm'):`<span class="tiny bold">${m}</span>`}</div><div class="tiny muted mt8">${m===100?'100 د.ل':m+' رحلة'}</div></div>`).join('')}</div></div></div>
      <div class="sec"><div class="list">
        <div class="li"><span class="ic brand">${I('car','sm')}</span><span class="tx"><span class="t" style="display:block">رحلات محسوبة</span><span class="s" style="display:block">في مدة الحملة الحالية</span></span><span class="bold num">${done}</span></div>
        <div class="li"><span class="ic">${I('cal','sm')}</span><span class="tx"><span class="t" style="display:block">تنتهي الحملة</span><span class="s" style="display:block">وقد تتوقف إذا انتهت ميزانيتها</span></span><span class="small">31 ديسمبر 2026</span></div>
        <div class="li"><span class="ic gold">${I('wallet','sm')}</span><span class="tx"><span class="t" style="display:block">تُضاف كـ</span><span class="s" style="display:block">للرحلات فقط، لا تُحوَّل ولا تُسحب</span></span><span class="small bold">رصيد مشاوير</span></div>
        <div class="li"><span class="ic">${I('repeat','sm')}</span><span class="tx"><span class="t" style="display:block">التكرار</span></span><span class="small">مرة واحدة فقط</span></div></div></div>
      <div class="sec-title">الشروط (نص الخادم)</div>
      <div class="sec" style="margin-top:0"><div class="card small ink2" style="line-height:1.9">
        • أكمل 100 رحلة خلال مدة الحملة واحصل على 100.00 د.ل.<br>• تُحسب الرحلات المكتملة فقط، ولا تُحسب الرحلات الملغاة.<br>• المكافأة مرة واحدة فقط.<br>• تُضاف المكافأة بعد 24 ساعة من الرحلة إذا بقيت الرحلة مكتملة.<br>• للراكب: تُضاف كرصيد مشاوير في محفظتك، يُستخدم في رحلاتك ولا يُحوَّل ولا يُسحب.<br>• تنتهي الحملة في 2026-12-31، وقد تتوقف إذا انتهت ميزانيتها.
        <div class="tiny muted mt8">مثال من منطق الخادم (CampaignRules::terms). القيم الحقيقية (24 ساعة، التاريخ، التكرار) تجي من إعدادات الحملة.</div></div></div>
      <div class="sec"><button class="card flex press" style="width:100%;text-align:start" data-sheet="whyNot"><span class="ic" style="width:38px;height:38px;border-radius:12px;background:var(--surface-2);display:flex;align-items:center;justify-content:center">${I('help','sm')}</span><span class="grow small bold">ليش رحلة ما انحسبتش؟</span>${I('chevL','sm')}</button></div>
      <div class="sec-title">سجل الرحلات المحسوبة</div>
      <div class="sec" style="margin-top:0"><div class="list">${HISTORY.filter(h=>h.st==='done').slice(0,3).map((h,i) => `<div class="li"><span class="ic green">${I('check','sm')}</span><span class="tx"><span class="t" style="display:block">${h.from} ← ${h.to}</span><span class="s" style="display:block">${h.date}</span></span><span class="tag green">رقم <span class="num">${done-i}</span></span></div>`).join('')}
        <div class="li"><span class="ic red">${I('x','sm')}</span><span class="tx"><span class="t" style="display:block">ميدان النصر ← المستشفى</span><span class="s" style="display:block">الثلاثاء · ملغاة — ما تُحسبش</span></span></div></div></div>
      <div class="demo-ctl" style="margin:12px 16px"><div class="tiny">محاكاة العرض (لا علاقة لها بالخادم)</div><div class="flex"><button class="chip" data-act="rwPlus">+1 رحلة</button><button class="chip" data-act="rwReach">الوصول إلى 100</button><button class="chip" data-act="rwCredit">اعتماد المكافأة</button><button class="chip" data-act="rwReset">إعادة</button></div></div>
    </div>`; },
  mount:(el) => animateRings(el)
});
SHEETS.whyNot = () => openSheet(`<h3>ليش رحلة ما انحسبتش؟</h3><div class="col small ink2" style="gap:10px;line-height:1.7">
  <div class="flex" style="align-items:flex-start">${I('x','sm')}<span>الرحلة انلغت (من أي طرف).</span></div>
  <div class="flex" style="align-items:flex-start">${I('route','sm')}<span>قصيرة جدًا في المسافة أو الوقت حسب حدود البرنامج.</span></div>
  <div class="flex" style="align-items:flex-start">${I('users','sm')}<span>رحلات كثيرة مع نفس السائق في نفس اليوم فوق الحد المسموح.</span></div>
  <div class="flex" style="align-items:flex-start">${I('tag','sm')}<span>قيمتها أقل من الحد الأدنى للحملة (إن وُجد).</span></div>
  <div class="flex" style="align-items:flex-start">${I('clock','sm')}<span>خارج مدة الحملة أو بعد انتهاء ميزانيتها.</span></div></div>
  <p class="tiny muted mt12">هذه القواعد موجودة في الخادم (rideRules / minimum_ride_amount). الأرقام نعرضها فقط إذا أرسلها الخادم — ما نفترضش أرقام.</p>
  <button class="btn secondary mt12" data-go="supportChat">اسأل الدعم عن رحلة معيّنة</button>`);
ACTS.rwPlus = () => { if (RW().done < RW().target) RW().done++; if (RW().done >= RW().target) return ACTS.rwReach(); refresh(); };
ACTS.rwReach = () => { RW().done = RW().target; RW().phase = 'pending'; P.sim='default'; refresh(); celebrate(); };
ACTS.rwCredit = () => { RW().phase = 'credited'; RW().done = RW().target; P.wallet.credit += 100; P.sim='default'; refresh(); pushNotif('أُضيفت مكافأة 100 رحلة', '100.00 د.ل رصيد مشاوير في محفظتك'); };
ACTS.rwReset = () => { RW().done = 63; RW().phase='progress'; if (P.wallet.credit > 100) P.wallet.credit -= 100; P.sim='default'; refresh(); };
function celebrate(){
  const scr = $('#screen'); confetti(scr);
  openSheet(`<div class="center celebrate">${ring(1, 120, 12, 'gold', `<span style="color:var(--gold)">${I('trophy','xl')}</span>`)}
    <h3 class="mt12">وصلت 100 رحلة!</h3><p class="sheet-sub">مبروك يا ${ME.first}. مكافأتك <b>100.00 د.ل</b> في الطريق — تُضاف كرصيد مشاوير بعد 24 ساعة إذا بقيت الرحلات مكتملة. نرسلولك إشعار أول ما تنضاف.</p>
    <button class="btn primary" onclick="closeSheet()">تمام</button></div>`, {mount:(s) => animateRings(s)});
}
screen('celebrate', { title:'لحظة الاستحقاق (احتفال)', group:'rewards',
  render:() => `${appbar('مكافآتي')}<div class="scroll">${stateBlock({icon:'trophy', tone:'gold', title:'اضغط لعرض لحظة الاستحقاق', text:'احتفال قصير (أقل من 1.5 ثانية)، يحترم «تقليل الحركة»، بدون وعود مالية غير دقيقة.', cta:'عرض الاحتفال', ctaAct:'rwReach'})}</div>`
});
