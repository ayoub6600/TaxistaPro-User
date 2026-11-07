import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'functions.dart';

/// The rider is in another country than his account's (e.g. a Libyan account in Cairo): before he books,
/// say it once — prices are in that country's money, and his wallet (in his own currency) can't pay here,
/// so the ride is cash. The server enforces the same (wallet_same_currency_only); this only explains it.
class MarketNotice {
  static final Set<String> _shown = {};

  static String get rideCurrency {
    if (etaDetails.isEmpty) return '';
    final first = etaDetails.first;
    return first is Map ? '${first['currency_name'] ?? ''}'.toUpperCase() : '';
  }

  static String get walletCurrency => '${userDetails['currency_code'] ?? ''}'.toUpperCase();

  /// true when this quote is in another currency than the rider's wallet
  static bool get foreign => rideCurrency.isNotEmpty && walletCurrency.isNotEmpty && rideCurrency != walletCurrency;

  static String _country(String currency) => switch (currency) {
        'EGP' => 'مصر',
        'LYD' => 'ليبيا',
        'TND' => 'تونس',
        _ => 'بلد آخر',
      };

  static String _money(String currency) => switch (currency) {
        'EGP' => 'الجنيه المصري',
        'LYD' => 'الدينار الليبي',
        'TND' => 'الدينار التونسي',
        _ => currency,
      };

  static Future<void> maybeShow(BuildContext context) async {
    if (!foreign || _shown.contains(rideCurrency) || !context.mounted) return;
    _shown.add(rideCurrency);
    final country = _country(rideCurrency);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 18 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xffE3E9F2), borderRadius: BorderRadius.circular(9)))),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: const Color(0xffE6F0FF), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.public_rounded, color: Color(0xff0873FF), size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text('أنت الآن في $country؟', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xff10213F))),
            const SizedBox(height: 6),
            Text(
              'تاكسيستا يخدم هنا. الأسعار بـ${_money(rideCurrency)}، والدفع كاش للسائق.\nمحفظتك بـ${_money(walletCurrency)} تنفع في ${_country(walletCurrency)} فقط.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13.5, height: 1.6, color: const Color(0xff5B6B85)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xff0873FF), minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: Text('نعم، أنا في $country', style: GoogleFonts.cairo(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}
