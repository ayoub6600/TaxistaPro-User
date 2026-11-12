import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One service on the home bar: «بدون وجهة», «سفر», «الشحن»…
class HomeService {
  const HomeService({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
    this.soon = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  /// «قريبًا»: shown, tappable (it says so), not working yet
  final bool soon;
}

/// The services bar under «البيت / العمل / مؤخرًا»: it scrolls sideways over the map (no card behind
/// it). The service at the focus (30% in from the right) is full size; the others are smaller the
/// farther they sit, labels always showing, so the rider sees there is more and scrolls to it.
/// It slides in once when the app opens and nudges once to show it scrolls.
class HomeServicesRow extends StatefulWidget {
  const HomeServicesRow({super.key, required this.services, this.rtl = true});

  final List<HomeService> services;
  final bool rtl;

  /// the slide-in plays once per app run
  static bool introPlayed = false;

  /// size for a centre at [distance] px from the focus point: 1 near it, down to 0.55
  static double scaleFor(double distance) {
    final d = distance.abs();
    if (d <= 60) return 1;
    return (1 - (d - 60) * .0032).clamp(.55, 1.0);
  }

  @override
  State<HomeServicesRow> createState() => _HomeServicesRowState();
}

class _HomeServicesRowState extends State<HomeServicesRow> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  late List<GlobalKey> _keys;
  late List<double> _k;
  late final AnimationController _intro;
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    _keys = [for (final _ in widget.services) GlobalKey()];
    _k = [for (var i = 0; i < widget.services.length; i++) i < 2 ? 1.0 : .7];
    _scroll.addListener(_measureSoon);
    final play = !HomeServicesRow.introPlayed;
    HomeServicesRow.introPlayed = true;
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700), value: play ? 0 : 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      if (!play || !mounted || MediaQuery.of(context).disableAnimations) {
        _intro.value = 1;
        return;
      }
      _intro.forward().whenComplete(_nudge);
    });
  }

  @override
  void didUpdateWidget(covariant HomeServicesRow old) {
    super.didUpdateWidget(old);
    if (old.services.length != widget.services.length) {
      _keys = [for (final _ in widget.services) GlobalKey()];
      _k = [for (var i = 0; i < widget.services.length; i++) i < 2 ? 1.0 : .7];
      _measureSoon();
    }
  }

  Future<void> _nudge() async {
    if (!mounted || !_scroll.hasClients || _scroll.position.maxScrollExtent < 30) return;
    await _scroll.animateTo(70, duration: const Duration(milliseconds: 420), curve: Curves.easeOut);
    if (!mounted) return;
    await _scroll.animateTo(0, duration: const Duration(milliseconds: 520), curve: Curves.easeInOut);
  }

  void _measureSoon() {
    if (_measuring) return;
    _measuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measuring = false;
      _measure();
    });
  }

  void _measure() {
    if (!mounted) return;
    final view = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (view == null || !view.hasSize) return;
    final viewLeft = view.localToGlobal(Offset.zero).dx;
    // the focus sits 30% in from the start edge (the right in Arabic)
    final focus = widget.rtl ? viewLeft + view.size.width * .7 : viewLeft + view.size.width * .3;
    var changed = false;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final centre = box.localToGlobal(Offset(box.size.width / 2, 0)).dx;
      final k = HomeServicesRow.scaleFor(centre - focus);
      if ((k - _k[i]).abs() > .01) {
        _k[i] = k;
        changed = true;
      }
    }
    if (changed) setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      key: _viewport,
      height: 54,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        // room at the end so the last service can reach the focus
        padding: EdgeInsetsDirectional.only(start: 2, end: width * .6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          for (var i = 0; i < widget.services.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _intro,
              builder: (context, child) {
                final t = Curves.easeOut.transform(((_intro.value * 1.4) - i * .1).clamp(0.0, 1.0));
                return Opacity(opacity: t, child: Transform.translate(offset: Offset((1 - t) * (widget.rtl ? -24 : 24), 0), child: child));
              },
              child: _ServiceChip(key: _keys[i], service: widget.services[i], k: _k[i]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({super.key, required this.service, required this.k});

  final HomeService service;
  final double k;

  @override
  Widget build(BuildContext context) {
    final s = service;
    final font = (13.5 * k).clamp(10.0, 13.5);
    return Semantics(
      button: true,
      label: s.soon ? '${s.label}، قريبًا' : s.label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: .4 + .6 * k,
        child: Material(
          color: s.background,
          elevation: 5,
          shadowColor: const Color(0xFF102A56).withValues(alpha: .25),
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: s.onTap,
            customBorder: const StadiumBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 44 * k,
              padding: EdgeInsetsDirectional.only(start: 6 * k, end: 11 * k),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 30 * k,
                  height: 30 * k,
                  decoration: BoxDecoration(color: s.iconBackground, shape: BoxShape.circle),
                  child: Icon(s.icon, size: 17 * k, color: s.iconColor),
                ),
                SizedBox(width: 6 * k),
                Text(s.label, style: GoogleFonts.cairo(fontSize: font, fontWeight: FontWeight.w800, color: s.foreground, height: 1.2)),
                if (s.soon && k > .95) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(8)),
                    child: Text('قريبًا', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w800, color: s.foreground)),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
