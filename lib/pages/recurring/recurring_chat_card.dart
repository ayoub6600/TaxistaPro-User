import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../functions/functions.dart';
import '../../functions/recurring_api.dart';

/// The server's action_card under a support-chat message about a recurring ride (design v2):
/// «مشوار الدوام» with its buttons (confirm / skip a day, accept / decline a schedule) answered in
/// place, or the answer already given. The buttons post to the endpoint the server names; the
/// server's reply replaces them. An older server sends no card and the link stays in the text.
class RecurringChatCard extends StatefulWidget {
  const RecurringChatCard({super.key, required this.card, this.onAnswered});
  final Map card;
  final VoidCallback? onAnswered;

  /// the chat text without the link the card stands for
  static String textWithoutLink(String text) => text
      .replaceAll(RegExp(r'https?://\S*/r/recurring(?:-day)?/\S+'), '')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  static bool handles(Map m) {
    final c = m['action_card'];
    return c is Map && (c['type'] == 'recurring_tomorrow' || c['type'] == 'recurring_confirm');
  }

  @override
  State<RecurringChatCard> createState() => _RecurringChatCardState();
}

class _RecurringChatCardState extends State<RecurringChatCard> {
  String? _busy;
  String? _done;
  bool _failed = false;

  static const _navy = [Color(0xff102A56), Color(0xff1965BF)];

  String _plain(String label) => label.replaceAll(RegExp(r'[✅❌⏭️⏭]️?'), '').trim();

  Future<void> _press(Map b) async {
    if (_busy != null) return;
    setState(() {
      _busy = '${b['action']}';
      _failed = false;
    });
    String? message;
    var ok = false;
    try {
      final r = await http
          .post(Uri.parse('$url${'${b['endpoint']}'.replaceFirst(RegExp(r'^/'), '')}'),
              headers: {
                'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(b['body'] is Map ? b['body'] : {}))
          .timeout(const Duration(seconds: 20));
      Map body = {};
      try {
        body = jsonDecode(r.body) as Map;
      } catch (_) {}
      ok = r.statusCode == 200 && body['success'] == true;
      message = body['message']?.toString();
    } catch (_) {
      message = 'ما فيش اتصال. ما تسجلش شي؛ جرب مرة ثانية.';
    }
    if (!mounted) return;
    setState(() {
      _busy = null;
      _failed = !ok;
      _done = message ?? (ok ? 'تم' : 'ما تمش. جرب مرة ثانية.');
    });
    if (ok) {
      unawaited(RecurringApi.refresh(force: true));
      widget.onAnswered?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final buttons = (c['buttons'] is List ? c['buttons'] as List : const []).whereType<Map>().toList();
    final date = DateTime.tryParse('${c['date'] ?? ''}');
    final sub = c['type'] == 'recurring_confirm'
        ? 'جدول رحلات متكرر جاهز لتأكيدك'
        : (date == null ? '' : 'يوم ${date.day}/${date.month}');
    final answered = _done ?? (buttons.isEmpty ? (c['done_label']?.toString()) : null);
    return Align(
      // beside the support's own bubbles (the far side from the rider's)
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: _navy), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.repeat_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${c['title'] ?? 'مشوار الدوام'}', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  if (sub.isNotEmpty) Text(sub, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            if (answered != null)
              Row(children: [
                Icon(
                  _failed
                      ? Icons.error_outline_rounded
                      : (answered.contains('⏭') || answered.contains('تخط') ? Icons.skip_next_rounded : Icons.check_circle_rounded),
                  size: 18,
                  color: _failed ? const Color(0xffFFCC66) : const Color(0xff30D158),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_plain(answered),
                      style: GoogleFonts.cairo(color: _failed ? const Color(0xffFFCC66) : Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
              ])
            else
              Row(children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: i == 0 ? const Color(0xff0A7AFF) : Colors.white.withValues(alpha: .16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        onPressed: _busy == null ? () => _press(buttons[i]) : null,
                        child: _busy == '${buttons[i]['action']}'
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(_icon('${buttons[i]['action']}'), size: 18, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(_plain('${buttons[i]['label'] ?? ''}'),
                                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                              ]),
                      ),
                    ),
                  ),
                ],
              ]),
          ]),
        ),
      ),
    );
  }

  IconData _icon(String action) => switch (action) {
        'attend' || 'confirm' => Icons.check_rounded,
        'skip' => Icons.skip_next_rounded,
        _ => Icons.close_rounded,
      };
}
