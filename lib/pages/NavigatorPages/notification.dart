import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/pages/login/login.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';

/// «الإشعارات» (design v2): filter chips, the list grouped by day, an icon per kind, a dot on the
/// unread ones, a swipe (or the bin) to delete after a confirmation, the full text in a sheet.
/// Same server calls as before: getnotificationHistory, getNotificationPages, deleteNotification.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

/// the kinds the filters know, from the server's push_type (a notification with a ride is a ride)
enum NoticeKind { rides, money, support, offers }

NoticeKind noticeKind(Map n) {
  final t = '${n['push_type'] ?? ''}'.toLowerCase();
  if (t.contains('wallet') || t.contains('gold') || t.contains('change_return') || t.contains('reward') || t.contains('transfer') || t.contains('topup')) {
    return NoticeKind.money;
  }
  if (t.startsWith('admin_call') || t.contains('support') || t.contains('chat') || t.contains('profile')) {
    return NoticeKind.support;
  }
  if (n['request_id'] != null ||
      t.contains('ride') ||
      t.contains('request') ||
      t.contains('trip') ||
      t.contains('scheduled') ||
      t.contains('pickup') ||
      t.contains('pulse') ||
      t.contains('recurring')) {
    return NoticeKind.rides;
  }
  return NoticeKind.offers;
}

/// «7th Nov 12:07 PM» (the server's text) as a date this year; null when it does not read
DateTime? noticeTime(Map n, {DateTime? now}) {
  final m = RegExp(r'^(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3})\w*\s+(\d{1,2}):(\d{2})\s*([AP]M)?', caseSensitive: false)
      .firstMatch('${n['converted_created_at'] ?? ''}'.trim());
  if (m == null) return null;
  const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
  final month = months.indexOf(m.group(2)!.toLowerCase()) + 1;
  if (month == 0) return null;
  var hour = int.parse(m.group(3)!) % 12;
  if ((m.group(5) ?? '').toUpperCase() == 'PM') hour += 12;
  final n0 = now ?? DateTime.now();
  var t = DateTime(n0.year, month, int.parse(m.group(1)!), hour, int.parse(m.group(4)!));
  if (t.isAfter(n0.add(const Duration(days: 2)))) t = DateTime(n0.year - 1, t.month, t.day, t.hour, t.minute);
  return t;
}

class _NotificationPageState extends State<NotificationPage> {
  bool _loading = true;
  bool _more = false;
  NoticeKind? _filter;

  bool get _rtl => languageDirection == 'rtl';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final val = await getnotificationHistory();
    if (!mounted) return;
    if (val == 'logout') return _logout();
    setState(() => _loading = false);
  }

  void _logout() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));

  Future<void> _loadMore() async {
    setState(() => _more = true);
    final val = await getNotificationPages('page=${notificationHistoryPage['pagination']['current_page'] + 1}');
    if (!mounted) return;
    if (val == 'logout') return _logout();
    setState(() => _more = false);
  }

  Future<bool> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(languages[choosenLanguage]?['text_delete_notification']?.toString() ?? (_rtl ? 'حذف الإشعار؟' : 'Delete notification?'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(languages[choosenLanguage]?['text_no']?.toString() ?? 'No')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xffE0243A)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(languages[choosenLanguage]?['text_yes']?.toString() ?? 'Yes'),
            ),
          ],
        ),
      ),
    );
    return yes == true;
  }

  Future<bool> _delete(Map n) async {
    if (!await _confirmDelete()) return false;
    final result = await deleteNotification(n['id']);
    if (!mounted) return false;
    if (result == 'logout') {
      _logout();
      return false;
    }
    if (result != 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_rtl ? 'ما تمش الحذف. جرب مرة ثانية.' : 'Could not delete. Try again.')));
      return false;
    }
    setState(() => notificationHistory.remove(n));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languages[choosenLanguage]?['text_notification_deleted']?.toString() ?? (_rtl ? 'انحذف الإشعار' : 'Deleted'))));
    unawaited(_load());
    return true;
  }

  void _open(Map n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: page,
      builder: (ctx) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${n['title'] ?? ''}', style: GoogleFonts.cairo(color: textColor, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('${n['body'] ?? ''}', style: GoogleFonts.cairo(color: textColor.withValues(alpha: .8), fontSize: 14.5, height: 1.6)),
              if (n['image'] != null && '${n['image']}'.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network('${n['image']}', fit: BoxFit.cover)),
              ],
              const SizedBox(height: 8),
              Text('${n['converted_created_at'] ?? ''}', style: GoogleFonts.notoSans(color: textColor.withValues(alpha: .5), fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = notificationHistory.whereType<Map>().where((n) => n.isNotEmpty).toList();
    final shown = _filter == null ? items : items.where((n) => noticeKind(n) == _filter).toList();
    final pagination = notificationHistoryPage['pagination'];
    final hasMore = pagination is Map && (pagination['current_page'] ?? 0) < (pagination['total_pages'] ?? 0);
    return ValueListenableBuilder(
      valueListenable: valueNotifierHome.value,
      builder: (context, value, child) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: page,
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: textColor),
                    style: IconButton.styleFrom(backgroundColor: textColor.withValues(alpha: .05), fixedSize: const Size(44, 44)),
                  ),
                  const SizedBox(width: 8),
                  Text(languages[choosenLanguage]?['text_notification']?.toString() == null || _rtl ? 'الإشعارات' : languages[choosenLanguage]['text_notification'].toString(),
                      style: GoogleFonts.cairo(color: textColor, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    _chip(null, _rtl ? 'الكل' : 'All'),
                    _chip(NoticeKind.rides, _rtl ? 'الرحلات' : 'Rides'),
                    _chip(NoticeKind.money, _rtl ? 'المحفظة والمال' : 'Wallet'),
                    _chip(NoticeKind.support, _rtl ? 'الدعم' : 'Support'),
                    _chip(NoticeKind.offers, _rtl ? 'العروض' : 'Offers'),
                  ],
                ),
              ),
              Expanded(
                child: _loading && items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: shown.isEmpty
                            ? ListView(children: [
                                const SizedBox(height: 120),
                                Icon(Icons.notifications_off_outlined, size: 56, color: textColor.withValues(alpha: .25)),
                                const SizedBox(height: 10),
                                Center(
                                  child: Text(_rtl ? 'ما فيش إشعارات هنا' : 'No notifications here',
                                      style: GoogleFonts.cairo(color: textColor.withValues(alpha: .55), fontSize: 15, fontWeight: FontWeight.w700)),
                                ),
                              ])
                            : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
                                ..._grouped(shown),
                                if (hasMore)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Center(
                                      child: _more
                                          ? const CircularProgressIndicator()
                                          : TextButton(
                                              onPressed: _loadMore,
                                              child: Text(languages[choosenLanguage]?['text_loadmore']?.toString() ?? (_rtl ? 'عرض المزيد' : 'Load more'),
                                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                                            ),
                                    ),
                                  ),
                              ]),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(NoticeKind? kind, String label) {
    final on = _filter == kind;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13, color: on ? Colors.white : textColor)),
        selected: on,
        showCheckmark: false,
        selectedColor: theme,
        backgroundColor: textColor.withValues(alpha: .05),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        onSelected: (_) => setState(() => _filter = kind),
      ),
    );
  }

  /// «اليوم», «هذا الأسبوع», «أقدم»: in the server's order
  List<Widget> _grouped(List<Map> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String bucket(Map n) {
      final t = noticeTime(n, now: now);
      if (t == null) return _rtl ? 'أقدم' : 'Earlier';
      if (!t.isBefore(today)) return _rtl ? 'اليوم' : 'Today';
      if (today.difference(DateTime(t.year, t.month, t.day)).inDays < 7) return _rtl ? 'هذا الأسبوع' : 'This week';
      return _rtl ? 'أقدم' : 'Earlier';
    }

    final out = <Widget>[];
    String? last;
    for (final n in list) {
      final b = bucket(n);
      if (b != last) {
        out.add(Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 14, 4, 8),
          child: Text(b, style: GoogleFonts.cairo(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
        ));
        last = b;
      }
      out.add(_card(n));
    }
    return out;
  }

  Widget _card(Map n) {
    final kind = noticeKind(n);
    final (IconData icon, Color color) = switch (kind) {
      NoticeKind.rides => (Icons.directions_car_filled_outlined, const Color(0xff0873FF)),
      NoticeKind.money => (Icons.account_balance_wallet_outlined, const Color(0xff14A47B)),
      NoticeKind.support => (Icons.headset_mic_outlined, const Color(0xff14A47B)),
      NoticeKind.offers => (Icons.local_offer_outlined, const Color(0xffB7791F)),
    };
    final unread = n['is_read'] == false || n['is_read'] == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('notice-${n['id']}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _delete(n),
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(color: const Color(0xffFDECEE), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.delete_outline_rounded, color: Color(0xffE0243A)),
        ),
        child: Material(
          color: unread ? theme.withValues(alpha: .05) : (isDarkTheme ? const Color(0xff171B22) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _open(n),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withValues(alpha: .07))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${n['title'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: textColor, fontSize: 15, fontWeight: FontWeight.w800, height: 1.35)),
                    const SizedBox(height: 2),
                    Text('${n['body'] ?? ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: textColor.withValues(alpha: .65), fontSize: 13, height: 1.5)),
                    const SizedBox(height: 4),
                    Text(_when(n), style: GoogleFonts.cairo(color: textColor.withValues(alpha: .45), fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(width: 6),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: theme, shape: BoxShape.circle),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _when(Map n) {
    final t = noticeTime(n);
    if (t == null) return '${n['converted_created_at'] ?? ''}';
    final d = DateTime.now().difference(t);
    if (_rtl) {
      if (d.inMinutes < 1) return 'الآن';
      if (d.inMinutes < 60) return 'منذ ${_count(d.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق')}';
      if (d.inHours < 24) return 'منذ ${_count(d.inHours, 'ساعة', 'ساعتين', 'ساعات')}';
      if (d.inDays == 1) return 'أمس';
      return 'منذ ${_count(d.inDays, 'يوم', 'يومين', 'أيام')}';
    }
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  /// Arabic counting: «ساعة», «ساعتين», «3 ساعات», «11 ساعة»
  static String _count(int n, String one, String two, String few) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return '$n $few';
    return '$n $one';
  }
}
