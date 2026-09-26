import 'dart:convert';

/// The origins whose payment form Smart Fill may ever touch: the Moamalat
/// gateway's checkout, exactly (scheme + host + port). Nothing else - no
/// wildcard, no other subdomain, no other port.
const List<String> kMoamalatGatewayOrigins = ['https://npg.moamalat.net:6006'];

/// The script the native layer installs in every frame of the payment web view
/// (iOS: `WKUserScript(forMainFrameOnly: false)` in an isolated `WKContentWorld`;
/// Android: `addDocumentStartJavaScript` with these exact origin rules).
///
/// What it does, and does not do:
///  * Runs its own origin check inside each frame and does NOTHING (no
///    listeners, no observers, no globals) unless the frame's origin is one of
///    [origins].
///  * Reports only "a card form is on screen" / "gone" - never any value.
///  * Fills only when native code calls `__tfFill(...)` after the customer's tap,
///    and only if that frame's own document has the card-form fingerprint
///    (PAN + expiry + a CVV-like field, distinct, in that order, in one form).
///  * Fills card number, expiry and name, and - only when asked - ticks the
///    payment-terms checkbox of that form. It never touches the CVV field, never
///    presses a button, never submits, never stores or logs a value.
String buildCardFillScript(List<String> origins) => _template.replaceFirst('__TF_ORIGINS__', jsonEncode(origins));

const String _template = r'''
(function () {
  'use strict';
  var ORIGINS = __TF_ORIGINS__;
  var W = window;

  function post(m) {
    try {
      if (W.webkit && W.webkit.messageHandlers && W.webkit.messageHandlers.taxistaFill) {
        W.webkit.messageHandlers.taxistaFill.postMessage(m);
      } else if (W.taxistaFill && typeof W.taxistaFill.postMessage === 'function') {
        W.taxistaFill.postMessage(JSON.stringify(m));
      }
    } catch (e) { }
  }

  // 1. origin gate - exact match, checked by the frame about itself.
  if (ORIGINS.indexOf(W.location.origin) < 0) return;

  // 2. conservative field detection
  var RX = {
    pan: /card\s*-?\s*n(?:um|o)|cc-?num|رقم\s*البطاقة|(?:x|X|•|\*|#){4}\s?(?:x|X|•|\*|#){4}/,
    exp: /\bexp|expir|mm\s*\/\s*yy|انتهاء|الصلاحية/i,
    cvv: /cvv|cvc|csc|security\s*code|الرمز|رمز\s*الأمان|^\s*(?:\*|•){3,4}\s*$/i,
    name: /name\s*on\s*card|card\s*-?\s*holder|holder|الاسم\s*على\s*البطاقة|اسم\s*حامل/i,
    terms: /terms|conditions|agree|accept|الشروط|الاحكام|الأحكام|اوافق|أوافق/i,
    notTerms: /save|remember|حفظ|تذكر/i,
    invalid: /(?:^|\s)(?:ng-invalid|p-invalid|is-invalid)(?:\s|$)/
  };
  var TEXTUAL = { text: 1, tel: 1, number: 1, password: 1, '': 1 };

  function visible(el) {
    var r = el.getBoundingClientRect();
    if (r.width < 4 || r.height < 4) return false;
    var s = W.getComputedStyle(el);
    return s.visibility !== 'hidden' && s.display !== 'none';
  }
  function usable(el) { return TEXTUAL[(el.type || '').toLowerCase()] === 1 && !el.disabled && !el.readOnly && visible(el); }
  function nearText(el) {
    var t = '';
    if (el.labels && el.labels.length) { for (var i = 0; i < el.labels.length; i++) t += ' ' + el.labels[i].textContent; }
    t += ' ' + (el.getAttribute('aria-label') || '');
    var c = el.parentElement;
    for (var d = 0; d < 4 && c && c !== document.body; d++, c = c.parentElement) {
      var txt = (c.textContent || '').replace(/\s+/g, ' ').trim();
      if (txt && txt.length < 60) { t += ' ' + txt; break; }
    }
    return t;
  }
  function score(el, role) {
    var s = 0, ac = (el.getAttribute('autocomplete') || '').toLowerCase(), idn = (el.id || '') + ' ' + (el.name || ''),
        ph = el.placeholder || '', lab = nearText(el), ml = parseInt(el.getAttribute('maxlength'), 10) || 0, ty = el.type || '';
    if (role === 'pan') {
      if (ac === 'cc-number') s += 5; if (RX.pan.test(idn)) s += 3; if (RX.pan.test(ph)) s += 3; if (RX.pan.test(lab)) s += 2;
      if (ml >= 16 && ml <= 23) s += 1; if (ty === 'password') s -= 9;
    } else if (role === 'exp') {
      if (ac === 'cc-exp') s += 5; if (RX.exp.test(idn)) s += 3; if (RX.exp.test(ph)) s += 3; if (RX.exp.test(lab)) s += 2;
      if (ml >= 4 && ml <= 7) s += 1; if (ty === 'password') s -= 9;
    } else if (role === 'cvv') {
      if (ac === 'cc-csc') s += 5; if (RX.cvv.test(idn)) s += 3; if (RX.cvv.test(ph)) s += 3; if (RX.cvv.test(lab)) s += 2;
      if (ty === 'password') s += 2; if (ml >= 3 && ml <= 4) s += 1;
    } else if (role === 'name') {
      if (ac === 'cc-name') s += 5; if (RX.name.test(idn)) s += 3; if (RX.name.test(ph)) s += 3; if (RX.name.test(lab)) s += 3;
      if (ty !== 'text') s -= 9;
    }
    return s;
  }
  function pick(list, role, exclude) {
    var best = null, bestScore = 0, tie = false;
    list.forEach(function (el) {
      if (exclude.indexOf(el) >= 0) return;
      var s = score(el, role);
      if (s > bestScore) { best = el; bestScore = s; tie = false; } else if (s === bestScore && s > 0) { tie = true; }
    });
    return bestScore >= 3 && !tie ? best : null;
  }
  function follows(a, b) { return !!(a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING); }

  function scan() {
    var inputs = Array.prototype.slice.call(document.querySelectorAll('input')).filter(usable);
    var cvv = pick(inputs, 'cvv', []);
    var pan = pick(inputs, 'pan', [cvv]);
    var exp = pick(inputs, 'exp', [cvv, pan]);
    if (!pan || !exp || !cvv) return { ok: false };
    if (!(follows(pan, exp) && follows(exp, cvv))) return { ok: false };
    if (pan.form !== exp.form || exp.form !== cvv.form) return { ok: false };
    var name = pick(inputs, 'name', [cvv, pan, exp]);
    if (name && name.form !== pan.form) name = null;
    var extra = inputs.filter(function (i) { return i !== pan && i !== exp && i !== cvv && i !== name && (i.type || 'text') !== 'password'; }).length;
    return { ok: true, pan: pan, exp: exp, cvv: cvv, name: name, unclassifiedInputs: extra, form: pan.form };
  }

  // The terms checkbox of THIS form: matched by its own id/name/label text, never a "save card" style switch.
  function findTerms(form) {
    var boxes = Array.prototype.slice.call(document.querySelectorAll('input[type=checkbox]')).filter(function (b) {
      if (b.disabled || b.form !== form) return false;
      var sig = (b.id || '') + ' ' + (b.name || '') + ' ' + nearText(b);
      return RX.terms.test(sig) && !RX.notTerms.test(sig);
    });
    return boxes;
  }
  // Whether the page itself has marked THIS field invalid: the field, or the custom-element host that wraps it
  // (e.g. p-inputmask). Never an outer form/container - a form is "invalid" simply because the CVV is still empty.
  function looksInvalid(el) {
    if (el.getAttribute('aria-invalid') === 'true') return true;
    var hosts = [el];
    var host = el.parentElement;
    if (host && /^P-|-/.test(host.tagName) && host.tagName.indexOf('-') > 0) hosts.push(host);
    for (var i = 0; i < hosts.length; i++) {
      var c = hosts[i].className;
      if (typeof c === 'string' && RX.invalid.test(c)) return true;
    }
    return false;
  }

  // 3. typing that looks like real typing to the page's own framework
  var nativeSet = Object.getOwnPropertyDescriptor(W.HTMLInputElement.prototype, 'value').set;
  function keyEvent(type, ch) {
    var code = ch.charCodeAt(0);
    var e = new KeyboardEvent(type, { key: ch, bubbles: true, cancelable: true, keyCode: code, which: code, charCode: type === 'keypress' ? code : 0 });
    try { Object.defineProperty(e, 'which', { value: code }); Object.defineProperty(e, 'keyCode', { value: code }); if (type === 'keypress') Object.defineProperty(e, 'charCode', { value: code }); } catch (x) { }
    return e;
  }
  function typeInto(el, text) {
    el.focus();
    nativeSet.call(el, '');
    el.dispatchEvent(new InputEvent('input', { bubbles: true, inputType: 'deleteContentBackward' }));
    for (var i = 0; i < text.length; i++) {
      var ch = text.charAt(i), kd = keyEvent('keydown', ch), kp = keyEvent('keypress', ch);
      el.dispatchEvent(kd); el.dispatchEvent(kp);
      var bi = new InputEvent('beforeinput', { bubbles: true, cancelable: true, data: ch, inputType: 'insertText' });
      el.dispatchEvent(bi);
      if (!kd.defaultPrevented && !kp.defaultPrevented && !bi.defaultPrevented) {
        nativeSet.call(el, el.value + ch);
        try { el.setSelectionRange(el.value.length, el.value.length); } catch (x) { }
        el.dispatchEvent(new InputEvent('input', { bubbles: true, data: ch, inputType: 'insertText' }));
      }
      el.dispatchEvent(keyEvent('keyup', ch));
    }
    el.dispatchEvent(new Event('change', { bubbles: true }));
    el.blur();
  }
  function digitsOf(v) { return String(v || '').replace(/\D+/g, ''); }

  // 4. the single entry point native code calls after the customer's tap.
  //    Values arrive as call arguments and are used once; nothing is kept.
  //    The page's own framework needs a moment to digest what was typed (its validity classes
  //    update asynchronously), so the outcome is verified after a short settle, never claimed early.
  function settle(check, tries, gap) {
    return new Promise(function (resolve) {
      var n = 0;
      (function step() {
        var r = check();
        if (r.ok || ++n >= tries) resolve(r); else W.setTimeout(step, gap);
      })();
    });
  }
  var fillNow = function (pan, exp, name, acceptTerms) {
    var f = scan();
    if (!f.ok || ORIGINS.indexOf(W.location.origin) < 0) {
      return Promise.resolve({ ok: false, pan: 'failed', exp: 'failed', name: 'absent', terms: 'skipped', reason: 'unknown_form' });
    }
    var p = digitsOf(pan), e = digitsOf(exp), nm = String(name || '').trim();
    var wantPan = p.length >= 12, wantExp = e.length === 4;
    if (wantPan) typeInto(f.pan, p);
    if (wantExp) typeInto(f.exp, e);
    if (f.name && nm) typeInto(f.name, nm.slice(0, parseInt(f.name.getAttribute('maxlength'), 10) || 60));
    var boxes = acceptTerms ? findTerms(f.form) : [];
    var box = boxes.length === 1 ? boxes[0] : null;
    if (box && !box.checked) box.click();

    var check = function () {
      var cur = scan(), g = cur.ok ? cur : f;      // the page may have re-rendered its inputs
      var out = { ok: false, pan: 'failed', exp: 'failed', name: 'absent', terms: 'skipped' };
      if (wantPan) out.pan = digitsOf(g.pan.value) === p && !looksInvalid(g.pan) ? 'filled' : 'failed';
      if (wantExp) out.exp = digitsOf(g.exp.value) === e && !looksInvalid(g.exp) ? 'filled' : 'failed';
      if (g.name) out.name = nm && g.name.value.length > 0 && !looksInvalid(g.name) ? 'filled' : 'failed';
      else if (g.unclassifiedInputs > 0) out.name = 'failed';   // an input we could not identify: do not claim success
      if (acceptTerms) {
        if (boxes.length === 0) out.terms = 'absent';
        else if (boxes.length > 1) out.terms = 'failed';
        else { var b = findTerms(g.form)[0] || box; out.terms = b && b.checked && !looksInvalid(b) ? 'checked' : 'failed'; }
      }
      out.ok = out.pan === 'filled' && out.exp === 'filled' && out.name !== 'failed' && out.terms !== 'failed';
      if (!out.ok) out.reason = 'not_accepted';
      return out;
    };
    return new Promise(function (resolve) { W.setTimeout(function () { settle(check, 4, 250).then(resolve); }, 200); });
  };
  Object.defineProperty(W, '__tfFill', { value: fillNow, enumerable: false, configurable: false });

  // Android delivers the fill command as a message to this frame (no page-visible global carries the values).
  if (W.taxistaFill && typeof W.taxistaFill.addEventListener === 'function') {
    W.taxistaFill.addEventListener('message', function (ev) {
      var d; try { d = JSON.parse(ev.data); } catch (x) { return; }
      if (!d || d.op !== 'fill') return;
      var pending = fillNow(d.pan, d.exp, d.name, !!d.terms);
      d = null;
      pending.then(function (r) { post({ t: 'result', r: r }); });
    });
  }

  // 5. tell native when a fillable form is on screen (state only, never values)
  var last = null, timer = null;
  function report() {
    timer = null;
    var s = scan(), state = s.ok ? 'ready' : 'gone';
    if (state !== last) { last = state; post({ t: state, origin: W.location.origin }); }
  }
  function schedule() { if (!timer) timer = W.setTimeout(report, 250); }
  // The frame is leaving (the bank moved on to its next step, or the page reloads): the form is gone.
  W.addEventListener('pagehide', function () { last = 'gone'; post({ t: 'gone', origin: W.location.origin }); });
  function start() {
    schedule();
    new MutationObserver(schedule).observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ['style', 'class', 'hidden', 'disabled'] });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
''';
