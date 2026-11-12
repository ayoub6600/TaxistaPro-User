import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'functions.dart';

/// «تاكسيستا قريبًا في طرابلس»: the rider stands in a city we drew but haven't opened yet.
/// The server says so in the market-switch answer (`coming_soon`); «بلّغني لما تفتح» puts him on
/// the city's list and the launch-day push reaches him. Shown at most twice a day, never once he asked.
class CityLaunch {
  static const _seenKey = 'city_launch_seen_';
  static const _again = Duration(hours: 12);
  static bool _open = false;

  static Future<void> maybeShow(BuildContext context, Object? soon) async {
    if (_open || soon is! Map || soon['zone_id'] == null || soon['subscribed'] == true) return;
    final zone = '${soon['zone_id']}';
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getInt('$_seenKey$zone') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - seen < _again.inMilliseconds || !context.mounted) return;
    await prefs.setInt('$_seenKey$zone', DateTime.now().millisecondsSinceEpoch);
    if (!context.mounted) return;
    _open = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CityLaunchSheet(data: Map<String, dynamic>.from(soon), notify: () => notifyMe(zone)),
      );
    } finally {
      _open = false;
    }
  }

  /// true when the server put him on the list
  static Future<bool> notifyMe(String zoneId) async {
    try {
      final r = await http.post(Uri.parse('${url}api/v1/request/city-launch/notify-me'),
          headers: {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'}, body: {'zone_id': zoneId}).timeout(const Duration(seconds: 15));
      return r.statusCode == 200 && jsonDecode(r.body)['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

class CityLaunchSheet extends StatefulWidget {
  const CityLaunchSheet({super.key, required this.data, required this.notify});

  final Map<String, dynamic> data;
  final Future<bool> Function() notify;

  @override
  State<CityLaunchSheet> createState() => _CityLaunchSheetState();
}

class _CityLaunchSheetState extends State<CityLaunchSheet> {
  static const _navy = Color(0xff102A56);
  static const _muted = Color(0xff55678A);
  static const _blue = Color(0xff0873FF);

  bool _busy = false;
  bool _done = false;
  bool _failed = false;

  TextStyle _t(double size, {FontWeight w = FontWeight.w700, Color c = _navy}) => GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: 1.5);

  Future<void> _ask() async {
    setState(() => [_busy = true, _failed = false]);
    final ok = await widget.notify();
    if (mounted) setState(() => [_busy = false, _done = ok, _failed = !ok]);
  }

  @override
  Widget build(BuildContext context) {
    final city = '${widget.data['city'] ?? ''}';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: const Color(0xffE3E9F2), borderRadius: BorderRadius.circular(9)))),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xffFFF4D6), borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.local_taxi_rounded, color: Color(0xffE0A100), size: 34),
            ),
          ),
          const SizedBox(height: 12),
          Text('${widget.data['title'] ?? 'تاكسيستا قريبًا في $city 🚖'}', textAlign: TextAlign.center, style: _t(21, w: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            _done ? 'تمام 👍 أول ما نفتحوا في $city يوصلك إشعار.' : '${widget.data['body'] ?? 'نجهزوا في السائقين هنا. اضغط «بلّغني» ونبعتولك إشعار أول ما نفتحوا.'}',
            textAlign: TextAlign.center,
            style: _t(14.5, w: FontWeight.w600, c: _done ? const Color(0xff0F8A4B) : _muted),
          ),
          if (_failed) ...[
            const SizedBox(height: 6),
            Text('ما قدرناش نسجلوك، جرّب مرة ثانية.', textAlign: TextAlign.center, style: _t(13.5, c: const Color(0xffD92D20))),
          ],
          const SizedBox(height: 16),
          if (!_done)
            FilledButton(
              onPressed: _busy ? null : _ask,
              style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: _busy
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                  : Text('🔔 بلّغني لما تفتح', style: _t(18, w: FontWeight.w900, c: Colors.white)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_done ? 'تمام' : 'ليس الآن', style: _t(16, w: FontWeight.w800, c: _muted))),
        ]),
      ),
    );
  }
}
