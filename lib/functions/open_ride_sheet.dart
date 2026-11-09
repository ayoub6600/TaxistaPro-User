import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// Before a ride with no destination: it stays inside the city, and it runs on the meter.
Future<bool> confirmOpenRide(BuildContext context, double lat, double lng) async {
  Map? terms;
  try {
    final r = await http
        .get(Uri.parse('${url}api/v1/request/open-ride-terms').replace(queryParameters: {'lat': '$lat', 'lng': '$lng'}),
            headers: {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) terms = jsonDecode(r.body)['data'] as Map?;
  } catch (_) {
    terms = null;
  }
  if (terms == null || !context.mounted) return true; // the booking screen still answers for this spot
  final answer = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OpenRideSheet(terms: terms!),
  );
  return answer == true;
}

class _OpenRideSheet extends StatelessWidget {
  const _OpenRideSheet({required this.terms});

  final Map terms;

  static const _navy = Color(0xff102A56);
  static const _muted = Color(0xff55678A);
  static const _blue = Color(0xff0873FF);

  TextStyle _t(double size, {FontWeight w = FontWeight.w700, Color c = _navy}) => GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: 1.5);

  String _n(Object? v) {
    final value = v as num;
    return value == value.roundToDouble() ? '${value.toInt()}' : '$value';
  }

  Widget _price(String label, Object? amount) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xffF3F7FE), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: _t(13, c: _muted)),
            Text('${_n(amount)} ${terms['currency_label']}', style: _t(20, w: FontWeight.w900)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: const Color(0xffE3E9F2), borderRadius: BorderRadius.circular(9)))),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xffE6F0FF), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.navigation_outlined, color: _blue, size: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('رحلة بدون وجهة', style: _t(21, w: FontWeight.w900)),
                  Text('تدل السائق على الطريق وأنت راكب', style: _t(14, w: FontWeight.w600, c: _muted)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: const Color(0xffFFF7E6), borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.info_outline_rounded, color: Color(0xffB45309), size: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text('الرحلة داخل حدود ${terms['city']} فقط، ولا تخرج عنها', style: _t(15, w: FontWeight.w800))),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _price('فتح العداد، يشمل أول ${_n(terms['included_km'])} كم', terms['opening']),
              const SizedBox(width: 10),
              _price('كل كيلو بعدها', terms['per_km']),
            ]),
            const SizedBox(height: 10),
            Text('السعر النهائي حسب المسافة الفعلية عند نهاية الرحلة', textAlign: TextAlign.center, style: _t(14, c: _muted)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: Text('اطلب الرحلة', style: _t(18, w: FontWeight.w900, c: Colors.white)),
            ),
          ]),
        ),
      );
}
