// Developer-only entry point (never part of the shipped app): opens the REAL Moamalat
// checkout page + Smart Fill against the local test rig, with synthetic cards.
//
//   flutter run -t tool/smart_fill_dev/main.dart \
//     --dart-define=CHECKOUT_URL=http://127.0.0.1:18101/old.html \
//     --dart-define=SMARTFILL_ORIGINS=http://127.0.0.1:18102 \
//     --dart-define=AUTO_OPEN=A
//
// Synthetic, obviously fake cards only. Never a real card.
import 'package:flutter/material.dart';
import 'package:taxista/payments/moamalat/card_vault.dart';
import 'package:taxista/payments/moamalat/moamalat_api.dart';
import 'package:taxista/payments/moamalat/moamalat_checkout_page.dart';
import 'package:taxista/payments/moamalat/moamalat_env.dart';
import 'package:taxista/payments/moamalat/saved_card.dart';
import 'package:taxista/payments/moamalat/secure_clipboard.dart';
import 'package:taxista/payments/moamalat/smart_fill_bridge.dart';
import 'package:taxista/payments/moamalat/smart_fill_controller.dart';

const String kUrl = String.fromEnvironment('CHECKOUT_URL', defaultValue: 'http://127.0.0.1:18101/old.html');
const String kOrigins = String.fromEnvironment('SMARTFILL_ORIGINS', defaultValue: 'http://127.0.0.1:18102');
const String kAuto = String.fromEnvironment('AUTO_OPEN'); // A | B | none
const String kAsset = String.fromEnvironment('ASSISTANT_ASSET', defaultValue: 'assets/images/driver_offer_mascot.png');

class _FakeApi implements MoamalatApi {
  @override
  Future<List<PaymentMethodOption>> methods() async => PaymentMethodOption.offlineFallback;
  @override
  Future<MoamalatOptions> options() async => const MoamalatOptions(available: true, currency: 'LYD', minAmount: 5, maxAmount: 2000);
  @override
  Future<MoamalatTopUp> initiate(double amount) async => MoamalatTopUp(id: 'DEV', reference: 'DEVREF', amount: amount, currency: 'LYD', paymentUrl: kUrl);
  @override
  Future<MoamalatStatus> status(String topUpId) async => const MoamalatStatus(status: 'pending', credited: false);
}

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: _Dev()));

class _Dev extends StatefulWidget {
  const _Dev();
  @override
  State<_Dev> createState() => _DevState();
}

class _DevState extends State<_Dev> {
  late final MoamalatEnv env;
  SavedCard? a, b;

  @override
  void initState() {
    super.initState();
    env = MoamalatEnv(
      api: _FakeApi(),
      vault: CardVault(store: MemorySecretStore(), ownerId: 'dev'),
      clipboard: SecureClipboard(),
      isRtl: true,
      smartFill: SmartFillSupport(bridge: ChannelSmartFillBridge.instance, assistantAsset: kAsset, origins: kOrigins.split(',')),
    );
    _seed();
  }

  Future<void> _seed() async {
    final one = await env.vault.add(holderName: 'TEST USER', number: '4111111111111111', expMonth: 12, expYear: 2030);
    final two = await env.vault.add(holderName: 'TEST TWO', number: '5555555555554444', expMonth: 11, expYear: 2031);
    setState(() {
      a = one.redacted();
      b = two.redacted();
    });
    if (kAuto == 'A') _open(a);
    if (kAuto == 'B') _open(b);
  }

  Future<void> _open(SavedCard? card) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MoamalatCheckoutPage(
        env: env,
        card: card,
        topUp: MoamalatTopUp(id: 'DEV', reference: 'DEVREF', amount: 25, currency: 'LYD', paymentUrl: kUrl),
        allowedMainFrameSchemes: const {'http', 'https', 'about'},
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Smart Fill dev rig')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FilledButton(key: const Key('open-a'), onPressed: a == null ? null : () => _open(a), child: const Text('Checkout with card A (4111…1111)')),
            const SizedBox(height: 12),
            FilledButton(key: const Key('open-b'), onPressed: b == null ? null : () => _open(b), child: const Text('Checkout with card B (5555…4444)')),
            const SizedBox(height: 12),
            OutlinedButton(key: const Key('open-none'), onPressed: () => _open(null), child: const Text('Checkout with NO saved card')),
          ]),
        ),
      );
}
