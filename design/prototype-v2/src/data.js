/* SAMPLE DATA ONLY — fictional people and amounts, Misrata place names for realism. */
const ME = { name:'أحمد علي', first:'أحمد', phone:'+218 91 000 0000', email:'ahmed@example.ly', since:'2024' };
const PLACES = [
  {id:'home', name:'البيت', addr:'الزروق، قرب جامع الزروق', pt:'home', kind:'home'},
  {id:'work', name:'الشغل', addr:'جامعة مصراتة — البوابة الرئيسية', pt:'work', kind:'work'},
  {id:'hospital', name:'مستشفى مصراتة المركزي', addr:'شارع بنغازي', pt:'hospital'},
  {id:'square', name:'ميدان النصر', addr:'وسط المدينة', pt:'square'},
  {id:'corniche', name:'كورنيش مصراتة', addr:'الطريق الساحلي', pt:'corniche'},
  {id:'airport', name:'مطار مصراتة الدولي', addr:'الكراريم', pt:'airport'},
  {id:'port', name:'ميناء قصر أحمد', addr:'قصر أحمد', pt:'port'},
  {id:'oldmarket', name:'سوق المدينة القديمة', addr:'وسط البلاد', pt:'oldmarket'},
  {id:'mall', name:'المجمع التجاري', addr:'طريق الزروق', pt:'mall'},
  {id:'ghiran', name:'الغيران', addr:'حي الغيران', pt:'ghiran'},
  {id:'stadium', name:'الملعب البلدي', addr:'شارع طرابلس', pt:'stadium'},
  {id:'tripoli', name:'شارع طرابلس', addr:'مصراتة', pt:'tripoli'}
];
const RECENT = ['hospital','square','oldmarket','airport'];
const placeById = id => PLACES.find(p => p.id===id) || {id, name:'موقعك الحالي', addr:'الزروق — قرب البيت', pt:'me'};
const VEHICLES = [ // sample services; in the app each comes from the server with its own icon and pricing_mode
  {id:'eco', name:'اقتصادي', seats:'4 ركاب', eta:3, fare:12.5, img:'carSide', popular:true},
  {id:'std', name:'عادي', seats:'4 ركاب', eta:5, fare:15.0, img:'carYellow', bid:true},
  {id:'van', name:'عائلي', seats:'7 ركاب', eta:9, fare:22.0, img:'carSide'}
];
const DRIVERS = {
  a:{id:11, name:'عبدالسلام', full:'عبدالسلام م.', rating:4.9, rides:1240, car:'هيونداي إلنترا', color:'أبيض', plate:'5-123456', ini:'ع'},
  b:{id:12, name:'سالم', full:'سالم ك.', rating:4.8, rides:860, car:'كيا سيراتو', color:'فضي', plate:'5-654321', ini:'س'},
  c:{id:13, name:'مصطفى', full:'مصطفى ب.', rating:4.7, rides:410, car:'تويوتا كورولا', color:'رمادي', plate:'5-246810', ini:'م'}
};
const OFFERS = [ {d:'b', price:13.0, eta:4}, {d:'c', price:12.0, eta:6} ];
const CANCEL_REASONS = ['السائق تأخّر كثير','غيّرت رأيي','السائق طلب مني ألغي','حطّيت مكان غلط','لقيت مواصلة ثانية','سبب آخر'];
const HISTORY = [
  {id:'R-2041', date:'اليوم 08:12', from:'البيت', to:'الشغل', fare:10.0, pay:'نقدًا', st:'done', d:'a', veh:'اقتصادي'},
  {id:'R-2033', date:'أمس 18:40', from:'المجمع التجاري', to:'البيت', fare:9.5, pay:'المحفظة', st:'done', d:'b', veh:'اقتصادي'},
  {id:'R-2019', date:'الثلاثاء 13:05', from:'ميدان النصر', to:'مستشفى مصراتة المركزي', fare:7.0, pay:'نقدًا', st:'cancelled', d:null, veh:'عادي', reason:'غيّرت رأيي'},
  {id:'R-1998', date:'الأحد 21:15', from:'كورنيش مصراتة', to:'البيت', fare:11.0, pay:'نقدًا', st:'done', d:'c', veh:'اقتصادي'},
  {id:'R-1980', date:'السبت 07:20', from:'البيت', to:'مطار مصراتة الدولي', fare:25.0, pay:'المحفظة + نقدًا', st:'done', d:'a', veh:'عادي'}
];
const NOTIFS = [
  {t:'مشوار الدوام غدوة', b:'غدوة السبت 07:15 من البيت للشغل. السائق يتحدد قبل الموعد.', at:'منذ 5 دقائق', ic:'repeat', tone:'brand', unread:true, go:'recDetail'},
  {t:'باقي 37 رحلة على مكافأتك', b:'أكملت 63 من 100 رحلة في حملة «100 رحلة = 100 دينار».', at:'منذ ساعة', ic:'trophy', tone:'gold', unread:true, go:'campaign'},
  {t:'ردّ دعم تاكسيستا', b:'تمام، فعّلنالك مشوار الدوام. أكّد من الرسالة.', at:'اليوم 10:02', ic:'headset', tone:'green', unread:true, go:'supportChat'},
  {t:'تمت إضافة 50.00 د.ل', b:'شحن المحفظة بالبطاقة المصرفية (معاملات).', at:'أمس', ic:'wallet', tone:'green', go:'wallet'},
  {t:'عرض جديد لرحلتك المجدولة', b:'سالم عرض 13.00 د.ل لرحلة الأحد 06:30 للمطار.', at:'أمس', ic:'car', tone:'brand', go:'upcoming'},
  {t:'كوبون «مصراتة5»', b:'خصم 5 د.ل على رحلتك الجاية لين 30 نوفمبر.', at:'الإثنين', ic:'tag', tone:'gold', go:'gifts'},
  {t:'كيف كانت رحلتك مع مصطفى؟', b:'قيّم رحلتك من الكورنيش.', at:'الأحد', ic:'star', tone:'', go:'histDetail'}
];
const TXNS = [
  {t:'رحلة R-2033', s:'خصم من المحفظة', v:-9.5, at:'أمس 18:58', k:'debit', ic:'car'},
  {t:'شحن بالبطاقة المصرفية', s:'معاملات · مرجع TX-88412', v:50, at:'أمس 12:10', k:'credit', ic:'card'},
  {t:'مكافأة حملة العودة', s:'رصيد مشاوير · للرحلات فقط', v:5, at:'الإثنين', k:'reward', ic:'trophy'},
  {t:'تحويل إلى +218 92 *** 1122', s:'تحويل أموال', v:-10, at:'الأحد', k:'debit', ic:'send'},
  {t:'رحلة R-1980', s:'المحفظة + نقدًا', v:-15, at:'السبت', k:'debit', ic:'car'},
  {t:'هدية ترحيبية', s:'رصيد مشاوير · أول رحلة', v:10, at:'أكتوبر', k:'reward', ic:'gift'}
];
const UPCOMING = [
  {id:'S-31', kind:'rec', day:'غدًا · السبت', date:'2026-11-07', time:'07:15', from:'البيت', to:'الشغل', st:'reserved', label:'سائق حجز الموعد', d:'a', price:8.0},
  {id:'S-29', kind:'sched', day:'الأحد 8 نوفمبر', date:'2026-11-08', time:'06:30', from:'البيت', to:'مطار مصراتة الدولي', st:'offer', label:'عرض سائق بانتظارك', d:'b', price:13.0, offer:true},
  {id:'S-32', kind:'rec', day:'الأحد 8 نوفمبر', date:'2026-11-08', time:'07:15', from:'البيت', to:'الشغل', st:'scheduled', label:'مجدول', price:8.0},
  {id:'S-33', kind:'rec', day:'الإثنين 9 نوفمبر', date:'2026-11-09', time:'07:45', from:'البيت', to:'الشغل', st:'scheduled', label:'مجدول · وقت معدّل', price:8.0, moved:true},
  {id:'S-30', kind:'sched', day:'الخميس 12 نوفمبر', date:'2026-11-12', time:'19:00', from:'البيت', to:'كورنيش مصراتة', st:'dispatching', label:'متاحة للسائقين', price:11.0}
];
const REC_DAYS = [ // the week of the agreement (Sat..Fri), sample
  {day:'السبت', date:'7 نوف', st:'reserved', label:'سائق حجز الموعد', time:'07:15'},
  {day:'الأحد', date:'8 نوف', st:'scheduled', label:'مجدول', time:'07:15'},
  {day:'الإثنين', date:'9 نوف', st:'scheduled', label:'مجدول · الوقت 07:45', time:'07:45'},
  {day:'الثلاثاء', date:'10 نوف', st:'skipped', label:'تم التخطي', time:'07:15'},
  {day:'الأربعاء', date:'11 نوف', st:'scheduled', label:'مجدول', time:'07:15'},
  {day:'الخميس', date:'12 نوف', st:'scheduled', label:'مجدول', time:'07:15'},
  {day:'الجمعة', date:'13 نوف', st:'off', label:'ما فيش مشوار', time:''}
];
const REC_PAST = [
  {day:'الخميس', date:'5 نوف', st:'completed', label:'مكتملة', time:'07:15'},
  {day:'الأربعاء', date:'4 نوف', st:'completed', label:'مكتملة', time:'07:15'},
  {day:'الثلاثاء', date:'3 نوف', st:'no_driver', label:'تعذر توفير سائق — ما عليك أي رسوم', time:'07:15'}
];
const DAY_STATE = { // backend dayState() -> visual
  scheduled:['مجدول','brand','clock'], searching:['نبحث عن سائق','warn','search'], reserved:['سائق حجز الموعد','brand','user'],
  driver_ready:['السائق أكد استعداده','green','check'], driver_on_way:['السائق في الطريق','green','car'], trip_started:['الرحلة بدأت','green','route'],
  completed:['مكتملة','green','check'], skipped:['تم التخطي','', 'skip'], cancelled:['ألغيت','red','x'], no_driver:['تعذر توفير سائق','red','alert'], failed:['ما تجهزتش','red','alert'], off:['—','','minus'],
  offer:['عرض سائق بانتظارك','gold','tag'], dispatching:['متاحة للسائقين','warn','search']
};
const COUPONS = [
  {code:'مصراتة5', v:'5.00 د.ل', s:'على رحلة واحدة · لين 30 نوفمبر', ok:true},
  {code:'WEEKEND', v:'10%', s:'حتى 3 د.ل · الجمعة والسبت', ok:true},
  {code:'RAMADAN', v:'15%', s:'انتهى', ok:false}
];
const FAQ = ['كيف نحسب سعر الرحلة؟','كيف نشحن المحفظة بالبطاقة؟','وش يصير لو ما لقيتش سائق للرحلة المجدولة؟','كيف نضيف سائق لسواقيني؟','كيف تُحسب مكافأة 100 رحلة؟'];
const CALLS = [
  {who:'عبدالسلام (سائق)', dir:'out', at:'اليوم 08:03', dur:'0:42', free:true},
  {who:'دعم تاكسيستا', dir:'missed', at:'أمس 16:20', dur:'', free:true},
  {who:'سالم (سائق)', dir:'in', at:'أمس 18:31', dur:'1:10', free:true},
  {who:'دعم تاكسيستا', dir:'out', at:'الإثنين', dur:'3:05', free:true}
];
const TRUSTED = [{n:'أخوي محمد', p:'+218 91 *** 4411'},{n:'الوالدة', p:'+218 92 *** 0090'}];
