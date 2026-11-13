part of '../booking_confirmation.dart';

mixin _BookingConfirmationActiveRide
    on State<BookingConfirmation>, _BookingConfirmationController {
  Widget buildActiveRideSheet(Size media) {
    final fare = _resolveRideFare(userRequestData);
    // a ride resumed after the app restarted: fetch the admin's games once here too
    if (!RideGamesHost.configured && userRequestData.isNotEmpty) {
      RideGamesHost.configure().then((_) {
        if (mounted) setState(() {});
      });
    }
    return (userRequestData.isNotEmpty &&
            userRequestData['accepted_at'] != null)
        ? AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            bottom: addressBottom != null
                ? -addressBottom
                : -(media.height - media.width),
            child: GestureDetector(
              onVerticalDragStart: (v) {
                _cont.jumpTo(0.0);
                start = v.globalPosition.dy;
                if (addressBottom != null) {
                  _addressBottom = addressBottom;
                } else {
                  addressBottom = (media.height - media.width);
                  _addressBottom = addressBottom;
                }
                gesture.clear();
              },
              onVerticalDragUpdate: (v) {
                if ((_addressBottom + (v.globalPosition.dy - start)) >
                        media.height * 0.2 &&
                    (_addressBottom + (v.globalPosition.dy - start)) <
                        ((media.height * 1.2) - media.width)) {
                  addressBottom =
                      _addressBottom + (v.globalPosition.dy - start);
                }
                setState(() {});
              },
              onVerticalDragEnd: (v) {},
              child: Container(
                  padding: EdgeInsets.fromLTRB(media.width * 0.025,
                      media.width * 0.02, media.width * 0.025, 0),
                  width: media.width * 1,
                  height: media.height * 1.2,
                  decoration: BoxDecoration(
                      color: page,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 5,
                            width: media.width * 0.2,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: hintColor),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.01,
                      ),
                      // design v2: what is happening now, big; the ride code beside it
                      SizedBox(
                        width: media.width * 0.9,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_activeRideTitle(),
                                  style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800, height: 1.25)),
                              Text(_activeRideLine(),
                                  maxLines: 3,
                                  style: GoogleFonts.cairo(color: textColor.withValues(alpha: .6), fontSize: 13, height: 1.45)),
                            ]),
                          ),
                          if (userRequestData['is_trip_start'] != 1 && userRequestData['show_otp_feature'] == true)
                            Container(
                              margin: const EdgeInsetsDirectional.only(start: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(children: [
                                Text(languageDirection == 'rtl' ? 'رمز الرحلة' : 'Ride code',
                                    style: GoogleFonts.cairo(color: theme, fontSize: 11, fontWeight: FontWeight.w700)),
                                Text('${userRequestData['ride_otp']}',
                                    style: GoogleFonts.notoSans(color: theme, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                              ]),
                            ),
                        ]),
                      ),
                      // «توصيل»: the delivery code the receiver gives the driver
                      if (ParcelCodeCard.of(userRequestData) case final card?)
                        Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: media.width * 0.9, child: card)),
                      // «ساحبة»: what was asked and what to do now
                      if (TowRideCard.of(userRequestData) case final card?)
                        Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: media.width * 0.9, child: card)),
                      // «الشحن»: the load, workers, floors and photos
                      if (FreightRideCard.of(userRequestData) case final card?)
                        Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: media.width * 0.9, child: card)),
                      if (userRequestData['accepted_at'] != null &&
                          userRequestData['arrived_at'] != null &&
                          userRequestData['is_trip_start'] == 0 &&
                          (waitingTime / 60).toStringAsFixed(0) != '0')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            width: media.width * 0.9,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xffFFF4DB), borderRadius: BorderRadius.circular(14)),
                            child: Text(
                              '${languages[choosenLanguage]['text_waiting_time']}: ${(waitingTime / 60).toStringAsFixed(0)} ${languages[choosenLanguage]['text_mins']}',
                              style: GoogleFonts.cairo(color: const Color(0xffB7791F), fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      SizedBox(height: media.width * 0.03),
                      if (fare != null) ...[
                        SizedBox(
                          width: media.width * 0.9,
                          child: _RideFareBadge(
                            fare: fare,
                            isRtl: languageDirection == 'rtl',
                            expanded: true,
                          ),
                        ),
                        SizedBox(height: media.width * 0.03),
                      ],
                      _activeDriverCard(media),
                      // «العب وأنت تستنى» while the driver is coming: the same box as on the search screen
                      if (RideGamesHost.enabledWhileDriverComing && userRequestData['arrived_at'] == null && userRequestData['is_trip_start'] != 1) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: media.width * 0.9,
                          child: RideGamesHost.boxOpen
                              ? WaitingGamesBox(
                                  status: RideGamesHost.status,
                                  controller: RideGamesHost.controller,
                                  height: (media.height * 0.24).clamp(150.0, 230.0).toDouble(),
                                  onClose: () => setState(() => RideGamesHost.boxOpen = false),
                                )
                              : PlayWhileWaitingButton(
                                  label: 'العب وأنت تستنى السائق',
                                  onTap: () => setState(() => RideGamesHost.boxOpen = true),
                                ),
                        ),
                      ],
                      SizedBox(
                        height: media.width * 0.04,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _cont,
                          physics: (addressBottom != null &&
                                  addressBottom <= (media.height * 0.25))
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              if (userRequestData['transport_type'] ==
                                  'delivery')
                                Column(
                                  children: [
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Text(
                                        '${userRequestData['goods_type']} - ${userRequestData['goods_type_quantity']}',
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * fourteen,
                                            fontWeight: FontWeight.w600,
                                            color: buttonColor),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                  ],
                                ),
                              // design v2: the route as one card (pickup, stops, destination), how the ride is
                              // paid, what cancelling costs (the server's rule), and one clear cancel button
                              _activeRouteCard(media),
                              const SizedBox(height: 12),
                              _activePaymentCard(media),
                              if (userRequestData['is_trip_start'] != 1) ...[
                                const SizedBox(height: 12),
                                _cancelPolicyNote(media),
                                const SizedBox(height: 12),
                                _cancelRideButton(media),
                              ],
                              SizedBox(
                                height: media.height * 0.25,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
            ))
        : Container();
  }

  /// «يوصلك خلال 4 دقائق», «وصل السائق», «في الطريق إلى وجهتك»
  String _activeRideTitle() {
    final rtl = languageDirection == 'rtl';
    final d = userRequestData;
    if (d['is_trip_start'] == 1) return rtl ? 'في الطريق إلى وجهتك' : 'On the way to your destination';
    if (d['arrived_at'] != null) return rtl ? 'وصل السائق' : 'Your driver has arrived';
    if (_dist != null) {
      final m = double.parse((_dist * 2).toString()).round();
      if (m > 0) return rtl ? 'يوصلك خلال $m ${m <= 10 && m > 2 ? 'دقائق' : 'دقيقة'}' : 'Arrives in $m min';
    }
    return rtl ? 'السائق في الطريق إليك' : 'Your driver is on the way';
  }

  /// the same words as before under the title (arrival, waiting charge, on the ride)
  String _activeRideLine() {
    final d = userRequestData;
    final l = languages[choosenLanguage];
    if (d['accepted_at'] != null && d['arrived_at'] == null && d['is_trip_start'] == 0) return '${l['text_captain_arrive']}';
    if (d['accepted_at'] != null && d['arrived_at'] != null && d['is_trip_start'] == 0) {
      if (d['is_bid_ride'] == 1 || d['waiting_charge'].toString() == '0') return '${l['text_captain_arrived']}';
      return '${l['text_captain_arrived']}, ${l['text_waiting_time_text'].toString().replaceAll('5', d['free_waiting_time_in_mins_before_trip_start'].toString()).replaceAll('**', (d['requested_currency_symbol'].toString() + d['waiting_charge'].toString()))}';
    }
    return '${l['text_onride']}';
  }

  Widget _v2Card({required Widget child}) => Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: textColor.withValues(alpha: .07)),
        ),
        child: child,
      );

  /// pickup, the stops in order, the destination — dots joined by a line
  Widget _activeRouteCard(Size media) {
    final rtl = languageDirection == 'rtl';
    final d = userRequestData;
    final stops = tripStops.length > 1 ? tripStops.sublist(0, tripStops.length - 1) : const [];
    final places = <(String, String, Color)>[
      (rtl ? 'من' : 'From', '${d['pick_address'] ?? ''}', const Color(0xff16A34A)),
      for (var i = 0; i < stops.length; i++) (rtl ? 'توقف ${i + 1}' : 'Stop ${i + 1}', '${stops[i]['address'] ?? ''}', const Color(0xffF59E0B)),
      if (d['is_rental'] != true && d['drop_address'] != null) (rtl ? 'إلى' : 'To', '${d['drop_address']}', const Color(0xffE0243A)),
    ];
    return _v2Card(
      child: Column(children: [
        for (var i = 0; i < places.length; i++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 18,
                child: Column(children: [
                  const SizedBox(height: 5),
                  Container(width: 11, height: 11, decoration: BoxDecoration(shape: BoxShape.circle, color: places[i].$3, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: places[i].$3.withValues(alpha: .35), blurRadius: 4)])),
                  if (i < places.length - 1) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: textColor.withValues(alpha: .12))),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < places.length - 1 ? 12 : 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(places[i].$1, style: GoogleFonts.cairo(color: textColor.withValues(alpha: .5), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    Text(places[i].$2, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.35)),
                  ]),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  /// how this ride is paid (cash, wallet, wallet + cash, card) and the amount — same values as before
  Widget _activePaymentCard(Size media) {
    final rtl = languageDirection == 'rtl';
    final d = userRequestData;
    final l = languages[choosenLanguage];
    final opt = '${d['payment_opt']}';
    final cur = d['requested_currency_symbol'] ?? 'LYD';
    final (IconData icon, String label) = switch (opt) {
      '1' => (Icons.payments_outlined, '${l['text_cash']}'),
      '2' => (Icons.account_balance_wallet_outlined, '${l['text_wallet']}'),
      '3' => (Icons.account_balance_wallet_outlined, '${l[d['wallet_split_is_estimate'] == true ? 'text_cash_expected' : 'text_cash_due']}'),
      _ => (Icons.credit_card_rounded, '${l['text_card']}'),
    };
    final amount = opt == '3' ? '$cur ${d['cash_due_amount'] ?? 0}' : _resolvedRideFareText(d);
    return _v2Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: theme.withValues(alpha: .08), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: theme, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rtl ? 'الدفع' : '${l['text_payingvia']}', style: GoogleFonts.cairo(color: textColor.withValues(alpha: .5), fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text(label, style: GoogleFonts.cairo(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ]),
          ),
          Text(amount, textDirection: ui.TextDirection.ltr, style: GoogleFonts.notoSans(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        if (opt == '3')
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 52, top: 4),
            child: Text(
              '${l[d['wallet_split_is_estimate'] == true ? 'text_wallet_expected' : 'text_wallet_paid']}: $cur ${d['wallet_paid_amount'] ?? 0}',
              style: GoogleFonts.cairo(color: textColor.withValues(alpha: .55), fontSize: 12),
            ),
          ),
      ]),
    );
  }

  /// what cancelling costs now: the server sends its rule (cancel_fee_policy); without it no amount is promised
  Widget _cancelPolicyNote(Size media) {
    final rtl = languageDirection == 'rtl';
    final d = userRequestData;
    final policy = d['cancel_fee_policy'];
    final arrived = d['arrived_at'] != null;
    String text;
    if (policy is Map) {
      final wait = policy['free_wait_minutes'] ?? 3;
      text = !arrived
          ? (rtl ? 'الإلغاء مجاني قبل ما يوصل السائق' : 'Cancelling is free until the driver arrives')
          : (rtl
              ? 'الإلغاء مجاني أول $wait دقائق من وصول السائق، وبعدها قد تُخصم رسوم إلغاء'
              : 'Free for the first $wait minutes after the driver arrives; a cancellation fee may apply after that');
    } else {
      text = rtl ? 'قد تُطبّق رسوم إلغاء حسب سياسة الإلغاء' : 'A cancellation fee may apply';
    }
    final free = policy is Map && !arrived;
    final color = free ? const Color(0xff15803D) : const Color(0xffB7791F);
    return Container(
      width: media.width * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(free ? Icons.verified_outlined : Icons.info_outline_rounded, color: color, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.cairo(color: color, fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.4))),
      ]),
    );
  }

  /// «إلغاء الرحلة»: the same reasons sheet and cancel flow as before
  Widget _cancelRideButton(Size media) {
    final rtl = languageDirection == 'rtl';
    return SizedBox(
      width: media.width * 0.9,
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xffD92D20),
          side: BorderSide(color: const Color(0xffD92D20).withValues(alpha: .35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () async {
          setState(() => isLoading = true);
          var reason = await cancelReason(userRequestData['is_driver_arrived'] == 0 ? 'before' : 'after');
          if (reason == true) {
            setState(() {
              _cancellingError = '';
              _cancelReason = '';
              _cancelling = true;
            });
          }
          setState(() => isLoading = false);
        },
        icon: const Icon(Icons.close_rounded, size: 20),
        label: Text(rtl ? 'إلغاء الرحلة' : '${languages[choosenLanguage]['text_cancel_booking']}',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }

  /// the driver as one card: photo and rating, name, the car without empty fields, the plate, rides done;
  /// then «رسالة» and «اتصال» (the same chat page and call button as before)
  Widget _activeDriverCard(Size media) {
    final rtl = languageDirection == 'rtl';
    // the games keep listening after the driver accepts (same round, same controller)
    RideGamesHost.sync(context,
        distanceKm: _dist is num ? (_dist as num).toDouble() : null,
        onCall: null,
        onChat: () => guardedPush(context, MaterialPageRoute(builder: (context) => const ChatPage())),
        onBackToTrip: () {});
    final drv = userRequestData['driverDetail']['data'];
    bool real(dynamic v) => v != null && '$v'.trim().isNotEmpty && '$v' != 'null' && '$v' != '-';
    final car = [drv['car_make_name'], drv['car_model_name'], drv['car_color']].where(real).join(' · ');
    final rides = userRequestData['driver_completed_rides_count'] ?? 0;
    final rating = drv['rating'];
    final unread = chatList.where((e) => e['from_type'] == 2 && e['seen'] == 0).isNotEmpty;
    return Container(
      width: media.width * 0.9,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: textColor.withValues(alpha: .07)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: NetworkImage('${drv['profile_picture']}'), fit: BoxFit.cover),
              ),
            ),
            PositionedDirectional(
              bottom: -6,
              start: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 4)]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Color(0xffF5A524), size: 14),
                  Text(rating == 0 || rating == null ? '—' : '$rating',
                      style: GoogleFonts.notoSans(color: const Color(0xff10213F), fontSize: 11.5, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${drv['name'] ?? ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(color: textColor, fontSize: 16.5, fontWeight: FontWeight.w800)),
              if (car.isNotEmpty)
                Text(car, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: textColor.withValues(alpha: .6), fontSize: 12.5)),
              Text(rtl ? '$rides رحلة مكتملة' : '$rides rides', style: GoogleFonts.cairo(color: textColor.withValues(alpha: .5), fontSize: 12)),
            ]),
          ),
          if (real(drv['car_number']))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xffFFD54F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff10213F), width: 1.6),
              ),
              child: Text('${drv['car_number']}',
                  textDirection: ui.TextDirection.ltr,
                  style: GoogleFonts.notoSans(color: const Color(0xff10213F), fontSize: 15, fontWeight: FontWeight.w800)),
            ),
        ]),
        if (userRequestData['is_trip_start'] == 0) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Material(
                color: theme.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final result = await guardedPush(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                    if (result == true) setState(() {});
                  },
                  child: SizedBox(
                    height: 48,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: theme, size: 21),
                        if (unread)
                          const PositionedDirectional(
                            top: -2,
                            end: -3,
                            child: CircleAvatar(radius: 4.5, backgroundColor: Color(0xffE0243A)),
                          ),
                      ]),
                      const SizedBox(width: 8),
                      Text(rtl ? 'رسالة' : 'Message', style: GoogleFonts.cairo(color: theme, fontSize: 14.5, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // one «اتصال»: the free call through Taxista, WhatsApp or the phone
            CallOptionsButton(
              peerName: '${drv['name']}',
              mobile: drv['mobile']?.toString(),
              freeCall: () => AdminCallController.instance.callDriver(requestId: userRequestData['id']?.toString()),
            ),
          ]),
        ],
      ]),
    );
  }
}
