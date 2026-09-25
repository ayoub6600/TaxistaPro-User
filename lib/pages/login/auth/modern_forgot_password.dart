import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../functions/functions.dart' as app;
import '../../../functions/rider_password_reset.dart';
import '../../../styles/styles.dart';
import 'auth_policy.dart';

enum _Step { phone, code, password }

/// Rider forgot-password: phone (+ country) -> verification code -> new
/// password + confirmation, then back to the normal phone/email + password
/// sign-in (no session is issued by the reset).
///
/// This is the only place a rider uses an OTP to recover access; there is no
/// "sign in with OTP". It talks only to `/api/v1/password/rider/*` on our own
/// backend, and the reset token from the code step lives in this State object
/// and nowhere else - it is never persisted, shown or logged. The selected
/// country's dial code (+218 Libya, +20 Egypt, ...) travels with every request
/// so the backend resolves the right account.
///
/// Pops with `true` once the password was changed.
class ModernForgotPassword extends StatefulWidget {
  const ModernForgotPassword({
    super.key,
    required this.policies,
    this.initialCountry,
    this.api,
    this.resendCooldown = const Duration(seconds: 60),
  });

  final List<CountryAuthPolicy> policies;
  final CountryAuthPolicy? initialCountry;

  /// Injectable for tests; production builds the client against `app.url`.
  final RiderPasswordResetApi? api;

  /// Client-side mirror of the backend's per-phone resend cooldown.
  final Duration resendCooldown;

  @override
  State<ModernForgotPassword> createState() => _ModernForgotPasswordState();
}

class _ModernForgotPasswordState extends State<ModernForgotPassword> {
  static const _minPasswordLength = 8;

  late final RiderPasswordResetApi _api;
  late final bool _ownsApi;

  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  CountryAuthPolicy? _country;
  _Step _step = _Step.phone;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _notice;

  // Held in memory for the duration of this screen only.
  String? _resetToken;

  Timer? _timer;
  int _cooldown = 0;
  String? _lastSentKey;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  String _copy(String ar, String en) => _rtl ? ar : en;

  String get _dialCode => normalizeDialCode(_country?.dialCode ?? '');
  String get _phoneKey => '$_dialCode|${localDigits(_phone.text)}';
  String get _displayPhone => '$_dialCode ${localDigits(_phone.text)}';

  @override
  void initState() {
    super.initState();
    _ownsApi = widget.api == null;
    _api = widget.api ?? RiderPasswordResetApi(baseUrl: app.url);
    _country = widget.initialCountry ??
        (widget.policies.isEmpty ? null : widget.policies.first);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resetToken = null;
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    if (_ownsApi) _api.close();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  void _startCooldown() {
    _timer?.cancel();
    _cooldown = widget.resendCooldown.inSeconds;
    if (_cooldown <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) {
          _cooldown = 0;
          timer.cancel();
        }
      });
    });
  }

  void _stopCooldown() {
    _timer?.cancel();
    _timer = null;
    _cooldown = 0;
  }

  String _failureMessage(RiderResetResult result) {
    if (result.message != null) return result.message!;
    switch (result.failure) {
      case RiderResetFailure.network:
        return _copy('تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجددًا.',
            'Could not reach the server. Check your connection and try again.');
      case RiderResetFailure.rateLimited:
        return _copy('محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.',
            'Too many attempts. Please wait a moment and try again.');
      case RiderResetFailure.resetTokenInvalid:
        return _tokenExpiredMessage;
      case RiderResetFailure.validation:
      case RiderResetFailure.server:
      case null:
        return _copy('تعذر إكمال العملية. حاول مجددًا.',
            'Could not continue. Please try again.');
    }
  }

  String get _tokenExpiredMessage => _copy(
      'انتهت صلاحية جلسة الاستعادة أو استُخدمت مسبقًا. اطلب رمزًا جديدًا للمتابعة.',
      'Your reset session expired or was already used. Request a new code to continue.');

  // ------------------------------------------------------------- validation

  String? _validate() {
    switch (_step) {
      case _Step.phone:
        final country = _country;
        if (country == null || _dialCode.isEmpty) {
          return _copy('اختر الدولة أولًا.', 'Choose your country first.');
        }
        final digits =
            localDigits(_phone.text).replaceFirst(RegExp(r'^0+'), '');
        if (digits.length < country.minPhoneLength ||
            digits.length > country.maxPhoneLength) {
          return _copy('راجع رقم الهاتف.', 'Check your phone number.');
        }
        return null;
      case _Step.code:
        return _otp.text.trim().length == 6
            ? null
            : _copy('أدخل الرمز المكوّن من 6 أرقام.',
                'Enter the 6-digit verification code.');
      case _Step.password:
        if (_password.text.length < _minPasswordLength) {
          return _copy(
              'استخدم 8 أحرف على الأقل.', 'Use at least 8 characters.');
        }
        if (_password.text != _confirm.text) {
          return _copy(
              'كلمتا المرور غير متطابقتين.', 'The passwords do not match.');
        }
        return null;
    }
  }

  // ---------------------------------------------------------------- actions

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final problem = _validate();
    if (problem != null) {
      setState(() {
        _error = problem;
        _notice = null;
      });
      return;
    }
    switch (_step) {
      case _Step.phone:
        await _sendCode();
      case _Step.code:
        await _verifyCode();
      case _Step.password:
        await _resetPassword();
    }
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (_loading) return;
    // Same number, still inside the resend window: the code is already on its
    // way, so go straight to the code step instead of tripping the backend's
    // cooldown with a request that cannot succeed.
    if (!resend && _cooldown > 0 && _lastSentKey == _phoneKey) {
      setState(() {
        _error = null;
        _notice = null;
        _step = _Step.code;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    final result = await _api.sendOtp(country: _dialCode, mobile: _phone.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _lastSentKey = _phoneKey;
        _startCooldown();
        _otp.clear();
        _step = _Step.code;
        if (resend) {
          _notice = _copy('تم إرسال رمز جديد.', 'A new code has been sent.');
        }
      } else {
        _error = _failureMessage(result);
        // A refused resend restarts the local countdown so the rider is not
        // invited to hammer the button; the backend decides when it is safe.
        if (resend && result.failure == RiderResetFailure.rateLimited) {
          _startCooldown();
        }
      }
    });
  }

  Future<void> _verifyCode() async {
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    final result = await _api.verifyOtp(
      country: _dialCode,
      mobile: _phone.text,
      otp: _otp.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _resetToken = result.data;
        _otp.clear();
        _stopCooldown();
        _step = _Step.password;
      } else {
        _error = _failureMessage(result);
      }
    });
  }

  Future<void> _resetPassword() async {
    final token = _resetToken;
    if (token == null) {
      // Cannot happen through the UI, but never send a reset without a token.
      setState(() {
        _step = _Step.phone;
        _error = _tokenExpiredMessage;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    final result = await _api.reset(
      country: _dialCode,
      mobile: _phone.text,
      resetToken: token,
      password: _password.text,
      passwordConfirmation: _confirm.text,
    );
    if (!mounted) return;
    if (result.ok) {
      _resetToken = null;
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _loading = false;
      if (result.failure == RiderResetFailure.resetTokenInvalid) {
        // Expired or already used: the only way forward is a fresh code.
        _resetToken = null;
        _lastSentKey = null;
        _password.clear();
        _confirm.clear();
        _step = _Step.phone;
      }
      _error = _failureMessage(result);
    });
  }

  void _back() {
    if (_loading) return;
    switch (_step) {
      case _Step.phone:
        Navigator.of(context).pop();
      case _Step.code:
        setState(() {
          _step = _Step.phone;
          _error = null;
          _notice = null;
        });
      case _Step.password:
        // The code was already spent on the token, so there is no code step to
        // return to - drop the token and start over from the phone.
        setState(() {
          _resetToken = null;
          _lastSentKey = null;
          _password.clear();
          _confirm.clear();
          _step = _Step.phone;
          _error = null;
          _notice = null;
        });
    }
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _Step.phone => _copy('استعادة حسابك', 'Recover your account'),
      _Step.code => _copy('أدخل رمز التحقق', 'Enter verification code'),
      _Step.password => _copy('أنشئ كلمة مرور جديدة', 'Create a new password'),
    };
    final subtitle = switch (_step) {
      _Step.phone => _copy('أدخل رقم الهاتف المرتبط بحسابك وسنرسل لك رمز تحقق.',
          'Enter the phone number linked to your account and we will send you a verification code.'),
      _Step.code => _copy('أرسلنا رمزًا مكوّنًا من 6 أرقام إلى {phone} عبر واتساب.',
              'We sent a 6-digit code to {phone} on WhatsApp.')
          .replaceAll('{phone}', '⁦$_displayPhone⁩'),
      _Step.password => _copy('اختر كلمة مرور جديدة. استخدم 8 أحرف على الأقل.',
          'Choose a new password. Use at least 8 characters.'),
    };

    return PopScope(
      canPop: _step == _Step.phone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  subtitle,
                  style:
                      TextStyle(color: Colors.blueGrey.shade600, height: 1.45),
                ),
                const SizedBox(height: 24),
                _stepBody(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _banner(_error!, isError: true),
                ] else if (_notice != null) ...[
                  const SizedBox(height: 14),
                  _banner(_notice!, isError: false),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _loading ? null : _submit,
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
                      : Text(switch (_step) {
                          _Step.phone => _copy('متابعة', 'Continue'),
                          _Step.code => _copy('تحقق من الرمز', 'Verify code'),
                          _Step.password =>
                            _copy('حفظ كلمة المرور', 'Save password'),
                        }),
                ),
                if (_step == _Step.code) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: (_loading || _cooldown > 0)
                        ? null
                        : () => _sendCode(resend: true),
                    child: Text(_cooldown > 0
                        ? _copy('إعادة إرسال الرمز خلال {seconds} ثانية',
                                'Resend code in {seconds}s')
                            .replaceAll('{seconds}', '$_cooldown')
                        : _copy('إعادة إرسال الرمز', 'Resend code')),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _back,
                    child:
                        Text(_copy('تغيير رقم الهاتف', 'Change phone number')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case _Step.phone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<CountryAuthPolicy>(
              key: ValueKey(_country?.id),
              initialValue: _country,
              isExpanded: true,
              decoration:
                  _decoration(_copy('الدولة', 'Country'), Icons.public_rounded),
              items: widget.policies
                  .map((country) => DropdownMenuItem(
                      value: country,
                      child: Text('${country.name}  ${country.dialCode}',
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                        _country = value;
                        _error = null;
                      }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              autofocus: true,
              enabled: !_loading,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
              decoration: _decoration(
                      _copy('رقم الهاتف', 'Phone number'), Icons.phone_rounded)
                  .copyWith(prefixText: '\u2066$_dialCode\u2069  '),
            ),
          ],
        );
      case _Step.code:
        return TextField(
          controller: _otp,
          autofocus: true,
          enabled: !_loading,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _submit(),
          style: const TextStyle(fontSize: 22, letterSpacing: 10),
          decoration: _decoration(_copy('رمز التحقق', 'Verification code'),
              Icons.verified_user_outlined),
        );
      case _Step.password:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _password,
              autofocus: true,
              enabled: !_loading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                _copy('كلمة المرور الجديدة', 'New password'),
                Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              enabled: !_loading,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: _decoration(
                _copy('تأكيد كلمة المرور', 'Confirm password'),
                Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _banner(String message, {required bool isError}) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isError ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isError ? Colors.red.shade800 : Colors.green.shade800)),
      );

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
