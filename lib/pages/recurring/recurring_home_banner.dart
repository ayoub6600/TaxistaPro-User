import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/calls/admin_call_controller.dart' show appNavigatorKey;
import '../../functions/live_activity.dart';
import '../../functions/recurring_api.dart';
import 'recurring_rides_page.dart';

/// Home: «مشوارك غدًا» while tomorrow's day of a recurring ride still waits for his answer. The same
/// card as on the iPhone lock screen: near-black, the real Taxista Rider icon, «9:30 صباحًا · البيت ← العمل»
/// and [تأكيد] [تخطي] side by side, answered right here. The server's words replace the buttons; a lost
/// connection never shows a success.
class RecurringTomorrowBanner extends StatefulWidget {
  const RecurringTomorrowBanner({super.key, required this.ride, required this.next});
  final Map<String, dynamic> ride;
  final Map<String, dynamic> next;

  @override
  State<RecurringTomorrowBanner> createState() => _RecurringTomorrowBannerState();
}

const _card = Color(0xff0B0B0F);
const _confirm = Color(0xff0A7AFF);
const _skip = Color(0xff383838);
const _success = Color(0xff30D158);
const _warning = Color(0xffFFCC66);

TextStyle _t(double s, {FontWeight w = FontWeight.w700, Color c = Colors.white}) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: 1.3);

/// «09:30» → «9:30 صباحًا»
String _clock(String? hhmm) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(hhmm ?? '');
  if (m == null) return hhmm ?? '';
  final h = int.parse(m.group(1)!);
  return '${(h % 12) == 0 ? 12 : h % 12}:${m.group(2)} ${h < 12 ? 'صباحًا' : (h < 15 ? 'ظهرًا' : 'مساءً')}';
}

class _RecurringTomorrowBannerState extends State<RecurringTomorrowBanner> {
  String? _busy; // attend | skip while the answer is on its way
  String? _result;
  bool _ok = false;
  String? _done; // the answer that the server accepted (or refused)
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _open() => appNavigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => RecurringRidePage(uuid: '${widget.ride['id']}', initial: widget.ride, focusOccurrence: widget.next['id'] as int?)));

  Future<void> _answer(String what) async {
    if (_busy != null) return; // one tap at a time; the server also keeps one answer per day
    HapticFeedback.selectionClick();
    if (what == 'skip') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تخطي مشوار الغد؟', style: _t(17, w: FontWeight.w800, c: const Color(0xff12121D))),
            content: Text('ما يجيك سائق في هذا اليوم فقط، وباقي الأيام تكمل عادي. التخطي مجاني.',
                style: _t(14, w: FontWeight.w500, c: const Color(0xff12121D))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('رجوع', style: _t(14, c: const Color(0xff12121D)))),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xffD92D20)),
                child: Text('تخطي', style: _t(14)),
              ),
            ],
          ),
        ),
      );
      if (sure != true || !mounted) return;
    }
    setState(() {
      _busy = what;
      _result = null;
    });
    final r = await RecurringApi.answer('${widget.ride['id']}', '${widget.next['date']}', what);
    if (!mounted) return;
    setState(() {
      _busy = null;
      _ok = r.ok;
      _done = what;
      _result = r.message;
    });
    if (r.ok) {
      HapticFeedback.mediumImpact();
      unawaited(LiveActivity.endDay('${widget.next['id'] ?? ''}')); // its lock-screen card leaves too
      // the answer is read, then the card leaves the home screen (the list refresh takes it off)
      _hide = Timer(const Duration(seconds: 3), () => unawaited(RecurringApi.refresh(force: true)));
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _clock('${widget.next['time'] ?? ''}');
    final label = '${widget.ride['label'] ?? ''}'.trim();
    final detail = label.isEmpty ? time : '$time · $label';
    final failed = _result != null && !_ok;
    final coming = widget.next['answer'] == 'coming';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * -12), child: child)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Material(
          color: _card,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _open,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset('assets/images/appstore.png', width: 40, height: 40, cacheWidth: 120, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        if (_result != null && _ok) ...[
                          const Icon(Icons.check_circle_rounded, color: _success, size: 18),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(_result != null && _ok ? (_done == 'skip' ? 'تخطينا مشوار الغد' : 'تم تأكيد مشوارك') : 'مشوارك غدًا',
                              style: _t(16.5, w: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      Text(_result ?? detail,
                          style: _t(13.5, w: FontWeight.w600, c: failed ? _warning : Colors.white.withValues(alpha: .68)),
                          maxLines: _result != null ? 2 : 1,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: (_result != null && _ok)
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(children: [
                            Expanded(
                                child: coming
                                    // already confirmed (another way, or before): the button says so; تخطي stays
                                    ? _Btn(label: 'مؤكد', icon: Icons.check_rounded, color: _confirm.withValues(alpha: .35), onTap: _open)
                                    : _Btn(label: 'تأكيد', icon: Icons.check_rounded, color: _confirm, busy: _busy == 'attend', onTap: () => _answer('attend'))),
                            const SizedBox(width: 10),
                            Expanded(child: _Btn(label: 'تخطي', icon: Icons.skip_next_rounded, color: _skip, busy: _busy == 'skip', onTap: () => _answer('skip'))),
                          ]),
                        ),
                ),
              ]),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  const _Btn({required this.label, required this.icon, required this.color, required this.onTap, this.busy = false});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool busy;

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? .96 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(13)),
            child: widget.busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(widget.icon, color: Colors.white, size: 19),
                    const SizedBox(width: 6),
                    Text(widget.label, style: _t(15.5, w: FontWeight.w800)),
                  ]),
          ),
        ),
      );
}
