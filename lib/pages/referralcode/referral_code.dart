import 'package:flutter/material.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../loadingPage/loading.dart';
import '../onTripPage/map_page.dart';

class Referral extends StatefulWidget {
  const Referral({super.key});

  @override
  State<Referral> createState() => _ReferralState();
}

dynamic referralCode;
final TextEditingController referalController = TextEditingController();

class _ReferralState extends State<Referral> {
  bool _loading = false;
  String? _error;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  String _copy(String ar, String en) => _rtl ? ar : en;

  @override
  void initState() {
    super.initState();
    referralCode = '';
    referalController.clear();
  }

  void _openHome() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const Maps()));
  }

  Future<void> _apply() async {
    final code = referalController.text.trim();
    if (code.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await updateReferral();
    if (!mounted) return;
    if (result == 'true') {
      _openHome();
    } else {
      setState(() {
        _loading = false;
        _error = _copy('رمز الإحالة غير صحيح أو انتهت صلاحيته.',
            'This referral code is invalid or expired.');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: _loading ? null : _openHome,
              label: Text(_copy('تخطي', 'Skip')),
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Stack(children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: theme.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.card_giftcard_rounded,
                        color: theme, size: 42),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _copy('هل دعاك صديق؟', 'Invited by a friend?'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _copy(
                        'أدخل رمز الإحالة للاستفادة من المكافأة. يمكنك تخطي هذه الخطوة.',
                        'Enter the referral code to claim your reward, or skip this step.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.55,
                      fontSize: 15,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 34),
                  TextField(
                    controller: referalController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _apply(),
                    decoration: InputDecoration(
                      hintText: _copy('مثال: TAXISTA24', 'Example: TAXISTA24'),
                      prefixIcon:
                          const Icon(Icons.confirmation_number_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 19),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                            color: Colors.blueGrey.withValues(alpha: .13)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: theme, width: 1.5),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 20),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: referalController,
                    builder: (_, value, __) => FilledButton(
                      onPressed:
                          value.text.trim().isEmpty || _loading ? null : _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme,
                        minimumSize: const Size.fromHeight(58),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(_copy('استخدام الرمز', 'Apply code'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _loading ? null : _openHome,
                    child: Text(_copy('ليس لدي رمز، ابدأ الآن',
                        'I do not have a code, start now')),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Loading(
              message: _copy('جارٍ تطبيق الرمز…', 'Applying your code…'),
              submessage: _copy('نتحقق من المكافأة لحسابك.',
                  'Checking the reward for your account.'),
            ),
        ]),
      );
}
