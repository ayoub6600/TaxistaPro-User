import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'functions.dart';
import 'service_zones.dart';

/// The rider is in another country than his account's: he hears it on the home screen, before
/// any request, and his yes moves the account. «ليس الآن» holds the question back for a day.
class MarketSwitch {
  static const _snoozeKey = 'market_switch_snooze_until';
  static const _lookEvery = Duration(minutes: 3);
  static const _navy = Color(0xff102A56);
  static const _muted = Color(0xff55678A);
  static const _blue = Color(0xff0873FF);

  static DateTime? _lookedAt;
  static bool _open = false;

  static Map<String, String> get _headers => {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'};
  static Uri get _base => Uri.parse('${url}api/v1/request/market-switch');

  static TextStyle _t(double size, {FontWeight w = FontWeight.w700, Color c = _navy}) => GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: 1.5);

  /// call with the rider's position whenever he is on the home screen
  static Future<void> look(BuildContext context, double lat, double lng) async {
    final last = _lookedAt;
    if (_open || bearerToken.isEmpty || (last != null && DateTime.now().difference(last) < _lookEvery)) return;
    _lookedAt = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (DateTime.now().millisecondsSinceEpoch < (prefs.getInt(_snoozeKey) ?? 0)) return;
      final r = await http.get(_base.replace(queryParameters: {'lat': '$lat', 'lng': '$lng'}), headers: _headers).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200 || !context.mounted) return;
      final data = Map<String, dynamic>.from(jsonDecode(r.body)['data'] as Map);
      if (data['state'] != 'ask') return;
      _open = true;
      final yes = await _ask(context, data);
      _open = false;
      if (yes) {
        await http.post(_base, headers: _headers, body: {'lat': '$lat', 'lng': '$lng'}).timeout(const Duration(seconds: 15));
        await getUserDetails();
        await ServiceZones.load(force: true);
      } else {
        await prefs.setInt(_snoozeKey, DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch);
      }
    } catch (_) {
      _open = false; // the booking still works and the server still refuses what it must
    }
  }

  static Future<bool> _ask(BuildContext context, Map data) async {
    final to = Map.from(data['to'] as Map);
    final from = data['from'] is Map ? Map.from(data['from'] as Map) : const {};
    final answer = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: const Color(0xffE3E9F2), borderRadius: BorderRadius.circular(9)))),
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: const Color(0xffE6F0FF), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.public_rounded, color: _blue, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text('موقعك الآن في ${to['country']}${from['country'] == null ? '' : '، مش في ${from['country']}'}', textAlign: TextAlign.center, style: _t(21, w: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('سنحوّلك إلى ${to['country']} حتى تظهر لك خدماتها وأسعارها', textAlign: TextAlign.center, style: _t(14.5, w: FontWeight.w600, c: _muted)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xffF3F7FE), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _row('الأسعار', 'بال${to['currency_label']}'),
                if (data['cash_only'] == true) ...[
                  const SizedBox(height: 8),
                  _row('الدفع', 'كاش للسائق'),
                  const SizedBox(height: 8),
                  _row('محفظتك بال${data['wallet_currency']}', 'تبقى محفوظة'),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: Text('نعم، حوّلني إلى ${to['country']}', style: _t(18, w: FontWeight.w900, c: Colors.white)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ليس الآن', style: _t(16, w: FontWeight.w800, c: _muted))),
          ]),
        ),
      ),
    );
    return answer == true;
  }

  static Widget _row(String label, String value) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: _t(14.5, c: _muted)),
        Text(value, style: _t(14.5)),
      ]);
}
