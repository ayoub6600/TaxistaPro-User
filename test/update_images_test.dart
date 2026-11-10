import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/update/forced_update_page.dart';
import 'package:taxista/update/update_images.dart';
import 'package:taxista/update/update_policy.dart';

/// «صور التحديث»: up to three images from the update node, a carousel in place of the icon, and
/// nothing changes for a node without images (what older servers and apps send).
void main() {
  test('the node images are read, at most three, only real links', () {
    final p = UpdatePolicy.fromMap({
      'release_notes': 'x',
      'images': [
        {'url': 'https://taxista.aljidartech.com/storage/app-release-images/a.jpg', 'caption': 'اشحن بـ LYPay'},
        {'url': 'javascript:alert(1)'},
        'junk',
        {'url': 'https://t/b.jpg'},
        {'url': 'https://t/c.jpg'},
        {'url': 'https://t/d.jpg'},
      ],
    });
    expect(p.images.map((i) => i.url), ['https://taxista.aljidartech.com/storage/app-release-images/a.jpg', 'https://t/b.jpg', 'https://t/c.jpg']);
    expect(p.images.first.caption, 'اشحن بـ LYPay');
    expect(UpdatePolicy.fromMap(p.toJson()).images.length, 3, reason: 'survives the cache');
    expect(UpdatePolicy.fromMap({'release_notes': 'x'}).images, isEmpty);
  });

  Widget page(List<UpdateImage> images) => MaterialApp(
        home: ForcedUpdatePage(appName: 'تاكسيستا', languageCode: 'ar', mandatory: true, onUpdate: () {}, images: images),
      );

  testWidgets('with images the carousel takes the icon place, with dots and the caption', (tester) async {
    await tester.pumpWidget(page(const [UpdateImage(url: 'https://t/a.jpg', caption: 'اشحن بـ LYPay'), UpdateImage(url: 'https://t/b.jpg', caption: 'صفحة الموقع')]));
    await tester.pump();
    expect(find.byKey(const ValueKey('update_images')), findsOneWidget);
    expect(find.byIcon(Icons.system_update_rounded), findsNothing);
    expect(find.byKey(const ValueKey('update_now')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('without images the page is exactly as before', (tester) async {
    await tester.pumpWidget(page(const []));
    expect(find.byKey(const ValueKey('update_images')), findsNothing);
    expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
  });
}
