import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class MoamalatOptions {
  const MoamalatOptions({
    required this.available,
    this.currency,
    this.minAmount = 0,
    this.maxAmount = 0,
  });

  final bool available;
  final String? currency;
  final double minAmount;
  final double maxAmount;

  static const unavailable = MoamalatOptions(available: false);
}

class MoamalatTopUp {
  const MoamalatTopUp({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.paymentUrl,
  });

  final String id;
  final String reference;
  final double amount;
  final String currency;
  final String paymentUrl;
}

/// The server's verdict on a top-up. Only [credited] means money reached the
/// wallet - the app never decides that itself.
class MoamalatStatus {
  const MoamalatStatus({required this.status, required this.credited});

  final String status; // pending | paid | failed | cancelled | needs_review
  final bool credited;

  bool get isFinal => status == 'paid' || status == 'failed' || status == 'cancelled';
}

enum MoamalatErrorKind { network, unauthorized, unavailable, invalidAmount, server }

class MoamalatException implements Exception {
  const MoamalatException(this.kind);

  final MoamalatErrorKind kind;

  @override
  String toString() => 'MoamalatException($kind)';
}

abstract class MoamalatApi {
  Future<MoamalatOptions> options();
  Future<MoamalatTopUp> initiate(double amount);
  Future<MoamalatStatus> status(String topUpId);
}

/// Talks to `POST /api/v1/payment/moamalat/*` with the signed-in user's token.
class HttpMoamalatApi implements MoamalatApi {
  HttpMoamalatApi({
    required this.baseUrl,
    required this.token,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  /// The app's API root, ending with `/`.
  final String baseUrl;
  final String Function() token;
  final Duration timeout;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${token()}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      final response = await call().timeout(timeout);
      if (response.statusCode == 401) {
        throw const MoamalatException(MoamalatErrorKind.unauthorized);
      }
      return response;
    } on MoamalatException {
      rethrow;
    } on SocketException {
      throw const MoamalatException(MoamalatErrorKind.network);
    } on TimeoutException {
      throw const MoamalatException(MoamalatErrorKind.network);
    } on http.ClientException {
      throw const MoamalatException(MoamalatErrorKind.network);
    }
  }

  Map<String, dynamic> _body(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<MoamalatOptions> options() async {
    final response = await _send(() => _client.get(Uri.parse('${baseUrl}api/v1/payment/moamalat/options'), headers: _headers));
    if (response.statusCode != 200) return MoamalatOptions.unavailable;
    final data = _body(response)['data'];
    if (data is! Map) return MoamalatOptions.unavailable;
    return MoamalatOptions(
      available: data['available'] == true,
      currency: data['currency']?.toString(),
      minAmount: double.tryParse(data['min_amount']?.toString() ?? '') ?? 0,
      maxAmount: double.tryParse(data['max_amount']?.toString() ?? '') ?? 0,
    );
  }

  @override
  Future<MoamalatTopUp> initiate(double amount) async {
    final response = await _send(() => _client.post(
          Uri.parse('${baseUrl}api/v1/payment/moamalat/initiate'),
          headers: _headers,
          body: jsonEncode({'amount': amount}),
        ));
    if (response.statusCode == 403) throw const MoamalatException(MoamalatErrorKind.unavailable);
    if (response.statusCode == 400 || response.statusCode == 422) {
      throw const MoamalatException(MoamalatErrorKind.invalidAmount);
    }
    final data = _body(response)['data'];
    if (response.statusCode != 200 || data is! Map || data['payment_url'] == null) {
      throw const MoamalatException(MoamalatErrorKind.server);
    }
    return MoamalatTopUp(
      id: data['topup_id'].toString(),
      reference: data['reference']?.toString() ?? '',
      amount: double.tryParse(data['amount']?.toString() ?? '') ?? amount,
      currency: data['currency']?.toString() ?? '',
      paymentUrl: data['payment_url'].toString(),
    );
  }

  @override
  Future<MoamalatStatus> status(String topUpId) async {
    final response = await _send(() => _client.get(Uri.parse('${baseUrl}api/v1/payment/moamalat/$topUpId/status'), headers: _headers));
    final data = _body(response)['data'];
    if (response.statusCode != 200 || data is! Map) {
      throw const MoamalatException(MoamalatErrorKind.server);
    }
    return MoamalatStatus(status: data['status']?.toString() ?? 'pending', credited: data['credited'] == true);
  }
}
