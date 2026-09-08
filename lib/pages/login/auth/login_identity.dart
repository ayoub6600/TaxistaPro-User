String normalizePhoneIdentity({
  required String input,
  required String dialCode,
  required int maxLocalLength,
}) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  final dialDigits = dialCode.replaceAll(RegExp(r'\D'), '');

  if (dialDigits.isNotEmpty &&
      digits.startsWith(dialDigits) &&
      digits.length > maxLocalLength) {
    digits = digits.substring(dialDigits.length);
  }

  return digits;
}
