import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../functions/calls/admin_call_api.dart';
import '../functions/calls/admin_call_controller.dart';
import '../functions/functions.dart';
import '../pages/chatPage/trip_chat_page.dart';

/// Under the driver of a ride in the trip history: a free call through Taxista (during the ride
/// and up to 24 hours after it) and the chat of that ride. The driver's phone number is not shown.
class TripContactActions extends StatefulWidget {
  final String requestId;
  final String driverName;
  final String? driverPhoto;
  final String? details;

  const TripContactActions({super.key, required this.requestId, required this.driverName, this.driverPhoto, this.details});

  @override
  State<TripContactActions> createState() => _TripContactActionsState();
}

class _TripContactActionsState extends State<TripContactActions> {
  bool _calling = false;

  bool get _ar => languageDirection == 'rtl';
  String _t(String ar, String en) => _ar ? ar : en;

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TripChatPage(
          requestId: widget.requestId, driverName: widget.driverName, driverPhoto: widget.driverPhoto, details: widget.details),
    ));
  }

  Future<void> _call() async {
    if (_calling) return;
    setState(() => _calling = true);
    final available = await AdminCallApi.availability(requestId: widget.requestId);
    String? problem;
    if (!available.ok) {
      problem = available.message;
    } else if (available.data['can_call_driver'] != true) {
      problem = _t('الاتصال المجاني بالسائق متاح أثناء الرحلة وحتى 24 ساعة بعد انتهائها. يمكنك مراسلته.',
          'The free call is available during the ride and up to 24 hours after it. You can write to the driver.');
    } else {
      problem = await AdminCallController.instance.callDriver(requestId: widget.requestId);
    }
    if (!mounted) return;
    setState(() => _calling = false);
    if (problem == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(problem),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(label: _t('مراسلة', 'Write'), onPressed: _openChat),
    ));
  }

  Widget _action({required IconData icon, required String label, required Color color, required VoidCallback onTap, bool busy = false}) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            busy
                ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: color))
                : Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _action(
          icon: Icons.call_rounded,
          label: _t('اتصال مجاني', 'Free call'),
          color: const Color(0xFF16A34A),
          onTap: _call,
          busy: _calling,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _action(
          icon: Icons.chat_bubble_rounded,
          label: _t('محادثة السائق', 'Chat with driver'),
          color: const Color(0xFF0873FF),
          onTap: _openChat,
        ),
      ),
    ]);
  }
}
