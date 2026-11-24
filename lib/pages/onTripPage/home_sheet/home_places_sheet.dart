import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _ink = Color(0xFF10213F);
const _muted = Color(0xFF687994);

/// One saved or recent destination in «أماكني».
class HomeQuickDestination {
  const HomeQuickDestination({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isConfigured = true,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  /// false: «البيت» / «الشغل» not saved yet; the tap adds it
  final bool isConfigured;
}

/// «أماكني»: home, work and the recent destinations, from the bookmark button on the home sheet.
/// The sheet closes first, then the place's own action runs (the same as before on the home cards).
Future<void> showHomePlacesSheet(BuildContext context, {required bool rtl, required List<HomeQuickDestination> places}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: HomePlacesList(
        rtl: rtl,
        places: places,
        onPick: (place) {
          Navigator.of(sheetContext).pop();
          place.onTap();
        },
      ),
    ),
  );
}

class HomePlacesList extends StatelessWidget {
  const HomePlacesList({super.key, required this.rtl, required this.places, required this.onPick});

  final bool rtl;
  final List<HomeQuickDestination> places;
  final void Function(HomeQuickDestination place) onPick;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * .75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(color: const Color(0xFFD5DCE6), borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(rtl ? 'أماكني' : 'My places', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: places.length,
                itemBuilder: (context, i) => _PlaceRow(place: places[i], rtl: rtl, onTap: () => onPick(places[i])),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.rtl, required this.onTap});

  final HomeQuickDestination place;
  final bool rtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: place.accent.withValues(alpha: .11), shape: BoxShape.circle),
            child: Icon(place.icon, color: place.accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(place.label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: _ink, height: 1.3)),
              if (place.subtitle.isNotEmpty)
                Text(place.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: _muted, height: 1.3)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(
            place.isConfigured ? (rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded) : Icons.add_rounded,
            color: const Color(0xFF9AA7B8),
          ),
        ]),
      ),
    );
  }
}
