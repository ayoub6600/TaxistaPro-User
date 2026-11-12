import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import '../NavigatorPages/walletpage.dart';
import 'intercity_style.dart';

/// «الدفع أونلاين قبل التأكيد»: the two sheets around taking a driver or booking seats when the admin
/// set online payment — «أكّد حجزك» (the amount from the wallet, the rules) and «اشحن محفظتك» when
/// the wallet is short (opens the wallet page; he comes back and confirms again).
class IcPay {
  /// true = pay and confirm
  static Future<bool> confirm(BuildContext context, {required String title, required String details, required num amount, required num fare, required IcPayment rules}) async {
    final yes = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: IcSheet(children: [
          Text(title, style: IcStyle.t(21, w: FontWeight.w900)),
          Text(details, style: IcStyle.t(13, w: FontWeight.w600, c: IcStyle.muted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(amount < fare ? 'عربون من محفظتك' : 'من محفظتك', style: IcStyle.t(13.5, w: FontWeight.w700, c: IcStyle.muted))),
                Text('LYD ${IcStyle.money(amount)}', style: IcStyle.t(24, w: FontWeight.w900)),
              ]),
              if (amount < fare)
                Row(children: [
                  Expanded(child: Text('الباقي نقدًا للكابتن', style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.muted))),
                  Text('LYD ${IcStyle.money(fare - amount)}', style: IcStyle.t(15, w: FontWeight.w800)),
                ]),
            ]),
          ),
          const SizedBox(height: 8),
          Text(rules.latePercent > 0
              ? 'إلغاء مجاني قبل الموعد بـ${rules.freeCancelHours} ساعات، وفلوسك ترجع لمحفظتك. بعدها ${rules.latePercent}٪ تروح للكابتن. لو الكابتن لغى أو ما جاش، ترجعلك كاملة.'
              : 'لو لغيت أو الكابتن ما جاش، فلوسك ترجع لمحفظتك كاملة.',
              style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
          const SizedBox(height: 12),
          IcButton(key: const ValueKey('ic-pay-confirm'), text: 'ادفع LYD ${IcStyle.money(amount)} وأكّد', onTap: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 6),
          IcButton(text: 'رجوع', ghost: true, onTap: () => Navigator.pop(ctx, false)),
        ]),
      ),
    );
    return yes == true;
  }

  /// the wallet is short: say by how much, and open the wallet to top up
  static Future<void> topUp(BuildContext context, IntercityResult r) async {
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: IcSheet(children: [
          Text('اشحن محفظتك وكمّل', style: IcStyle.t(21, w: FontWeight.w900)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _line('الحجز يحتاج', r.amount),
              _line('رصيد محفظتك', r.balance),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            key: const ValueKey('ic-missing'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xffFFF8E6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffFDE3A7))),
            child: Text('ناقصك LYD ${IcStyle.money(r.missing)}. اشحن وارجع، والعرض مازال مستنيك.', style: IcStyle.t(13.5, w: FontWeight.w800, c: const Color(0xff9A6700))),
          ),
          const SizedBox(height: 12),
          IcButton(text: 'اشحن محفظتك', onTap: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 6),
          IcButton(text: 'بعدين', ghost: true, onTap: () => Navigator.pop(ctx, false)),
        ]),
      ),
    );
    if (go == true && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletPage()));
    }
  }

  static Widget _line(String label, num v) => Row(children: [
        Expanded(child: Text(label, style: IcStyle.t(13.5, w: FontWeight.w700, c: IcStyle.muted))),
        Text('LYD ${IcStyle.money(v)}', style: IcStyle.t(17, w: FontWeight.w900)),
      ]);
}

/// «الدفع: نقدًا · من المحفظة» when the admin lets the rider choose
class IcPayChoice extends StatelessWidget {
  const IcPayChoice({super.key, required this.online, required this.onChanged});

  final bool online;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget side(String text, bool on, bool value) => Expanded(
          child: Semantics(
            button: true,
            selected: on,
            label: text,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: on ? [BoxShadow(color: IcStyle.navy.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Text(text, style: IcStyle.t(14, w: FontWeight.w900, c: on ? IcStyle.blue : IcStyle.muted)),
              ),
            ),
          ),
        );
    return Row(children: [
      Text('الدفع', style: IcStyle.t(15, w: FontWeight.w900)),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [side('💵 نقدًا', !online, false), const SizedBox(width: 4), side('💳 من المحفظة', online, true)]),
        ),
      ),
    ]);
  }
}

/// «الدفع أونلاين من محفظتك لما تختار الكابتن» — the one line when the admin made it online
class IcPayNote extends StatelessWidget {
  const IcPayNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('ic-pay-note'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xffE7F8EE), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Text('💳', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: IcStyle.t(12.5, w: FontWeight.w800, c: const Color(0xff0F6B45)))),
        ]),
      );
}
