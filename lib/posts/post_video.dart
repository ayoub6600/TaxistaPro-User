import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'posts_api.dart';

/// A post's video inside the app, light like Facebook's (owner 2026-11-22):
///  - the server's HLS: 4-second pieces, so it starts after the first piece and the phone picks
///    360p or 720p by its network (AVPlayer / ExoPlayer do that themselves);
///  - only ONE video plays in the whole app; it starts muted when most of it is on screen, pauses
///    when it scrolls away, and its player is released a moment after it leaves the screen;
///  - the poster shows first (cached), so nothing jumps.
class PostVideo extends StatefulWidget {
  const PostVideo({super.key, required this.post, this.autoplay = true, this.maxHeight = 520});
  final Map<String, dynamic> post;
  final bool autoplay;
  final double maxHeight;

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  static _PostVideoState? _playing;

  VideoPlayerController? _c;
  bool _starting = false, _failed = false, _muted = true, _counted = false, _userPaused = false;
  Timer? _release;

  Map get _v => widget.post['video'] is Map ? widget.post['video'] as Map : const {};
  int get _id => (widget.post['id'] as num).toInt();
  double get _ratio {
    final w = (_v['width'] as num?)?.toDouble() ?? 16, h = (_v['height'] as num?)?.toDouble() ?? 9;
    final r = w > 0 && h > 0 ? w / h : 16 / 9;
    return r < 0.8 ? 0.8 : r; // a vertical video sits in a 4:5 frame in the feed (cropped a little), like Facebook
  }

  @override
  void dispose() {
    _release?.cancel();
    if (_playing == this) _playing = null;
    _c?.dispose();
    super.dispose();
  }

  Future<void> _start({bool muted = true}) async {
    if (_starting || _failed) return;
    final hls = '${_v['hls'] ?? ''}';
    if (!hls.startsWith('http')) return;
    _release?.cancel();
    if (_playing != null && _playing != this) _playing!._pause();
    _playing = this;
    if (_c == null) {
      _starting = true;
      final c = VideoPlayerController.networkUrl(Uri.parse(hls), videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      try {
        await c.initialize();
      } catch (_) {
        await c.dispose();
        if (mounted) {
          setState(() {
            _failed = true;
            _starting = false;
          });
        }
        return;
      }
      if (!mounted || _playing != this) {
        await c.dispose();
        _starting = false;
        return;
      }
      c.addListener(_tick);
      _c = c;
      _starting = false;
    }
    _muted = muted;
    await _c!.setVolume(muted ? 0 : 1);
    await _c!.play();
    if (!_counted) {
      _counted = true;
      PostsApi.event(_id, 'play');
    }
    if (mounted) setState(() {});
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _pause() {
    _c?.pause();
    if (_playing == this) _playing = null;
  }

  void _onVisible(VisibilityInfo info) {
    if (!mounted) return;
    final f = info.visibleFraction;
    final c = _c;
    final ended = c != null && c.value.isInitialized && c.value.position >= c.value.duration;
    if (f >= 0.7 && widget.autoplay && !_userPaused && !ended && !(c?.value.isPlaying ?? false)) {
      unawaited(_start(muted: _muted));
    } else if (f < 0.3) {
      _pause();
    }
    _release?.cancel();
    if (f == 0) {
      // gone from the screen: give the memory back a little later (scrolling back soon keeps it)
      _release = Timer(const Duration(seconds: 3), () {
        final c = _c;
        _c = null;
        c?.removeListener(_tick);
        c?.dispose();
        if (_playing == this) _playing = null;
        if (mounted) setState(() {});
      });
    }
  }

  void _tap() {
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      _userPaused = false;
      _failed = false;
      unawaited(_start(muted: false));
      return;
    }
    if (c.value.isPlaying && _muted) {
      setState(() => _muted = false);
      c.setVolume(1);
      return;
    }
    if (c.value.isPlaying) {
      _userPaused = true;
      _pause();
    } else {
      _userPaused = false;
      if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
      unawaited(_start(muted: _muted));
    }
    setState(() {});
  }

  void _full() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    c.setVolume(1);
    _muted = false;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FullVideo(controller: c))).then((_) {
      if (mounted) setState(() {});
    });
  }

  String _clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    final playing = ready && c.value.isPlaying;
    final buffering = _starting || (ready && c.value.isBuffering && playing);
    final total = Duration(seconds: (_v['duration_s'] as num?)?.toInt() ?? 0);
    return VisibilityDetector(
      key: ValueKey('post-video-$_id'),
      onVisibilityChanged: _onVisible,
      child: LayoutBuilder(builder: (context, box) {
        final h = (box.maxWidth / _ratio).clamp(160.0, widget.maxHeight);
        return GestureDetector(
          onTap: _tap,
          child: Container(
            width: box.maxWidth,
            height: h,
            color: const Color(0xFF0B1224),
            child: Stack(fit: StackFit.expand, children: [
              if ('${_v['poster'] ?? ''}'.startsWith('http'))
                CachedNetworkImage(imageUrl: '${_v['poster']}', fit: BoxFit.cover, fadeInDuration: Duration.zero, errorWidget: (_, __, ___) => const SizedBox()),
              if (ready)
                FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c))),
              if (!playing && !buffering)
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)]),
                    child: Icon(_failed ? Icons.refresh_rounded : Icons.play_arrow_rounded, size: 40, color: const Color(0xFF0873FF)),
                  ),
                ),
              if (buffering) const Center(child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))),
              if (_failed)
                const Positioned(left: 12, right: 12, bottom: 14, child: Text('ما قدرناش نشغّلوه توا. اضغط تعاود.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              if (!ready && total.inSeconds > 0)
                Positioned(left: 10, bottom: 10, child: _pill(_clock(total))),
              if (ready) ...[
                Positioned(left: 0, right: 0, bottom: 0, child: VideoProgressIndicator(c, allowScrubbing: true, padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(playedColor: Color(0xFF0873FF), bufferedColor: Colors.white38, backgroundColor: Colors.white12))),
                Positioned(left: 8, bottom: 10, child: _round(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, () {
                  setState(() => _muted = !_muted);
                  c.setVolume(_muted ? 0 : 1);
                }, _muted ? 'تشغيل الصوت' : 'كتم الصوت')),
                Positioned(right: 8, bottom: 10, child: _round(Icons.fullscreen_rounded, _full, 'ملء الشاشة')),
                Positioned(left: 56, bottom: 16, child: _pill('${_clock(c.value.position)} / ${_clock(c.value.duration)}')),
              ],
            ]),
          ),
        );
      }),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .7), borderRadius: BorderRadius.circular(8)),
        child: Text(t, textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _round(IconData i, VoidCallback on, String label) => Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: on,
          radius: 24,
          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), shape: BoxShape.circle), child: Icon(i, color: Colors.white, size: 22)),
        ),
      );
}

/// The same player on the whole screen (whole video, nothing cropped).
class _FullVideo extends StatefulWidget {
  const _FullVideo({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_FullVideo> createState() => _FullVideoState();
}

class _FullVideoState extends State<_FullVideo> {
  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_tick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          Center(child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))),
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => c.value.isPlaying ? c.pause() : c.play())),
          if (!c.value.isPlaying) const Center(child: Icon(Icons.play_circle_fill_rounded, size: 76, color: Colors.white)),
          Positioned(left: 0, right: 0, bottom: 0, child: VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.fromLTRB(12, 10, 12, 18))),
          Positioned(top: 8, right: 8, child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30), tooltip: 'إغلاق')),
        ]),
      ),
    );
  }
}
