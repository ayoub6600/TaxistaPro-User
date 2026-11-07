import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_core.dart';
import 'theme.dart';

/// Per-game local numbers.
class GameStats {
  int level = 1;
  final Map<int, int> stars = {};
  int best = 0;
  int plays = 0;
  DateTime? lastPlayed;

  int get starTotal => stars.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
        'level': level,
        'stars': stars.map((k, v) => MapEntry('$k', v)),
        'best': best,
        'plays': plays,
        if (lastPlayed != null) 'last': lastPlayed!.millisecondsSinceEpoch,
      };

  static GameStats fromJson(Map<String, dynamic> j) {
    final s = GameStats();
    s.level = (j['level'] as num?)?.toInt() ?? 1;
    final st = j['stars'];
    if (st is Map) {
      st.forEach((k, v) {
        final lv = int.tryParse('$k');
        if (lv != null && v is num) s.stars[lv] = v.toInt().clamp(0, 3);
      });
    }
    s.best = (j['best'] as num?)?.toInt() ?? 0;
    s.plays = (j['plays'] as num?)?.toInt() ?? 0;
    final last = j['last'];
    if (last is num) s.lastPlayed = DateTime.fromMillisecondsSinceEpoch(last.toInt());
    return s;
  }
}

/// Local progress only (shared_preferences). Nothing goes to the server.
class GameProgress extends ChangeNotifier {
  GameProgress._();
  static final GameProgress instance = GameProgress._();
  static const storageKey = 'taxista_waiting_games_v1';

  final Map<String, GameStats> games = {};
  final Set<String> badges = {};
  String skinId = 'blue';
  bool loaded = false;

  GameStats stats(String id) => games.putIfAbsent(id, GameStats.new);
  int level(String id) => stats(id).level;
  int get totalStars => games.values.fold(0, (a, s) => a + s.starTotal);
  Color get skinColor => CarSkin.byId(skinId).color;

  String? get lastPlayedId {
    String? id;
    DateTime? best;
    games.forEach((k, v) {
      if (v.lastPlayed != null && (best == null || v.lastPlayed!.isAfter(best!))) {
        best = v.lastPlayed;
        id = k;
      }
    });
    return id;
  }

  bool skinUnlocked(CarSkin s) => totalStars >= s.needStars;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(storageKey);
      games.clear();
      badges.clear();
      if (raw != null) {
        final j = jsonDecode(raw);
        if (j is Map) {
          final g = j['games'];
          if (g is Map) {
            g.forEach((k, v) {
              if (v is Map) games['$k'] = GameStats.fromJson(Map<String, dynamic>.from(v));
            });
          }
          final b = j['badges'];
          if (b is List) badges.addAll(b.map((e) => '$e'));
          skinId = '${j['skin'] ?? 'blue'}';
        }
      }
    } catch (_) {
      // corrupt or unavailable storage: start fresh, never crash the ride screen
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          storageKey,
          jsonEncode({
            'games': games.map((k, v) => MapEntry(k, v.toJson())),
            'badges': badges.toList(),
            'skin': skinId,
          }));
    } catch (_) {}
  }

  void touch(String id) {
    stats(id).lastPlayed = DateTime.now();
    notifyListeners();
  }

  void setSkin(CarSkin s) {
    if (!skinUnlocked(s)) return;
    skinId = s.id;
    notifyListeners();
    save();
  }

  /// Records a finished round. Returns the names of newly earned badges / skins.
  List<String> record(TaxistaGame game, GameResult r) {
    final s = stats(game.id);
    final before = totalStars;
    s.plays++;
    s.lastPlayed = DateTime.now();
    s.best = max(s.best, r.score);
    if (r.stars > 0) {
      s.stars[r.level] = max(s.stars[r.level] ?? 0, r.stars);
      if (r.level >= s.level) s.level = r.level + 1;
    }
    final earned = <String>[];
    if (s.stars.length >= 3 && badges.add(game.id)) earned.add('وسام جديد: ${game.badge}');
    if (totalStars >= 25 && badges.add('star25')) earned.add('وسام جديد: نجم الانتظار');
    if (games.values.where((g) => g.plays > 0).length >= 8 && badges.add('explorer')) {
      earned.add('وسام جديد: جرّب كل شي');
    }
    for (final sk in CarSkin.all) {
      if (sk.needStars > before && sk.needStars <= totalStars) earned.add('لون جديد للتاكسي: ${sk.name}');
    }
    notifyListeners();
    save();
    return earned;
  }

  static String badgeName(String id, List<TaxistaGame> catalog) {
    if (id == 'star25') return 'نجم الانتظار';
    if (id == 'explorer') return 'جرّب كل شي';
    for (final g in catalog) {
      if (g.id == id) return g.badge;
    }
    return id;
  }

  @visibleForTesting
  void resetForTest() {
    games.clear();
    badges.clear();
    skinId = 'blue';
    loaded = false;
  }
}
