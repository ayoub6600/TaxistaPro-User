import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'moamalat_env.dart';
import 'saved_card.dart';

/// Groups typed digits in fours: `4111111111111111` -> `4111 1111 1111 1111`.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = CardRules.digitsOnly(normalizeDigits(newValue.text));
    if (digits.length > 19) digits = digits.substring(0, 19);
    final grouped = CardRules.groupNumber(digits);
    return TextEditingValue(text: grouped, selection: TextSelection.collapsed(offset: grouped.length));
  }
}

/// `1228` -> `12/28`.
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = CardRules.digitsOnly(normalizeDigits(newValue.text));
    if (digits.length > 4) digits = digits.substring(0, 4);
    final text = digits.length > 2 ? '${digits.substring(0, 2)}/${digits.substring(2)}' : digits;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Manage the cards kept on this device: add, edit, delete, choose the default.
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
    if (mounted) setState(() => _cards = cards);
  }

  Future<void> _openForm([SavedCard? card]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: env.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CardForm(env: env, existing: card),
    );
    if (saved == true) await _reload();
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
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(env.t('حذف', 'Delete'), style: const TextStyle(color: Color(0xffD92D20))),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await env.vault.delete(card.id);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Directionality(
      textDirection: env.direction,
      child: Scaffold(
        backgroundColor: env.background,
        appBar: AppBar(
          backgroundColor: env.background,
          elevation: 0,
          foregroundColor: env.text,
          title: Text(env.t('البطاقات المحفوظة', 'Saved cards'), style: env.style(size: 17, weight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: cards == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    _SecurityNote(env: env),
                    const SizedBox(height: 12),
                    if (cards.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(children: [
                          Icon(Icons.credit_card_rounded, size: 44, color: env.muted),
                          const SizedBox(height: 10),
                          Text(env.t('لا توجد بطاقات محفوظة', 'No saved cards yet'), style: env.style(size: 15, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(env.t('أضف بطاقتك مرة واحدة لتسهيل الدفع لاحقاً.', 'Add your card once to make payments easier.'),
                              textAlign: TextAlign.center, style: env.style(size: 12.5, weight: FontWeight.w500, color: env.muted)),
                        ]),
                      ),
                    for (final card in cards)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SavedCardTile(
                          env: env,
                          card: card,
                          trailing: PopupMenuButton<String>(
                            key: Key('card-menu-${card.id}'),
                            onSelected: (value) async {
                              if (value == 'default') {
                                await env.vault.setDefault(card.id);
                                await _reload();
                              } else if (value == 'edit') {
                                await _openForm(card);
                              } else if (value == 'delete') {
                                await _confirmDelete(card);
                              }
                            },
                            itemBuilder: (_) => [
                              if (!card.isDefault)
                                PopupMenuItem(value: 'default', child: Text(env.t('تعيين كافتراضية', 'Make default'))),
                              PopupMenuItem(value: 'edit', child: Text(env.t('تعديل', 'Edit'))),
                              PopupMenuItem(value: 'delete', child: Text(env.t('حذف', 'Delete'))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('add-card'),
          backgroundColor: env.accent,
          foregroundColor: Colors.white,
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_card_rounded),
          label: Text(env.t('إضافة بطاقة', 'Add card'), style: env.style(size: 14, weight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.env});

  final MoamalatEnv env;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: env.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.lock_rounded, size: 18, color: env.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            env.t(
              'تُحفظ بطاقاتك مشفّرة على هذا الجهاز فقط. لا نحفظ رمز الأمان (CVV) أبداً ولا نرسل رقم البطاقة إلى خوادمنا.',
              'Your cards are kept encrypted on this device only. We never store the security code (CVV) and never send the card number to our servers.',
            ),
            style: env.style(size: 12, weight: FontWeight.w500, color: env.text),
          ),
        ),
      ]),
    );
  }
}

/// One saved card as a list row: masked number, holder, expiry.
class SavedCardTile extends StatelessWidget {
  const SavedCardTile({
    super.key,
    required this.env,
    required this.card,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  final MoamalatEnv env;
  final SavedCard card;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: env.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? env.accent : env.border, width: selected ? 1.8 : 1),
          ),
          child: Row(children: [
            Icon(Icons.credit_card_rounded, color: env.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: env.style(size: 14, weight: FontWeight.w800)),
                  ),
                  if (card.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: env.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                      child: Text(env.t('افتراضية', 'Default'), style: env.style(size: 10.5, weight: FontWeight.w800, color: env.accent)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(card.masked, key: Key('masked-${card.id}'), style: env.style(size: 13.5, weight: FontWeight.w700, color: env.muted)),
                ),
                const SizedBox(height: 2),
                Text(
                  // The holder is already the title unless the card has a nickname.
                  card.title == card.holderName ? card.expiryText : '${card.holderName}  ·  ${card.expiryText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: env.style(size: 12, weight: FontWeight.w500, color: env.muted),
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

/// Add or edit a card. There is no security-code field on purpose.
class CardForm extends StatefulWidget {
  const CardForm({super.key, required this.env, this.existing});

  final MoamalatEnv env;
  final SavedCard? existing;

  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  late final TextEditingController _holder = TextEditingController(text: widget.existing?.holderName ?? '');
  final TextEditingController _number = TextEditingController();
  late final TextEditingController _expiry = TextEditingController(text: widget.existing?.expiryText ?? '');
  late final TextEditingController _nickname = TextEditingController(text: widget.existing?.nickname ?? '');
  String? _holderError, _numberError, _expiryError;
  bool _saving = false;

  MoamalatEnv get env => widget.env;
  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final replacingNumber = !_editing || _number.text.trim().isNotEmpty;
    setState(() {
      _holderError = CardRules.isHolderValid(_holder.text) ? null : env.t('أدخل اسم حامل البطاقة', 'Enter the cardholder name');
      _numberError = replacingNumber && !CardRules.isNumberValid(_number.text)
          ? env.t('رقم البطاقة غير صحيح', 'Card number looks wrong')
          : null;
      _expiryError = CardRules.isExpiryValid(_expiry.text) ? null : env.t('تاريخ الانتهاء غير صحيح أو منتهٍ', 'Expiry is invalid or in the past');
    });
    if (_holderError != null || _numberError != null || _expiryError != null) return;

    setState(() => _saving = true);
    final expiry = CardRules.parseExpiry(_expiry.text)!;
    try {
      if (_editing) {
        await env.vault.update(
          widget.existing!.id,
          holderName: _holder.text,
          number: replacingNumber ? _number.text : null,
          expMonth: expiry.month,
          expYear: expiry.year,
          nickname: _nickname.text,
        );
      } else {
        await env.vault.add(
          holderName: _holder.text,
          number: _number.text,
          expMonth: expiry.month,
          expYear: expiry.year,
          nickname: _nickname.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _numberError = env.t('تعذّر حفظ البطاقة على هذا الجهاز', 'Could not save the card on this device');
        });
      }
    }
  }

  InputDecoration _decoration(String label, {String? error, String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: env.direction,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_editing ? env.t('تعديل البطاقة', 'Edit card') : env.t('إضافة بطاقة', 'Add card'),
                textAlign: TextAlign.center, style: env.style(size: 17, weight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              key: const Key('card-holder'),
              controller: _holder,
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: _decoration(env.t('اسم حامل البطاقة', 'Cardholder name'), error: _holderError),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                key: const Key('card-number'),
                controller: _number,
                keyboardType: TextInputType.number,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const <String>[],
                inputFormatters: [CardNumberFormatter()],
                decoration: _decoration(
                  env.t('رقم البطاقة', 'Card number'),
                  error: _numberError,
                  hint: _editing ? '${widget.existing!.masked}  (${env.t('اتركه فارغاً للإبقاء عليه', 'leave empty to keep')})' : '0000 0000 0000 0000',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                key: const Key('card-expiry'),
                controller: _expiry,
                keyboardType: TextInputType.number,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const <String>[],
                inputFormatters: [ExpiryFormatter()],
                decoration: _decoration(env.t('تاريخ الانتهاء (شهر/سنة)', 'Expiry (MM/YY)'), error: _expiryError, hint: 'MM/YY'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('card-nickname'),
              controller: _nickname,
              decoration: _decoration(env.t('اسم للبطاقة (اختياري)', 'Card name (optional)')),
            ),
            const SizedBox(height: 10),
            Text(
              env.t('لا نطلب رمز الأمان (CVV) ولا نحفظه. ستُدخله بنفسك في صفحة الدفع.',
                  'We never ask for or store the security code (CVV). You enter it yourself on the payment page.'),
              style: env.style(size: 11.5, weight: FontWeight.w500, color: env.muted),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('save-card'),
              style: FilledButton.styleFrom(backgroundColor: env.accent, minimumSize: const Size.fromHeight(48)),
              onPressed: _saving ? null : _save,
              child: Text(env.t('حفظ', 'Save'), style: env.style(size: 15, weight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}
