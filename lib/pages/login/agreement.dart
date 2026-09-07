import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../loadingPage/loading.dart';
import '../referralcode/referral_code.dart';

class AggreementPage extends StatefulWidget {
  const AggreementPage({super.key});

  @override
  State<AggreementPage> createState() => _AggreementPageState();
}

class _AggreementPageState extends State<AggreementPage> {
  bool _accepted = false;
  bool _loading = false;
  String? _error;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  String _copy(String ar, String en) => _rtl ? ar : en;

  Future<void> _continue() async {
    if (!_accepted) {
      setState(() => _error = _copy('وافق على الشروط وسياسة الخصوصية للمتابعة.',
          'Accept the terms and privacy policy to continue.'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    valueNotifierLogin.incrementNotifier();
    final result = await registerUser();
    if (!mounted) return;

    if (result == 'true') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Referral()),
        (_) => false,
      );
      return;
    }

    setState(() {
      _loading = false;
      _error = result?.toString() ??
          _copy('تعذر إنشاء الحساب، حاول مرة أخرى.',
              'Could not create your account. Please try again.');
    });
    valueNotifierLogin.incrementNotifier();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(_copy('مراجعة الحساب', 'Review your account'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: Stack(children: [
          SafeArea(
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: Column(children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: theme.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified_user_rounded,
                          size: 39, color: theme),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _copy('أنت على بُعد خطوة واحدة', 'You are one step away'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _copy(
                          'نحافظ على بياناتك ونستخدمها فقط لتشغيل رحلاتك بأمان.',
                          'We protect your data and use it only to run your trips safely.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.55,
                        fontSize: 15,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const _TrustItem(
                      icon: Icons.lock_outline_rounded,
                      titleAr: 'حساب آمن',
                      titleEn: 'Secure account',
                      subtitleAr: 'بيانات الدخول مشفّرة ومحمية.',
                      subtitleEn:
                          'Your sign-in details are encrypted and protected.',
                    ),
                    const SizedBox(height: 12),
                    const _TrustItem(
                      icon: Icons.location_on_outlined,
                      titleAr: 'الموقع عند الحاجة فقط',
                      titleEn: 'Location only when needed',
                      subtitleAr: 'نستخدم موقعك لخدمة الرحلة وتحديد التغطية.',
                      subtitleEn: 'Used for trips and service availability.',
                    ),
                    const SizedBox(height: 20),
                    _ConsentCard(
                      accepted: _accepted,
                      enabled: !_loading,
                      onChanged: (value) => setState(() {
                        _accepted = value;
                        _error = null;
                      }),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                child: FilledButton.icon(
                  onPressed: _loading ? null : _continue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(_copy('إنشاء الحساب', 'Create account')),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme,
                    minimumSize: const Size.fromHeight(58),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ]),
          ),
          if (_loading)
            Loading(
              message: _copy('جارٍ إنشاء حسابك…', 'Creating your account…'),
              submessage: _copy('نؤمّن بياناتك ونجهّز تجربتك.',
                  'Securing your details and preparing your experience.'),
            ),
        ]),
      );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
  });
  final IconData icon;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: .1)),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: theme),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rtl ? titleAr : titleEn,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(rtl ? subtitleAr : subtitleEn,
                  style:
                      TextStyle(height: 1.35, color: Colors.blueGrey.shade600)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.accepted,
    required this.enabled,
    required this.onChanged,
  });
  final bool accepted;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: enabled ? () => onChanged(!accepted) : null,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accepted ? theme.withValues(alpha: .08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: accepted ? theme : Colors.blueGrey.withValues(alpha: .16),
              width: accepted ? 1.5 : 1),
        ),
        child: Row(children: [
          Checkbox(
            value: accepted,
            onChanged: enabled ? (value) => onChanged(value ?? false) : null,
            activeColor: theme,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                style:
                    DefaultTextStyle.of(context).style.copyWith(height: 1.55),
                children: [
                  TextSpan(text: rtl ? 'أوافق على ' : 'I agree to the '),
                  _link(rtl ? 'شروط الاستخدام' : 'Terms of Use',
                      'terms and conditions url'),
                  TextSpan(text: rtl ? ' و' : ' and '),
                  _link(rtl ? 'سياسة الخصوصية' : 'Privacy Policy',
                      'privacy policy url'),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  TextSpan _link(String text, String setting) => TextSpan(
        text: text,
        style: TextStyle(color: theme, fontWeight: FontWeight.w700),
        recognizer: TapGestureRecognizer()..onTap = () => openBrowser(setting),
      );
}
