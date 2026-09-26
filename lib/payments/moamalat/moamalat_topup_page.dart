import 'package:flutter/material.dart';

import 'moamalat_api.dart';
import 'moamalat_checkout_page.dart';
import 'moamalat_env.dart';
import 'saved_card.dart';
import 'saved_cards_page.dart';
import 'topup_flow.dart';

/// Wallet -> Add money -> Moamalat: choose an amount and (optionally) a saved
/// card, then continue to the secure payment page.
class MoamalatTopUpPage extends StatefulWidget {
  const MoamalatTopUpPage({super.key, required this.env, required this.options, this.checkoutViewBuilder});

  final MoamalatEnv env;
  final MoamalatOptions options;

  /// Replaces the real payment web view (tests only).
  final PaymentViewBuilder? checkoutViewBuilder;

  @override
  State<MoamalatTopUpPage> createState() => _MoamalatTopUpPageState();
}

class _MoamalatTopUpPageState extends State<MoamalatTopUpPage> {
  final TextEditingController _amount = TextEditingController();
  List<SavedCard> _cards = const [];
  String? _selectedCardId;
  bool _starting = false;
  String? _error;

  MoamalatEnv get env => widget.env;
  String get _currency => widget.options.currency ?? '';

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadCards({bool keepSelection = true}) async {
    final cards = await env.vault.load();
    if (!mounted) return;
    setState(() {
      // Only the last four digits stay in screen state; the vault is asked again when a fill is tapped.
      _cards = cards.map((c) => c.redacted()).toList();
      final stillThere = keepSelection && cards.any((c) => c.id == _selectedCardId);
      if (!stillThere) _selectedCardId = cards.isEmpty ? null : cards.first.id; // default card is first
    });
  }

  SavedCard? get _selected {
    for (final c in _cards) {
      if (c.id == _selectedCardId) return c;
    }
    return null;
  }

  double? get _parsedAmount => double.tryParse(normalizeDigits(_amount.text).replaceAll(',', '.').trim());

  List<int> get _quickAmounts {
    final min = widget.options.minAmount;
    final max = widget.options.maxAmount;
    return [20, 50, 100, 200].where((v) => v >= min && (max <= 0 || v <= max)).toList();
  }

  Future<void> _continue() async {
    if (_starting) return;
    final amount = _parsedAmount;
    final min = widget.options.minAmount;
    final max = widget.options.maxAmount;
    if (amount == null || amount <= 0) {
      setState(() => _error = env.t('أدخل مبلغاً صحيحاً', 'Enter a valid amount'));
      return;
    }
    if (amount < min || (max > 0 && amount > max)) {
      setState(() => _error = env.t(
          'المبلغ يجب أن يكون بين ${_fmt(min)} و${_fmt(max)} $_currency', 'Amount must be between ${_fmt(min)} and ${_fmt(max)} $_currency'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final topUp = await env.api.initiate(amount);
      if (!mounted) return;
      final outcome = await Navigator.of(context).push<TopUpOutcome>(
        MaterialPageRoute(builder: (_) => MoamalatCheckoutPage(env: env, topUp: topUp, card: _selected, cardOnFile: widget.options.cardOnFile, viewBuilder: widget.checkoutViewBuilder)),
      );
      if (!mounted) return;
      if (outcome == TopUpOutcome.paid) {
        env.onWalletChanged?.call();
        Navigator.of(context).pop(true);
        return;
      }
    } on MoamalatException catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  String _messageFor(MoamalatException e) {
    switch (e.kind) {
      case MoamalatErrorKind.network:
        return env.t('تحقق من اتصالك بالإنترنت ثم حاول مجدداً', 'Check your internet connection and try again');
      case MoamalatErrorKind.unavailable:
        return env.t('الدفع عبر معاملات غير متاح حالياً', 'Moamalat payment is not available right now');
      case MoamalatErrorKind.invalidAmount:
        return env.t('المبلغ غير مقبول', 'That amount is not accepted');
      case MoamalatErrorKind.unauthorized:
        return env.t('انتهت الجلسة. سجّل الدخول مجدداً', 'Your session expired. Please sign in again');
      case MoamalatErrorKind.server:
        return env.t('تعذّر بدء الدفع. حاول مجدداً بعد قليل', 'Could not start the payment. Try again shortly');
    }
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: env.direction,
      child: Scaffold(
        backgroundColor: env.background,
        appBar: AppBar(
          backgroundColor: env.background,
          elevation: 0,
          foregroundColor: env.text,
          title: Text(env.t('الدفع الإلكتروني الآمن', 'Secure online payment'), style: env.style(size: 17, weight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(env.t('المبلغ', 'Amount'), style: env.style(size: 13, weight: FontWeight.w700, color: env.muted)),
              const SizedBox(height: 6),
              TextField(
                key: const Key('topup-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: env.style(size: 22, weight: FontWeight.w800),
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  suffixText: _currency,
                  hintText: '0',
                  filled: true,
                  fillColor: env.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: env.border)),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final v in _quickAmounts)
                  ActionChip(
                    key: Key('quick-$v'),
                    label: Text('$v $_currency', style: env.style(size: 12.5, weight: FontWeight.w700, color: env.accent)),
                    backgroundColor: env.accent.withOpacity(0.08),
                    side: BorderSide.none,
                    onPressed: () => setState(() {
                      _amount.text = '$v';
                      _error = null;
                    }),
                  ),
              ]),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, key: const Key('topup-error'), style: env.style(size: 12.5, weight: FontWeight.w700, color: const Color(0xffD92D20))),
              ],
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Text(env.t('بطاقاتي', 'My cards'), style: env.style(size: 14.5, weight: FontWeight.w800))),
                TextButton(
                  key: const Key('manage-cards'),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SavedCardsPage(env: env)));
                    await _loadCards();
                  },
                  child: Text(_cards.isEmpty ? env.t('إضافة بطاقة', 'Add a card') : env.t('إدارة', 'Manage'),
                      style: env.style(size: 13, weight: FontWeight.w800, color: env.accent)),
                ),
              ]),
              const SizedBox(height: 6),
              if (_cards.isEmpty)
                Text(
                    widget.options.cardOnFile
                        ? env.t('لدفع أسرع في المرة القادمة: فعّل «حفظ البطاقة» في صفحة الدفع الآمنة وستجد بطاقتك جاهزة.',
                            'For faster payments next time, turn on “Save card” on the secure payment page and your card will be ready.')
                        : env.t('يمكنك حفظ بطاقتك على هذا الجهاز لنسخ بياناتها بسهولة في صفحة الدفع.',
                            'Save your card on this device to copy its details easily on the payment page.'),
                    key: const Key('cards-empty-note'),
                    style: env.style(size: 12.5, weight: FontWeight.w500, color: env.muted))
              else ...[
                for (final card in _cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SavedCardTile(
                      env: env,
                      card: card,
                      selected: card.id == _selectedCardId,
                      onTap: () => setState(() => _selectedCardId = card.id),
                      trailing: Icon(
                        card.id == _selectedCardId ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: card.id == _selectedCardId ? env.accent : env.muted,
                      ),
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: const Key('no-card'),
                    onPressed: () => setState(() => _selectedCardId = null),
                    child: Text(env.t('الدفع دون بطاقة محفوظة', 'Pay without a saved card'), style: env.style(size: 12.5, weight: FontWeight.w700, color: env.muted)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('topup-continue'),
                style: FilledButton.styleFrom(backgroundColor: env.accent, minimumSize: const Size.fromHeight(52)),
                onPressed: _starting ? null : _continue,
                child: _starting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(env.t('المتابعة إلى الدفع الآمن', 'Continue to secure payment'), style: env.style(size: 15, weight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.lock_rounded, size: 14, color: env.muted),
                const SizedBox(width: 6),
                Flexible(child: Text(env.t('تتم عملية الدفع على صفحة معاملات الآمنة', 'Payment is completed on the secure Moamalat page'),
                    style: env.style(size: 11.5, weight: FontWeight.w500, color: env.muted))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
