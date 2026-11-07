import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../functions/functions.dart';

/// Photos in the chats (support, current ride, past ride): the photo in the bubble, full screen
/// with zoom on tap, and sending one (camera or gallery -> preview with an optional caption ->
/// upload with the same client id on a retry, so the server keeps one message).
class ChatPhotos {
  static const _blue = Color(0xFF0873FF);

  /// the photo links of a message from the server (message_type image), or none
  static List<String> of(Map m) => m['message_type'] == 'image' && m['images'] is List
      ? (m['images'] as List).map((e) => '$e').where((e) => e.startsWith('http')).toList()
      : const [];

  static String caption(Map m) => '${m['caption'] ?? ''}'.trim();

  static String _newClientId() {
    final r = Random.secure();
    return 'p${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${List.generate(8, (_) => r.nextInt(36).toRadixString(36)).join()}';
  }

  /// camera / gallery -> preview + caption -> upload. Returns the server's message, or null.
  static Future<Map<String, dynamic>?> pickAndSend(BuildContext context, {required String endpoint, Map<String, String> fields = const {}}) async {
    final rtl = languageDirection == 'rtl';
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xffE3E9F2), borderRadius: BorderRadius.circular(9))),
            const SizedBox(height: 8),
            _sourceRow(ctx, Icons.photo_camera_outlined, rtl ? 'التقط صورة' : 'Take a photo', ImageSource.camera),
            _sourceRow(ctx, Icons.photo_library_outlined, rtl ? 'اختر من الصور' : 'Choose from photos', ImageSource.gallery),
          ]),
        ),
      ),
    );
    if (source == null || !context.mounted) return null;
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rtl ? 'اسمح للتطبيق باستخدام الكاميرا والصور من الإعدادات' : 'Allow camera and photos in Settings')));
      }
      return null;
    }
    if (picked == null || !context.mounted) return null;
    final file = File(picked.path);
    final caption = await _preview(context, file);
    if (caption == null || !context.mounted) return null;
    return _upload(context, endpoint: endpoint, fields: fields, file: file, caption: caption, clientId: _newClientId());
  }

  static Widget _sourceRow(BuildContext ctx, IconData icon, String label, ImageSource source) => ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: _blue.withValues(alpha: .08), borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: _blue),
        ),
        title: Text(label, style: GoogleFonts.cairo(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xff10213F))),
        onTap: () => Navigator.pop(ctx, source),
      );

  /// the photo big, a caption field and «إرسال»; returns the caption ('' = none) or null = cancelled
  static Future<String?> _preview(BuildContext context, File file) {
    final rtl = languageDirection == 'rtl';
    final ctrl = TextEditingController();
    return Navigator.of(context).push<String>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(rtl ? 'إرسال صورة' : 'Send a photo', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          ),
          body: Column(children: [
            Expanded(child: InteractiveViewer(minScale: 1, maxScale: 4, child: Center(child: Image.file(file, fit: BoxFit.contain)))),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: rtl ? 'أضف تعليقًا (اختياري)' : 'Add a caption (optional)',
                        hintStyle: GoogleFonts.cairo(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: _blue,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
                      child: const SizedBox.square(dimension: 50, child: Icon(Icons.send_rounded, color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ));
  }

  static Future<Map<String, dynamic>?> _upload(BuildContext context,
      {required String endpoint, required Map<String, String> fields, required File file, required String caption, required String clientId}) async {
    final rtl = languageDirection == 'rtl';
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 2),
      behavior: SnackBarBehavior.floating,
      content: Row(children: [
        const Icon(Icons.photo_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(rtl ? 'جارٍ إرسال الصورة…' : 'Sending the photo…')),
        const SizedBox(width: 60, child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.white24)),
      ]),
    ));
    Map<String, dynamic>? data;
    String error = rtl ? 'ما وصلتش الصورة. تأكد من الإنترنت وجرّب مرة ثانية.' : 'The photo was not sent. Check your connection.';
    var retryable = true;
    for (var attempt = 0; attempt < 3 && data == null && retryable; attempt++) {
      try {
        final req = http.MultipartRequest('POST', Uri.parse('${url}api/v1/request/$endpoint'));
        req.headers.addAll({'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}', 'Accept': 'application/json'});
        req.fields.addAll({...fields, 'client_uuid': clientId, if (caption.isNotEmpty) 'caption': caption});
        req.files.add(await http.MultipartFile.fromPath('image', file.path));
        final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        if (res.statusCode == 200 && body is Map && body['data'] is Map) {
          data = Map<String, dynamic>.from(body['data']);
        } else {
          retryable = res.statusCode >= 500 || res.statusCode == 429;
          final errs = body is Map ? body['errors'] : null;
          if (errs is Map && errs.isNotEmpty) {
            error = '${(errs.values.first is List ? (errs.values.first as List).first : errs.values.first)}';
          } else if (body is Map && '${body['message'] ?? ''}'.isNotEmpty && res.statusCode < 500) {
            error = '${body['message']}';
          }
        }
      } catch (_) {
        retryable = true;
      }
      if (data == null && retryable) await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
    messenger.hideCurrentSnackBar();
    if (data == null) {
      messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFFB91C1C), content: Text(error)));
    }
    return data;
  }

  /// full screen with zoom (pinch / double tap), swipe down or ✕ to close
  static void open(BuildContext context, List<String> urls, {int index = 0}) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _PhotoViewer(urls: urls, index: index),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }
}

/// the photo(s) inside a chat bubble: rounded, a soft placeholder while loading, tap to open
class ChatPhotoTiles extends StatelessWidget {
  const ChatPhotoTiles({super.key, required this.urls, this.width = 230});
  final List<String> urls;
  final double width;

  @override
  Widget build(BuildContext context) {
    final shown = urls.take(4).toList();
    Widget tile(int i, double w, double h) => GestureDetector(
          onTap: () => ChatPhotos.open(context, urls, index: i),
          child: Hero(
            tag: '${urls[i]}#$i',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                width: w,
                height: h,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: w, height: h, color: const Color(0xffE7EEF8), child: const Icon(Icons.photo_outlined, color: Color(0xff9FB3D6))),
                errorWidget: (_, __, ___) => Container(
                  width: w,
                  height: h,
                  color: const Color(0xffF1F4F9),
                  alignment: Alignment.center,
                  child: Text(languageDirection == 'rtl' ? 'الصورة ما عادتش متاحة' : 'Photo no longer available',
                      style: GoogleFonts.cairo(color: const Color(0xff687994), fontSize: 12)),
                ),
              ),
            ),
          ),
        );
    if (shown.length == 1) return tile(0, width, width * .78);
    final half = (width - 4) / 2;
    return SizedBox(
      width: width,
      child: Wrap(spacing: 4, runSpacing: 4, children: [for (var i = 0; i < shown.length; i++) tile(i, half, half)]),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.index});
  final List<String> urls;
  final int index;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.index);
  late int _at = widget.index;
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: (1 - (_drag.abs() / 400)).clamp(.3, 1)),
      body: Stack(children: [
        GestureDetector(
          onVerticalDragUpdate: (d) => setState(() => _drag += d.delta.dy),
          onVerticalDragEnd: (_) {
            if (_drag.abs() > 120) {
              Navigator.pop(context);
            } else {
              setState(() => _drag = 0);
            }
          },
          child: Transform.translate(
            offset: Offset(0, _drag),
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _at = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: '${widget.urls[i]}#$i',
                    child: CachedNetworkImage(imageUrl: widget.urls[i], fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .12)),
              ),
              const Spacer(),
              if (widget.urls.length > 1)
                Text('${_at + 1} / ${widget.urls.length}', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}
