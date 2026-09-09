import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../functions/functions.dart';

class MapAdvertisementBanner extends StatefulWidget {
  const MapAdvertisementBanner({
    super.key,
    this.onAvailabilityChanged,
    this.compact = false,
  });

  final ValueChanged<bool>? onAvailabilityChanged;
  final bool compact;

  @override
  State<MapAdvertisementBanner> createState() => _MapAdvertisementBannerState();
}

class _MapAdvertisementBannerState extends State<MapAdvertisementBanner> {
  List<dynamic> _available = const [];
  String _signature = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAvailableBanners();
  }

  @override
  void didUpdateWidget(covariant MapAdvertisementBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveAvailableBanners();
  }

  void _resolveAvailableBanners() {
    final resolved = banners.where((banner) {
      return banner is Map &&
          (banner['image']?.toString().trim().isNotEmpty ?? false);
    }).toList(growable: false);
    final signature =
        resolved.map((banner) => banner['image']?.toString() ?? '').join('|');
    if (signature == _signature) return;
    _signature = signature;
    _available = resolved;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onAvailabilityChanged?.call(resolved.isNotEmpty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_available.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: widget.compact ? 0 : 12),
      child: _available.length == 1
          ? SizedBox(
              height: widget.compact ? 62 : null,
              child: widget.compact
                  ? _BannerCard(banner: _available.first)
                  : AspectRatio(
                      aspectRatio: 5,
                      child: _BannerCard(banner: _available.first),
                    ),
            )
          : CarouselSlider.builder(
              itemCount: _available.length,
              itemBuilder: (_, index, __) =>
                  _BannerCard(banner: _available[index]),
              options: CarouselOptions(
                aspectRatio: 5,
                height: widget.compact ? 62 : null,
                viewportFraction: 1,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 550),
                autoPlayCurve: Curves.easeOutCubic,
                pauseAutoPlayOnTouch: true,
              ),
            ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final dynamic banner;

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner['image']?.toString() ?? '';
    final targetUrl = banner['url']?.toString() ?? '';

    return Material(
      color: Colors.blueGrey.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: targetUrl.isEmpty ? null : () => _openUrl(targetUrl),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 180),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
