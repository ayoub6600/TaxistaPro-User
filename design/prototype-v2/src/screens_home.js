/* Screens: start/auth, home & search, booking — evolved from today's app look. SAMPLE DATA. */
'use strict';
const B = () => P.booking;
const isB = () => false;
const greet = () => { const h = new Date().getHours(); return h < 12 ? 'صباح الخير' : 'مساء الخير'; };
const vehOf = id => VEHICLES.find(v => v.id===id) || VEHICLES[0];
const fareOf = id => vehOf(id).fare;
const dropName = () => B().noDest ? 'بدون وجهة — تقولها للسائق' : placeById(B().drop||'square').name;
const pickName = () => B().pick==='me' ? 'موقعك الحالي · الزروق' : placeById(B().pick).name;
function couponValue(){ return B().coupon ? 5 : 0; }
function finalFare(){ const base = B().mode==='offer' ? B().offer : fareOf(B().veh); return Math.max(0, base - couponValue()); }
const pimg = (k, w, h, extra='') => `<img class="pimg" src="${IMG[k]}" alt="" width="${w}" ${h?`height="${h}"`:''} ${extra}>`;

/* ================= START ================= */
screen('splash', { title:'شاشة البداية', group:'start', statusLight:true,
  render:() => `<div class="splash" style="background-image:url(${IMG.onboard})">
    <div class="logo" style="animation:popIn .6s var(--ease-spring) both"><img src="${IMG.logo}" alt="Taxista"></div>
    <div style="color:#fff;font-weight:800;font-size:28px;animation:rise .6s .2s var(--ease-out) both">تاكسيستا</div>
    <div class="small" style="color:rgba(255,255,255,.8);animation:rise .6s .3s var(--ease-out) both">اسرع طريقة لتطلب سيارة من دون ما تستنى او تفاصل</div>
    <div style="position:absolute;bottom:70px;display:flex;flex-direction:column;align-items:center;gap:10px">
      ${P.sim==='weak' ? `<div class="banner warn" style="max-width:300px">${I('wifiOff','sm')}<span>الاتصال بطيء… يبدو أن الإنترنت لديك ضعيف. أبقِ التطبيق مفتوحًا، ما زلنا نحاول.</span></div>` : `<span class="spinner" style="width:26px;height:26px;border-radius:50%;border:3px solid rgba(255,255,255,.3);border-top-color:#fff;animation:spin .8s linear infinite"></span>`}
    </div></div>`,
  states:['weak'],
  mount:() => later(() => { if (P.screen==='splash' && P.sim==='default') go('onboarding', {}, {replace:true}); }, 1900)
});

const SLIDES = [ // today's onboarding copy (translation.dart)
  ['shield','ضمان','سلامة هي اولويتنا دائمًا وأبدًا معك في كل خطوة من نقطة الانطلاق إلى الوصول'],
  ['headset','دعم 24 ساعة','انطلق في رحلتك بثقة، مع العلم أن التزامنا بإرضائك لا يتزعزع'],
  ['tag','الوضوح','أسعار عادلة، ووضوح تام. معنا لن تجد أي رسوم خفية، الشفافية هي ضمانتنا'],
  ['car','وصول سلس وسهل','رحلات سلسة بنقره واحده فقط استكشف دون أي متاعب في كل خطوة علي الطريق']];
screen('onboarding', { title:'التعريف (4 شرائح)', group:'start', statusLight:true,
  render:(p) => { const i = p.i||0; const s = SLIDES[i];
    return `<div style="position:absolute;inset:0;background:#0A1220 url(${IMG.onboard}) center/cover"></div><div style="position:absolute;inset:0;background:linear-gradient(180deg,rgba(10,18,32,.05) 30%,rgba(10,18,32,.92) 70%)"></div>
      <div class="col" style="position:absolute;left:0;right:0;bottom:0;padding:24px 24px calc(28px + env(safe-area-inset-bottom,0px));color:#fff;gap:10px" id="slide">
        <div style="width:58px;height:58px;border-radius:18px;background:rgba(255,255,255,.14);display:flex;align-items:center;justify-content:center;animation:popIn .5s var(--ease-spring) both">${I(s[0],'lg')}</div>
        <h2 style="font-size:28px;margin:6px 0 0;font-weight:800;animation:rise .45s var(--ease-out) both">${s[1]}</h2>
        <p style="margin:0;font-size:15.5px;line-height:1.9;opacity:.85;animation:rise .45s 60ms var(--ease-out) both">${s[2]}</p>
        <div class="flex between mt16"><div class="progress-dots" style="justify-content:flex-start">${SLIDES.map((_,k) => `<i class="${k===i?'on':''}" style="${k===i?'background:#fff':''}"></i>`).join('')}</div>
          <button class="link" style="color:rgba(255,255,255,.8)" data-go="login" data-replace="1">تخطي</button></div>
        <button class="btn primary" ${i<3?`data-act="slideNext"`:'data-go="login" data-replace="1"'}>${i<3?'التالي':'يلا نبدأ !'}</button>
      </div>`; },
  mount:(el) => { // swipe between slides
    let x0 = null; el.addEventListener('pointerdown', e => x0 = e.clientX); el.addEventListener('pointerup', e => { if (x0===null) return; const dx = e.clientX - x0; x0 = null; const i = P.params.i||0;
      if (dx < -50 && i > 0) go('onboarding', {i:i-1}, {replace:true}); else if (dx > 50 && i < 3) go('onboarding', {i:i+1}, {replace:true}); });
  }
});
ACTS.slideNext = () => go('onboarding', {i:(P.params.i||0)+1}, {replace:true});

screen('login', { title:'تسجيل الدخول', group:'start', states:['error','offline'],
  render:(p) => { const tab = p.tab||'phone'; return `
    ${appbar('', {noBack:true, right:`<button class="chip" data-go="language">${I('globe','sm')} العربية</button>`})}
    <div class="scroll" style="padding:0 20px 20px">
      <div class="logo" style="width:68px;height:68px;border-radius:20px;margin-bottom:16px;animation:popIn .5s var(--ease-spring) both"><img src="${IMG.logo}" alt=""></div>
      <h2 style="font-size:26px;margin:0;font-weight:800">تسجيل الدخول</h2>
      <p class="ink2" style="margin:4px 0 18px">اختر طريقة الدخول المناسبة لك.</p>
      <div class="tabs" style="margin:0 0 16px"><button class="${tab==='phone'?'on':''}" data-act="loginTab" data-v="phone">الهاتف</button><button class="${tab==='email'?'on':''}" data-act="loginTab" data-v="email">البريد</button></div>
      <div id="loginFields" class="stagger">${tab==='phone' ? `<div><div class="field-label">الدولة</div><div class="input"><span style="font-size:20px">🇱🇾</span><span class="grow bold">ليبيا</span><span class="num muted">+218</span>${I('chevD','sm')}</div></div>
        <div class="mt12"><div class="field-label">اكتب رقم موبايلك</div><div class="input"><span class="num bold muted">+218</span><input inputmode="tel" placeholder="91 234 5678" value="91 000 0000" dir="ltr"></div></div>`
      : `<div><div class="field-label">البريد الإلكتروني</div><div class="input">${I('msg','sm')}<input placeholder="name@example.ly" dir="ltr"></div></div>`}
      <div class="mt12"><div class="field-label">كلمة المرور</div><div class="input ${P.sim==='error'?'error':''}">${I('lock','sm')}<input type="password" value="••••••••"><button class="link small">إظهار</button></div>
      ${P.sim==='error'?`<div class="help err">بيانات الدخول غير صحيحة. راجع الحساب وكلمة المرور.</div>`:''}</div></div>
      ${P.sim==='offline'?`<div class="banner danger mt12">${I('wifiOff','sm')}<span>تعذر الاتصال بالخادم. تحقق من الإنترنت ثم أعد المحاولة.</span></div>`:''}
      <div class="flex between mt12"><span></span><button class="link" data-go="forgot">نسيت كلمة المرور؟</button></div>
      <button class="btn primary mt16" data-act="doLogin">تسجيل الدخول</button>
      <button class="btn outline mt12" data-go="signup">إنشاء حساب جديد</button>
    </div>`; }
});
ACTS.loginTab = (t) => { P.params.tab = t.dataset.v; refresh(); };
ACTS.doLogin = async (b) => { if (P.sim==='error'){ const i = $('.page:last-child .input.error'); if (i){ i.classList.remove('error'); void i.offsetWidth; i.classList.add('error'); } return; } b.innerHTML = '<span class="spinner"></span>'; await wait(800); go('permission', {}, {root:true}); };

screen('forgot', { title:'استعادة الحساب + رمز واتساب', group:'start', states:['error'],
  render:(p) => { const st = p.st||0; return `${appbar('استعادة حسابك')}
    <div class="scroll" style="padding:0 20px 20px">
      <div class="steps">${[0,1,2].map(k=>`<span class="${k<=st?'done':''}"></span>`).join('')}</div>
      <div class="stagger">${st===0?`<h3 style="margin:12px 0 6px">رقم الهاتف</h3><p class="ink2 small">أدخل رقم الهاتف المرتبط بحسابك وسنرسل لك رمز تحقق.</p>
        <div class="input mt12"><span class="num bold muted">+218</span><input value="91 000 0000" dir="ltr"></div>
        <button class="btn primary mt24" data-go="forgot" data-replace="1" data-p='{"st":1}'>أرسل الرمز على واتساب</button>`
      : st===1? otpBlock('forgot', {st:2}) :
      `<h3 style="margin:12px 0 6px">أنشئ كلمة مرور جديدة</h3><p class="ink2 small">استخدم 8 أحرف على الأقل.</p>
        <div class="input mt12">${I('lock','sm')}<input type="password" value="••••••••••"></div>
        <div class="bar-h mt8"><i style="width:80%;background:var(--success)"></i></div><div class="help">قوية بما يكفي</div>
        <button class="btn primary mt24" data-act="pwDone">حفظ والدخول</button>`}</div>
    </div>`; }
});
ACTS.pwDone = () => { go('login', {}, {root:true}); later(() => toast('تم تحديث كلمة المرور. سجّل الدخول الآن.'), 350); };
function otpBlock(next, p){
  return `<h3 style="margin:12px 0 6px">أدخل رمز التحقق</h3><p class="ink2 small">أرسلنا رمزًا مكوّنًا من 6 أرقام إلى <span class="num">+218 91 000 0000</span> عبر واتساب.</p>
    <div class="otp mt16" id="otp">${[0,1,2,3,4,5].map(k=>`<span class="${k===0?'f':''}"></span>`).join('')}</div>
    ${P.sim==='error'?`<div class="help err center">الرمز غير صحيح، حاول مرة أخرى.</div>`:''}
    <div class="center mt16 small muted">إعادة إرسال الرمز خلال <span class="num" data-count="0" data-from="42" data-ms="42000">42</span> ثانية</div>
    <button class="btn secondary mt16" data-act="autoOtp" data-next="${next}" data-p='${JSON.stringify(p)}'>${I('msg','sm')} الصق الرمز من واتساب</button>`;
}
ACTS.autoOtp = async (t) => { const spans = $$('#otp span'); for (let k=0;k<6;k++){ await wait(110); spans.forEach(s => s.classList.remove('f')); spans[k].textContent = '481926'[k]; spans[k].classList.add('f'); spans[k].style.animation='none'; void spans[k].offsetWidth; spans[k].style.animation=''; }
  await wait(350); go(t.dataset.next, JSON.parse(t.dataset.p), {replace:true}); };

const SIGNUP = [ // today's order (auth_policy.dart SignupField)
  ['name','أهلًا! ما اسمك؟','اكتب اسمك كما تحب أن يظهر.'],['country','الدولة','الرمز الدولي مضبوط تلقائيًا.'],['area','أين تسكن؟','اختر المنطقة التي ستستخدم فيها تاكسيستا.'],
  ['email','بريدك الإلكتروني (اختياري)',''],['password','أمّن حسابك','استخدم 8 أحرف على الأقل.'],['phone','رقم هاتفك','نرسل لك رمز التحقق على واتساب.'],['otp','',''],['gender','الجنس','']];
screen('signup', { title:'إنشاء حساب (نفس خطوات اليوم)', group:'start', states:['error'],
  render:(p) => { const st = p.st||0; const [k,t,s] = SIGNUP[st];
    const body = { name:`<div class="input">${I('user','sm')}<input value="أحمد علي"></div>`,
      country:`<div class="input"><span style="font-size:20px">🇱🇾</span><span class="grow bold">ليبيا</span><span class="num muted">+218</span></div>`,
      area:`<div class="list">${['مصراتة','طرابلس','بنغازي'].map((a,i)=>`<button class="li" data-act="reasonPick"><span class="radio ${i===0?'on':''}"></span><span class="tx"><span class="t">${a}</span></span></button>`).join('')}</div><div class="banner info mt12">${I('pin','sm')}<span>حددنا منطقتك تلقائيًا من موقعك: <b>مصراتة</b></span></div>`,
      email:`<div class="input">${I('msg','sm')}<input placeholder="name@example.ly" dir="ltr"></div>`,
      password:`<div class="input">${I('lock','sm')}<input type="password" value="••••••••"></div><div class="bar-h mt8"><i style="width:70%;background:var(--success)"></i></div>`,
      phone:`<div class="input"><span class="num bold muted">+218</span><input value="92 000 0000" dir="ltr"></div>`,
      otp:otpBlock('signup', {st:7}), gender:`<div class="flex"><button class="chip on" data-act="pickTime">ذكر</button><button class="chip" data-act="pickTime">أنثى</button></div>` }[k];
    return `${appbar('إنشاء حساب', {sub:`الخطوة ${st+1} من ${SIGNUP.length}`})}
    <div class="scroll" style="padding:0 20px 20px"><div class="bar-h"><i style="width:${(st+1)/SIGNUP.length*100}%"></i></div>
      <div class="stagger" style="margin-top:18px">${t?`<h3 style="margin:0 0 4px;font-size:21px;font-weight:800">${t}</h3>`:''}${s?`<p class="ink2 small" style="margin:0 0 14px">${s}</p>`:''}<div>${body}</div></div></div>
    ${k==='otp'?'':`<div class="sticky-cta"><button class="btn primary" ${st<SIGNUP.length-1?`data-go="signup" data-replace="1" data-p='{"st":${st+1}}'`:'data-go="agreement" data-replace="1"'}>${k==='phone'?'أرسل الرمز على واتساب':'التالي'}</button></div>`}`; }
});
screen('agreement', { title:'الموافقة وإنشاء الحساب', group:'start',
  render:() => `${appbar('مراجعة الحساب')}
    <div class="scroll" style="padding:0 20px 20px"><h3 style="margin:8px 0 4px;font-size:21px;font-weight:800">أنت على بُعد خطوة واحدة</h3><p class="ink2 small">نحافظ على بياناتك ونستخدمها فقط لتشغيل رحلاتك بأمان.</p>
      <div class="list mt12 stagger"><div class="li"><span class="ic brand">${I('lock','sm')}</span><span class="tx"><span class="t" style="display:block">حساب آمن</span><span class="s" style="display:block">بيانات الدخول مشفّرة ومحمية.</span></span></div>
        <div class="li"><span class="ic brand">${I('pin','sm')}</span><span class="tx"><span class="t" style="display:block">الموقع عند الحاجة فقط</span><span class="s" style="display:block">نستخدم موقعك لخدمة الرحلة وتحديد التغطية.</span></span></div></div>
      <button class="flex mt16 small" style="align-items:flex-start;text-align:start" data-act="agreeT"><span class="radio" id="agreeR" style="border-radius:7px"></span><span>أوافق على <span class="link small">شروط الاستخدام</span> و<span class="link small">سياسة الخصوصية</span></span></button></div>
    <div class="sticky-cta"><button class="btn primary disabled" id="agreeBtn" data-act="signupDone">إنشاء الحساب</button></div>`
});
ACTS.agreeT = () => { const r = $('#agreeR'); r.classList.toggle('on'); $('#agreeBtn').classList.toggle('disabled', !r.classList.contains('on')); };
ACTS.signupDone = async (b) => { b.innerHTML = '<span class="spinner"></span> جارٍ إنشاء حسابك…'; await wait(900); go('permission', {after:'gift'}, {root:true}); };
SHEETS.welcomeGift = () => { openSheet(`<div class="center"><div class="state" style="padding:4px 0 0"><img src="${IMG.mascot}" alt="" width="104" style="animation:popIn .6s var(--ease-spring) both"></div>
  <div class="tag gold">هدية ترحيبية</div><h3 class="mt8">أهلًا بك في تاكسيستا!</h3><div class="xbold" style="font-size:40px;color:var(--brand)">${cnt(10,0)} <span style="font-size:18px">دينار</span></div>
  <p class="sheet-sub">هذه هديتك الترحيبية، جاهزة لرحلتك الأولى. تُخصم تلقائيًا من أول رحلة.</p>
  <button class="btn primary" onclick="closeSheet()">ابدأ رحلتك</button></div>`, {mount:(s) => countUps(s)}); confetti($('#screen')); };

screen('permission', { title:'إذن الموقع (قبل/بعد الرفض)', group:'start', states:['denied'],
  render:() => P.sim==='denied' ? `<div class="scroll col" style="padding:90px 24px 24px;align-items:center;text-align:center">
      <div class="state"><img src="${IMG.noLocation}" alt="" width="120" style="animation:popIn .5s var(--ease-spring) both"><h3>الموقع مقفول</h3><p>ما نقدروش نحددوا مكانك تلقائيًا. فعّله من الإعدادات، أو اختر نقطة اللقاء على الخريطة بيدك.</p></div></div>
      <div class="sticky-cta col" style="gap:8px;border:0"><button class="btn primary">${I('settings','sm')} افتح الإعدادات</button><button class="btn outline" data-act="permSkip">أحدد على الخريطة</button></div>`
    : `<div class="scroll col" style="padding:80px 24px 24px;align-items:center;text-align:center">
      <img src="${IMG.mascot}" alt="" width="130" style="animation:popIn .6s var(--ease-spring) both">
      <h2 class="mt16" style="margin-bottom:6px;font-weight:800">تمكين الموقع</h2><p class="ink2" style="line-height:1.9">لتستمتع من تجربة رحلتك، خلّي السائق يلقاك بسرعة. نستخدم موقعك أثناء استعمال التطبيق فقط.</p></div>
      <div class="sticky-cta col" style="gap:8px;border:0"><button class="btn primary" data-act="permOk">السماح بالموقع</button><button class="btn ghost" data-act="permSkip">مش الآن</button></div>`
});
ACTS.permOk = () => { const gift = P.params.after==='gift'; go('home', {}, {root:true}); if (gift) later(() => SHEETS.welcomeGift(), 900); };
ACTS.permSkip = () => { P.sim='default'; go('home', {}, {root:true}); later(() => { P.sim='denied'; refresh(); }, 50); };

screen('update', { title:'تحديث مطلوب / متاح', group:'start', states:['success'],
  render:() => `<div class="scroll col" style="padding:100px 24px 24px;align-items:center;text-align:center">
    <div class="logo" style="width:96px;height:96px;animation:popIn .5s var(--ease-spring) both"><img src="${IMG.logo}" alt=""></div>
    <h2 class="mt24" style="margin-bottom:6px;font-weight:800">تحديث جديد لتاكسيستا</h2>
    <p class="ink2" style="line-height:1.8">حسّنّا المكالمات والخرائط وأداء التطبيق لتجربة أسرع وأسهل.</p>
    <div class="tag brand">الإصدار <span class="num">6.8.0</span></div>
    ${P.sim==='success'?'':`<div class="banner warn mt16">${I('info','sm')}<span>هذا التحديث مطلوب لمتابعة استخدام تاكسيستا بأمان.</span></div>`}</div>
    <div class="sticky-cta col" style="gap:6px;border:0"><button class="btn primary">${I('download','sm')} تحديث الآن</button>${P.sim==='success'?'<button class="btn ghost" data-go="home" data-replace="1">لاحقًا</button>':''}</div>`
});
screen('offline', { title:'لا يوجد إنترنت', group:'start',
  render:() => `${appbar('')}<div class="scroll">${stateBlock({icon:'wifiOff', tone:'red', title:'ما فيش اتصال بالإنترنت', text:'تحقّق من الواي فاي أو بيانات الهاتف. سنكمل فور عودة الاتصال، ورحلتك الجارية تبقى محفوظة.', cta:'إعادة المحاولة', ctaAct:'retry'})}</div>`
});

/* ================= HOME ================= */
function homeMap(denied){
  return `${mapHTML({center:MAP_PTS.me, oy:120, idleCars:!denied})}
    ${denied?'':`<div class="mascot-on-map" style="top:calc(50% - 120px - 128px)"><div class="bob" style="display:flex;flex-direction:column;align-items:center"><div class="pin-bubble">${ME.first}</div><img src="${IMG.mascot}" alt=""></div></div>`}`;
}
function homeFloat(after){
  const r = P.rewards, next = UPCOMING[0];
  return `<div class="home-float">
    ${after ? `<button class="booking-card" data-go="upcoming"><span style="width:42px;height:42px;border-radius:14px;background:rgba(255,255,255,.16);display:flex;align-items:center;justify-content:center">${I('repeat','sm')}</span>
        <span class="grow"><span class="bold small" style="display:block">مشوار الدوام · ${next.day} <span class="num">${next.time}</span></span><span class="tiny" style="display:block;opacity:.8">${next.label} · البيت ← الشغل</span></span>${I('chevL','sm')}</button>` :
      `<button class="booking-card" data-go="upcomingOld"><span class="grow"><span class="bold small" style="display:block">حجوزاتك</span><span class="tiny" style="display:block;opacity:.8">رحلاتك القادمة في مكان واحد</span></span>${I('chevL','sm')}</button>`}
    <div class="quick">
      ${[['home','home','البيت','الزروق','var(--brand)'],['work','work','الشغل','جامعة مصراتة','var(--work)'],['hospital','history','مؤخراً','المستشفى المركزي','var(--recent)']].map(([id,ic,t,s,c]) => `<button class="qd" data-act="pickDest" data-id="${id}"><span class="soft" style="background:color-mix(in srgb, ${c} 12%, transparent);color:${c}">${I(ic,'sm')}</span><span class="t">${t}</span><span class="s"><span class="grow" style="overflow:hidden;text-overflow:ellipsis">${s}</span>${I('chevL','xs')}</span></button>`).join('')}
    </div>
    <div class="flex" style="gap:9px"><button class="nodest grow" data-act="noDest"><span style="color:var(--brand)">${I('nav','sm')}</span>رحلة بدون وجهة</button>
      ${after?`<button class="nodest" style="width:auto;flex:0 0 auto" data-go="recurring">${I('repeat','sm')} مشوار الدوام</button>`:''}</div>
    <button class="where" data-go="search" data-p='{"field":"drop"}'><span class="bar"></span><span class="lbl">${after?'<b style="color:var(--ink);font-size:16.5px">إلى أين؟</b><small>ابحث عن مكان أو عنوان</small>':'ابحث عن مكان أو عنوان'}</span>
      ${after?`<span class="later" data-sheet="schedule">${I('clock','xs')} الآن</span>`:''}<span class="go">${I('search')}</span></button>
  </div>`;
}
function promoCard(after){
  const r = P.rewards;
  return `<${after?'button':'div'} class="promo-card" ${after?'data-go="campaign"':''} style="position:absolute;top:calc(54px + 58px);left:16px;right:16px;z-index:5;width:auto;animation:rise 500ms 200ms var(--ease-out) both">
    ${after ? ring(r.done/r.target, 42, 5, 'var(--brand)', `<span class="tiny xbold num">${r.done}</span>`) : `<span style="width:38px;height:38px;border-radius:50%;background:#E8F5EE;color:#159668;display:flex;align-items:center;justify-content:center">${I('gift','sm')}</span>`}
    <span class="grow"><span class="bold" style="display:block;font-size:13px;color:var(--ink)">مكافأة الرحلات: 100 دينار</span><span class="tiny muted" style="display:block">أكملت ${r.done} من ${r.target} رحلة${after?` · باقي ${r.target-r.done}`:''}</span>
      ${after?'':`<span class="bar-h" style="display:block;height:4px;margin-top:6px"><i style="width:${r.done}%;background:#1677F8"></i></span>`}</span>
    <span style="color:var(--brand)">${I('chevL','sm')}</span></${after?'button':'div'}>`;
}
screen('home', { title:'الرئيسية (الخريطة)', group:'home', states:['loading','denied','offline','recovery','ongoing'],
  before:() => `${homeMap(false)}<div class="map-top"><button class="icon-btn" style="border-radius:18px">${I('menu')}</button><span></span></div>${promoCard(false)}
    <button class="icon-btn round map-fab" style="right:18px;bottom:350px">${I('locate')}</button>${homeFloat(false)}`,
  render:() => {
    const denied = P.sim==='denied', loading = P.sim==='loading';
    return `${homeMap(denied)}
      ${P.sim==='offline'?`<div style="position:absolute;top:0;left:0;right:0;z-index:7;padding-top:calc(46px + env(safe-area-inset-top,0px))">${offlineBar()}</div>`:''}
      <div class="map-top" style="${P.sim==='offline'?'top:92px':''}">
        <button class="icon-btn" data-act="drawer" aria-label="القائمة">${I('menu')}${P.chatUnread?'<span class="badge">'+P.chatUnread+'</span>':''}</button>
        <button class="status-pill" data-go="mappick" data-p='{"field":"pick"}' style="max-width:200px;animation:rise .5s var(--ease-out) both">
          ${loading?`<span class="sk" style="width:110px;height:14px"></span>`:denied?`${I('alert','sm')}<span class="small">الموقع غير محدد</span>`:`<span class="live"></span><span class="small" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">الزروق · قرب البيت</span>`}</button>
        <button class="icon-btn" data-go="notifications" aria-label="الإشعارات">${I('bell')}${P.notifUnread?'<span class="badge">'+P.notifUnread+'</span>':''}</button>
      </div>
      ${P.sim==='recovery'?`<div class="card" role="alert" style="position:absolute;top:112px;left:16px;right:16px;z-index:6;animation:rise .45s var(--ease-spring) both"><div class="flex"><span class="avatar">${pimg('driverAvatar',46)}</span><div class="grow"><div class="bold">سائق متاح الآن</div><div class="small muted">وجدنا سائقًا متاحًا لرحلتك السابقة. هل ما زلت تحتاج الرحلة؟</div></div></div>
        <div class="flex between small mt8"><span class="muted">الأجرة التقديرية</span><b class="num">12.50 د.ل</b></div><div class="row-btns mt12"><button class="btn primary sm" style="height:44px" data-act="recYesRide">نعم، أريد الرحلة</button><button class="btn outline sm" style="height:44px" data-act="recNoRide">لا، شكرًا</button></div></div>`
      : P.sim==='ongoing'?`<button class="booking-card" style="position:absolute;top:112px;left:16px;right:16px;z-index:6;width:auto;animation:rise .45s var(--ease-spring) both" data-go="found"><span class="live"></span><span class="grow"><span class="bold small" style="display:block">رحلتك جارية</span><span class="tiny" style="display:block;opacity:.8">عبدالسلام في الطريق · يوصل خلال 4 د</span></span>${I('chevL','sm')}</button>`
      : denied?`<div class="card" style="position:absolute;top:112px;left:16px;right:16px;z-index:6;animation:rise .45s var(--ease-spring) both"><div class="flex"><img src="${IMG.noLocation}" width="44" alt=""><div class="grow small"><b>ما قدرناش نحدد موقعك.</b> فعّل الموقع أو حدّد نقطة اللقاء على الخريطة.</div></div><div class="row-btns mt12"><button class="btn primary sm" style="height:42px" data-go="permission">فعّل الموقع</button><button class="btn outline sm" style="height:42px" data-go="mappick" data-p='{"field":"pick"}'>على الخريطة</button></div></div>`
      : promoCard(true)}
      <button class="icon-btn round map-fab" style="right:18px;bottom:${398}px" data-act="recenter" aria-label="موقعي">${I('locate')}</button>
      ${homeFloat(true)}`;
  },
  mount:(el) => { animateRings(el);
    if (!P.seenActionPush && P.view!=='before' && P.sim==='default'){ P.seenActionPush = true; later(() => ACTS.demoActionPush(), 5500); } }
});
ACTS.demoActionPush = () => pushNotif('مشوار الدوام غدوة 07:15', 'من البيت للشغل · سائق حجز الموعد. تبيه؟', {go:'recDetail', actions:[
  {t:'✅ تمام', ok:true, fn:() => toast('تمام، مشوار الغدوة محجوز', 'check')},
  {t:'⏭️ تخطي غدوة', fn:() => { REC_DAYS[0].st='skipped'; REC_DAYS[0].label='تم التخطي'; toast('تخطينا مشوار السبت. باقي الأيام كما هي.', 'skip'); }}]});
ACTS.drawer = () => openDrawer();
ACTS.recYesRide = () => { P.sim='default'; P.driver='b'; go('found'); toast('حجزنا لك السائق', 'check'); };
ACTS.recNoRide = () => { P.sim='default'; refresh(); };
ACTS.recenter = (b) => { const svg = $('.page:last-child svg.base'); if (svg){ const t = svg.style.transform; svg.style.transform = t + ' scale(1.08)'; setTimeout(() => svg.style.transform = t, 300); } toast('رجعنا الخريطة لموقعك', 'locate'); };
ACTS.pickDest = (b) => { const id = b.dataset.id; Object.assign(B(), {drop:id, noDest:false, pick:'me'}); go('options'); };
ACTS.noDest = () => { Object.assign(B(), {noDest:true, drop:null}); go('mappick', {field:'pick', nodest:true}); };

/* ---- search ---- */
screen('search', { title:'البحث عن وجهة', group:'home', states:['results','noresults','offline','loading'],
  render:(p) => {
    const f = p.field||'drop';
    const q = P.sim==='results' ? 'مست' : P.sim==='noresults' ? 'شارع الحرية ٩' : '';
    return `<div class="appbar" style="padding-bottom:6px"><button class="icon-btn" data-back aria-label="رجوع">${I('back')}</button><h2>خطّط لرحلتك</h2>
        <button class="chip" data-sheet="schedule">${I('clock','xs')} الآن ${I('chevD','xs')}</button></div>
      <div style="padding:0 16px 8px">
        <div class="route-fields">
          <div class="rf"><span class="dot"></span><input id="qPick" value="${f==='pick'?'':'موقعك الحالي · الزروق'}" placeholder="وين يقابلك السائق؟" ${f==='pick'?'autofocus':''}></div>
          <div class="rf"><span class="sq"></span><input id="qDrop" value="${q}" placeholder="إلى أين؟" ${f==='drop'?'autofocus':''}></div>
          <button class="swap" data-act="swap" aria-label="تبديل">${I('swap','sm')}</button>
        </div>
      </div>
      <div class="chips" style="padding-bottom:8px">
        <button class="chip" data-act="pickDest" data-id="home">${I('home','xs')} البيت</button>
        <button class="chip" data-act="pickDest" data-id="work">${I('work','xs')} الشغل</button>
        <button class="chip" data-go="mappick" data-p='{"field":"${f}"}'>${I('map','xs')} اختر من الخريطة</button>
        <button class="chip" data-go="favAddr">${I('plus','xs')} أضف مكان</button>
      </div>
      ${P.sim==='offline'?offlineBar():''}
      <div class="scroll" id="results">${searchBody(q)}</div>`;
  },
  mount:(el) => {
    const inp = $('#qDrop', el); if (!inp) return;
    if (P.params.field!=='pick') setTimeout(() => inp.focus({preventScroll:true}), 350);
    let tm; inp.addEventListener('input', () => { clearTimeout(tm); const v = inp.value.trim(); $('#results', el).innerHTML = v ? searchSkeleton() : searchBody(''); tm = setTimeout(() => { $('#results', el).innerHTML = searchBody(v); }, v ? 280 : 0); });
  }
});
function searchSkeleton(){ return `<div class="sec">${[1,2,3].map(()=>`<div class="flex" style="padding:12px 0"><div class="sk" style="width:38px;height:38px;border-radius:12px"></div><div class="grow"><div class="sk" style="height:13px;width:55%"></div><div class="sk mt8" style="height:10px;width:35%"></div></div></div>`).join('')}</div>`; }
function searchBody(q){
  if (P.sim==='loading') return searchSkeleton();
  const row = (pl, ic, hl) => `<button class="li" data-act="pickDest" data-id="${pl.id}"><span class="ic ${ic==='home'||ic==='work'?'brand':''}">${I(ic,'sm')}</span><span class="tx"><span class="t" style="display:block">${hl?hl(pl.name):pl.name}</span><span class="s" style="display:block">${pl.addr}</span></span><span class="end tiny">${['1.2','3.4','2.1','8.9','4.0'][pl.name.length%5]} كم</span></button>`;
  if (!q){
    return `${P.sim==='offline'?`<div class="sec"><div class="banner warn">${I('wifiOff','sm')}<span>البحث يحتاج إنترنت. تقدر تختار من أماكنك المحفوظة والأخيرة، أو <b>تحدد على الخريطة</b>.</span></div></div>`:''}
      <div class="sec-title">آخر الأماكن</div><div class="sec" style="margin-top:0"><div class="list">${RECENT.map(id => row(placeById(id),'history')).join('')}</div></div>
      <div class="sec-title">أماكنك المحفوظة <button class="link small" data-go="favAddr">تعديل</button></div><div class="sec" style="margin-top:0"><div class="list">${row(PLACES[0],'home')}${row(PLACES[1],'work')}</div></div>
      <div class="sec" style="margin:14px 16px 24px"><button class="li list" data-act="noDest"><span class="ic">${I('nav','sm')}</span><span class="tx"><span class="t" style="display:block">رحلة بدون وجهة</span><span class="s" style="display:block">السائق يجيك وتقوله وين ماشي</span></span>${I('chevL','sm')}</button></div>`;
  }
  const res = PLACES.filter(p => p.name.includes(q) || p.addr.includes(q));
  if (!res.length) return stateBlock({icon:'search', title:`ما لقيناش «${esc(q)}»`, text:'جرّب اسم أقصر أو اسم معلم قريب، أو حدّد المكان مباشرة على الخريطة.', cta:'حدّد على الخريطة', ctaGo:'mappick'});
  const hl = n => n.replace(q, `<mark>${esc(q)}</mark>`);
  return `<div class="sec-title">النتائج</div><div class="sec" style="margin-top:0"><div class="list">${res.map(p => row(p, p.kind||'pin', hl)).join('')}</div></div>
    <div class="sec small muted center" style="margin:14px 16px">ما لقيتش المكان؟ <button class="link small" data-go="mappick">حدّده على الخريطة</button></div>`;
}
ACTS.swap = (t) => { t.classList.toggle('spin'); const a = $('#qPick'), b = $('#qDrop'); if (a && b){ const v = a.value; a.value = b.value; b.value = v; } };

/* ---- map pick ---- */
screen('mappick', { title:'اختيار مكان من الخريطة', group:'home', states:['loading','error'],
  render:(p) => {
    const pick = p.field==='pick';
    const title = p.nodest ? 'وين يقابلك السائق؟' : pick ? 'حدّد نقطة اللقاء' : p.fav ? 'حدّد مكان «'+p.fav+'»' : 'حدّد الوجهة';
    const addr = P.sim==='loading' ? `<span class="sk" style="display:inline-block;width:160px;height:14px"></span>` : P.sim==='error' ? 'تعذّر تحديد هذا العنوان' : (p.addr || (pick ? 'الزروق — قرب جامع الزروق' : 'ميدان النصر — وسط المدينة'));
    return `${mapHTML({center:MAP_PTS.me, oy:110})}
      <div class="center-pin drop-in" id="cpin" style="top:calc(50% - 110px)"><div class="pin-bubble">${pick?'نقطة مقابلة السائق':'الوجهة'}</div><img src="${pick?IMG.pickMarker:IMG.dropMarker}" alt=""><div class="shadow"></div></div>
      <div class="map-top"><button class="icon-btn" data-back aria-label="رجوع">${I('back')}</button><div class="status-pill small">${title}</div><button class="icon-btn" data-act="recenter">${I('locate')}</button></div>
      <div class="dock">
        <div class="grab"></div>
        <div class="tiny muted">${pick?'نقطة اللقاء':'الوجهة'} · اسحب الخريطة لتحريك الدبوس</div>
        <div class="flex mt8" style="align-items:flex-start"><span class="ic" style="width:40px;height:40px;border-radius:12px;background:var(--brand-50);color:var(--brand);display:flex;align-items:center;justify-content:center">${I('pin','sm')}</span>
          <div class="grow"><div class="bold" id="paddr">${addr}</div><div class="tiny muted">${P.sim==='error'?'جرّب تحرّك الدبوس شوية أو ابحث بالاسم':'دقة الموقع ± 10 م'}</div></div>
          <button class="link small" data-go="search" data-replace="1" data-p='{"field":"${p.field||'drop'}"}'>بحث</button></div>
        ${p.nodest?`<div class="banner info mt12">${I('info','sm')}<span>رحلة بدون وجهة: تقول للسائق وين ماشي داخل السيارة. الأجرة تُحسب في النهاية حسب المسافة والوقت (التعرفة واضحة في الخطوة الجاية).</span></div>`:''}
        <button class="btn primary mt12 ${P.sim==='error'?'disabled':''}" data-act="confirmPin">${p.fav?'حفظ المكان':pick?'تأكيد نقطة اللقاء':'تأكيد الوجهة'}</button>
      </div>`;
  },
  mount:(el, p) => {
    const map = $('.map', el), svg = $('svg.base', el), pin = $('#cpin', el); if (!map) return; map.style.touchAction = 'none';
    let x0=null, y0=null, base = svg.style.transform;
    map.addEventListener('pointerdown', e => { x0=e.clientX; y0=e.clientY; pin.classList.add('lift'); svg.style.transition='none'; $('#paddr',el).innerHTML = '<span class="sk" style="display:inline-block;width:150px;height:14px"></span>'; });
    map.addEventListener('pointermove', e => { if (x0===null) return; svg.style.transform = base + ` translate(${(e.clientX-x0)/1}px, ${(e.clientY-y0)/1}px)`; });
    const up = () => { if (x0===null) return; x0=null; pin.classList.remove('lift'); pin.classList.remove('drop-in'); void pin.offsetWidth; pin.classList.add('drop-in'); svg.style.transition=''; if (navigator.vibrate) try{navigator.vibrate(12);}catch(_){} setTimeout(() => { const pl = PLACES[2+Math.floor(Math.random()*8)]; $('#paddr',el).innerHTML = `<span style="animation:rise .3s var(--ease-out) both;display:inline-block">${pl.addr} — ${pl.name}</span>`; }, 450); };
    map.addEventListener('pointerup', up); map.addEventListener('pointerleave', up);
  }
});
ACTS.confirmPin = () => {
  const p = P.params;
  if (p.fav){ back(); later(() => toast(`حفظنا «${p.fav}»`), 260); return; }
  if (p.nodest || p.field!=='pick'){ if (p.field!=='pick') Object.assign(B(), {drop:'square', noDest:false}); go('options'); }
  else { back(); later(() => toast('حدّثنا نقطة اللقاء'), 260); }
};

/* ---- favourite addresses ---- */
screen('favAddr', { title:'عناويني المفضلة', group:'home', states:['empty','loading'],
  render:() => `${appbar('عناويني المفضلة')}<div class="scroll">${simStates({empty:{icon:'pin', title:'ما عندكش عناوين محفوظة', text:'احفظ البيت والشغل وأي مكان تمشيله ديما، وتطلب له بضغطة وحدة.', cta:'أضف عنوان', ctaGo:'mappick'}}) || `
    <div class="sec"><div class="list">
      <div class="li"><span class="ic brand">${I('home','sm')}</span><span class="tx"><span class="t" style="display:block">البيت</span><span class="s" style="display:block">الزروق، قرب جامع الزروق</span></span><button class="icon-btn" style="box-shadow:none;width:36px;height:36px" data-go="mappick" data-p='{"fav":"البيت"}'>${I('edit','sm')}</button></div>
      <div class="li"><span class="ic brand">${I('work','sm')}</span><span class="tx"><span class="t" style="display:block">الشغل</span><span class="s" style="display:block">جامعة مصراتة — البوابة الرئيسية</span></span><button class="icon-btn" style="box-shadow:none;width:36px;height:36px" data-go="mappick" data-p='{"fav":"الشغل"}'>${I('edit','sm')}</button></div>
      <div class="li"><span class="ic">${I('heart','sm')}</span><span class="tx"><span class="t" style="display:block">بيت الوالدة</span><span class="s" style="display:block">الغيران</span></span><button class="icon-btn" style="box-shadow:none;width:36px;height:36px" data-act="delFav">${I('trash','sm')}</button></div>
    </div></div>
    <div class="sec"><button class="btn secondary" data-go="mappick" data-p='{"fav":"مكان جديد"}'>${I('plus','sm')} أضف عنوان جديد</button></div>
    <p class="sec tiny muted">نصيحة: الأماكن المحفوظة تظهر في الرئيسية وفي البحث، وتشتغل حتى لو الإنترنت ضعيف.</p>`}</div>`
});
ACTS.delFav = (b) => dialog({icon:'trash', tone:'red', title:'نحذف «بيت الوالدة»؟', text:'تقدر تضيفه من جديد في أي وقت.', ok:'حذف', cancel:'تراجع', danger:true, onOk:() => { b.closest('.li').remove(); toast('حُذف العنوان'); }});

/* ================= BOOKING ================= */
// Same structure as today's booking_confirmation: map with route on top, a sheet with service cards
// (fixed price = «اقتصادي», bidding service shows «السعر العادل» + «عرضك»), then payment / coupon / time / options.
screen('options', { title:'اختيار السيارة والسعر', group:'book', states:['loading','error','weak'],
  render:() => {
    const b = B(); const v = vehOf(b.veh); const offer = !!v.bid && !b.noDest;
    const fair = v.fare; const ratio = b.offer / fair; const pos = Math.max(4, Math.min(96, (ratio-0.7)/0.6*100));
    const hint = ratio < 0.85 ? ['warn','عرضك أقل بكثير من السعر العادل — البحث ممكن يطوّل.'] : ratio > 1.1 ? ['info','عرض مرتفع — غالبًا تلقى سائق أسرع.'] : ['success','عرض مناسب، قريب من السعر العادل.'];
    const to = placeById(b.drop||'square').pt;
    return `${mapHTML({center:[228,478], oy:270, zoom:.6, route: b.noDest?null:['me', to], pins: b.noDest?[['me','pick']]:[['me','pick'],[to,'drop']]})}
      <div class="map-top"><button class="icon-btn" data-back aria-label="رجوع">${I('back')}</button>
        <button class="status-pill grow" style="justify-content:flex-start;min-width:0" data-go="search">${I('route','sm')}<span class="small" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${b.noDest?'من موقعك · بدون وجهة':`إلى ${dropName()}`}</span><span class="tiny muted" style="margin-inline-start:auto">${b.noDest?'':'<span class="num">4.2</span> كم · <span class="num">11</span> د'}</span></button></div>
      <div class="dock" style="max-height:72%"><div class="grab"></div>
        <div class="flex between" style="margin-bottom:8px"><b style="font-size:16px">اختر السيارة والسعر الأنسب لرحلتك</b>${b.noDest?'':`<button class="link small" data-sheet="fareInfo">التعرفة</button>`}</div>
        <div class="scroll" style="padding-bottom:4px">
        ${P.sim==='weak'?`<div class="banner warn" style="margin-bottom:10px">${I('wifiOff','sm')}<span>الإنترنت ضعيف — الأسعار من آخر تحديث، نأكدها قبل الطلب.</span></div>`:''}
        ${P.sim==='error'?`<div class="banner danger" style="margin-bottom:10px">${I('alert','sm')}<div class="grow">تعذر تأكيد سعر الرحلة الآن. حاول مرة أخرى.</div><button class="link small" data-act="retry">إعادة</button></div>`:''}
        ${b.noDest ? `<div class="banner info" style="margin-bottom:10px">${I('info','sm')}<div class="grow">بدون وجهة: تقولها للسائق، والأجرة حسب العداد. <b>فتح 3.00 · الكيلو 1.20 · الدقيقة 0.20 د.ل</b> <span class="tiny">(عيّنة)</span></div></div>`:''}
        <button class="card flex" style="width:100%;text-align:start;padding:10px 12px;background:var(--success-bg);box-shadow:none;margin-bottom:10px" data-act="favFirst">
          <span class="avatar" style="width:38px;height:38px">${pimg('driverAvatar',38)}</span><span class="grow"><span class="small bold" style="display:block">سائقك المفضل متاح الآن · عبدالسلام</span><span class="tiny muted" style="display:block">نعرض طلبك عليه أولًا، وإن لم يقبل نكمل البحث كالمعتاد.</span></span>
          <span class="toggle ${b.fav?'on':''}"></span></button>
        <div id="vehs" class="${P.sim==='loading'?'':'stagger'}">${P.sim==='loading' ? [1,2,3].map(()=>`<div class="veh" style="margin-top:9px"><div class="sk" style="width:74px;height:46px"></div><div class="grow"><div class="sk" style="height:14px;width:40%"></div><div class="sk mt8" style="height:10px;width:60%"></div></div><div class="sk" style="width:60px;height:20px"></div></div>`).join('') :
          VEHICLES.map(x => { const on = x.id===b.veh; return `<div><button class="veh ${on?'on':''}" data-act="veh" data-v="${x.id}"><img class="car" src="${IMG[x.img]}" alt="">
            <span class="grow"><span class="flex" style="gap:6px"><span class="xbold" style="font-size:15.5px">${x.name}</span>${x.popular?'<span class="badge-pop">الأكثر طلبًا</span>':''}${x.bid?'<span class="tag brand">فاوض</span>':''}</span>
              <span class="tiny muted flex" style="gap:8px;margin-top:4px">${I('users','xs')} ${x.seats} · ${I('clock','xs')} الأقرب <span class="num">${x.eta}</span> د</span></span>
            <span class="p">${b.noDest?'<small>بالعداد</small>':x.bid?`<small>السعر العادل</small>${on?cnt(x.fare,2,x.fare*.8):x.fare.toFixed(2)}`:`${on?cnt(x.fare - couponValue(),2,(x.fare-couponValue())*.8):(x.fare).toFixed(2)}<small>${on&&b.coupon?`<s>${x.fare.toFixed(2)}</s> بعد الكوبون`:'دينار'}</small>`}</span></button>
            ${on && offer ? `<div class="bid-box"><div class="flex between"><span class="bold small">عرضك</span><span class="tiny muted">عدّل السعر لإرسال عرض للسائق</span></div>
              <div class="stepper mt8"><button data-act="offerStep" data-v="-0.5" aria-label="أقل">${I('minus')}</button><div class="val" id="offerVal"><span class="num">${b.offer.toFixed(2)}</span> <small>دينار</small></div><button data-act="offerStep" data-v="0.5" aria-label="أكثر">${I('plus')}</button></div>
              <div class="fairbar"><span class="kn" id="fairKn" style="left:${pos}%"></span></div>
              <div class="flex between tiny muted"><span>أقل</span><span>السعر العادل ${fair.toFixed(2)}</span><span>أعلى</span></div>
              <div class="banner ${hint[0]} mt8" style="padding:8px 10px" id="fairHint">${I(hint[0]==='success'?'check':'info','xs')}<span class="small">${hint[1]}</span></div></div>`:''}</div>`; }).join('')}
        </div>
        <div class="opts">
          <button class="opt" data-sheet="payment">${pimg(b.pay==='wallet'?'walletImg':'cash',26,26)}<span class="grow"><span class="k">الدفع</span>${({cash:'نقدًا',wallet:'المحفظة',mix:'المحفظة + نقدًا'})[b.pay]}</span>${I('chevD','xs')}</button>
          <button class="opt" data-sheet="coupon" style="${b.coupon?'background:var(--success-bg);color:var(--success)':''}">${pimg('promo',26,26)}<span class="grow"><span class="k">كوبونات الخصم</span>${b.coupon?'مصراتة5 · −5.00':'أضف'}</span>${I('chevD','xs')}</button>
          <button class="opt" data-sheet="schedule">${pimg('rideLater',26,26)}<span class="grow"><span class="k">الوقت</span>${b.when==='now'?'الآن':b.when}</span>${I('chevD','xs')}</button>
          <button class="opt" data-sheet="more">${pimg('luggage',26,26)}<span class="grow"><span class="k">التفضيلات</span>${b.forOther?'لشخص آخر':b.prefs.length?b.prefs.join('، '):'أمتعة، لشخص آخر…'}</span>${I('chevD','xs')}</button>
        </div>
        </div>
        <button class="btn primary mt12 ${P.sim==='error'||P.sim==='loading'?'disabled':''}" data-act="request">${b.when!=='now'?`${I('cal','sm')} جدولة الرحلة`:offer?`أرسل عرضك · <span class="num" id="ctaPrice">${(b.offer-couponValue()).toFixed(2)}</span> دينار`:b.noDest?`اطلب ${v.name} بالعداد`:`اطلب ${v.name} · <span class="num">${finalFare().toFixed(2)}</span> دينار`}</button>
      </div>`;
  }
});
ACTS.veh = (t) => { const v = vehOf(t.dataset.v); B().veh = v.id; B().mode = v.bid ? 'offer' : 'fixed'; B().offer = v.fare; refresh(); };
ACTS.offerStep = (t) => { // update in place so the number and knob animate instead of re-rendering
  const b = B(); b.offer = Math.max(3, +(b.offer + (+t.dataset.v)).toFixed(2));
  const v = vehOf(b.veh), fair = v.fare, ratio = b.offer/fair, pos = Math.max(4, Math.min(96, (ratio-0.7)/0.6*100));
  const val = $('#offerVal'); if (val){ val.innerHTML = `<span class="num">${b.offer.toFixed(2)}</span> <small>دينار</small>`; val.classList.remove('bump'); void val.offsetWidth; val.classList.add('bump'); }
  const kn = $('#fairKn'); if (kn) kn.style.left = pos + '%';
  const cta = $('#ctaPrice'); if (cta) cta.textContent = (b.offer - couponValue()).toFixed(2);
  const h = $('#fairHint'); if (h){ const k = ratio < 0.85 ? ['warn','عرضك أقل بكثير من السعر العادل — البحث ممكن يطوّل.'] : ratio > 1.1 ? ['info','عرض مرتفع — غالبًا تلقى سائق أسرع.'] : ['success','عرض مناسب، قريب من السعر العادل.']; h.className = 'banner '+k[0]+' mt8'; h.innerHTML = `${I(k[0]==='success'?'check':'info','xs')}<span class="small">${k[1]}</span>`; }
  if (navigator.vibrate) try{ navigator.vibrate(6); }catch(_){}
};
ACTS.offerSet = (t) => { B().offer = +(+t.dataset.v).toFixed(2); refresh(); };
ACTS.favFirst = (t) => { B().fav = !B().fav; t.querySelector('.toggle').classList.toggle('on', B().fav); if (B().fav) toast('نعرض طلبك على عبدالسلام أولًا', 'heart'); };
ACTS.request = async (btn) => {
  if (B().when !== 'now'){ btn.innerHTML = '<span class="spinner"></span>'; await wait(700);
    openSheet(`<div class="center"><div class="state" style="padding:4px 0">${checkAnim()}<h3>تمت جدولة رحلتك</h3><p>${B().when} · إلى ${dropName()}. نعرضها على السائقين ونخبرك أول ما يحجزها سائق.</p></div>
      <button class="btn primary" data-act="toUpcoming">عرض الرحلات القادمة</button></div>`);
    return; }
  btn.innerHTML = '<span class="spinner"></span> نرسل طلبك…'; await wait(600); go('searching');
};
ACTS.toUpcoming = () => { B().when='now'; closeSheet(true); go('upcoming'); };
SHEETS.fareInfo = () => openSheet(`<h3>كيف نحسب السعر العادل؟</h3><p class="sheet-sub">حسب المسافة والوقت المتوقع ونوع السيارة. عرضك يوصل لأقرب السائقين، وكل سائق يقدر يقبل أو يعرض سعر آخر — وأنت تختار.</p>
  <div class="list"><div class="li"><span class="tx"><span class="t">فتح العداد</span></span><span class="end num">3.00</span></div><div class="li"><span class="tx"><span class="t">سعر الكيلو</span></span><span class="end num">1.20</span></div><div class="li"><span class="tx"><span class="t">سعر الدقيقة</span></span><span class="end num">0.20</span></div></div><p class="tiny muted mt8">أرقام عيّنة. التعرفة الحقيقية تجي من الخادم لكل سوق ونوع سيارة.</p>
  <button class="btn primary mt12" onclick="closeSheet()">فهمت</button>`);
SHEETS.payment = () => { const cur = B().pay; const row = (k, ic, t, s, dis) => `<button class="li" ${dis?'style="opacity:.5" disabled':`data-act="setPay" data-v="${k}"`}><span class="ic ${k===cur?'brand':''}">${I(ic,'sm')}</span><span class="tx"><span class="t" style="display:block">${t}</span><span class="s" style="display:block">${s}</span></span><span class="radio ${k===cur?'on':''}"></span></button>`;
  openSheet(`<h3>طريقة الدفع</h3><p class="sheet-sub">تقدر تغيّرها قبل ما يقبل السائق.</p><div class="list">
    ${row('cash','cash','نقدًا','تدفع للسائق في النهاية')}
    ${row('wallet','wallet','المحفظة','الرصيد '+(P.wallet.own+P.wallet.credit).toFixed(2)+' د.ل · منها 15.00 رصيد مشاوير')}
    ${row('mix','layers','المحفظة + نقدًا','نخصم من المحفظة والباقي نقدًا')}
    ${row('card','card','البطاقة المصرفية','غير متاحة للرحلات حاليًا — اشحن المحفظة بالبطاقة', true)}</div>
    <button class="btn secondary mt12" data-go="topup">${I('plus','sm')} اشحن المحفظة</button>`); };
ACTS.setPay = (t) => { B().pay = t.dataset.v; closeSheet(); refresh(); };
SHEETS.coupon = (p) => openSheet(`<h3>كوبون أو هدية</h3><p class="sheet-sub">الكوبون يُطبّق على هذه الرحلة فقط. الهدية الترحيبية تُخصم تلقائيًا من المحفظة.</p>
  <div class="flex"><div class="input grow" id="cpIn">${I('tag','sm')}<input id="cpv" placeholder="اكتب رمز الخصم" value="${p.bad?'XYZ':''}"></div><button class="btn primary sm" style="height:54px" data-act="applyCoupon">تطبيق</button></div>
  <div id="cpMsg">${p.bad?`<div class="help err">${I('x','xs')} الرمز غير صحيح أو انتهت صلاحيته.</div>`:''}</div>
  <div class="sec-title" style="margin:16px 0 8px">كوبوناتك</div><div class="list">${COUPONS.map(c => `<button class="li" ${c.ok?`data-act="applyCoupon" data-code="${c.code}"`:'disabled style="opacity:.5"'}><span class="ic ${c.ok?'gold':''}">${I('tag','sm')}</span><span class="tx"><span class="t" style="display:block">${c.code} · ${c.v}</span><span class="s" style="display:block">${c.s}</span></span>${c.ok?'<span class="link small">استعمل</span>':''}</button>`).join('')}</div>
  ${B().coupon?`<button class="btn danger mt12" data-act="rmCoupon">إزالة الكوبون</button>`:''}`);
ACTS.applyCoupon = async (t) => { const code = t.dataset.code || ($('#cpv')||{}).value || ''; if (!code || code.toUpperCase()==='XYZ'){ $('#cpMsg').innerHTML = `<div class="help err">${I('x','xs')} الرمز غير صحيح أو انتهت صلاحيته.</div>`; $('#cpIn').classList.add('error'); return; }
  t.innerHTML = '<span class="spinner" style="border-top-color:var(--brand)"></span>'; await wait(500); B().coupon = code; closeSheet(); refresh(); toast('تم الخصم، وفّرت 5.00 دينار في هذه الرحلة', 'tag'); };
ACTS.rmCoupon = () => { B().coupon = null; closeSheet(); refresh(); };
SHEETS.schedule = () => openSheet(`<h3>متى تبي الرحلة؟</h3><p class="sheet-sub">الرحلة المجدولة تنعرض على السائقين مسبقًا، ونخبرك أول ما يحجزها سائق.</p>
  <div class="chips" style="margin:0 -16px;padding:0 16px 4px"><button class="chip on" data-act="setWhen" data-v="now">الآن</button><button class="chip" data-act="setWhen" data-v="بعد ساعة">بعد ساعة</button><button class="chip" data-act="setWhen" data-v="بعد ساعتين">بعد ساعتين</button><button class="chip" data-act="setWhen" data-v="غدًا 07:30">غدًا صباحًا</button></div>
  <div class="field-label mt16">اليوم</div><div class="week pick">${['اليوم','غدًا','الأحد','الإثنين','الثلاثاء','الأربعاء','الخميس'].map((d,i)=>`<button class="d ${i===1?'on':''}" data-act="pickDay">${d}<span class="tiny">${7+i}</span></button>`).join('')}</div>
  <div class="field-label mt16">وقت الانطلاق</div><div class="chips" style="margin:0 -16px;padding:0 16px">${['06:30','07:00','07:15','07:30','08:00','08:30','09:00'].map((t,i)=>`<button class="chip ${i===3?'on':''}" data-act="pickTime"><span class="num">${t}</span></button>`).join('')}</div>
  <div class="banner info mt12">${I('info','sm')}<span>السعر التقديري ${fareOf(B().veh).toFixed(2)} د.ل، وقد يُضاف رسم الحجز المسبق إن وُجد. <button class="link small" data-go="recurring">تبي نفس المشوار كل يوم؟ مشوار الدوام</button></span></div>
  <button class="btn primary mt12" data-act="setWhen" data-v="غدًا 07:30">تأكيد الموعد · غدًا <span class="num">07:30</span></button>`);
ACTS.setWhen = (t) => { B().when = t.dataset.v; closeSheet(); if (P.screen==='options') refresh(); else if (B().when!=='now'){ toast('الموعد: '+B().when+' — اختر وجهتك', 'cal'); } };
ACTS.pickDay = (t) => { $$('.week.pick .d').forEach(d => d.classList.remove('on')); t.classList.add('on'); };
ACTS.pickTime = (t) => { t.parentElement.querySelectorAll('.chip').forEach(c => c.classList.remove('on')); t.classList.add('on'); };
SHEETS.more = () => openSheet(`<h3>خيارات الرحلة</h3><div class="list mt8">
    <button class="li" data-act="pref" data-v="أمتعة"><span class="ic">${I('luggage','sm')}</span><span class="tx"><span class="t">عندي أمتعة</span></span><span class="toggle ${B().prefs.includes('أمتعة')?'on':''}"></span></button>
    <button class="li" data-act="pref" data-v="حيوان أليف"><span class="ic">${I('paw','sm')}</span><span class="tx"><span class="t">معاي حيوان أليف</span></span><span class="toggle ${B().prefs.includes('حيوان أليف')?'on':''}"></span></button></div>
  <div class="sec-title" style="margin:16px 0 8px">الرحلة لشخص آخر؟</div>
  <div class="input">${I('user','sm')}<input placeholder="اسم الراكب" value="${B().forOther||''}" id="foN"></div>
  <div class="input mt8"><span class="num bold">+218</span><input placeholder="رقم هاتفه" dir="ltr"><button class="link small">من جهات الاتصال</button></div>
  <div class="input mt8">${I('msg','sm')}<input placeholder="ملاحظة للسائق (اختياري)"></div>
  <button class="btn primary mt12" data-act="saveMore">تم</button>`);
ACTS.pref = (t) => { const v = t.dataset.v, a = B().prefs; const i = a.indexOf(v); i>=0 ? a.splice(i,1) : a.push(v); t.querySelector('.toggle').classList.toggle('on'); };
ACTS.saveMore = () => { const n = ($('#foN')||{}).value; B().forOther = n || null; closeSheet(); refresh(); };

/* ---- searching (today: «قريبًا سيتم قبول طلبك», offers rail, drivers viewing) ---- */
screen('searching', { title:'البحث عن سائق', group:'book', states:['weak','nodriver'],
  render:() => {
    const offer = B().mode==='offer' && !B().noDest;
    if (P.sim==='nodriver') return `${mapHTML({center:MAP_PTS.me, oy:150})}<span class="loc-dot" style="left:50%;top:calc(50% - 150px)"></span>
      <div class="dock"><div class="grab"></div><div class="state" style="padding:4px 10px 12px"><img src="${IMG.driverMascot}" alt="" width="92" style="animation:popIn .5s var(--ease-spring) both"><h3>ما لقيناش سائق متاح الآن</h3><p>السائقون القريبون مشغولين. ما عليك أي رسوم. اختار وش نديروا:</p></div>
        <div class="col" style="gap:8px"><button class="btn primary" data-act="retrySearch">${I('refresh','sm')} حاول مرة ثانية</button>
        <div class="row-btns">${offer?`<button class="btn outline sm" style="height:46px" data-act="raise">ارفع عرضك +1</button>`:''}<button class="btn outline sm" style="height:46px" data-act="toSchedule">جدولها لوقت لاحق</button></div>
        <button class="btn ghost" data-act="cancelSearch">رجوع للرئيسية</button></div></div>`;
    return `${mapHTML({center:MAP_PTS.me, oy:200, radar:true})}
      <div class="map-top"><span></span><div class="status-pill"><span class="live"></span><span class="small">نوسّع نطاق البحث عن سائق</span></div><button class="icon-btn round" data-sheet="tripSos" aria-label="طوارئ" style="color:var(--danger)">${I('shield')}</button></div>
      <div class="dock" style="max-height:70%"><div class="grab"></div>
        ${P.sim==='weak'?`<div class="banner warn" style="margin-bottom:10px">${I('wifiOff','sm')}<span><b>الإنترنت ضعيف…</b> نعيد إرسال طلبك (المحاولة 2 من 3). طلبك لن يتكرر ولن يضيع.</span></div>`:''}
        <div class="flex between" style="align-items:flex-start"><div><div class="xbold" style="font-size:22px;color:var(--navy);line-height:1.3" id="srchTitle">قريبًا سيتم قبول طلبك</div>
          <div class="small muted" id="srchSub">جارٍ التواصل مع السائقين القريبين · وقت البحث <span class="num" id="elapsed">0:00</span></div></div>
          <div class="center" style="flex:0 0 auto"><div class="xbold num" style="font-size:18px">${offer?(B().offer-couponValue()).toFixed(2):finalFare().toFixed(2)}</div><div class="tiny muted">${offer?'عرضك':'دينار'}</div></div></div>
        <div class="steps"><span class="done"></span><span class="now" id="st2"></span><span id="st3"></span></div>
        <div class="flex tiny muted between"><span>أرسلنا الطلب</span><span>السائقون يشاهدونه</span><span>قبول</span></div>
        <div id="offersWrap" hidden><div class="bold small mt12" id="offersCount"></div><div class="offer-rail" id="offers"></div></div>
        <div class="flex mt12" id="viewersRow" style="min-height:40px"><div class="viewers" id="viewers"></div><span class="small muted" id="viewersTxt">طلبك ظاهر الآن لأقرب <span class="num">6</span> سائقين</span></div>
        <div class="card mt12" style="box-shadow:none;background:var(--surface-2);padding:10px 12px">
          <div class="flex small"><span class="dot" style="width:10px;height:10px;border-radius:50%;border:3px solid var(--success)"></span><span class="grow">${pickName()}</span></div>
          <div class="flex small mt8"><span style="width:10px;height:10px;border-radius:3px;background:var(--danger)"></span><span class="grow">${dropName()}</span><span class="tiny muted">${({cash:'نقدًا',wallet:'المحفظة',mix:'محفظة + نقدًا'})[B().pay]}</span></div></div>
        <div class="row-btns mt12">${offer?`<button class="btn secondary sm" style="height:48px" data-act="raise">${I('plus','sm')} ارفع العرض</button>`:`<button class="btn secondary sm" style="height:48px" data-go="supportChat">${I('headset','sm')} الدعم</button>`}<button class="btn outline sm" style="height:48px" data-act="cancelSearch">إلغاء الطلب</button></div>
      </div>`;
  },
  mount:(el) => {
    if (P.sim==='nodriver') return;
    const t0 = Date.now(); const tick = () => { const s = Math.floor((Date.now()-t0)/1000); const e = $('#elapsed', el); if (!e) return; e.textContent = `${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}`; later(tick, 1000); }; tick();
    const offer = B().mode==='offer' && !B().noDest;
    const viewers = $('#viewers', el);
    ['ع','س','م','خ'].forEach((n,i) => later(() => { if (!viewers.isConnected) return; viewers.insertAdjacentHTML('beforeend', `<span class="avatar" style="background:${['#EAF4FF','#E7F6F0','#FFF4DB','#F2F5FA'][i]}">${i===0?pimg('driverAvatar',34):n}</span>`); $('#viewersTxt', el).innerHTML = `<span class="num">${i+1}</span> ${i?'سائقين يشاهدون':'سائق واحد يشاهد'} الطلب الآن`; }, 900 + i*700));
    if (offer){
      OFFERS.forEach((o, i) => later(() => { const d = DRIVERS[o.d]; const box = $('#offers', el); if (!box) return; $('#offersWrap', el).hidden = false;
        box.insertAdjacentHTML('afterbegin', `<div class="offer" id="of${i}"><div class="flex"><span class="avatar">${pimg('driverAvatar',46)}</span><div class="grow"><div class="bold small">${d.name} · ${I('star','xs')} <span class="num">${d.rating}</span></div><div class="tiny muted">${d.car} · يوصلك خلال <span class="num">${o.eta}</span> د</div></div></div>
          <div class="flex between"><div><div class="small ink2">أقدر أوصلك بـ</div><div class="xbold" style="font-size:22px">${cnt(o.price,2,B().offer)} <span class="small">دينار</span></div><div class="tiny muted">عرضك ${B().offer.toFixed(2)}</div></div>
          <div class="col" style="gap:4px"><button class="btn primary sm" style="height:40px;padding:0 18px" data-act="acceptOffer" data-d="${o.d}">قبول عرض</button><button class="btn ghost sm" style="height:30px;font-size:12px" data-act="declineOffer" data-i="${i}">رفض</button></div></div><i class="timer"></i></div>`);
        countUps(box.firstElementChild); box.scrollTo({left:0, behavior:'smooth'});
        $('#offersCount', el).textContent = i ? `${i+1} عروض تم استلامها` : 'عرض واحد تم استلامه';
        $('#srchTitle', el).textContent = 'وصلتك عروض من السائقين'; $('#st2', el).className = 'done'; $('#st3', el).className='now';
        if (navigator.vibrate) try{ navigator.vibrate([20,40,20]);}catch(e){}
      }, 2600 + i*2800));
    } else {
      later(() => { const st = $('#st2', el); if (st) st.className='done'; const s3 = $('#st3', el); if (s3) s3.className='now'; }, 2400);
      later(() => { if (P.screen==='searching' && P.sim!=='weak') { P.driver='a'; go('found', {}, {replace:true}); toast('لقينالك سواق! عبدالسلام قبل طلبك', 'check'); } }, 5200);
    }
  }
});
ACTS.acceptOffer = (t) => { P.driver = t.dataset.d; go('found', {}, {replace:true}); toast('قبلت عرض '+DRIVERS[P.driver].name, 'check'); };
ACTS.declineOffer = (t) => { const o = document.getElementById('of'+t.dataset.i); if (o){ o.style.transition='all .2s'; o.style.opacity='0'; o.style.transform='translateX(-30px)'; setTimeout(() => o.remove(), 200); } };
ACTS.raise = () => { B().offer = +(B().offer + 1).toFixed(2); P.sim='default'; go('searching', {}, {replace:true}); toast('رفعنا عرضك إلى '+B().offer.toFixed(2)+' د.ل', 'plus'); };
ACTS.retrySearch = () => { P.sim='default'; go('searching', {}, {replace:true}); };
ACTS.toSchedule = () => { P.sim='default'; go('options', {}, {replace:true}); later(() => SHEETS.schedule(), 300); };
ACTS.cancelSearch = () => dialog({icon:'x', tone:'red', title:'نلغي الطلب؟', text:'ما في أي رسوم لأن ما فيش سائق قبل طلبك بعد.', ok:'إلغاء الطلب', cancel:'كمّل البحث', danger:true, onOk:() => { P.sim='default'; go('home', {}, {root:true, fade:true}); later(() => toast('ألغينا الطلب'), 300); }});
