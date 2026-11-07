/* Boot */
'use strict';
(function(){
  document.documentElement.lang = 'ar'; document.documentElement.dir = 'rtl';
  const saved = {};
  try { ['theme','reduced'].forEach(k => { const v = localStorage.getItem('tx-'+k); if (v) saved[k] = v; }); } catch(e){}
  try { if (matchMedia('(prefers-reduced-motion: reduce)').matches && !saved.reduced) saved.reduced = '1'; } catch(e){}
  Studio.init();
  Object.entries(saved).forEach(([k,v]) => Studio.set(k, v));
  let id = (location.hash||'').slice(1);
  if (id === 'settings') id = 'prefs';
  if (!SCREENS[id]) id = 'home';
  if (id === 'drawer'){ go('home', {}, {root:true, fade:true}); setTimeout(openDrawer, 80); }
  else go(id, {}, {root:true, fade:true});
  addEventListener('hashchange', () => { let h = (location.hash||'').slice(1); if (h==='settings') h='prefs'; if (SCREENS[h] && h !== P.screen) go(h, {}, {root:true, fade:true}); });
  let seen = false; try { seen = localStorage.getItem('tx-intro') === '1'; } catch(e){}
  if (!seen && id === 'home') setTimeout(() => {
    openSheet(`<div class="center"><img src="${IMG.driverMascot}" alt="" width="96" style="animation:popIn .6s var(--ease-spring) both"><h3 class="mt8">هذا نموذج تاكسيستا المطوّر</h3>
      <p class="sheet-sub">نفس شكل التطبيق اليوم، مع حركة وتفاصيل أنظف. كل شي ينضغط. البيانات تجريبية ولا يُرسل أي طلب.</p></div>
      <div class="list"><div class="li"><span class="ic brand">${I('search','sm')}</span><span class="tx"><span class="t" style="white-space:normal">اضغط «إلى أين؟» واطلب رحلة للنهاية</span></span></div>
      <div class="li"><span class="ic brand">${I('menu','sm')}</span><span class="tx"><span class="t" style="white-space:normal">القائمة الجانبية: مكافآتي، المحفظة، رحلاتي المتكررة…</span></span></div>
      <div class="li"><span class="ic brand">${I('layers','sm')}</span><span class="tx"><span class="t" style="white-space:normal">زر «الحالي / المطوّر» أسفل بعض الشاشات للمقارنة</span></span></div>
      <div class="li"><span class="ic brand">${I('list','sm')}</span><span class="tx"><span class="t" style="white-space:normal">زر ☰ الصغير: كل الشاشات والحالات والملاحظات</span></span></div></div>
      <button class="btn primary mt12" onclick="closeSheet()">يلا نجرّب</button>`, {onClose:() => { try { localStorage.setItem('tx-intro','1'); } catch(e){} }});
  }, 700);
})();
