import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../functions/prior_balance.dart';

/// The ride screens' blues (same as the trip fare card) and the calm amber of «رصيد سابق».
const _blue = Color(0xff1677FF);
const _navy = Color(0xff102A56);
const _muted = Color(0xff7B8BA8);
const _amber = Color(0xffB7791F);

/// During the ride, in place of «سعر الرحلة 11 د.ل»: «تدفع للكابتن 15 د.ل» and, under it,
/// «11 أجرة + 4 رصيد سابق عليك».
class PriorBalanceDueBadge extends StatelessWidget {
  const PriorBalanceDueBadge({super.key, required this.words});

  final PriorBalanceWords words;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffDCEAFF)),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: Color(0xffE8F2FF), shape: BoxShape.circle),
          child: const Icon(Icons.payments_outlined, size: 18, color: _blue),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(words.payCaptainLabel,
                style: GoogleFonts.cairo(color: _navy, fontSize: 13, fontWeight: FontWeight.w800, height: 1.3)),
            Text(words.dueBreakdown,
                key: const ValueKey('prior-due-breakdown'),
                style: GoogleFonts.cairo(color: _amber, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.3)),
          ]),
        ),
        const SizedBox(width: 10),
        Text(words.total,
            key: const ValueKey('prior-due-total'),
            style: GoogleFonts.cairo(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

/// After the ride: the big total he paid, then «أجرة الرحلة 11 د.ل» and «رصيد سابق عليك 4 د.ل».
class PriorBalancePaidSummary extends StatelessWidget {
  const PriorBalancePaidSummary({super.key, required this.title, required this.words, this.totalSize = 26});

  final String title;
  final PriorBalanceWords words;
  final double totalSize;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: _blue, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(words.total,
          key: const ValueKey('prior-paid-total'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: _navy, fontSize: totalSize, fontWeight: FontWeight.w900, height: 1.2)),
      const SizedBox(height: 4),
      Text(words.fareLine,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: _muted, fontSize: 13, fontWeight: FontWeight.w700)),
      Text(words.priorLine,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: _amber, fontSize: 13, fontWeight: FontWeight.w800)),
    ]);
  }
}

/// Services sheet, above the request button: one calm line about the old balance.
class PriorBalanceBookingNote extends StatelessWidget {
  const PriorBalanceBookingNote({super.key, required this.words});

  final PriorBalanceWords words;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xffF4F8FE), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, size: 18, color: _blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(words.bookingNote,
              style: GoogleFonts.cairo(color: _navy, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4)),
        ),
      ]),
    );
  }
}
