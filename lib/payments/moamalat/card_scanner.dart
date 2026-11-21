import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import 'card_ocr.dart';
import 'card_text_parser.dart';

/// Card scanning for the Add Card form: the photo path.
///
/// The live camera scanner (`card_scanner_page.dart`) reads camera frames; this
/// file is its fallback when the live camera cannot run: one photo taken with
/// the phone's camera app, or one picked from the photos. Both go through the
/// same on-device recogniser (`card_ocr.dart`).
///
/// Privacy rules the scanner enforces (live frames and photos alike):
///  * the image is read ON THE DEVICE (Apple Vision on iOS, ML Kit's bundled
///    model on Android - no network) - it is never sent to Taxista or to any
///    cloud OCR service;
///  * live frames are read in memory and never written to disk; a photo is used
///    once and then deleted from disk, whatever the outcome - nothing is kept in
///    app storage, saved to the phone's photos, attached to analytics or logged;
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

/// Takes ONE photo with the rear camera (the phone's own camera screen).
/// `requestFullMetadata: false` keeps the app from asking for photo-library
/// access it does not need.
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

/// One photo the customer already has. The system picker hands the app a copy
/// of that one picture only (no library permission); the copy is deleted after
/// reading.
class PickedPhotoCardImageSource implements CardImageSource {
  PickedPhotoCardImageSource({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> capture() async {
    final photo = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2400, requestFullMetadata: false);
    return photo?.path;
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
    CardOcr? ocr,
    DateTime Function()? clock,
    ImageDeleter? deleter,
  })  : _source = source ?? CameraCardImageSource(),
        _ocr = ocr ?? const ChannelCardOcr(),
        _clock = clock ?? DateTime.now,
        _delete = deleter ?? _deleteFile;

  final CardImageSource _source;
  final CardOcr _ocr;
  final DateTime Function() _clock;
  final ImageDeleter _delete;

  Future<CardScanOutcome> scan() async {
    String? path;
    try {
      path = await _source.capture();
      if (path == null) return const CardScanOutcome(CardScanStatus.cancelled);
      final frame = await _ocr.recognizeFile(path);
      final rows = cardReadingRows(frame.lines);
      final card = parseCardText(rows.rows, alternativeRows: rows.alternatives, now: _clock());
      if (card.number == null && card.expiryMonth == null) return const CardScanOutcome(CardScanStatus.unreadable);
      // One photo is one reading (no agreement between frames): the number is
      // always shown for checking.
      return CardScanOutcome(CardScanStatus.success, card.copyWith(review: {...card.review, CardField.number}));
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
