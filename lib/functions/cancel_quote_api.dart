import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// «تعويض الكابتن»: before the reasons, the rider learns what cancelling now costs when the driver has
/// already driven toward him. The server writes every word (title, message, buttons) and decides the
/// amount; the app only shows it and sends the answer with the cancel (`compensate`).
class CancelQuote {
  /// the server's quote for this ride, or null (nothing to show, an old server, no internet)
  static Future<Map?> fetch(String rideId) async {
    try {
      final r = await http.get(Uri.parse('${url}api/v1/request/cancel-quote?request_id=$rideId'), headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final data = jsonDecode(r.body)['data'];
      return data is Map && data['applies'] == true ? data : null;
    } catch (_) {
      return null;
    }
  }

  /// 'pay' | 'free' | null (= keep waiting for the driver)
  static Future<String?> ask(BuildContext context, Map q) {
    final mandatory = q['mandatory'] == true;
    Widget button(String text, String value, {bool primary = false, bool danger = false}) => SizedBox(
          width: double.infinity,
          height: 50,
          child: primary
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger ? const Color(0xffD92D20) : const Color(0xff0873FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context, value),
                  child: Text(text, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff344054),
                    side: const BorderSide(color: Color(0xffD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context, value),
                  child: Text(text, style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w700)),
                ),
        );
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xffE4E7EC), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xffE8F1FF), shape: BoxShape.circle),
              child: const Icon(Icons.local_taxi_rounded, color: Color(0xff0873FF), size: 34),
            ),
            const SizedBox(height: 12),
            Text('${q['title'] ?? ''}',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xff101828))),
            const SizedBox(height: 8),
            Text('${q['message'] ?? ''}',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14.5, height: 1.7, fontWeight: FontWeight.w600, color: const Color(0xff475467))),
            const SizedBox(height: 18),
            button('${q['wait_label'] ?? 'خليني نستنى الكابتن'}', 'wait', primary: true),
            const SizedBox(height: 10),
            button('${q['pay_label'] ?? ''}', 'pay', primary: mandatory, danger: mandatory),
            if (!mandatory && q['free_label'] != null) ...[
              const SizedBox(height: 10),
              button('${q['free_label']}', 'free'),
            ],
          ]),
        ),
      ),
    ).then((v) => v == 'pay' || v == 'free' ? v : null);
  }
}
