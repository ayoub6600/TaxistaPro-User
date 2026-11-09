import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// Asked the moment a destination is pinned: outside the city the rider hears why, right there.
/// No answer from the server lets him go on; the booking itself is refused there too.
Future<bool> destinationAllowed(BuildContext context, LatLng pick, LatLng drop) async {
  String? why;
  try {
    final r = await http.get(
      Uri.parse('${url}api/v1/request/drop-check').replace(queryParameters: {
        'pick_lat': '${pick.latitude}',
        'pick_lng': '${pick.longitude}',
        'drop_lat': '${drop.latitude}',
        'drop_lng': '${drop.longitude}',
      }),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) why = jsonDecode(r.body)['refused']?.toString();
  } catch (_) {
    return true;
  }
  if (why == null) return true;
  if (context.mounted) await _showRefusal(context, why);
  return false;
}

Future<void> _showRefusal(BuildContext context, String why) {
  final cut = why.indexOf('. ');
  final title = cut < 0 ? why : why.substring(0, cut);
  final body = cut < 0 ? '' : why.substring(cut + 2);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: const Color(0xffFFF4DC), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.wrong_location_outlined, color: Color(0xffB45309), size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xff102A56), height: 1.4)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xff55678A), height: 1.6)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff0873FF), minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Text('غيّر الوجهة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
      ),
    ),
  );
}
