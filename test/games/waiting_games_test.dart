import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/games/waiting_games.dart';

RideGameStatus _status(String phase) => RideGameStatus(
      phase: phase,
      driverName: 'محمد',
      etaText: '6 دقائق',
      carText: 'أكسنت بيضاء',
      onCall: () {},
      onChat: () {},
      onBackToTrip: () {},
    );

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _frames(WidgetTester tester, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUp(() {
    GamesTheme.useGoogleFonts = false;
    SharedPreferences.setMockInitialValues({});
    GameProgress.instance.resetForTest();
    WaitingGamesConfig.loadFrom(null, tryoutBuild: true);
  });

  test('catalog has at least 15 unique games with Arabic names', () {
    final ids = GameCatalog.all.map((g) => g.id).toList();
    expect(ids.length, greaterThanOrEqualTo(15));
    expect(ids.toSet().length, ids.length);
    final latin = RegExp(r'[A-Za-z]');
    for (final g in GameCatalog.all) {
      expect(latin.hasMatch(g.title), isFalse, reason: g.id);
      expect(latin.hasMatch(g.pitch), isFalse, reason: g.id);
      expect(latin.hasMatch(g.badge), isFalse, reason: g.id);
    }
  });

  test('config: null = off unless tryout; server switches a game off and reorders', () {
    WaitingGamesConfig.loadFrom(null);
    expect(WaitingGamesConfig.enabled, isFalse);
    expect(WaitingGamesConfig.visibleGames(), isEmpty);

    WaitingGamesConfig.loadFrom(null, tryoutBuild: true);
    expect(WaitingGamesConfig.visibleGames().length, GameCatalog.all.length);

    WaitingGamesConfig.loadFrom({
      'enabled': true,
      'games': [
        {'id': 'ring', 'enabled': true, 'new': true},
        {'id': 'night', 'enabled': false},
      ],
    });
    final ids = WaitingGamesConfig.visibleGames().map((g) => g.id).toList();
    expect(ids, isNot(contains('night')));
    expect(ids.first, 'ring');
    expect(WaitingGamesConfig.isNew('ring'), isTrue);

    WaitingGamesConfig.loadFrom({'enabled': 0});
    expect(WaitingGamesConfig.visibleGames(), isEmpty);
  });

  test('progress is saved and loaded locally', () async {
    final p = GameProgress.instance;
    final game = GameCatalog.byId('park')!;
    final earned = p.record(game, const GameResult(stars: 3, title: 't', line: 'l', level: 1, score: 9));
    p.record(game, const GameResult(stars: 2, title: 't', line: 'l', level: 2, score: 5));
    p.record(game, const GameResult(stars: 1, title: 't', line: 'l', level: 3, score: 2));
    await p.save();
    expect(earned, isEmpty);
    expect(p.badges, contains('park'));
    p.resetForTest();
    expect(p.totalStars, 0);
    await p.load();
    expect(p.stats('park').starTotal, 6);
    expect(p.level('park'), 4);
    expect(p.stats('park').best, 9);
    expect(p.badges, contains('park'));
  });

  testWidgets('every game simulates and paints in box, portrait and landscape (with rotation)', (tester) async {
    const sizes = [Size(360, 160), Size(374, 760), Size(828, 320)];
    for (final g in GameCatalog.all) {
      final game = g as WorldGame;
      for (final size in sizes) {
        GameResult? result;
        final s = GameSession(game: game, level: 4, onFinish: (r) => result = r, silent: true);
        final w = game.worldFor(s);
        w.ensure(size);
        for (var i = 0; i < 60 * 130 && !w.over; i++) {
          w.auto(1 / 60);
          w.step(1 / 60);
          if (i % 30 == 0) {
            final rec = ui.PictureRecorder();
            w.paintAll(Canvas(rec));
            rec.endRecording().dispose();
          }
          if (i == 200) w.ensure(Size(size.height + 40, size.width)); // rotate mid-round
          if (i == 400) w.ensure(size);
        }
        // pointer input in virtual space must never throw
        w.down(const Offset(10, 10));
        w.move(const Offset(40, 30));
        w.up(const Offset(40, 30));
        expect(w.over || result == null, isTrue, reason: '${g.id} $size');
        if (result != null) expect(result!.stars, inInclusiveRange(0, 3));
      }
    }
  });

  testWidgets('every game builds and runs in the small box 360×160', (tester) async {
    await _setSize(tester, const Size(400, 800));
    final status = ValueNotifier(_status('searching'));
    for (final g in GameCatalog.all) {
      final ctrl = WaitingGamesController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 360, child: WaitingGamesBox(status: status, height: 160, onClose: () {}, controller: ctrl)),
          ),
        ),
      ));
      ctrl.play(g);
      await tester.pump();
      ctrl.tapToStart();
      await _frames(tester);
      await tester.tapAt(tester.getCenter(find.byType(WaitingGamesBox)));
      await _frames(tester, 4);
      expect(tester.takeException(), isNull, reason: g.id);
      await tester.pumpWidget(const SizedBox());
      ctrl.dispose();
    }
  });

  for (final size in const [Size(390, 844), Size(844, 390)]) {
    testWidgets('every game builds full screen ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      await _setSize(tester, size);
      final status = ValueNotifier(_status('accepted'));
      for (final g in GameCatalog.all) {
        final ctrl = WaitingGamesController()..play(g);
        await tester.pumpWidget(MaterialApp(home: WaitingGamesFullScreen(controller: ctrl, status: status)));
        ctrl.tapToStart();
        await _frames(tester);
        expect(tester.takeException(), isNull, reason: '${g.id} $size');
        await tester.pumpWidget(const SizedBox());
        ctrl.dispose();
      }
    });
  }

  testWidgets('picker and games center lay out in portrait and landscape', (tester) async {
    for (final size in const [Size(390, 844), Size(844, 390)]) {
      await _setSize(tester, size);
      final status = ValueNotifier(_status('searching'));
      await tester.pumpWidget(MaterialApp(home: GamesCenterPage(status: status)));
      await _frames(tester, 3);
      expect(find.text('مركز الألعاب'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: WaitingGamesBox(status: status, height: 200, onClose: () {})),
      ));
      await _frames(tester, 3);
      expect(find.text('اختار لعبة'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('full screen pops by itself when the driver arrives; progress kept', (tester) async {
    await _setSize(tester, const Size(390, 844));
    final status = ValueNotifier(_status('searching'));
    final ctrl = WaitingGamesController();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                ctrl.play(GameCatalog.byId('ring')!);
                WaitingGamesFullScreen.open(context, controller: ctrl, status: status);
              },
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('افتح'));
    await _frames(tester, 30);
    expect(find.byType(WaitingGamesFullScreen), findsOneWidget);
    ctrl.tapToStart();
    await _frames(tester, 10);
    status.value = _status('accepted');
    await _frames(tester, 4);
    expect(find.textContaining('لقينا لك سائق'), findsOneWidget);
    status.value = _status('approaching');
    await _frames(tester, 4);
    expect(find.text('السائق قرّب يوصل!'), findsOneWidget);
    expect(ctrl.session!.paused.value, isTrue);
    status.value = _status('arrived');
    await _frames(tester, 40);
    expect(find.byType(WaitingGamesFullScreen), findsNothing);
    expect(ctrl.session, isNotNull);
    expect(ctrl.session!.paused.value, isTrue);
    await tester.pump(const Duration(seconds: 5));
    ctrl.dispose();
  });

  testWidgets('box closes itself on arrival', (tester) async {
    await _setSize(tester, const Size(390, 844));
    final status = ValueNotifier(_status('searching'));
    var closed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WaitingGamesBox(status: status, height: 190, onClose: () => closed++)),
    ));
    await _frames(tester, 2);
    status.value = _status('arrived');
    await _frames(tester, 2);
    expect(closed, 1);
  });
}
