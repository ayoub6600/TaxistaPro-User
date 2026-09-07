import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../functions/functions.dart' as app;
import '../../../styles/styles.dart';
import '../agreement.dart';
import 'auth_policy.dart';

class ModernSignup extends StatefulWidget {
  const ModernSignup({super.key});

  @override
  State<ModernSignup> createState() => _ModernSignupState();
}

class _ModernSignupState extends State<ModernSignup> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  SignupField _step = SignupField.name;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String _gender = '';
  CountryAuthPolicy? _country;
  late final List<CountryAuthPolicy> _policies;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _policies = List.generate(app.countries.length, (index) {
      return CountryAuthPolicy.fromApi(
        index,
        Map<String, dynamic>.from(app.countries[index] as Map),
      );
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String _copy(String ar, String en) => _rtl ? ar : en;

  List<SignupField> get _flow {
    final policy = _country;
    if (policy == null) return SignupField.values;
    return signupFlowFor(policy, hasEmail: _email.text.trim().isNotEmpty);
  }

  int get _stepIndex => _flow.indexOf(_step);

  SignupOtpChannel get _channel =>
      _country!.channelFor(hasEmail: _email.text.trim().isNotEmpty);

  void _advance() {
    final flow = _flow;
    final index = flow.indexOf(_step);
    if (index >= 0 && index < flow.length - 1) {
      setState(() {
        _step = flow[index + 1];
        _error = null;
      });
    }
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = _validate());
    if (_error != null) return;

    if (_step == SignupField.password && _channel == SignupOtpChannel.email) {
      await _sendOtp();
      return;
    }
    if (_step == SignupField.phone && _channel != SignupOtpChannel.email) {
      await _sendOtp();
      return;
    }
    if (_step == SignupField.otp) {
      await _verifyOtp();
      return;
    }
    if (_step == SignupField.gender) {
      _finish();
      return;
    }
    _advance();
  }

  String? _validate() {
    switch (_step) {
      case SignupField.name:
        return _name.text.trim().length < 2
            ? _copy('اكتب اسمك كما تحب أن يظهر.',
                'Enter the name you want us to use.')
            : null;
      case SignupField.country:
        return _country == null
            ? _copy('اختر الدولة.', 'Choose your country.')
            : null;
      case SignupField.email:
        final value = _email.text.trim();
        if (value.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
          return _copy(
              'البريد الإلكتروني غير صحيح.', 'Enter a valid email address.');
        }
        if ((_country?.emailOptional == false) && value.isEmpty) {
          return _copy('البريد مطلوب لهذه الدولة.',
              'Email is required for this country.');
        }
        return null;
      case SignupField.password:
        return _password.text.length < 8
            ? _copy('استخدم 8 أحرف على الأقل.', 'Use at least 8 characters.')
            : null;
      case SignupField.phone:
        final length = _phone.text.replaceAll(RegExp(r'\D'), '').length;
        return length < _country!.minPhoneLength ||
                length > _country!.maxPhoneLength
            ? _copy('راجع رقم الهاتف.', 'Check your phone number.')
            : null;
      case SignupField.otp:
        return _otp.text.trim().length != 6
            ? _copy('أدخل رمز التحقق المكوّن من 6 أرقام.',
                'Enter the 6-digit verification code.')
            : null;
      case SignupField.gender:
        return _gender.isEmpty
            ? _copy('اختر الجنس للمتابعة.', 'Choose a gender to continue.')
            : null;
    }
  }

  Future<void> _sendOtp() async {
    final policy = _country!;
    final channel = _channel;
    setState(() => _loading = true);
    dynamic result;
    if (channel == SignupOtpChannel.email) {
      result = await app.sendOTPtoEmail(_email.text.trim());
    } else {
      result = await app.sendOTPtoMobile(
        _phone.text.trim(),
        policy.dialCode,
        channel: channel.name,
      );
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == 'success') {
        final flow = _flow;
        _step = flow[flow.indexOf(_step) + 1];
        _error = null;
      } else {
        _error = result?.toString() ??
            _copy('تعذر إرسال الرمز.', 'Could not send the code.');
      }
    });
  }

  Future<void> _verifyOtp() async {
    final channel = _channel;
    setState(() => _loading = true);
    final result = channel == SignupOtpChannel.email
        ? await app.emailVerify(_email.text.trim(), _otp.text.trim())
        : await app.validateSmsOtp(_phone.text.trim(), _otp.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == 'success') {
        final flow = _flow;
        _step = flow[flow.indexOf(_step) + 1];
        _error = null;
      } else {
        _error = result?.toString() ??
            _copy('الرمز غير صحيح.', 'The code is not valid.');
      }
    });
  }

  void _finish() {
    app.configurePendingUserRegistration(
      displayName: _name.text.trim(),
      emailAddress: _email.text.trim(),
      plainPassword: _password.text,
      mobileNumber: _phone.text.replaceAll(RegExp(r'\D'), ''),
      selectedGender: _gender,
      countryIndex: _country!.index,
    );
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AggreementPage()));
  }

  void _back() {
    if (_step == SignupField.name) {
      Navigator.pop(context);
    } else {
      final flow = _flow;
      final index = flow.indexOf(_step);
      setState(() {
        _step = flow[index - 1];
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
        title: Text(_copy('إنشاء حساب', 'Create account'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Progress(
                      step: _stepIndex, count: _flow.length, color: theme),
                  const SizedBox(height: 42),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(.06, 0), end: Offset.zero)
                              .animate(animation),
                          child: child),
                    ),
                    child: _stepBody(colors),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(14)),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onErrorContainer)),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _next,
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
                        : Text(
                            _step == SignupField.gender
                                ? _copy('مراجعة ومتابعة', 'Review and continue')
                                : _copy('متابعة', 'Continue'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  if (_step == SignupField.email &&
                      (_country?.emailOptional ?? false))
                    TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                _email.clear();
                                _advance();
                              },
                        child: Text(_copy('تخطي الآن', 'Skip for now'))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _stepBody(ColorScheme colors) {
    final channel = _country == null ? SignupOtpChannel.sms : _channel;
    switch (_step) {
      case SignupField.name:
        return _StepCard(
            key: const ValueKey(0),
            icon: Icons.waving_hand_rounded,
            title: _copy('أهلًا! ما اسمك؟', 'Nice to meet you'),
            subtitle: _copy(
                'سنستخدمه داخل رحلاتك وحسابك.', 'What should we call you?'),
            child: _Field(
                controller: _name,
                hint: _copy('اسمك', 'Your name'),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _next()));
      case SignupField.country:
        return _StepCard(
            key: const ValueKey(SignupField.country),
            icon: Icons.public_rounded,
            title: _copy('من أي دولة؟', 'Where are you from?'),
            subtitle: _copy('سنضبط طريقة التحقق ورقم الهاتف تلقائيًا.',
                'We will tailor verification and phone formatting for you.'),
            child: DropdownButtonFormField<CountryAuthPolicy>(
              initialValue: _country,
              isExpanded: true,
              decoration: _decoration(_copy('اختر الدولة', 'Choose country')),
              items: _policies
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text('${item.name}  ${item.dialCode}')))
                  .toList(),
              onChanged: (value) => setState(() => _country = value),
            ));
      case SignupField.email:
        return _StepCard(
            key: const ValueKey(SignupField.email),
            icon: Icons.alternate_email_rounded,
            title: _copy('بريدك الإلكتروني', 'Your email'),
            subtitle: _country?.emailOptional == true
                ? _copy('لاستعادة الحساب والإيصالات. يمكنك تخطيه.',
                    'Useful for recovery and receipts. You can skip it.')
                : _copy('سنرسل رمز التحقق إلى هذا البريد.',
                    'We will send your verification code to this email.'),
            child: Column(children: [
              _Field(
                  controller: _email,
                  hint: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true),
              _GmailSuggestion(controller: _email),
            ]));
      case SignupField.password:
        return _StepCard(
            key: const ValueKey(2),
            icon: Icons.lock_outline_rounded,
            title: _copy('أمّن حسابك', 'Secure your account'),
            subtitle:
                _copy('استخدم 8 أحرف على الأقل.', 'Use at least 8 characters.'),
            child: _Field(
                controller: _password,
                hint: _copy('كلمة المرور', 'Password'),
                obscureText: _obscure,
                autofocus: true,
                suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined))));
      case SignupField.phone:
        return _StepCard(
            key: const ValueKey(SignupField.phone),
            icon: Icons.phone_iphone_rounded,
            title: _copy('رقم هاتفك', 'Your phone number'),
            subtitle: _copy('الرمز الدولي مضبوط تلقائيًا.',
                'Your country code is already set.'),
            child: Column(children: [
              _Field(
                  controller: _phone,
                  hint: _copy('رقم الهاتف', 'Phone number'),
                  prefixText: '${_country?.dialCode ?? ''}  ',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true),
            ]));
      case SignupField.otp:
        return _StepCard(
            key: const ValueKey(4),
            icon: _channelIcon(channel),
            title: _copy('أدخل رمز التحقق', 'Enter verification code'),
            subtitle: _otpMessage(channel),
            child: _Field(
                controller: _otp,
                hint: '000000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)
                ],
                autofocus: true,
                textAlign: TextAlign.center,
                letterSpacing: 10));
      case SignupField.gender:
        return _StepCard(
            key: const ValueKey(5),
            icon: Icons.person_outline_rounded,
            title: _copy('كيف تحب أن نخاطبك؟', 'One last detail'),
            subtitle: _copy('يمكنك تغيير هذا لاحقًا من الملف الشخصي.',
                'You can change this later.'),
            child: Row(children: [
              Expanded(
                  child: _GenderChoice(
                      label: _copy('ذكر', 'Male'),
                      icon: Icons.male_rounded,
                      selected: _gender == 'male',
                      onTap: () => setState(() => _gender = 'male'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _GenderChoice(
                      label: _copy('أنثى', 'Female'),
                      icon: Icons.female_rounded,
                      selected: _gender == 'female',
                      onTap: () => setState(() => _gender = 'female'))),
            ]));
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none));

  IconData _channelIcon(SignupOtpChannel value) => switch (value) {
        SignupOtpChannel.email => Icons.mark_email_read_outlined,
        SignupOtpChannel.whatsapp => Icons.chat_bubble_outline_rounded,
        _ => Icons.sms_outlined,
      };

  String _otpMessage(SignupOtpChannel value) => switch (value) {
        SignupOtpChannel.email => _copy('أرسلنا الرمز إلى بريدك الإلكتروني.',
            'We sent the code to your email.'),
        SignupOtpChannel.whatsapp => _copy('أرسلنا الرمز إلى رقمك عبر واتساب.',
            'We sent the code to your WhatsApp number.'),
        _ => _copy(
            'أرسلنا الرمز إلى رقم هاتفك.', 'We sent the code to your phone.'),
      };
}

class _GmailSuggestion extends StatelessWidget {
  const _GmailSuggestion({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final suggestion = gmailSuggestionFor(value.text);
          if (suggestion == null) return const SizedBox.shrink();
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ActionChip(
                avatar: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(suggestion),
                onPressed: () {
                  controller.value = TextEditingValue(
                    text: suggestion,
                    selection:
                        TextSelection.collapsed(offset: suggestion.length),
                  );
                },
              ),
            ),
          );
        },
      );
}

class _Progress extends StatelessWidget {
  const _Progress(
      {required this.step, required this.count, required this.color});
  final int step;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
          value: (step + 1) / count,
          minHeight: 6,
          color: color,
          backgroundColor: color.withValues(alpha: .12)));
}

class _StepCard extends StatelessWidget {
  const _StepCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.child});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: theme.withValues(alpha: .1), shape: BoxShape.circle),
            child: Icon(icon, color: theme, size: 30)),
        const SizedBox(height: 22),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, height: 1.2)),
        const SizedBox(height: 10),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, height: 1.5, color: Colors.blueGrey.shade600)),
        const SizedBox(height: 30),
        child,
      ]);
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.controller,
      required this.hint,
      this.keyboardType,
      this.obscureText = false,
      this.autofocus = false,
      this.suffix,
      this.prefixText,
      this.inputFormatters,
      this.textInputAction,
      this.onSubmitted,
      this.textAlign = TextAlign.start,
      this.letterSpacing});
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final Widget? suffix;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextAlign textAlign;
  final double? letterSpacing;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: autofocus,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        textAlign: textAlign,
        style: TextStyle(fontSize: 17, letterSpacing: letterSpacing),
        decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
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
                borderSide: BorderSide(color: theme, width: 1.5))),
      );
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
                color: selected ? theme.withValues(alpha: .1) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: selected
                        ? theme
                        : Colors.blueGrey.withValues(alpha: .15),
                    width: selected ? 2 : 1)),
            child: Column(children: [
              Icon(icon, color: selected ? theme : Colors.blueGrey, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? theme : Colors.blueGrey.shade800))
            ])),
      );
}
