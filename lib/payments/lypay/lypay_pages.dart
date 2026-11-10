import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../moamalat/moamalat_env.dart';
import 'lypay_api.dart';

/// Picks the transfer screenshot; replaced in tests.
typedef ReceiptPicker = Future<File?> Function();

Future<File?> pickReceiptFromGallery() async {
  final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90, requestFullMetadata: false);
  return x == null ? null : File(x.path);
}

/// «تحويل LYPay» from the Add Money sheet: a request still open goes straight to its status line,
/// otherwise step 1 (the company account and how to transfer).
Future<void> openLypay(BuildContext context, {required MoamalatEnv env, required LypayApi api, ReceiptPicker? picker}) async {
  LypayInfo info;
  try {
    info = await api.info();
  } on LypayException catch (e) {
    if (context.mounted) _say(context, e.message ?? env.t('تعذر الاتصال. حاول مرة أخرى.', 'No connection. Try again.'));
    return;
  }
  if (!context.mounted) return;
  if (info.openRequest != null) {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LypayStatusPage(env: env, api: api, request: info.openRequest!)));
    return;
  }
  if (!info.available) {
    _say(context, env.t('الشحن بتحويل LYPay غير متاح الآن', 'LYPay transfer is not available right now'));
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LypayAccountPage(env: env, api: api, info: info, picker: picker)));
}

void _say(BuildContext context, String text) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

String _money(double v) => '${v.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} د.ل';

/// The frame of the three pages: back, title, line under it, body, the one button at the bottom.
class _LypayFrame extends StatelessWidget {
  const _LypayFrame({required this.env, required this.title, required this.sub, required this.children, this.bottom});

  final MoamalatEnv env;
  final String title;
  final String sub;
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: env.direction,
        child: Scaffold(
          backgroundColor: env.background,
          appBar: AppBar(
            backgroundColor: env.background,
            surfaceTintColor: env.background,
            elevation: 0,
            foregroundColor: env.text,
            titleSpacing: 0,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: env.style(size: 19, weight: FontWeight.w900)),
              Text(sub, style: env.style(size: 12.5, color: env.muted)),
            ]),
          ),
          body: SafeArea(
            child: Column(children: [
              Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: children)),
              if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: bottom),
            ]),
          ),
        ),
      );
}

Widget _card(MoamalatEnv env, List<Widget> children) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: env.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: env.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );

Widget _button(MoamalatEnv env, String text, VoidCallback? onTap, {bool busy = false, Key? key}) => SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        key: key,
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(backgroundColor: env.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: busy
            ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Text(text, style: env.style(size: 17, weight: FontWeight.w900, color: Colors.white)),
      ),
    );

/* ------------------------------------------------------------------ step 1 */

class LypayAccountPage extends StatelessWidget {
  const LypayAccountPage({super.key, required this.env, required this.api, required this.info, this.picker});

  final MoamalatEnv env;
  final LypayApi api;
  final LypayInfo info;
  final ReceiptPicker? picker;

  Widget _fact(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: env.style(size: 12.5, weight: FontWeight.w800, color: env.muted)),
          Text(value, style: env.style(size: 15.5, weight: FontWeight.w800)),
        ]),
      );

  Widget _copy(BuildContext context, String label, String shown, String copied, {bool big = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: env.border))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: env.style(size: 12.5, weight: FontWeight.w800, color: env.muted)),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(shown, maxLines: 1, overflow: TextOverflow.ellipsis, style: env.style(size: big ? 17 : 15.5, weight: FontWeight.w900)),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: Key('copy-$label'),
            style: TextButton.styleFrom(backgroundColor: env.accent.withValues(alpha: .1), foregroundColor: env.accent, minimumSize: const Size(64, 40)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copied));
              if (context.mounted) _say(context, env.t('تم النسخ', 'Copied'));
            },
            child: Text(env.t('نسخ', 'Copy'), style: env.style(size: 14, weight: FontWeight.w800, color: env.accent)),
          ),
        ]),
      );

  Widget _step(String n, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: env.accent.withValues(alpha: .1)),
            child: Text(n, style: env.style(size: 14, weight: FontWeight.w900, color: env.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: env.style(size: 14.5, weight: FontWeight.w700))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final a = info.account;
    return _LypayFrame(
      env: env,
      title: env.t('تحويل LYPay', 'LYPay transfer'),
      sub: env.t('الخطوة 1 من 2', 'Step 1 of 2'),
      bottom: _button(env, env.t('حوّلت، نبعث الإيصال', 'I transferred, send the receipt'), () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LypaySendPage(env: env, api: api, info: info, picker: picker)));
      }, key: const Key('lypay-transferred')),
      children: [
        _card(env, [
          Text(env.t('حوّل لحساب تاكسيستا', 'Transfer to Taxista'), style: env.style(size: 16.5, weight: FontWeight.w900)),
          if (a.bankName.isNotEmpty) _fact(env.t('اسم المصرف', 'Bank'), a.bankName),
          _fact(env.t('اسم الحساب', 'Account name'), a.accountName),
          _copy(context, env.t('الآيبان IBAN · من أي مصرف', 'IBAN · from any bank'), a.ibanGrouped, a.iban, big: true),
          if (a.accountNumber.isNotEmpty) _copy(context, env.t('رقم الحساب · لو نفس المصرف', 'Account number · same bank'), a.accountNumber, a.accountNumber),
        ]),
        _card(env, [
          Text(env.t('كيف تحوّل؟', 'How to transfer'), style: env.style(size: 15, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          _step('1', env.t('انسخ الآيبان (أو رقم الحساب لو مصرفك نفس مصرفنا)', 'Copy the IBAN (or the account number if your bank is ours)')),
          _step('2', env.t('افتح تطبيق مصرفك ← LYPay أو «تحويل فوري»، والصق الآيبان', 'Open your bank app → LYPay or instant transfer, paste the IBAN')),
          _step('3', env.t('اكتب المبلغ وأكد التحويل', 'Enter the amount and confirm')),
          _step('4', env.t('خذ سكرين شوت لصفحة «تمت العملية»، وارجع هنا', 'Take a screenshot of the «done» page and come back')),
        ]),
      ],
    );
  }
}

/* ------------------------------------------------------------------ step 2 */

class LypaySendPage extends StatefulWidget {
  const LypaySendPage({super.key, required this.env, required this.api, required this.info, this.picker});

  final MoamalatEnv env;
  final LypayApi api;
  final LypayInfo info;
  final ReceiptPicker? picker;

  @override
  State<LypaySendPage> createState() => _LypaySendPageState();
}

class _LypaySendPageState extends State<LypaySendPage> {
  final _amount = TextEditingController();
  File? _receipt;
  bool _busy = false;

  MoamalatEnv get env => widget.env;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await (widget.picker ?? pickReceiptFromGallery)();
    if (f != null && mounted) setState(() => _receipt = f);
  }

  Future<void> _send() async {
    final amount = double.tryParse(normalizeDigits(_amount.text.trim()).replaceAll(',', '.')) ?? 0;
    if (_receipt == null) return _say(context, env.t('أرفق صورة التحويل', 'Attach the transfer screenshot'));
    if (amount < widget.info.minAmount) return _say(context, env.t('أقل مبلغ ${_money(widget.info.minAmount)}', 'Minimum ${widget.info.minAmount}'));
    setState(() => _busy = true);
    try {
      final r = await widget.api.submit(amount, _receipt!);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LypayStatusPage(env: env, api: widget.api, request: r)));
    } on LypayException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _say(context, e.message ?? env.t('تعذر الإرسال. تأكد من الإنترنت وحاول مرة أخرى.', 'Could not send. Check the connection and retry.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) => _LypayFrame(
        env: env,
        title: env.t('تحويل LYPay', 'LYPay transfer'),
        sub: env.t('الخطوة 2 من 2', 'Step 2 of 2'),
        bottom: _button(env, env.t('أرسل الطلب', 'Send'), _send, busy: _busy, key: const Key('lypay-send')),
        children: [
          _card(env, [
            Text(env.t('صورة التحويل', 'Transfer screenshot'), style: env.style(size: 15, weight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (_receipt == null)
              OutlinedButton.icon(
                key: const Key('lypay-pick'),
                onPressed: _pick,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(96), side: BorderSide(color: env.accent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: Icon(Icons.add_photo_alternate_rounded, color: env.accent),
                label: Text(env.t('اختار السكرين شوت من الصور', 'Choose the screenshot'), style: env.style(size: 15, weight: FontWeight.w800, color: env.accent)),
              )
            else
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_receipt!, width: 92, height: 130, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(env.t('✓ الصورة جاهزة', '✓ Screenshot ready'), style: env.style(size: 14, weight: FontWeight.w800, color: const Color(0xff047857))),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _pick, child: Text(env.t('بدّل الصورة', 'Change'), style: env.style(size: 14, weight: FontWeight.w800, color: env.accent))),
                  ]),
                ),
              ]),
          ]),
          _card(env, [
            Text(env.t('المبلغ اللي حوّلته', 'The amount you transferred'), style: env.style(size: 15, weight: FontWeight.w900)),
            const SizedBox(height: 10),
            TextField(
              key: const Key('lypay-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              style: env.style(size: 26, weight: FontWeight.w900),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: env.t('د.ل', 'LYD'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: env.accent, width: 2)),
              ),
            ),
            const SizedBox(height: 6),
            Text(env.t('نفس المبلغ اللي في الصورة · أقل شي ${_money(widget.info.minAmount)}', 'Same as in the screenshot · minimum ${widget.info.minAmount}'),
                style: env.style(size: 12.5, color: env.muted)),
          ]),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: env.accent.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
            child: Text(env.t('نراجعو الصورة مع حساب الشركة، ونشحنوا محفظتك خلال دقائق. يوصلك إشعار.', 'We check it against our account and top up your wallet within minutes.'),
                style: env.style(size: 13.5, weight: FontWeight.w700)),
          ),
        ],
      );
}

/* ------------------------------------------------------------------ the status line */

class LypayStatusPage extends StatefulWidget {
  const LypayStatusPage({super.key, required this.env, required this.api, required this.request, this.poll = const Duration(seconds: 10)});

  final MoamalatEnv env;
  final LypayApi api;
  final LypayRequest request;
  final Duration poll;

  @override
  State<LypayStatusPage> createState() => _LypayStatusPageState();
}

class _LypayStatusPageState extends State<LypayStatusPage> with WidgetsBindingObserver {
  late LypayRequest _r = widget.request;
  Timer? _timer;

  MoamalatEnv get env => widget.env;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_r.isOpen) _timer = Timer.periodic(widget.poll, (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _r.isOpen) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final r = await widget.api.status(_r.reference);
      if (!mounted) return;
      final wasOpen = _r.isOpen;
      setState(() => _r = r);
      if (!r.isOpen) {
        _timer?.cancel();
        if (wasOpen && r.status == 'approved') env.onWalletChanged?.call();
      }
    } on LypayException {
      // keep the line as it is; the next tick tries again
    }
  }

  String _time(DateTime? t) => t == null ? '' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final approved = r.status == 'approved';
    final rejected = r.status == 'rejected';
    final steps = <_Step>[
      _Step(env.t('تم إرسال الطلب', 'Request sent'), '${_time(r.sentAt)} · ${env.t('وصلتنا الصورة والمبلغ', 'we have the screenshot and amount')}', _State.done),
      _Step(
        env.t('جاري التأكد من الحوالة', 'Checking the transfer'),
        r.status == 'sent' || r.status == 'checking' ? env.t('نطابقو التحويل مع حساب الشركة. عادة خلال دقائق', 'Matching it with our account. Usually minutes') : _time(r.checkingAt),
        r.isOpen ? _State.now : _State.done,
      ),
      if (rejected)
        _Step(env.t('ما لقيناش الحوالة', 'Transfer not found'), '${env.t('السبب', 'Reason')}: ${r.rejectReason ?? ''}', _State.bad)
      else ...[
        _Step(env.t('تم التأكد', 'Confirmed'), approved ? env.t('${_time(r.reviewedAt)} · الحوالة وصلت', '${_time(r.reviewedAt)} · received') : '', approved ? _State.done : _State.wait),
        _Step(env.t('تم شحن محفظتك', 'Wallet topped up'), approved ? '+${_money(r.amountCredited ?? r.amount)}' : '', approved ? _State.done : _State.wait),
      ],
    ];
    return _LypayFrame(
      env: env,
      title: env.t('طلب الشحن', 'Top-up request'),
      sub: 'LYPay · ${_money(r.amount)} · ${r.reference}',
      bottom: r.isOpen ? null : _button(env, rejected ? env.t('ابعث الصورة من جديد', 'Send again') : env.t('رجوع للمحفظة', 'Back to wallet'), () => Navigator.of(context).pop()),
      children: [
        if (approved)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xff065f46), Color(0xff10b981)]), borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 54),
              const SizedBox(height: 6),
              Text(env.t('تم شحن محفظتك', 'Your wallet is topped up'), style: env.style(size: 21, weight: FontWeight.w900, color: Colors.white)),
              Text('+${_money(r.amountCredited ?? r.amount)}', style: env.style(size: 16, weight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        _card(env, [for (var i = 0; i < steps.length; i++) _StepRow(env: env, step: steps[i], last: i == steps.length - 1)]),
        if (r.isOpen)
          Text(env.t('تقدر تسكّر الصفحة، يوصلك إشعار لما يتشحن.', 'You can close this page; we notify you.'),
              textAlign: TextAlign.center, style: env.style(size: 13, weight: FontWeight.w700, color: env.muted)),
        if (rejected)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xfffdeaea), borderRadius: BorderRadius.circular(16)),
            child: Text(env.t('ما تخصم منك شي. لو حوّلت فعلًا، ابعث صورة أوضح أو كلمنا.', 'Nothing was charged. If you did transfer, send a clearer screenshot or contact us.'),
                style: env.style(size: 13.5, weight: FontWeight.w700, color: const Color(0xff7f1d1d))),
          ),
      ],
    );
  }
}

enum _State { done, now, wait, bad }

class _Step {
  const _Step(this.title, this.sub, this.state);

  final String title;
  final String sub;
  final _State state;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.env, required this.step, required this.last});

  final MoamalatEnv env;
  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xff047857);
    const red = Color(0xffb91c1c);
    final s = step.state;
    final Widget dot = switch (s) {
      _State.done => const CircleAvatar(radius: 15, backgroundColor: green, child: Icon(Icons.check_rounded, color: Colors.white, size: 18)),
      _State.now => _Pulse(color: env.accent),
      _State.bad => const CircleAvatar(radius: 15, backgroundColor: red, child: Icon(Icons.priority_high_rounded, color: Colors.white, size: 18)),
      _State.wait => Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: env.border, width: 2.5))),
    };
    final color = switch (s) { _State.now => env.accent, _State.bad => red, _State.wait => env.muted, _State.done => env.text };
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          dot,
          if (!last) Expanded(child: Container(width: 3, margin: const EdgeInsets.symmetric(vertical: 4), color: s == _State.done ? green : env.border)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step.title, style: env.style(size: 16.5, weight: FontWeight.w900, color: color)),
              if (step.sub.trim().isNotEmpty) Text(step.sub, style: env.style(size: 13.5, color: env.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});

  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color, boxShadow: [
            BoxShadow(color: widget.color.withValues(alpha: .45 * (1 - _c.value)), spreadRadius: 10 * _c.value),
          ]),
          child: const Center(child: CircleAvatar(radius: 5, backgroundColor: Colors.white)),
        ),
      );
}
