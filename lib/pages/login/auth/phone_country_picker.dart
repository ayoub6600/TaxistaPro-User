import 'package:flutter/material.dart';

import 'auth_policy.dart';

/// The phone's country is its own choice: a Libyan number can sign up for rides in Cairo.
List<CountryAuthPolicy> phoneCountries(List<CountryAuthPolicy> all) => [for (final c in all) if (c.dialCode.trim().isNotEmpty) c];

/// The tappable «+218 ▾» at the start of the phone field.
class PhoneCountryButton extends StatelessWidget {
  const PhoneCountryButton({super.key, required this.country, required this.onTap});

  final CountryAuthPolicy? country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('⁦${country?.dialCode ?? ''}⁩', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
            Container(width: 1, height: 26, margin: const EdgeInsetsDirectional.only(start: 6), color: Colors.blueGrey.withValues(alpha: .25)),
          ]),
        ),
      );
}

Future<CountryAuthPolicy?> pickPhoneCountry(BuildContext context, List<CountryAuthPolicy> all, CountryAuthPolicy? current, {required bool rtl}) =>
    showModalBottomSheet<CountryAuthPolicy>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * .7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(rtl ? 'رمز دولة رقم الهاتف' : 'Phone country code', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              Flexible(
                child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 12), children: [
                  for (final c in phoneCountries(all))
                    ListTile(
                      title: Text(c.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('⁦${c.dialCode}⁩', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        if (c.index == current?.index) const Padding(padding: EdgeInsetsDirectional.only(start: 8), child: Icon(Icons.check_circle_rounded, color: Color(0xFF0873FF))),
                      ]),
                      onTap: () => Navigator.pop(sheet, c),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
