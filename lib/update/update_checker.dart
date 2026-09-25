import 'dart:async';
import 'dart:convert';

import 'update_policy.dart';

enum UpdateSource { network, cache, none }

class UpdateCheckResult {
  const UpdateCheckResult(this.decision, this.policy, this.source);

  final UpdateDecision decision;
  final UpdatePolicy? policy;
  final UpdateSource source;
}

/// Reads the app's update policy and turns it into exactly one decision, on
/// any network:
///  - live policy when the endpoint answers within [timeout];
///  - otherwise the last policy seen (so a mandatory update stays mandatory
///    on a bad connection) without waiting for a retry;
///  - with no cached policy, one retry after [retryDelay];
///  - and if that also fails the app simply opens: a version check must never
///    leave startup hanging or the app unusable.
/// It never throws and always finishes in a bounded time.
class UpdateChecker {
  UpdateChecker({
    required this.fetch,
    required this.readCache,
    required this.writeCache,
    this.timeout = const Duration(seconds: 4),
    this.retryDelay = const Duration(seconds: 1),
  });

  /// Returns the raw policy map, or null when the node does not exist. Throws
  /// (or times out) when the backend cannot be reached.
  final Future<Map<dynamic, dynamic>?> Function() fetch;
  final Future<String?> Function() readCache;
  final Future<void> Function(String json) writeCache;
  final Duration timeout;
  final Duration retryDelay;

  Future<UpdateCheckResult> check({
    required String installedVersion,
    required int installedBuild,
    required bool isIos,
  }) async {
    UpdateCheckResult decide(UpdatePolicy policy, UpdateSource source) =>
        UpdateCheckResult(
          policy.evaluate(
            installedVersion: installedVersion,
            installedBuild: installedBuild,
            isIos: isIos,
          ),
          policy,
          source,
        );

    var live = await _tryFetch();
    if (live == null) {
      final cached = await _cachedPolicy();
      if (cached != null) return decide(cached, UpdateSource.cache);
      await Future<void>.delayed(retryDelay);
      live = await _tryFetch();
    }
    if (live == null) {
      return const UpdateCheckResult(UpdateDecision.none, null, UpdateSource.none);
    }

    final policy = UpdatePolicy.fromMap(live.data);
    unawaited(_remember(policy));
    return decide(policy, UpdateSource.network);
  }

  Future<_Fetched?> _tryFetch() async {
    try {
      final data = await fetch().timeout(timeout);
      return _Fetched(data ?? const {});
    } catch (_) {
      return null;
    }
  }

  Future<UpdatePolicy?> _cachedPolicy() async {
    try {
      final raw = await readCache();
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? UpdatePolicy.fromMap(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _remember(UpdatePolicy policy) async {
    try {
      await writeCache(jsonEncode(policy.toJson()));
    } catch (_) {}
  }
}

class _Fetched {
  const _Fetched(this.data);

  final Map<dynamic, dynamic> data;
}
