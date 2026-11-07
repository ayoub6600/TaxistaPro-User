import 'package:flutter/foundation.dart';

import 'game_core.dart';
import 'progress.dart';

/// Ride state as the games see it. The host builds it from its own ride data and
/// passes a [ValueListenable]; the games only listen and never change the ride.
class RideGameStatus {
  const RideGameStatus({
    required this.phase,
    required this.onBackToTrip,
    this.driverName,
    this.etaText,
    this.carText,
    this.onCall,
    this.onChat,
  });

  /// searching | accepted | approaching | arrived | on_trip | cancelled
  final String phase;
  final String? driverName;
  final String? etaText;
  final String? carText;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback onBackToTrip;

  bool get isWaiting => phase == 'searching' || phase == 'accepted' || phase == 'approaching';

  /// The games must close: the trip takes priority.
  bool get mustClose => phase == 'arrived' || phase == 'on_trip' || phase == 'cancelled';

  RideGameStatus copyWith({String? phase, String? driverName, String? etaText, String? carText}) => RideGameStatus(
        phase: phase ?? this.phase,
        driverName: driverName ?? this.driverName,
        etaText: etaText ?? this.etaText,
        carText: carText ?? this.carText,
        onCall: onCall,
        onChat: onChat,
        onBackToTrip: onBackToTrip,
      );
}

/// Owns the current round outside the widget tree, so the same round continues
/// when the box is enlarged, the device rotates, or the ride sheet is swapped.
class WaitingGamesController extends ChangeNotifier {
  WaitingGamesController({GameProgress? progress}) : progress = progress ?? GameProgress.instance;

  final GameProgress progress;
  GameSession? session;
  GameResult? result;
  List<String> earned = const [];
  bool fullScreenOpen = false;
  bool approachDismissed = false;
  bool _disposed = false;

  bool get playing => session != null;

  void play(TaxistaGame game) {
    result = null;
    earned = const [];
    session = GameSession(
      game: game,
      level: progress.level(game.id),
      skin: progress.skinColor,
      onFinish: _onFinish,
    );
    progress.touch(game.id);
    _notify();
  }

  void tapToStart() {
    final s = session;
    if (s == null || s.finished) return;
    s.awaiting.value = false;
    s.paused.value = false;
    _notify();
  }

  /// Freeze the round. The next tap continues without losing time.
  void pause([String text = 'اضغط باش تكمّل']) {
    final s = session;
    if (s == null) return;
    s.paused.value = true;
    if (!s.finished) {
      s.awaitingText = text;
      s.awaiting.value = true;
    }
    _notify();
  }

  void _onFinish(GameResult r) {
    final s = session;
    if (s == null) return;
    result = r;
    earned = progress.record(s.game, r);
    _notify();
  }

  void playAgain() {
    final s = session;
    if (s != null) play(s.game);
  }

  void toPicker() {
    pause();
    session = null;
    result = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
