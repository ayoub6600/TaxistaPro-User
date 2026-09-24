import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Normalises a dial code ("+218", "218", " +20 ") to the canonical
/// `+<digits>` form the backend expects. Returns an empty string when there are
/// no digits to work with.
String normalizeDialCode(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? '' : '+$digits';
}

/// Strips everything except digits from a phone number typed by the rider
/// (spaces, dashes, a pasted "+"). The leading trunk zero is left alone - the
/// backend normalises it.
String localDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

/// Why a forgot-password call did not succeed. The screen picks its behaviour
/// from this, never from the (server-localised) message text.
enum RiderResetFailure {
  /// 422 - wrong/expired code, no rider with that phone, weak password, ...
  validation,

  /// 422 on `reset_token` only - the token from the OTP step has expired or
  /// was already used, so the rider must request a new code.
  resetTokenInvalid,

  /// 400 or 429 - resend cooldown / attempt caps / the provider refused to
  /// send. Show the message, never retry automatically.
  rateLimited,

  /// The request never reached the server (offline, DNS, timeout).
  network,

  /// Anything else: 5xx, an unparseable body, a 200 without the expected data.
  server,
}

/// Outcome of one call. [message] is the server's own text when it sent one
/// (already localised server-side); null means the screen should fall back to
/// its own translated string.
class RiderResetResult<T> {
  const RiderResetResult.success([this.data])
      : failure = null,
        message = null,
        field = null;

  const RiderResetResult.failure(this.failure, {this.message, this.field})
      : data = null;

  final T? data;
  final RiderResetFailure? failure;
  final String? message;

  /// The request field the first validation error was reported against.
  final String? field;

  bool get ok => failure == null;
}

/// Client for the Rider forgot-password contract under
/// `/api/v1/password/rider/`: phone + country -> `send-otp` -> `verify-otp`
/// (answers with a short-lived, single-use `reset_token`) -> `reset`.
///
/// This is the only place a rider ever uses an OTP to get into their account:
/// normal sign-in is always phone (or email) + password. The client only talks
/// to our own backend - the verification provider's credentials live
/// server-side and never here - and it logs nothing: `verify-otp` answers with
/// a reset token that must not reach any log.
class RiderPasswordResetApi {
  RiderPasswordResetApi({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  /// Backend root with a trailing slash, e.g. `https://example.com/`.
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  /// Step 1 - ask the backend to send a verification code to the rider's phone.
  Future<RiderResetResult<void>> sendOtp({
    required String country,
    required String mobile,
  }) async {
    final response = await _post('send-otp', {
      'country': normalizeDialCode(country),
      'mobile': localDigits(mobile),
    });
    return response.failure != null
        ? RiderResetResult.failure(response.failure!,
            message: response.message, field: response.field)
        : const RiderResetResult.success();
  }

  /// Step 2 - check the code. On success [RiderResetResult.data] is the opaque
  /// `reset_token` for step 3. It is not an OTP: hold it in memory only.
  Future<RiderResetResult<String>> verifyOtp({
    required String country,
    required String mobile,
    required String otp,
  }) async {
    final response = await _post('verify-otp', {
      'country': normalizeDialCode(country),
      'mobile': localDigits(mobile),
      'otp': otp.trim(),
    });
    if (response.failure != null) {
      return RiderResetResult.failure(response.failure!,
          message: response.message, field: response.field);
    }
    final data = response.body?['data'];
    final token = data is Map ? data['reset_token'] : null;
    if (token is! String || token.isEmpty) {
      return const RiderResetResult.failure(RiderResetFailure.server);
    }
    return RiderResetResult.success(token);
  }

  /// Step 3 - redeem the reset token for a new password. No session is issued;
  /// the rider signs in normally afterwards.
  Future<RiderResetResult<void>> reset({
    required String country,
    required String mobile,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _post('reset', {
      'country': normalizeDialCode(country),
      'mobile': localDigits(mobile),
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    if (response.failure == null) return const RiderResetResult.success();
    // A 422 on reset_token means "expired or already used" specifically;
    // password problems (too short, mismatch) stay plain validation errors.
    final failure = response.failure == RiderResetFailure.validation &&
            response.field == 'reset_token'
        ? RiderResetFailure.resetTokenInvalid
        : response.failure!;
    return RiderResetResult.failure(failure,
        message: response.message, field: response.field);
  }

  void close() => _client.close();

  Future<_RawResponse> _post(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${baseUrl}api/v1/password/rider/$path'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      return const _RawResponse.failure(RiderResetFailure.network);
    } on SocketException {
      return const _RawResponse.failure(RiderResetFailure.network);
    } on http.ClientException {
      return const _RawResponse.failure(RiderResetFailure.network);
    }

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } on FormatException {
      json = null;
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (json != null && json['success'] == true) {
        return _RawResponse.success(json);
      }
      return _RawResponse.failure(RiderResetFailure.server,
          message: _messageOf(json));
    }
    if (status == 422) {
      final first = _firstValidationError(json);
      return _RawResponse.failure(RiderResetFailure.validation,
          message: first.message ?? _messageOf(json), field: first.field);
    }
    if (status == 400 || status == 429) {
      return _RawResponse.failure(RiderResetFailure.rateLimited,
          message: _messageOf(json));
    }
    return _RawResponse.failure(RiderResetFailure.server,
        message: _messageOf(json));
  }

  static String? _messageOf(Map<String, dynamic>? json) {
    final message = json?['message'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        : null;
  }

  /// Laravel-style `errors: { field: ["msg", ...] }`; returns the first field
  /// and its first message.
  static ({String? field, String? message}) _firstValidationError(
      Map<String, dynamic>? json) {
    final errors = json?['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final entry = errors.entries.first;
      final value = entry.value;
      final message = value is List && value.isNotEmpty
          ? value.first?.toString()
          : value?.toString();
      return (
        field: entry.key.toString(),
        message:
            (message == null || message.trim().isEmpty) ? null : message.trim(),
      );
    }
    return (field: null, message: null);
  }
}

class _RawResponse {
  const _RawResponse.success(this.body)
      : failure = null,
        message = null,
        field = null;

  const _RawResponse.failure(this.failure, {this.message, this.field})
      : body = null;

  final Map<String, dynamic>? body;
  final RiderResetFailure? failure;
  final String? message;
  final String? field;
}
