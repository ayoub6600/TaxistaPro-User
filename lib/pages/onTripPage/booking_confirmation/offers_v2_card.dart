part of '../booking_confirmation.dart';

/// «العروض والبحث» v2 — one driver's price, wide: the price and minutes away, the driver (photo,
/// Taxista's captain beside it, rating, trips, car), and two answers: «غالي شوية» / «قبول بـ X».
/// The accept button drains with the time the offer has left.
class _OfferCardV2 extends StatelessWidget {
  const _OfferCardV2({
    required this.driver,
    required this.myFare,
    required this.currency,
    required this.badge,
    required this.leftRatio,
    required this.isAccepting,
    required this.locked,
    required this.onAccept,
    required this.onTooHigh,
    required this.onTap,
  });

  final NearbyDriverCandidate driver;
  final double myFare;
  final String currency;

  /// 'favorite' · 'best' · null (then «+N على سعرك»)
  final String? badge;
  final double leftRatio;
  final bool isAccepting;
  final bool locked;
  final VoidCallback onAccept;
  final VoidCallback onTooHigh;
  final VoidCallback onTap;

  static const _red = Color(0xffE11D48);

  @override
  Widget build(BuildContext context) {
    final price = driver.counterOffer ?? 0;
    final up = price - myFare;
    final fav = badge == 'favorite';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: fav ? _red : (badge == 'best' ? _searchBlue : const Color(0xffE3E9F2)), width: badge != null ? 2 : 1.5),
          boxShadow: [BoxShadow(color: const Color(0xff15386B).withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text('$currency ${OffersV2.money(price)}',
                textDirection: ui.TextDirection.ltr, style: GoogleFonts.cairo(color: _searchNavy, fontSize: 25, fontWeight: FontWeight.w900, height: 1.1)),
            const SizedBox(width: 8),
            if (driver.etaMinutes != null)
              Text('${driver.etaMinutes} د', style: GoogleFonts.cairo(color: const Color(0xff8492A8), fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            _badge(up),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Image.asset(_offerMascotAsset, width: 40, height: 46, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(width: 40)),
            Transform.translate(
              offset: const Offset(10, 0),
              child: Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: fav ? _red : const Color(0xff66E7DC), width: 2)),
                child: ClipOval(child: _DriverPortrait(driver: driver)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(driver.name.isEmpty ? 'كابتن قريب' : driver.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: _searchNavy, fontSize: 15.5, fontWeight: FontWeight.w800)),
                Text.rich(
                  TextSpan(children: [
                    if (driver.rating != null) ...[
                      const TextSpan(text: '★ ', style: TextStyle(color: Color(0xffF5A400))),
                      TextSpan(text: driver.rating!.toStringAsFixed(1)),
                    ],
                    if (driver.rating != null && driver.completedTrips != null) const TextSpan(text: ' · '),
                    if (driver.completedTrips != null) TextSpan(text: '${driver.completedTrips} رحلة'),
                  ]),
                  style: GoogleFonts.cairo(color: _searchMuted, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if (driver.carLine.isNotEmpty)
                  Text(driver.carLine,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: _searchNavy, fontSize: 13, fontWeight: FontWeight.w700)),
                if (driver.isFinishingNearby)
                  Text(_finishingNearbyLine(driver, true),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: const Color(0xff087F65), fontSize: 12, fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              flex: 4,
              child: _button(
                label: 'غالي شوية',
                filled: false,
                onTap: locked ? null : onTooHigh,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: _button(
                label: 'قبول بـ ${OffersV2.money(price)}',
                filled: true,
                busy: isAccepting,
                onTap: locked ? null : onAccept,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(double up) {
    final (text, bg, fg) = switch (badge) {
      'favorite' => ('❤ سائقك المفضل', const Color(0xffFFE4E8), const Color(0xffBE123C)),
      'best' => ('أفضل عرض', _searchBlue, Colors.white),
      _ => ('‎+${OffersV2.money(up)} على سعرك', const Color(0xffFFF4E0), const Color(0xffB45309)),
    };
    if (badge == null && up <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: GoogleFonts.cairo(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _button({required String label, required bool filled, bool busy = false, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled ? _searchBlue : const Color(0xffF3F7FE),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Stack(children: [
              if (filled)
                // the offer's time left, draining from the end
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerEnd,
                    widthFactor: leftRatio.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0xff0559C9)),
                  ),
                ),
              Center(
                child: busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(label, style: GoogleFonts.cairo(color: filled ? Colors.white : _searchNavy, fontSize: 15.5, fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// While he plays: the best offer pinned above the game, so none is missed.
class _OfferStripV2 extends StatelessWidget {
  const _OfferStripV2({required this.top, required this.count, required this.currency, required this.leftRatio, required this.onAccept, required this.onShowAll});

  final NearbyDriverCandidate top;
  final int count;
  final String currency;
  final double leftRatio;
  final VoidCallback onAccept;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final name = top.name.isEmpty ? 'كابتن' : top.name;
    final price = OffersV2.money(top.counterOffer ?? 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _searchBlue, width: 2)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
                // the favourite comes first even when another price is lower: never call it «أفضلها»
                '${top.isFavorite ? '❤' : '🚕'} ${count == 1 ? 'عرض من $name' : (top.isFavorite ? '$count عروض · سائقك المفضل $name' : '$count عروض · أفضلها من $name')} · $currency $price',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: _searchNavy, fontSize: 13, fontWeight: FontWeight.w800)),
            if (top.carLine.isNotEmpty)
              Text([top.carLine, if (top.etaMinutes != null) '${top.etaMinutes} د'].join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: _searchMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 74,
          height: 40,
          child: Material(
            color: _searchBlue,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAccept,
              child: Stack(children: [
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerEnd,
                    widthFactor: leftRatio.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0xff0559C9)),
                  ),
                ),
                Center(child: Text('قبول', style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 40,
          child: TextButton(
            onPressed: onShowAll,
            style: TextButton.styleFrom(backgroundColor: const Color(0xffF3F7FE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('العروض', style: GoogleFonts.cairo(color: _searchNavy, fontSize: 13.5, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
