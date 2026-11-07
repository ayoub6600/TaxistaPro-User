import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'core/game_core.dart';
import 'core/theme.dart';

/// A game that lives on the server (public/waiting-games/<id>/): the admin adds it in Taxista Admin
/// and every app shows it at once, no update. It runs in a web view inside the same box / full screen,
/// talking to the app through `TaxistaGames` (bridge.js): the app pauses/starts it, it reports the result.
class WebGame extends TaxistaGame {
  const WebGame({required this.id, required this.title, required this.pitch, required this.icon, required this.badge, required this.url});

  factory WebGame.fromJson(Map g) => WebGame(
        id: '${g['id']}',
        title: '${g['title'] ?? g['id']}',
        pitch: '${g['pitch'] ?? ''}',
        icon: iconFor('${g['icon'] ?? ''}'),
        badge: '${g['badge'] ?? ''}'.isEmpty ? '${g['title'] ?? ''}' : '${g['badge']}',
        url: '${g['url'] ?? ''}',
      );

  @override
  final String id;
  @override
  final String title;
  @override
  final String pitch;
  @override
  final IconData icon;
  @override
  final String badge;
  final String url;

  static IconData iconFor(String name) => switch (name) {
        'grid_view' => Icons.grid_view_rounded,
        'add_road' => Icons.add_road_rounded,
        'traffic' => Icons.traffic_rounded,
        'local_taxi' => Icons.local_taxi_rounded,
        'route' || 'alt_route' => Icons.alt_route_rounded,
        'star' || 'auto_awesome' => Icons.auto_awesome_rounded,
        'puzzle' || 'extension' => Icons.extension_rounded,
        'speed' => Icons.speed_rounded,
        _ => Icons.sports_esports_rounded,
      };

  @override
  Widget build(BuildContext context, GameSession session) => _WebGameView(key: ValueKey('web-$id-${session.level}'), game: this, session: session);
}

class _WebGameView extends StatefulWidget {
  const _WebGameView({super.key, required this.game, required this.session});
  final WebGame game;
  final GameSession session;

  @override
  State<_WebGameView> createState() => _WebGameViewState();
}

class _WebGameViewState extends State<_WebGameView> {
  // kept on the session: the same page continues when the box grows to full screen
  late final WebViewController _web;
  bool _loaded = false;
  bool _failed = false;

  GameSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    final existing = s.world;
    if (existing is WebViewController) {
      _web = existing;
      _loaded = true;
    } else {
      final sep = widget.game.url.contains('?') ? '&' : '?';
      _web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(GamesTheme.night)
        ..addJavaScriptChannel('TaxistaGames', onMessageReceived: (m) => _onMessage(m.message))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loaded = true);
            _syncPause();
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) {
              if (mounted) setState(() => _failed = true);
            }
          },
          // the game stays on its own page: links never leave it
          onNavigationRequest: (r) => r.url.startsWith(widget.game.url.split('?').first) ? NavigationDecision.navigate : NavigationDecision.prevent,
        ))
        ..loadRequest(Uri.parse('${widget.game.url}${sep}level=${s.level}'));
      s.world = _web;
    }
    s.paused.addListener(_syncPause);
    s.awaiting.addListener(_syncStart);
  }

  @override
  void dispose() {
    s.paused.removeListener(_syncPause);
    s.awaiting.removeListener(_syncStart);
    super.dispose();
  }

  void _syncPause() {
    if (!_loaded) return;
    _web.runJavaScript('window.taxistaPause && taxistaPause(${s.paused.value})').catchError((_) {});
  }

  void _syncStart() {
    if (!_loaded || s.awaiting.value) return;
    _web.runJavaScript('window.taxistaStart && taxistaStart()').catchError((_) {});
  }

  void _onMessage(String raw) {
    Map? m;
    try {
      final d = jsonDecode(raw);
      if (d is Map) m = d;
    } catch (_) {}
    if (m == null) return;
    switch (m['type']) {
      case 'haptic':
        s.haptic((m['strength'] as num?)?.toInt() ?? 1);
      case 'finish':
        s.finish(GameResult(
          stars: ((m['stars'] as num?)?.toInt() ?? 1).clamp(1, 3),
          score: (m['score'] as num?)?.toInt() ?? 0,
          title: '${m['title'] ?? 'خلصت المرحلة'}',
          line: '${m['line'] ?? ''}',
          level: s.level,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text('اللعبة تحتاج إنترنت. جرّب مرة ثانية أو اختار لعبة من داخل التطبيق.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 14, height: 1.5)),
        ),
      );
    }
    return Stack(fit: StackFit.expand, children: [
      // the page gets every touch (the trip sheet around it never steals a drag)
      WebViewWidget(controller: _web, gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())}),
      if (!_loaded) const Center(child: Icon(Icons.sports_esports_rounded, color: Colors.white24, size: 44)),
    ]);
  }
}
