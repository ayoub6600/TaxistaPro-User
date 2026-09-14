import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/pages/login/login.dart';
import 'package:taxista/translations/translation.dart';

import '../../functions/functions.dart';
import '../../functions/schedule_time.dart';
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

  bool get isRtl => languageDirection == 'rtl';

  @override
  void initState() {
    super.initState();
    load();
    // Relative labels ("starts in 12 min", "today", "tomorrow") must keep
    // advancing while the rider simply has this screen open, not only on
    // the next pull-to-refresh.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
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
    if (val == 'logout') {
      navigateLogout();
      return;
    }
    setState(() {});
  }

  navigateLogout() {
    Future.delayed(const Duration(seconds: 1), () {
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
        return languages[choosenLanguage]
            ['text_scheduled_status_dispatching'];
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
        textDirection:
            (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            Container(
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              padding: EdgeInsets.fromLTRB(
                  media.width * 0.05, media.width * 0.05, media.width * 0.05, 0),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: media.width * 0.05),
                        width: media.width * 1,
                        alignment: Alignment.center,
                        child: MyText(
                          text: languages[choosenLanguage]
                              ['text_upcoming_rides'],
                          size: media.width * twenty,
                          fontweight: FontWeight.w600,
                        ),
                      ),
                      Positioned(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(media.width * 0.05),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: media.width * 0.11,
                              width: media.width * 0.11,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.white, width: 0.5),
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.17)),
                              child: Icon(Icons.arrow_back,
                                  size: media.width * 0.05,
                                  color:
                                      (isDarkTheme) ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: (upcomingScheduledRides.isNotEmpty)
                          ? Column(
                              children: [
                                Column(
                                  children: upcomingScheduledRides
                                      .asMap()
                                      .map((i, value) {
                                        return MapEntry(
                                            i,
                                            (upcomingScheduledRides[i].isEmpty)
                                                ? _shimmerCard(media)
                                                : _rideCard(media,
                                                    upcomingScheduledRides[i]));
                                      })
                                      .values
                                      .toList(),
                                ),
                                (upcomingScheduledRidesPage['pagination'] !=
                                        null)
                                    ? (upcomingScheduledRidesPage['pagination']
                                                ['current_page'] <
                                            upcomingScheduledRidesPage[
                                                    'pagination']
                                                ['total_pages'])
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
    final driver = item['driverDetail'] != null &&
            item['driverDetail']['data'] != null
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

    return Container(
      width: media.width * 1,
      padding: EdgeInsets.all(media.width * 0.03),
      margin: EdgeInsets.only(bottom: media.width * 0.03),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: page,
        // A ready ride is about to start, so it earns a bit more visual
        // weight than the calm "scheduled/dispatching/reserved" cards
        // around it - without leaving this list or looking like an
        // active-trip card.
        border: isReady ? Border.all(color: online, width: 1.4) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: statusColor(item['scheduled_status'])),
                child: MyText(
                  text: statusLabel(item['scheduled_status']),
                  fontweight: FontWeight.w600,
                  color: Colors.white,
                  size: media.width * twelve,
                ),
              ),
              MyText(
                text: item['request_number'],
                color: Colors.grey,
                fontweight: FontWeight.w600,
                size: media.width * twelve,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(isReady ? Icons.notifications_active : Icons.watch_later,
                  color: isReady ? online : Colors.blue, size: media.width * 0.045),
              SizedBox(width: media.width * 0.02),
              Expanded(
                child: MyText(
                  text: relativeLabel,
                  color: isReady ? online : Colors.grey,
                  fontweight: isReady ? FontWeight.w800 : FontWeight.w600,
                  size: media.width * fourteen,
                ),
              ),
            ],
          ),
          SizedBox(height: media.width * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: media.width * 0.08,
                width: media.width * 0.08,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.4)),
                child: const Icon(Icons.location_on_outlined,
                    color: Colors.white),
              ),
              SizedBox(width: media.width * 0.03),
              Expanded(
                child: MyText(
                  text: item['pick_address'],
                  maxLines: 2,
                  size: media.width * twelve,
                ),
              ),
            ],
          ),
          if (item['drop_address'] != null) ...[
            SizedBox(height: media.width * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: media.width * 0.08,
                  width: media.width * 0.08,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFFF0000)),
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: MyText(
                    text: item['drop_address'],
                    maxLines: 1,
                    size: media.width * twelve,
                  ),
                ),
              ],
            ),
          ],
          if (item['request_eta_amount'] != null) ...[
            SizedBox(height: media.width * 0.02),
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: media.width * 0.02),
                MyText(
                  text:
                      '${item['requested_currency_symbol'] ?? ''} ${item['request_eta_amount']}',
                  fontweight: FontWeight.bold,
                  size: media.width * fourteen,
                ),
              ],
            ),
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
                      padding: EdgeInsets.symmetric(vertical: media.width * 0.025),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderLines, width: 1.2)),
                      child: MyText(
                        text: languages[choosenLanguage]['text_reschedule'],
                        size: media.width * fourteen,
                        color: Colors.blue,
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
                      padding: EdgeInsets.symmetric(vertical: media.width * 0.025),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: verifyDeclined),
                      child: MyText(
                        text: languages[choosenLanguage]['text_cancel_ride'],
                        size: media.width * fourteen,
                        color: Colors.white,
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
                          actionError =
                              languages[choosenLanguage]['text_error'] ??
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
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final minMinutes = int.tryParse(
            (userDetails['user_can_make_a_ride_after_x_miniutes'] ?? '30')
                .toString()) ??
        30;
    pickedDateTime = DateTime.now().add(Duration(minutes: minMinutes));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final minMinutes = int.tryParse(
            (userDetails['user_can_make_a_ride_after_x_miniutes'] ?? '30')
                .toString()) ??
        30;

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
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(12), color: topBar),
            child: CupertinoDatePicker(
              minimumDate: DateTime.now().add(Duration(minutes: minMinutes)),
              initialDateTime: pickedDateTime,
              maximumDate: DateTime.now().add(const Duration(days: 30)),
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
