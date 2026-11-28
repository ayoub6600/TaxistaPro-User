import 'package:flutter/material.dart';

import '../functions/money_label.dart';
import '../widgets/widgets.dart' show Button;
import 'ambassadors_api.dart';
import 'ambassadors_kit.dart';

/// «اشترك في الذهبي»: what is taken from the wallet and what he gets, then POST gold with one key
/// for this sheet (a double tap or a retry is the same purchase, paid once). Pops the new page
/// state, [topUp] when the wallet is short, or nothing.
class AmbassadorGoldConfirmSheet extends StatefulWidget {
  const AmbassadorGoldConfirmSheet({super.key, required this.state});

  static const topUp = 'topup';

  final AmbassadorState state;

  @override
  State<AmbassadorGoldConfirmSheet> createState() => _AmbassadorGoldConfirmSheetState();
}

class _AmbassadorGoldConfirmSheetState extends State<AmbassadorGoldConfirmSheet> {
  final String _key = AmbassadorsApi.newKey();
  String? _error;
  bool _short = false;

  Future<void> _pay() async {
    setState(() => _error = null);
    final r = await AmbassadorsApi.buyGold(_key);
    if (!mounted) return;
    if (r.ok) {
      Navigator.of(context).pop(r.state);
      return;
    }
    setState(() {
      _error = r.error;
      // «محفظتك فيها 5.60 د.ل، اشحن 244.40 الأول»: offer the top-up instead of trying again
      _short = r.status == 422 && ((r.error ?? '').contains('اشحن') || widget.state.gold.short);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final g = s.gold;
    final price = moneyAmount(g.priceLyd);
    Widget line(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✓', style: AmbLook.t(14, w: FontWeight.w800, color: AmbLook.gold)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AmbLook.t(14, h: 1.6))),
          ]),
        );
    return AmbSheet(children: [
      Row(children: [
        const AmbCrown(size: 44),
        const SizedBox(width: 12),
        Expanded(child: Text('تشترك في السفير الذهبي؟', style: AmbLook.t(19, w: FontWeight.w800))),
      ]),
      const SizedBox(height: 14),
      line('ينخصم $price د.ل من محفظتك (فيها توا ${moneyAmount(g.walletLyd)} د.ل).'),
      line('لمدة ${ambMonths(g.months)} تاخذ ${ambNum(g.shareOfProfit)}% من ربح تاكسيستا (يعني ${ambNum(g.pct)}% من سعر المشوار) من مشاوير كل اللي جبتهم.'),
      line('تقدر تسحب أرباحك تحويل على حسابك.'),
      if (_error != null) ...[
        const SizedBox(height: 4),
        AmbNote(_error!, tone: AmbNoteTone.red),
      ],
      const SizedBox(height: 14),
      if (_short)
        Button(
          key: const ValueKey('amb-gold-sheet-topup'),
          onTap: () => Navigator.of(context).pop(AmbassadorGoldConfirmSheet.topUp),
          text: 'اشحن محفظتك',
          backgroundcolor: AmbLook.blue,
          width: double.infinity,
        )
      else
        Button(
          key: const ValueKey('amb-gold-pay'),
          onTap: _pay,
          text: 'اشترك بـ$price د.ل',
          backgroundcolor: AmbLook.gold,
          textcolor: AmbLook.night,
          width: double.infinity,
        ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('مش توا', style: AmbLook.t(15, w: FontWeight.w700, color: AmbLook.sub)),
      ),
    ]);
  }
}

/// «اسحب أرباحك»: the amount (between the smallest and what he has), the bank, the holder's name and
/// the account (or LYPay) number; the administration transfers it. Pops the new page state.
class AmbassadorWithdrawSheet extends StatefulWidget {
  const AmbassadorWithdrawSheet({super.key, required this.withdraw});

  final AmbassadorWithdraw withdraw;

  /// «٥٠٫٥» / «50,5» / « 50 » → 50.5; null when it is not a number
  static double? amountOf(String text) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final ch in text.trim().split('')) {
      final i = eastern.indexOf(ch);
      b.write(i >= 0 ? '$i' : (ch == '٫' || ch == ',' ? '.' : ch));
    }
    final v = double.tryParse(b.toString().replaceAll(' ', ''));
    return v == null || v.isNaN || v.isInfinite ? null : v;
  }

  /// The first thing to fix, in his words, or null when the request can go.
  static String? check({
    required String amount,
    required String bank,
    required String name,
    required String number,
    required double min,
    required double available,
  }) {
    final v = amountOf(amount);
    if (v == null || v <= 0) return 'اكتب المبلغ اللي تبي تسحبه.';
    if (min > 0 && v + 0.004 < min) return 'أقل سحب ${moneyAmount(min)} د.ل.';
    if (v > available + 0.004) return 'تقدر تسحب لين ${moneyAmount(available)} د.ل بس.';
    if (bank.trim().length < 2) return 'اكتب اسم المصرف (أو LYPay).';
    if (name.trim().length < 3) return 'اكتب اسم صاحب الحساب كامل.';
    final n = number.replaceAll(RegExp(r'[\s-]'), '');
    if (n.length < 6 || !RegExp(r'^[A-Za-z0-9+]+$').hasMatch(n)) return 'اكتب رقم الحساب أو رقم LYPay صح.';
    return null;
  }

  @override
  State<AmbassadorWithdrawSheet> createState() => _AmbassadorWithdrawSheetState();
}

class _AmbassadorWithdrawSheetState extends State<AmbassadorWithdrawSheet> {
  final _amount = TextEditingController();
  final _bank = TextEditingController();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final String _key = AmbassadorsApi.newKey();
  String? _error;

  @override
  void initState() {
    super.initState();
    // the bank of his last request, so a second withdrawal is quicker
    final last = widget.withdraw.requests.where((r) => r.bank != null);
    if (last.isNotEmpty) _bank.text = last.first.bank!;
  }

  @override
  void dispose() {
    _amount.dispose();
    _bank.dispose();
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final w = widget.withdraw;
    final problem = AmbassadorWithdrawSheet.check(
      amount: _amount.text,
      bank: _bank.text,
      name: _name.text,
      number: _number.text,
      min: w.minLyd,
      available: w.availableLyd,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _error = null);
    FocusManager.instance.primaryFocus?.unfocus();
    final r = await AmbassadorsApi.withdraw(
      amount: AmbassadorWithdrawSheet.amountOf(_amount.text)!,
      bankName: _bank.text.trim(),
      accountName: _name.text.trim(),
      accountNumber: _number.text.replaceAll(RegExp(r'[\s-]'), ''),
      key: _key,
    );
    if (!mounted) return;
    if (r.ok) {
      Navigator.of(context).pop(r.state);
    } else {
      setState(() => _error = r.error);
    }
  }

  Widget _field(String label, TextEditingController c, {String? hint, TextInputType? keyboard, Key? key, TextDirection? direction}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AmbLook.t(13, w: FontWeight.w700, color: AmbLook.sub)),
          const SizedBox(height: 4),
          TextField(
            key: key,
            controller: c,
            keyboardType: keyboard,
            textDirection: direction,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: AmbLook.t(16, w: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AmbLook.t(14, color: AmbLook.mute),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AmbLook.blue, width: 1.5)),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final w = widget.withdraw;
    return AmbSheet(children: [
      Text('اسحب أرباحك', style: AmbLook.t(20, w: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(
        'تقدر تسحب لين ${moneyAmount(w.availableLyd)} د.ل${w.minLyd > 0 ? ' · أقل سحب ${moneyAmount(w.minLyd)} د.ل' : ''}',
        style: AmbLook.t(13, color: AmbLook.sub),
      ),
      const SizedBox(height: 12),
      _field(
        'المبلغ (د.ل)',
        _amount,
        key: const ValueKey('amb-w-amount'),
        hint: moneyAmount(w.availableLyd),
        keyboard: const TextInputType.numberWithOptions(decimal: true),
        direction: TextDirection.ltr,
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: () => setState(() {
            _amount.text = moneyAmount(w.availableLyd);
            _error = null;
          }),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: const Size(0, 32)),
          child: Text('كل المبلغ (${moneyAmount(w.availableLyd)} د.ل)', style: AmbLook.t(13, w: FontWeight.w700, color: AmbLook.blue)),
        ),
      ),
      _field('اسم المصرف', _bank, key: const ValueKey('amb-w-bank'), hint: 'مثلاً: مصرف الجمهورية، أو LYPay'),
      _field('اسم صاحب الحساب', _name, key: const ValueKey('amb-w-name'), hint: 'الاسم زي ما هو في المصرف'),
      _field('رقم الحساب أو رقم LYPay', _number, key: const ValueKey('amb-w-number'), keyboard: TextInputType.text, direction: TextDirection.ltr),
      Text('الإدارة تحوّلك الفلوس على الحساب هذا، ويوصلك إشعار لما تتحوّل.', style: AmbLook.t(12.5, color: AmbLook.mute, h: 1.6)),
      if (_error != null) ...[
        const SizedBox(height: 10),
        AmbNote(_error!, tone: AmbNoteTone.red),
      ],
      const SizedBox(height: 14),
      Button(key: const ValueKey('amb-w-send'), onTap: _send, text: 'ابعت طلب السحب', backgroundcolor: AmbLook.blue, width: double.infinity),
    ]);
  }
}
