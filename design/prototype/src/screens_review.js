/* Review screens: concept comparison, design system, states gallery, before/after, coverage map. */
'use strict';
screen('compare', { title:'مقارنة A و B', group:'review',
  render:() => `${appbar('اتجاهان بصريان', {sub:'بدّل من لوحة التحكم وشوف الفرق على أي شاشة'})}
    <div class="scroll" style="padding-bottom:24px">
      <div class="sec"><div class="row-btns"><button class="btn ${P.concept==='a'?'primary':'outline'}" data-act="setC" data-v="a">A · بسيط وهادئ</button><button class="btn ${P.concept==='b'?'primary':'outline'}" data-act="setC" data-v="b">B · مميز وحديث</button></div></div>
      <div class="sec"><div class="card"><div class="bold">A — Clean & Minimal</div><div class="small ink2 mt8" style="line-height:1.8">خريطة هي البطلة، أسطح بيضاء، حدود رفيعة، ظلال خفيفة، زوايا 12–16، أزرار مسطحة، حركة قصيرة جدًا. أخف على الأجهزة المتوسطة والشاشات الصغيرة، وأوضح لأول مرة.</div></div>
      <div class="card"><div class="bold">B — Modern Premium Mobility</div><div class="small ink2 mt8" style="line-height:1.8">رأس بتدرّج كحلي←أزرق، بطاقات أعمق بظل أوضح، زوايا 20–24، حلقة مكافآت متدرّجة، أزرار بتدرّج أزرق←سماوي، شارة العملات في الرئيسية. هوية أقوى وإحساس «تطبيق كبير».</div></div></div>
      <div class="sec"><table class="cov card" style="padding:0"><tr><th>المعيار</th><th>A</th><th>B</th></tr>
        ${[['سرعة الفهم لأول مرة','★★★','★★☆'],['قوة الهوية','★★☆','★★★'],['الأداء والبطارية','★★★','★★☆'],['إبراز المكافآت والمحفظة','★★☆','★★★'],['تحمّل الشمس القوية (تباين)','★★★','★★☆'],['كلفة التنفيذ في Flutter','أقل','متوسطة']].map(r=>`<tr>${r.map(c=>`<td>${c}</td>`).join('')}</tr>`).join('')}</table></div>
      <div class="sec"><div class="banner success">${I('check','sm')}<span><b>التوصية: A كأساس + لمسات B في 4 أماكن فقط</b> (رأس المكافآت، بطاقة المحفظة، الاحتفال، شاشة البداية). التفصيل في الوثيقة وفي DECISIONS_NEEDED.</span></div></div>
    </div>`
});
ACTS.setC = (t) => Studio.set('concept', t.dataset.v);

screen('designSystem', { title:'نظام التصميم', group:'review',
  render:() => { const sw = (n, v, t) => `<div class="swatch"><i style="background:${v}"></i><div><div class="small bold">${n}</div><div class="tiny muted kbd">${t}</div></div></div>`;
    return `${appbar('نظام التصميم', {sub:'Taxista Rider DS v0.1'})}
    <div class="scroll" style="padding-bottom:24px">
      <div class="sec-title">الألوان (تتبدّل مع الوضع الداكن)</div>
      <div class="sec ds-grid" style="margin-top:0">${sw('brand','var(--brand)','#0873FF / #3D8BFF')}${sw('brand-50','var(--brand-50)','#EAF4FF / #12223F')}${sw('navy','#0A1F44','#0A1F44')}${sw('cyan accent','#17C3E8','#17C3E8')}${sw('ink','var(--ink)','#0E1A2B / #EAF0F8')}${sw('ink-3','var(--ink-3)','#7F8CA1')}${sw('surface','var(--surface)','#FFF / #111A2A')}${sw('bg','var(--bg)','#F4F6FA / #0A101C')}${sw('success','var(--success)','#109A4C')}${sw('warn','var(--warn)','#B76E00')}${sw('danger','var(--danger)','#D92D20')}${sw('gold','var(--gold)','#B8860B')}</div>
      <div class="sec-title">الخط: IBM Plex Sans Arabic (بديل: Cairo)</div>
      <div class="sec" style="margin-top:0"><div class="card">${[['Display 32/800','٣٢ — 12.50 د.ل',32,800],['Title 22/700','عنوان الشاشة',22,700],['Headline 18/700','إلى أين؟',18,700],['Body 15/400','نص أساسي مريح للقراءة',15,400],['Label 13/600','تسمية زر أو حقل',13,600],['Caption 12/500','ملاحظة صغيرة',12,500]].map(([n,s,z,w])=>`<div class="flex between" style="padding:6px 0"><span style="font-size:${z}px;font-weight:${w}">${s}</span><span class="tiny muted kbd">${n}</span></div>`).join('')}
        <div class="tiny muted mt8">الأرقام: tabular + LTR داخل النص العربي (<span class="kbd">.num</span>) حتى لا تقفز الأسعار.</div></div></div>
      <div class="sec-title">المسافات · الحواف · الظلال</div>
      <div class="sec" style="margin-top:0"><div class="card small">مسافات: <span class="kbd">4 · 8 · 12 · 16 · 20 · 24 · 32</span><br>حواف A: <span class="kbd">8 · 12 · 16 · 20 · 28</span> — B: <span class="kbd">8 · 14 · 20 · 24 · 32</span><br>ظلال: <span class="kbd">sh-1 (قوائم) · sh-2 (بطاقات) · sh-3 (نوافذ)</span><br>اللمس: أي هدف ≥ <span class="kbd">44×44</span>، الزر الرئيسي <span class="kbd">54</span> ارتفاع.</div></div>
      <div class="sec-title">الأزرار</div>
      <div class="sec col" style="margin-top:0;gap:8px"><button class="btn primary">أساسي · اطلب الرحلة</button><button class="btn secondary">ثانوي</button><button class="btn outline">محدد</button><button class="btn danger">خطِر · إلغاء</button><div class="row-btns"><button class="btn primary"><span class="spinner"></span></button><button class="btn primary disabled">معطّل</button></div></div>
      <div class="sec-title">الحقول والشرائح</div>
      <div class="sec" style="margin-top:0"><div class="input">${I('search','sm')}<input placeholder="حقل عادي"></div><div class="input error mt8">${I('alert','sm')}<input value="حقل فيه خطأ"></div><div class="help err">رسالة خطأ واضحة تقول وش نديرو</div>
        <div class="flex mt12" style="flex-wrap:wrap;gap:8px"><span class="chip on">مختار</span><span class="chip">عادي</span><span class="tag brand">brand</span><span class="tag green">نجاح</span><span class="tag warn">تنبيه</span><span class="tag red">خطأ</span><span class="tag gold">مكافأة</span></div></div>
      <div class="sec-title">التنبيهات</div>
      <div class="sec col" style="margin-top:0;gap:8px"><div class="banner info">${I('info','sm')}<span>معلومة</span></div><div class="banner success">${I('check','sm')}<span>نجاح</span></div><div class="banner warn">${I('alert','sm')}<span>تحذير</span></div><div class="banner danger">${I('x','sm')}<span>خطأ</span></div></div>
      <div class="sec-title">الأيقونات (خط 1.9، 24px)</div>
      <div class="sec" style="margin-top:0"><div class="card" style="display:grid;grid-template-columns:repeat(8,1fr);gap:12px;color:var(--ink-2)">${Object.keys(ICONS).slice(0,48).map(k=>`<span title="${k}" style="display:flex;justify-content:center">${I(k)}</span>`).join('')}</div></div>
      <div class="sec-title">Skeleton</div>${skeletonList(2)}
      <div class="sec-title">الحركة</div>
      <div class="sec" style="margin-top:0"><div class="card small" style="line-height:1.9">ضغط الزر 120ms (scale .97) · الصفحات 320ms دخول / 220ms رجوع (من اليسار في RTL) · النوافذ السفلية 320ms spring، تُغلق بالسحب لأسفل > 90px · التوستات 320ms · رسم المسار 900ms · حلقة المكافأة 1100ms · الاحتفال ≤ 1.4s · «تقليل الحركة» يلغي الحركة ويُبقي التلاشي.</div></div>
    </div>`; }
});

screen('statesGallery', { title:'معرض الحالات', group:'review',
  render:() => `${appbar('كل الحالات', {sub:'Default · Loading · Empty · Error · Offline · Denied · Success · Confirm'})}
    <div class="scroll" style="padding-bottom:24px">
      <div class="sec"><div class="banner info">${I('info','sm')}<span>كل شاشة في اللوحة عندها أزرار «حالات هذه الشاشة». هنا ملخص سريع.</span></div></div>
      <div class="sec-title">تحميل</div>${skeletonList(2)}
      <div class="sec-title">فارغ</div><div class="card" style="margin:0 16px">${stateBlock({icon:'history', title:'ما عندكش رحلات بعد', text:'أول رحلة تكملها تظهر هنا.', cta:'اطلب رحلة', ctaGo:'search'})}</div>
      <div class="sec-title">خطأ + إعادة المحاولة</div><div class="card" style="margin:0 16px">${stateBlock({icon:'alert', tone:'red', title:'تعذّر التحميل', text:'صار خلل مؤقت. بياناتك ما تضررتش.', cta:'إعادة المحاولة', ctaAct:'retry'})}</div>
      <div class="sec-title">بدون إنترنت / إنترنت ضعيف</div><div class="sec col" style="margin-top:0;gap:8px"><div class="offline-bar" style="border-radius:12px">${I('wifiOff','sm')} لا يوجد اتصال — نعرض آخر بيانات محفوظة</div><div class="banner warn">${I('wifiOff','sm')}<span><b>الإنترنت ضعيف…</b> نعيد إرسال طلبك (المحاولة 2 من 3). طلبك لن يتكرر ولن يضيع.</span></div></div>
      <div class="sec-title">رفض الإذن</div><div class="sec" style="margin-top:0"><div class="banner danger">${I('pin','sm')}<div class="grow">ما قدرناش نحدد موقعك. <b>فعّل الموقع</b> أو حدّد على الخريطة.</div></div></div>
      <div class="sec-title">نجاح</div><div class="card" style="margin:0 16px">${stateBlock({icon:'check', tone:'green', title:'تمت إضافة الرصيد', text:'تمت إضافة 50.00 د.ل إلى محفظتك.'})}</div>
      <div class="sec-title">تأكيد (نافذة)</div><div class="sec" style="margin-top:0"><button class="btn outline" data-act="cancelSearch">اعرض نافذة تأكيد الإلغاء</button></div>
      <div class="sec-title">معطّل</div><div class="sec" style="margin-top:0"><button class="btn primary disabled">اطلب · بانتظار السعر</button><div class="help center">نوضّح دائمًا ليش الزر معطّل</div></div>
    </div>`
});

const BA = [
  ['الرئيسية','الخريطة + 3 بطاقات (البيت/الشغل/مؤخرًا) + زر «رحلة بدون وجهة» + شريط بحث؛ بطاقة الحملة فيها سهم لكن ما تنضغطش؛ لا يوجد مدخل للرحلات القادمة أو مشوار الدوام.','«إلى أين؟» أكبر وأعلى، «الآن ▾» للجدولة داخل نفس الحقل، اختصاران: بدون وجهة ومشوار الدوام، شريط بطاقات: الموعد الجاي + حلقة 100 رحلة + الكوبون — كلها تنضغط.','home'],
  ['البحث عن وجهة','يبدأ البحث بعد 4 أحرف («اكتب 4 أحرف على الأقل»)، والنتائج في ورقة منفصلة عن حقول الرحلة.','حقلا الانطلاق والوجهة معًا مع تبديل، اقتراحات فورية قبل الكتابة، نتائج من حرفين مع تمييز، حالة «ما لقيناش» تقترح الخريطة، وضع بدون إنترنت يعرض المحفوظ.','search'],
  ['رحلة بدون وجهة','زر ← صفحة اختيار الانطلاق ← الحجز؛ ما يوضّحش كيف تُحسب الأجرة.','نفس المسار، مع شرح واضح «تقولها للسائق — الأجرة بالعداد» وعرض التعرفة قبل الطلب.','mappick'],
  ['اختيار السيارة والمفاوضة','بطاقات خدمة + سعر عادل/عرضك؛ الاقتصادي والمفاوضة يختلطوا على المستخدم الجديد.','مفتاح واضح «سعر ثابت | فاوض بسعرك»، مؤشر عدالة العرض مع نصيحة، شرائح أسعار جاهزة، 4 خيارات تحت (الدفع/الكوبون/الوقت/خيارات) بدل نوافذ متفرقة.','options'],
  ['البحث عن سائق','عدّة رسائل متتابعة («نوسّع نطاق البحث…»)، العروض كبطاقات.','3 مراحل تقدّم ثابتة، عدّاد وقت، عروض بعدّاد 15 ثانية وقبول/رفض، حالة «ما لقيناش» بخيارات (حاول/ارفع/جدولها).','searching'],
  ['السائق في الطريق','معلومات السائق والأزرار موزعة، الإلغاء بارز.','بطاقة سائق موحّدة (لوحة كبيرة)، 4 أزرار ثابتة (اتصال مجاني/رسالة/مشاركة/طوارئ)، الإلغاء رابط ثانوي مع أسباب ورسوم واضحة فقط عند تطبيقها.','found'],
  ['الرحلات القادمة','صفحتان: «حجوزاتك» و«الرحلات القادمة»؛ لا تظهر أيام مشوار الدوام.','صفحة واحدة موحّدة مع فلتر (الكل/مجدولة/مشوار الدوام)، حالة كل يوم بلون وأيقونة، عرض السائق قبول/رفض.','upcoming'],
  ['مشوار الدوام','غير موجود في التطبيق (الخادم جاهز).','قائمة + تفاصيل أسبوعية + تأكيد ✅/❌ + تخطي يوم + تغيير وقت يوم + إيقاف/استئناف/إلغاء + طلب جديد بـ3 خطوات.','recDetail'],
  ['مكافآتي','3 أرصدة + عملات + حملات بشريط خطي + إنجازات + حركات؛ لا توجد صفحة تفاصيل للحملة.','حلقة تقدّم كبيرة تنضغط ← صفحة الحملة: معالم، شروط الخادم، «ليش ما انحسبتش؟»، سجل الرحلات المحسوبة، الاحتفال، «في الطريق»، ثم الظهور في المحفظة.','campaign'],
  ['القائمة الجانبية','15 عنصر بدون تجميع؛ «هدية»، «خارج المحطة»، «إشعار» أسماء مربكة؛ شارات الإشعارات بيضاء على أبيض.','4 مجموعات (رحلاتي، فلوسي ومكافآتي، المساعدة والأمان، التطبيق)، رصيد وتقدّم المكافأة في الرأس، أسماء واضحة، شارات حمراء.','drawer'],
  ['المحفظة','رصيد واحد + قائمة؛ رصيد المشاوير مخفي في صفحة المكافآت.','رصيد كلي مقسوم (أموالك/رصيد مشاوير)، 4 إجراءات، فلاتر المعاملات، تفاصيل كل معاملة.','wallet'],
  ['محادثة الدعم','نص وصوت؛ لا تفاعلات ولا بطاقات إجراء.','ضغط مزدوج للتفاعل (بدون تكبير)، بطاقة ✅ أؤكد / ❌ لا، «معدّلة»، «تم حذف هذه الرسالة».','supportChat'],
  ['الإشعارات','قائمة مع حذف.','كل الإشعارات مع فلاتر وتجميع بالأيام، كل إشعار يفتح شاشته، «قراءة الكل».','notifications'],
  ['التسجيل','8 خطوات (الاسم، الدولة، المنطقة، البريد، كلمة المرور، الهاتف، الرمز، الجنس) + صفحة موافقة.','4 خطوات: الهاتف ← رمز واتساب ← الاسم (+اختياري) ← كلمة المرور والموافقة؛ المنطقة تلقائية.','signup']
];
screen('beforeAfter', { title:'قبل / بعد', group:'review',
  render:() => `${appbar('قبل / بعد', {sub:'التصميم الحالي (من الكود) مقابل المقترح'})}
    <div class="scroll" style="padding-bottom:24px">
      <div class="sec"><div class="banner info">${I('info','sm')}<span>«قبل» مبني على قراءة كود Flutter الحالي (بدون لقطات من المحاكي). اضغط «جرّب» لفتح الشاشة الجديدة، وسجّل رأيك من لوحة الملاحظات.</span></div></div>
      ${BA.map(([t,b,a,id]) => `<div class="sec"><div class="card"><div class="flex between"><span class="bold">${t}</span><button class="btn secondary sm" data-go="${id}">جرّب ${I('chevL','xs')}</button></div>
        <div class="ba mt8"><div class="small ink2 before" style="padding-inline-start:10px"><b style="color:var(--danger)">قبل:</b> ${b}</div><div class="small ink2 after" style="padding-inline-start:10px"><b style="color:var(--success)">بعد:</b> ${a}</div></div></div></div>`).join('')}
    </div>`
});

const COVER = [
  ['الاقتصادي (سعر ثابت)','options'],['المفاوضة (عرض السعر)','options'],['رحلة بدون وجهة','home → mappick → options'],['اختيار من الخريطة','mappick'],['البيت والعمل والأخيرة','home / search'],['الكوبون والهدية','options → كوبون'],['طريقة الدفع (نقد/محفظة/محفظة+نقد)','options → الدفع'],['الأمتعة والحيوان الأليف','options → خيارات'],['الطلب لشخص آخر','options → خيارات'],['الجدولة (Ride Later)','«الآن ▾» في الرئيسية/البحث/الحجز'],['سواقيني عند الطلب','options (اطلبه أولًا)'],['البحث عن سائق + الإنترنت الضعيف','searching'],['عدم وجود سائق','searching (حالة)'],['قبول عرض سائق','searching'],['عرض استرجاع رحلة سابقة','home (بطاقة الاسترجاع — كما هي)'],['تتبع السائق + وصل','found'],['الاتصال المجاني CallKit + الرسائل الصوتية','call / tripChat'],['مشاركة الرحلة','found / ontrip'],['SOS','found / ontrip / sos'],['الإلغاء بالأسباب والرسوم','found → إلغاء'],['تعديل الوجهة (مقترح)','ontrip'],['الفاتورة','invoice'],['التقييم + الأوسمة + الهدية الذهبية','rate'],['الرحلات القادمة (موحّدة)','upcoming'],['عروض السائقين للمجدولة','upcoming / schedDetail'],['إعادة الجدولة وإلغاء المجدولة','schedDetail'],['رحلاتي المتكررة / مشوار الدوام','recurring / recDetail'],['تأكيد ✅/❌','recConfirm / supportChat'],['تخطي يوم / تغيير وقت يوم','recDetail → اليوم'],['إيقاف/استئناف/إلغاء','recDetail'],['مكافآت 100 رحلة','rewards / campaign'],['العملات الذهبية والتحويل','rewards → العملات'],['الأرصدة الثلاثة','rewards / wallet'],['الإنجازات وسجل المكافآت','rewards'],['إيقاف عروض التسويق','rewards'],['المحفظة والمعاملات','wallet / transactions'],['الشحن بمعاملات + التعبئة الذكية','topup / checkout'],['بطاقة الشحن','wallet → إضافة فلوس'],['تحويل الأموال','wallet → تحويل'],['بطاقاتي (على الجهاز)','savedCards'],['الهدايا والإحالة','gifts'],['الإشعارات كلها','notifications'],['دعم العملاء + المحادثة','support / supportChat'],['التفاعلات والرسائل المعدلة/المحذوفة','supportChat'],['الشكاوى','complaint'],['سجل المكالمات','callLog'],['جهات الثقة','sos'],['الملف الشخصي والصورة','profile'],['السجل وتفاصيل الرحلة','history / histDetail'],['صفحة السائق والإبلاغ والحظر','driverProfile'],['عناويني المفضلة','favAddr'],['بين المدن (Outstation)','outstation'],['الإعدادات والمظهر وحذف الحساب','settings'],['اللغة','language'],['الدخول / الاستعادة / التسجيل / OTP واتساب','login / forgot / signup'],['هدية التسجيل','signup → الإذن → الرئيسية'],['إذن الموقع ورفضه','permission / home'],['التحديث الإجباري','update'],['بدون إنترنت','offline'],['التعريف (Onboarding)','onboarding'],['أجار بالساعة / توصيل أغراض','تبقى كما هي في الكود (حسب التفعيل) — راجع الوثيقة']
];
screen('coverage', { title:'خريطة التغطية (لا شيء محذوف)', group:'review',
  render:() => `${appbar('لا شيء محذوف', {sub:`${COVER.length} وظيفة موجودة ← مكانها في التصميم الجديد`})}
    <div class="scroll" style="padding-bottom:24px"><div class="sec"><table class="cov card" style="padding:0"><tr><th>الوظيفة</th><th>مكانها الجديد</th></tr>
      ${COVER.map(([f,w]) => { const id = w.split(/[ /→(]/)[0]; return `<tr><td>${I('check','xs')} ${f}</td><td>${SCREENS[id]?`<button class="link small" data-go="${id}">${w}</button>`:`<span class="small">${w}</span>`}</td></tr>`; }).join('')}</table></div></div>`
});
