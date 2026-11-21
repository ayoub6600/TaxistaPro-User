import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// One line of text the on-device recogniser found.
class OcrLine {
  const OcrLine({required this.text, required this.box, this.alternatives = const [], this.confidence = 1});

  final String text;

  /// Normalised to the upright image: (0,0) top-left, (1,1) bottom-right.
  final Rect box;

  /// The recogniser's other guesses for the same text (best first).
  final List<String> alternatives;
  final double confidence;

  static OcrLine? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    final b = raw['box'];
    if (text is! String || b is! List || b.length != 4) return null;
    double d(Object? v) => v is num ? v.toDouble() : 0;
    final alts = raw['alts'];
    return OcrLine(
      text: text,
      box: Rect.fromLTWH(d(b[0]), d(b[1]), d(b[2]), d(b[3])),
      alternatives: alts is List ? alts.whereType<String>().toList() : const [],
      confidence: d(raw['conf'] ?? 1),
    );
  }
}

/// What one camera frame (or one photo) yielded.
class OcrFrame {
  const OcrFrame({required this.lines, this.luma});

  final List<OcrLine> lines;

  /// Average brightness of the card area, 0-255 (null when unknown).
  final double? luma;

  static const OcrFrame empty = OcrFrame(lines: []);
}

/// The raw pixels of one camera frame, handed to the native recogniser.
class OcrFrameInput {
  const OcrFrameInput({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.format,
    required this.rotation,
    required this.roi,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;

  /// `bgra8888` (iOS) or `nv21` (Android).
  final String format;

  /// Clockwise degrees that turn the buffer upright (0, 90, 180, 270).
  final int rotation;

  /// The card area, normalised to the upright image (top-left origin).
  final Rect roi;
}

/// On-device text recognition. iOS: Apple Vision; Android: ML Kit's bundled
/// model (no download, no network). Nothing is uploaded, nothing is written to
/// disk, nothing is logged. This is the app's ONE recognition path: the live
/// scanner sends camera frames, the photo fallback sends one file.
abstract class CardOcr {
  Future<OcrFrame> recognizeFrame(OcrFrameInput input);

  /// One still photo (e.g. picked from the gallery). The file is read once.
  Future<OcrFrame> recognizeFile(String path);
}

class ChannelCardOcr implements CardOcr {
  const ChannelCardOcr();

  static const String channelName = 'taxista/card_ocr';

  static const MethodChannel _channel = MethodChannel(channelName);

  @override
  Future<OcrFrame> recognizeFrame(OcrFrameInput input) async {
    final raw = await _channel.invokeMethod<Object?>('recognizeFrame', {
      'bytes': input.bytes,
      'width': input.width,
      'height': input.height,
      'bytesPerRow': input.bytesPerRow,
      'format': input.format,
      'rotation': input.rotation,
      'roi': [input.roi.left, input.roi.top, input.roi.width, input.roi.height],
    });
    return _frame(raw);
  }

  @override
  Future<OcrFrame> recognizeFile(String path) async {
    final raw = await _channel.invokeMethod<Object?>('recognizeFile', {'path': path});
    return _frame(raw);
  }

  OcrFrame _frame(Object? raw) {
    if (raw is! Map) return OcrFrame.empty;
    final lines = raw['lines'];
    final luma = raw['luma'];
    return OcrFrame(
      lines: lines is List ? lines.map(OcrLine.fromMap).whereType<OcrLine>().toList() : const [],
      luma: luma is num ? luma.toDouble() : null,
    );
  }
}

/// The lines whose centre lies inside [roi] (slightly widened), joined into
/// visual rows in reading order. A card number is often recognised as four
/// separate groups: joining what sits on one row lets the parser see it whole.
/// The single lines follow the rows, so a line is never lost.
({List<String> rows, List<String> alternatives, List<OcrLine> inside}) cardReadingRows(List<OcrLine> lines, {Rect? roi}) {
  final area = roi?.inflate(math.max(roi.width, roi.height) * 0.04);
  final inside = [
    for (final l in lines)
      if (l.text.trim().isNotEmpty && (area == null || area.contains(l.box.center))) l,
  ]..sort((a, b) => a.box.center.dy.compareTo(b.box.center.dy));

  final groups = <List<OcrLine>>[];
  for (final line in inside) {
    if (groups.isEmpty) {
      groups.add([line]);
      continue;
    }
    final last = groups.last;
    final centerY = last.map((l) => l.box.center.dy).reduce((a, b) => a + b) / last.length;
    final tolerance = math.max(last.first.box.height, line.box.height) * 0.6;
    if ((line.box.center.dy - centerY).abs() <= tolerance) {
      last.add(line);
    } else {
      groups.add([line]);
    }
  }

  final rows = <String>[];
  final alternatives = <String>[];
  for (final group in groups) {
    group.sort((a, b) => a.box.left.compareTo(b.box.left));
    final joined = group.map((l) => l.text.trim()).where((t) => t.isNotEmpty).join(' ');
    if (joined.isNotEmpty) rows.add(joined);
    // One alternative row per group: each line's second guess (or itself).
    if (group.any((l) => l.alternatives.isNotEmpty)) {
      alternatives.add(group.map((l) => (l.alternatives.isNotEmpty ? l.alternatives.first : l.text).trim()).join(' '));
    }
  }
  if (groups.length > 1 || (groups.isNotEmpty && groups.first.length > 1)) {
    for (final line in inside) {
      rows.add(line.text.trim());
    }
  }
  return (rows: rows, alternatives: alternatives, inside: inside);
}
