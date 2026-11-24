import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_services.dart';

const _ink = Color(0xFF10213F);
const _muted = Color(0xFF64748B);
const _blue = Color(0xFF0873FF);
const _track = Color(0x330873FF);
const _field = Color(0xFFF1F3F6);

/// The calm frosted-glass panel pinned at the bottom of the home map.
///
/// Compact: «إلى أين؟» with «أماكني» beside it, then the services as tinted rounded squares that scroll
/// sideways (a blue line under them follows the real scroll). Dragged up, the same panel grows
/// over the map and shows «خدمات أخرى» ([more]: other pages the app has, never the services of the
/// row again); dragged down it goes back. [above] floats over the map just above the panel (the
/// gift bar, the location button…); each of its pieces keeps its own bottom margin.
///
/// One BackdropFilter for the whole panel (none per item), so it stays light.
class RiderHomeSheet extends StatefulWidget {
  const RiderHomeSheet({
    super.key,
    required this.services,
    required this.onWhereTo,
    required this.onPlaces,
    this.more = const [],
    this.above,
    this.expanded,
    this.rtl = true,
  });

  final List<HomeService> services;

  /// «خدمات أخرى»: each one a page that really exists
  final List<HomeService> more;
  final VoidCallback onWhereTo;
  final VoidCallback onPlaces;
  final Widget Function(BuildContext context, bool expanded)? above;

  /// tells the page when the panel is up (the cards at the top step aside)
  final ValueNotifier<bool>? expanded;
  final bool rtl;

  // the compact part has fixed heights, so the panel knows its own size on any phone
  static const double handleHeight = 22;
  static const double searchHeight = 52;
  static const double serviceWidth = 76;
  static const double serviceMinWidth = 68;
  static const double serviceHeight = 94;
  static const double trackHeight = 4;
  static const double sectionGap = 12;
  static const double otherHeaderHeight = 40;
  static const double otherRowHeight = 52;

  /// handle, search row, services and the line under them (no bottom inset)
  static double compactBody() => handleHeight + searchHeight + 12 + serviceHeight + 6 + trackHeight;

  @override
  State<RiderHomeSheet> createState() => _RiderHomeSheetState();
}

class _RiderHomeSheetState extends State<RiderHomeSheet> {
  final DraggableScrollableController _sheet = DraggableScrollableController();
  bool _up = false;

  /// 0 compact … 1 pulled up: «خدمات أخرى» fades in with it (in compact it sits, unseen, over the
  /// phone's bottom inset)
  final ValueNotifier<double> _reveal = ValueNotifier(0);

  double _min = .3;
  double _max = .6;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSheet);
  }

  @override
  void dispose() {
    _sheet.removeListener(_onSheet);
    _sheet.dispose();
    _reveal.dispose();
    widget.expanded?.value = false;
    super.dispose();
  }

  void _onSheet() {
    if (!_sheet.isAttached) return;
    _reveal.value = ((_sheet.size - _min) / (_max - _min)).clamp(0.0, 1.0);
    final up = _sheet.size > (_min + _max) / 2;
    if (up != _up) {
      setState(() => _up = up);
      widget.expanded?.value = up;
    }
  }

  void _toggle() {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(_up ? _min : _max, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final more = widget.more;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Directionality(
        textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: LayoutBuilder(builder: (context, box) {
          final height = box.maxHeight;
          final compact = RiderHomeSheet.compactBody() + math.max(padding.bottom, 14.0);
          final wanted = RiderHomeSheet.compactBody() +
              RiderHomeSheet.sectionGap +
              (more.isEmpty ? 0 : RiderHomeSheet.otherHeaderHeight + more.length * RiderHomeSheet.otherRowHeight + 8) +
              padding.bottom +
              8;
          // the top of the map (menu, notifications, the floating gift) stays in sight
          final room = height - padding.top - 140;
          _min = (compact / height).clamp(.05, .95);
          _max = (math.max(math.min(wanted, room), compact + 1) / height).clamp(_min + .001, 1.0);
          return PopScope(
            canPop: !_up,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && _up) _toggle();
            },
            child: Stack(children: [
              if (widget.above != null)
                AnimatedBuilder(
                  animation: _sheet,
                  builder: (context, child) {
                    final size = _sheet.isAttached ? _sheet.size : _min;
                    return Positioned(left: 16, right: 16, bottom: size * height + 2, child: child!);
                  },
                  child: widget.above!(context, _up),
                ),
              DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: _min,
                minChildSize: _min,
                maxChildSize: _max,
                snap: true,
                builder: (context, scroll) => _Panel(
                  scroll: scroll,
                  services: widget.services,
                  more: more,
                  reveal: _reveal,
                  bottomInset: padding.bottom,
                  rtl: widget.rtl,
                  onWhereTo: widget.onWhereTo,
                  onPlaces: widget.onPlaces,
                  onHandle: _toggle,
                  up: _up,
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.scroll,
    required this.services,
    required this.more,
    required this.reveal,
    required this.bottomInset,
    required this.rtl,
    required this.onWhereTo,
    required this.onPlaces,
    required this.onHandle,
    required this.up,
  });

  final ScrollController scroll;
  final List<HomeService> services;
  final List<HomeService> more;
  final ValueListenable<double> reveal;
  final double bottomInset;
  final bool rtl;
  final VoidCallback onWhereTo;
  final VoidCallback onPlaces;
  final VoidCallback onHandle;
  final bool up;

  static const _radius = BorderRadius.vertical(top: Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // soft layered shadows: a wide faint one and a close one
      decoration: const BoxDecoration(
        borderRadius: _radius,
        boxShadow: [BoxShadow(color: Color(0x120B2350), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _radius,
              // frosted white with a hairline edge
              color: Colors.white.withValues(alpha: .9),
              border: Border(top: BorderSide(color: Colors.black.withValues(alpha: .06), width: .5)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: CustomScrollView(
                controller: scroll,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Semantics(
                        button: true,
                        label: up ? (rtl ? 'تصغير' : 'Collapse') : (rtl ? 'خدمات أخرى' : 'More services'),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onHandle,
                          child: SizedBox(
                            height: RiderHomeSheet.handleHeight,
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4.5,
                                decoration: BoxDecoration(color: const Color(0x3310213F), borderRadius: BorderRadius.circular(99)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: RiderHomeSheet.searchHeight,
                          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Expanded(child: _WhereTo(rtl: rtl, onTap: onWhereTo)),
                            const SizedBox(width: 10),
                            _PlacesButton(rtl: rtl, onTap: onPlaces),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      HomeServicesStrip(services: services, rtl: rtl),
                      const SizedBox(height: RiderHomeSheet.sectionGap),
                    ]),
                  ),
                  if (more.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Reveal(
                        reveal: reveal,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          SizedBox(
                            height: RiderHomeSheet.otherHeaderHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(rtl ? 'خدمات أخرى' : 'More',
                                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: _muted, height: 1.2)),
                              ),
                            ),
                          ),
                          // one grouped list, iOS Settings style
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black.withValues(alpha: .05), width: .5),
                            ),
                            child: Column(children: [
                              for (var i = 0; i < more.length; i++) _MoreLine(item: more[i], rtl: rtl, last: i == more.length - 1),
                            ]),
                          ),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: bottomInset + 8)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.reveal, required this.child});

  final ValueListenable<double> reveal;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: reveal,
        builder: (context, t, child) => IgnorePointer(
          ignoring: t < .5,
          child: Opacity(opacity: Curves.easeIn.transform(t), child: child),
        ),
        child: child,
      );
}

/// An iOS-style service icon: a soft rounded square tinted with the service's colour and the
/// glyph in that colour. Flat: no gradient, no shine, no shadow.
class HomeServiceIcon extends StatelessWidget {
  const HomeServiceIcon({super.key, required this.icon, required this.color, this.size = 48});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(size * .3)),
        child: Icon(icon, color: color, size: size * .5),
      );
}

class _WhereTo extends StatelessWidget {
  const _WhereTo({required this.rtl, required this.onTap});

  final bool rtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = rtl ? 'إلى أين؟' : 'Where to?';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: _field,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const ValueKey('home-where-to'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 12),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 22, color: _muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w600, color: _ink, height: 1.2)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PlacesButton extends StatelessWidget {
  const _PlacesButton({required this.rtl, required this.onTap});

  final bool rtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: rtl ? 'أماكني' : 'My places',
        excludeSemantics: true,
        child: Material(
          color: _field,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: const ValueKey('home-places'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox.square(
              dimension: RiderHomeSheet.searchHeight,
              child: Icon(Icons.bookmark_border_rounded, color: _blue, size: 24),
            ),
          ),
        ),
      );
}

/// The services as small circles in one sideways row (from the right in Arabic), with a light-blue
/// line under them whose blue part follows the real scroll; the line hides when every service fits.
class HomeServicesStrip extends StatefulWidget {
  const HomeServicesStrip({super.key, required this.services, this.rtl = true});

  final List<HomeService> services;
  final bool rtl;

  @override
  State<HomeServicesStrip> createState() => _HomeServicesStripState();
}

class _HomeServicesStripState extends State<HomeServicesStrip> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<ScrollMetrics?> _metrics = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  void _read() {
    if (!mounted || !_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    _metrics.value = _scroll.position.copyWith();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _metrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: RiderHomeSheet.serviceHeight,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            _metrics.value = n.metrics.copyWith();
            return false;
          },
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (n) {
              if (n.depth == 0) _metrics.value = n.metrics.copyWith();
              return false;
            },
            child: LayoutBuilder(builder: (context, box) {
              // all of them share the width when each still gets a comfortable size; else they scroll
              final count = widget.services.length;
              final share = count == 0 ? 0.0 : (box.maxWidth - 16) / count;
              final extent = share >= RiderHomeSheet.serviceMinWidth ? math.min(share, 92.0) : RiderHomeSheet.serviceWidth;
              return ListView.builder(
                key: const ValueKey('home-services'),
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemExtent: extent,
                itemCount: count,
                itemBuilder: (context, i) => _ServiceCircle(service: widget.services[i], rtl: widget.rtl),
              );
            }),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ValueListenableBuilder<ScrollMetrics?>(
          valueListenable: _metrics,
          builder: (context, m, _) => ServicesScrollTrack(metrics: m),
        ),
      ),
    ]);
  }
}

/// The light-blue line under the services: the blue part is as long as the part in sight and sits
/// where the scroll is (at the right in Arabic when nothing is scrolled). Nothing when all fit.
class ServicesScrollTrack extends StatelessWidget {
  const ServicesScrollTrack({super.key, required this.metrics});

  final ScrollMetrics? metrics;

  static bool showsFor(ScrollMetrics? m) => m != null && m.hasContentDimensions && m.maxScrollExtent > .5;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    if (!showsFor(m)) return const SizedBox(height: RiderHomeSheet.trackHeight);
    return SizedBox(
      key: const ValueKey('services-track'),
      height: RiderHomeSheet.trackHeight,
      child: LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final total = m!.viewportDimension + m.maxScrollExtent - m.minScrollExtent;
        final bar = (width * m.viewportDimension / total).clamp(28.0, width);
        final progress = ((m.pixels - m.minScrollExtent) / (m.maxScrollExtent - m.minScrollExtent)).clamp(0.0, 1.0);
        return Stack(children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: _track, borderRadius: BorderRadius.circular(99)))),
          PositionedDirectional(
            key: const ValueKey('services-track-bar'),
            start: progress * (width - bar),
            top: 0,
            bottom: 0,
            width: bar,
            child: DecoratedBox(decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(99))),
          ),
        ]);
      }),
    );
  }
}

class _ServiceCircle extends StatelessWidget {
  const _ServiceCircle({required this.service, required this.rtl});

  final HomeService service;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = service;
    final soon = rtl ? 'قريبًا' : 'Soon';
    return Semantics(
      button: true,
      label: s.soon ? '${s.label}، $soon' : s.label,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('home-service-${s.id}'),
        onTap: s.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          const SizedBox(height: 3),
          // a closed service keeps its place, a little quieter
          Opacity(opacity: s.soon ? .5 : 1, child: HomeServiceIcon(icon: s.icon, color: s.color, size: 50)),
          const SizedBox(height: 6),
          SizedBox(
            height: 18,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(s.label, maxLines: 1, style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink, height: 1.2)),
              ),
            ),
          ),
          const SizedBox(height: 1),
          SizedBox(
            height: 16,
            child: s.soon
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(color: const Color(0xFFEEF1F5), borderRadius: BorderRadius.circular(99)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(soon, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: _muted, height: 1.3)),
                    ),
                  )
                : null,
          ),
        ]),
      ),
    );
  }
}

class _MoreLine extends StatelessWidget {
  const _MoreLine({required this.item, required this.rtl, required this.last});

  final HomeService item;
  final bool rtl;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = item;
    return Semantics(
      button: true,
      label: s.label,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('home-more-${s.id}'),
        onTap: s.onTap,
        child: SizedBox(
          height: RiderHomeSheet.otherRowHeight,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(width: 14),
            Center(child: HomeServiceIcon(icon: s.icon, color: s.color, size: 32)),
            const SizedBox(width: 12),
            // the hairline starts under the label, as in iOS Settings
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: last ? null : Border(bottom: BorderSide(color: Colors.black.withValues(alpha: .08), width: .5)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: _ink, height: 1.2)),
                  ),
                  Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: const Color(0xFFC4CAD3), size: 22),
                  const SizedBox(width: 10),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
