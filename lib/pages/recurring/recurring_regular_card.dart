import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/recurring_api.dart';

/// «سائقك الثابت» on a schedule's page: the question after a good ride, then who it is.
class RecurringRegularCard extends StatefulWidget {
  const RecurringRegularCard({super.key, required this.ride, required this.onChanged});

  final Map<String, dynamic> ride;
  final VoidCallback onChanged;

  @override
  State<RecurringRegularCard> createState() => _RecurringRegularCardState();
}

class _RecurringRegularCardState extends State<RecurringRegularCard> {
  bool _busy = false;
  String? _error;

  Map get _r => (widget.ride['regular'] as Map?) ?? const {};

  TextStyle _t(double s, [FontWeight w = FontWeight.w700]) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: const Color(0xff102A56));

  Future<void> _answer(String a) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await RecurringApi.regular('${widget.ride['id']}', a);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!res.ok) _error = '${res.body['message'] ?? 'ما تمش، جرب مرة ثانية'}';
    });
    if (res.ok) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final status = _r['status'];
    final name = '${_r['driver_name'] ?? ''}';
    if (status != 'asked' && status != 'rider_yes' && status != 'active' && status != 'declined') return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xffE3E9F4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (status == 'asked') ...[
          Text('تبي $name يكون سائقك الثابت؟', style: _t(16, FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: FilledButton(onPressed: _busy ? null : () => _answer('yes'), child: const Text('نعم'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _answer('no'), child: const Text('لا'))),
          ]),
        ],
        if (status == 'rider_yes') Text('ننتظر رد $name.', style: _t(15)),
        if (status == 'declined') Text('$name ما يقدرش يثبت. مشوارك مفتوح لكل السائقين.', style: _t(15)),
        if (status == 'active') ...[
          Text('$name سائقك الثابت', style: _t(16, FontWeight.w800)),
          if ('${_r['car'] ?? ''}'.isNotEmpty) Text('${_r['car']}', style: _t(13, FontWeight.w600)),
          TextButton(onPressed: _busy ? null : () => _answer('stop'), child: const Text('رجّع المشوار مفتوحًا للسائقين')),
        ],
        if (_error != null) Text(_error!, style: _t(13).copyWith(color: const Color(0xffC81E3A))),
      ]),
    );
  }
}
