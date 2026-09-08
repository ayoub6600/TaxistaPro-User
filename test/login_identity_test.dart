import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/login/auth/login_identity.dart';

void main() {
  group('normalizePhoneIdentity', () {
    test('keeps an Egyptian local number unchanged', () {
      expect(
        normalizePhoneIdentity(
          input: '1030855688',
          dialCode: '+20',
          maxLocalLength: 10,
        ),
        '1030855688',
      );
    });

    test('removes the Egyptian dial code when it was typed in the field', () {
      expect(
        normalizePhoneIdentity(
          input: '+20 103 085 5688',
          dialCode: '+20',
          maxLocalLength: 10,
        ),
        '1030855688',
      );
    });

    test('removes formatting without stripping a valid local prefix', () {
      expect(
        normalizePhoneIdentity(
          input: '091-234-5678',
          dialCode: '+218',
          maxLocalLength: 10,
        ),
        '0912345678',
      );
    });
  });
}
