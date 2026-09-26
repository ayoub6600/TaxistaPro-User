import 'package:flutter/material.dart';

import 'moamalat_env.dart';
import 'saved_card.dart';

/// Shown above the payment page. The gateway's form lives in an isolated
/// cross-origin frame that the app cannot fill in (and the bank offers no way
/// to pre-fill it), so this panel makes the manual step as short as it can be:
/// one slim bar, always visible while the customer types, that copies the next
/// detail - number, then expiry, then name - straight from secure storage on a
/// single tap. The card is only ever shown masked, the clipboard is cleared
/// again automatically, and the CVV is never handled here.
class CardHelperPanel extends StatefulWidget {
  const CardHelperPanel({super.key, required this.env, required this.card});

  final MoamalatEnv env;
  final SavedCard card;

  @override
  State<CardHelperPanel> createState() => _CardHelperPanelState();
}

class _CardHelperPanelState extends State<CardHelperPanel> {
  static const List<String> _order = ['number', 'expiry', 'name'];

  final Set<String> _copied = {};
  bool _expanded = false;

  MoamalatEnv get env => widget.env;

  /// The detail the customer most likely needs next: the first not yet copied.
  String? get _next {
    for (final kind in _order) {
      if (!_copied.contains(kind)) return kind;
    }
    return null;
  }

  Future<void> _copy(String kind, String value) async {
    await env.clipboard.copy(value);
    if (mounted) setState(() => _copied.add(kind));
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(Icons.credit_card_rounded, size: 17, color: env.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(env.t('بطاقتك المحفوظة', 'Your saved card'), maxLines: 1, overflow: TextOverflow.ellipsis, style: env.style(size: 13, weight: FontWeight.w800))),
              const SizedBox(width: 6),
              Flexible(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(card.masked, maxLines: 1, overflow: TextOverflow.ellipsis, style: env.style(size: 12, weight: FontWeight.w700, color: env.muted)),
                ),
              ),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: env.muted),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Row(children: [
            Expanded(child: _copyButton('number', const Key('copy-number'), env.t('الرقم', 'Number'), card.number)),
            const SizedBox(width: 6),
            Expanded(child: _copyButton('expiry', const Key('copy-expiry'), env.t('الانتهاء', 'Expiry'), card.expiryText)),
            if (card.holderName.trim().isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(child: _copyButton('name', const Key('copy-name'), env.t('الاسم', 'Name'), card.holderName.trim())),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _copied.isEmpty
                  ? env.t('انسخ ثم الصق في حقل الدفع. رمز الأمان (CVV) تكتبه بنفسك ولا نحفظه.',
                      'Copy, then paste into the payment field. You type the security code (CVV) yourself - we never store it.')
                  : env.t('تم النسخ - الصقه في الحقل ثم انسخ التالي. يُمسح من الحافظة تلقائياً.',
                      'Copied - paste it into the field, then copy the next one. It is cleared from the clipboard automatically.'),
              key: const Key('helper-note'),
              style: env.style(size: 11, weight: FontWeight.w500, color: env.muted),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _line(env.t('الاسم', 'Name'), card.holderName),
              _line(env.t('رقم البطاقة', 'Card number'), card.masked, ltr: true),
              _line(env.t('تاريخ الانتهاء', 'Expiry'), card.expiryText, ltr: true),
            ]),
          ),
      ]),
    );
  }

  Widget _copyButton(String kind, Key key, String label, String value) {
    final done = _copied.contains(kind);
    final isNext = _next == kind;
    final color = isNext ? Colors.white : env.accent;
    // Scales down instead of overflowing on a narrow phone or a long label.
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.check_rounded : Icons.copy_rounded, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, maxLines: 1, style: env.style(size: 12, weight: FontWeight.w800, color: color)),
      ]),
    );
    const padding = EdgeInsets.symmetric(horizontal: 4, vertical: 8);
    if (isNext) {
      return FilledButton(
        key: key,
        style: FilledButton.styleFrom(backgroundColor: env.accent, padding: padding, minimumSize: const Size(0, 38)),
        onPressed: () => _copy(kind, value),
        child: content,
      );
    }
    return OutlinedButton(
      key: key,
      style: OutlinedButton.styleFrom(padding: padding, minimumSize: const Size(0, 38)),
      onPressed: () => _copy(kind, value),
      child: content,
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
