import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/constants/spaces.dart';

class CustminformationMyBooking extends StatelessWidget {
  const CustminformationMyBooking({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        title,
        // "Order ID",
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          color: const Color(
              0xFF797979), // Equivalent to #797979 (Secondary Black)
          fontSize: 12, // Font size of 12px
          fontWeight: FontWeight.w400, // Normal font weight
          height: 1.0, // Equivalent to line-height: normal;
        ),
      ),
      const HeightSpace(6),
      Text(
        subtitle,
        // "# ${data.bookingId}",
        textDirection: TextDirection.ltr,
        style: GoogleFonts.cairo(
          color: const Color(0xFF242424), // Main Black (#242424)
          fontSize: 14, // Font size of 14px
          fontWeight: FontWeight.w500, // Medium font weight
          height: 1.0, // Line height: normal (equivalent to 1.0 in Flutter)
        ),
      ),
    ]);
  }
}
