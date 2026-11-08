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
