import 'card_brand.dart';

/// A payment card the user chose to keep on THIS device for Moamalat top-ups.
///
/// There is deliberately no CVV anywhere in this model: the security code is
/// never asked for, stored, copied or sent. The card number is a secret that
/// only ever lives in the platform secure store (see `card_vault.dart`); it is
/// never written to the Taxista backend, logs, analytics or Firebase.
class SavedCard {
  const SavedCard({
    required this.id,
    required this.holderName,
    required this.number,
    required this.expMonth,
    required this.expYear,
    this.nickname,
    this.isDefault = false,
    this.brandHint,
  });

  final String id;
  final String holderName;

  /// Digits only. Secret - never log, never show in full.
  final String number;
  final int expMonth;

  /// Four digits, e.g. 2028.
  final int expYear;
  final String? nickname;
  final bool isDefault;

  /// The network of the real number, kept on a [redacted] copy (whose digits
  /// are stars) so the card is still drawn with the right mark. Never stored.
  final CardBrand? brandHint;

  CardBrand get brand => brandHint ?? cardBrandOf(number);

  bool isExpired({DateTime? now}) => CardRules.isExpired(expMonth, expYear, now: now);

  String get last4 => number.length >= 4 ? number.substring(number.length - 4) : number;

  /// `**** **** **** 1234`
  String get masked => '**** **** **** $last4';

  /// `•••• •••• •••• 1234`, as drawn on the card picture.
  String get maskedDots => '•••• •••• •••• $last4';

  /// `12/28`
  String get expiryText =>
      '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';

  /// The same card with the number blanked out except its last four digits - safe to keep in
  /// screen state. The real number is fetched from the vault again only when the
  /// customer explicitly asks for it (Smart Fill / copy).
  SavedCard redacted() => SavedCard(
        id: id,
        holderName: holderName,
        number: '${'*' * 12}$last4',
        expMonth: expMonth,
        expYear: expYear,
        nickname: nickname,
        isDefault: isDefault,
        brandHint: brand,
      );

  /// Name to show in lists: the nickname if there is one, else the holder.
  String get title => (nickname != null && nickname!.trim().isNotEmpty) ? nickname!.trim() : holderName;

  SavedCard copyWith({
    String? holderName,
    String? number,
    int? expMonth,
    int? expYear,
    String? nickname,
    bool clearNickname = false,
    bool? isDefault,
  }) {
    return SavedCard(
      id: id,
      holderName: holderName ?? this.holderName,
      number: number ?? this.number,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      nickname: clearNickname ? null : (nickname ?? this.nickname),
      isDefault: isDefault ?? this.isDefault,
      // A new number decides its own brand.
      brandHint: number == null ? brandHint : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'holder': holderName,
        'number': number,
        'expMonth': expMonth,
        'expYear': expYear,
        if (nickname != null) 'nickname': nickname,
        'isDefault': isDefault,
      };

  static SavedCard? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final number = raw['number']?.toString() ?? '';
    final month = int.tryParse(raw['expMonth']?.toString() ?? '');
    final year = int.tryParse(raw['expYear']?.toString() ?? '');
    final id = raw['id']?.toString() ?? '';
    if (id.isEmpty || number.isEmpty || month == null || year == null) return null;
    return SavedCard(
      id: id,
      holderName: raw['holder']?.toString() ?? '',
      number: number,
      expMonth: month,
      expYear: year,
      nickname: raw['nickname']?.toString(),
      isDefault: raw['isDefault'] == true,
    );
  }

  /// Never prints the number, so an accidental `print(card)` stays safe.
  @override
  String toString() => 'SavedCard($masked, $expiryText)';
}

/// Input rules for the add / edit card form.
class CardRules {
  const CardRules._();

  /// Digits only; Arabic-Indic digits count as digits.
  static String digitsOnly(String input) => normalizeDigits(input).replaceAll(RegExp(r'\D'), '');

  /// `4111111111111111` -> `4111 1111 1111 1111` (Amex 4-6-5).
  static String groupNumber(String digits) => groupCardNumber(digitsOnly(digits));

  static bool luhnValid(String digits) {
    if (digits.isEmpty) return false;
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = digits.codeUnitAt(i) - 48;
      if (n < 0 || n > 9) return false;
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Visa, Mastercard and Amex numbers must have one of their lengths and pass
  /// the Luhn check. Numo, Meeza and other local cards are only length-checked,
  /// so a genuine card is never rejected by a rule that may not apply to it.
  static bool isNumberValid(String input) {
    final digits = digitsOnly(input);
    if (digits.length < 12 || digits.length > 19) return false;
    final brand = cardBrandOf(digits);
    if (!brand.usesLuhn) return true;
    return brand.lengths.contains(digits.length) && luhnValid(digits);
  }

  static bool isHolderValid(String input) => input.trim().length >= 2;

  /// Parses `MM/YY` or `MM/YYYY` (separator optional). Null when malformed.
  static ({int month, int year})? parseExpiry(String input) {
    final digits = digitsOnly(input);
    if (digits.length != 4 && digits.length != 6) return null;
    final month = int.tryParse(digits.substring(0, 2));
    var year = int.tryParse(digits.substring(2));
    if (month == null || year == null || month < 1 || month > 12) return null;
    if (digits.length == 4) year += 2000;
    return (month: month, year: year);
  }

  /// A card is usable until the END of its expiry month.
  static bool isExpired(int month, int year, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return year < today.year || (year == today.year && month < today.month);
  }

  static bool isExpiryValid(String input, {DateTime? now}) {
    final parsed = parseExpiry(input);
    return parsed != null && parsed.year <= (now ?? DateTime.now()).year + 20 && !isExpired(parsed.month, parsed.year, now: now);
  }
}
