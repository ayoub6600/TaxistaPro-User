import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../functions/functions.dart' as app;
import '../../../styles/styles.dart';
import 'auth_policy.dart';

class ModernForgotPassword extends StatefulWidget {
  const ModernForgotPassword({
    super.key,
    required this.policies,
    this.initialCountry,
  });

  final List<CountryAuthPolicy> policies;
  final CountryAuthPolicy? initialCountry;

  @override
  State<ModernForgotPassword> createState() => _ModernForgotPasswordState();
}

class _ModernForgotPasswordState extends State<ModernForgotPassword> {
  final _identity = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  CountryAuthPolicy? _country;
  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  String _copy(String ar, String en) => _rtl ? ar : en;
  SignupOtpChannel get _channel => _country?.channel ?? SignupOtpChannel.email;
  bool get _usesEmail => _channel == SignupOtpChannel.email;

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry ??
        (widget.policies.isEmpty ? null : widget.policies.first);
  }

  @override
  void dispose() {
    _identity.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    dynamic result;
    if (_step == 0) {
      result = _usesEmail
          ? await app.sendOTPtoEmail(_identity.text.trim())
          : await app.sendOTPtoMobile(
              _identity.text.trim(),
              _country!.dialCode,
              channel: _channel.name,
            );
    } else if (_step == 1) {
      result = _usesEmail
          ? await app.emailVerify(_identity.text.trim(), _otp.text.trim())
          : await app.validateSmsOtp(_identity.text.trim(), _otp.text.trim());
    } else {
      result = await app.updatePassword(
        _identity.text.trim(),
        _password.text,
        _usesEmail,
      );
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == 'success' || result == true) {
        if (_step == 2) {
          Navigator.of(context).pop(true);
        } else {
          _step++;
        }
      } else {
        _error = result?.toString() ??
            _copy('تعذر إكمال العملية. حاول مجددًا.',
                'Could not continue. Please try again.');
      }
    });
  }

  String? _validate() {
    if (_country == null) {
      return _copy('اختر الدولة أولًا.', 'Choose your country first.');
    }
    if (_step == 0) {
      final value = _identity.text.trim();
      if (_usesEmail &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        return _copy('أدخل بريدًا صحيحًا.', 'Enter a valid email address.');
      }
      final phoneLength = value.replaceAll(RegExp(r'\D'), '').length;
      if (!_usesEmail &&
          (phoneLength < _country!.minPhoneLength ||
              phoneLength > _country!.maxPhoneLength)) {
        return _copy('راجع رقم الهاتف.', 'Check your phone number.');
      }
    } else if (_step == 1 && _otp.text.trim().length != 6) {
      return _copy('أدخل الرمز المكوّن من 6 أرقام.',
          'Enter the 6-digit verification code.');
    } else if (_step == 2 && _password.text.length < 8) {
      return _copy('استخدم 8 أحرف على الأقل.', 'Use at least 8 characters.');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      0 => _copy('استعادة حسابك', 'Recover your account'),
      1 => _copy('أدخل رمز التحقق', 'Enter verification code'),
      _ => _copy('أنشئ كلمة مرور جديدة', 'Create a new password'),
    };
    final channelName = _usesEmail
        ? _copy('البريد الإلكتروني', 'email')
        : _copy('واتساب', 'WhatsApp');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.lock_reset_rounded, color: theme, size: 34),
              ),
              const SizedBox(height: 24),
              Text(title,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                _copy('سنرسل رمز الأمان عبر $channelName حسب إعدادات بلدك.',
                    'We will send the security code by $channelName based on your country settings.'),
                style: TextStyle(color: Colors.blueGrey.shade600, height: 1.45),
              ),
              const SizedBox(height: 24),
              if (_step == 0) ...[
                DropdownButtonFormField<CountryAuthPolicy>(
                  key: ValueKey(_country?.id),
                  initialValue: _country,
                  decoration: _decoration(
                      _copy('الدولة', 'Country'), Icons.public_rounded),
                  items: widget.policies
                      .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text('${country.name}  ${country.dialCode}')))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _country = value;
                    _identity.clear();
                    _error = null;
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _identity,
                  autofocus: true,
                  keyboardType: _usesEmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  inputFormatters: _usesEmail
                      ? null
                      : [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration(
                    _usesEmail
                        ? _copy('بريدك الإلكتروني', 'Email address')
                        : _copy('رقم الهاتف', 'Phone number'),
                    _usesEmail
                        ? Icons.alternate_email_rounded
                        : Icons.phone_rounded,
                  ).copyWith(
                      prefixText:
                          _usesEmail ? null : '${_country?.dialCode ?? ''}  '),
                ),
              ] else if (_step == 1)
                TextField(
                  controller: _otp,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: _decoration(
                      _copy('رمز التحقق', 'Verification code'),
                      Icons.verified_user_outlined),
                )
              else
                TextField(
                  controller: _password,
                  autofocus: true,
                  obscureText: _obscure,
                  decoration: _decoration(
                          _copy('كلمة المرور الجديدة', 'New password'),
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
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade800)),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _loading ? null : _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: theme,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _loading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_step == 2
                        ? _copy('حفظ كلمة المرور', 'Save password')
                        : _copy('متابعة', 'Continue')),
              ),
            ],
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      );
}
