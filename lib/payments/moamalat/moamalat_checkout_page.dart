import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'card_helper_panel.dart';
import 'moamalat_api.dart';
import 'moamalat_env.dart';
import 'saved_card.dart';
import 'smart_fill_assistant.dart';
import 'smart_fill_controller.dart';
import 'topup_flow.dart';

/// Builds the payment page view. The default is a real WebView; tests inject
/// a stand-in so the page's behaviour can be checked without a platform view.
typedef PaymentViewBuilder = Widget Function(
  BuildContext context, {
  required String url,
  required void Function(String message) onMessage,
  required VoidCallback onLoaded,
  required void Function(String description) onLoadError,
});

enum _Phase { paying, settling, done }

/// The secure Moamalat payment page inside the app, with the saved-card helper
/// above it. It only relays what the page says; the wallet is credited by the
/// server, and this screen reports success only once the server confirms it.
class MoamalatCheckoutPage extends StatefulWidget {
  const MoamalatCheckoutPage({
    super.key,
    required this.env,
    required this.topUp,
    this.card,
    this.cardOnFile = false,
    this.smartFill,
    this.allowedMainFrameSchemes = const {'https', 'about'},
    this.viewBuilder,
    this.settleTimeout = const Duration(seconds: 30),
    this.loadTimeout = const Duration(seconds: 30),
    this.autoCloseAfter = const Duration(milliseconds: 2500),
  });

  final MoamalatEnv env;
  final MoamalatTopUp topUp;
  /// The selected saved card as a redacted copy (last four digits only). The
  /// real number is read from the vault only when the customer taps a fill action.
  final SavedCard? card;

  /// Tests inject a ready-made controller; the app builds its own from [MoamalatEnv.smartFill].
  final SmartFillController? smartFill;

  /// Schemes the payment page itself may navigate to. Always https in the app; the
  /// local test rig widens it.
  final Set<String> allowedMainFrameSchemes;

  /// The bank keeps cards for our customers: the payment page offers the saved
  /// ones, so the customer is told to pick theirs instead of typing a card.
  final bool cardOnFile;
  final PaymentViewBuilder? viewBuilder;
  final Duration settleTimeout;
  final Duration loadTimeout;

  /// After a confirmed payment the success screen shows this long, then the
  /// customer is returned to the wallet on their own.
  final Duration autoCloseAfter;

  @override
  State<MoamalatCheckoutPage> createState() => _MoamalatCheckoutPageState();
}

class _MoamalatCheckoutPageState extends State<MoamalatCheckoutPage> {
  _Phase _phase = _Phase.paying;
  TopUpOutcome? _outcome;
  bool _loaded = false;
  bool _loadFailed = false;
  int _attempt = 0; // bumped to rebuild the web view on retry
  Timer? _loadTimer;
  Timer? _autoCloseTimer;
  SmartFillController? _smart;
  bool _ownsSmart = false;

  MoamalatEnv get env => widget.env;

  @override
  void initState() {
    super.initState();
    _smart = widget.smartFill;
    if (_smart == null && widget.card != null && env.smartFill != null) {
      final card = widget.card!;
      _smart = SmartFillController(support: env.smartFill!, fetchCard: () => env.vault.byId(card.id));
      _ownsSmart = true;
    }
    _armLoadTimer();
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _autoCloseTimer?.cancel();
    if (_ownsSmart) _smart?.dispose();
    // Never leave a card number on the clipboard after the payment screen.
    env.clipboard.clearNow();
    super.dispose();
  }

  void _armLoadTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer(widget.loadTimeout, () {
      if (mounted && !_loaded && _phase == _Phase.paying) setState(() => _loadFailed = true);
    });
  }

  void _retryLoad() {
    setState(() {
      _loaded = false;
      _loadFailed = false;
      _attempt++;
    });
    _armLoadTimer();
  }

  void _onMessage(String message) {
    if (_phase != _Phase.paying) return; // one verdict per attempt
    switch (message.trim()) {
      case 'done':
      case 'review':
        _settle(expectFinal: true);
        break;
      case 'error':
      case 'cancel':
        _settle(expectFinal: false);
        break;
    }
  }

  Future<void> _settle({required bool expectFinal}) async {
    setState(() => _phase = _Phase.settling);
    TopUpOutcome outcome;
    try {
      outcome = await TopUpFlow(env.api, maxWait: widget.settleTimeout).settle(widget.topUp.id, expectFinal: expectFinal);
    } catch (_) {
      outcome = TopUpOutcome.unconfirmed;
    }
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _phase = _Phase.done;
    });
    if (outcome == TopUpOutcome.paid) {
      env.clipboard.clearNow();
      // Money is in the wallet: show it, then go back without another tap.
      _autoCloseTimer?.cancel();
      _autoCloseTimer = Timer(widget.autoCloseAfter, () {
        if (mounted && _phase == _Phase.done) Navigator.of(context).pop(_outcome);
      });
    }
  }

  Future<void> _recheck() async {
    setState(() => _phase = _Phase.paying);
    await _settle(expectFinal: true);
  }

  Future<void> _requestClose() async {
    if (_phase == _Phase.settling) return;
    if (_phase == _Phase.done) {
      Navigator.of(context).pop(_outcome);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: env.direction,
        child: AlertDialog(
          title: Text(env.t('إغلاق صفحة الدفع؟', 'Close the payment page?'), style: env.style(size: 16, weight: FontWeight.w800)),
          content: Text(env.t('إن لم تُكمل الدفع فلن تُضاف أي أموال إلى محفظتك.', 'If you have not finished paying, nothing will be added to your wallet.'),
              style: env.style(size: 13, weight: FontWeight.w500, color: env.muted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(env.t('متابعة الدفع', 'Keep paying'))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(env.t('إغلاق', 'Close'))),
          ],
        ),
      ),
    );
    if (leave != true || !mounted) return;
    // The payment may have gone through just before the page was closed:
    // ask the server rather than assuming.
    await _settle(expectFinal: false);
    if (mounted) Navigator.of(context).pop(_outcome);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: Directionality(
        textDirection: env.direction,
        child: Scaffold(
          backgroundColor: env.background,
          appBar: AppBar(
            backgroundColor: env.background,
            elevation: 0,
            foregroundColor: env.text,
            leading: IconButton(key: const Key('checkout-close'), icon: const Icon(Icons.close_rounded), onPressed: _requestClose),
            title: Text(env.t('الدفع الإلكتروني الآمن', 'Secure online payment'), style: env.style(size: 16, weight: FontWeight.w800)),
          ),
          body: SafeArea(
            child: _phase == _Phase.done ? _result() : _paying(),
          ),
        ),
      ),
    );
  }

  Widget _paying() {
    final builder = widget.viewBuilder ?? _realView;
    return Stack(children: [
      Column(children: [
        if (_smart != null)
          AnimatedBuilder(
            animation: _smart!,
            builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
              SmartFillAssistant(env: env, controller: _smart!),
              if (widget.card != null && _smart!.showFallbackHelper) _helper(),
            ]),
          )
        else if (widget.card != null)
          _helper(),
        if (widget.card == null && widget.cardOnFile) _cardOnFileHint(),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: KeyedSubtree(
              key: ValueKey(_attempt),
              child: builder(
                context,
                url: widget.topUp.paymentUrl,
                onMessage: _onMessage,
                onLoaded: () {
                  if (mounted && !_loaded) setState(() => _loaded = true);
                },
                onLoadError: (_) {
                  if (mounted && !_loaded && !_loadFailed) setState(() => _loadFailed = true);
                },
              ),
            ),
          ),
        ),
      ]),
      if (!_loaded && !_loadFailed) const Center(child: CircularProgressIndicator()),
      if (_loadFailed && !_loaded)
        Positioned.fill(
          child: Container(
            color: env.background,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: env.muted),
              const SizedBox(height: 12),
              Text(env.t('تعذّر فتح صفحة الدفع', 'Could not open the payment page'), style: env.style(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(env.t('تحقق من اتصالك بالإنترنت ثم أعد المحاولة.', 'Check your internet connection and try again.'),
                  textAlign: TextAlign.center, style: env.style(size: 13, weight: FontWeight.w500, color: env.muted)),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('retry-load'),
                style: FilledButton.styleFrom(backgroundColor: env.accent),
                onPressed: _retryLoad,
                child: Text(env.t('إعادة المحاولة', 'Try again')),
              ),
            ]),
          ),
        ),
      if (_phase == _Phase.settling)
        Positioned.fill(
          child: Container(
            key: const Key('settling'),
            color: env.background.withOpacity(0.94),
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(env.t('جارٍ تأكيد الدفع…', 'Confirming your payment…'), style: env.style(size: 15, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(env.t('لا تُغلق هذه الصفحة.', 'Please keep this page open.'), style: env.style(size: 12.5, weight: FontWeight.w500, color: env.muted)),
            ]),
          ),
        ),
    ]);
  }

  Widget _helper() {
    final card = widget.card!;
    return CardHelperPanel(env: env, card: card, fetchCard: () => env.vault.byId(card.id));
  }

  Widget _cardOnFileHint() {
    return Container(
      key: const Key('card-on-file-hint'),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: env.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.credit_score_rounded, size: 18, color: env.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            env.t('إن ظهرت بطاقتك المحفوظة لدى البنك فاخترها وأدخل رمز الأمان (CVV) فقط.',
                'If your card saved with the bank appears, pick it and enter only the security code (CVV).'),
            style: env.style(size: 12, weight: FontWeight.w600, color: env.text),
          ),
        ),
      ]),
    );
  }

  Widget _result() {
    final outcome = _outcome ?? TopUpOutcome.unconfirmed;
    final IconData icon;
    final Color color;
    final String title;
    final String body;
    switch (outcome) {
      case TopUpOutcome.paid:
        icon = Icons.check_circle_rounded;
        color = const Color(0xff0E8A4B);
        title = env.t('تمت إضافة الرصيد', 'Balance added');
        body = env.t('تمت إضافة ${_amountText()} إلى محفظتك.', '${_amountText()} was added to your wallet.');
        break;
      case TopUpOutcome.notPaid:
        icon = Icons.cancel_rounded;
        color = const Color(0xffD92D20);
        title = env.t('لم تكتمل عملية الدفع', 'Payment was not completed');
        body = env.t('لم تُضف أي أموال إلى محفظتك. يمكنك المحاولة مرة أخرى.', 'Nothing was added to your wallet. You can try again.');
        break;
      case TopUpOutcome.unconfirmed:
        icon = Icons.hourglass_top_rounded;
        color = const Color(0xffC26A00);
        title = env.t('لم نتمكن من تأكيد الدفع بعد', 'We could not confirm the payment yet');
        body = env.t(
            'لم تُضف أي أموال إلى محفظتك حتى الآن. إن تم خصم المبلغ من بطاقتك فتواصل مع الدعم مع ذكر رقم العملية: ${widget.topUp.reference}',
            'Nothing has been added to your wallet yet. If your card was charged, contact support with reference ${widget.topUp.reference}.');
        break;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(title, key: const Key('result-title'), textAlign: TextAlign.center, style: env.style(size: 19, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body, key: const Key('result-body'), textAlign: TextAlign.center, style: env.style(size: 13.5, weight: FontWeight.w500, color: env.muted)),
          const SizedBox(height: 24),
          if (outcome == TopUpOutcome.paid) ...[
            Text(env.t('نعيدك إلى المحفظة…', 'Taking you back to your wallet…'),
                key: const Key('auto-return-note'), style: env.style(size: 12, weight: FontWeight.w600, color: env.muted)),
            const SizedBox(height: 12),
          ],
          if (outcome == TopUpOutcome.unconfirmed)
            OutlinedButton(
              key: const Key('recheck'),
              onPressed: _recheck,
              child: Text(env.t('تحقق مرة أخرى', 'Check again')),
            ),
          FilledButton(
            key: const Key('result-done'),
            style: FilledButton.styleFrom(backgroundColor: env.accent, minimumSize: const Size(180, 48)),
            onPressed: () => Navigator.of(context).pop(_outcome),
            child: Text(outcome == TopUpOutcome.notPaid ? env.t('حسناً', 'OK') : env.t('تم', 'Done'), style: env.style(size: 15, weight: FontWeight.w800, color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  String _amountText() {
    final a = widget.topUp.amount;
    return '${a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toStringAsFixed(2)} ${widget.topUp.currency}';
  }

  /// The real payment view: a WebView with a JS channel the hosted page uses
  /// to say what the gateway reported (and, for Smart Fill, the native frame bridge).
  Widget _realView(BuildContext context, {required String url, required void Function(String message) onMessage, required VoidCallback onLoaded, required void Function(String description) onLoadError}) {
    return _PlatformPaymentView(
      url: url,
      onMessage: onMessage,
      onLoaded: onLoaded,
      onLoadError: onLoadError,
      smart: _smart,
      allowedSchemes: widget.allowedMainFrameSchemes,
    );
  }
}

class _PlatformPaymentView extends StatefulWidget {
  const _PlatformPaymentView({
    required this.url,
    required this.onMessage,
    required this.onLoaded,
    required this.onLoadError,
    this.smart,
    this.allowedSchemes = const {'https', 'about'},
  });

  final SmartFillController? smart;
  final Set<String> allowedSchemes;
  final String url;
  final void Function(String message) onMessage;
  final VoidCallback onLoaded;
  final void Function(String description) onLoadError;

  @override
  State<_PlatformPaymentView> createState() => _PlatformPaymentViewState();
}

class _PlatformPaymentViewState extends State<_PlatformPaymentView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('PaymentChannel', onMessageReceived: (m) => widget.onMessage(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => widget.onLoaded(),
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) widget.onLoadError(error.description);
        },
        onNavigationRequest: (request) {
          // Frames inside the payment page are the gateway's business; the
          // page itself may only ever move to https.
          if (!request.isMainFrame) return NavigationDecision.navigate;
          final scheme = Uri.tryParse(request.url)?.scheme ?? '';
          return widget.allowedSchemes.contains(scheme) ? NavigationDecision.navigate : NavigationDecision.prevent;
        },
      ));
    _start();
  }

  /// Smart Fill's frame script must be in place BEFORE the page loads, so the
  /// native side is connected first and the page is requested afterwards.
  Future<void> _start() async {
    final smart = widget.smart;
    if (smart != null) {
      final id = _nativeId(_controller);
      if (id == null) {
        smart.markUnsupported();
      } else {
        await smart.attach(id);
      }
    }
    if (!mounted) return;
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  static int? _nativeId(WebViewController controller) {
    final platform = controller.platform;
    if (platform is WebKitWebViewController) return platform.webViewIdentifier;
    if (platform is AndroidWebViewController) return platform.webViewIdentifier;
    return null;
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
