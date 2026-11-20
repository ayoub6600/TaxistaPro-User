import 'package:flutter/material.dart';

import '../../../functions/errand_api.dart';
import '../../../functions/tr.dart';
import '../../intercity/intercity_style.dart';
import 'errand_draft.dart';

/// One stop: its number, the place (a tap opens the search), «شن ياخذ الكابتن؟», who to ask for
/// there (optional), and «مدفوعة» or «الكابتن يدفع عني». Up / down / remove on the top row.
class ErrandStopCard extends StatelessWidget {
  const ErrandStopCard({
    super.key,
    required this.stop,
    required this.index,
    required this.count,
    required this.config,
    required this.onPlace,
    required this.onPays,
    required this.onMove,
    required this.onRemove,
  });

  final ErrandStopDraft stop;
  final int index;
  final int count;
  final ErrandConfig config;
  final VoidCallback onPlace;
  final ValueChanged<String> onPays;
  final void Function(int by) onMove;
  final VoidCallback onRemove;

  static const stopColor = Color(0xff0873FF);

  @override
  Widget build(BuildContext context) {
    final n = index + 1;
    final place = stop.place;
    return Container(
      key: ValueKey('errand-stop-$index'),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: IcStyle.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          number(n),
          const SizedBox(width: 8),
          Expanded(child: Text(tr('الوقفة $n', 'Stop $n'), style: IcStyle.t(15, w: FontWeight.w900))),
          _icon(Icons.arrow_upward_rounded, tr('لفوق', 'Move up'), index > 0 ? () => onMove(-1) : null, ValueKey('errand-up-$index')),
          _icon(Icons.arrow_downward_rounded, tr('لتحت', 'Move down'), index < count - 1 ? () => onMove(1) : null, ValueKey('errand-down-$index')),
          _icon(Icons.close_rounded, tr('شيل الوقفة', 'Remove the stop'), onRemove, ValueKey('errand-remove-$index')),
        ]),
        const SizedBox(height: 6),
        Material(
          color: place == null ? stopColor.withValues(alpha: .06) : IcStyle.soft,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: ValueKey('errand-place-$index'),
            onTap: onPlace,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(Icons.storefront_rounded, color: stopColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place == null ? tr('وين الوقفة؟ اختار المكان', 'Where is the stop? Choose the place') : (place.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : place.address),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IcStyle.t(14, w: place == null ? FontWeight.w600 : FontWeight.w800, c: place == null ? IcStyle.muted : IcStyle.navy),
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: IcStyle.muted),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(tr('شن ياخذ الكابتن؟', 'What does the captain take?'), style: IcStyle.t(13, w: FontWeight.w800)),
        const SizedBox(height: 4),
        field(stop.item, tr('مثلًا: فلتر زيت تويوتا', 'e.g. a Toyota oil filter'), ValueKey('errand-item-$index')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: field(stop.contactName, tr('اسم اللي هناك (اختياري)', 'Who to ask for (optional)'), ValueKey('errand-contact-$index'))),
          const SizedBox(width: 8),
          Expanded(child: field(stop.contactPhone, tr('رقمه (اختياري)', 'Their number (optional)'), ValueKey('errand-phone-$index'), phone: true)),
        ]),
        const SizedBox(height: 10),
        _pays(),
      ]),
    );
  }

  Widget _pays() {
    final cur = config.currency;
    final chips = Row(children: [
      Expanded(child: IcChip(key: ValueKey('errand-paid-$index'), text: tr('مدفوعة', 'Already paid'), selected: stop.pays == 'paid', fill: true, onTap: () => onPays('paid'))),
      if (config.buyAllowed) ...[
        const SizedBox(width: 8),
        Expanded(
            child: IcChip(
                key: ValueKey('errand-captain-$index'), text: tr('الكابتن يدفع عني', 'The captain pays'), selected: stop.pays == 'captain', fill: true, onTap: () => onPays('captain'))),
      ],
    ]);
    String? note;
    if (config.buyAllowed) {
      note = tr(
          'الكابتن يدفع عنك لين ${IcStyle.money(config.buyMax)} $cur${config.receiptRequired ? '، ويصوّر الفاتورة' : ''}، وأنت تأكد المبلغ.',
          'The captain pays up to ${IcStyle.money(config.buyMax)} $cur${config.receiptRequired ? ', photographs the receipt' : ''}, and you confirm the amount.');
    } else if (config.buyEnabled) {
      note = tr('الكابتن يشتري عنك بعد ${config.minRides} رحلات كاملة.', 'The captain can buy for you after ${config.minRides} completed rides.');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      chips,
      if (note != null) ...[
        const SizedBox(height: 6),
        Text(note, key: ValueKey('errand-buy-note-$index'), style: IcStyle.t(12, w: FontWeight.w700, c: IcStyle.muted)),
      ],
    ]);
  }

  /// the blue numbered disc, the same on the map
  static Widget number(int n, {double size = 26}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: stopColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: Text('$n', style: IcStyle.t(size * .5, w: FontWeight.w900, c: Colors.white).copyWith(height: 1.1)),
      );

  Widget _icon(IconData icon, String tip, VoidCallback? onTap, Key key) => IconButton(
        key: key,
        tooltip: tip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 20, color: onTap == null ? IcStyle.line : IcStyle.navy),
      );

  /// a tap anywhere else closes the keyboard (as on the parcel page)
  static Widget field(TextEditingController c, String hint, Key key, {bool phone = false}) => TextField(
        key: key,
        controller: c,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        textInputAction: TextInputAction.done,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        textDirection: phone ? TextDirection.ltr : (appRtl ? TextDirection.rtl : TextDirection.ltr),
        style: IcStyle.t(14, w: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: IcStyle.t(13, w: FontWeight.w500, c: IcStyle.muted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line, width: 1.5)),
        ),
      );
}
