import 'package:flutter/foundation.dart';

import '../catalog.dart';
import '../web_game.dart';
import 'game_core.dart';

/// What the admin panel controls. The app ships every game; the server only
/// switches them on/off, marks «جديد», and orders them.
///
/// Server shape (part of an existing settings response, cached by the host):
/// `{'enabled': true, 'games': [{'id': 'night', 'enabled': true, 'new': true}, ...]}`
class WaitingGamesConfig {
  WaitingGamesConfig._();

  static bool enabled = false;
  static Set<String> disabledGames = <String>{};
  static Set<String> newGames = <String>{};
  static List<String> order = <String>[];

  /// games from the server (public/waiting-games): shown with the app's own, no update needed
  static List<TaxistaGame> webGames = <TaxistaGame>[];

  /// the admin's rules: show while searching / while the driver comes
  static bool whileSearching = true;
  static bool whileDriverComing = true;

  /// [serverConfig] null (missing / failed / old backend) = off, except in a
  /// tryout build (TestFlight) where [tryoutBuild] turns everything on.
  static void loadFrom(Map? serverConfig, {bool tryoutBuild = false}) {
    disabledGames = <String>{};
    newGames = <String>{};
    order = <String>[];
    webGames = <TaxistaGame>[];
    whileSearching = true;
    whileDriverComing = true;
    if (serverConfig == null) {
      enabled = tryoutBuild;
      return;
    }
    enabled = _flag(serverConfig['enabled']);
    final games = serverConfig['games'];
    if (games is List) {
      for (final g in games) {
        if (g is! Map) continue;
        final id = g['id']?.toString();
        if (id == null || id.isEmpty) continue;
        order.add(id);
        if (g.containsKey('enabled') && !_flag(g['enabled'])) disabledGames.add(id);
        if (_flag(g['new'])) newGames.add(id);
        if (g['kind'] == 'web' && '${g['url'] ?? ''}'.startsWith('http')) webGames.add(WebGame.fromJson(g));
      }
    }
    final rules = serverConfig['rules'];
    if (rules is Map) {
      if (rules.containsKey('while_searching')) whileSearching = _flag(rules['while_searching']);
      if (rules.containsKey('while_driver_coming')) whileDriverComing = _flag(rules['while_driver_coming']);
    }
    final disabled = serverConfig['disabled'];
    if (disabled is List) disabledGames.addAll(disabled.map((e) => '$e'));
  }

  static bool _flag(dynamic v) => v == true || v == 1 || v?.toString() == '1' || v?.toString() == 'true';

  static bool isNew(String id) => newGames.contains(id);

  /// Games the rider may see, in the admin's order (unknown ids keep catalog order).
  static List<TaxistaGame> visibleGames() {
    if (!enabled) return const <TaxistaGame>[];
    final all = <TaxistaGame>[...GameCatalog.all, ...webGames];
    final list = all.where((g) => !disabledGames.contains(g.id)).toList();
    int rank(TaxistaGame g) {
      final i = order.indexOf(g.id);
      return i >= 0 ? i : 1000 + all.indexOf(g);
    }

    list.sort((a, b) => rank(a).compareTo(rank(b)));
    return list;
  }

  @visibleForTesting
  static void reset() {
    enabled = false;
    webGames = <TaxistaGame>[];
    whileSearching = true;
    whileDriverComing = true;
    disabledGames = <String>{};
    newGames = <String>{};
    order = <String>[];
  }
}
