import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// The company account the customer transfers to, as the admin wrote it.
class LypayAccount {
  const LypayAccount({required this.bankName, required this.accountName, required this.iban, required this.accountNumber});

  final String bankName;
  final String accountName;
  final String iban;
  final String accountNumber;

  /// LY83 0020 0000 … : easier to compare with the bank app, copied without the spaces.
  String get ibanGrouped => iban.replaceAllMapped(RegExp(r'.{1,4}'), (m) => '${m[0]} ').trim();
}

/// One request on its way: sent → checking → approved, or rejected with the admin's reason.
class LypayRequest {
  const LypayRequest({
    required this.reference,
    required this.status,
    required this.amount,
    this.amountCredited,
    this.rejectReason,
    this.sentAt,
    this.checkingAt,
    this.reviewedAt,
  });

  final String reference;
  final String status; // sent | checking | approved | rejected
  final double amount;
  final double? amountCredited;
  final String? rejectReason;
  final DateTime? sentAt;
  final DateTime? checkingAt;
  final DateTime? reviewedAt;

  bool get isOpen => status == 'sent' || status == 'checking';

  static LypayRequest fromJson(Map j) {
    DateTime? at(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
    double? num0(Object? v) => v == null ? null : double.tryParse('$v');
    return LypayRequest(
      reference: '${j['reference']}',
      status: '${j['status']}',
      amount: num0(j['amount']) ?? 0,
      amountCredited: num0(j['amount_credited']),
      rejectReason: j['reject_reason']?.toString(),
      sentAt: at(j['sent_at']),
      checkingAt: at(j['checking_at']),
      reviewedAt: at(j['reviewed_at']),
    );
  }
}

class LypayInfo {
  const LypayInfo({required this.available, required this.account, required this.minAmount, this.openRequest});

  final bool available;
  final LypayAccount account;
  final double minAmount;
  final LypayRequest? openRequest;
}

class LypayException implements Exception {
  const LypayException(this.message);

  /// The server's own sentence when it gave one (Arabic), else null: the page says "no connection".
  final String? message;
}

abstract class LypayApi {
  Future<LypayInfo> info();
  Future<LypayRequest> submit(double amount, File receipt);
  Future<LypayRequest> status(String reference);
}

/// `GET|POST /api/v1/payment/lypay` with the signed-in user's token.
class HttpLypayApi implements LypayApi {
  HttpLypayApi({required this.baseUrl, required this.token, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final String Function() token;
  final http.Client _client;

  Map<String, String> get _headers => {'Authorization': 'Bearer ${token()}', 'Accept': 'application/json'};

  Map _data(http.Response r) {
    Map body = const {};
    try {
      final d = jsonDecode(r.body);
      if (d is Map) body = d;
    } catch (_) {}
    if (r.statusCode >= 200 && r.statusCode < 300 && body['data'] is Map) return body['data'] as Map;
    throw LypayException(body['message'] is String && r.statusCode < 500 ? body['message'] as String : null);
  }

  Future<http.Response> _guard(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw const LypayException(null);
    } on SocketException {
      throw const LypayException(null);
    } on http.ClientException {
      throw const LypayException(null);
    }
  }

  @override
  Future<LypayInfo> info() async {
    final d = _data(await _guard(() => _client.get(Uri.parse('${baseUrl}api/v1/payment/lypay'), headers: _headers)));
    final a = d['account'] is Map ? d['account'] as Map : const {};
    return LypayInfo(
      available: d['available'] == true,
      account: LypayAccount(
        bankName: '${a['bank_name'] ?? ''}',
        accountName: '${a['account_name'] ?? ''}',
        iban: '${a['iban'] ?? ''}',
        accountNumber: '${a['account_number'] ?? ''}',
      ),
      minAmount: double.tryParse('${d['min_amount']}') ?? 10,
      openRequest: d['open_request'] is Map ? LypayRequest.fromJson(d['open_request'] as Map) : null,
    );
  }

  @override
  Future<LypayRequest> submit(double amount, File receipt) async {
    final req = http.MultipartRequest('POST', Uri.parse('${baseUrl}api/v1/payment/lypay'))
      ..headers.addAll(_headers)
      ..fields['amount'] = amount.toStringAsFixed(2)
      ..files.add(await http.MultipartFile.fromPath('receipt', receipt.path));
    final r = await _guard(() async => http.Response.fromStream(await _client.send(req)));
    return LypayRequest.fromJson(_data(r)['request'] as Map);
  }

  @override
  Future<LypayRequest> status(String reference) async {
    final d = _data(await _guard(() => _client.get(Uri.parse('${baseUrl}api/v1/payment/lypay/$reference'), headers: _headers)));
    return LypayRequest.fromJson(d['request'] as Map);
  }
}
