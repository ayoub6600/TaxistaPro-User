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

  String get last4 => number.length >= 4 ? number.substring(number.length - 4) : number;

  /// `**** **** **** 1234`
  String get masked => '**** **** **** $last4';

  /// `12/28`
  String get expiryText =>
      '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';

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

  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// `4111111111111111` -> `4111 1111 1111 1111`
  static String groupNumber(String digits) {
    final clean = digitsOnly(digits);
    final out = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) out.write(' ');
      out.write(clean[i]);
    }
    return out.toString();
  }

  static bool luhnValid(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return digits.isNotEmpty && sum % 10 == 0;
  }

  /// Visa and Mastercard numbers must pass the Luhn check. Other issuers
  /// (including local Libyan cards) are only length-checked, so a genuine card
  /// is never rejected by a rule that does not apply to it.
  static bool isNumberValid(String input) {
    final digits = digitsOnly(input);
    if (digits.length < 12 || digits.length > 19) return false;
    final major = digits.startsWith('4') || RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits);
    return major ? luhnValid(digits) : true;
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
