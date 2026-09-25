import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:image_picker/image_picker.dart';

import 'card_text_parser.dart';

/// Optional card scanning for the Add Card form.
///
/// Privacy rules this file enforces:
///  * the photo is read ON THE DEVICE (Apple Vision on iOS, ML Kit's bundled
///    model on Android - no network) - it is never sent to Taxista or to any cloud OCR service;
///  * it is used once and then deleted from disk, whatever the outcome - it is
///    never kept in app storage, never saved to the gallery, never attached to
///    analytics, never logged;
///  * only text is kept, and only long enough to fill the form; the card number
///    is never logged and no field for a security code exists.

/// The camera would not open because the user refused permission.
class CardCameraDenied implements Exception {
  const CardCameraDenied();
}

abstract class CardImageSource {
  /// A file path to one photo of the card, or null if the user cancelled.
  Future<String?> capture();
}

abstract class CardTextRecognizer {
  /// The text lines found in the image, in reading order.
  Future<List<String>> recognize(String imagePath);
}

/// Takes ONE photo with the rear camera. `requestFullMetadata: false` keeps the
/// app from asking for photo-library access it does not need.
class CameraCardImageSource implements CardImageSource {
  CameraCardImageSource({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> capture() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1800,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      return photo?.path;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' || e.code == 'camera_access_restricted') {
        throw const CardCameraDenied();
      }
      rethrow;
    }
  }
}

/// On-device text recognition through a small native channel: Apple's Vision
/// framework on iOS, Google's ML Kit (bundled model, no download) on Android.
/// Nothing leaves the device and neither engine talks to a server.
class NativeCardTextRecognizer implements CardTextRecognizer {
  NativeCardTextRecognizer({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'taxista/card_ocr';

  final MethodChannel _channel;

  @override
  Future<List<String>> recognize(String imagePath) async {
    final lines = await _channel.invokeMethod<List<dynamic>>('recognize', <String, dynamic>{'path': imagePath});
    return <String>[for (final line in lines ?? const <dynamic>[]) line.toString()];
  }
}

enum CardScanStatus { success, cancelled, denied, unreadable, failed }

class CardScanOutcome {
  const CardScanOutcome(this.status, [this.card = ScannedCard.empty]);

  final CardScanStatus status;
  final ScannedCard card;
}

typedef ImageDeleter = Future<void> Function(String path);

Future<void> _deleteFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

class CardScanner {
  CardScanner({
    CardImageSource? source,
    CardTextRecognizer? recognizer,
    DateTime Function()? clock,
    ImageDeleter? deleter,
  })  : _source = source ?? CameraCardImageSource(),
        _recognizer = recognizer ?? NativeCardTextRecognizer(),
        _clock = clock ?? DateTime.now,
        _delete = deleter ?? _deleteFile;

  final CardImageSource _source;
  final CardTextRecognizer _recognizer;
  final DateTime Function() _clock;
  final ImageDeleter _delete;

  Future<CardScanOutcome> scan() async {
    String? path;
    try {
      path = await _source.capture();
      if (path == null) return const CardScanOutcome(CardScanStatus.cancelled);
      final lines = await _recognizer.recognize(path);
      final card = parseCardText(lines, now: _clock());
      return card.isEmpty
          ? const CardScanOutcome(CardScanStatus.unreadable)
          : CardScanOutcome(CardScanStatus.success, card);
    } on CardCameraDenied {
      return const CardScanOutcome(CardScanStatus.denied);
    } catch (_) {
      return const CardScanOutcome(CardScanStatus.failed);
    } finally {
      // The photo is discarded the moment the text has been read - success,
      // failure or cancel - and a failing delete never surfaces the image.
      if (path != null) {
        try {
          await _delete(path);
        } catch (_) {}
      }
    }
  }
}
