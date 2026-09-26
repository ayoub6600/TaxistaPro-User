import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'saved_card.dart';

/// Where the encrypted card blob lives. The production implementation is the
/// iOS Keychain / Android Keystore; tests use memory.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// iOS Keychain (this device only, after first unlock - it is never synced to
/// iCloud or restored onto another device) / Android EncryptedSharedPreferences
/// backed by the Keystore. Encrypted at rest by the operating system.
class SecureStorageSecretStore implements SecretStore {
  const SecureStorageSecretStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// The user's saved cards, scoped to one account on this device.
///
/// Everything (holder, number, expiry, nickname) is stored as one JSON value
/// inside the secure store - never in SharedPreferences, files, logs, the
/// backend or Firebase. Operations are serialised so quick taps cannot
/// interleave a read-modify-write and lose a card.
class CardVault {
  CardVault({required this.store, required this.ownerId});

  final SecretStore store;

  /// The signed-in user id, so two accounts on one phone never see each
  /// other's cards.
  final String ownerId;

  Future<void> _tail = Future.value();

  String get _key => 'taxista.moamalat.cards.v1.$ownerId';

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<List<SavedCard>> load() => _serial(_read);

  Future<List<SavedCard>> _read() async {
    try {
      final raw = await store.read(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final cards = decoded.map(SavedCard.fromJson).whereType<SavedCard>().toList();
      return _ordered(cards);
    } catch (_) {
      // An unreadable blob is treated as "no cards", never as a crash.
      return [];
    }
  }

  Future<void> _write(List<SavedCard> cards) =>
      store.write(_key, jsonEncode(cards.map((c) => c.toJson()).toList()));

  List<SavedCard> _ordered(List<SavedCard> cards) {
    final sorted = [...cards]..sort((a, b) => a.isDefault == b.isDefault ? 0 : (a.isDefault ? -1 : 1));
    return sorted;
  }

  /// One card by id (null when it was deleted meanwhile).
  Future<SavedCard?> byId(String id) async {
    for (final card in await load()) {
      if (card.id == id) return card;
    }
    return null;
  }

  Future<SavedCard?> defaultCard() async {
    final cards = await load();
    return cards.isEmpty ? null : cards.first;
  }

  Future<SavedCard> add({
    required String holderName,
    required String number,
    required int expMonth,
    required int expYear,
    String? nickname,
  }) {
    return _serial(() async {
      final cards = await _read();
      final digits = CardRules.digitsOnly(number);
      final card = SavedCard(
        id: _newId(),
        holderName: holderName.trim(),
        number: digits,
        expMonth: expMonth,
        expYear: expYear,
        nickname: (nickname == null || nickname.trim().isEmpty) ? null : nickname.trim(),
        // The first card becomes the default automatically.
        isDefault: cards.isEmpty,
      );
      await _write([...cards, card]);
      return card;
    });
  }

  /// Change name / expiry / nickname; pass [number] only to replace the number.
  Future<SavedCard?> update(
    String id, {
    String? holderName,
    String? number,
    int? expMonth,
    int? expYear,
    String? nickname,
    bool clearNickname = false,
  }) {
    return _serial(() async {
      final cards = await _read();
      final index = cards.indexWhere((c) => c.id == id);
      if (index < 0) return null;
      final updated = cards[index].copyWith(
        holderName: holderName?.trim(),
        number: number == null ? null : CardRules.digitsOnly(number),
        expMonth: expMonth,
        expYear: expYear,
        nickname: nickname?.trim(),
        clearNickname: clearNickname || (nickname != null && nickname.trim().isEmpty),
      );
      cards[index] = updated;
      await _write(cards);
      return updated;
    });
  }

  Future<void> setDefault(String id) {
    return _serial(() async {
      final cards = await _read();
      if (!cards.any((c) => c.id == id)) return;
      await _write([for (final c in cards) c.copyWith(isDefault: c.id == id)]);
    });
  }

  Future<void> delete(String id) {
    return _serial(() async {
      var cards = await _read();
      final removed = cards.where((c) => c.id == id).toList();
      cards = cards.where((c) => c.id != id).toList();
      // Deleting the default hands the role to the next card.
      if (removed.any((c) => c.isDefault) && cards.isNotEmpty && !cards.any((c) => c.isDefault)) {
        cards[0] = cards[0].copyWith(isDefault: true);
      }
      if (cards.isEmpty) {
        await store.delete(_key);
      } else {
        await _write(cards);
      }
    });
  }

  Future<void> clearAll() => _serial(() => store.delete(_key));

  static final Random _random = Random.secure();

  static String _newId() =>
      List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
