import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../functions/functions.dart' as app;
import '../../../styles/styles.dart';
import '../../onTripPage/invoice.dart';
import '../../onTripPage/map_page.dart';
import 'auth_policy.dart';
import 'modern_forgot_password.dart';
import 'modern_signup.dart';
import 'signup_location_resolver.dart';

enum _LoginMethod { email, phone }

class ModernLogin extends StatefulWidget {
  const ModernLogin({super.key});

  @override
  State<ModernLogin> createState() => _ModernLoginState();
}

class _ModernLoginState extends State<ModernLogin> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  List<CountryAuthPolicy> _policies = const [];
  CountryAuthPolicy? _country;
  _LoginMethod _method = _LoginMethod.email;
  bool _loading = true;
  bool _detectingLocation = true;
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
    await app.getCountryCode();
    await app.getemailmodule();
    final policies = List.generate(app.countries.length, (index) {
      return CountryAuthPolicy.fromApi(
        index,
        Map<String, dynamic>.from(app.countries[index] as Map),
      );
    });
    CountryAuthPolicy? detected;
    if (policies.isNotEmpty) {
      try {
        detected = (await detectSignupLocation(
          baseUrl: app.url,
          policies: policies,
        ))
            ?.country;
      } catch (_) {
        detected = null;
      }
    }
    if (!mounted) return;
    final selected = detected ?? (policies.isEmpty ? null : policies.first);
    setState(() {
      _policies = policies;
      _country = selected;
      _method = selected?.channel == SignupOtpChannel.email
          ? _LoginMethod.email
          : _LoginMethod.phone;
      _detectingLocation = false;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final identity = _normalizedIdentity(_identity.text);
    final validation = _validate(identity);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final isEmail = _method == _LoginMethod.email;
    final loginResult = await app.userLogin(
      identity,
      isEmail ? 1 : 0,
      _password.text,
      false,
    );
    final result =
        loginResult == true ? await app.getUserDetails() : loginResult;
    if (!mounted) return;
    if (result == true) {
      final destination = app.userRequestData.isNotEmpty &&
              app.userRequestData['is_completed'] == 1
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
          ? _copy('بيانات الدخول غير صحيحة. راجع الحساب وكلمة المرور.',
              'The login details are incorrect. Check your account and password.')
          : result.toString();
    });
  }

  String? _validate(String identity) {
    if (_country == null) {
      return _copy('تعذر تحديد الدولة. اخترها للمتابعة.',
          'Choose your country to continue.');
    }
    if (_method == _LoginMethod.email) {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(identity)) {
        return _copy(
            'أدخل بريدًا إلكترونيًا صحيحًا.', 'Enter a valid email address.');
      }
    } else {
      final phoneLength = identity.replaceAll(RegExp(r'\D'), '').length;
      if (phoneLength < _country!.minPhoneLength ||
          phoneLength > _country!.maxPhoneLength) {
        return _copy('راجع رقم الهاتف.', 'Check your phone number.');
      }
    }
    if (_password.text.length < 8) {
      return _copy('أدخل كلمة المرور الصحيحة.', 'Enter your password.');
    }
    return null;
  }

  String _normalizedIdentity(String input) {
    final value = input.trim();
    if (_method == _LoginMethod.email || _country == null) return value;

    var digits = value.replaceAll(RegExp(r'\D'), '');
    final dialDigits = _country!.dialCode.replaceAll(RegExp(r'\D'), '');
    if (dialDigits.isNotEmpty &&
        digits.startsWith(dialDigits) &&
        digits.length > _country!.maxPhoneLength) {
      digits = digits.substring(dialDigits.length);
    }
    return digits;
  }

  void _changeMethod(_LoginMethod method) {
    setState(() {
      _method = method;
      _identity.clear();
      _error = null;
    });
  }

  Future<void> _forgotPassword() async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ModernForgotPassword(
        policies: _policies,
        initialCountry: _country,
      ),
    ));
    if (changed == true && mounted) {
      setState(() {
        _password.clear();
        _error = _copy('تم تحديث كلمة المرور. سجّل الدخول الآن.',
            'Password updated. You can sign in now.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = _method == _LoginMethod.email;
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
                  const SizedBox(height: 26),
                  Text(_copy('مرحبًا بعودتك', 'Welcome back'),
                      style: const TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          height: 1.15)),
                  const SizedBox(height: 8),
                  Text(
                    _detectingLocation
                        ? _copy('نحدد دولتك لضبط الدخول بأمان…',
                            'Detecting your country for a secure sign-in…')
                        : _copy('اختر طريقة الدخول المناسبة لك.',
                            'Choose the sign-in method that suits you.'),
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.blueGrey.shade600),
                  ),
                  const SizedBox(height: 22),
                  if (_policies.isNotEmpty)
                    DropdownButtonFormField<CountryAuthPolicy>(
                      key: ValueKey(_country?.id),
                      initialValue: _country,
                      decoration: _decoration(
                          _copy('الدولة', 'Country'), Icons.public_rounded),
                      items: _policies
                          .map((country) => DropdownMenuItem(
                              value: country,
                              child:
                                  Text('${country.name}  ${country.dialCode}')))
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (country) => setState(() {
                                _country = country;
                                _method =
                                    country?.channel == SignupOtpChannel.email
                                        ? _LoginMethod.email
                                        : _LoginMethod.phone;
                                _identity.clear();
                                _error = null;
                              }),
                    ),
                  const SizedBox(height: 14),
                  SegmentedButton<_LoginMethod>(
                    segments: [
                      ButtonSegment(
                          value: _LoginMethod.email,
                          icon: const Icon(Icons.alternate_email_rounded),
                          label: Text(_copy('البريد', 'Email'))),
                      ButtonSegment(
                          value: _LoginMethod.phone,
                          icon: const Icon(Icons.phone_rounded),
                          label: Text(_copy('الهاتف', 'Phone'))),
                    ],
                    selected: {_method},
                    onSelectionChanged: _loading
                        ? null
                        : (selection) => _changeMethod(selection.first),
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _identity,
                    keyboardType: isEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    inputFormatters: isEmail
                        ? null
                        : [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      isEmail
                          ? _copy('البريد الإلكتروني', 'Email address')
                          : _copy('رقم الهاتف', 'Phone number'),
                      isEmail
                          ? Icons.person_outline_rounded
                          : Icons.phone_rounded,
                    ).copyWith(
                        prefixText:
                            isEmail ? null : '${_country?.dialCode ?? ''}  '),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    textInputAction: TextInputAction.done,
                    decoration: _decoration(_copy('كلمة المرور', 'Password'),
                            Icons.lock_outline_rounded)
                        .copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _loading ? null : _forgotPassword,
                      child:
                          Text(_copy('نسيت كلمة المرور؟', 'Forgot password?')),
                    ),
                  ),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _error!.startsWith('تم')
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14)),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _error!.startsWith('تم')
                                  ? Colors.green.shade800
                                  : Colors.red.shade800)),
                    ),
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
                  const SizedBox(height: 14),
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

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: .12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme, width: 1.5),
        ),
      );
}
