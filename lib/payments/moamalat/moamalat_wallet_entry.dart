import 'package:flutter/material.dart';

import 'moamalat_api.dart';
import 'moamalat_env.dart';
import 'moamalat_topup_page.dart';

/// The "Moamalat - secure online payment" row on the wallet page. It renders
/// nothing unless the server says Moamalat is available for this wallet's
/// market and currency (e.g. Libya / LYD), so a market Moamalat cannot settle
/// never sees a payment method that would fail.
class MoamalatWalletEntry extends StatefulWidget {
  const MoamalatWalletEntry({super.key, required this.env, this.width});

  final MoamalatEnv env;
  final double? width;

  @override
  State<MoamalatWalletEntry> createState() => _MoamalatWalletEntryState();
}

class _MoamalatWalletEntryState extends State<MoamalatWalletEntry> {
  MoamalatOptions? _options;

  MoamalatEnv get env => widget.env;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final options = await env.api.options();
      if (mounted) setState(() => _options = options);
    } catch (_) {
      // Unreachable server: keep the entry hidden rather than showing a
      // payment method that cannot start.
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    if (options == null || !options.available) return const SizedBox.shrink();

    return Directionality(
      textDirection: env.direction,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: widget.width,
          child: Material(
            color: env.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: const Key('moamalat-entry'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MoamalatTopUpPage(env: env, options: options))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: env.border)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: env.accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.lock_rounded, size: 20, color: env.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(env.t('معاملات', 'Moamalat'), style: env.style(size: 14.5, weight: FontWeight.w800)),
                      Text(env.t('الدفع الإلكتروني الآمن', 'Secure online payment'),
                          style: env.style(size: 12, weight: FontWeight.w500, color: env.muted)),
                    ]),
                  ),
                  Icon(env.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: env.muted),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
