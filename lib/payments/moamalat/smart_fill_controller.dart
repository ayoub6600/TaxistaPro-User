import 'dart:async';

import 'package:flutter/foundation.dart';

import 'card_fill_script.dart';
import 'saved_card.dart';
import 'smart_fill_bridge.dart';

/// What the assistant shows.
enum SmartFillPhase {
  /// This platform cannot do it: the classic copy helper is used instead.
  unsupported,

  /// Supported, but the Moamalat card form is not on screen (yet).
  waiting,

  /// The card form is on screen and a card is selected: offer "Smart Fill".
  ready,

  filling,

  /// Every intended operation succeeded.
  success,

  /// Something was not filled / accepted: nothing is claimed, retry offered.
  failed,
}

/// Host-app configuration of Smart Fill (shared by the Rider and Driver apps).
class SmartFillSupport {
  const SmartFillSupport({required this.bridge, required this.assistantAsset, this.origins = kMoamalatGatewayOrigins});

  final SmartFillBridge bridge;

  /// The app's own existing character image.
  final String assistantAsset;

  /// The exact gateway origins Smart Fill may operate on.
  final List<String> origins;
}

/// The state machine behind the assistant. It holds no card data: the selected
/// card is fetched from the encrypted vault only inside [fill], i.e. after the
/// customer's explicit tap, and dropped as soon as the bridge has it.
class SmartFillController extends ChangeNotifier {
  SmartFillController({
    required this.support,
    required this.fetchCard,
    this.formTimeout = const Duration(seconds: 20),
    this.collapseAfterSuccess = const Duration(milliseconds: 3500),
  });

  final SmartFillSupport support;

  /// Reads the selected card from the vault (called only on Smart Fill taps).
  final Future<SavedCard?> Function() fetchCard;
  final Duration formTimeout;
  final Duration collapseAfterSuccess;

  SmartFillPhase _phase = SmartFillPhase.waiting;
  SmartFillPhase get phase => _phase;

  SmartFillResult? _last;
  SmartFillResult? get lastResult => _last;

  /// The success panel shrinks to a slim chip after a moment.
  bool _collapsed = false;
  bool get collapsed => _collapsed;

  /// The classic copy helper is offered when Smart Fill cannot work here.
  bool _fallback = false;
  bool get showFallbackHelper => _fallback;

  int? _webViewId;
  StreamSubscription<SmartFillFrameEvent>? _sub;
  Timer? _formTimer;
  Timer? _collapseTimer;
  bool _disposed = false;

  /// Connects to the payment web view. Call before the page is loaded.
  Future<void> attach(int webViewId) async {
    _webViewId = webViewId;
    _sub?.cancel();
    _sub = support.bridge.events.where((e) => e.webViewId == webViewId).listen(_onFrame);
    final ok = await support.bridge.install(webViewId: webViewId, script: buildCardFillScript(support.origins), origins: support.origins);
    if (_disposed) return;
    if (!ok) {
      _phase = SmartFillPhase.unsupported;
      _fallback = true;
      notifyListeners();
      return;
    }
    _formTimer?.cancel();
    _formTimer = Timer(formTimeout, () {
      // No recognisable card form after a while: keep the customer moving with the classic helper.
      if (!_disposed && _phase == SmartFillPhase.waiting) {
        _fallback = true;
        notifyListeners();
      }
    });
  }

  /// The payment view cannot host the frame script (no native web view to attach to).
  void markUnsupported() {
    if (_disposed) return;
    _phase = SmartFillPhase.unsupported;
    _fallback = true;
    notifyListeners();
  }

  void _onFrame(SmartFillFrameEvent e) {
    if (_disposed) return;
    if (_phase == SmartFillPhase.filling) return; // our own typing must not flip the state
    if (e.state == SmartFillFrameState.ready) {
      _formTimer?.cancel();
      _collapseTimer?.cancel();
      // A (re)loaded form is empty: offer the fill again, never a stale success.
      _phase = SmartFillPhase.ready;
      _fallback = false;
      _collapsed = false;
      _last = null;
    } else {
      _collapseTimer?.cancel();
      _phase = SmartFillPhase.waiting;
      _collapsed = false;
    }
    notifyListeners();
  }

  /// The customer tapped "Smart Fill" (or "Retry").
  Future<void> fill() async {
    if (_disposed || _webViewId == null) return;
    if (_phase != SmartFillPhase.ready && _phase != SmartFillPhase.failed) return;
    _phase = SmartFillPhase.filling;
    _collapsed = false;
    notifyListeners();

    SmartFillResult result;
    try {
      SavedCard? card = await fetchCard();
      if (card == null) {
        result = SmartFillResult.error;
      } else {
        result = await support.bridge.fill(
          webViewId: _webViewId!,
          pan: card.number,
          exp: card.expiryText,
          name: card.holderName,
          acceptTerms: true,
        );
        card = null; // drop our reference
      }
    } catch (_) {
      result = SmartFillResult.error;
    }
    if (_disposed) return;
    _last = result;
    if (result.ok) {
      _phase = SmartFillPhase.success;
      _collapseTimer?.cancel();
      _collapseTimer = Timer(collapseAfterSuccess, () {
        if (!_disposed && _phase == SmartFillPhase.success) {
          _collapsed = true;
          notifyListeners();
        }
      });
    } else {
      _phase = SmartFillPhase.failed;
      _fallback = result.formNotRecognised;
    }
    notifyListeners();
  }

  /// The customer dismisses the assistant card into its slim chip.
  void collapse() {
    if (_disposed) return;
    _collapsed = true;
    notifyListeners();
  }

  void expand() {
    if (_disposed) return;
    _collapsed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _formTimer?.cancel();
    _collapseTimer?.cancel();
    final id = _webViewId;
    if (id != null) unawaited(support.bridge.dispose(id));
    super.dispose();
  }
}
