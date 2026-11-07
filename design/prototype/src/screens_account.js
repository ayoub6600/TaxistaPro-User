/* Screens: drawer, wallet, account, history, favourites, gifts, notifications, settings, support, SOS. SAMPLE DATA. */
'use strict';

/* ================= DRAWER ================= */
screen('drawer', { title:'القائمة الجانبية', group:'account',
  render:() => { const li = (id, ic, t, extra='', tone='') => `<button class="li" data-go="${id}"><span class="ic ${tone}">${I(ic,'sm')}</span><span class="tx"><span class="t">${t}</span></span>${extra}</button>`;
    return `<div class="dh"><button class="flex press" style="width:100%;text-align:start" data-go="profile"><span class="avatar lg">أ</span><span class="grow"><span class="bold" style="font-size:18px;display:block">${ME.name}</span><span class="small s num" style="display:block">${ME.phone}</span></span>${I('chevL','sm')}</button>
        <div class="flex mt12" style="gap:8px"><button class="chip grow" style="justify-content:center;${isB()?'background:rgba(255,255,255,.14);color:#fff;border:0':''}" data-go="wallet">${I('wallet','xs')} <span class="num">${(P.wallet.own+P.wallet.credit).toFixed(2)}</span> د.ل</button><button class="chip grow" style="justify-content:center;${isB()?'background:rgba(255,255,255,.14);color:#fff;border:0':''}" data-go="campaign">${I('trophy','xs')} <span class="num">${P.rewards.done}</span>/100</button></div></div>
      <div class="scroll" style="padding-bottom:12px">
        <div class="group-t">رحلاتي</div>
        ${li('upcoming','cal','الرحلات القادمة', `<span class="count blue">${UPCOMING.length}</span>`)}
        ${li('recurring','repeat','رحلاتي المتكررة', '<span class="tag brand">جديد</span>')}
        ${li('history','history','سجل الرحلات')}
        ${li('favorites','heart','سواقيني')}
        ${li('favAddr','pin','عناويني المفضلة')}
        ${li('outstation','route','رحلات بين المدن', '<span class="tag">حسب التفعيل</span>')}
        <div class="group-t">فلوسي ومكافآتي</div>
        ${li('wallet','wallet','المحفظة')}
        ${li('rewards','trophy','مكافآتي','', 'gold')}
        ${li('gifts','gift','الهدايا والكوبونات')}
        <div class="group-t">المساعدة والأمان</div>
        ${li('supportChat','headset','دعم العملاء', P.chatUnread?`<span class="count">${P.chatUnread}</span>`:'')}
        ${li('notifications','bell','الإشعارات', P.notifUnread?`<span class="count">${P.notifUnread}</span>`:'')}
        ${li('callLog','phone','سجل المكالمات')}
        ${li('complaint','file','تقديم شكوى')}
        ${li('sos','shield','الطوارئ وجهات الثقة','', 'red')}
        <div class="group-t">التطبيق</div>
        ${li('settings','settings','الإعدادات')}
        <button class="li" data-act="logout"><span class="ic">${I('logout','sm')}</span><span class="tx"><span class="t">تسجيل الخروج</span></span></button>
        <div class="tiny muted" style="padding:12px 18px">تاكسيستا · الإصدار <span class="num">6.8.0 (تصميم)</span></div>
      </div>`; }
});
ACTS.logout = () => dialog({icon:'logout', title:'تسجيل الخروج؟', text:'تقدر ترجع تدخل برقمك وكلمة المرور في أي وقت.', ok:'تسجيل الخروج', cancel:'رجوع', danger:true, onOk:() => go('login', {}, {root:true, fade:true})});

/* ================= WALLET ================= */
screen('wallet', { title:'المحفظة', group:'wallet', states:['loading','empty','error','offline'],
  render:() => { const w = P.wallet; return `${appbar('المحفظة', {right:`<button class="icon-btn" data-go="savedCards" aria-label="بطاقاتي">${I('card')}</button>`})}${offlineBar()}
    <div class="scroll" style="padding-bottom:24px">${P.sim==='loading'?skeletonList(4): P.sim==='error'?simStates({}): `
      <div class="sec"><div class="wallet-hero"><div class="small muted">الرصيد المتاح</div><div class="amt"><span class="num">${(w.own+w.credit).toFixed(2)}</span> <span style="font-size:18px">د.ل</span></div>
        <div class="split"><div><div class="tiny muted">أموالك</div><div class="bold num">${w.own.toFixed(2)}</div></div><div><div class="tiny muted">رصيد مشاوير</div><div class="bold num">${w.credit.toFixed(2)}</div></div><button data-sheet="balInfo" data-p='{"k":"credit"}' class="muted" aria-label="شرح">${I('info','sm')}</button></div>
        <div class="qa"><button data-sheet="addMoney"><span class="ib">${I('plus')}</span>إضافة فلوس</button><button data-sheet="transfer"><span class="ib">${I('send')}</span>تحويل</button><button data-go="savedCards"><span class="ib">${I('card')}</span>بطاقاتي</button><button data-go="rewards"><span class="ib">${I('trophy')}</span>مكافآتي</button></div></div></div>
      <div class="sec-title">آخر المعاملات <button class="link small" data-go="transactions">الكل</button></div>
      <div class="sec" style="margin-top:0">${P.sim==='empty'?stateBlock({icon:'wallet', title:'ما فيش معاملات بعد', text:'لما تشحن محفظتك أو تدفع رحلة منها، تظهر الحركة هنا.', cta:'إضافة فلوس', ctaSheet:'addMoney'}):`<div class="list">${txRows(TXNS.slice(0,4))}</div>`}</div>`}
    </div>`; }
});
function txRows(list){
  const extra = P.rewards.phase==='credited' ? [{t:'مكافأة 100 رحلة', s:'رصيد مشاوير · للرحلات فقط', v:100, at:'الآن', k:'reward', ic:'trophy'}] : [];
  return [...extra, ...list].map(t => `<button class="li" data-sheet="txInfo" data-p='${JSON.stringify(t).replace(/'/g,'&#39;')}'><span class="ic ${t.k==='reward'?'gold':t.v>0?'green':''}">${I(t.ic,'sm')}</span><span class="tx"><span class="t" style="display:block">${t.t}</span><span class="s" style="display:block">${t.s} · ${t.at}</span></span><span class="${t.v>0?'amt-pos':'amt-neg'} num">${t.v>0?'+':''}${t.v.toFixed(2)}</span></button>`).join('');
}
SHEETS.txInfo = (t) => openSheet(`<h3>${t.t}</h3><div class="xbold mt8" style="font-size:30px;color:${t.v>0?'var(--success)':'var(--ink)'}"><span class="num">${t.v>0?'+':''}${t.v.toFixed(2)}</span> د.ل</div><div class="small muted">${t.s} · ${t.at}</div>
  <div class="list mt12"><div class="li"><span class="tx"><span class="t">الحالة</span></span><span class="tag green">مكتملة</span></div><div class="li"><span class="tx"><span class="t">المرجع</span></span><span class="num small">TX-${Math.floor(10000+Math.random()*80000)}</span></div></div>
  <button class="btn ghost mt8" data-go="supportChat">مشكلة في هذه المعاملة؟</button>`);
screen('transactions', { title:'المعاملات', group:'wallet', states:['loading','empty'],
  render:(p) => { const f = p.f||'all'; const list = TXNS.filter(t => f==='all' || (f==='credit'&&t.k==='credit') || (f==='debit'&&t.k==='debit') || (f==='reward'&&t.k==='reward'));
    return `${appbar('المعاملات')}<div class="chips" style="padding-bottom:8px">${[['all','الكل'],['credit','إضافة'],['debit','خصم'],['reward','مكافآت']].map(([k,t])=>`<button class="chip ${f===k?'on':''}" data-go="transactions" data-replace="1" data-p='{"f":"${k}"}'>${t}</button>`).join('')}</div>
    <div class="scroll">${simStates({empty:{icon:'list', title:'ما فيش حركات هنا', text:'جرّب فلتر آخر.'}}) || `<div class="sec-title">نوفمبر 2026</div><div class="sec" style="margin-top:0"><div class="list">${txRows(list)}</div></div>`}</div>`; }
});
SHEETS.addMoney = (p) => openSheet(`<h3>إضافة فلوس</h3><p class="sheet-sub">اختر طريقة الإضافة</p>
  ${P.sim==='offline'?`<div class="banner warn" style="margin-bottom:10px">${I('wifiOff','sm')}<span>تعذّر الاتصال بالخادم. تظهر الطرق الأساسية فقط.</span></div>`:''}
  <div class="list">
    <button class="li" ${P.sim==='disabled'?'disabled style="opacity:.5"':'data-go="topup"'}><span class="ic brand">${I('card','sm')}</span><span class="tx"><span class="t" style="display:block">البطاقة المصرفية</span><span class="s" style="display:block">${P.sim==='disabled'?'الدفع بالبطاقة البنكية غير متاح الآن':'ادفع ببطاقتك المصرفية بأمان · معاملات'}</span></span>${I('chevL','sm')}</button>
    <button class="li" data-sheet="cardCode"><span class="ic">${I('ticket','sm')}</span><span class="tx"><span class="t" style="display:block">بطاقة شحن</span><span class="s" style="display:block">أدخل رمز بطاقة الشحن</span></span>${I('chevL','sm')}</button>
    <button class="li" data-act="noop"><span class="ic">${I('users','sm')}</span><span class="tx"><span class="t" style="display:block">من صديق</span><span class="s" style="display:block">اطلب منه يحوّلك من محفظته</span></span>${I('chevL','sm')}</button></div>
  <p class="tiny muted mt8">الطرق تظهر حسب منطقتك (البطاقة المصرفية في ليبيا فقط).</p>`);
ACTS.noop = () => toast('مثال: يفتح «تحويل» عند صديقك', 'info');
SHEETS.cardCode = () => openSheet(`<h3>بطاقة شحن</h3><p class="sheet-sub">اكتب الرمز المطبوع على البطاقة.</p><div class="input">${I('ticket','sm')}<input placeholder="أدخل رمز بطاقة الشحن" dir="ltr" inputmode="numeric"></div><button class="btn primary mt12" data-act="codeOk">شحن</button>`);
ACTS.codeOk = async (b) => { b.innerHTML='<span class="spinner"></span>'; await wait(700); closeSheet(); P.wallet.own += 20; refresh(); toast('تمت إضافة 20.00 د.ل إلى محفظتك'); };
SHEETS.transfer = () => openSheet(`<h3>تحويل أموال</h3><p class="sheet-sub">من «أموالك» فقط — رصيد المشاوير ما يتحوّلش.</p>
  <div class="field-label">رقم المستلم</div><div class="input"><span class="num bold">+218</span><input placeholder="92 000 0000" dir="ltr"></div>
  <div class="field-label mt12">المبلغ</div><div class="input"><input placeholder="0.00" dir="ltr" inputmode="decimal"><span class="muted">د.ل</span></div><div class="help">المتاح للتحويل: ${P.wallet.own.toFixed(2)} د.ل</div>
  <button class="btn primary mt12" data-act="trDo">متابعة</button>`);
ACTS.trDo = () => { closeSheet(); dialog({icon:'send', title:'تأكيد التحويل', text:'تحويل 10.00 د.ل إلى +218 92 000 0000؟ ما يمكنش التراجع بعد التأكيد.', ok:'تأكيد التحويل', cancel:'رجوع', onOk:() => { P.wallet.own -= 10; refresh(); toast('تم التحويل'); }}); };
screen('topup', { title:'شحن بالبطاقة (معاملات)', group:'wallet', states:['error','disabled'],
  render:() => `${appbar('شحن بالبطاقة المصرفية', {sub:'الدفع الإلكتروني الآمن · معاملات'})}
    <div class="scroll" style="padding:0 16px 20px">
      ${P.sim==='disabled'?`<div class="banner danger">${I('alert','sm')}<span>الدفع عبر معاملات غير متاح حالياً. جرّب بطاقة شحن أو حاول لاحقًا.</span></div>`:''}
      <div class="field-label mt12">المبلغ</div>
      <div class="input ${P.sim==='error'?'error':''}" style="height:70px"><input id="amt" value="${P.sim==='error'?'2':'50'}" dir="ltr" inputmode="decimal" style="font-size:30px;font-weight:800"><span class="muted bold">د.ل</span></div>
      <div class="help ${P.sim==='error'?'err':''}">المبلغ يجب أن يكون بين 5.00 و500.00 د.ل</div>
      <div class="chips" style="margin:10px -16px 0;padding:0 16px">${[10,20,50,100,200].map(v=>`<button class="chip ${v===50?'on':''}" data-act="amt" data-v="${v}"><span class="num">${v}</span></button>`).join('')}</div>
      <div class="sec-title" style="margin:20px 0 8px">بطاقاتي <button class="link small" data-go="savedCards">إدارة</button></div>
      <div class="list"><button class="li"><span class="radio on"></span><span class="ic brand">${I('card','sm')}</span><span class="tx"><span class="t" style="display:block">بطاقة •••• 4821</span><span class="s" style="display:block">محفوظة على هذا الجهاز للتعبئة الذكية</span></span></button>
        <button class="li"><span class="radio"></span><span class="ic">${I('card','sm')}</span><span class="tx"><span class="t">الدفع دون بطاقة محفوظة</span></span></button></div>
      <div class="banner info mt12">${I('lock','sm')}<span>تتم عملية الدفع على صفحة معاملات الآمنة. «التعبئة الذكية» تعبّي بيانات بطاقتك وتوافق على الشروط بضغطة — رمز CVV تكتبه أنت.</span></div>
    </div>
    <div class="sticky-cta"><button class="btn primary ${P.sim==='disabled'||P.sim==='error'?'disabled':''}" data-go="checkout">${I('lock','sm')} المتابعة إلى الدفع الآمن</button></div>`
});
ACTS.amt = (t) => { $('#amt').value = t.dataset.v; t.parentElement.querySelectorAll('.chip').forEach(c=>c.classList.remove('on')); t.classList.add('on'); };
screen('checkout', { title:'صفحة الدفع + النتيجة', group:'wallet', states:['pending','success','failed'],
  render:() => { const s = P.sim;
    if (s==='success') return `${appbar('',{noBack:true})}<div class="scroll">${stateBlock({icon:'check', tone:'green', title:'تمت إضافة الرصيد', text:'تمت إضافة 50.00 د.ل إلى محفظتك. نعيدك إلى المحفظة…'})}</div><div class="sticky-cta"><button class="btn primary" data-act="toWallet">تم</button></div>`;
    if (s==='failed') return `${appbar('',{noBack:true})}<div class="scroll">${stateBlock({icon:'x', tone:'red', title:'لم تكتمل عملية الدفع', text:'لم تُضف أي أموال إلى محفظتك. يمكنك المحاولة مرة أخرى.'})}</div><div class="sticky-cta col" style="gap:8px"><button class="btn primary" data-go="topup" data-replace="1">إعادة المحاولة</button><button class="btn ghost" data-act="toWallet">إغلاق</button></div>`;
    if (s==='pending') return `${appbar('',{noBack:true})}<div class="scroll"><div class="state"><div class="art"><span class="spinner" style="width:40px;height:40px;border-color:var(--brand-100);border-top-color:var(--brand)"></span></div><h3>جارٍ تأكيد الدفع…</h3><p>لا تُغلق هذه الصفحة. لو تم خصم المبلغ ولم يظهر خلال دقائق، تواصل مع الدعم مع رقم العملية TX-88412.</p></div></div>`;
    return `${appbar('الدفع الإلكتروني الآمن', {sub:'صفحة معاملات (محاكاة)', right:`<button class="icon-btn" data-act="closePay" aria-label="إغلاق">${I('x')}</button>`})}
      <div class="scroll" style="padding:0 16px 20px"><div class="card"><div class="flex between"><span class="bold">المبلغ</span><span class="bold num">50.00 LYD</span></div><div class="tiny muted mt8">صفحة البنك الحقيقية تُعرض هنا داخل التطبيق (WebView).</div></div>
      <div class="card"><div class="field-label">رقم البطاقة</div><div class="input"><input value="•••• •••• •••• 4821" dir="ltr" disabled></div><div class="flex mt12" style="gap:8px"><div class="input grow"><input value="08/28" dir="ltr" disabled></div><div class="input grow"><input placeholder="CVV" dir="ltr"></div></div>
        <label class="flex mt12 small"><span class="radio on" style="border-radius:6px"></span> أوافق على الشروط</label></div>
      <div class="banner success">${I('sparkle','sm')}<span><b>التعبئة الذكية:</b> عبّينا البطاقة ووافقنا على الشروط. اكتب CVV فقط.</span></div></div>
      <div class="sticky-cta"><button class="btn primary" data-act="payNow">ادفع 50.00 د.ل</button></div>`; }
});
ACTS.closePay = () => dialog({icon:'x', title:'إغلاق صفحة الدفع؟', text:'إن لم تُكمل الدفع فلن تُضاف أي أموال إلى محفظتك.', ok:'إغلاق', cancel:'متابعة الدفع', onOk:() => back()});
ACTS.payNow = async () => { P.sim='pending'; refresh(); await wait(1600); if (P.screen!=='checkout') return; P.sim='success'; P.wallet.own += 50; refresh(); confetti($('#screen')); };
ACTS.toWallet = () => { P.sim='default'; go('wallet', {}, {replace:true}); };
screen('savedCards', { title:'بطاقاتي (على الجهاز)', group:'wallet', states:['empty'],
  render:() => `${appbar('بطاقاتي')}<div class="scroll">${simStates({empty:{icon:'card', title:'ما فيش بطاقات محفوظة', text:'أضف بطاقتك مرة واحدة لتسهيل الدفع لاحقاً. تبقى على هذا الجهاز فقط.', cta:'إضافة بطاقة', ctaAct:'noop'}}) || `
    <div class="sec"><div class="card" style="background:linear-gradient(135deg,#0A1F44,#0873FF);color:#fff;border:0;height:180px;display:flex;flex-direction:column;justify-content:space-between"><div class="flex between"><span class="bold">بطاقة مصرفية</span>${I('card')}</div><div class="num" style="font-size:22px;letter-spacing:2px">•••• •••• •••• 4821</div><div class="flex between small"><span>AHMED ALI</span><span class="num">08/28</span></div></div></div>
    <div class="sec"><div class="banner info">${I('lock','sm')}<span>محفوظة بتشفير على هذا الجهاز، وما توصلش لخوادم تاكسيستا. تُستعمل لتعبئة صفحة البنك فقط.</span></div></div>
    <div class="sec"><button class="btn secondary">${I('plus','sm')} إضافة بطاقة</button><button class="btn ghost mt8" style="color:var(--danger)">حذف البطاقة</button></div>`}</div>`
});

/* ================= PROFILE / HISTORY / FAVOURITES ================= */
screen('profile', { title:'الملف الشخصي', group:'account', states:['error'],
  render:() => `${appbar('الملف الشخصي', {hero:true})}
    <div class="scroll" style="padding-bottom:20px"><div class="sec center"><div style="position:relative;display:inline-block"><span class="avatar lg" style="width:88px;height:88px;font-size:32px">أ</span><button class="icon-btn" style="position:absolute;bottom:-4px;left:-4px;width:34px;height:34px" data-sheet="photo" aria-label="تغيير الصورة">${I('edit','sm')}</button></div>
      <h3 style="margin:10px 0 0">${ME.name}</h3><div class="small muted">راكب منذ ${ME.since} · ${I('star','xs')} <span class="num">4.9</span></div></div>
      <div class="sec"><div class="bal3"><div class="b center"><div class="v num">142</div><div class="k">رحلة</div></div><div class="b center"><div class="v num">3</div><div class="k">في سواقيني</div></div><div class="b center"><div class="v num">340</div><div class="k">عملة</div></div></div></div>
      <div class="sec"><div class="field-label">الاسم</div><div class="input">${I('user','sm')}<input value="${ME.name}"></div>
        <div class="field-label mt12">رقم الهاتف</div><div class="input" style="background:var(--surface-2)"><span class="num grow">${ME.phone}</span><span class="tag">${I('lock','xs')} مؤكد</span></div><div class="help">لتغيير الرقم تواصل مع الدعم (يتطلب تحقق).</div>
        <div class="field-label mt12">البريد الإلكتروني</div><div class="input ${P.sim==='error'?'error':''}">${I('msg','sm')}<input value="${ME.email}" dir="ltr"></div>${P.sim==='error'?'<div class="help err">البريد الإلكتروني غير صحيح.</div>':''}
        <div class="field-label mt12">الجنس</div><div class="flex"><button class="chip on">ذكر</button><button class="chip">أنثى</button><button class="chip">غير محدد</button></div></div>
      <div class="sec"><button class="btn primary" data-act="saveProfile">حفظ التغييرات</button></div></div>`
});
ACTS.saveProfile = async (b) => { b.innerHTML = '<span class="spinner"></span>'; await wait(600); b.innerHTML = 'حفظ التغييرات'; toast('حفظنا ملفك'); };
SHEETS.photo = () => openSheet(`<h3>صورة الملف</h3><div class="list"><button class="li"><span class="ic">${I('eye','sm')}</span><span class="tx"><span class="t">افتح الكاميرا</span></span></button><button class="li"><span class="ic">${I('layers','sm')}</span><span class="tx"><span class="t">من الصور</span></span></button><button class="li"><span class="ic red">${I('trash','sm')}</span><span class="tx"><span class="t">إزالة الصورة</span></span></button></div><p class="tiny muted mt8">لو الإذن مرفوض نعرض زر «افتح الإعدادات».</p>`);

screen('history', { title:'سجل الرحلات', group:'account', states:['loading','empty','offline'],
  render:(p) => { const f = p.f||'done'; const list = HISTORY.filter(h => h.st===f);
    return `${appbar('سجل الرحلات')}${offlineBar()}
      <div class="tabs"><button class="${f==='done'?'on':''}" data-go="history" data-replace="1" data-p='{"f":"done"}'>مكتملة</button><button class="${f==='cancelled'?'on':''}" data-go="history" data-replace="1" data-p='{"f":"cancelled"}'>ملغاة</button><button data-go="upcoming">القادمة</button></div>
      <div class="scroll" style="padding-bottom:20px">${simStates({empty:{icon:'history', title:'ما عندكش رحلات بعد', text:'أول رحلة تكملها تظهر هنا مع الفاتورة والسائق.', cta:'اطلب رحلة', ctaGo:'search'}}) || list.map(h => `<div class="sec" style="margin-top:10px"><button class="card press" style="width:100%;text-align:start;display:block" data-go="histDetail" data-p='{"id":"${h.id}"}'>
        <div class="flex between"><span class="small muted">${h.date} · ${h.veh}</span>${h.st==='done'?`<span class="bold num">${h.fare.toFixed(2)} د.ل</span>`:'<span class="tag red">ملغاة</span>'}</div>
        <div class="timeline mt8"><div class="tl done"><div class="t small">${h.from}</div></div><div class="tl"><div class="t small">${h.to}</div></div></div>
        <div class="flex between tiny muted">${h.d?`<span class="flex"><span class="avatar" style="width:22px;height:22px;font-size:10px">${DRIVERS[h.d].ini}</span>${DRIVERS[h.d].full}</span>`:`<span>${h.reason||''}</span>`}<span>${h.pay}</span></div></button></div>`).join('')}</div>`; }
});
screen('histDetail', { title:'تفاصيل رحلة سابقة', group:'account', states:['loading'],
  render:(p) => { const h = HISTORY.find(x => x.id===p.id) || HISTORY[0]; const d = h.d ? DRIVERS[h.d] : null;
    return `${appbar('تفاصيل الرحلة', {sub:`${h.id} · ${h.date}`})}
    <div class="scroll" style="padding-bottom:20px">${simStates({}) || `
      <div class="sec"><div class="card" style="padding:0;overflow:hidden"><div style="height:160px;position:relative">${mapHTML({center:[175,410], zoom:.55, route:['home','work'], pins:[['home','pick'],['work','drop']]})}</div>
        <div class="pad"><div class="timeline"><div class="tl done"><div class="t">${h.from}</div><div class="s"><span class="num">08:12</span></div></div><div class="tl done"><div class="t">${h.to}</div><div class="s"><span class="num">08:29</span> · <span class="num">6.8</span> كم</div></div></div></div></div></div>
      ${d?`<div class="sec"><div class="card flex"><span class="avatar">${d.ini}</span><div class="grow"><div class="bold">${d.full}</div><div class="tiny muted">${d.car} · <span class="num">${d.plate}</span> · قيّمتها ${I('star','xs')}5</div></div><button class="icon-btn" data-go="driverProfile" aria-label="صفحة السائق">${I('user','sm')}</button></div></div>`:''}
      <div class="sec"><div class="card small"><div class="flex between"><span class="muted">الأجرة الأساسية</span><span class="num">${h.fare.toFixed(2)}</span></div><div class="flex between mt8"><span class="muted">الخصم</span><span class="num">0.00</span></div><div class="hr"></div><div class="flex between bold"><span>الإجمالي · ${h.pay}</span><span class="num">${h.fare.toFixed(2)} د.ل</span></div></div></div>
      <div class="sec"><div class="list">
        <button class="li" data-act="rebook"><span class="ic brand">${I('repeat','sm')}</span><span class="tx"><span class="t" style="display:block">اطلب نفس الرحلة</span><span class="s" style="display:block">نفس الانطلاق والوجهة</span></span>${I('chevL','sm')}</button>
        <button class="li" data-go="recNew"><span class="ic">${I('cal','sm')}</span><span class="tx"><span class="t" style="display:block">خليها مشوار متكرر</span><span class="s" style="display:block">نحجزها لك كل يوم</span></span>${I('chevL','sm')}</button>
        ${d?`<button class="li" data-go="tripChat"><span class="ic">${I('msg','sm')}</span><span class="tx"><span class="t" style="display:block">راسل السائق</span><span class="s" style="display:block">نسيت حاجة في السيارة؟ متاح 24 ساعة بعد الرحلة</span></span>${I('chevL','sm')}</button>`:''}
        <button class="li" data-go="complaint"><span class="ic red">${I('file','sm')}</span><span class="tx"><span class="t">تقديم شكوى عن هذه الرحلة</span></span>${I('chevL','sm')}</button></div></div>`}
    </div>`; }
});
ACTS.rebook = () => { Object.assign(B(), {pick:'me', drop:'work', noDest:false}); go('options'); };

screen('favorites', { title:'سواقيني', group:'account', states:['loading','empty','error'],
  render:() => `${appbar('سواقيني', {sub:'سائقينك المفضلين'})}
    <div class="scroll" style="padding-bottom:20px">${simStates({empty:{icon:'heart', title:'لا يوجد سائقون في «سواقيني» بعد', text:'بعد رحلة جميلة اضغط على القلب لتضيف سائقك. لما يكون قريب ومتاح نعرض طلبك عليه أولًا.'}}) || `
      <div class="sec"><div class="banner info">${I('info','sm')}<span>عند الطلب: لو واحد من سواقيني قريب ومتاح، تقدر تختار «اطلبه أولًا». لو ما قبلش نكمل البحث عادي.</span></div></div>
      ${Object.values(DRIVERS).map((d,i) => `<div class="sec" style="margin-top:10px"><div class="card"><div class="flex"><span class="avatar">${d.ini}</span><div class="grow"><div class="bold">${d.full} ${i===0?'<span class="tag green">يفضّلك أيضًا</span>':''}</div><div class="tiny muted">${d.car} · ${I('star','xs')} <span class="num">${d.rating}</span> · <span class="num">${[12,5,2][i]}</span> رحلة معًا</div></div>
        <span class="tag ${i<2?'green':''}">${i<2?'<span class="live" style="width:6px;height:6px"></span> متاح قريب':'غير متاح'}</span></div>
        <div class="row-btns mt12"><button class="btn secondary sm" style="height:42px" data-act="${i<2?'reqFav':'noop'}">${i<2?'اطلبه الآن':'نبّهني لما يتاح'}</button><button class="btn outline sm" style="height:42px" data-go="driverProfile">صفحته</button><button class="icon-btn" style="box-shadow:none;border:1px solid var(--line)" data-act="rmFav" aria-label="إزالة">${I('heart','sm')}</button></div></div></div>`).join('')}`}
    </div>`
});
ACTS.reqFav = () => { B().fav = true; go('search'); toast('اختر وجهتك — نعرض الطلب على سائقك أولًا', 'heart'); };
ACTS.rmFav = (t) => dialog({icon:'heart', title:'إزالة من سواقيني؟', text:'يقدر يرجع لما تضيفه بعد رحلة جديدة.', ok:'إزالة', cancel:'تراجع', danger:true, onOk:() => { t.closest('.sec').remove(); toast('أزلناه من «سواقيني»'); }});
screen('driverProfile', { title:'صفحة السائق', group:'account',
  render:() => { const d = DRIVERS.a; return `${appbar('صفحة السائق', {right:`<button class="icon-btn" data-sheet="report" aria-label="المزيد">${I('dots')}</button>`})}
    <div class="scroll" style="padding-bottom:20px"><div class="sec center"><span class="avatar lg" style="width:88px;height:88px;font-size:32px;margin:0 auto">${d.ini}</span><h3 style="margin:10px 0 0">${d.full}</h3><div class="small muted">${d.car} · ${d.color}</div>
      <div class="flex mt12" style="justify-content:center"><span class="tag green">${I('heart','xs')} في «سواقيني»</span></div></div>
      <div class="sec"><div class="bal3"><div class="b center"><div class="v">${I('star','xs')} <span class="num">${d.rating}</span></div><div class="k">التقييم</div></div><div class="b center"><div class="v num">${d.rides}</div><div class="k">رحلة</div></div><div class="b center"><div class="v num">3</div><div class="k">سنوات</div></div></div></div>
      <div class="sec-title">أوسمة من الركاب</div><div class="sec" style="margin-top:0;display:flex;flex-wrap:wrap;gap:8px">${['سواقة آمنة · 212','في الموعد · 180','نظيفة · 150','محترم · 140'].map(b=>`<span class="tag brand" style="padding:7px 11px;font-size:12.5px">${b}</span>`).join('')}</div>
      <div class="sec-title">كلمات الركاب</div><div class="sec" style="margin-top:0"><div class="card small">«سواق محترم ووصلني في الوقت»<div class="tiny muted mt8">راكب موثّق · أكتوبر</div></div></div>
      <div class="sec"><button class="btn secondary" data-act="shareTrip">${I('share','sm')} مشاركة صفحة السائق</button></div></div>`; }
});
SHEETS.report = () => openSheet(`<h3>الإبلاغ أو الحظر</h3><div class="list">${['محتوى مسيء','إزعاج أو تحرش','كشف معلومات خاصة','سبب آخر'].map(r=>`<button class="li" data-act="reasonPick"><span class="radio"></span><span class="tx"><span class="t">${r}</span></span></button>`).join('')}</div>
  <button class="btn primary mt12" onclick="closeSheet();toast('وصلنا البلاغ')">إبلاغ</button><button class="btn danger mt8" onclick="closeSheet();toast('حظرنا هذا السائق')">حظر هذا السائق</button><p class="tiny muted mt8">الحظر: لن يظهر لك في «سواقيني» ولن تُعرض عليه طلباتك كسائق مفضل، ولن يرى صفحتك.</p>`);

screen('gifts', { title:'الهدايا والكوبونات', group:'account', states:['empty'],
  render:() => `${appbar('الهدايا والكوبونات')}
    <div class="scroll" style="padding-bottom:20px">
      <div class="sec"><div class="card" style="background:var(--hero);color:${isB()?'#fff':'var(--ink)'}"><div class="flex"><span class="ic" style="width:48px;height:48px;border-radius:16px;background:var(--gold-bg);color:var(--gold);display:flex;align-items:center;justify-content:center">${I('gift','lg')}</span><div class="grow"><div class="bold">ادعُ صديق لتاكسيستا</div><div class="small" style="opacity:.8">انضم لعائلة تاكسيستا عن طريق رمز دعوتي لتسهيل مشوارك</div></div></div>
        <div class="flex mt12" style="gap:8px"><div class="input grow" style="height:46px;background:var(--surface-2)"><span class="bold num grow" style="color:var(--ink)">AHMED-7K2</span><button class="link small" data-act="copyCode">${I('copy','xs')} نسخ</button></div><button class="btn primary sm" style="height:46px" data-act="shareTrip">${I('share','sm')} شارك</button></div></div></div>
      <div class="sec-title">كوبوناتك</div>
      <div class="sec" style="margin-top:0">${P.sim==='empty'?stateBlock({icon:'tag', title:'ما عندكش كوبونات الآن', text:'نرسلولك الكوبونات في الإشعارات، وتقدر تكتب أي رمز عند الطلب.'}):`<div class="list">${COUPONS.map(c=>`<div class="li" style="${c.ok?'':'opacity:.5'}"><span class="ic ${c.ok?'gold':''}">${I('tag','sm')}</span><span class="tx"><span class="t" style="display:block">${c.code} · ${c.v}</span><span class="s" style="display:block">${c.s}</span></span>${c.ok?'<button class="btn secondary sm" data-act="useCoupon">استعمل</button>':'<span class="tag">منتهي</span>'}</div>`).join('')}</div>`}</div>
      <div class="sec"><div class="input">${I('tag','sm')}<input placeholder="عندك رمز؟ اكتبه هنا"><button class="link small">إضافة</button></div></div>
      <div class="sec-title">هدايا من تاكسيستا</div>
      <div class="sec" style="margin-top:0"><div class="list"><div class="li"><span class="ic green">${I('gift','sm')}</span><span class="tx"><span class="t" style="display:block">هدية ترحيبية 10.00 د.ل</span><span class="s" style="display:block">استُخدمت في أول رحلة</span></span><span class="tag green">${I('check','xs')} مستعملة</span></div>
        <button class="li" data-go="rewards"><span class="ic gold">${I('trophy','sm')}</span><span class="tx"><span class="t" style="display:block">مكافآت الرحلات</span><span class="s" style="display:block">100 رحلة = 100 دينار وغيرها</span></span>${I('chevL','sm')}</button></div></div>
    </div>`
});
ACTS.copyCode = () => toast('نسخنا رمز الدعوة', 'copy');
ACTS.useCoupon = () => { B().coupon = 'مصراتة5'; go('search'); toast('الكوبون جاهز لرحلتك الجاية', 'tag'); };

screen('notifications', { title:'الإشعارات (كلها)', group:'account', states:['loading','empty','error'],
  render:(p) => { const f = p.f||'all'; return `${appbar('الإشعارات', {right:`<button class="link small" data-act="readAll">قراءة الكل</button>`})}
    <div class="chips" style="padding-bottom:8px">${[['all','الكل'],['rides','الرحلات'],['money','المحفظة والمكافآت'],['support','الدعم'],['offers','العروض']].map(([k,t])=>`<button class="chip ${f===k?'on':''}" data-go="notifications" data-replace="1" data-p='{"f":"${k}"}'>${t}</button>`).join('')}</div>
    <div class="scroll" style="padding-bottom:20px">${simStates({empty:{icon:'bell', title:'ما فيش إشعارات', text:'كل إشعار يوصلك (رحلات، محفظة، مكافآت، دعم، عروض) ينحفظ هنا.'}}) || `
      <div class="sec-title">اليوم</div><div class="sec" style="margin-top:0"><div class="list">${NOTIFS.slice(0,3).map(notifRow).join('')}</div></div>
      <div class="sec-title">هذا الأسبوع</div><div class="sec" style="margin-top:0"><div class="list">${NOTIFS.slice(3).map(notifRow).join('')}</div></div>
      <p class="sec tiny muted center">اسحب إشعار لليسار لحذفه · نعرض كل ما وصلك خلال 90 يوم</p>`}</div>`; }
});
function notifRow(n){ return `<button class="li" data-go="${n.go}" style="${n.unread&&P.notifUnread?'background:var(--brand-50)':''}"><span class="ic ${n.tone==='gold'?'gold':n.tone==='green'?'green':n.tone==='brand'?'brand':''}">${I(n.ic,'sm')}</span><span class="tx"><span class="t" style="display:block;white-space:normal">${n.t}</span><span class="s" style="display:block;white-space:normal">${n.b}</span><span class="tiny muted">${n.at}</span></span>${n.unread&&P.notifUnread?'<span class="count blue" style="min-width:10px;height:10px;padding:0"></span>':''}</button>`; }
ACTS.readAll = () => { P.notifUnread = 0; refresh(); toast('علّمنا الكل كمقروء'); };

screen('settings', { title:'الإعدادات', group:'account',
  render:() => `${appbar('الإعدادات')}
    <div class="scroll" style="padding-bottom:20px">
      <div class="sec-title">العرض</div><div class="sec" style="margin-top:0"><div class="list">
        <button class="li" data-go="language"><span class="ic">${I('globe','sm')}</span><span class="tx"><span class="t">اللغة</span></span><span class="end">العربية ${I('chevL','sm')}</span></button>
        <div class="li"><span class="ic">${I('moon','sm')}</span><span class="tx"><span class="t">المظهر</span></span><div class="tabs" style="margin:0;width:190px">${[['light','فاتح'],['dark','داكن'],['auto','تلقائي']].map(([k,t])=>`<button class="${(P.theme===k)?'on':''}" data-act="theme" data-v="${k}" style="height:32px;font-size:12px">${t}</button>`).join('')}</div></div>
        <div class="li"><span class="ic">${I('sparkle','sm')}</span><span class="tx"><span class="t" style="display:block">تقليل الحركة</span><span class="s" style="display:block">يتبع إعداد الهاتف تلقائيًا</span></span><button class="toggle ${reduced()?'on':''}" data-act="reducedT"></button></div>
        <div class="li"><span class="ic">${I('eye','sm')}</span><span class="tx"><span class="t" style="display:block">حجم الخط</span><span class="s" style="display:block">يتبع حجم خط الهاتف (حتى 130%)</span></span></div></div></div>
      <div class="sec-title">الإشعارات</div><div class="sec" style="margin-top:0"><div class="list">
        ${[['تحديثات الرحلات',1,1],['المحفظة والمكافآت',1,0],['عروض تاكسيستا',1,0],['رسائل الدعم',1,1]].map(([t,on,lock])=>`<div class="li"><span class="tx"><span class="t" style="display:block">${t}</span>${lock?'<span class="s" style="display:block">ضرورية للخدمة</span>':''}</span><button class="toggle ${on?'on':''}" ${lock?'disabled style="opacity:.6"':'data-act="tglSelf"'}></button></div>`).join('')}</div></div>
      <div class="sec-title">عن التطبيق</div><div class="sec" style="margin-top:0"><div class="list">
        <button class="li" data-go="support"><span class="ic">${I('help','sm')}</span><span class="tx"><span class="t">الأسئلة الشائعة</span></span>${I('chevL','sm')}</button>
        <button class="li"><span class="ic">${I('lock','sm')}</span><span class="tx"><span class="t">سياسة الخصوصية</span></span>${I('chevL','sm')}</button>
        <button class="li"><span class="ic">${I('file','sm')}</span><span class="tx"><span class="t">الشروط والأحكام</span></span>${I('chevL','sm')}</button>
        <div class="li"><span class="ic">${I('info','sm')}</span><span class="tx"><span class="t">الإصدار</span></span><span class="end num">6.8.0</span></div></div></div>
      <div class="sec"><button class="btn danger" data-act="delAcc">${I('trash','sm')} حذف الحساب</button></div></div>`
});
ACTS.theme = (t) => { const v = t.dataset.v==='auto' ? (matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light') : t.dataset.v; Studio.set('theme', v); };
ACTS.reducedT = () => Studio.set('reduced', reduced()?'0':'1');
ACTS.delAcc = () => dialog({icon:'trash', tone:'red', title:'نحذف حسابك نهائيًا؟', text:'تنحذف بياناتك ورحلاتك ورصيد المشاوير. لو عندك أموال في المحفظة حوّلها أو تواصل مع الدعم قبل الحذف.', ok:'نعم، احذف حسابي', cancel:'تراجع', danger:true, onOk:() => toast('في التطبيق: نطلب تأكيد برمز واتساب قبل الحذف', 'lock')});
screen('language', { title:'تغيير اللغة', group:'account',
  render:() => `${appbar('اللغة')}<div class="scroll"><div class="sec"><div class="list">
    <button class="li"><span class="tx"><span class="t" style="display:block">العربية</span><span class="s" style="display:block">لهجة ليبية · من اليمين لليسار</span></span><span class="radio on"></span></button>
    <button class="li" data-act="enLang"><span class="tx"><span class="t" style="display:block">English</span><span class="s" style="display:block">Left to right</span></span><span class="radio"></span></button></div></div>
    <p class="sec tiny muted">التغيير فوري بدون إعادة تشغيل. الأسماء والعناوين تبقى كما هي.</p></div>`
});
ACTS.enLang = () => toast('In the app: switches to English (LTR) instantly. The prototype is Arabic-only.', 'globe');
screen('outstation', { title:'رحلات بين المدن', group:'account', states:['empty'],
  render:() => `${appbar('رحلات بين المدن', {sub:'تظهر فقط إذا كانت مفعّلة لحسابك'})}<div class="scroll">${P.sim==='empty'?stateBlock({icon:'route', title:'ما عندكش رحلات بين المدن', text:'اطلب رحلة لمدينة ثانية (مثلاً طرابلس أو سرت) واستقبل عروض السائقين.', cta:'اطلب رحلة بين المدن', ctaGo:'search'}):`
    <div class="sec"><div class="card"><div class="flex between"><span class="bold">مصراتة ← طرابلس</span><span class="tag warn">بانتظار العروض</span></div><div class="small muted mt8">ذهاب فقط · الخميس 07:00 · عرضك 180.00 د.ل</div>
      <div class="list mt12"><div class="li"><span class="avatar" style="width:34px;height:34px;font-size:13px">س</span><span class="tx"><span class="t" style="display:block">سالم · 190.00 د.ل</span><span class="s" style="display:block">كيا سيراتو · 4.8</span></span><button class="btn success sm">قبول</button></div></div></div></div>
    <p class="sec tiny muted">الشاشة الحالية في التطبيق اسمها «خارج المحطة» — نقترح «بين المدن».</p>`}</div>`
});

/* ================= SUPPORT ================= */
screen('support', { title:'مركز المساعدة', group:'support',
  render:() => `${appbar('كيف نقدروا نساعدوك؟', {hero:true, sub:'نرد على رسائلك بأسرع وقت'})}
    <div class="scroll" style="padding-bottom:20px">
      <div class="sec"><div class="row-btns"><button class="btn primary" data-go="supportChat">${I('msg','sm')} محادثة</button><button class="btn secondary" data-go="call" data-p='{"who":"support"}'>${I('phone','sm')} اتصال مجاني</button></div>
        <div class="tiny muted center mt8"><span class="live" style="display:inline-block;width:6px;height:6px"></span> متاحون للمكالمات الآن · مكالمة صوتية داخل التطبيق دون رصيد</div></div>
      <div class="sec-title">مواضيع سريعة</div>
      <div class="chips">${['مشكلة في رحلة','الدفع','المحفظة والرصيد','حسابي','مشوار الدوام','اقتراح أو ملاحظة'].map(t=>`<button class="chip" data-go="supportChat">${t}</button>`).join('')}</div>
      <div class="sec-title">الأسئلة الشائعة</div>
      <div class="sec" style="margin-top:0"><div class="list">${FAQ.map(q=>`<details class="li" style="display:block"><summary class="flex" style="list-style:none;cursor:pointer"><span class="grow t" style="white-space:normal">${q}</span>${I('chevD','sm')}</summary><div class="small ink2 mt8" style="line-height:1.7">إجابة مختصرة تُدار من لوحة الإدارة (FAQ).</div></details>`).join('')}</div></div>
      <div class="sec"><div class="list"><button class="li" data-go="complaint"><span class="ic red">${I('file','sm')}</span><span class="tx"><span class="t">تقديم شكوى</span></span>${I('chevL','sm')}</button><button class="li" data-go="callLog"><span class="ic">${I('phone','sm')}</span><span class="tx"><span class="t">سجل المكالمات</span></span>${I('chevL','sm')}</button><button class="li"><span class="ic">${I('globe','sm')}</span><span class="tx"><span class="t" style="display:block">طرق تواصل أخرى</span><span class="s" style="display:block">موقع تاكسيستا · واتساب الدعم</span></span>${I('chevL','sm')}</button></div></div></div>`
});
screen('supportChat', { title:'محادثة الدعم (تفاعلات + بطاقة تأكيد)', group:'support', states:['loading','error','empty'],
  render:() => `${appbar('دعم تاكسيستا', {sub:'متاحون الآن · نرد عادةً خلال دقائق', right:`<button class="icon-btn" data-go="call" data-p='{"who":"support"}' aria-label="اتصال مجاني">${I('phone')}</button>`})}
    ${P.sim==='loading'?skeletonList(4):P.sim==='empty'?`<div class="scroll">${stateBlock({icon:'headset', title:'كيف نقدروا نساعدوك؟', text:'اكتب رسالتك أو سجّل رسالة صوتية، وسيرد عليك فريق تاكسيستا هنا في أقرب وقت.'})}<div class="chips" style="justify-content:center;flex-wrap:wrap">${['مشكلة في رحلة','الدفع','المحفظة والرصيد','حسابي'].map(t=>`<button class="chip">${t}</button>`).join('')}</div></div>`:`
    <div class="chat" id="chat">
      <div class="day-sep">أمس</div>
      <div class="msg me" data-m="1">السلام عليكم، نبي نحجز مشوار للشغل كل يوم الساعة 7 وربع<div class="meta">16:02 · ✓✓</div></div>
      <div class="msg them has-r" data-m="2">وعليكم السلام يا أحمد، تمام. من البيت في الزروق لجامعة مصراتة صح؟<div class="meta">16:05</div><div class="reacts">👍</div></div>
      <div class="msg me" data-m="3">صح، من السبت للخميس<div class="meta">16:06 · ✓✓</div></div>
      <div class="msg them deleted" data-m="4">${I('x','xs')} تم حذف هذه الرسالة<div class="meta">16:07</div></div>
      <div class="day-sep">اليوم</div>
      <div class="msg them" data-m="5">جهّزنالك مشوار الدوام بسعر رسمي 10 د.ل، وتاكسيستا تخصملك 2 د.ل، فتدفع 8 د.ل لكل مشوار.<div class="meta">10:01 · <span>معدّلة</span></div></div>
      <div class="action-card" id="ac">
        <div class="h">${I('repeat','sm')}<div class="grow"><div class="bold small">مشوار الدوام · البيت ← الشغل</div><div class="tiny muted">السبت–الخميس · 07:15 · 8.00 د.ل</div></div></div>
        <div class="b">راجع التفاصيل وأكّد، وأول مشوار يتحجز لك تلقائيًا. <button class="link small" data-go="recConfirm">عرض التفاصيل</button></div>
        <div class="f"><button style="color:var(--success)" data-act="acYes">✅ أؤكد</button><button style="color:var(--danger)" data-act="acNo">❌ لا</button></div></div>
      <div class="msg them" data-m="6"><div class="voice">${I('play','sm')}<span class="wave">${Array.from({length:22}).map((_,i)=>`<i style="height:${6+((i*5)%14)}px"></i>`).join('')}</span><span class="tiny num">0:12</span></div><div class="meta">10:03</div></div>
      ${P.sim==='error'?`<div class="msg me" style="opacity:.75">شكرًا<div class="meta" style="color:#FFD2CC">لم تُرسل · اضغط لإعادة المحاولة</div></div>`:''}
    </div>
    <div class="tiny muted center" style="padding:4px">اضغط مرتين على أي رسالة للتفاعل</div>
    <div class="composer"><button class="icon-btn" style="box-shadow:none" data-sheet="voiceRec" aria-label="رسالة صوتية">${I('mic')}</button><div class="input"><input placeholder="اكتب رسالتك…"></div><button class="icon-btn" style="background:var(--brand);color:#fff" data-act="sendSup" aria-label="إرسال">${I('send')}</button></div>`}`,
  mount:(el) => {
    const chat = $('#chat', el); if (!chat) return; chat.scrollTop = chat.scrollHeight;
    let lastTap = 0, lastEl = null;
    const openBar = (m) => { $$('.react-bar', el).forEach(b => b.remove()); if (m.classList.contains('deleted')) return;
      const bar = document.createElement('div'); bar.className = 'react-bar'; bar.innerHTML = ['👍','❤️','😂','😮','🙏','✅'].map(e => `<button>${e}</button>`).join('');
      const r = m.getBoundingClientRect(), pr = el.getBoundingClientRect(); bar.style.top = Math.max(60, r.top - pr.top - 54) + 'px'; bar.style[m.classList.contains('me')?'left':'right'] = '12px';
      el.appendChild(bar);
      bar.addEventListener('click', e => { const b = e.target.closest('button'); if (!b) return; let rc = m.querySelector('.reacts'); if (!rc){ rc = document.createElement('div'); rc.className = 'reacts'; m.appendChild(rc); m.classList.add('has-r'); } rc.textContent = b.textContent; bar.remove(); if (navigator.vibrate) try{navigator.vibrate(8);}catch(e){} });
      setTimeout(() => document.addEventListener('pointerdown', function h(ev){ if (!bar.contains(ev.target)){ bar.remove(); document.removeEventListener('pointerdown', h); } }), 10);
    };
    chat.addEventListener('dblclick', e => { const m = e.target.closest('.msg'); if (m){ e.preventDefault(); openBar(m); } });
    chat.addEventListener('pointerup', e => { if (e.pointerType !== 'touch') return; const m = e.target.closest('.msg'); const now = Date.now(); if (m && m===lastEl && now-lastTap < 320){ openBar(m); lastTap = 0; } else { lastTap = now; lastEl = m; } });
  }
});
ACTS.acYes = (t) => { const ac = $('#ac'); ac.querySelector('.f').innerHTML = `<div class="grow center small bold" style="padding:13px;color:var(--success)">${I('check','xs')} أكّدت · بانتظار أول مشوار السبت</div>`; P.rec.status='active'; const c = $('#chat'); c.insertAdjacentHTML('beforeend', `<div class="msg them" style="animation:offerIn .3s var(--ease-spring)">تمام! أكّدنا مشوار الدوام. أول مشوار السبت 07:15 🚕<div class="meta">الآن</div></div>`); c.scrollTop = c.scrollHeight; };
ACTS.acNo = () => dialog({icon:'x', tone:'red', title:'ما تبيش هذا المشوار؟', text:'نسجّل ردّك «لا» ونخبر الفريق. تقدر تكتبلهم وش تبي يتغير.', ok:'نعم، لا', cancel:'رجوع', danger:true, onOk:() => { $('#ac .f').innerHTML = `<div class="grow center small bold" style="padding:13px;color:var(--danger)">❌ رفضت · سجّلنا ردّك</div>`; }});
ACTS.sendSup = () => { const inp = $('.page:last-child .composer input'); if (!inp || !inp.value.trim()) return; const c = $('#chat'); c.insertAdjacentHTML('beforeend', `<div class="msg me" style="animation:offerIn .25s var(--ease-spring)">${esc(inp.value)}<div class="meta">الآن · ✓</div></div>`); inp.value=''; c.scrollTop = c.scrollHeight; };
SHEETS.voiceRec = () => openSheet(`<div class="center"><h3>تسجيل رسالة صوتية</h3><div class="sheet-sub">اسحب لليمين للإلغاء · ارفع إصبعك للإرسال</div>
  <div style="width:92px;height:92px;border-radius:50%;background:var(--danger);color:#fff;display:flex;align-items:center;justify-content:center;margin:8px auto;box-shadow:0 0 0 12px var(--danger-bg)">${I('mic','lg')}</div><div class="bold num">0:04</div>
  <div class="row-btns mt16"><button class="btn outline" onclick="closeSheet()">إلغاء</button><button class="btn primary" onclick="closeSheet();toast('أُرسلت الرسالة الصوتية','mic')">إرسال</button></div></div>`);

screen('complaint', { title:'تقديم شكوى', group:'support', states:['success'],
  render:(p) => { if (P.sim==='success') return `${appbar('')}${stateBlock({icon:'check', tone:'green', title:'وصلتنا شكواك', text:'رقمها C-1042. نراجعوها ونردوا عليك في محادثة الدعم خلال 24 ساعة.', cta:'افتح المحادثة', ctaGo:'supportChat'})}`;
    const st = p.st||0; return `${appbar('تقديم شكوى', {sub: st===0?'وش نوع المشكلة؟':'التفاصيل'})}
    <div class="scroll" style="padding-bottom:20px">${st===0?`<div class="sec"><div class="list">${['السائق','الأجرة أو الدفع','السيارة','السلامة','التطبيق','شي آخر'].map(c=>`<button class="li" data-go="complaint" data-replace="1" data-p='{"st":1,"c":"${c}"}'><span class="tx"><span class="t">${c}</span></span>${I('chevL','sm')}</button>`).join('')}</div></div>`
    : `<div class="sec"><div class="card flex"><span class="ic" style="width:38px;height:38px;border-radius:12px;background:var(--surface-2);display:flex;align-items:center;justify-content:center">${I('car','sm')}</span><div class="grow small"><b>رحلة R-2041</b><div class="tiny muted">اليوم 08:12 · البيت ← الشغل</div></div><button class="link small">تغيير</button></div>
      <div class="field-label mt12">${p.c||''} — اكتب شكواك هنا</div><div class="input" style="height:auto;padding:10px 14px"><textarea rows="5" style="border:0;outline:0;background:transparent;width:100%;resize:none;font-size:15px" placeholder="احكيلنا وش صار بالتفصيل"></textarea></div>
      <button class="btn outline mt12">${I('plus','sm')} أرفق صورة (اختياري)</button></div>`}</div>
    ${st===1?`<div class="sticky-cta"><button class="btn primary" data-act="cmpSend">إرسال الشكوى</button></div>`:''}`; }
});
ACTS.cmpSend = async (b) => { b.innerHTML = '<span class="spinner"></span>'; await wait(600); P.sim='success'; refresh(); };
screen('callLog', { title:'سجل المكالمات', group:'support', states:['empty'],
  render:(p) => { const f = p.f||'all'; const list = CALLS.filter(c => f==='all' || c.dir===f);
    return `${appbar('سجل المكالمات', {sub:'مكالمات مجانية عبر تطبيق تاكسيستا'})}
    <div class="chips" style="padding-bottom:8px">${[['all','الكل'],['missed','الفائتة'],['in','الواردة'],['out','الصادرة']].map(([k,t])=>`<button class="chip ${f===k?'on':''}" data-go="callLog" data-replace="1" data-p='{"f":"${k}"}'>${t}</button>`).join('')}</div>
    <div class="scroll">${(P.sim==='empty'||!list.length)?stateBlock({icon:'phone', title:f==='missed'?'لا توجد مكالمات فائتة':'لا توجد مكالمات بعد', text:'مكالماتك مع السائقين ومع دعم تاكسيستا تظهر هنا، ويمكنك معاودة الاتصال أو المراسلة منها.'}):`<div class="sec"><div class="list">${list.map(c=>`<div class="li"><span class="ic ${c.dir==='missed'?'red':''}">${I('phone','sm')}</span><span class="tx"><span class="t" style="display:block;${c.dir==='missed'?'color:var(--danger)':''}">${c.who}</span><span class="s" style="display:block">${({in:'واردة',out:'صادرة',missed:'فائتة'})[c.dir]} · ${c.at}${c.dur?' · '+c.dur:''}</span></span><button class="icon-btn" style="width:36px;height:36px;box-shadow:none" data-go="call" data-p='{"who":"${c.who.includes('دعم')?'support':'driver'}"}' aria-label="معاودة الاتصال">${I('phone','sm')}</button><button class="icon-btn" style="width:36px;height:36px;box-shadow:none" data-go="${c.who.includes('دعم')?'supportChat':'tripChat'}" aria-label="مراسلة">${I('msg','sm')}</button></div>`).join('')}</div></div>`}</div>`; }
});
screen('sos', { title:'الطوارئ وجهات الثقة', group:'support', states:['empty','denied'],
  render:() => `${appbar('الطوارئ وجهات الثقة')}
    <div class="scroll" style="padding-bottom:20px">
      <div class="sec"><div class="card" style="background:var(--danger-bg);border:0"><div class="flex"><span style="color:var(--danger)">${I('shield','lg')}</span><div class="grow small" style="color:var(--danger)"><b>في خطر أثناء رحلة؟</b> زر «طوارئ» موجود في شاشة الرحلة دائمًا. يتصل بالطوارئ، ويخبّر إدارة تاكسيستا، ويشارك موقعك مع جهات الثقة.</div></div></div></div>
      <div class="sec-title">جهات الثقة <span class="tiny muted">حتى 4</span></div>
      <div class="sec" style="margin-top:0">${P.sim==='empty'?stateBlock({icon:'users', title:'ما أضفتش جهات ثقة', text:'أضف أشخاص نرسلولهم موقعك لما تضغط «طوارئ».'}):`<div class="list">${TRUSTED.map(t=>`<div class="li"><span class="avatar gray" style="width:38px;height:38px">${t.n[0]}</span><span class="tx"><span class="t" style="display:block">${t.n}</span><span class="s num" style="display:block">${t.p}</span></span><button class="icon-btn" style="width:36px;height:36px;box-shadow:none" data-act="rmTrusted" aria-label="حذف">${I('trash','sm')}</button></div>`).join('')}</div>`}
        ${P.sim==='denied'?`<div class="banner warn mt12">${I('lock','sm')}<div class="grow">إذن جهات الاتصال مرفوض. تقدر تكتب الرقم بيدك أو تفتح الإعدادات.</div></div>`:''}
        <button class="btn secondary mt12" data-sheet="addTrusted">${I('plus','sm')} إضافة جهة ثقة</button></div></div>`
});
ACTS.rmTrusted = (t) => { t.closest('.li').remove(); toast('حذفنا جهة الثقة'); };
SHEETS.addTrusted = () => openSheet(`<h3>إضافة جهة ثقة</h3><button class="btn outline">${I('users','sm')} اختر من جهات الاتصال</button><div class="hr"></div><div class="input">${I('user','sm')}<input placeholder="الاسم"></div><div class="input mt8"><span class="num bold">+218</span><input placeholder="رقم الهاتف" dir="ltr"></div><button class="btn primary mt12" onclick="closeSheet();toast('أضفنا جهة الثقة')">إضافة</button>`);
