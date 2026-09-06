import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/utils/version.dart';

void main() {
  group('isVersionOutdated', () {
    test('detects newer major, minor, and patch versions', () {
      expect(isVersionOutdated('6.1.6', '7.0.0'), isTrue);
      expect(isVersionOutdated('6.1.6', '6.2.0'), isTrue);
      expect(isVersionOutdated('6.1.6', '6.1.7'), isTrue);
    });

    test('treats equal and older versions as current', () {
      expect(isVersionOutdated('6.1.6', '6.1.6'), isFalse);
      expect(isVersionOutdated('6.2.0', '6.1.9'), isFalse);
    });

    test('handles missing segments and build metadata', () {
      expect(isVersionOutdated('6.1', '6.1.1'), isTrue);
      expect(isVersionOutdated('6.1.6+33', '6.1.6+34'), isFalse);
    });
  });
}
