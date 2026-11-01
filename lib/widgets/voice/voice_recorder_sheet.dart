import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:record/record.dart';

import 'voice_bubble.dart';

/// A finished recording the user chose to send.
class VoiceRecording {
  final File file;
  final int durationMs;

  VoiceRecording(this.file, this.durationMs);
}

/// Records a voice message in a bottom sheet: the clock while recording (stops by itself at
/// [maxSeconds]), cancel, stop, then listen before sending or delete. AAC (.m4a), mono, small.
/// Returns the recording to send, or null.
class VoiceRecorderSheet extends StatefulWidget {
  final int maxSeconds;

  const VoiceRecorderSheet({super.key, this.maxSeconds = 120});

  static Future<VoiceRecording?> show(BuildContext context, {int maxSeconds = 120}) async {
    final status = await perm.Permission.microphone.request();
    if (!status.isGranted && !status.isLimited) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('اسمح للتطبيق باستخدام الميكروفون من إعدادات الهاتف لإرسال رسالة صوتية.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return null;
    }
    if (!context.mounted) return null;

    return showModalBottomSheet<VoiceRecording>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceRecorderSheet(maxSeconds: maxSeconds),
    );
  }

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _clock;
  DateTime? _started;
  Duration _elapsed = Duration.zero;
  String? _path;
  bool _recording = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 22050, numChannels: 1),
        path: path,
      );
      _started = DateTime.now();
      setState(() => _recording = true);
      _clock = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || _started == null) return;
        setState(() => _elapsed = DateTime.now().difference(_started!));
        if (_elapsed.inSeconds >= widget.maxSeconds) _stop();
      });
    } catch (_) {
      setState(() => _error = 'تعذّر تشغيل الميكروفون.');
    }
  }

  Future<void> _stop() async {
    _clock?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    if (_elapsed.inMilliseconds < 700 || path == null) {
      setState(() {
        _recording = false;
        _error = 'التسجيل قصير جدًا. تحدّث لثانية على الأقل.';
      });
      return;
    }
    setState(() {
      _recording = false;
      _path = path;
    });
  }

  Future<void> _discard() async {
    _clock?.cancel();
    if (_recording) {
      await _recorder.cancel();
    }
    if (_path != null) {
      try {
        await File(_path!).delete();
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _round(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Container(width: 56, height: 56, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: fg, size: 26)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1D4ED8);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: dark ? const Color(0xFF111A2D) : Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_path == null ? 'رسالة صوتية' : 'استمع قبل الإرسال',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: dark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 18),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB91C1C))))
          else if (_path == null)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _RecDot(active: _recording),
              const SizedBox(width: 10),
              Text(_fmt(_elapsed),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()], color: dark ? Colors.white : const Color(0xFF0F172A))),
            ])
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(18)),
              child: VoiceBubble(filePath: _path, durationMs: _elapsed.inMilliseconds, mine: true),
            ),
          const SizedBox(height: 8),
          Text(_path == null ? 'الحد الأقصى ${widget.maxSeconds} ثانية' : 'المدة ${_fmt(_elapsed)}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _round(Icons.delete_outline, _path == null ? 'إلغاء التسجيل' : 'حذف التسجيل', const Color(0xFFFDEAEA), const Color(0xFFB91C1C), _discard),
            if (_path == null && _error == null)
              _round(Icons.stop_rounded, 'إنهاء التسجيل', blue, Colors.white, _stop)
            else if (_path != null)
              _round(Icons.send_rounded, 'إرسال الرسالة الصوتية', blue, Colors.white,
                  () => Navigator.of(context).pop(VoiceRecording(File(_path!), _elapsed.inMilliseconds))),
          ]),
        ]),
      ),
    );
  }
}

class _RecDot extends StatefulWidget {
  final bool active;

  const _RecDot({required this.active});

  @override
  State<_RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<_RecDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return FadeTransition(
      opacity: reduce || !widget.active ? const AlwaysStoppedAnimation(1) : Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle)),
    );
  }
}
