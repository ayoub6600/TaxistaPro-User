import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/update/forced_update_page.dart';
import 'package:taxista/update/update_checker.dart';
import 'package:taxista/update/update_gate.dart';
import 'package:taxista/update/update_policy.dart';

Map<dynamic, dynamic> policy({
  String version = '6.4.2',
  bool mandatory = true,
  String versionIos = '',
  String versionAndroid = '',
  Object? buildIos = 0,
  Object? buildAndroid = 0,
}) =>
    {
      'version': version,
      'is_mandatory': mandatory,
      'version_ios': versionIos,
      'version_android': versionAndroid,
      'min_build_ios': buildIos,
      'min_build_android': buildAndroid,
      'release_notes': '',
      'url': '',
      'url_ios': '',
    };

UpdateDecision decide(Map<dynamic, dynamic> data, String installed,
        {int build = 1, bool ios = true}) =>
    UpdatePolicy.fromMap(data)
        .evaluate(installedVersion: installed, installedBuild: build, isIos: ios);

void main() {
  group('decision matrix', () {
    test('installed newer than the minimum opens normally', () {
      expect(decide(policy(version: '6.4.2'), '6.4.3'), UpdateDecision.none);
    });

    test('installed equal to the minimum opens normally', () {
      expect(decide(policy(version: '6.4.2'), '6.4.2'), UpdateDecision.none);
    });

    test('installed below the minimum is a mandatory update', () {
      expect(decide(policy(version: '6.4.3'), '6.4.2'), UpdateDecision.mandatory);
    });

    test('below the minimum but not mandatory is only an optional update', () {
      expect(decide(policy(version: '6.4.3', mandatory: false), '6.4.2'),
          UpdateDecision.optional);
    });

    test('versions compare numerically, never as strings (6.4.2 < 6.4.10)', () {
      expect(decide(policy(version: '6.4.10'), '6.4.2'), UpdateDecision.mandatory);
      expect(decide(policy(version: '6.4.2'), '6.4.10'), UpdateDecision.none);
      expect(decide(policy(version: '10.0.0'), '9.9.9'), UpdateDecision.mandatory);
    });

    test('an empty policy never blocks anyone', () {
      expect(decide(policy(version: ''), '1.0.0'), UpdateDecision.none);
      expect(decide(const {}, '1.0.0'), UpdateDecision.none);
    });

    test('per-platform minimums override the general one and are independent', () {
      final p = policy(version: '6.4.2', versionIos: '6.4.10', versionAndroid: '6.4.1');
      expect(decide(p, '6.4.5', ios: true), UpdateDecision.mandatory);
      expect(decide(p, '6.4.5', ios: false), UpdateDecision.none);
    });

    test('a minimum build number blocks an older build of the same version', () {
      final p = policy(version: '6.4.2', buildIos: '12', buildAndroid: 30);
      expect(decide(p, '6.4.2', build: 11, ios: true), UpdateDecision.mandatory);
      expect(decide(p, '6.4.2', build: 12, ios: true), UpdateDecision.none);
      expect(decide(p, '6.4.2', build: 29, ios: false), UpdateDecision.mandatory);
      expect(decide(p, '6.4.2', build: 30, ios: false), UpdateDecision.none);
    });

    test('loosely typed Firebase values are read correctly', () {
      expect(UpdatePolicy.fromMap({'is_mandatory': 1}).isMandatory, isTrue);
      expect(UpdatePolicy.fromMap({'is_mandatory': 'true'}).isMandatory, isTrue);
      expect(UpdatePolicy.fromMap({'is_mandatory': 0}).isMandatory, isFalse);
      expect(UpdatePolicy.fromMap({'min_build_ios': 'x'}).minBuildIos, 0);
    });
  });

  group('store links', () {
    test('this app opens its own verified listing when the admin link is blank or unsafe', () {
      for (final bad in ['', 'javascript:alert(1)', 'http://insecure.example', 'not a url']) {
        final p = UpdatePolicy(urlIos: bad, urlAndroid: bad);
        expect(
            p.storeUrl(isIos: true, fallbackIos: riderAppStoreFallback, fallbackAndroid: riderPlayStoreFallback),
            riderAppStoreFallback);
      }
      expect(riderAppStoreFallback, contains('id6739538467'), reason: 'Rider listing, not the Driver one');
      expect(riderAppStoreFallback, isNot(contains('6739504111')));
    });

    test("the admin's https link wins", () {
      const p = UpdatePolicy(urlIos: 'https://apps.apple.com/app/id6739538467');
      expect(p.storeUrl(isIos: true, fallbackIos: 'x', fallbackAndroid: 'y'),
          'https://apps.apple.com/app/id6739538467');
    });
  });

  group('Rider and Driver never share a policy', () {
    test('the Rider app only reads the Rider node', () {
      expect(riderUpdateNode, 'force_update_user');
      expect(riderUpdateNode, isNot('force_update_driver'));
    });

    test('an outdated Driver policy has no effect on the Rider decision', () {
      final riderNode = policy(version: '6.4.2', mandatory: true);
      final driverNode = policy(version: '9.9.9', mandatory: true);
      // The Rider app is only ever handed riderNode:
      expect(decide(riderNode, '6.4.2'), UpdateDecision.none);
      expect(decide(driverNode, '6.4.2'), UpdateDecision.mandatory);
    });
  });

  group('UpdateChecker on weak networks', () {
    UpdateChecker checker({
      required Future<Map<dynamic, dynamic>?> Function() fetch,
      String? cached,
      List<String>? saved,
      Duration timeout = const Duration(milliseconds: 40),
    }) =>
        UpdateChecker(
          fetch: fetch,
          readCache: () async => cached,
          writeCache: (json) async => saved?.add(json),
          timeout: timeout,
          retryDelay: const Duration(milliseconds: 5),
        );

    Future<UpdateCheckResult> run(UpdateChecker c) =>
        c.check(installedVersion: '6.4.2', installedBuild: 5, isIos: true);

    test('a live mandatory policy blocks and is remembered', () async {
      final saved = <String>[];
      final result = await run(checker(fetch: () async => policy(version: '6.4.3'), saved: saved));
      expect(result.decision, UpdateDecision.mandatory);
      expect(result.source, UpdateSource.network);
      await Future<void>.delayed(Duration.zero);
      expect(saved, hasLength(1));
    });

    test('a hanging endpoint times out and the app opens (no cache)', () async {
      var calls = 0;
      final result = await run(checker(fetch: () {
        calls++;
        return Completer<Map<dynamic, dynamic>?>().future; // never answers
      }));
      expect(result.decision, UpdateDecision.none);
      expect(result.source, UpdateSource.none);
      expect(calls, 2, reason: 'exactly one controlled retry');
    });

    test('a failing endpoint with a cached mandatory policy still blocks, without waiting', () async {
      var calls = 0;
      final result = await run(checker(
        fetch: () async {
          calls++;
          throw TimeoutException('offline');
        },
        cached: jsonEncode(UpdatePolicy.fromMap(policy(version: '6.4.3')).toJson()),
      ));
      expect(result.decision, UpdateDecision.mandatory);
      expect(result.source, UpdateSource.cache);
      expect(calls, 1);
    });

    test('a corrupt cache is ignored, never a crash', () async {
      final result = await run(checker(fetch: () async => throw Exception('x'), cached: '{not json'));
      expect(result.decision, UpdateDecision.none);
    });

    test('the retry can succeed', () async {
      var calls = 0;
      final result = await run(checker(fetch: () async {
        calls++;
        if (calls == 1) throw Exception('blip');
        return policy(version: '6.4.3');
      }));
      expect(result.decision, UpdateDecision.mandatory);
      expect(calls, 2);
    });

    test('a missing node means no requirement', () async {
      final result = await run(checker(fetch: () async => null));
      expect(result.decision, UpdateDecision.none);
      expect(result.source, UpdateSource.network);
    });
  });

  group('ForcedUpdatePage', () {
    Widget host(Widget child) => MaterialApp(home: child);

    testWidgets('mandatory: Arabic copy, RTL, Update now works, no Later, no spinner', (tester) async {
      var updated = 0;
      await tester.pumpWidget(host(ForcedUpdatePage(
        appName: 'تاكسيستا',
        languageCode: 'ar',
        mandatory: true,
        onUpdate: () => updated++,
      )));

      expect(find.text('يتوفر تحديث جديد لـتاكسيستا'), findsOneWidget);
      expect(find.text('يجب تحديث التطبيق للاستمرار والاستفادة من آخر التحسينات.'), findsOneWidget);
      expect(find.text('تحديث الآن'), findsOneWidget);
      expect(find.byKey(const ValueKey('update_later')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(Directionality.of(tester.element(find.byKey(const ValueKey('update_title')))), TextDirection.rtl);

      await tester.tap(find.byKey(const ValueKey('update_now')));
      expect(updated, 1, reason: 'the button is not covered by anything');
    });

    testWidgets('mandatory: Back cannot dismiss it', (tester) async {
      await tester.pumpWidget(host(Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ForcedUpdatePage(
                  appName: 'تاكسيستا', languageCode: 'ar', mandatory: true, onUpdate: () {}),
            )),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('update_now')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('update_now')), findsOneWidget, reason: 'still there');
    });

    testWidgets('optional: shows Later and it calls back', (tester) async {
      var later = 0;
      await tester.pumpWidget(host(ForcedUpdatePage(
        appName: 'تاكسيستا',
        languageCode: 'ar',
        mandatory: false,
        onUpdate: () {},
        onLater: () => later++,
      )));

      expect(find.text('لاحقًا'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('update_later')));
      expect(later, 1);
    });

    testWidgets('English is left-to-right, a failed store open shows a hint, notes render', (tester) async {
      await tester.pumpWidget(host(ForcedUpdatePage(
        appName: 'Taxista',
        languageCode: 'en',
        mandatory: true,
        notes: 'Bug fixes',
        updateFailed: true,
        onUpdate: () {},
      )));

      expect(find.text('A new update is available for Taxista'), findsOneWidget);
      expect(Directionality.of(tester.element(find.byKey(const ValueKey('update_title')))), TextDirection.ltr);
      expect(find.byKey(const ValueKey('update_failed')), findsOneWidget);
      expect(find.text('Bug fixes'), findsOneWidget);
    });

    testWidgets('phone-width layout does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(ForcedUpdatePage(
        appName: 'تاكسيستا',
        languageCode: 'ar',
        mandatory: true,
        notes: 'ملاحظات الإصدار الطويلة ' * 8,
        updateFailed: true,
        onUpdate: () {},
      )));
      expect(tester.takeException(), isNull);
    });
  });

  test('the update language never depends on the app language being loaded', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(updateLanguage('en'), 'en');
    expect(updateLanguage('ar'), 'ar');
    expect(updateLanguage(''), anyOf('ar', 'en'));
  });
}
