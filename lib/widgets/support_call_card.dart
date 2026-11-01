import 'package:flutter/material.dart';

import '../styles/styles.dart' show isDarkTheme;

/// A call with the administration, as a card in the chat with it: which way it went, how it
/// ended (with its length), when, and - when the administration takes calls now - "call again".
/// The server sends the card already worded for this side (message_type 'call', see CallChatLog).
class SupportCallCard extends StatelessWidget {
  final Map call;
  final String? time;
  final bool highlighted;
  final VoidCallback? onCallBack;

  const SupportCallCard({super.key, required this.call, this.time, this.highlighted = false, this.onCallBack});

  /// The card for a chat message, or null when the message is not a call.
  static SupportCallCard? fromMessage(Map message, {bool highlighted = false, VoidCallback? onCallBack}) {
    if (message['message_type'] != 'call' || message['call'] is! Map) return null;
    return SupportCallCard(
        call: message['call'] as Map,
        time: message['user_timezone']?.toString(),
        highlighted: highlighted,
        onCallBack: onCallBack);
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkTheme == true;
    final missed = call['missed'] == true;
    final outgoing = call['direction'] == 'outgoing';
    final accent = missed ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8);
    final ink = dark ? const Color(0xFFE8EDF6) : const Color(0xFF0F172A);
    final sub = dark ? const Color(0xFFC3CBDA) : const Color(0xFF475569);
    final canCallBack = call['can_call_back'] == true && onCallBack != null;
    final title = call['title']?.toString() ?? 'مكالمة صوتية';
    final label = call['label']?.toString() ?? '';

    return Semantics(
      container: true,
      label: '$title، $label',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1A2438) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: highlighted ? const Color(0xFFF59E0B) : (dark ? const Color(0xFF243049) : const Color(0xFFE2E8F0)),
              width: highlighted ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: accent.withValues(alpha: dark ? 0.22 : 0.1), shape: BoxShape.circle),
              child: Icon(missed ? Icons.phone_missed : (outgoing ? Icons.call_made : Icons.call_received), size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(fontSize: 13, color: missed ? accent : sub)),
                  if (time != null && time!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(time!, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 11, color: sub.withValues(alpha: 0.8))),
                    ),
                ],
              ),
            ),
            if (canCallBack) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onCallBack,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(48, 40),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.call, size: 16),
                label: const Text('إعادة الاتصال', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
