import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_brand.dart';
import 'card_scanner_page.dart';
import 'card_text_parser.dart';
import 'card_vault.dart';
import 'card_visual.dart';
import 'moamalat_env.dart';
import 'saved_card.dart';

const Color _amber = Color(0xFFB26A00);
const Color _red = Color(0xFFD92D20);

/// Groups typed digits the way the brand prints them (Arabic-Indic digits work).
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = CardRules.digitsOnly(newValue.text);
    if (digits.length > 19) digits = digits.substring(0, 19);
    final grouped = groupCardNumber(digits);
    return TextEditingValue(text: grouped, selection: TextSelection.collapsed(offset: grouped.length));
  }
}

/// `1228` -> `12/28`.
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = CardRules.digitsOnly(newValue.text);
    if (digits.length > 4) digits = digits.substring(0, 4);
    // "8" -> "08" when the month can only be one digit.
    if (digits.length == 1 && int.parse(digits) > 1) digits = '0$digits';
    final text = digits.length > 2 ? '${digits.substring(0, 2)}/${digits.substring(2)}' : digits;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// The cards kept on this phone: add (live camera scan or typing), edit,
/// delete, choose the default.
class SavedCardsPage extends StatefulWidget {
  const SavedCardsPage({super.key, required this.env});

  final MoamalatEnv env;

  @override
  State<SavedCardsPage> createState() => _SavedCardsPageState();
}

class _SavedCardsPageState extends State<SavedCardsPage> {
  List<SavedCard>? _cards;

  MoamalatEnv get env => widget.env;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final cards = await env.vault.load();
    // Only the last four digits stay in screen state.
    if (mounted) setState(() => _cards = cards.map((c) => c.redacted()).toList());
  }

  Future<void> _add({bool scan = false}) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CardFormPage(env: env, startWithScan: scan)));
    if (saved == true) await _reload();
  }

  Future<void> _edit(SavedCard card) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CardFormPage(env: env, existing: card)));
    if (saved == true) await _reload();
  }

  Future<void> _actions(SavedCard card) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: env.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => Directionality(
        textDirection: env.direction,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: env.border, borderRadius: BorderRadius.circular(9))),
              const SizedBox(height: 14),
              SizedBox(width: 220, child: _visual(card)),
              const SizedBox(height: 10),
              if (!card.isDefault)
                ListTile(
                  key: const Key('card-make-default'),
                  leading: Icon(Icons.star_rounded, color: env.accent),
                  title: Text(env.t('تعيين كافتراضية', 'Make default'), style: env.style(weight: FontWeight.w700)),
                  onTap: () => Navigator.pop(context, 'default'),
                ),
              ListTile(
                key: const Key('card-edit'),
                leading: Icon(Icons.edit_rounded, color: env.text),
                title: Text(env.t('تعديل', 'Edit'), style: env.style(weight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                key: const Key('card-delete'),
                leading: const Icon(Icons.delete_outline_rounded, color: _red),
                title: Text(env.t('حذف من هذا الجهاز', 'Delete from this phone'), style: env.style(weight: FontWeight.w700, color: _red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ]),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'default') {
      await env.vault.setDefault(card.id);
      HapticFeedback.selectionClick();
      await _reload();
    } else if (action == 'edit') {
      await _edit(card);
    } else if (action == 'delete') {
      await _confirmDelete(card);
    }
  }

  Future<void> _confirmDelete(SavedCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: env.direction,
        child: AlertDialog(
          title: Text(env.t('حذف البطاقة؟', 'Delete this card?'), style: env.style(size: 16, weight: FontWeight.w800)),
          content: Text('${card.masked}\n${env.t('ستُحذف من هذا الجهاز فقط.', 'It will be removed from this device only.')}',
              style: env.style(size: 13, weight: FontWeight.w500, color: env.muted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(env.t('إلغاء', 'Cancel'))),
            TextButton(key: const Key('confirm-delete'), onPressed: () => Navigator.pop(context, true), child: Text(env.t('حذف', 'Delete'), style: const TextStyle(color: _red))),
          ],
        ),
      ),
    );
    if (ok == true) {
      await env.vault.delete(card.id);
      await _reload();
    }
  }

  Widget _visual(SavedCard card) {
    final expired = card.isExpired();
    return CardVisual(
      key: Key('card-${card.id}'),
      brand: card.brand,
      numberText: card.maskedDots,
      holderText: card.holderName,
      expiryText: card.expiryText,
      title: card.nickname,
      dimmed: expired,
      badge: expired
          ? _badge(env.t('منتهية', 'Expired'), _red)
          : (card.isDefault ? _badge(env.t('افتراضية', 'Default'), Colors.white) : null),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withValues(alpha: 0.6))),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Directionality(
      textDirection: env.direction,
      child: Scaffold(
        backgroundColor: env.background,
        appBar: AppBar(
          backgroundColor: env.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: env.text,
          title: Text(env.t('البطاقات المحفوظة', 'Saved cards'), style: env.style(size: 17, weight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: cards == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  children: [
                    SecurityNote(env: env),
                    const SizedBox(height: 16),
                    if (cards.isEmpty) _empty(),
                    for (final card in cards)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        // Tap a card for: make default, edit, delete.
                        child: GestureDetector(key: Key('card-menu-${card.id}'), onTap: () => _actions(card), child: _visual(card)),
                      ),
                  ],
                ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: cards == null || cards.isEmpty
            ? null
            : FloatingActionButton.extended(
                key: const Key('add-card'),
                backgroundColor: env.accent,
                foregroundColor: env.onAccent,
                onPressed: () => _add(),
                icon: const Icon(Icons.add_card_rounded),
                label: Text(env.t('إضافة بطاقة', 'Add card'), style: env.style(size: 14, weight: FontWeight.w800, color: env.onAccent)),
              ),
      ),
    );
  }

  Widget _empty() {
    return Column(children: [
      const SizedBox(height: 8),
      const SizedBox(
        width: 250,
        child: CardVisual(brand: CardBrand.local, numberText: '•••• •••• •••• ••••', holderText: 'YOUR NAME', expiryText: 'MM/YY', title: 'TAXISTA', dimmed: true),
      ),
      const SizedBox(height: 18),
      Text(env.t('لا توجد بطاقات محفوظة', 'No saved cards yet'), style: env.style(size: 16, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(env.t('صوّر بطاقتك مرة وحدة، وبعدها تلقاها جاهزة في كل شحن.', 'Scan your card once; it is ready for every top-up after that.'),
          textAlign: TextAlign.center, style: env.style(size: 13, weight: FontWeight.w500, color: env.muted)),
      const SizedBox(height: 20),
      FilledButton.icon(
        key: const Key('empty-scan'),
        style: FilledButton.styleFrom(backgroundColor: env.accent, foregroundColor: env.onAccent, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () => _add(scan: true),
        icon: const Icon(Icons.document_scanner_outlined),
        label: Text(env.t('صوّر البطاقة', 'Scan your card'), style: env.style(size: 15, weight: FontWeight.w800, color: env.onAccent)),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        key: const Key('empty-type'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), side: BorderSide(color: env.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () => _add(),
        icon: Icon(Icons.keyboard_alt_outlined, color: env.text),
        label: Text(env.t('اكتب البيانات بيدك', 'Type the details'), style: env.style(size: 14, weight: FontWeight.w700)),
      ),
    ]);
  }
}

class SecurityNote extends StatelessWidget {
  const SecurityNote({super.key, required this.env});

  final MoamalatEnv env;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: env.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.verified_user_rounded, size: 20, color: env.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            env.t('تُحفظ بطاقاتك مشفّرة على هذا الجهاز فقط. لا نحفظ رمز الأمان (CVV) أبداً ولا نرسل رقم البطاقة إلى خوادمنا.',
                'Your cards are kept encrypted on this device only. We never store the security code (CVV) and never send the card number to our servers.'),
            style: env.style(size: 12, weight: FontWeight.w500, color: env.text),
          ),
        ),
      ]),
    );
  }
}

/// Add or edit a card, with a live preview and the camera scanner. There is no
/// security-code field on purpose.
class CardFormPage extends StatefulWidget {
  const CardFormPage({super.key, required this.env, this.existing, this.startWithScan = false, this.openScanner});

  final MoamalatEnv env;

  /// A redacted copy of the card being edited (its number is not shown).
  final SavedCard? existing;
  final bool startWithScan;

  /// Replaces the camera screen (tests only).
  final Future<CardScanResult?> Function(BuildContext context)? openScanner;

  @override
  State<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends State<CardFormPage> {
  late final TextEditingController _holder = TextEditingController(text: widget.existing?.holderName ?? '');
  final TextEditingController _number = TextEditingController();
  late final TextEditingController _expiry = TextEditingController(text: widget.existing?.expiryText ?? '');
  late final TextEditingController _nickname = TextEditingController(text: widget.existing?.nickname ?? '');
  final FocusNode _numberFocus = FocusNode();
  final FocusNode _holderFocus = FocusNode();
  final FocusNode _expiryFocus = FocusNode();

  String? _holderError, _numberError, _expiryError, _saveError;
  bool _saving = false;
  bool _fromScan = false;
  bool _confirmed = false;
  Set<CardField> _review = const <CardField>{};

  MoamalatEnv get env => widget.env;
  bool get _editing => widget.existing != null;

  static const String _explainedKey = 'taxista.card_scan_explained.v1';

  @override
  void initState() {
    super.initState();
    for (final c in [_holder, _number, _expiry, _nickname]) {
      c.addListener(_changed);
    }
    for (final f in [_numberFocus, _holderFocus, _expiryFocus]) {
      f.addListener(_changed);
    }
    if (widget.startWithScan) WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_holder, _number, _expiry, _nickname]) {
      c.dispose();
    }
    _numberFocus.dispose();
    _holderFocus.dispose();
    _expiryFocus.dispose();
    super.dispose();
  }

  Future<bool> _explainOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_explainedKey) == true) return true;
      if (!mounted) return false;
      final agreed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: env.direction,
          child: AlertDialog(
            key: const Key('scan-explainer'),
            icon: Icon(Icons.document_scanner_rounded, color: env.accent, size: 36),
            title: Text(env.t('تصوير البطاقة', 'Scan your card'), style: env.style(size: 17, weight: FontWeight.w800)),
            content: Text(
              env.t(
                  'سنفتح الكاميرا لقراءة رقم البطاقة واسم حاملها وتاريخ الانتهاء من الوجه الأمامي فقط. تتم القراءة على جهازك، ولا تُرفع الصورة ولا تُحفظ. ستراجع البيانات وتصحّحها قبل الحفظ، ولن نقرأ رمز الأمان (CVV).',
                  'We will open the camera to read the number, name and expiry from the FRONT of the card. Reading happens on your phone; the image is never uploaded or kept. You review and correct everything before saving, and we never read the security code (CVV).'),
              style: env.style(size: 13, weight: FontWeight.w500, color: env.muted),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(env.t('إلغاء', 'Cancel'))),
              FilledButton(
                key: const Key('scan-continue'),
                style: FilledButton.styleFrom(backgroundColor: env.accent, foregroundColor: env.onAccent),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(env.t('متابعة', 'Continue')),
              ),
            ],
          ),
        ),
      );
      if (agreed == true) await prefs.setBool(_explainedKey, true);
      return agreed == true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _scan() async {
    FocusScope.of(context).unfocus();
    if (!await _explainOnce() || !mounted) return;
    final result = widget.openScanner != null ? await widget.openScanner!(context) : await CardScannerPage.open(context, isRtl: env.isRtl);
    if (!mounted || result == null) return;
    if (result.manual) {
      _numberFocus.requestFocus();
      return;
    }
    final card = result.card;
    if (card == null) return;
    setState(() {
      if (card.number != null) _number.text = groupCardNumber(card.number!);
      if (card.expiryText != null) _expiry.text = card.expiryText!;
      if (card.holder != null) _holder.text = card.holder!;
      _review = {
        ...card.review,
        if (card.number == null) CardField.number,
        if (card.expiryText == null) CardField.expiry,
        if (card.holder == null) CardField.holder,
      };
      _fromScan = true;
      // Nothing doubtful: the customer still glances at the preview, but needs no extra tick.
      _confirmed = _review.isEmpty;
      _holderError = _numberError = _expiryError = _saveError = null;
    });
    // Take the customer straight to the first field that needs them.
    if (_review.contains(CardField.number)) {
      _numberFocus.requestFocus();
    } else if (_review.contains(CardField.expiry)) {
      _expiryFocus.requestFocus();
    } else if (_review.contains(CardField.holder)) {
      _holderFocus.requestFocus();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final replacingNumber = !_editing || _number.text.trim().isNotEmpty;
    setState(() {
      _saveError = null;
      _holderError = CardRules.isHolderValid(_holder.text) ? null : env.t('أدخل اسم حامل البطاقة', 'Enter the cardholder name');
      _numberError = replacingNumber && !CardRules.isNumberValid(_number.text) ? env.t('رقم البطاقة غير صحيح', 'Card number looks wrong') : null;
      _expiryError = CardRules.isExpiryValid(_expiry.text) ? null : env.t('تاريخ الانتهاء غير صحيح أو منتهٍ', 'Expiry is invalid or in the past');
    });
    if (_holderError != null || _numberError != null || _expiryError != null) {
      HapticFeedback.lightImpact();
      return;
    }
    if (_fromScan && !_confirmed) {
      setState(() => _saveError = env.t('أكّد إنك راجعت الخانات المعلَّمة', 'Confirm you checked the highlighted details'));
      return;
    }

    setState(() => _saving = true);
    final expiry = CardRules.parseExpiry(_expiry.text)!;
    try {
      if (_editing) {
        await env.vault.update(widget.existing!.id,
            holderName: _holder.text, number: replacingNumber ? _number.text : null, expMonth: expiry.month, expYear: expiry.year, nickname: _nickname.text);
      } else {
        await env.vault.add(holderName: _holder.text, number: _number.text, expMonth: expiry.month, expYear: expiry.year, nickname: _nickname.text);
      }
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } on DuplicateCard {
      if (mounted) setState(() => _saveError = env.t('البطاقة هذي محفوظة من قبل على هذا الجهاز.', 'This card is already saved on this device.'));
    } on TooManyCards {
      if (mounted) setState(() => _saveError = env.t('تقدر تحفظ ${CardVault.maxCards} بطاقات بالكثير.', 'You can keep up to ${CardVault.maxCards} cards.'));
    } catch (_) {
      if (mounted) setState(() => _saveError = env.t('تعذّر حفظ البطاقة على هذا الجهاز', 'Could not save the card on this device'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _helperFor(CardField field) =>
      _fromScan && _review.contains(field) ? env.t('تحقق من هذا الحقل — قد لا تكون القراءة دقيقة', 'Check this field — the reading may be wrong') : null;

  InputDecoration _decoration(String label, {String? error, String? hint, String? helper, Widget? prefix, bool flagged = false}) {
    final borderColor = flagged ? _amber : env.border;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      helperText: helper,
      helperMaxLines: 2,
      helperStyle: const TextStyle(color: _amber, fontWeight: FontWeight.w700),
      counterStyle: env.style(size: 11, weight: FontWeight.w500, color: env.muted),
      // Readable on both the light and the dark (Driver) look.
      labelStyle: env.style(size: 13.5, weight: FontWeight.w600, color: env.muted),
      floatingLabelStyle: env.style(size: 13.5, weight: FontWeight.w700, color: env.text),
      hintStyle: env.style(size: 14, weight: FontWeight.w500, color: env.muted.withValues(alpha: 0.7)),
      prefixIcon: prefix,
      prefixIconColor: env.muted,
      filled: true,
      fillColor: flagged ? const Color(0x14B26A00) : env.surface,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: flagged ? 1.6 : 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: env.accent, width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red, width: 1.8)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = CardRules.digitsOnly(_number.text);
    final brand = digits.isEmpty && _editing ? widget.existing!.brand : cardBrandOf(digits);
    final numberPreview = digits.isEmpty
        ? (_editing ? widget.existing!.maskedDots : '•••• •••• •••• ••••')
        : (_numberFocus.hasFocus ? groupCardNumber(digits) : maskForPreview(digits));
    final highlight = _numberFocus.hasFocus
        ? CardVisualField.number
        : (_holderFocus.hasFocus ? CardVisualField.holder : (_expiryFocus.hasFocus ? CardVisualField.expiry : null));

    return Directionality(
      textDirection: env.direction,
      child: Scaffold(
        backgroundColor: env.background,
        appBar: AppBar(
          backgroundColor: env.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: env.text,
          title: Text(_editing ? env.t('تعديل البطاقة', 'Edit card') : env.t('إضافة بطاقة', 'Add card'), style: env.style(size: 17, weight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              CardVisual(
                brand: brand,
                numberText: numberPreview,
                holderText: _holder.text.trim().isEmpty ? env.t('الاسم', 'NAME') : _holder.text,
                expiryText: _expiry.text.isEmpty ? 'MM/YY' : _expiry.text,
                title: _nickname.text.trim().isEmpty ? null : _nickname.text.trim(),
                highlight: highlight,
              ),
              const SizedBox(height: 16),
              _scanBanner(),
              const SizedBox(height: 16),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  key: const Key('card-number'),
                  controller: _number,
                  focusNode: _numberFocus,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const <String>[],
                  inputFormatters: [CardNumberFormatter()],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _expiryFocus.requestFocus(),
                  style: env.style(size: 17, weight: FontWeight.w700),
                  decoration: _decoration(
                    env.t('رقم البطاقة', 'Card number'),
                    error: _numberError,
                    helper: _helperFor(CardField.number) ?? (_editing ? env.t('خلّيه فاضي باش يبقى الرقم الحالي', 'Leave empty to keep the current number') : null),
                    hint: _editing ? widget.existing!.masked : '0000 0000 0000 0000',
                    prefix: const Icon(Icons.credit_card_rounded),
                    flagged: _fromScan && _review.contains(CardField.number),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      key: const Key('card-expiry'),
                      controller: _expiry,
                      focusNode: _expiryFocus,
                      keyboardType: TextInputType.number,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const <String>[],
                      inputFormatters: [ExpiryFormatter()],
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _holderFocus.requestFocus(),
                      style: env.style(size: 16, weight: FontWeight.w700),
                      decoration: _decoration(env.t('تاريخ الانتهاء', 'Expiry'),
                          error: _expiryError, hint: 'MM/YY', helper: _helperFor(CardField.expiry), flagged: _fromScan && _review.contains(CardField.expiry)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 56,
                    alignment: AlignmentDirectional.centerStart,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: env.border.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: env.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            key: const Key('cvv-note'),
                            // Never asked for here: a Numo card has none, others type it on the bank's page.
                            brand.hasCvv ? env.t('رمز CVV تكتبه في صفحة الدفع', 'Type the CVV on the payment page') : env.t('بطاقة نومو ما عندهاش رمز CVV', 'A Numo card has no CVV'),
                            style: env.style(size: 11.5, weight: FontWeight.w600, color: env.muted)),
                      ),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                key: const Key('card-holder'),
                controller: _holder,
                focusNode: _holderFocus,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const <String>[],
                textInputAction: TextInputAction.done,
                style: env.style(size: 15, weight: FontWeight.w700),
                decoration: _decoration(env.t('اسم صاحب البطاقة (زي ما هو مكتوب)', 'Cardholder name (as printed)'),
                    error: _holderError, helper: _helperFor(CardField.holder), prefix: const Icon(Icons.person_outline_rounded), flagged: _fromScan && _review.contains(CardField.holder)),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('card-nickname'),
                controller: _nickname,
                maxLength: 24,
                style: env.style(size: 14, weight: FontWeight.w600),
                decoration: _decoration(env.t('اسم للبطاقة (اختياري) — مثلاً: بطاقة المرتب', 'Card nickname (optional)'), prefix: const Icon(Icons.label_outline_rounded)),
              ),
              if (_fromScan && _review.isNotEmpty) ...[
                const SizedBox(height: 4),
                CheckboxListTile(
                  key: const Key('confirm-scan'),
                  value: _confirmed,
                  onChanged: (v) => setState(() {
                    _confirmed = v == true;
                    _saveError = null;
                  }),
                  activeColor: env.accent,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(env.t('راجعت الخانات المعلَّمة وهي نفس اللي في بطاقتي', 'I checked the highlighted fields against my card'),
                      style: env.style(size: 13, weight: FontWeight.w700)),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 6),
                Text(_saveError!, key: const Key('save-error'), style: env.style(size: 12.5, weight: FontWeight.w700, color: _red)),
              ],
              const SizedBox(height: 14),
              FilledButton(
                key: const Key('save-card'),
                style: FilledButton.styleFrom(backgroundColor: env.accent, foregroundColor: env.onAccent, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: env.onAccent))
                    : Text(env.t('حفظ البطاقة', 'Save card'), style: env.style(size: 15, weight: FontWeight.w800, color: env.onAccent)),
              ),
              const SizedBox(height: 12),
              SecurityNote(env: env),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanBanner() {
    final scanned = _fromScan;
    return Material(
      color: scanned ? const Color(0x1422C55E) : env.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('scan-card'),
        borderRadius: BorderRadius.circular(16),
        onTap: _scan,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scanned ? const Color(0x6622C55E) : env.accent.withValues(alpha: 0.45), width: 1.4),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: scanned ? const Color(0xFF22C55E) : env.accent, borderRadius: BorderRadius.circular(12)),
              child: Icon(scanned ? Icons.check_rounded : Icons.document_scanner_outlined, color: scanned ? Colors.white : env.onAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  scanned
                      ? (_review.isEmpty ? env.t('انقرت البطاقة كاملة', 'Card read completely') : env.t('انقرت — راجع الخانات المعلَّمة', 'Read - check the highlighted fields'))
                      : env.t('صوّر البطاقة بالكاميرا', 'Scan with the camera'),
                  style: env.style(size: 14.5, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  scanned ? env.t('اضغط باش تعاود التصوير', 'Tap to scan again') : env.t('نقروا الرقم والاسم والتاريخ وحدهم — داخل تليفونك', 'Reads number, name and expiry automatically - on your phone'),
                  style: env.style(size: 12, weight: FontWeight.w500, color: env.muted),
                ),
              ]),
            ),
            Icon(env.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: env.muted),
          ]),
        ),
      ),
    );
  }
}

/// One saved card as a compact row (used to pick a card before paying).
class SavedCardTile extends StatelessWidget {
  const SavedCardTile({super.key, required this.env, required this.card, this.trailing, this.selected = false, this.onTap});

  final MoamalatEnv env;
  final SavedCard card;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final expired = card.isExpired();
    return Material(
      color: env.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: expired ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? env.accent : env.border, width: selected ? 1.8 : 1),
          ),
          child: Row(children: [
            SizedBox(
              width: 74,
              child: CardVisual(brand: card.brand, numberText: '•••• ${card.last4}', holderText: '', expiryText: '', dimmed: expired),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: env.style(size: 14, weight: FontWeight.w800))),
                  if (card.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: env.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                      child: Text(env.t('افتراضية', 'Default'), style: env.style(size: 10, weight: FontWeight.w800, color: env.accent)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (card.brand.label.isNotEmpty) ...[
                      Text(card.brand.label, style: env.style(size: 11.5, weight: FontWeight.w800, color: env.muted)),
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: Text(card.masked, key: Key('masked-${card.id}'), style: env.style(size: 13, weight: FontWeight.w700, color: env.muted))),
                  ]),
                ),
                Text(
                  expired
                      ? env.t('منتهية الصلاحية', 'Expired')
                      // The holder is already the title unless the card has a nickname.
                      : (card.title == card.holderName ? card.expiryText : '${card.holderName}  ·  ${card.expiryText}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: env.style(size: 11.5, weight: FontWeight.w600, color: expired ? _red : env.muted),
                ),
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}
