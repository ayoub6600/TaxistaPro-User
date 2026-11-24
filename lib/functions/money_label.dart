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
