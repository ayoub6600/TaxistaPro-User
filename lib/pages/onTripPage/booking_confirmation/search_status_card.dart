part of '../booking_confirmation.dart';

/// Shown while the rider's driver is being arranged behind the scenes: another driver is being
/// found, or a driver finishing a trip nearby will come next.
class _SearchStatusCard extends StatelessWidget {
  const _SearchStatusCard({required this.width, this.next});

  final double width;
  final Map? next;

  @override
  Widget build(BuildContext context) {
    final name = '${next?['name'] ?? ''}';
    final car = '${next?['car'] ?? ''}';
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      child: Row(children: [
        if (next == null)
          const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3))
        else
          const Icon(Icons.local_taxi_rounded, color: Color(0xff0A77FF), size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(next == null ? 'نجهز لك أقرب سائق' : '$name ينهي مشوار قريب ويوصلك خلال ${next!['eta_minutes']} دقيقة',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xff102A56))),
            Text(next == null ? 'لحظات وتظهر بيانات سيارتك.' : car,
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xff55678A))),
          ]),
        ),
      ]),
    );
  }
}
