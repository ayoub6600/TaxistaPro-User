import 'dart:async';

import 'package:flutter/material.dart';

import '../../functions/calls/admin_call_controller.dart';
import '../../functions/functions.dart';
import '../NavigatorPages/adminchatpage.dart';
import '../chatPage/chat_page.dart';

/// Taxista's call screen: who is on the other side (photo, name, what they are), the call's state
/// and clock, and the controls - answer / decline when it rings, mute / speaker / hang up during
/// the call, the chat with that person at any time. Dark Taxista blue, right to left, the same in
/// light and dark mode. (A locked iPhone shows Apple's own CallKit screen instead.)
class AdminCallPage extends StatefulWidget {
  const AdminCallPage({super.key});

  static bool isOpen = false;

  @override
  State<AdminCallPage> createState() => _AdminCallPageState();
}

class _AdminCallPageState extends State<AdminCallPage> {
  final AdminCallController call = AdminCallController.instance;
  Timer? _clock;

  static const _blue = Color(0xFF1D4ED8);
  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFE11D48);

  @override
  void initState() {
    super.initState();
    AdminCallPage.isOpen = true;
    call.addListener(_changed);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && call.status == 'accepted') setState(() {});
    });
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (call.status == 'idle') Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    AdminCallPage.isOpen = false;
    call.removeListener(_changed);
    _clock?.cancel();
    super.dispose();
  }

  String _elapsed() {
    final since = call.answeredAt;
    if (since == null) return call.statusLabel;
    final s = DateTime.now().difference(since).inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// The chat with the person on the call; the call goes on (the green bar brings it back).
  void _openChat() {
    final target = call.chat;
    if (target == null) return;
    if (target['type'] == 'trip') {
      if (userRequestData.isEmpty || userRequestData['id']?.toString() != target['request_id']?.toString()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محادثة الرحلة متاحة أثناء الرحلة فقط.'), behavior: SnackBarBehavior.floating));
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminChatPage()));
    }
  }

  IconData get _peerIcon => {'admin': Icons.support_agent, 'rider': Icons.person, 'driver': Icons.local_taxi}[call.peer['type']] ?? Icons.person;

  Widget _round({required IconData icon, required String label, required Color color, Color iconColor = Colors.white, double size = 70, required VoidCallback? onTap}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: size / 2 + 8,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: size * 0.44),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _avatar() {
    final photo = call.peer['photo']?.toString();
    return Container(
      width: 132,
      height: 132,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08), border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2)),
      child: ClipOval(
        child: photo != null && photo.isNotEmpty
            ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _iconAvatar())
            : _iconAvatar(),
      ),
    );
  }

  Widget _iconAvatar() => Container(color: const Color(0xFF2C4FA8), alignment: Alignment.center, child: Icon(_peerIcon, color: Colors.white, size: 58));

  @override
  Widget build(BuildContext context) {
    final ringingHere = call.status == 'incoming';
    final live = call.status != 'ended' && call.status != 'idle';
    final type = call.peer['type']?.toString() ?? 'admin';
    final sub = [
      type == 'admin' ? 'الدعم والتشغيل' : AdminCallController.roleLabel(type),
      if (call.peer['car'] != null) call.peer['car'],
      if (call.peer['plate'] != null) call.peer['plate'],
    ].where((x) => x != null && x.toString().isNotEmpty).join(' · ');

    return PopScope(
      canPop: !live || call.status == 'accepted' || call.status == 'reconnecting',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.3, colors: [Color(0xFF1F3B7A), Color(0xFF0D1A3D), Color(0xFF070E22)]),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
                child: Column(children: [
                  Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/images/logo.png', width: 34, height: 34, fit: BoxFit.cover)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('مكالمة تاكسيستا', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.lock_outline, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    const Text('مشفّرة', style: TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ]),
                  const Spacer(flex: 2),
                  _avatar(),
                  const SizedBox(height: 22),
                  Text(call.peerName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  if (sub.isNotEmpty) Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(call.status),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (call.status == 'reconnecting') ...[
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent)),
                          const SizedBox(width: 8),
                        ],
                        Text(call.status == 'accepted' ? _elapsed() : call.statusLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: call.status == 'reconnecting' ? Colors.amberAccent : Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  if (call.chat != null && !ringingHere)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: OutlinedButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('الدردشة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                      ),
                    ),
                  if (ringingHere)
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _round(icon: Icons.call_end, label: 'رفض', color: _red, size: 76, onTap: call.decline),
                      _round(icon: Icons.call, label: 'رد', color: _green, size: 76, onTap: () => call.answer(call.callId ?? '')),
                    ])
                  else if (live)
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _round(
                        icon: call.muted ? Icons.mic_off : Icons.mic,
                        label: call.muted ? 'إلغاء الكتم' : 'كتم',
                        color: call.muted ? Colors.white : Colors.white24,
                        iconColor: call.muted ? const Color(0xFF0D1A3D) : Colors.white,
                        onTap: () => call.setMuted(!call.muted),
                      ),
                      _round(
                        icon: call.speaker ? Icons.volume_up : Icons.volume_down,
                        label: 'مكبر الصوت',
                        color: call.speaker ? Colors.white : Colors.white24,
                        iconColor: call.speaker ? _blue : Colors.white,
                        onTap: call.toggleSpeaker,
                      ),
                      _round(icon: Icons.call_end, label: 'إنهاء', color: _red, onTap: () => call.hangUp()),
                    ])
                  else
                    _round(icon: Icons.close, label: 'إغلاق', color: Colors.white24, onTap: () => Navigator.of(context).maybePop()),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// While a call goes on and its screen is not shown: a green bar on top of every screen that
/// brings the call back (like the phone's own "return to call" bar).
class OngoingCallBar extends StatelessWidget {
  const OngoingCallBar({super.key});

  @override
  Widget build(BuildContext context) {
    final call = AdminCallController.instance;
    return AnimatedBuilder(
      animation: call,
      builder: (context, _) {
        if (!call.busy || AdminCallPage.isOpen || call.status == 'incoming') return const SizedBox.shrink();
        return Material(
          color: const Color(0xFF16A34A),
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: call.openScreen,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(children: [
                    const Icon(Icons.call, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('مكالمة جارية مع ${call.peerName} — اضغط للعودة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
