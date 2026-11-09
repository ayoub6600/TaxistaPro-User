import 'functions.dart';

/// A quote in another currency than the rider's wallet: the wallet can't pay it, so the ride is cash.
/// The server enforces the same (wallet_same_currency_only). The home screen explains it (MarketSwitch).
class MarketNotice {
  static String get rideCurrency {
    if (etaDetails.isEmpty) return '';
    final first = etaDetails.first;
    return first is Map ? '${first['currency_name'] ?? ''}'.toUpperCase() : '';
  }

  static String get walletCurrency => '${userDetails['currency_code'] ?? ''}'.toUpperCase();

  /// true when this quote is in another currency than the rider's wallet
  static bool get foreign => rideCurrency.isNotEmpty && walletCurrency.isNotEmpty && rideCurrency != walletCurrency;
}
