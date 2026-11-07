/* Boot */
'use strict';
(function(){
  const saved = {};
  try { ['concept','theme','reduced','font'].forEach(k => { const v = localStorage.getItem('tx-'+k); if (v) saved[k] = v; }); } catch(e){}
  try { if (matchMedia('(prefers-reduced-motion: reduce)').matches && !saved.reduced) saved.reduced = '1'; } catch(e){}
  const q = new URLSearchParams(location.search);
  ['concept','theme','reduced','font'].forEach(k => { if (q.get(k)) saved[k] = q.get(k); });
  Studio.init();
  Object.entries(saved).forEach(([k,v]) => Studio.set(k, v));
  let id = (location.hash||'').slice(1) || q.get('screen') || 'splash';
  if (!SCREENS[id]) id = 'splash';
  if (q.get('sim')) P.sim = q.get('sim');
  if (id === 'drawer'){ go('home', {}, {root:true, fade:true}); setTimeout(openDrawer, 80); }
  else go(id, {}, {root:true, fade:true});
  if (q.get('sheet') && SHEETS[q.get('sheet')]) setTimeout(() => SHEETS[q.get('sheet')]({}), 200);
})();
