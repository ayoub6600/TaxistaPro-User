import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sending a booking over a connection that may be weak.
///
/// On a weak connection the booking can reach the server while its answer
/// never reaches the phone. Every send of one booking carries the same
/// `client_request_id`, and the server answers a repeat with the ride that id
/// already created (BookingReplay on the backend), so resending is safe: the
/// rider never ends up with two rides, and a ride that was created is never
/// lost behind a spinner.
class BookingSend {
  BookingSend._();

  /// How many times one booking is sent before the rider is told.
  static const attempts = 3;

  /// One send waits this long for an answer.
  static const timeout = Duration(seconds: 20);

  /// Which send is running now (1-based), for the waiting screen; 0 = idle.
  static final ValueNotifier<int> attempt = ValueNotifier<int>(0);

  /// The JSON booking body with this booking's own id added.
  static String withBookingId(String body, String bookingId) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return body;
      return jsonEncode({...decoded, 'client_request_id': bookingId});
    } catch (_) {
      return body;
    }
  }

  /// A failure that means "the answer did not arrive", not "the server said no".
  static bool isConnectionFailure(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is HandshakeException ||
      error is http.ClientException;

  /// Sends [post] until an answer arrives, up to [tries] times, waiting a
  /// little longer before each new try. Returns null when no answer ever
  /// arrived; any other error is rethrown at once.
  static Future<http.Response?> send(
    Future<http.Response> Function() post, {
    int tries = attempts,
    Duration perTry = timeout,
    Duration Function(int failed)? pause,
  }) async {
    pause ??= (failed) => Duration(seconds: 2 * failed);
    try {
      for (var i = 1; i <= tries; i++) {
        attempt.value = i;
        try {
          return await post().timeout(perTry);
        } catch (error) {
          if (!isConnectionFailure(error)) rethrow;
          if (i < tries) await Future<void>.delayed(pause(i));
        }
      }
      return null;
    } finally {
      attempt.value = 0;
    }
  }
}
