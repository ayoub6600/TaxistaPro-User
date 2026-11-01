import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// A voice message in a chat bubble: play / pause, seek, time, speed 1x / 1.5x / 2x.
/// [url] is the signed link from the server (or [filePath] for a recording not sent yet).
/// One voice message plays at a time.
class VoiceBubble extends StatefulWidget {
  final String? url;
  final String? filePath;
  final int durationMs;
  final bool mine;
  final bool expired;

  const VoiceBubble({super.key, this.url, this.filePath, required this.durationMs, this.mine = false, this.expired = false});

  /// The fields a chat message carries for a voice message, or null for a text message.
  static VoiceBubble? fromMessage(Map message, {required bool mine}) {
    if (message['message_type'] != 'voice') return null;
    return VoiceBubble(
      url: message['audio_url']?.toString(),
      durationMs: int.tryParse('${message['audio_duration_ms'] ?? 0}') ?? 0,
      mine: mine,
      expired: message['audio_expired'] == true || message['audio_url'] == null,
    );
  }

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  static _VoiceBubbleState? _playing;

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];
  Duration _position = Duration.zero;
  Duration? _duration;
  PlayerState _state = PlayerState.stopped;
  double _rate = 1;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.onPositionChanged.listen((p) => mounted ? setState(() => _position = p) : null));
    _subs.add(_player.onDurationChanged.listen((d) => mounted ? setState(() => _duration = d) : null));
    _subs.add(_player.onPlayerStateChanged.listen((s) => mounted ? setState(() => _state = s) : null));
    _subs.add(_player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    }));
  }

  @override
  void dispose() {
    if (_playing == this) _playing = null;
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (_playing != null && _playing != this) await _playing!._player.pause();
    _playing = this;
    try {
      setState(() => _failed = false);
      if (_state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(widget.filePath != null ? DeviceFileSource(widget.filePath!) : UrlSource(widget.url!));
        await _player.setPlaybackRate(_rate);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _speed() async {
    final next = _rate == 1 ? 1.5 : (_rate == 1.5 ? 2.0 : 1.0);
    setState(() => _rate = next);
    try {
      await _player.setPlaybackRate(next);
    } catch (_) {}
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.mine ? Colors.white : const Color(0xFF0F2A6B);
    if (widget.expired || (widget.url == null && widget.filePath == null)) {
      return Text('انتهت مدة الاحتفاظ بهذه الرسالة الصوتية', style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 13));
    }
    final total = _duration ?? Duration(milliseconds: widget.durationMs);
    final max = total.inMilliseconds <= 0 ? 1.0 : total.inMilliseconds.toDouble();
    final value = _position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    final playing = _state == PlayerState.playing;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Semantics(
          button: true,
          label: playing ? 'إيقاف مؤقت' : 'تشغيل الرسالة الصوتية',
          child: InkResponse(
            onTap: _toggle,
            radius: 24,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.mine ? Colors.white : const Color(0xFF1D4ED8)),
              child: Icon(playing ? Icons.pause : Icons.play_arrow, color: widget.mine ? const Color(0xFF1D4ED8) : Colors.white, size: 24),
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: fg,
              inactiveTrackColor: fg.withValues(alpha: 0.3),
              thumbColor: fg,
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(_failed ? 'تعذّر' : _fmt(playing || _position > Duration.zero ? _position : total),
            style: TextStyle(color: fg, fontSize: 12, fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: 'سرعة التشغيل',
          child: InkWell(
            onTap: _speed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: fg.withValues(alpha: 0.8)), borderRadius: BorderRadius.circular(10)),
              child: Text('${_rate == 1 ? '1' : (_rate == 2 ? '2' : '1.5')}x', style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}
