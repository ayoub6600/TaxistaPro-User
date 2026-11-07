import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/pages/login/login.dart';
import 'package:taxista/translations/translation.dart';

import '../../functions/functions.dart';
import '../../utils/scheduled_offers.dart';
import '../../functions/schedule_time.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';

class UpcomingScheduledRidesPage extends StatefulWidget {
  const UpcomingScheduledRidesPage({super.key});

  @override
  State<UpcomingScheduledRidesPage> createState() =>
      _UpcomingScheduledRidesPageState();
}

class _UpcomingScheduledRidesPageState
    extends State<UpcomingScheduledRidesPage> {
  bool isLoading = false;
  bool showCancelConfirm = false;
  dynamic cancelId;
  String? actionError;
  Timer? _ticker;
  String? _answeringOfferId;

  /// 0 all, 1 scheduled, 2 recurring
  int _filter = 0;

  bool get isRtl => languageDirection == 'rtl';

  @override
  void initState() {
    super.initState();
    load();
    // Relative labels ("starts in 12 min", "today", "tomorrow") must keep
    // advancing while the rider simply has this screen open, not only on
    // the next pull-to-refresh.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
        _refreshOffers();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  load() async {
    if (upcomingScheduledRides.isEmpty) {
      for (var i = 0; i < 6; i++) {
        upcomingScheduledRides.add({});
      }
      setState(() {});
    }
    var val = await getUpcomingScheduledRides();
    if (!mounted) return;
    if (val == 'logout') {
      navigateLogout();
      return;
    }
    if (mounted) setState(() {});
  }

  Widget _buildOfferTile(Map item, ScheduledOffer offer) {
    final busy = _answeringOfferId != null;
    final mine = _answeringOfferId == offer.offerId.toString();
    final currency = offer.currency.isNotEmpty
        ? offer.currency
        : '${item['requested_currency_symbol'] ?? ''}';
    return Container(
      key: ValueKey('offer-${offer.offerId}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${isRtl ? 'السعر المرجعي' : 'Reference fare'}: ${moneyLabel(offer.referenceFare)} $currency',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 2),
        Text(
          '${isRtl ? 'عرض السائق' : 'Driver offer'}: ${moneyLabel(offer.proposedFare)} $currency',
          key: ValueKey('offer-fare-${offer.offerId}'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        if ((offer.driverName ?? '').isNotEmpty || offer.vehicle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [offer.driverName, offer.vehicle]
                  .where((part) => part != null && part.isNotEmpty)
                  .join(' · '),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: FilledButton(
              key: ValueKey('accept-offer-${offer.offerId}'),
              onPressed: busy ? null : () => _answerOffer(offer, accept: true),
              child: Text(mine
                  ? (isRtl ? 'جارٍ التأكيد…' : 'Confirming…')
                  : (isRtl ? 'قبول العرض' : 'Accept offer')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              key: ValueKey('reject-offer-${offer.offerId}'),
              onPressed: busy ? null : () => _answerOffer(offer, accept: false),
              child: Text(isRtl ? 'رفض العرض' : 'Decline'),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _answerOffer(ScheduledOffer offer, {required bool accept}) async {
    setState(() {
      _answeringOfferId = offer.offerId.toString();
      actionError = null;
    });
    final result = accept
        ? await acceptScheduledCounterOffer(offer)
        : await rejectScheduledCounterOffer(offer);
    if (!mounted) return;
    if (result != 'success') actionError = result;
    // Whatever the answer, the server is the truth: reload the list.
    await getUpcomingScheduledRides();
    if (mounted) setState(() => _answeringOfferId = null);
  }

  // Offers arrive with each ride in the upcoming payload, so refreshing them
  // is just refreshing the list - one request, not one per ride.
  Future<void> _refreshOffers() async {
    await getUpcomingScheduledRides();
    if (mounted) setState(() {});
  }

  navigateLogout() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false);
    });
  }

  loadMore() async {
    setState(() {
      for (var i = 0; i < 6; i++) {
        upcomingScheduledRides.add({});
      }
    });
    var val = await getUpcomingScheduledRidesPages(
        'page=${upcomingScheduledRidesPage['pagination']['current_page'] + 1}');
    if (val == 'logout') {
      navigateLogout();
    }
    setState(() {});
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'reserved':
      case 'ready':
        return online;
      case 'cancelled':
      case 'expired':
        return verifyDeclined;
      case 'active':
        return Colors.blue;
      default:
        return textColor;
    }
  }

  String statusLabel(String? status) {
    switch (status) {
      case 'scheduled':
        return languages[choosenLanguage]['text_scheduled_status_scheduled'];
      case 'dispatching':
        return languages[choosenLanguage]['text_scheduled_status_dispatching'];
      case 'reserved':
        return languages[choosenLanguage]['text_scheduled_status_reserved'];
      case 'ready':
        return languages[choosenLanguage]['text_scheduled_status_ready'];
      case 'active':
        return languages[choosenLanguage]['text_scheduled_status_active'];
      case 'cancelled':
        return languages[choosenLanguage]['text_scheduled_status_cancelled'];
      case 'expired':
        return languages[choosenLanguage]['text_scheduled_status_expired'];
      default:
        return status ?? '';
    }
  }

  bool canManage(dynamic item) {
    // Rescheduling/cancelling stops making sense once the ride is about to
    // start (ready) or already running (active) - matches the backend's
    // own BLOCKS_AVAILABILITY gate.
    final status = item['scheduled_status'];
    return status != 'ready' && status != 'active';
  }

  void openReschedule(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RescheduleSheet(
        requestId: item['id'],
        onDone: () async {
          Navigator.pop(context);
          await load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          children: [
            Container(
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              padding: EdgeInsets.fromLTRB(media.width * 0.05,
                  media.width * 0.05, media.width * 0.05, 0),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  // «الرحلات القادمة · كل مواعيدك في مكان واحد», then الكل / مجدولة / مشوار الدوام
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_rounded, color: textColor),
                        style: IconButton.styleFrom(backgroundColor: textColor.withValues(alpha: .05), fixedSize: const Size(44, 44)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(languages[choosenLanguage]['text_upcoming_rides'] ?? (isRtl ? 'الرحلات القادمة' : 'Upcoming rides'),
                              style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
                          Text(isRtl ? 'كل مواعيدك في مكان واحد' : 'All your bookings in one place',
                              style: GoogleFonts.cairo(color: textColor.withValues(alpha: .55), fontSize: 12.5)),
                        ]),
                      ),
                    ]),
                  ),
                  if (upcomingScheduledRides.any((e) => e is Map && e['recurring_label'] != null))
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: textColor.withValues(alpha: .05), borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        for (final f in const [0, 1, 2])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _filter == f ? page : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _filter == f ? [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                                ),
                                child: Text(
                                  [
                                    isRtl ? 'الكل' : 'All',
                                    isRtl ? 'مجدولة' : 'Scheduled',
                                    isRtl ? 'مشوار الدوام' : 'Recurring',
                                  ][f],
                                  style: GoogleFonts.cairo(color: textColor, fontSize: 13.5, fontWeight: _filter == f ? FontWeight.w800 : FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: (upcomingScheduledRides.isNotEmpty)
                          ? Column(
                              children: [
                                Column(children: _grouped(media)),
                                (upcomingScheduledRidesPage['pagination'] !=
                                        null)
                                    ? (upcomingScheduledRidesPage['pagination']
                                                ['current_page'] <
                                            upcomingScheduledRidesPage[
                                                'pagination']['total_pages'])
                                        ? InkWell(
                                            onTap: loadMore,
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.025),
                                              margin: EdgeInsets.only(
                                                  bottom: media.width * 0.05),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: page,
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2)),
                                              child: MyText(
                                                text: languages[choosenLanguage]
                                                        ['text_loadmore'] ??
                                                    'Load more',
                                                size: media.width * sixteen,
                                                color: textColor,
                                              ),
                                            ),
                                          )
                                        : Container()
                                    : Container(),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: media.width * 0.4),
                                MyText(
                                  text: languages[choosenLanguage]
                                      ['text_no_upcoming_rides'],
                                  textAlign: TextAlign.center,
                                  fontweight: FontWeight.w800,
                                  size: media.width * sixteen,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (showCancelConfirm) _cancelOverlay(media),
          ],
        ),
      ),
    );
  }

  /// the rides by day («غدًا · السبت», «الأحد 8 نوفمبر»), in the server's order
  List<Widget> _grouped(media) {
    final out = <Widget>[];
    String? last;
    for (final item in upcomingScheduledRides) {
      if (item is! Map || item.isEmpty) {
        out.add(_shimmerCard(media));
        continue;
      }
      final recurring = item['recurring_label'] != null;
      if (_filter == 1 && recurring) continue;
      if (_filter == 2 && !recurring) continue;
      final t = parseTripStart(item);
      String day = '';
      if (t != null) {
        final now = DateTime.now();
        final d = DateTime(t.year, t.month, t.day).difference(DateTime(now.year, now.month, now.day)).inDays;
        final weekday = scheduleDateLabel(t, isRtl: isRtl).split('،').first.split(',').first;
        day = d == 0
            ? '${isRtl ? 'اليوم' : 'Today'} · $weekday'
            : d == 1
                ? '${isRtl ? 'غدًا' : 'Tomorrow'} · $weekday'
                : scheduleDateLabel(t, isRtl: isRtl);
      }
      if (day.isNotEmpty && day != last) {
        out.add(Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 10, 4, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(day, style: GoogleFonts.cairo(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ));
        last = day;
      }
      out.add(_rideCard(media, item));
    }
    return out;
  }

  Widget _tag(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.cairo(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _place(Color dot, String text, int lines) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: dot.withValues(alpha: .25), width: 3)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, maxLines: lines, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
      ]);

  Widget _shimmerCard(media) {
    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.02),
      height: media.width * 0.35,
      decoration: BoxDecoration(
          color: page.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _rideCard(media, dynamic item) {
    final driver =
        item['driverDetail'] != null && item['driverDetail']['data'] != null
            ? item['driverDetail']['data']
            : null;
    final isReady = item['scheduled_status'] == 'ready';
    final tripStart = parseTripStart(item);
    final relativeLabel = tripStart != null
        ? scheduleRelativeLabel(tripStart, isRtl: isRtl)
        : (item['trip_start_time'] ?? '').toString();
    final vehicleLabel = [item['car_make_name'], item['car_model_name']]
        .where((v) => v != null && v != '-')
        .join(' ');

    final clock = tripStart == null
        ? ''
        : '${tripStart.hour.toString().padLeft(2, '0')}:${tripStart.minute.toString().padLeft(2, '0')}';
    final hasOffer = driver == null && (scheduledCounterOffers[item['id']?.toString()] ?? []).isNotEmpty;
    return Container(
      width: media.width * 1,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 12, offset: const Offset(0, 4))],
        // A ready ride is about to start, so it earns a bit more visual
        // weight than the calm "scheduled/dispatching/reserved" cards
        // around it - without leaving this list or looking like an
        // active-trip card.
        border: Border.all(color: isReady ? online : textColor.withValues(alpha: .06), width: isReady ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // «07:15» big, then what this booking is: recurring, its state, an offer waiting
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (clock.isNotEmpty)
                Text(clock,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.notoSans(color: textColor, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  if (item['recurring_label'] != null)
                    _tag('${item['recurring_label']}', const Color(0xff0873FF), Icons.repeat_rounded),
                  _tag(statusLabel(item['scheduled_status']), statusColor(item['scheduled_status']) == textColor ? const Color(0xff4B5770) : statusColor(item['scheduled_status']),
                      isReady ? Icons.notifications_active_rounded : (driver != null ? Icons.person_rounded : Icons.schedule_rounded)),
                  if (hasOffer) _tag(isRtl ? 'عرض سائق بانتظارك' : 'A driver offer', const Color(0xffB7791F), Icons.local_offer_outlined),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$relativeLabel · ${item['request_number'] ?? ''}',
            style: GoogleFonts.cairo(color: isReady ? online : textColor.withValues(alpha: .55), fontSize: 12.5, fontWeight: isReady ? FontWeight.w800 : FontWeight.w600),
          ),
          if (item['scheduled_status'] == 'scheduled' && driver == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                isRtl
                    ? 'رحلتك متاحة للسائقين الآن. إن لم يحجزها أحد، سنعيد عرضها بقوة قبل الموعد بـ${userDetails['scheduled_driver_search_window_minutes'] ?? 30} دقيقة.'
                    : 'Your ride is available to drivers now. If none reserve it, we will offer it again ${userDetails['scheduled_driver_search_window_minutes'] ?? 30} minutes before pickup.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          const SizedBox(height: 10),
          // the route as two dots on a line: pickup, then the destination
          _place(const Color(0xff14A47B), '${item['pick_address'] ?? ''}', 2),
          if (item['drop_address'] != null) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4.5),
              child: Container(width: 1.5, height: 10, color: textColor.withValues(alpha: .15)),
            ),
            _place(const Color(0xffE0243A), '${item['drop_address']}', 1),
          ],
          if (item['request_eta_amount'] != null) ...[
            SizedBox(height: media.width * 0.02),
            Row(
              children: [
                Icon(Icons.payments_outlined, color: textColor.withValues(alpha: .5), size: 18),
                const SizedBox(width: 6),
                Text(isRtl ? 'السعر العادل' : 'Fair fare', style: GoogleFonts.cairo(color: textColor.withValues(alpha: .6), fontSize: 13)),
                const Spacer(),
                Text('${item['request_eta_amount']} ${item['requested_currency_symbol'] ?? ''}',
                    style: GoogleFonts.notoSans(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
          if (item['rider_proposed_fare'] != null ||
              (item['accepted_ride_fare'] != null &&
                  double.tryParse(item['accepted_ride_fare'].toString()) != 0)) ...[
            const SizedBox(height: 5),
            Text(driver == null
                ? '${isRtl ? 'عرضك' : 'Your offer'}: ${item['requested_currency_symbol'] ?? ''} ${item['rider_proposed_fare']}'
                : '${isRtl ? 'السعر المتفق عليه' : 'Agreed fare'}: ${item['requested_currency_symbol'] ?? ''} ${item['accepted_ride_fare']}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.blue)),
          ],
          if (driver == null &&
              (scheduledCounterOffers[item['id']?.toString()] ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final offer in scheduledCounterOffers[item['id']?.toString()]!)
              _buildOfferTile(item, offer),
            if (actionError != null)
              Text(actionError!, style: const TextStyle(color: Colors.red)),
          ],
          if (driver != null) ...[
            SizedBox(height: media.width * 0.02),
            const MySeparator(),
            SizedBox(height: media.width * 0.02),
            Row(
              children: [
                if (driver['profile_picture'] != null)
                  Container(
                    height: media.width * 0.1,
                    width: media.width * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: NetworkImage(driver['profile_picture']),
                          fit: BoxFit.cover),
                    ),
                  ),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: driver['name'] ?? '',
                        fontweight: FontWeight.w600,
                        size: media.width * fourteen,
                      ),
                      MyText(
                        text: isRtl
                            ? 'سيأتيك عند الموعد: $relativeLabel'
                            : 'Picks you up at: $relativeLabel',
                        color: online,
                        size: media.width * twelve,
                      ),
                      if (vehicleLabel.isNotEmpty ||
                          (item['car_number'] != null &&
                              item['car_number'] != '-'))
                        MyText(
                          text: [
                            if (vehicleLabel.isNotEmpty) vehicleLabel,
                            if (item['car_number'] != null &&
                                item['car_number'] != '-')
                              item['car_number']
                          ].join(' · '),
                          color: Colors.grey,
                          size: media.width * twelve,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (canManage(item)) ...[
            SizedBox(height: media.width * 0.03),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => openReschedule(item),
                    child: Container(
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.symmetric(vertical: media.width * 0.025),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xff0873FF).withValues(alpha: .08)),
                      child: MyText(
                        text: languages[choosenLanguage]['text_reschedule'],
                        size: media.width * fourteen,
                        fontweight: FontWeight.w700,
                        color: const Color(0xff0873FF),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        showCancelConfirm = true;
                        cancelId = item['id'];
                        actionError = null;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.symmetric(vertical: media.width * 0.025),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xffE0243A).withValues(alpha: .08)),
                      child: MyText(
                        text: languages[choosenLanguage]['text_cancel_ride'],
                        size: media.width * fourteen,
                        fontweight: FontWeight.w700,
                        color: const Color(0xffE0243A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cancelOverlay(media) {
    return Positioned(
      top: 0,
      child: Container(
        height: media.height * 1,
        width: media.width * 1,
        color: Colors.transparent.withOpacity(0.6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: media.width * 0.9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: media.height * 0.1,
                    width: media.width * 0.1,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: page),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showCancelConfirm = false;
                          cancelId = null;
                        });
                      },
                      child: Icon(Icons.cancel_outlined, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(media.width * 0.05),
              width: media.width * 0.9,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: page),
              child: Column(
                children: [
                  MyText(
                    text: languages[choosenLanguage]['text_ridecancel'],
                    size: media.width * eighteen,
                    textAlign: TextAlign.center,
                  ),
                  if (actionError != null) ...[
                    SizedBox(height: media.width * 0.02),
                    MyText(
                      text: actionError!,
                      size: media.width * twelve,
                      color: verifyDeclined,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: media.width * 0.05),
                  Button(
                    onTap: () async {
                      setState(() => isLoading = true);
                      var val = await cancelLaterRequest(cancelId);
                      setState(() => isLoading = false);
                      if (val == 'success') {
                        setState(() {
                          showCancelConfirm = false;
                          cancelId = null;
                        });
                        await load();
                      } else if (val == 'logout') {
                        navigateLogout();
                      } else {
                        setState(() {
                          actionError = languages[choosenLanguage]
                                  ['text_error'] ??
                              'Something went wrong';
                        });
                      }
                    },
                    text: languages[choosenLanguage]['text_cancel_ride'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RescheduleSheet extends StatefulWidget {
  final dynamic requestId;
  final Future<void> Function() onDone;
  const _RescheduleSheet({required this.requestId, required this.onDone});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime pickedDateTime;
  late final DateTime pickerMinimumDate;
  late final DateTime pickerMaximumDate;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final minMinutes = int.tryParse(
            (userDetails['user_can_make_a_ride_after_x_miniutes'] ?? '30')
                .toString()) ??
        30;
    // All three Cupertino bounds come from one instant and remain fixed
    // while this sheet rebuilds; separate DateTime.now() calls or a moving
    // minimum used to make an old initial date fail its constructor assert.
    final pickerNow = DateTime.now();
    pickerMinimumDate = pickerNow.add(Duration(minutes: minMinutes));
    pickerMaximumDate = pickerNow.add(const Duration(days: 30));
    pickedDateTime = pickerMinimumDate.add(const Duration(minutes: 1));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final initialDate = pickedDateTime.isBefore(pickerMinimumDate)
        ? pickerMinimumDate.add(const Duration(minutes: 1))
        : pickedDateTime.isAfter(pickerMaximumDate)
            ? pickerMaximumDate
            : pickedDateTime;

    return Container(
      height: media.height * 0.55,
      width: media.width * 1,
      padding: EdgeInsets.all(media.width * 0.03),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(media.width * 0.05),
              topRight: Radius.circular(media.width * 0.05))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText(
            text: languages[choosenLanguage]['text_reschedule_ride'],
            size: media.width * eighteen,
            fontweight: FontWeight.w600,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),
          Container(
            height: media.width * 0.5,
            width: media.width * 0.9,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), color: topBar),
            child: CupertinoDatePicker(
              minimumDate: pickerMinimumDate,
              initialDateTime: initialDate,
              maximumDate: pickerMaximumDate,
              onDateTimeChanged: (val) {
                setState(() => pickedDateTime = val);
              },
            ),
          ),
          if (error != null) ...[
            SizedBox(height: 8.h),
            MyText(
              text: error!,
              size: media.width * twelve,
              color: verifyDeclined,
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(media.width * 0.03),
            child: Button(
              onTap: () async {
                setState(() {
                  isLoading = true;
                  error = null;
                });
                var val = await rescheduleScheduledRide(
                    widget.requestId, pickedDateTime);
                if (!mounted) return;
                setState(() => isLoading = false);
                if (val == 'success') {
                  await widget.onDone();
                } else if (val == 'logout') {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    error = val is String
                        ? val
                        : (languages[choosenLanguage]['text_error'] ??
                            'Something went wrong');
                  });
                }
              },
              text: languages[choosenLanguage]['text_confirm_reschedule'],
            ),
          ),
        ],
      ),
    );
  }
}
