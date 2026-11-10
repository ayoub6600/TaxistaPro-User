import 'dart:async';

import 'package:flutter/material.dart';

/// One «صورة تحديث» set from Taxista Admin: a real screen of what is new.
class UpdateImage {
  const UpdateImage({required this.url, this.caption = ''});

  final String url;
  final String caption;

  static List<UpdateImage> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <UpdateImage>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final url = item['url']?.toString().trim() ?? '';
      if (!url.startsWith('https://') && !url.startsWith('http://')) continue;
      out.add(UpdateImage(url: url, caption: item['caption']?.toString().trim() ?? ''));
      if (out.length == 3) break;
    }
    return out;
  }

  Map<String, dynamic> toJson() => {'url': url, 'caption': caption};
}

/// The images side by side: swipe, or they turn by themselves every few seconds. An image that does
/// not load is simply left out; with none loaded the carousel takes no room.
class UpdateImagesCarousel extends StatefulWidget {
  const UpdateImagesCarousel({super.key, required this.images, this.accent = const Color(0xFF0873FF), this.autoTurn = const Duration(seconds: 4)});

  final List<UpdateImage> images;
  final Color accent;
  final Duration autoTurn;

  @override
  State<UpdateImagesCarousel> createState() => _UpdateImagesCarouselState();
}

class _UpdateImagesCarouselState extends State<UpdateImagesCarousel> {
  final _pages = PageController();
  final _broken = <int>{};
  int _at = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(widget.autoTurn, (_) {
        if (!mounted || !_pages.hasClients) return;
        final next = (_at + 1) % widget.images.length;
        _pages.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty || _broken.length == images.length) return const SizedBox.shrink();
    final caption = images[_at].caption;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AspectRatio(
        aspectRatio: 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: PageView.builder(
            key: const ValueKey('update_images'),
            controller: _pages,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _at = i),
            itemBuilder: (_, i) => ColoredBox(
              color: widget.accent.withValues(alpha: .08),
              child: Image.network(
                images[i].url,
                fit: BoxFit.cover,
                semanticLabel: images[i].caption,
                errorBuilder: (_, __, ___) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_broken.contains(i)) setState(() => _broken.add(i));
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
      if (images.length > 1) ...[
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < images.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _at ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(color: i == _at ? widget.accent : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
            ),
        ]),
      ],
      if (caption.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(caption, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      ],
    ]);
  }
}
