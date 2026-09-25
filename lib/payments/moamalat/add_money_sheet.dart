import 'package:flutter/material.dart';

import 'moamalat_api.dart';
import 'moamalat_checkout_page.dart' show PaymentViewBuilder;
import 'moamalat_env.dart';
import 'moamalat_topup_page.dart';

/// "Add money": the one place a rider or driver chooses HOW.
///
/// The methods come from the server for the customer's own market, so a market
/// without the bank card never sees it (and the server refuses it anyway). The
/// customer-facing names are "Qareeb recharge cards" and "Bank card" - the
/// payment provider behind the bank card is not part of the label.
Future<void> showAddMoneySheet(
  BuildContext context, {
  required MoamalatEnv env,
  required VoidCallback onQareeb,
  PaymentViewBuilder? checkoutViewBuilder,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: env.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => AddMoneySheet(env: env),
  );
  if (choice == null || !context.mounted) return;

  if (choice == PaymentMethodOption.qareebCard) {
    onQareeb();
    return;
  }
  if (choice == PaymentMethodOption.bankCard) {
    MoamalatOptions options;
    try {
      options = await env.api.options();
    } catch (_) {
      options = MoamalatOptions.unavailable;
    }
    if (!context.mounted) return;
    if (!options.available) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(env.t('الدفع بالبطاقة البنكية غير متاح الآن', 'Bank card payment is not available right now')),
      ));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MoamalatTopUpPage(env: env, options: options, checkoutViewBuilder: checkoutViewBuilder),
    ));
  }
}

class AddMoneySheet extends StatefulWidget {
  const AddMoneySheet({super.key, required this.env});

  final MoamalatEnv env;

  @override
  State<AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<AddMoneySheet> {
  List<PaymentMethodOption>? _methods;
  bool _offline = false;

  MoamalatEnv get env => widget.env;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final methods = await env.api.methods();
      if (mounted) setState(() => _methods = methods);
    } catch (_) {
      // Server unreachable: the manual recharge-card entry always worked
      // without it, so keep that available; the bank card needs the server.
      if (mounted) {
        setState(() {
          _methods = PaymentMethodOption.offlineFallback;
          _offline = true;
        });
      }
    }
  }

  IconData _icon(String key) =>
      key == PaymentMethodOption.bankCard ? Icons.credit_card_rounded : Icons.confirmation_number_outlined;

  String _subtitle(String key) => key == PaymentMethodOption.bankCard
      ? env.t('ادفع ببطاقتك المصرفية بأمان', 'Pay securely with your bank card')
      : env.t('أدخل رمز بطاقة الشحن', 'Enter your recharge card code');

  @override
  Widget build(BuildContext context) {
    final methods = _methods;
    return Directionality(
      textDirection: env.direction,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: env.border, borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 14),
            Text(env.t('إضافة فلوس', 'Add money'), textAlign: TextAlign.center, style: env.style(size: 18, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(env.t('اختر طريقة الإضافة', 'Choose how to add money'),
                textAlign: TextAlign.center, style: env.style(size: 12.5, weight: FontWeight.w500, color: env.muted)),
            const SizedBox(height: 16),
            if (methods == null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
            else if (methods.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(env.t('لا توجد طرق إضافة متاحة في منطقتك حالياً', 'No ways to add money are available in your area yet'),
                    key: const Key('no-methods'), textAlign: TextAlign.center, style: env.style(size: 13, color: env.muted)),
              )
            else
              for (final method in methods) ...[
                _MethodTile(
                  env: env,
                  method: method,
                  icon: _icon(method.key),
                  subtitle: _subtitle(method.key),
                  onTap: () => Navigator.of(context).pop(method.key),
                ),
                const SizedBox(height: 10),
              ],
            if (_offline)
              Text(env.t('تعذّر الاتصال بالخادم. تظهر الطرق الأساسية فقط.', 'Could not reach the server. Only the basic option is shown.'),
                  textAlign: TextAlign.center, style: env.style(size: 11.5, weight: FontWeight.w500, color: env.muted)),
          ]),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.env, required this.method, required this.icon, required this.subtitle, required this.onTap});

  final MoamalatEnv env;
  final PaymentMethodOption method;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: env.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('method-${method.key}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: env.border)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: env.accent.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: env.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(env.isRtl ? method.labelAr : method.labelEn, style: env.style(size: 15, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: env.style(size: 12, weight: FontWeight.w500, color: env.muted)),
              ]),
            ),
            Icon(env.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: env.muted),
          ]),
        ),
      ),
    );
  }
}
