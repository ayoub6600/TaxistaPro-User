import 'package:flutter/material.dart';

import 'moamalat_env.dart';
import 'saved_card.dart';

/// Shown above the payment page. The gateway's form lives in an isolated
/// cross-origin frame that the app cannot fill in, so this panel offers the
/// next best thing: it shows the card only masked, and copies the real number
/// or expiry straight from secure storage to the clipboard on request (the
/// clipboard is cleared again automatically). The CVV is never handled here.
class CardHelperPanel extends StatefulWidget {
  const CardHelperPanel({super.key, required this.env, required this.card});

  final MoamalatEnv env;
  final SavedCard card;

  @override
  State<CardHelperPanel> createState() => _CardHelperPanelState();
}

class _CardHelperPanelState extends State<CardHelperPanel> {
  String? _copied; // 'number' | 'expiry'
  bool _expanded = true;

  MoamalatEnv get env => widget.env;

  Future<void> _copy(String kind, String value) async {
    await env.clipboard.copy(value);
    if (mounted) setState(() => _copied = kind);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: env.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: env.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          key: const Key('helper-toggle'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Icon(Icons.credit_card_rounded, size: 18, color: env.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(env.t('بطاقتك المحفوظة', 'Your saved card'), style: env.style(size: 13.5, weight: FontWeight.w800))),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(card.masked, style: env.style(size: 12.5, weight: FontWeight.w700, color: env.muted)),
              ),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: env.muted),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _line(env.t('الاسم', 'Name'), card.holderName),
              _line(env.t('رقم البطاقة', 'Card number'), card.masked, ltr: true),
              _line(env.t('تاريخ الانتهاء', 'Expiry'), card.expiryText, ltr: true),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('copy-number'),
                    onPressed: () => _copy('number', card.number),
                    icon: Icon(_copied == 'number' ? Icons.check_rounded : Icons.copy_rounded, size: 16),
                    label: Text(env.t('نسخ رقم البطاقة', 'Copy card number'), style: env.style(size: 12, weight: FontWeight.w700, color: env.accent)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('copy-expiry'),
                    onPressed: () => _copy('expiry', card.expiryText),
                    icon: Icon(_copied == 'expiry' ? Icons.check_rounded : Icons.copy_rounded, size: 16),
                    label: Text(env.t('نسخ تاريخ الانتهاء', 'Copy expiry'), style: env.style(size: 12, weight: FontWeight.w700, color: env.accent)),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                _copied == null
                    ? env.t('الصق القيمة في حقل الدفع. أدخل رمز الأمان (CVV) بنفسك - لا نحفظه.',
                        'Paste it into the payment field. Enter the security code (CVV) yourself - we never store it.')
                    : env.t('تم النسخ وسيُمسح من الحافظة تلقائياً بعد دقيقة.', 'Copied. It will be cleared from the clipboard in a minute.'),
                key: const Key('helper-note'),
                style: env.style(size: 11.5, weight: FontWeight.w500, color: env.muted),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _line(String label, String value, {bool ltr = false}) {
    final text = Text(value, style: env.style(size: 12.5, weight: FontWeight.w700));
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        SizedBox(width: 96, child: Text(label, style: env.style(size: 12, weight: FontWeight.w500, color: env.muted))),
        Expanded(child: ltr ? Directionality(textDirection: TextDirection.ltr, child: Align(alignment: AlignmentDirectional.centerStart, child: text)) : text),
      ]),
    );
  }
}
