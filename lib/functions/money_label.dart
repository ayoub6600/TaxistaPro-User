/// What the rider reads next to an amount: the word in Arabic, the code otherwise,
/// and always the ride's own currency.
String moneyLabel(dynamic currency, {required bool arabic}) {
  final value = '${currency ?? ''}'.trim();
  final key = value.toUpperCase();
  if (value.isEmpty || const {'LYD', 'LYD.', 'د.ل', 'ل.د'}.contains(key)) {
    return arabic ? 'دينار' : 'LYD';
  }
  if (arabic && const {'EGP', '£', 'E£', 'ج.م'}.contains(key)) return 'جنيه';
  return value;
}

/// The short sign next to a price (owner 2026-11-24: «د.ل» not «LYD»): «12 د.ل», «40 ج.م»; the code in English.
String moneyShort(dynamic currency, {required bool arabic}) {
  final value = '${currency ?? ''}'.trim();
  final key = value.toUpperCase();
  if (value.isEmpty || const {'LYD', 'LYD.', 'د.ل', 'ل.د', 'دينار'}.contains(key)) {
    return arabic ? 'د.ل' : 'LYD';
  }
  if (const {'EGP', '£', 'E£', 'ج.م', 'جنيه'}.contains(key)) return arabic ? 'ج.م' : 'EGP';
  return value;
}

/// An amount as the rider reads it: «11» when whole, «11.50» otherwise (owner 2026-11-25: no «.00»).
String moneyAmount(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('${value ?? ''}'.trim());
  if (number == null) return '${value ?? ''}'.trim();
  final cents = (number * 100).round();
  return cents % 100 == 0 ? (cents ~/ 100).toString() : (cents / 100).toStringAsFixed(2);
}

/// «11 د.ل»: the amount first, then the short sign («11 LYD» in English). Shown in the
/// surrounding direction, so an Arabic reader meets the number first.
String moneyText(dynamic amount, dynamic currency, {required bool arabic}) =>
    '${moneyAmount(amount)} ${moneyShort(currency, arabic: arabic)}';
