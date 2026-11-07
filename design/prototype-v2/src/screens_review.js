/* Review screens for the owner: what changed vs today, the motion list, coverage, tokens. */
'use strict';
const CHANGES = [
  ['الرئيسية','نفس الخريطة والشخصية والبطاقات الثلاث وزر «رحلة بدون وجهة» وشريط البحث. أضفنا: «إلى أين؟» بخط أوضح، زر «الآن» للجدولة، بطاقة المكافأة صارت تنفتح وفيها حلقة تقدّم، بطاقة الموعد الجاي تشمل مشوار الدوام، واختصار «مشوار الدوام».','home'],
  ['اختيار السيارة','نفس بطاقات الخدمة (حواف 22، إطار أزرق للمختارة، «الأكثر طلبًا»، «السعر العادل»، «عرضك»). أضفنا: عدّاد ± للعرض داخل البطاقة مع مؤشر العدالة، الأسعار تعدّ لما تختار، وشبكة الدفع/الكوبون/الوقت/التفضيلات بأيقونات التطبيق.','options'],
  ['البحث عن سائق','نفس العنوان «قريبًا سيتم قبول طلبك» وعروض السائقين و«يشاهدون الطلب الآن». أضفنا: نبض حول نقطة اللقاء، مراحل 3 وعدّاد وقت، العروض تدخل كبطاقات قابلة للسحب مع مؤقت.','searching'],
  ['السائق والرحلة','نفس بيانات السائق واللوحة والاتصال والدردشة والمشاركة والطوارئ. أضفنا: السيارة تتحرك على الطريق، وقت الوصول يعدّ تنازليًا، شريط تقدّم، إلغاء بأسباب ورسوم عند تطبيقها فقط.','found'],
  ['القائمة الجانبية','نفس بطاقة الملف الزرقاء ونفس أيقونات التطبيق. أضفنا: تجميع في 4 أقسام، أسماء أوضح، عدّادات حمراء ظاهرة، الرصيد والتقدّم في الرأس، «رحلاتي المتكررة».','drawer'],
  ['مكافآتي','نفس الأرصدة الثلاثة والعملات والإنجازات. أضفنا: بطاقة 100 رحلة بحلقة كبيرة تنفتح لصفحة تفاصيل فيها الشروط، «ليش ما انحسبتش؟»، والاحتفال عند الوصول.','rewards'],
  ['الرحلات القادمة','كانت صفحتين («حجوزاتك» و«الرحلات القادمة») بدون أيام مشوار الدوام. صارت صفحة واحدة بفلتر.','upcoming'],
  ['رحلاتي المتكررة','جديدة: التأكيد ✅/❌، تخطي يوم، تغيير وقت يوم، إيقاف واستئناف وإلغاء.','recDetail'],
  ['محادثة الدعم','نفس الفقاعات والرسائل الصوتية. أضفنا: بطاقة ✅ أؤكد / ❌ لا، تفاعلات بالضغط مرتين، «معدّلة» و«تم حذف هذه الرسالة».','supportChat'],
  ['الإشعارات','كل الإشعارات مع فلاتر وسحب للحذف، ومثال الإشعار التفاعلي بزرّين.','notifications']
];
screen('changes', { title:'ما الذي تغيّر عن اليوم', group:'review',
  render:() => `${appbar('ما الذي تغيّر؟', {sub:'نفس هوية التطبيق — تطوير هادئ'})}
    <div class="scroll stagger" style="padding-bottom:24px">
      <div class="sec"><div class="banner info">${I('info','sm')}<span>في الشاشات المعلّمة يظهر أسفلها زر <b>الحالي / المطوّر</b> للمقارنة. «الحالي» مبني من كود التطبيق، وليس لقطة من الهاتف.</span></div></div>
      ${CHANGES.map(([t,d,id]) => `<div class="sec"><div class="card"><div class="flex between"><b>${t}</b><button class="btn secondary sm" style="height:36px" data-go="${id}">جرّب ${I('chevL','xs')}</button></div><p class="small ink2" style="margin:8px 0 0;line-height:1.8">${d}</p></div></div>`).join('')}
    </div>`
});
const MOTION = [
  ['انتقال الصفحات (من اليسار في العربي) والرجوع بالسحب من حافة الشاشة اليمنى','history',''],
  ['ورقة سفلية تنسحب لتحت وتقفل، أو ترجع بنعومة','options','sheet:coupon'],
  ['ورقة الحجز تنطوي وتفتح بالضغط أو السحب على المقبض','options',''],
  ['دبوس الخريطة يرتفع أثناء السحب وينزل بارتداد','mappick',''],
  ['الدبابيس تسقط والمسار ينرسم على الخريطة','options',''],
  ['نبض البحث عن سائق + صور السائقين تظهر واحدة واحدة','searching',''],
  ['عروض السائقين تدخل كبطاقات بمؤقت 20 ثانية','searching','offer'],
  ['السيارة تتحرك على الطريق والوقت يعدّ تنازليًا','found',''],
  ['الأسعار والأرصدة تعدّ للرقم','wallet',''],
  ['عدّاد العرض ± ينبض ومؤشر العدالة ينزلق','options','offer'],
  ['استجابة الضغط (تصغير بسيط + موجة)','home',''],
  ['هيكل التحميل (Skeleton)','history','sim:loading'],
  ['علامة نجاح تنرسم','checkout','sim:success'],
  ['احتفال 100 رحلة (قصاصات)','campaign','act:rwReach'],
  ['سحب الإشعار لحذفه','notifications',''],
  ['التفاعل بالضغط مرتين في المحادثة (انفجار رموز)','supportChat',''],
  ['إشعار ينزل من فوق بزرّين ✅ / ⏭️','home','act:demoActionPush'],
  ['النجوم تقفز عند التقييم','rate',''],
  ['حلقة المكافأة تمتلئ','campaign','']
];
screen('motion', { title:'كل الحركات (جرّبها)', group:'review',
  render:() => `${appbar('الحركات والتفاعلات', {sub:'اضغط أي سطر لتجربته'})}
    <div class="scroll" style="padding-bottom:24px"><div class="sec"><div class="list stagger">${MOTION.map(([t,id,x],i) => `<button class="li" data-act="tryMotion" data-i="${i}"><span class="ic brand">${I('play','sm')}</span><span class="tx"><span class="t" style="white-space:normal">${t}</span></span>${I('chevL','sm')}</button>`).join('')}</div></div>
    <p class="sec tiny muted">«تقليل الحركة» في اللوحة (أو إعداد الهاتف) يوقف الحركات ويُبقي التلاشي فقط.</p></div>`
});
ACTS.tryMotion = (t) => { const [, id, x] = MOTION[+t.dataset.i];
  if (x==='offer'){ Object.assign(B(), {veh:'std', mode:'offer', offer:15, drop:B().drop||'square', noDest:false}); }
  if (x.startsWith('sim:')) P.sim = x.slice(4); else P.sim = 'default';
  if (!B().drop && (id==='options'||id==='searching')) B().drop = 'square';
  if (id==='found') P.driver = 'a';
  go(id);
  if (x.startsWith('sheet:')) later(() => SHEETS[x.slice(6)]({}), 500);
  if (x.startsWith('act:')) later(() => ACTS[x.slice(4)](), 700);
};

screen('designSystem', { title:'الألوان والمكوّنات', group:'review',
  render:() => { const sw = (n, v, t) => `<div class="swatch"><i style="background:${v}"></i><div><div class="small bold">${n}</div><div class="tiny muted kbd">${t}</div></div></div>`;
    return `${appbar('الهوية والمكوّنات', {sub:'من ألوان التطبيق نفسه (styles.dart)'})}
    <div class="scroll" style="padding-bottom:24px">
      <div class="sec ds-grid">${sw('الأزرق الأساسي','var(--brand)','#0873FF theme')}${sw('كحلي البطاقات','#102A56','#102A56 → #1965BF')}${sw('العمل','var(--work)','#2381E9')}${sw('مؤخرًا / نجاح','var(--recent)','#14A47B')}${sw('النص','var(--ink)','#12121D textColor')}${sw('الرمادي','var(--ink-3)','#7B8BA8')}${sw('الذهبي','var(--gold)','#B7791F / #F6D365')}${sw('خطر','var(--danger)','#E0243A')}</div>
      <div class="sec"><div class="card small" style="line-height:1.9">الخط: <b>Cairo</b> (نفس MyText في التطبيق)، والأرقام <b>Noto Sans</b>. الحواف: البطاقات 20–22، شريط البحث 24، الأوراق 30، الأزرار 16. الظلال: نفس ارتفاع البطاقات العائمة الحالية.</div></div>
      <div class="sec col" style="gap:8px"><button class="btn primary">زر أساسي</button><button class="btn secondary">ثانوي</button><button class="btn outline">محدد</button><button class="btn danger">إلغاء</button></div>
      <div class="sec"><div class="quick">${[['home','البيت','var(--brand)'],['work','الشغل','var(--work)'],['history','مؤخراً','var(--recent)']].map(([ic,t,c]) => `<div class="qd"><span class="soft" style="background:color-mix(in srgb, ${c} 12%, transparent);color:${c}">${I(ic,'sm')}</span><span class="t">${t}</span><span class="s">بطاقة سريعة</span></div>`).join('')}</div></div>
      <div class="sec">${skeletonList(1).replace('<div class="sec">','<div>')}</div>
      <div class="sec flex" style="flex-wrap:wrap;gap:8px"><span class="tag brand">brand</span><span class="tag green">نجاح</span><span class="tag warn">تنبيه</span><span class="tag red">خطأ</span><span class="tag gold">مكافأة</span></div>
    </div>`; }
});

const COVER = [
  ['الاقتصادي (سعر ثابت)','options'],['المفاوضة (السعر العادل + عرضك)','options'],['رحلة بدون وجهة','mappick'],['اختيار من الخريطة','mappick'],['البيت والعمل والأخيرة','home'],['الكوبون والهدية','options'],['طريقة الدفع','options'],['الأمتعة ولشخص آخر','options'],['الجدولة','options'],['سواقيني عند الطلب','options'],['البحث عن سائق + الإنترنت الضعيف','searching'],['عدم وجود سائق','searching'],['قبول عرض سائق','searching'],['عرض استرجاع رحلة','home'],['تتبع السائق ووصل','found'],['الاتصال المجاني والرسائل الصوتية','call'],['المشاركة والطوارئ','found'],['الإلغاء بالأسباب','found'],['الفاتورة','invoice'],['التقييم وسواقيني والهدية الذهبية','rate'],['الرحلات القادمة الموحّدة','upcoming'],['تفاصيل المجدولة وعروضها','schedDetail'],['رحلاتي المتكررة','recurring'],['تأكيد ✅/❌','recConfirm'],['تخطي يوم / تغيير وقته / إيقاف / استئناف / إلغاء','recDetail'],['مكافأة 100 رحلة','campaign'],['العملات والأرصدة والإنجازات','rewards'],['المحفظة والمعاملات والتحويل','wallet'],['الشحن بمعاملات','topup'],['بطاقاتي','savedCards'],['الهدايا والإحالة','gifts'],['الإشعارات','notifications'],['الدعم والمحادثة والتفاعلات','supportChat'],['الشكاوى','complaint'],['سجل المكالمات','callLog'],['جهات الثقة','sos'],['الملف الشخصي','profile'],['السجل وتفاصيله','history'],['صفحة السائق والإبلاغ','driverProfile'],['العناوين المفضلة','favAddr'],['بين المدن','outstation'],['الإعدادات وحذف الحساب','prefs'],['اللغة','language'],['الدخول والاستعادة والتسجيل ورمز واتساب','login'],['هدية التسجيل','agreement'],['إذن الموقع','permission'],['التحديث','update'],['بدون إنترنت','offline']
];
screen('coverage', { title:'لا شيء محذوف', group:'review',
  render:() => `${appbar('لا شيء محذوف', {sub:`${COVER.length} وظيفة موجودة ← مكانها`})}
    <div class="scroll" style="padding-bottom:24px"><div class="sec"><div class="list">${COVER.map(([f,id]) => `<button class="li" data-go="${id}"><span class="ic green">${I('check','sm')}</span><span class="tx"><span class="t" style="white-space:normal">${f}</span></span>${I('chevL','sm')}</button>`).join('')}</div></div></div>`
});
