/* Screens: start/auth, home & search, booking. SAMPLE DATA. */
'use strict';
const B = () => P.booking;
const isB = () => P.concept === 'b';
const greet = () => { const h = new Date().getHours(); return h < 12 ? 'صباح الخير' : 'مساء الخير'; };
const fareOf = id => (VEHICLES.find(v => v.id===id)||VEHICLES[0]).fare;
const dropName = () => B().noDest ? 'بدون وجهة — تقولها للسائق' : placeById(B().drop||'square').name;
const pickName = () => B().pick==='me' ? 'موقعك الحالي · الزروق' : placeById(B().pick).name;
function couponValue(){ return B().coupon ? 5 : 0; }
function finalFare(){ const base = B().mode==='offer' ? B().offer : fareOf(B().veh); return Math.max(0, base - couponValue()); }

/* ================= START ================= */
screen('splash', { title:'شاشة البداية', group:'start', statusLight:() => isB(),
  render:() => `<div class="splash">
    <div class="logo" style="animation:pop .5s var(--ease-spring)"><img src="${LOGO}" alt="Taxista"></div>
    <div class="wordmark" style="color:${isB()?'#fff':'var(--ink)'}">Taxista <span style="color:${isB()?'#9CD8FF':'var(--brand)'}">تاكسيستا</span></div>
    <div class="small" style="color:${isB()?'rgba(255,255,255,.75)':'var(--ink-3)'}">مشوارك في مصراتة، بضغطة</div>
    <div style="position:absolute;bottom:60px;display:flex;flex-direction:column;align-items:center;gap:10px">
      ${P.sim==='weak' ? `<div class="banner warn" style="max-width:300px">${I('wifiOff','sm')}<span>الاتصال بطيء… أبقِ التطبيق مفتوحًا، ما زلنا نحاول.</span></div>` : `<div class="tiny" style="color:${isB()?'rgba(255,255,255,.6)':'var(--ink-3)'}">نجهّز الخريطة…</div>`}
    </div></div>`,
  states:['weak'],
  mount:() => later(() => { if (P.screen==='splash' && P.sim==='default') go('onboarding', {}, {replace:true, fade:true}); }, 1800)
});

screen('onboarding', { title:'التعريف (3 شرائح)', group:'start',
  render:(p) => { const i = p.i||0; const slides = [
    ['car','وصول سلس وسهل','اطلب سيارة في ثواني، وشوف سائقك على الخريطة لين يوصلك.'],
    ['tag','أسعار واضحة، أو فاوض','سعر ثابت معروف قبل الطلب، أو اعرض سعرك وخلّي السائقين يردّوا.'],
    ['shield','سلامتك أولًا','زر طوارئ، مشاركة الرحلة، ودعم يرد عليك من التطبيق.']];
    const s = slides[i];
    return `<div class="scroll col" style="padding:90px 24px 24px;align-items:center;text-align:center">
      <div style="width:220px;height:220px;border-radius:60px;background:${isB()?'var(--hero)':'var(--brand-50)'};color:${isB()?'#fff':'var(--brand)'};display:flex;align-items:center;justify-content:center;margin:20px 0 28px">${I(s[0],'xl')}</div>
      <h2 style="font-size:26px;margin:0 0 10px">${s[1]}</h2><p class="ink2" style="font-size:16px;line-height:1.8;margin:0 0 24px">${s[2]}</p>
      <div class="progress-dots">${[0,1,2].map(k => `<i class="${k===i?'on':''}"></i>`).join('')}</div></div>
      <div class="sticky-cta col" style="gap:6px;border:0">
        <button class="btn primary" ${i<2?`data-go="onboarding" data-replace="1" data-p='{"i":${i+1}}'`:'data-go="login" data-replace="1"'}>${i<2?'التالي':'يلا نبدأ'}</button>
        <button class="btn ghost" data-go="login" data-replace="1">تخطي</button></div>`; }
});

screen('login', { title:'تسجيل الدخول', group:'start', states:['error','offline'],
  render:(p) => { const tab = p.tab||'phone'; return `
    ${appbar('', {noBack:true, right:`<button class="chip" data-go="language">${I('globe','sm')} العربية</button>`})}
    <div class="scroll" style="padding:0 20px 20px">
      <div class="logo" style="width:64px;height:64px;border-radius:20px;margin-bottom:16px"><img src="${LOGO}" alt=""></div>
      <h2 style="font-size:26px;margin:0">أهلًا بيك في تاكسيستا</h2>
      <p class="ink2" style="margin:6px 0 20px">دخّل رقمك وكلمة المرور، أو أنشئ حساب جديد.</p>
      <div class="tabs" style="margin:0 0 16px"><button class="${tab==='phone'?'on':''}" data-go="login" data-replace="1" data-p='{"tab":"phone"}'>رقم الهاتف</button><button class="${tab==='email'?'on':''}" data-go="login" data-replace="1" data-p='{"tab":"email"}'>البريد</button></div>
      ${tab==='phone' ? `<div class="field-label">رقم الهاتف</div>
        <div class="input"><span class="num bold">🇱🇾 +218</span><span style="width:1px;height:24px;background:var(--line)"></span><input inputmode="tel" placeholder="91 234 5678" value="91 000 0000" dir="ltr"></div>`
      : `<div class="field-label">البريد الإلكتروني</div><div class="input">${I('msg','sm')}<input placeholder="name@example.ly" dir="ltr"></div>`}
      <div class="field-label mt12">كلمة المرور</div>
      <div class="input ${P.sim==='error'?'error':''}">${I('lock','sm')}<input type="password" value="••••••••"><button class="link small">إظهار</button></div>
      ${P.sim==='error'?`<div class="help err">بيانات الدخول غير صحيحة. راجع الرقم وكلمة المرور.</div>`:''}
      ${P.sim==='offline'?`<div class="banner danger mt12">${I('wifiOff','sm')}<span>تعذر الاتصال بالخادم. تحقق من الإنترنت ثم أعد المحاولة.</span></div>`:''}
      <div class="flex between mt12"><span></span><button class="link" data-go="forgot">نسيت كلمة المرور؟</button></div>
      <button class="btn primary mt16" data-act="doLogin">تسجيل الدخول</button>
      <div class="hr" style="margin:20px 0"></div>
      <button class="btn outline" data-go="signup">إنشاء حساب جديد</button>
      <p class="tiny muted center mt16">بالمتابعة توافق على <span class="link tiny">شروط الاستخدام</span> و<span class="link tiny">سياسة الخصوصية</span></p>
    </div>`; }
});
ACTS.doLogin = async (b) => { b.innerHTML = '<span class="spinner"></span>'; await wait(700); go('permission', {}, {root:true, fade:true}); };

screen('forgot', { title:'استعادة الحساب + رمز واتساب', group:'start', states:['error'],
  render:(p) => { const st = p.st||0; return `${appbar('استعادة حسابك')}
    <div class="scroll" style="padding:0 20px 20px">
      <div class="progress-dots" style="justify-content:flex-start;margin:4px 0 18px">${[0,1,2].map(k=>`<i class="${k===st?'on':''}"></i>`).join('')}</div>
      ${st===0?`<h3 style="margin:0 0 6px">رقم الهاتف المرتبط بحسابك</h3><p class="ink2 small">نرسلولك رمز من 6 أرقام على <b>واتساب</b>.</p>
        <div class="input mt12"><span class="num bold">+218</span><input value="91 000 0000" dir="ltr"></div>
        <button class="btn primary mt24" data-go="forgot" data-replace="1" data-p='{"st":1}'>أرسل الرمز على واتساب</button>`
      : st===1? otpBlock('forgot', {st:2}) :
      `<h3 style="margin:0 0 6px">كلمة مرور جديدة</h3><p class="ink2 small">8 أحرف على الأقل.</p>
        <div class="input mt12">${I('lock','sm')}<input type="password" value="••••••••••"></div>
        <div class="help">${I('check','xs')} قوية بما يكفي</div>
        <button class="btn primary mt24" data-act="pwDone">حفظ والدخول</button>`}
    </div>`; }
});
ACTS.pwDone = () => { go('login', {}, {root:true}); later(() => toast('تم تحديث كلمة المرور. سجّل الدخول الآن.'), 350); };
function otpBlock(next, p){
  return `<h3 style="margin:0 0 6px">دخّل رمز التحقق</h3><p class="ink2 small">أرسلنا رمز من 6 أرقام إلى <span class="num">+218 91 000 0000</span> عبر واتساب.</p>
    <div class="otp mt16">${'4 8 1 '.split(' ').map((d,k)=>`<span class="${k===3?'f':''}">${d}</span>`).join('')}<span></span><span></span></div>
    ${P.sim==='error'?`<div class="help err center">الرمز غير صحيح، باقيلك محاولتين.</div>`:''}
    <div class="center mt16 small muted">إعادة الإرسال خلال <span class="num">0:42</span></div>
    <button class="btn secondary mt16">${I('msg','sm')} افتح واتساب</button>
    <button class="btn primary mt12" data-go="${next}" data-replace="1" data-p='${JSON.stringify(p)}'>تحقق</button>`;
}

screen('signup', { title:'إنشاء حساب (مقترح: 4 خطوات)', group:'start', states:['error'],
  render:(p) => { const st = p.st||0; const titles = ['رقم هاتفك','رمز واتساب','أهلًا! ما اسمك؟','أمّن حسابك']; return `${appbar('إنشاء حساب', {sub:`الخطوة ${st+1} من 4`})}
    <div class="scroll" style="padding:0 20px 20px">
      <div class="steps">${[0,1,2,3].map(k=>`<span class="${k<st?'done':k===st?'done':''}"></span>`).join('')}</div>
      ${st===0?`<h3 style="margin:8px 0 6px">${titles[0]}</h3><p class="ink2 small">نستعمله للدخول والتواصل مع السائق. الرمز الدولي مضبوط حسب موقعك.</p>
        <div class="input mt12"><span class="num bold">🇱🇾 +218</span><input value="92 000 0000" dir="ltr"></div>
        <div class="banner info mt12">${I('pin','sm')}<span>حددنا منطقتك تلقائيًا: <b>مصراتة</b> · <button class="link small">تغيير</button></span></div>
        <button class="btn primary mt24" data-go="signup" data-replace="1" data-p='{"st":1}'>أرسل الرمز على واتساب</button>`
      : st===1? otpBlock('signup', {st:2})
      : st===2? `<h3 style="margin:8px 0 6px">${titles[2]}</h3><p class="ink2 small">اكتب اسمك كما تحب يظهر للسائق.</p>
        <div class="input mt12">${I('user','sm')}<input value="أحمد علي"></div>
        <div class="field-label mt16">الجنس (اختياري)</div><div class="flex"><button class="chip on">ذكر</button><button class="chip">أنثى</button><button class="chip">أفضّل ما نقول</button></div>
        <div class="field-label mt16">البريد الإلكتروني (اختياري)</div><div class="input"><input placeholder="name@example.ly" dir="ltr"></div>
        <button class="btn primary mt24" data-go="signup" data-replace="1" data-p='{"st":3}'>التالي</button>`
      : `<h3 style="margin:8px 0 6px">${titles[3]}</h3><p class="ink2 small">كلمة مرور من 8 أحرف على الأقل، تستعملها مع رقمك للدخول.</p>
        <div class="input mt12">${I('lock','sm')}<input type="password" value="••••••••"></div>
        <label class="flex mt16 small" style="align-items:flex-start"><span class="radio on" style="border-radius:6px"></span><span>أوافق على <span class="link small">شروط الاستخدام</span> و<span class="link small">سياسة الخصوصية</span>. نستعمل موقعك أثناء الخدمة فقط.</span></label>
        <div class="field-label mt16">رمز دعوة من صديق؟ (اختياري)</div><div class="input">${I('gift','sm')}<input placeholder="مثال: TAXISTA24" dir="ltr"></div>
        <button class="btn primary mt24" data-act="signupDone">إنشاء الحساب</button>`}
    </div>`; }
});
ACTS.signupDone = async (b) => { b.innerHTML = '<span class="spinner"></span> نجهّز حسابك…'; await wait(800); go('permission', {after:'gift'}, {root:true, fade:true}); };
SHEETS.welcomeGift = () => { openSheet(`<div class="center"><div class="state" style="padding:8px 0 0"><img src="${MASCOT}" alt="" width="110" height="110" style="object-fit:contain"></div>
  <h3>أهلًا بيك في تاكسيستا!</h3><p class="sheet-sub">هديتك الترحيبية <b>10.00 د.ل</b> جاهزة كرصيد مشاوير، تُخصم تلقائيًا من أول رحلة.</p>
  <button class="btn primary" onclick="closeSheet()">ابدأ رحلتك</button></div>`); confetti($('#screen')); };

screen('permission', { title:'إذن الموقع (قبل/بعد الرفض)', group:'start', states:['denied'],
  render:() => P.sim==='denied' ? `<div class="scroll col" style="padding:90px 24px 24px;align-items:center;text-align:center">
      <div class="state"><div class="art red">${I('pin','xl')}</div><h3>الموقع مقفول</h3><p>ما نقدروش نحددوا مكانك تلقائيًا. تقدر تفعّله من الإعدادات، أو تختار نقطة اللقاء على الخريطة بيدك.</p></div></div>
      <div class="sticky-cta col" style="gap:8px;border:0"><button class="btn primary">${I('settings','sm')} افتح الإعدادات</button><button class="btn outline" data-act="permSkip">أحدد على الخريطة</button></div>`
    : `<div class="scroll col" style="padding:90px 24px 24px;align-items:center;text-align:center">
      <div style="width:200px;height:200px;border-radius:56px;background:var(--brand-50);display:flex;align-items:center;justify-content:center;color:var(--brand);margin:10px 0 24px;position:relative">${I('locate','xl')}<span class="loc-dot" style="left:50%;top:50%"></span></div>
      <h2 style="margin:0 0 8px">خلّي السائق يلقاك بسرعة</h2><p class="ink2" style="line-height:1.8">نستعمل موقعك أثناء استعمال التطبيق فقط، باش نحددوا نقطة اللقاء ونوصّلوا أقرب سائق.</p></div>
      <div class="sticky-cta col" style="gap:8px;border:0"><button class="btn primary" data-act="permOk">السماح بالموقع</button><button class="btn ghost" data-act="permSkip">مش الآن</button></div>`
});
ACTS.permOk = () => { const gift = P.params.after==='gift'; go('home', {}, {root:true, fade:true}); if (gift) later(() => SHEETS.welcomeGift(), 700); };
ACTS.permSkip = () => { P.sim='default'; go('home', {}, {root:true, fade:true}); later(() => { P.sim='denied'; refresh(); }, 50); };

screen('update', { title:'تحديث مطلوب / متاح', group:'start', states:['success'],
  render:() => `<div class="scroll col" style="padding:100px 24px 24px;align-items:center;text-align:center">
    <div class="logo" style="width:96px;height:96px"><img src="${LOGO}" alt=""></div>
    <h2 class="mt24" style="margin-bottom:6px">تحديث جديد لتاكسيستا</h2>
    <p class="ink2" style="line-height:1.8">حسّنّا المكالمات والخرائط وأداء التطبيق لتجربة أسرع وأسهل.</p>
    <div class="tag brand">الإصدار <span class="num">6.8.0</span></div>
    ${P.sim==='success'?'':`<div class="banner warn mt16">${I('info','sm')}<span>هذا التحديث مطلوب لمتابعة الاستخدام بأمان.</span></div>`}</div>
    <div class="sticky-cta col" style="gap:6px;border:0"><button class="btn primary">${I('download','sm')} تحديث الآن</button>${P.sim==='success'?'<button class="btn ghost" data-go="home" data-replace="1">لاحقًا</button>':''}</div>`
});
screen('offline', { title:'لا يوجد إنترنت', group:'start',
  render:() => `${appbar('')}<div class="scroll">${stateBlock({icon:'wifiOff', tone:'red', title:'ما فيش اتصال بالإنترنت', text:'تحقّق من الواي فاي أو بيانات الهاتف. لو عندك رحلة جارية ما تقلقش — تبقى محفوظة ونكمل فور رجوع الاتصال.', cta:'إعادة المحاولة', ctaAct:'retry'})}</div>`
});

/* ================= HOME ================= */
screen('home', { title:'الرئيسية (الخريطة)', group:'home', states:['loading','denied','offline','recovery','ongoing'],
  render:() => {
    const nextRide = UPCOMING[0]; const r = P.rewards;
    const denied = P.sim==='denied', loading = P.sim==='loading';
    return `${mapHTML({center:MAP_PTS.me, oy:150, idleCars:!denied, pins: denied?[]:[['me','pick']]})}
      ${denied?'':`<span class="loc-dot" style="left:50%;top:calc(50% - 150px)"></span>`}
      ${P.sim==='offline'?`<div style="position:absolute;top:0;left:0;right:0;z-index:7;padding-top:46px">${offlineBar()}</div>`:''}
      <div class="map-top" style="${P.sim==='offline'?'top:92px':''}">
        <button class="icon-btn" data-act="drawer" aria-label="القائمة">${I('menu')}${P.chatUnread?'<span class="badge">'+P.chatUnread+'</span>':''}</button>
        <button class="status-pill press" data-go="mappick" data-p='{"field":"pick"}' style="max-width:200px">
          ${loading?`<span class="sk" style="width:110px;height:14px"></span>`:denied?`${I('alert','sm')}<span class="small">الموقع غير محدد</span>`:`<span class="live"></span><span class="small" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">الزروق · قرب البيت</span>`}
        </button>
        <button class="icon-btn" data-go="notifications" aria-label="الإشعارات">${I('bell')}${P.notifUnread?'<span class="badge">'+P.notifUnread+'</span>':''}</button>
      </div>
      ${P.sim==='ongoing'?`<button class="card flex press" style="position:absolute;top:110px;left:16px;right:16px;z-index:6;text-align:start;background:var(--navy);color:#fff;border:0" data-go="found"><span class="live"></span><span class="grow"><span class="bold small" style="display:block">رحلتك جارية</span><span class="tiny" style="display:block;opacity:.8">عبدالسلام في الطريق · يوصل خلال 4 د</span></span>${I('chevL','sm')}</button>`:''}
      ${P.sim==='recovery'?`<div style="position:absolute;top:110px;left:16px;right:16px;z-index:6" class="card" role="alert"><div class="flex"><span class="avatar">س</span><div class="grow"><div class="bold">سائق متاح الآن</div><div class="small muted">وجدنا سائقًا متاحًا لرحلتك السابقة. هل ما زلت تحتاج الرحلة؟</div></div></div>
        <div class="flex between small mt8"><span class="muted">الأجرة التقديرية</span><b class="num">12.50 د.ل</b></div><div class="row-btns mt12"><button class="btn primary sm" style="height:44px" data-act="recYesRide">نعم، أريد الرحلة</button><button class="btn outline sm" style="height:44px" data-act="recNoRide">لا، شكرًا</button></div></div>`:''}
      <button class="icon-btn map-fab" style="left:16px;bottom:${isB()?392:372}px" data-act="recenter" aria-label="موقعي">${I('locate')}</button>
      <div class="dock home-dock" style="max-height:64%"><div class="hero-top">
        <div class="grab"></div>
        ${denied?`<div class="banner danger" style="margin-bottom:10px">${I('pin','sm')}<div class="grow">ما قدرناش نحدد موقعك. <b>فعّل الموقع</b> أو حدّد نقطة اللقاء على الخريطة.</div></div>
          <div class="row-btns" style="margin-bottom:10px"><button class="btn sm primary" style="flex:1" data-go="permission">فعّل الموقع</button><button class="btn sm outline" style="flex:1" data-go="mappick" data-p='{"field":"pick"}'>على الخريطة</button></div>`:''}
        <div class="flex between" style="margin-bottom:10px">
          <div><div class="small muted">${greet()} يا ${ME.first}</div>${isB()?`<div class="bold" style="font-size:18px">وين ماشي اليوم؟</div>`:''}</div>
          ${isB()?`<button class="tag gold press" data-go="rewards">${I('coins','xs')} <span class="num">340</span></button>`:''}
        </div>
        <button class="where" data-go="search" data-p='{"field":"drop"}'>${I('search')}<span>إلى أين؟</span>
          <span class="later" data-sheet="schedule">${I('clock','xs')} الآن ${I('chevD','xs')}</span></button></div>
        <div class="quick">
          <button class="qd" data-act="pickDest" data-id="home"><span class="ic">${I('home','sm')}</span><span class="t">البيت</span><span class="s">الزروق</span></button>
          <button class="qd" data-act="pickDest" data-id="work"><span class="ic">${I('work','sm')}</span><span class="t">الشغل</span><span class="s">جامعة مصراتة</span></button>
          <button class="qd" data-act="pickDest" data-id="hospital"><span class="ic">${I('history','sm')}</span><span class="t">مؤخرًا</span><span class="s">المستشفى المركزي</span></button>
        </div>
        <div class="flex mt12" style="gap:8px">
          <button class="chip grow" style="justify-content:center" data-act="noDest">${I('nav','sm')} رحلة بدون وجهة</button>
          <button class="chip grow" style="justify-content:center" data-go="recurring">${I('repeat','sm')} مشوار الدوام</button>
        </div>
        <div class="mini-cards">
          <button class="mini" data-go="upcoming"><span class="ic" style="width:40px;height:40px;border-radius:12px;background:var(--brand-50);color:var(--brand);display:flex;align-items:center;justify-content:center">${I('cal','sm')}</span>
            <span class="tx"><span class="t" style="display:block">${nextRide.day} · <span class="num">${nextRide.time}</span></span><span class="s" style="display:block">مشوار الدوام · ${nextRide.label}</span></span></button>
          <button class="mini" data-go="campaign">${ring(r.done/r.target, 40, 5, isB()?'grad':'var(--brand)', `<span class="tiny bold num">${r.done}</span>`)}
            <span class="tx"><span class="t" style="display:block">مكافأة 100 رحلة</span><span class="s" style="display:block">باقي ${r.target-r.done} رحلة على 100 د.ل</span></span></button>
          <button class="mini" data-go="gifts"><span class="ic" style="width:40px;height:40px;border-radius:12px;background:var(--gold-bg);color:var(--gold);display:flex;align-items:center;justify-content:center">${I('tag','sm')}</span>
            <span class="tx"><span class="t" style="display:block">كوبون «مصراتة5»</span><span class="s" style="display:block">خصم 5 د.ل · لين 30 نوفمبر</span></span></button>
        </div>
      </div>`;
  },
  mount:(el) => { animateRings(el); }
});
ACTS.drawer = () => openDrawer();
ACTS.recYesRide = () => { P.sim='default'; P.driver='b'; go('found'); toast('حجزنا لك السائق', 'check'); };
ACTS.recNoRide = () => { P.sim='default'; refresh(); };
ACTS.recenter = (b) => { b.classList.add('hl'); setTimeout(() => b.classList.remove('hl'), 1200); toast('رجعنا الخريطة لموقعك', 'locate'); };
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
ACTS.swap = () => toast('بدّلنا الانطلاق والوجهة', 'swap');

/* ---- map pick ---- */
screen('mappick', { title:'اختيار مكان من الخريطة', group:'home', states:['loading','error'],
  render:(p) => {
    const pick = p.field==='pick';
    const title = p.nodest ? 'وين يقابلك السائق؟' : pick ? 'حدّد نقطة اللقاء' : p.fav ? 'حدّد مكان «'+p.fav+'»' : 'حدّد الوجهة';
    const addr = P.sim==='loading' ? `<span class="sk" style="display:inline-block;width:160px;height:14px"></span>` : P.sim==='error' ? 'تعذّر تحديد هذا العنوان' : (p.addr || (pick ? 'الزروق — قرب جامع الزروق' : 'ميدان النصر — وسط المدينة'));
    return `${mapHTML({center:MAP_PTS.me, oy:110})}
      <div class="center-pin ${pick?'':'drop'}" id="cpin" style="top:calc(50% - 110px)"><div class="pin-bubble">${pick?'السائق يقابلك هنا':'الوجهة'}</div><div class="head"></div><div class="stick"></div><div class="shadow"></div></div>
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
    const up = () => { if (x0===null) return; x0=null; pin.classList.remove('lift'); svg.style.transition=''; setTimeout(() => { const pl = PLACES[2+Math.floor(Math.random()*8)]; $('#paddr',el).textContent = pl.addr + ' — ' + pl.name; }, 450); };
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
screen('options', { title:'اختيار السيارة والسعر', group:'book', states:['loading','error','weak'],
  render:() => {
    const b = B(); const offer = b.mode==='offer';
    const v = VEHICLES.find(x => x.id===b.veh);
    const fair = v.fare;
    const ratio = b.offer / fair; const pos = Math.max(4, Math.min(96, (ratio-0.7)/0.6*100));
    const hint = ratio < 0.85 ? ['warn','عرضك أقل بكثير من السعر العادل — البحث ممكن يطوّل.'] : ratio > 1.1 ? ['info','عرض مرتفع — غالبًا تلقى سائق أسرع.'] : ['success','عرض مناسب، قريب من السعر العادل.'];
    const route = b.noDest ? null : ['me', placeById(b.drop||'square').pt];
    return `${mapHTML({center:[228,478], oy:250, zoom:.6, route, pins: b.noDest?[['me','pick']]:[['me','pick'],[placeById(b.drop||'square').pt,'drop']]})}
      <div class="map-top"><button class="icon-btn" data-back aria-label="رجوع">${I('back')}</button>
        <button class="status-pill press grow" style="justify-content:flex-start;min-width:0" data-go="search">${I('route','sm')}<span class="small" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${b.noDest?'من موقعك · بدون وجهة':`إلى ${dropName()}`}</span><span class="tiny muted" style="margin-inline-start:auto">${b.noDest?'':'<span class="num">4.2</span> كم · <span class="num">11</span> د'}</span></button></div>
      <div class="dock" style="max-height:70%">
        <div class="grab"></div>
        <div class="scroll" style="padding-bottom:4px">
        ${P.sim==='weak'?`<div class="banner warn" style="margin-bottom:10px">${I('wifiOff','sm')}<span>الإنترنت ضعيف — الأسعار المعروضة من آخر تحديث، نأكدها قبل الطلب.</span></div>`:''}
        ${P.sim==='error'?`<div class="banner danger" style="margin-bottom:10px">${I('alert','sm')}<div class="grow">تعذر تأكيد سعر الرحلة الآن.</div><button class="link small" data-act="retry">إعادة</button></div>`:''}
        ${b.noDest ? `<div class="banner info" style="margin-bottom:10px">${I('info','sm')}<div class="grow">بدون وجهة: الأجرة حسب العداد. <b>فتح 3.00 · الكيلو 1.20 · الدقيقة 0.20 د.ل</b> <span class="tiny">(عيّنة)</span></div></div>` : `
        <div class="mode-switch ${offer?'offer':''}" role="tablist"><span class="knob"></span>
          <button class="${!offer?'on':''}" data-act="mode" data-v="fixed">سعر ثابت<small>تعرف السعر قبل الطلب</small></button>
          <button class="${offer?'on':''}" data-act="mode" data-v="offer">فاوض بسعرك<small>السائقون يردّوا بعروض</small></button></div>`}
        <button class="card flex mt12 press" style="width:100%;text-align:start;padding:10px 12px;background:var(--success-bg);border:0;box-shadow:none" data-act="favFirst">
          <span class="avatar" style="width:36px;height:36px;font-size:14px">ع</span><span class="grow"><span class="small bold" style="display:block">عبدالسلام من «سواقيني» متاح الآن</span><span class="tiny muted" style="display:block">نعرض طلبك عليه أولًا، ولو ما قبلش نكمل البحث عادي.</span></span>
          <span class="toggle ${b.fav?'on':''}"></span></button>
        <div class="mt12" id="vehs">${P.sim==='loading' ? [1,2,3].map(()=>`<div class="veh" style="margin-top:8px"><div class="sk" style="width:62px;height:40px"></div><div class="grow"><div class="sk" style="height:14px;width:40%"></div><div class="sk mt8" style="height:10px;width:60%"></div></div><div class="sk" style="width:60px;height:20px"></div></div>`).join('') :
          VEHICLES.map(x => `<button class="veh ${x.id===b.veh?'on':''}" data-act="veh" data-v="${x.id}">${vehicleArt(x.color)}
            <span class="grow"><span class="flex" style="gap:6px"><span class="bold">${x.name}</span>${x.popular?'<span class="tag brand">الأكثر طلبًا</span>':''}</span><span class="tiny muted" style="display:block">${x.note} · يوصل خلال <span class="num">${x.eta}</span> د</span></span>
            <span class="p">${b.noDest?'<small>بالعداد</small>':offer&&x.id===b.veh?`<small>العادل</small>${x.fare.toFixed(2)}`:`${(x.fare - (x.id===b.veh?couponValue():0)).toFixed(2)}<small>${x.id===b.veh&&b.coupon?`<s>${x.fare.toFixed(2)}</s> بعد الكوبون`:'د.ل'}</small>`}</span></button>`).join('')}
        </div>
        ${offer && !b.noDest ? `<div class="card mt12" style="box-shadow:none;background:var(--surface-2);border:0">
          <div class="flex between"><span class="bold">عرضك للسائقين</span><button class="link small" data-sheet="fareInfo">كيف نحسب العادل؟</button></div>
          <div class="stepper mt8" style="background:var(--surface)"><button data-act="offerStep" data-v="-0.5" aria-label="أقل">${I('minus')}</button><div class="val"><span class="num">${b.offer.toFixed(2)}</span> <small>د.ل</small></div><button data-act="offerStep" data-v="0.5" aria-label="أكثر">${I('plus')}</button></div>
          <div class="fairbar"><span class="kn" style="left:${pos}%"></span></div>
          <div class="flex between tiny muted"><span>أقل</span><span>السعر العادل ${fair.toFixed(2)}</span><span>أعلى</span></div>
          <div class="banner ${hint[0]} mt8" style="padding:8px 10px">${I(hint[0]==='success'?'check':'info','xs')}<span class="small">${hint[1]}</span></div>
          <div class="chips" style="padding:8px 0 0;margin:0"><button class="chip" data-act="offerSet" data-v="${fair-1}">${(fair-1).toFixed(2)}</button><button class="chip on" data-act="offerSet" data-v="${fair}">العادل ${fair.toFixed(2)}</button><button class="chip" data-act="offerSet" data-v="${fair+1}">${(fair+1).toFixed(2)}</button><button class="chip" data-act="offerSet" data-v="${fair+2}">${(fair+2).toFixed(2)}</button></div>
        </div>`:''}
        <div class="opts">
          <button class="opt" data-sheet="payment">${I(b.pay==='wallet'?'wallet':'cash','sm')}<span class="grow"><span class="k">الدفع</span>${({cash:'نقدًا',wallet:'المحفظة',mix:'المحفظة + نقدًا'})[b.pay]}</span>${I('chevD','xs')}</button>
          <button class="opt" data-sheet="coupon" style="${b.coupon?'background:var(--success-bg);color:var(--success)':''}">${I('tag','sm')}<span class="grow"><span class="k">كوبون / هدية</span>${b.coupon?'مصراتة5 · −5.00':'أضف'}</span>${I('chevD','xs')}</button>
          <button class="opt" data-sheet="schedule">${I('clock','sm')}<span class="grow"><span class="k">الوقت</span>${b.when==='now'?'الآن':b.when}</span>${I('chevD','xs')}</button>
          <button class="opt" data-sheet="more">${I('sliders','sm')}<span class="grow"><span class="k">خيارات</span>${b.forOther?'لشخص آخر':b.prefs.length?b.prefs.join('، '):'أمتعة، لشخص آخر…'}</span>${I('chevD','xs')}</button>
        </div>
        </div>
        <button class="btn primary mt12 ${P.sim==='error'||P.sim==='loading'?'disabled':''}" data-act="request">${b.when!=='now'?`${I('cal','sm')} جدول الرحلة`:offer&&!b.noDest?`أرسل عرضك · <span class="price num">${(b.offer-couponValue()).toFixed(2)}</span> د.ل`:b.noDest?`اطلب ${v.name} بالعداد`:`اطلب ${v.name} · <span class="price num">${finalFare().toFixed(2)}</span> د.ل`}</button>
      </div>`;
  }
});
ACTS.mode = (t) => { B().mode = t.dataset.v; if (B().mode==='offer') B().offer = fareOf(B().veh); refresh(); };
ACTS.veh = (t) => { B().veh = t.dataset.v; B().offer = fareOf(B().veh); refresh(); };
ACTS.offerStep = (t) => { B().offer = Math.max(3, +(B().offer + (+t.dataset.v)).toFixed(2)); refresh(); };
ACTS.offerSet = (t) => { B().offer = +(+t.dataset.v).toFixed(2); refresh(); };
ACTS.favFirst = () => { B().fav = !B().fav; refresh(); if (B().fav) toast('نعرض طلبك على عبدالسلام أولًا', 'heart'); };
ACTS.request = async (btn) => {
  if (B().when !== 'now'){ btn.innerHTML = '<span class="spinner"></span>'; await wait(700);
    dialog({icon:'cal', tone:'green', title:'تمت جدولة رحلتك', text:`${B().when} · إلى ${dropName()}. نعرضها على السائقين ونخبرك أول ما يحجزها سائق.`, ok:'عرض الرحلات القادمة', onOk:() => { B().when='now'; go('upcoming', {}, {root:false}); }});
    return; }
  btn.innerHTML = '<span class="spinner"></span> نرسل طلبك…'; await wait(600); go('searching', {}, {replace:false});
};
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

/* ---- searching ---- */
screen('searching', { title:'البحث عن سائق', group:'book', states:['weak','nodriver'],
  render:() => {
    const offer = B().mode==='offer' && !B().noDest;
    if (P.sim==='nodriver') return `${mapHTML({center:MAP_PTS.me, oy:150})}<span class="loc-dot" style="left:50%;top:calc(50% - 150px)"></span>
      <div class="dock"><div class="grab"></div><div class="state" style="padding-bottom:16px"><img src="${MASCOT}" alt="" width="84" height="84" style="object-fit:contain"><h3>ما لقيناش سائق متاح الآن</h3><p>السائقون القريبون مشغولين. ما عليك أي رسوم. اختار وش نديروا:</p></div>
        <div class="col" style="gap:8px;margin-top:-10px"><button class="btn primary" data-act="retrySearch">${I('refresh','sm')} حاول مرة ثانية</button>
        <div class="row-btns">${offer?`<button class="btn outline sm" style="height:46px" data-act="raise">ارفع عرضك +1</button>`:''}<button class="btn outline sm" style="height:46px" data-act="toSchedule">جدولها لوقت لاحق</button></div>
        <button class="btn ghost" data-act="cancelSearch">رجوع للرئيسية</button></div></div>`;
    return `${mapHTML({center:MAP_PTS.me, oy:170, radar:true})}
      <div class="map-top"><span></span><div class="status-pill"><span class="live"></span><span class="small">نلقالك في سائق…</span></div><button class="icon-btn" data-sheet="tripSos" aria-label="طوارئ" style="color:var(--danger)">${I('shield')}</button></div>
      <div class="dock" style="max-height:66%"><div class="grab"></div>
        ${P.sim==='weak'?`<div class="banner warn" style="margin-bottom:10px">${I('wifiOff','sm')}<span><b>الإنترنت ضعيف…</b> نعيد إرسال طلبك (المحاولة 2 من 3). طلبك لن يتكرر ولن يضيع.</span></div>`:''}
        <div class="flex between"><div><div class="bold" style="font-size:18px" id="srchTitle">${offer?'عرضك وصل للسائقين':'نتواصل مع السائقين القريبين'}</div>
          <div class="small muted" id="srchSub">طلبك ظاهر الآن لأقرب <span class="num">6</span> سائقين · <span class="num" id="elapsed">0:00</span></div></div>
          <div class="center"><div class="bold num">${offer?(B().offer-couponValue()).toFixed(2):finalFare().toFixed(2)}</div><div class="tiny muted">${offer?'عرضك':'د.ل'}</div></div></div>
        <div class="steps"><span class="done"></span><span class="now" id="st2"></span><span id="st3"></span></div>
        <div class="flex tiny muted between" style="margin-top:-6px"><span>أرسلنا الطلب</span><span>السائقون يشاهدونه</span><span>قبول</span></div>
        <div id="offers" class="mt12"></div>
        <div class="card mt12" style="box-shadow:none;background:var(--surface-2);border:0;padding:10px 12px">
          <div class="flex small"><span class="dot" style="width:10px;height:10px;border-radius:50%;border:3px solid var(--brand)"></span><span class="grow">${pickName()}</span></div>
          <div class="flex small mt8"><span style="width:10px;height:10px;border-radius:3px;background:var(--ink)"></span><span class="grow">${dropName()}</span><span class="tiny muted">${({cash:'نقدًا',wallet:'المحفظة',mix:'محفظة + نقدًا'})[B().pay]}</span></div></div>
        <div class="row-btns mt12">${offer?`<button class="btn secondary sm" style="height:48px" data-act="raise">${I('plus','sm')} ارفع العرض</button>`:''}<button class="btn outline sm" style="height:48px" data-act="cancelSearch">إلغاء الطلب</button></div>
      </div>`;
  },
  mount:(el) => {
    if (P.sim==='nodriver') return;
    const t0 = Date.now(); const tick = () => { const s = Math.floor((Date.now()-t0)/1000); const e = $('#elapsed', el); if (!e) return; e.textContent = `${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}`; later(tick, 1000); }; tick();
    const offer = B().mode==='offer' && !B().noDest;
    if (offer){
      OFFERS.forEach((o, i) => later(() => { const d = DRIVERS[o.d]; const box = $('#offers', el); if (!box) return;
        box.insertAdjacentHTML('beforeend', `<div class="offer" id="of${i}"><span class="avatar">${d.ini}</span><div class="grow"><div class="bold small">${d.name} · ${I('star','xs')} <span class="num">${d.rating}</span></div><div class="tiny muted">${d.car} · يوصلك خلال <span class="num">${o.eta}</span> د</div></div>
          <div class="center" style="margin-inline-end:4px"><div class="bold num">${o.price.toFixed(2)}</div><div class="tiny muted">${o.price>B().offer?'أعلى من عرضك':'أقل من عرضك'}</div></div>
          <div class="col" style="gap:4px"><button class="btn primary sm" style="height:34px;padding:0 12px" data-act="acceptOffer" data-d="${o.d}">قبول</button><button class="btn ghost sm" style="height:28px;font-size:12px" data-act="declineOffer" data-i="${i}">رفض</button></div><i class="timer"></i></div>`);
        $('#srchTitle', el).textContent = (i+1)+' عرض وصلك'; $('#st2', el).className = 'done'; $('#st3', el).className='now';
        if (navigator.vibrate) try{ navigator.vibrate(30);}catch(e){}
      }, 2200 + i*2600));
    } else {
      later(() => { const s = $('#srchSub', el); if (s) s.innerHTML = 'سائق واحد يشاهد الطلب الآن…'; const st = $('#st2', el); if (st) st.className='done'; const s3 = $('#st3', el); if (s3) s3.className='now'; }, 2000);
      later(() => { if (P.screen==='searching' && P.sim!=='weak') { P.driver='a'; go('found', {}, {replace:true}); toast('لقينالك سائق!', 'check'); } }, 4600);
    }
  }
});
ACTS.acceptOffer = (t) => { P.driver = t.dataset.d; go('found', {}, {replace:true}); toast('قبلت عرض '+DRIVERS[P.driver].name, 'check'); };
ACTS.declineOffer = (t) => { const o = document.getElementById('of'+t.dataset.i); if (o){ o.style.transition='all .2s'; o.style.opacity='0'; o.style.transform='translateX(-30px)'; setTimeout(() => o.remove(), 200); } };
ACTS.raise = () => { B().offer = +(B().offer + 1).toFixed(2); P.sim='default'; go('searching', {}, {replace:true}); toast('رفعنا عرضك إلى '+B().offer.toFixed(2)+' د.ل', 'plus'); };
ACTS.retrySearch = () => { P.sim='default'; go('searching', {}, {replace:true}); };
ACTS.toSchedule = () => { P.sim='default'; go('options', {}, {replace:true}); later(() => SHEETS.schedule(), 300); };
ACTS.cancelSearch = () => dialog({icon:'x', tone:'red', title:'نلغي الطلب؟', text:'ما في أي رسوم لأن ما فيش سائق قبل طلبك بعد.', ok:'إلغاء الطلب', cancel:'كمّل البحث', danger:true, onOk:() => { P.sim='default'; go('home', {}, {root:true, fade:true}); later(() => toast('ألغينا الطلب'), 300); }});
