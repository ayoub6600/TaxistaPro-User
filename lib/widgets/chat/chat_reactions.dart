import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../functions/functions.dart';

/// Emoji reactions in the chat with Taxista («مثل الفيسبوك»): a double tap on a message opens the six
/// emojis; the same emoji again removes it. The server keeps them (ChatReactions) and tells the admin;
/// the admin's reactions on the rider's messages come back in the chat history (`reactions`).
class ChatReactions {
  static const allowed = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  static List<Map> of(Map m) => (m['reactions'] is List ? m['reactions'] as List : const []).whereType<Map>().toList();

  static String? mine(Map m) {
    for (final r in of(m)) {
      if (r['mine'] == true) return '${r['emoji']}';
    }
    return null;
  }

  /// sends the choice; on success the message's `reactions` is replaced by the server's list
  static Future<bool> send(Map m, String? emoji) async {
    final id = '${m['id'] ?? ''}';
    if (id.isEmpty) return false;
    try {
      final r = await http
          .post(Uri.parse('${url}api/v1/request/admin-chat/$id/react'),
              headers: {
                'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'emoji': emoji}))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return false;
      final data = jsonDecode(r.body)['data'];
      if (data is Map && data['reactions'] is List) m['reactions'] = data['reactions'];
      return true;
    } catch (_) {
      return false;
    }
  }

  /// the same for a line of the ride's chat (rider <-> driver)
  static Future<bool> sendTrip(Map m, String? emoji) async {
    final id = '${m['id'] ?? ''}';
    if (id.isEmpty) return false;
    try {
      final r = await http
          .post(Uri.parse('${url}api/v1/request/chat/$id/react'),
              headers: {
                'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'emoji': emoji}))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return false;
      final data = jsonDecode(r.body)['data'];
      if (data is Map && data['reactions'] is List) m['reactions'] = data['reactions'];
      return true;
    } catch (_) {
      return false;
    }
  }

  /// the six emojis in a small floating bar; returns the chosen one ('' = remove mine)
  static Future<String?> pick(BuildContext context, {String? current}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, mainAxisSize: MainAxisSize.min, children: [
            for (final e in allowed)
              _EmojiButton(emoji: e, selected: e == current, onTap: () => Navigator.pop(ctx, e == current ? '' : e)),
          ]),
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({required this.emoji, required this.selected, required this.onTap});
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? const Color(0xffE6F0FF) : Colors.transparent),
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      );
}

/// the reactions under a bubble: «❤️» for one, «❤️ 👍» for both sides; tapping it opens the picker again
class ChatReactionChips extends StatelessWidget {
  const ChatReactionChips({super.key, required this.reactions, required this.mine, this.onTap});
  final List<Map> reactions;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    // own bubbles are always on the right (both languages): the chip sits under its own bubble
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Transform.translate(
          offset: const Offset(0, -6),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xffE3E9F2)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 6)],
              ),
              child: Text(reactions.map((r) => '${r['emoji']}').join(' '), style: const TextStyle(fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}
