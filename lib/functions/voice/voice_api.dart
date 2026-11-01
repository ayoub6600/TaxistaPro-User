import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../functions.dart';

/// Voice messages: uploads to the trip chat (with the rider) and to the chat with the
/// administration. The server checks the recording (type, size, its real length) and keeps it
/// private; histories carry a signed, expiring audio_url to play it.
class VoiceApi {
  /// The text stored with a voice message (also what older app versions show).
  static const placeholder = '🎤 رسالة صوتية';

  static String newClientId() {
    final r = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'v$r${(r.hashCode & 0xfffff).toRadixString(36)}';
  }

  /// [endpoint]: 'send-voice' (trip chat) or 'send-voice-message' (administration). The same
  /// [clientId] on a retry makes the server return the same message instead of a second one.
  static Future<VoiceUploadResult> upload({
    required String endpoint,
    required File file,
    required int durationMs,
    required String clientId,
    Map<String, String> fields = const {},
    void Function(double progress)? onProgress,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${url}api/v1/request/$endpoint'));
      request.headers.addAll({
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Accept': 'application/json',
      });
      request.fields.addAll({...fields, 'duration_ms': '$durationMs', 'client_uuid': clientId});
      final length = await file.length();
      var sent = 0;
      final stream = file.openRead().transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sent += data.length;
          onProgress?.call(length == 0 ? 1 : sent / length);
          sink.add(data);
        },
      ));
      request.files.add(http.MultipartFile('audio', stream, length, filename: 'voice.m4a'));
      final response = await http.Response.fromStream(await request.send()).timeout(const Duration(seconds: 60));
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      return VoiceUploadResult(response.statusCode, body);
    } catch (_) {
      return VoiceUploadResult(0, const {});
    }
  }
}

class VoiceUploadResult {
  final int status;
  final Map<String, dynamic> body;

  VoiceUploadResult(this.status, this.body);

  bool get ok => status >= 200 && status < 300 && body['success'] != false;

  /// A connection problem or a server error: worth trying again with the same client id.
  bool get retryable => status == 0 || status >= 500;

  Map<String, dynamic> get data => body['data'] is Map ? Map<String, dynamic>.from(body['data']) : {};

  String get message {
    if (status == 0) return 'تعذّر الاتصال بالخادم. تحقق من الإنترنت ثم أعد المحاولة.';
    final errors = body['errors'];
    if (errors is Map && errors['audio'] is List && (errors['audio'] as List).isNotEmpty) {
      return (errors['audio'] as List).first.toString();
    }
    if (status == 429) return 'محاولات كثيرة خلال دقيقة. انتظر قليلًا ثم حاول مرة أخرى.';
    return (body['message'] ?? 'تعذّر إرسال الرسالة الصوتية.').toString();
  }
}
