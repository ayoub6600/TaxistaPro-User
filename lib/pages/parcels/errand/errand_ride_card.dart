import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../functions/errand_api.dart';
import '../../../functions/intercity_api.dart' show IntercityResult;
import '../../../functions/tr.dart';
import 'errand_stop_card.dart';

/// On his ride screen during «مشوار بوقفات»: each stop with its number, place, what is taken, and
/// where the captain is with it (لسه / وصل / استلم ✓). When the captain paid at a stop: the amount,
/// the receipt, and «صحيح ✓» / «مش صحيح» — the answer goes to the server and stays shown.
class ErrandRideCard extends StatefulWidget {
  const ErrandRideCard({super.key, required this.rideId, required this.errand, this.currency = '', this.answer});

  final Object rideId;
  final Map errand;
  final String currency;

  /// tests replace the network
  final Future<IntercityResult> Function(int position, bool confirmed)? answer;

  static Widget? of(Map ride) {
    final e = ride['errand'];
    if (e is! Map || ride['id'] == null) return null;
    return ErrandRideCard(rideId: ride['id'], errand: e, currency: '${ride['requested_currency_symbol'] ?? ride['requested_currency_code'] ?? ''}');
  }

  static bool _yes(Object? v) => v == true || v == 1 || v == '1';

  static num? amount(Map stop) {
    final v = stop['purchase_amount'];
    final n = v is num ? v : num.tryParse('${v ?? ''}');
    return n != null && n > 0 ? n : null;
  }

  @override
  State<ErrandRideCard> createState() => _ErrandRideCardState();
}

class _ErrandRideCardState extends State<ErrandRideCard> {
  // answers given on this screen, until the ride's JSON carries them
  final Map<int, String> _answered = {};
  final Set<int> _sending = {};

  TextStyle _t(double s, {FontWeight w = FontWeight.w700, Color c = const Color(0xff102A56)}) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: 1.4);

  static String _money(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Future<void> _answer(int position, bool confirmed) async {
    if (_sending.contains(position)) return;
    setState(() => _sending.add(position));
    final r = widget.answer != null ? await widget.answer!(position, confirmed) : await ErrandApi.answer(widget.rideId, position, confirmed);
    if (!mounted) return;
    setState(() {
      _sending.remove(position);
      if (r.ok) _answered[position] = confirmed ? 'confirmed' : 'disputed';
    });
    if (!r.ok) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(r.message, textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr)));
    }
  }

  void _receipt(String url) => showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.network(url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                        padding: const EdgeInsets.all(24), child: Text(tr('ما قدرناش نفتحوا الصورة.', 'The photo could not open.'), style: _t(14)))),
              ),
            ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('سكّر', 'Close'), style: _t(15, w: FontWeight.w900, c: const Color(0xff0873FF)))),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.errand;
    final stops = [for (final s in (e['stops'] as List? ?? const [])) if (s is Map) s];
    final line = '${e['purchases_line'] ?? ''}'.trim();
    return Container(
      key: const ValueKey('errand-ride-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text('🛍️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(child: Text('${e['name'] ?? tr('مشوار بوقفات', 'Errand with stops')}', style: _t(15, w: FontWeight.w900))),
        ]),
        for (var i = 0; i < stops.length; i++) _stop(stops[i], i),
        if (line.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('💵 $line', key: const ValueKey('errand-purchases-line'), style: _t(12.5, w: FontWeight.w800, c: const Color(0xff16803C))),
        ],
      ]),
    );
  }

  Widget _stop(Map s, int i) {
    final position = (s['position'] as num?)?.toInt() ?? i + 1;
    final picked = ErrandRideCard._yes(s['picked']), arrived = ErrandRideCard._yes(s['arrived']);
    final (state, color) = picked
        ? (tr('استلم ✓', 'Picked up ✓'), const Color(0xff16803C))
        : arrived
            ? (tr('الكابتن وصل', 'Captain arrived'), const Color(0xffB7791F))
            : (tr('لسه', 'Not yet'), const Color(0xff55678A));
    final item = '${s['item'] ?? ''}';
    final amount = ErrandRideCard.amount(s);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        key: ValueKey('errand-ride-stop-$position'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ErrandStopCard.number(position, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item, style: _t(14, w: FontWeight.w900)),
                Text('${s['address'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12, c: const Color(0xff55678A))),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(999)),
              child: Text(state, style: _t(12, w: FontWeight.w900, c: color)),
            ),
          ]),
          if (amount != null) _purchase(s, position, item, amount),
        ]),
      ),
    );
  }

  Widget _purchase(Map s, int position, String item, num amount) {
    final receipt = '${s['receipt'] ?? ''}'.trim();
    final answer = _answered[position] ?? (s['rider_answer'] == null ? '' : '${s['rider_answer']}');
    final cur = widget.currency.isEmpty ? '' : ' ${widget.currency}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(tr('الكابتن دفع ${_money(amount)}$cur عن «$item»', 'The captain paid ${_money(amount)}$cur for «$item»'),
            key: ValueKey('errand-paid-$position'), style: _t(13.5, w: FontWeight.w900)),
        if (receipt.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: ValueKey('errand-receipt-$position'),
              onPressed: () => _receipt(receipt),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(tr('شوف الفاتورة', 'See the receipt'), style: _t(13, w: FontWeight.w800, c: const Color(0xff0873FF))),
            ),
          ),
        if (answer == 'confirmed')
          Text(tr('أكدت المبلغ ✓', 'You confirmed the amount ✓'), key: ValueKey('errand-answer-$position'), style: _t(13, w: FontWeight.w900, c: const Color(0xff16803C)))
        else if (answer == 'disputed')
          Text(tr('قلت إن المبلغ مش صحيح، نراجعوه مع الكابتن.', 'You said the amount is wrong; we will check it with the captain.'),
              key: ValueKey('errand-answer-$position'), style: _t(13, w: FontWeight.w900, c: const Color(0xffB42318)))
        else
          Row(children: [
            Expanded(
              child: FilledButton(
                key: ValueKey('errand-yes-$position'),
                onPressed: _sending.contains(position) ? null : () => _answer(position, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(tr('صحيح ✓', 'Correct ✓'), style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: ValueKey('errand-no-$position'),
                onPressed: _sending.contains(position) ? null : () => _answer(position, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffB42318),
                  side: const BorderSide(color: Color(0xffB42318), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(tr('مش صحيح', 'Not correct'), style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
      ]),
    );
  }
}
