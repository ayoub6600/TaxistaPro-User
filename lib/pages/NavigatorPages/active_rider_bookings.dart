import 'package:flutter/material.dart';

import '../../functions/functions.dart';
import '../onTripPage/booking_confirmation.dart';
import 'upcoming_scheduled_rides.dart';

/// One entry point for all of a rider's current bookings. Scheduled bookings
/// remain visible before a driver is assigned; live bookings can be selected
/// individually without replacing or losing the other ride.
class ActiveRiderBookingsPage extends StatefulWidget {
  const ActiveRiderBookingsPage({super.key});

  @override
  State<ActiveRiderBookingsPage> createState() =>
      _ActiveRiderBookingsPageState();
}

class _ActiveRiderBookingsPageState extends State<ActiveRiderBookingsPage> {
  bool _loading = true;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getActiveRiderBookings();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error =
          result == 'success' ? null : 'تعذر تحميل الحجوزات. اسحب للتحديث.';
    });
  }

  Future<void> _open(Map<String, dynamic> ride) async {
    if (_opening) return;
    if (ride['is_later'] == 1 || ride['is_later'] == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpcomingScheduledRidesPage()),
      );
      await _load();
      return;
    }

    setState(() => _opening = true);
    final id = ride['id']?.toString();
    final result = id == null ? false : await getUserDetails(id: id);
    if (!mounted) return;
    setState(() => _opening = false);
    if (result != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرحلة. حاول مجدداً.')),
      );
      return;
    }

    ismulitipleride = true;
    if (userRequestData['accepted_at'] == null) streamRequest();
    final type = userRequestData['is_rental'] == true
        ? 1
        : userRequestData['drop_address'] == null
            ? 2
            : null;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingConfirmation(type: type)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xffF6F8FC),
        elevation: 0,
        title: Text(rtl ? 'حجوزاتك' : 'Your bookings',
            style: const TextStyle(color: Color(0xff102A56), fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && activeRiderBookings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (activeRiderBookings.isNotEmpty) ...[
                    Text(rtl ? 'رحلاتك القادمة في مكان واحد' : 'Your upcoming rides in one place',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xff102A56))),
                    const SizedBox(height: 5),
                    Text(rtl ? 'تابع الموعد والسائق أو افتح تفاصيل أي حجز.' : 'Check the time and driver or open any booking.',
                        style: const TextStyle(color: Color(0xff6A7890), fontSize: 13)),
                    const SizedBox(height: 18),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                  if (activeRiderBookings.isEmpty && _error == null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          rtl ? 'لا توجد حجوزات قائمة' : 'No active bookings'),
                    ),
                  for (final item in activeRiderBookings)
                    if (item is Map)
                      _bookingCard(Map<String, dynamic>.from(item), rtl),
                ],
              ),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> ride, bool rtl) {
    final scheduled = ride['is_later'] == true || ride['is_later'] == 1;
    final confirmed = ride['driver_id'] != null;
    final status = scheduled
        ? confirmed
            ? (rtl ? 'السائق أكد الموعد' : 'Driver confirmed')
            : (rtl ? 'متاحة للسائقين' : 'Available to drivers')
        : ride['is_trip_start'] == true || ride['is_trip_start'] == 1
            ? (rtl ? 'الرحلة جارية' : 'Ride in progress')
            : confirmed
                ? (rtl ? 'قبلها السائق' : 'Driver accepted')
                : (rtl ? 'بانتظار السائق' : 'Waiting for driver');
    final accent = confirmed ? const Color(0xff168358) : const Color(0xff1677FF);
    return InkWell(
      onTap: _opening ? null : () => _open(ride),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffE7ECF5)),
          boxShadow: const [BoxShadow(color: Color(0x110F2A56), blurRadius: 12, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xffEAF3FF), borderRadius: BorderRadius.circular(12)),
                child: Icon(scheduled ? Icons.calendar_month_rounded : Icons.route_rounded,
                    color: const Color(0xff1677FF), size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(scheduled ? (rtl ? 'رحلة مجدولة' : 'Scheduled ride') : (rtl ? 'رحلة قائمة' : 'Active ride'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xff102A56))),
                Text(ride['request_number']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xff6A7890))),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Color(0xff7891B1)),
            ]),
            if (scheduled) ...[
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 17, color: Color(0xff1677FF)),
                const SizedBox(width: 7),
                Expanded(child: Text(ride['trip_start_time']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff102A56)))),
              ]),
              if (confirmed && ride['driverDetail'] is Map &&
                  ride['driverDetail']['data'] is Map)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    rtl
                        ? 'السائق ${ride['driverDetail']['data']['name'] ?? ''} سيأتي عند هذا الموعد'
                        : '${ride['driverDetail']['data']['name'] ?? 'Your driver'} will arrive at this time',
                    style: const TextStyle(color: Color(0xff168358), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
            const SizedBox(height: 13),
            Text(ride['pick_address']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xff344761))),
            if (ride['drop_address'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('→ ${ride['drop_address']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xff6A7890))),
              ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xffE7ECF5)),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const Spacer(),
              if (ride['request_eta_amount'] != null)
                Text('${ride['request_eta_amount']} ${ride['requested_currency_symbol'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff102A56))),
            ]),
          ],
        ),
      ),
    );
  }
}
