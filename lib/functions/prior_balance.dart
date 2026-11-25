import 'money_label.dart';

/// «رصيد سابق»: a rider whose wallet went below zero (an old fee) settles it in cash on his next
/// cash ride - the captain collects fare + owed (server PriorBalanceCollector). Owner 2026-11-25:
/// the rider only saw the fare big, paid 11 instead of 15, and the captain lost 4. So every screen
/// shows the total he hands over, and what it is made of.
class PriorBalanceSplit {
  const PriorBalanceSplit({required this.fare, required this.prior});

  /// what this ride itself costs in cash
  final double fare;

  /// the old balance owed, collected with it
  final double prior;

  double get total => fare + prior;
}

/// A positive amount owed, or 0 (missing, empty, zero, negative or not a number).
double priorBalanceAmount(dynamic value) {
  final amount = value is num ? value.toDouble() : double.tryParse('${value ?? ''}'.trim());
  return amount != null && amount > 0 ? amount : 0;
}

/// The server collects it only on cash (1) and wallet + cash (3) rides, never from the wallet alone.
bool priorBalancePaidInCash(dynamic paymentOpt) => const {'1', '3'}.contains('${paymentOpt ?? ''}'.trim());

/// What the captain collects on top of [fare] on a ride paid with [paymentOpt]; null when nothing.
PriorBalanceSplit? priorBalanceSplit({required dynamic paymentOpt, required dynamic prior, required double fare}) {
  if (!priorBalancePaidInCash(paymentOpt)) return null;
  final owed = priorBalanceAmount(prior);
  if (owed <= 0) return null;
  return PriorBalanceSplit(fare: fare, prior: owed);
}

/// During the ride (driver on the way, arrived, on the trip): the ride's `prior_balance_due`.
PriorBalanceSplit? activeRidePriorBalance(Map<dynamic, dynamic> ride, {required double fare}) =>
    priorBalanceSplit(paymentOpt: ride['payment_opt'], prior: ride['prior_balance_due'], fare: fare);

/// After the ride: the bill's `prior_balance_collected` (the server only sets it on a cash ride).
PriorBalanceSplit? invoicePriorBalance(Map<dynamic, dynamic> ride, {required double fare}) {
  final bill = ride['requestBill'];
  final data = bill is Map ? bill['data'] : null;
  final owed = priorBalanceAmount(data is Map ? data['prior_balance_collected'] : null);
  if (owed <= 0) return null;
  return PriorBalanceSplit(fare: fare, prior: owed);
}

/// The words, one place for all screens: «د.ل» after the amount, no «.00».
class PriorBalanceWords {
  const PriorBalanceWords(this.split, this.currency, {required this.arabic});

  final PriorBalanceSplit split;
  final dynamic currency;
  final bool arabic;

  String get total => moneyText(split.total, currency, arabic: arabic);

  /// active ride: «تدفع للكابتن»
  String get payCaptainLabel => arabic ? 'تدفع للكابتن' : 'You pay the captain';

  /// active ride: «11 أجرة + 4 رصيد سابق عليك»
  String get dueBreakdown => arabic
      ? '${moneyAmount(split.fare)} أجرة + ${moneyAmount(split.prior)} رصيد سابق عليك'
      : '${moneyAmount(split.fare)} fare + ${moneyAmount(split.prior)} earlier balance';

  /// invoice: «أجرة الرحلة 11 د.ل»
  String get fareLine => arabic
      ? 'أجرة الرحلة ${moneyText(split.fare, currency, arabic: true)}'
      : 'Trip fare ${moneyText(split.fare, currency, arabic: false)}';

  /// invoice: «رصيد سابق عليك 4 د.ل»
  String get priorLine => arabic
      ? 'رصيد سابق عليك ${moneyText(split.prior, currency, arabic: true)}'
      : 'Your earlier balance ${moneyText(split.prior, currency, arabic: false)}';

  /// services sheet, under the price: «+ 4 د.ل رصيد سابق عليك»
  String get priceAddOn => arabic
      ? '+ ${moneyText(split.prior, currency, arabic: true)} رصيد سابق عليك'
      : '+ ${moneyText(split.prior, currency, arabic: false)} earlier balance';

  /// services sheet, above the button (calm, not alarming)
  String get bookingNote => arabic
      ? 'عليك ${moneyText(split.prior, currency, arabic: true)} من رحلة سابقة، تدفعها للكابتن مع هذي الرحلة.'
      : 'You owe ${moneyText(split.prior, currency, arabic: false)} from an earlier ride; you pay it to the captain with this ride.';
}
