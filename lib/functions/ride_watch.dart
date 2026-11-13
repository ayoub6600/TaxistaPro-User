import 'dart:async';

import 'functions.dart' show getUserDetails, userRequestData;

/// A request made from its own page (a parcel, a tow…) has no searching screen of its own: look
/// every 8 seconds, for 3 minutes, until a driver took it — the home screen then turns into the
/// ride, as for any ride.
class RideWatch {
  static Timer? _t;

  static void untilDriver() {
    _t?.cancel();
    var left = 22;
    unawaited(Future(() => getUserDetails()));
    _t = Timer.periodic(const Duration(seconds: 8), (t) async {
      if (--left <= 0 || userRequestData.isNotEmpty) {
        t.cancel();
        return;
      }
      await getUserDetails();
      if (userRequestData.isNotEmpty) t.cancel();
    });
  }
}
