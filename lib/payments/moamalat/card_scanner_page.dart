import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import 'card_brand.dart';
import 'card_ocr.dart';
import 'card_scan_session.dart';
import 'card_scanner.dart';
import 'card_text_parser.dart';
import 'card_visual.dart';

/// Taxista blue (never another app's brand colour): the frame while reading.
const Color _blue = CardVisual.taxistaBlue;
const Color _green = Color(0xFF22C55E);

/// What the scanner hands back.
class CardScanResult {
  const CardScanResult._(this.card, this.manual);

  /// Read from the camera / a photo, for the customer to check.
  const CardScanResult.scanned(ScannedCard card) : this._(card, false);

  /// The customer chose to type the details instead.
  const CardScanResult.manual() : this._(null, true);

  final ScannedCard? card;
  final bool manual;
}

/// Live card scanner.
///
/// The camera stream is read on the phone (Apple Vision on iOS, ML Kit's
/// bundled model on Android) only inside the card frame. Frames are never
/// written to disk, uploaded or logged, the full number is never drawn on
/// screen, and only the front of the card is read - there is no security-code
/// field anywhere. When the live camera cannot run, the customer can still take
/// one photo with the phone's camera, pick a photo, or type the details.
class CardScannerPage extends StatefulWidget {
  const CardScannerPage({super.key, required this.isRtl, this.ocr = const ChannelCardOcr(), this.photoScanner, this.debugPreview, this.debugProgress, this.debugCameraProblem});

  final bool isRtl;
  final CardOcr ocr;

  /// Replaces the photo fallback's picker (tests only).
  final CardScanner Function(CardImageSource source)? photoScanner;

  /// Screenshots/tests only: a picture instead of the camera, and a fixed progress.
  @visibleForTesting
  final Widget? debugPreview;
  @visibleForTesting
  final ScanProgress? debugProgress;

  /// Screenshots/tests only: show the "camera off" panel (true = refused).
  @visibleForTesting
  final bool? debugCameraProblem;

  static Future<CardScanResult?> open(BuildContext context, {required bool isRtl}) {
    return Navigator.of(context).push<CardScanResult>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => CardScannerPage(isRtl: isRtl),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  State<CardScannerPage> createState() => _CardScannerPageState();
}

enum _Hint { place, hold, closer, light, glare, done }

class _CardScannerPageState extends State<CardScannerPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _camera;
  CardScanSession _session = CardScanSession();
  ScanProgress _progress = ScanProgress.initial;

  bool _busy = false;
  bool _streaming = false;
  bool _finishing = false;
  bool _disposed = false;
  bool _torch = false;
  bool _deniedCamera = false;
  bool _noCamera = false;
  bool _readingPhoto = false;
  String? _photoProblem;

  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _firstTextAt;
  double? _luma;
  int _darkFrames = 0;
  double _textHeight = 0;
  Size _viewport = Size.zero;

  late final AnimationController _laser = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
  late final AnimationController _success = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _torchPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  static const Duration _minFrameGap = Duration(milliseconds: 140);

  String t(String ar, String en) => widget.isRtl ? ar : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.debugCameraProblem != null) {
      _deniedCamera = widget.debugCameraProblem!;
      _noCamera = !widget.debugCameraProblem!;
      _laser.stop();
      return;
    }
    if (widget.debugPreview != null) {
      _progress = widget.debugProgress ?? ScanProgress.initial;
      _laser.stop();
      _laser.value = 0.42;
      return;
    }
    unawaited(_start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(_stop(dispose: true));
    } else if (state == AppLifecycleState.resumed && _camera == null && !_finishing && !_deniedCamera && !_readingPhoto && widget.debugPreview == null && widget.debugCameraProblem == null) {
      unawaited(_start());
    }
  }

  // ---- camera --------------------------------------------------------------------------------------

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _noCamera = true);
        return;
      }
      final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      final camera = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      _camera = camera;
      await camera.initialize();
      if (_disposed || !mounted) {
        await camera.dispose();
        return;
      }
      try {
        await camera.setFocusMode(FocusMode.auto);
        await camera.setExposureMode(ExposureMode.auto);
      } catch (_) {}
      if (_torch) {
        try {
          await camera.setFlashMode(FlashMode.torch);
        } catch (_) {}
      }
      setState(() {});
      _focusOnCard();
      await camera.startImageStream(_onFrame);
      _streaming = true;
    } on CameraException catch (e) {
      final denied = e.code.contains('AccessDenied') || e.code.contains('AccessRestricted') || e.code == 'cameraPermission';
      if (mounted) setState(() => denied ? _deniedCamera = true : _noCamera = true);
    } catch (_) {
      if (mounted) setState(() => _noCamera = true);
    }
  }

  Future<void> _stop({bool dispose = false}) async {
    final camera = _camera;
    if (camera == null) return;
    if (_streaming) {
      _streaming = false;
      try {
        await camera.stopImageStream();
      } catch (_) {}
    }
    if (dispose) {
      _camera = null;
      try {
        await camera.dispose();
      } catch (_) {}
      if (mounted && !_disposed) setState(() {});
    }
  }

  void _focusOnCard([Offset? screenPoint]) {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _viewport.isEmpty) return;
    final point = screenPoint ?? _guide(_viewport).center;
    final n = Offset((point.dx / _viewport.width).clamp(0.0, 1.0), (point.dy / _viewport.height).clamp(0.0, 1.0));
    try {
      if (camera.value.focusPointSupported) camera.setFocusPoint(n);
      if (camera.value.exposurePointSupported) camera.setExposurePoint(n);
    } catch (_) {}
  }

  /// The card frame on screen: ISO card proportions, upper part of the screen.
  static Rect _guide(Size viewport) {
    final width = viewport.width * 0.88;
    final height = width / CardVisual.aspect;
    return Rect.fromCenter(center: Offset(viewport.width / 2, viewport.height * 0.34), width: width, height: height);
  }

  /// The frame's area in the upright camera image (normalised), given that the
  /// preview fills the screen ("cover").
  Rect? _roi(Size upright) {
    if (_viewport.isEmpty || upright.isEmpty) return null;
    final scale = _viewport.width / upright.width > _viewport.height / upright.height ? _viewport.width / upright.width : _viewport.height / upright.height;
    final shownW = upright.width * scale;
    final shownH = upright.height * scale;
    final offX = (_viewport.width - shownW) / 2;
    final offY = (_viewport.height - shownH) / 2;
    final g = _guide(_viewport);
    final r = Rect.fromLTRB((g.left - offX) / shownW, (g.top - offY) / shownH, (g.right - offX) / shownW, (g.bottom - offY) / shownH);
    return r.intersect(const Rect.fromLTWH(0, 0, 1, 1));
  }

  int _rotation(CameraController camera) {
    final description = camera.description;
    if (Platform.isIOS) return description.sensorOrientation;
    const turns = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final turn = turns[camera.value.deviceOrientation] ?? 0;
    return description.lensDirection == CameraLensDirection.front
        ? (description.sensorOrientation + turn) % 360
        : (description.sensorOrientation - turn + 360) % 360;
  }

  void _onFrame(CameraImage image) {
    if (_busy || _finishing || _disposed) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < _minFrameGap) return;
    final camera = _camera;
    if (camera == null || image.planes.isEmpty) return;
    final rotation = _rotation(camera);
    final upright = rotation % 180 == 0 ? Size(image.width.toDouble(), image.height.toDouble()) : Size(image.height.toDouble(), image.width.toDouble());
    final roi = _roi(upright);
    if (roi == null || roi.isEmpty) return;
    final plane = image.planes.first;
    _busy = true;
    _lastFrame = now;
    unawaited(_read(OcrFrameInput(
      bytes: plane.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
      format: Platform.isIOS ? 'bgra8888' : 'nv21',
      rotation: rotation,
      roi: roi,
    )));
  }

  Future<void> _read(OcrFrameInput input) async {
    try {
      final frame = await widget.ocr.recognizeFrame(input);
      if (_disposed || _finishing || !mounted) return;
      final rows = cardReadingRows(frame.lines, roi: input.roi);
      final reading = parseCardText(rows.rows, alternativeRows: rows.alternatives);
      final before = _progress;
      final textSeen = rows.inside.length >= 2;
      final progress = _session.observe(reading, textSeen: textSeen);
      _trackConditions(frame, rows.inside, input.roi);
      _feedback(before, progress);
      setState(() => _progress = progress);
      if (progress.done) await _complete(progress.result!);
    } catch (_) {
      // Glare, motion, a busy recogniser: just wait for the next frame. Never log the text.
    } finally {
      _busy = false;
    }
  }

  void _trackConditions(OcrFrame frame, List<OcrLine> inside, Rect roi) {
    final luma = frame.luma;
    if (luma != null) {
      _luma = _luma == null ? luma : _luma! * 0.7 + luma * 0.3;
      _darkFrames = _luma! < 60 ? _darkFrames + 1 : 0;
      if (_darkFrames == 4 && !_torch) _torchPulse.repeat(reverse: true);
    }
    if (inside.isNotEmpty) {
      _firstTextAt ??= DateTime.now();
      final avg = inside.map((l) => l.box.height / roi.height).reduce((a, b) => a + b) / inside.length;
      _textHeight = _textHeight == 0 ? avg : _textHeight * 0.7 + avg * 0.3;
    }
  }

  void _feedback(ScanProgress before, ScanProgress now) {
    bool locked(FieldState a, FieldState b) => a != FieldState.locked && b == FieldState.locked;
    if (locked(before.numberState, now.numberState) || locked(before.expiryState, now.expiryState) || locked(before.holderState, now.holderState)) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _complete(ScannedCard card) async {
    if (_finishing) return;
    _finishing = true;
    await _stop();
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    setState(() {});
    await _success.forward();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) Navigator.of(context).pop(CardScanResult.scanned(card));
  }

  Future<void> _useWhatWeHave() async {
    if (_finishing) return;
    await _complete(_session.finishNow());
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    _torchPulse.stop();
    _torchPulse.value = 0;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      final next = !_torch;
      await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      HapticFeedback.selectionClick();
      if (mounted) setState(() => _torch = next);
    } catch (_) {}
  }

  /// The photo path: one picture (the phone's camera screen, or one from the
  /// photos), read by the same on-device recogniser and deleted straight after.
  Future<void> _fromPhoto({bool camera = false}) async {
    if (_readingPhoto) return;
    setState(() {
      _readingPhoto = true;
      _photoProblem = null;
    });
    // The live camera lets go first: the phone's camera screen needs it.
    await _stop(dispose: camera);
    try {
      final CardImageSource source = camera ? CameraCardImageSource() : PickedPhotoCardImageSource();
      final scanner = widget.photoScanner?.call(source) ?? CardScanner(source: source, ocr: widget.ocr);
      final outcome = await scanner.scan();
      if (!mounted) return;
      switch (outcome.status) {
        case CardScanStatus.success:
          await _complete(outcome.card);
          return;
        case CardScanStatus.cancelled:
          break;
        case CardScanStatus.denied:
          setState(() => _photoProblem = t('الكاميرا مقفولة على التطبيق. افتحها من الإعدادات أو اختار صورة.', 'Camera access is off. Allow it in Settings or pick a photo.'));
          break;
        case CardScanStatus.unreadable:
          setState(() => _photoProblem = t('ما قدرناش نقروا بطاقة في الصورة هذي. جرّب صورة أوضح للوجه الأمامي.', 'We could not read a card in that photo. Try a clearer photo of the front.'));
          break;
        case CardScanStatus.failed:
          setState(() => _photoProblem = t('ما قدرناش نقروا الصورة. جرّب مرة ثانية أو اكتب البيانات بيدك.', 'Could not read that photo. Try again or type the details.'));
          break;
      }
    } finally {
      if (mounted && !_finishing) {
        setState(() => _readingPhoto = false);
        final live = _camera;
        if (live == null) {
          if (!_deniedCamera && !_noCamera && widget.debugPreview == null && widget.debugCameraProblem == null) unawaited(_start());
        } else if (live.value.isInitialized && !_streaming) {
          try {
            await live.startImageStream(_onFrame);
            _streaming = true;
          } catch (_) {}
        }
      }
    }
  }

  void _restart() {
    HapticFeedback.selectionClick();
    setState(() {
      _session = CardScanSession();
      _progress = ScanProgress.initial;
      _firstTextAt = null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _laser.dispose();
    _success.dispose();
    _torchPulse.dispose();
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      () async {
        try {
          if (_streaming) await camera.stopImageStream();
        } catch (_) {}
        try {
          await camera.dispose();
        } catch (_) {}
      }();
    }
    super.dispose();
  }

  // ---- UI ------------------------------------------------------------------------------------------

  _Hint get _hint {
    if (_finishing || _progress.done) return _Hint.done;
    if (_darkFrames >= 4 && !_torch) return _Hint.light;
    if (!_progress.textSeen) return _Hint.place;
    if (_textHeight > 0 && _textHeight < 0.055) return _Hint.closer;
    final since = _firstTextAt == null ? Duration.zero : DateTime.now().difference(_firstTextAt!);
    if (_progress.numberState != FieldState.locked && since > const Duration(seconds: 6)) return _Hint.glare;
    return _Hint.hold;
  }

  String _hintText(_Hint h) {
    switch (h) {
      case _Hint.place:
        return t('حط وجه البطاقة اللي فيه الرقم داخل الإطار', 'Place the front of your card inside the frame');
      case _Hint.hold:
        return t('ثبّت البطاقة شوية… جاري القراءة', 'Hold still… reading');
      case _Hint.closer:
        return t('قرّب البطاقة شوية لين تعبّي الإطار', 'Move the card a little closer to fill the frame');
      case _Hint.light:
        return t('الضو ضعيف — شغّل الفلاش', 'It is dark here - turn on the torch');
      case _Hint.glare:
        return t('ميّل البطاقة شوية باش يروح اللمعان', 'Tilt the card slightly to avoid glare');
      case _Hint.done:
        return t('انقرت البطاقة ✓', 'Card read ✓');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(builder: (context, c) {
            _viewport = Size(c.maxWidth, c.maxHeight);
            final guide = _guide(_viewport);
            return Stack(fit: StackFit.expand, children: [
              _preview(),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (d) => _focusOnCard(d.localPosition),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_laser, _success]),
                  builder: (context, _) => CustomPaint(
                    painter: _FramePainter(
                      guide: guide,
                      laser: _laser.value,
                      success: _success.value,
                      locked: _progress.numberState == FieldState.locked,
                      reading: _progress.textSeen,
                    ),
                  ),
                ),
              ),
              if (_success.value > 0 || _finishing)
                Positioned.fromRect(
                  rect: guide,
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: _success, curve: Curves.elasticOut),
                    child: const Center(
                      child: CircleAvatar(radius: 34, backgroundColor: _green, child: Icon(Icons.check_rounded, color: Colors.white, size: 44)),
                    ),
                  ),
                ),
              _overlay(guide),
              if (_deniedCamera || _noCamera) _cameraProblem(),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _preview() {
    if (widget.debugPreview != null) return widget.debugPreview!;
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || camera.value.previewSize == null) {
      return const ColoredBox(color: Colors.black);
    }
    final size = camera.value.previewSize!; // landscape (sensor) size
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: size.height, height: size.width, child: CameraPreview(camera)),
      ),
    );
  }

  Widget _overlay(Rect guide) {
    final hint = _hint;
    return Stack(children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(children: [
              _roundButton(Icons.close_rounded, () => Navigator.of(context).pop(), key: const Key('scan-close')),
              Expanded(
                child: Text(t('صوّر البطاقة', 'Scan card'),
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              AnimatedBuilder(
                animation: _torchPulse,
                builder: (context, child) => Transform.scale(scale: 1 + _torchPulse.value * 0.12, child: child),
                child: _roundButton(_torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded, _toggleTorch,
                    key: const Key('scan-torch'), active: _torch),
              ),
            ]),
          ),
        ),
      ),
      Positioned(
        top: guide.bottom + 14,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey(hint),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (hint == _Hint.done
                        ? _green
                        : (hint == _Hint.light || hint == _Hint.glare || hint == _Hint.closer ? const Color(0xFFF59E0B) : Colors.black))
                    .withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(_hintText(hint), key: const Key('scan-hint'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_photoProblem != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(_photoProblem!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD7C9), fontWeight: FontWeight.w600)),
              ),
            _livePanel(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                Expanded(
                  child: _textButton(Icons.keyboard_alt_outlined, t('نكتبها بيدي', 'Type it'), () => Navigator.of(context).pop(const CardScanResult.manual()),
                      key: const Key('scan-manual')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _textButton(_readingPhoto ? Icons.hourglass_top_rounded : Icons.photo_library_outlined, t('من الصور', 'From photos'),
                      _readingPhoto ? null : () => _fromPhoto(),
                      key: const Key('scan-photo')),
                ),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }

  /// The card as it is being read: fields appear and lock one by one.
  Widget _livePanel() {
    final p = _progress;
    final number = p.number;
    final canFinish = !_finishing && (p.numberState == FieldState.locked || (_session.hasAnything && _firstTextAt != null && DateTime.now().difference(_firstTextAt!) > const Duration(seconds: 8)));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xEE111827), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          SizedBox(
            width: 128,
            child: CardVisual(
              brand: number == null ? CardBrand.local : cardBrandOf(number),
              numberText: number == null ? '•••• •••• •••• ••••' : maskForPreview(number),
              holderText: p.holder ?? '••••••',
              expiryText: p.expiryText ?? '••/••',
              highlight: p.numberState != FieldState.locked
                  ? CardVisualField.number
                  : (p.expiryState != FieldState.locked ? CardVisualField.expiry : (p.holderState != FieldState.locked ? CardVisualField.holder : null)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldRow(t('رقم البطاقة', 'Card number'), number == null ? null : maskForPreview(number), p.numberState, ltr: true),
              const SizedBox(height: 6),
              _fieldRow(t('تاريخ الانتهاء', 'Expiry'), p.expiryText, p.expiryState, ltr: true),
              const SizedBox(height: 6),
              _fieldRow(t('اسم صاحب البطاقة', 'Cardholder'), p.holder, p.holderState),
            ]),
          ),
        ]),
        if (canFinish || p.numberState == FieldState.locked) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton(
                key: const Key('scan-use'),
                style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: canFinish ? _useWhatWeHave : null,
                child: Text(t('كمّل باللي انقرا', 'Continue with what was read'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const Key('scan-restart'),
              onPressed: _restart,
              tooltip: t('عاود القراءة', 'Read again'),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _fieldRow(String label, String? value, FieldState state, {bool ltr = false}) {
    final Widget icon;
    switch (state) {
      case FieldState.locked:
        icon = const Icon(Icons.check_circle_rounded, color: _green, size: 18, key: ValueKey('locked'));
        break;
      case FieldState.reading:
        icon = const SizedBox(width: 16, height: 16, key: ValueKey('reading'), child: CircularProgressIndicator(strokeWidth: 2, color: _blue));
        break;
      case FieldState.searching:
        icon = Icon(Icons.radio_button_unchecked_rounded, color: Colors.white.withValues(alpha: 0.35), size: 18, key: const ValueKey('searching'));
        break;
    }
    final text = Text(
      value ?? '—',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: state == FieldState.locked ? Colors.white : Colors.white60, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: ltr ? 0.6 : 0),
    );
    return Row(children: [
      AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: icon),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ltr ? Directionality(textDirection: TextDirection.ltr, child: Align(alignment: AlignmentDirectional.centerStart, child: text)) : text,
        ]),
      ),
    ]);
  }

  Widget _roundButton(IconData icon, VoidCallback onTap, {Key? key, bool active = false}) {
    return Material(
      key: key,
      color: active ? Colors.white : Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: active ? Colors.black : Colors.white, size: 24)),
      ),
    );
  }

  Widget _textButton(IconData icon, String label, VoidCallback? onTap, {Key? key}) {
    return OutlinedButton.icon(
      key: key,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white30),
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _cameraProblem() {
    return Container(
      key: const Key('scan-camera-problem'),
      color: Colors.black,
      padding: const EdgeInsets.all(28),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 54),
          const SizedBox(height: 16),
          Text(
            _deniedCamera ? t('الكاميرا مقفولة على التطبيق', 'Camera access is off') : t('الكاميرا المباشرة ما خدمتش على هذا الجهاز', 'The live camera is not available'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _deniedCamera
                ? t('تقدر تفتح الكاميرا من الإعدادات، أو تختار صورة البطاقة، أو تكتب البيانات بيدك.', 'You can allow the camera in Settings, pick a photo of the card, or type the details.')
                : t('تقدر تصوّر البطاقة بكاميرا الجهاز، أو تختار صورتها، أو تكتب البيانات بيدك.', 'You can take one photo of the card, pick a photo, or type the details.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (_photoProblem != null) ...[
            const SizedBox(height: 10),
            Text(_photoProblem!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFE1A8), fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 22),
          if (_deniedCamera)
            FilledButton(
              key: const Key('scan-settings'),
              style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
              onPressed: () => openAppSettings(),
              child: Text(t('افتح الإعدادات', 'Open Settings')),
            )
          else
            FilledButton.icon(
              key: const Key('scan-take-photo'),
              style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
              onPressed: _readingPhoto ? null : () => _fromPhoto(camera: true),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(t('صوّر بكاميرا الجهاز', 'Take one photo')),
            ),
          const SizedBox(height: 10),
          _textButton(Icons.photo_library_outlined, t('اختار صورة البطاقة', 'Pick a photo of the card'), _readingPhoto ? null : () => _fromPhoto(), key: const Key('scan-photo-fallback')),
          const SizedBox(height: 10),
          _textButton(Icons.keyboard_alt_outlined, t('نكتبها بيدي', 'Type it'), () => Navigator.of(context).pop(const CardScanResult.manual()), key: const Key('scan-manual-fallback')),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('إغلاق', 'Close'), style: const TextStyle(color: Colors.white70))),
        ]),
      ),
    );
  }
}

/// Dims everything but the card frame, draws its corners (white while
/// searching, Taxista blue while reading, green when the number is locked) and the
/// scanning light that sweeps across it.
class _FramePainter extends CustomPainter {
  _FramePainter({required this.guide, required this.laser, required this.success, required this.locked, required this.reading});

  final Rect guide;
  final double laser;
  final double success;
  final bool locked;
  final bool reading;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(guide.width * 0.05);
    final frame = RRect.fromRectAndRadius(guide, radius);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(frame),
      Paint()..color = const Color(0xB3000000),
    );

    final color = Color.lerp(locked ? _green : (reading ? _blue : Colors.white), _green, success)!;
    if (success > 0) {
      canvas.drawRRect(frame, Paint()..color = _green.withValues(alpha: 0.18 * (1 - (success - 0.5).abs() * 2).clamp(0.0, 1.0)));
    }

    // Thin outline + bold corners.
    canvas.drawRRect(frame, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.35));
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    final len = guide.width * 0.12;
    final r = radius.x;
    void cornerPath(Offset a, Offset b, Offset c) => canvas.drawPath(Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(b.dx, b.dy, c.dx, c.dy), corner);
    // Each corner: straight run, rounded turn, straight run.
    for (final (o, dx, dy) in [
      (guide.topLeft, 1.0, 1.0),
      (guide.topRight, -1.0, 1.0),
      (guide.bottomLeft, 1.0, -1.0),
      (guide.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(Offset(o.dx + dx * r, o.dy), Offset(o.dx + dx * len, o.dy), corner);
      canvas.drawLine(Offset(o.dx, o.dy + dy * r), Offset(o.dx, o.dy + dy * len), corner);
      cornerPath(Offset(o.dx, o.dy + dy * r), o, Offset(o.dx + dx * r, o.dy));
    }

    // The scanning light (hidden once the number is locked).
    if (!locked && success == 0) {
      final y = guide.top + guide.height * (0.1 + 0.8 * Curves.easeInOut.transform(laser));
      final beam = Rect.fromLTRB(guide.left + 10, y - 14, guide.right - 10, y + 14);
      canvas.drawRect(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(beam),
      );
      canvas.drawLine(Offset(guide.left + 14, y), Offset(guide.right - 14, y), Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 1.6);
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.laser != laser || old.success != success || old.locked != locked || old.reading != reading || old.guide != guide;
}
