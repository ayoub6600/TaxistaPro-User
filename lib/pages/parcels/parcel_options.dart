import 'package:flutter/material.dart';

import '../../functions/tr.dart';
import '../intercity/intercity_style.dart';

/// How the sender pays, as the server decides it with payment 'auto' (owner 2026-11-19): his wallet
/// when it holds the price, else cash to the captain at pickup. Offers are always cash (the price is
/// known only when he takes one). The receiver always pays cash at delivery.
class ParcelPay {
  /// true: from the wallet; false: cash; null: not known yet (no price or no balance read)
  static bool? senderWallet({required num? price, required num? balance, required bool offers}) {
    if (offers) return false;
    if (price == null || balance == null) return null;
    return balance >= price;
  }

  static String senderLine({required num? price, required num? balance, required bool offers, required String currency}) =>
      switch (senderWallet(price: price, balance: balance, offers: offers)) {
        true => tr('من محفظتك (رصيدك $currency ${IcStyle.money(balance!)})', 'From your wallet (balance $currency ${IcStyle.money(balance)})'),
        false => tr('كاش للكابتن لما ياخذ الطرد', 'Cash to the captain when he takes the parcel'),
        null => tr('من محفظتك لو رصيدك يكفي، وإلا كاش للكابتن لما ياخذ الطرد', 'From your wallet if it covers it, else cash to the captain at pickup'),
      };

  static String receiverLine() => tr('كاش للكابتن وقت التسليم', 'Cash to the captain at delivery');

  /// the summary's line: who pays and how
  static String line({required String payer, required num? price, required num? balance, required bool offers, required String currency}) => payer == 'receiver'
      ? tr('المستلم · ${receiverLine()}', 'The receiver · ${receiverLine()}')
      : tr('أنا · ${senderLine(price: price, balance: balance, offers: offers, currency: currency)}',
          'Me · ${senderLine(price: price, balance: balance, offers: offers, currency: currency)}');
}

/// «مين يدفع؟»: two clear rows, each saying how the money goes.
class ParcelPayer extends StatelessWidget {
  const ParcelPayer({super.key, required this.payer, required this.onPayer, required this.senderLine});

  final String payer;
  final ValueChanged<String> onPayer;
  final String senderLine;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(tr('مين يدفع؟', 'Who pays?'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        _row('sender', tr('أنا', 'Me'), senderLine, const ValueKey('parcel-payer-sender')),
        const SizedBox(height: 6),
        _row('receiver', tr('المستلم', 'The receiver'), ParcelPay.receiverLine(), const ValueKey('parcel-payer-receiver')),
      ]);

  Widget _row(String value, String title, String subtitle, Key key) {
    final on = payer == value;
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        key: key,
        onTap: () => onPayer(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on ? const Color(0xffF5F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? IcStyle.blue : IcStyle.line, width: on ? 2 : 1.5),
          ),
          child: Row(children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? IcStyle.blue : const Color(0xffD5DEEB), width: on ? 6 : 2)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: IcStyle.t(14.5, w: FontWeight.w900)),
                Text(subtitle, style: IcStyle.t(12, w: FontWeight.w700, c: IcStyle.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// «التسليم بكود»: on by default; off means he answers for the hand-over himself.
class ParcelCodeSwitch extends StatelessWidget {
  const ParcelCodeSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 8),
        decoration: BoxDecoration(
          color: value ? const Color(0xffEFFAF3) : const Color(0xffFFF4F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? const Color(0xffBBE5C8) : const Color(0xffF9C9C1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(value ? '🔒' : '🔓', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Expanded(child: Text(tr('التسليم بكود', 'Delivery with a code'), style: IcStyle.t(15, w: FontWeight.w900))),
            Switch.adaptive(key: const ValueKey('parcel-code-switch'), value: value, onChanged: onChanged, activeTrackColor: const Color(0xff16A34A)),
          ]),
          Text(
            value
                ? tr('الكود أأمن: الكابتن ما يسلّمش الطرد إلا للي عنده الكود', 'Safer: the captain hands the parcel only to whoever has the code')
                : tr('بدون كود: أنت المسؤول عن التسليم', 'No code: you answer for the hand-over'),
            key: const ValueKey('parcel-code-note'),
            style: IcStyle.t(12.5, w: FontWeight.w700, c: value ? const Color(0xff16803C) : const Color(0xffB42318)),
          ),
        ]),
      );
}
