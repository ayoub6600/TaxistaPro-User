import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/login/auth/auth_policy.dart';
import 'package:taxista/pages/login/auth/phone_country_picker.dart';

CountryAuthPolicy c(int i, String name, String dial) => CountryAuthPolicy(index: i, id: i, name: name, code: name, dialCode: dial, minPhoneLength: 9, maxPhoneLength: 10, channel: SignupOtpChannel.whatsapp, areas: const []);

void main() {
  final all = [c(0, 'مصر', '+20'), c(1, 'ليبيا', '+218'), c(2, 'بدون رمز', '')];

  test('only countries with a dial code can be picked for the phone', () {
    expect(phoneCountries(all).map((x) => x.dialCode), ['+20', '+218']);
  });

  testWidgets('a rider in Egypt can switch the phone code to Libya', (tester) async {
    CountryAuthPolicy? picked;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
          body: PhoneCountryButton(country: all[0], onTap: () async => picked = await pickPhoneCountry(context, all, all[0], rtl: true)),
        ))));
    expect(find.text('⁦+20⁩'), findsOneWidget);
    await tester.tap(find.byType(PhoneCountryButton));
    await tester.pumpAndSettle();
    expect(find.text('بدون رمز'), findsNothing);
    await tester.tap(find.text('ليبيا'));
    await tester.pumpAndSettle();
    expect(picked?.dialCode, '+218');
  });
}
