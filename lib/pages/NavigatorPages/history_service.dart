import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/service_kind.dart';
import '../../functions/tr.dart';
import 'history_again.dart';

TextStyle _t(double s, {FontWeight w = FontWeight.w700, Color c = const Color(0xff102A56)}) =>
    GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: 1.4);

/// The trip's kind on its history card: «📦 طرد لـأحمد», «🚛 ونش», «🚕 رحلة», each in its own colour.
class HistoryServiceTitle extends StatelessWidget {
  const HistoryServiceTitle({super.key, required this.ride});

  final Map ride;

  @override
  Widget build(BuildContext context) {
    final k = ServiceKind.of(ride);
    return Container(
      key: ValueKey('history-kind-${k.kind}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: k.color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12), border: Border.all(color: k.color.withValues(alpha: .3))),
      child: Text(k.title(ride), maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13.5, w: FontWeight.w900, c: k.color)),
    );
  }
}

/// the history card's first line under the status: the kind, and «اطلبها مرة ثانية» when it can be
class HistoryServiceHeader extends StatelessWidget {
  const HistoryServiceHeader({super.key, required this.ride, this.onAgain});

  final Map ride;
  final VoidCallback? onAgain;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Flexible(child: Align(alignment: AlignmentDirectional.centerStart, child: HistoryServiceTitle(ride: ride))),
          const SizedBox(width: 8),
          HistoryAgainButton(ride: ride, onAgain: onAgain),
        ]),
      );
}

/// «🔁 اطلبها مرة ثانية»: a parcel or an ordinary ride with both places
class HistoryAgainButton extends StatelessWidget {
  const HistoryAgainButton({super.key, required this.ride, this.onAgain});

  final Map ride;

  /// tests replace what it opens
  final VoidCallback? onAgain;

  @override
  Widget build(BuildContext context) {
    if (!HistoryAgain.can(ride)) return const SizedBox.shrink();
    final k = ServiceKind.of(ride);
    return TextButton.icon(
      key: const ValueKey('history-again'),
      onPressed: onAgain ?? () => HistoryAgain.open(context, ride),
      style: TextButton.styleFrom(
        foregroundColor: k.color,
        backgroundColor: k.color.withValues(alpha: .08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Text('🔁', style: TextStyle(fontSize: 14)),
      label: Text(tr('اطلبها مرة ثانية', 'Book it again'), style: _t(13.5, w: FontWeight.w900, c: k.color)),
    );
  }
}

/// On the trip's details page: what this parcel / tow / freight was (owner 2026-11-19).
class HistoryServiceDetails extends StatelessWidget {
  const HistoryServiceDetails({super.key, required this.ride, this.showTitle = true});

  final Map ride;
  final bool showTitle;

  /// the lines to show, label → text (empty for an ordinary ride)
  static List<(String, String)> lines(Map ride) {
    final out = <(String, String)>[];
    void add(String label, Object? v) {
      final s = '${v ?? ''}'.trim();
      if (s.isNotEmpty && s != 'null') out.add((label, s));
    }

    final p = ride['parcel'];
    if (p is Map) {
      final phone = '${p['receiver_phone'] ?? ''}'.trim();
      add(tr('المستلم', 'Receiver'), [p['receiver_name'], if (phone.isNotEmpty) '\u2066$phone\u2069'].where((e) => '${e ?? ''}'.isNotEmpty).join(' · '));
      add(tr('الحجم', 'Size'), p['size_label'] ?? p['size']);
      final pay = p['pay'];
      add(
          tr('الدفع', 'Payment'),
          pay is Map && '${pay['sender'] ?? ''}'.trim().isNotEmpty
              ? pay['sender']
              : p['payer'] == 'receiver'
                  ? tr('المستلم كاش وقت التسليم', 'The receiver, cash at delivery')
                  : tr('أنا', 'Me'));
      add(tr('التسليم', 'Hand-over'), p['needs_code'] == false ? tr('🔓 بدون كود', '🔓 Without a code') : tr('🔒 بكود', '🔒 With a code'));
      add(tr('ملاحظة', 'Note'), p['note']);
      final problem = p['problem'];
      if (problem is Map) add(tr('⚠️ مشكلة', '⚠️ Problem'), [problem['label'], problem['note']].where((e) => '${e ?? ''}'.trim().isNotEmpty).join(' · '));
    }
    final t = ride['tow'];
    if (t is Map) {
      add(tr('الساحبة', 'Tow truck'), t['kind_label']);
      add(tr('شن صار', 'What happened'), t['condition_label']);
      add(tr('السيارة', 'Car'), t['car_label']);
      if (t['workshop'] is Map) add(tr('الورشة', 'Workshop'), (t['workshop'] as Map)['name']);
      add(tr('ملاحظة', 'Note'), t['note']);
    }
    final f = ride['freight'];
    if (f is Map) {
      add(tr('السيارة', 'Vehicle'), f['class_label']);
      add(tr('الحمولة', 'Load'), [f['category_label'], f['items']].where((e) => '${e ?? ''}'.trim().isNotEmpty).join(' · '));
      final w = (f['workers'] as num?)?.toInt() ?? 0;
      if (w > 0) add(tr('العمال', 'Workers'), '$w');
      add(tr('الاستلام', 'Pickup floor'), f['pick_floor_label']);
      add(tr('التسليم', 'Drop floor'), f['drop_floor_label']);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final k = ServiceKind.of(ride);
    final l = lines(ride);
    if (l.isEmpty) return const SizedBox.shrink();
    return Container(
      key: ValueKey('history-details-${k.kind}'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: k.color.withValues(alpha: .06), borderRadius: BorderRadius.circular(16), border: Border.all(color: k.color.withValues(alpha: .25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (showTitle) ...[
          Text(k.title(ride), style: _t(15, w: FontWeight.w900, c: k.color)),
          const SizedBox(height: 4),
        ],
        for (final (label, text) in l)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 92, child: Text(label, style: _t(12.5, c: const Color(0xff55678A)))),
              Expanded(child: Text(text, style: _t(13, w: FontWeight.w800))),
            ]),
          ),
      ]),
    );
  }
}
