import 'dart:async';

import 'package:flutter/material.dart';

import '../../functions/voice/voice_api.dart';
import 'voice_recorder_sheet.dart';

/// Records and sends one voice message from a chat screen: the recorder sheet, then the upload
/// with its progress at the bottom of the screen. A dropped connection is retried with the same
/// client id (the server keeps one message), then the user gets "إعادة المحاولة".
class VoiceSend {
  static Future<Map<String, dynamic>?> recordAndSend(
    BuildContext context, {
    required String endpoint,
    Map<String, String> fields = const {},
    int maxSeconds = 120,
  }) async {
    final rec = await VoiceRecorderSheet.show(context, maxSeconds: maxSeconds);
    if (rec == null || !context.mounted) return null;

    return _send(context, endpoint: endpoint, fields: fields, rec: rec, clientId: VoiceApi.newClientId());
  }

  static Future<Map<String, dynamic>?> _send(
    BuildContext context, {
    required String endpoint,
    required Map<String, String> fields,
    required VoiceRecording rec,
    required String clientId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final progress = ValueNotifier<double>(0);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 2),
      behavior: SnackBarBehavior.floating,
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, p, __) => Row(children: [
            const Icon(Icons.mic, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('جارٍ إرسال الرسالة الصوتية… ${(p * 100).round()}%')),
            SizedBox(width: 60, child: LinearProgressIndicator(value: p, color: Colors.white, backgroundColor: Colors.white24)),
          ]),
        ),
      ),
    ));

    VoiceUploadResult result = VoiceUploadResult(0, const {});
    for (var attempt = 0; attempt < 3; attempt++) {
      result = await VoiceApi.upload(endpoint: endpoint, file: rec.file, durationMs: rec.durationMs, clientId: clientId, fields: fields, onProgress: (p) => progress.value = p);
      if (result.ok || !result.retryable) break;
      await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
    messenger.hideCurrentSnackBar();

    if (result.ok) {
      try {
        await rec.file.delete();
      } catch (_) {}
      return result.data;
    }
    if (!context.mounted) return null;
    final retry = Completer<Map<String, dynamic>?>();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFB91C1C),
      duration: Duration(seconds: result.retryable ? 12 : 5),
      content: Text(result.message, textDirection: TextDirection.rtl),
      action: result.retryable
          ? SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => retry.complete(context.mounted ? _send(context, endpoint: endpoint, fields: fields, rec: rec, clientId: clientId) : null),
            )
          : null,
    )).closed.then((reason) {
      if (!retry.isCompleted) retry.complete(null);
    });

    return retry.future;
  }
}
