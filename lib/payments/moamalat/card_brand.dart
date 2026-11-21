/// The card network, read from the first digits (the BIN). Used only to draw
/// the right mark on the card, to say whether the card has a security code and
/// to choose how strictly the number is checked - never sent anywhere.
enum CardBrand { visa, mastercard, amex, meeza, numo, local }

extension CardBrandInfo on CardBrand {
  String get label {
    switch (this) {
      case CardBrand.visa:
        return 'VISA';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'AMEX';
      case CardBrand.meeza:
        return 'Meeza';
      case CardBrand.numo:
        return 'Numo';
      case CardBrand.local:
        return '';
    }
  }

  /// Only the international networks are known to always carry a Luhn check
  /// digit. Numo, Meeza and other local cards are length-checked only, so a
  /// genuine card is never rejected by a rule that may not apply to it.
  bool get usesLuhn => this == CardBrand.visa || this == CardBrand.mastercard || this == CardBrand.amex;

  /// A Libyan Numo card has no security code (the bank's page hides the CVV
  /// field for it). Nothing here ever asks for or keeps a CVV either way.
  bool get hasCvv => this != CardBrand.numo;

  /// The lengths the number is expected to have (validation uses them only for
  /// the Luhn brands; the scanner prefers them when several runs are seen).
  List<int> get lengths {
    switch (this) {
      case CardBrand.amex:
        return const [15];
      case CardBrand.visa:
        return const [13, 16, 19];
      case CardBrand.mastercard:
      case CardBrand.meeza:
        return const [16];
      case CardBrand.numo:
        return const [16, 17, 18, 19];
      case CardBrand.local:
        return const [12, 13, 14, 15, 16, 17, 18, 19];
    }
  }
}

CardBrand cardBrandOf(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return CardBrand.local;
  if (d.startsWith('4')) return CardBrand.visa;
  // Libya's national switch card: 63… or 8….
  if (d.startsWith('8')) return CardBrand.numo;
  if (d.length >= 2) {
    final two = int.parse(d.substring(0, 2));
    if (two == 63) return CardBrand.numo;
    if (two == 34 || two == 37) return CardBrand.amex;
    if (two >= 51 && two <= 55) return CardBrand.mastercard;
  }
  // Egypt's national card (Meeza) starts 5078.
  if (d.startsWith('5078')) return CardBrand.meeza;
  if (d.length >= 4) {
    final four = int.parse(d.substring(0, 4));
    if (four >= 2221 && four <= 2720) return CardBrand.mastercard;
  }
  return CardBrand.local;
}

/// `4111111111111111` -> `4111 1111 1111 1111`; Amex is grouped 4-6-5.
String groupCardNumber(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  final groups = cardBrandOf(d) == CardBrand.amex ? const [4, 6, 5] : const [4, 4, 4, 4];
  final out = <String>[];
  var i = 0;
  for (final g in groups) {
    if (i >= d.length) break;
    final end = (i + g) > d.length ? d.length : i + g;
    out.add(d.substring(i, end));
    i = end;
  }
  // 17-19 digit cards: the rest in one more group.
  if (i < d.length) out.add(d.substring(i));
  return out.join(' ');
}

/// Arabic-Indic and Persian digits -> Latin, so an Arabic keyboard works.
String normalizeDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final a = arabic.indexOf(ch);
    final p = persian.indexOf(ch);
    out.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
  }
  return out.toString();
}
