import 'package:flutter/material.dart';

import '../../../functions/functions.dart';
import '../../../styles/styles.dart';
import '../../onTripPage/invoice.dart';
import '../../onTripPage/map_page.dart';
import '../login.dart' show LegacyLogin;
import 'modern_signup.dart';

class ModernLogin extends StatefulWidget {
  const ModernLogin({super.key});

  @override
  State<ModernLogin> createState() => _ModernLoginState();
}

class _ModernLoginState extends State<ModernLogin> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _loading = true;
  bool _obscure = true;
  String? _error;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  String _copy(String ar, String en) => _rtl ? ar : en;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await getCountryCode();
    await getemailmodule();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final identity = _identity.text.trim();
    if (identity.isEmpty || _password.text.isEmpty) {
      setState(() => _error =
          _copy('أدخل بيانات تسجيل الدخول.', 'Enter your login details.'));
      return;
    }
    final isEmail = identity.contains('@');
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await verifyUser(
        identity, isEmail ? 1 : 0, _password.text, '', false, false);
    if (!mounted) return;
    if (result == true) {
      final destination =
          userRequestData.isNotEmpty && userRequestData['is_completed'] == 1
              ? const Invoice()
              : const Maps();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
      return;
    }
    setState(() {
      _loading = false;
      _error = result == false
          ? _copy('لا يوجد حساب بهذه البيانات.',
              'We could not find an account with these details.')
          : result.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                        color: theme, borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.local_taxi_rounded,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 30),
                  Text(_copy('مرحبًا بعودتك', 'Welcome back'),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                  const SizedBox(height: 10),
                  Text(
                      _copy('أدخل بريدك أو رقم هاتفك، وسنتعرف عليه تلقائيًا.',
                          'Use your email or phone number. We will detect it automatically.'),
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.blueGrey.shade600)),
                  const SizedBox(height: 34),
                  _AuthField(
                      controller: _identity,
                      hint: _copy('البريد أو رقم الهاتف', 'Email or phone'),
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.person_outline_rounded),
                  const SizedBox(height: 14),
                  _AuthField(
                      controller: _password,
                      hint: _copy('كلمة المرور', 'Password'),
                      obscureText: _obscure,
                      icon: Icons.lock_outline_rounded,
                      onSubmitted: (_) => _login(),
                      suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined))),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const LegacyLogin())),
                      child:
                          Text(_copy('نسيت كلمة المرور؟', 'Forgot password?')),
                    ),
                  ),
                  if (_error != null) ...[
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14)),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade800))),
                    const SizedBox(height: 14),
                  ],
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                        backgroundColor: theme,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_copy('تسجيل الدخول', 'Sign in'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ModernSignup())),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: theme,
                        minimumSize: const Size.fromHeight(56),
                        side: BorderSide(color: theme.withValues(alpha: .28)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    child: Text(_copy('إنشاء حساب جديد', 'Create an account'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField(
      {required this.controller,
      required this.hint,
      required this.icon,
      this.keyboardType,
      this.obscureText = false,
      this.suffix,
      this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        textInputAction:
            obscureText ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.blueGrey.withValues(alpha: .12))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme, width: 1.5)),
        ),
      );
}
