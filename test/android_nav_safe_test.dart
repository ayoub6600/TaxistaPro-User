import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/widgets/android_nav_safe.dart';

Widget host(double bottom) => MediaQuery(
      data: MediaQueryData(size: const Size(400, 800), padding: EdgeInsets.only(bottom: bottom), viewPadding: EdgeInsets.only(bottom: bottom)),
      child: const Directionality(textDirection: TextDirection.rtl, child: AndroidNavSafe(child: Align(alignment: Alignment.bottomCenter, child: SizedBox(key: Key('button'), height: 50, width: 100)))),
    );

void main() {
  testWidgets('on Android the bottom button sits above the phone buttons', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(host(48));
    expect(tester.getBottomLeft(find.byKey(const Key('button'))).dy, 800 - 48);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iPhone keeps its own layout', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(host(34));
    expect(tester.getBottomLeft(find.byKey(const Key('button'))).dy, 800);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a page that takes the whole screen height still ends above the phone buttons', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(400, 800), padding: EdgeInsets.only(bottom: 48), viewPadding: EdgeInsets.only(bottom: 48)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AndroidNavSafe(
          child: Builder(builder: (context) => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(key: const Key('page'), height: MediaQuery.of(context).size.height, width: 100),
              )),
        ),
      ),
    ));
    expect(tester.getBottomLeft(find.byKey(const Key('page'))).dy, 800 - 48);
    debugDefaultTargetPlatformOverride = null;
  });
}
