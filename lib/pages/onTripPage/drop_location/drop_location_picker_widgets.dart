part of '../drop_loc_select.dart';

const _pickerBlue = Color(0xFF0873FF);
const _pickerInk = Color(0xFF10213F);
const _pickerMuted = Color(0xFF8794AA);
const _pickerMint = Color(0xFF22B879);

class _TaxistaCenterPin extends StatelessWidget {
  const _TaxistaCenterPin({
    required this.moving,
    required this.selectingPickup,
  });

  final bool moving;
  final bool selectingPickup;

  @override
  Widget build(BuildContext context) {
    final color = selectingPickup ? _pickerBlue : _pickerMint;
    return SizedBox(
      width: 104,
      height: 116,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: moving ? 74 : 86,
            height: moving ? 74 : 86,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: moving ? .10 : .16),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(bottom: moving ? 25 : 12),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .28),
                  blurRadius: moving ? 22 : 14,
                  offset: Offset(0, moving ? 10 : 6),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: color,
              size: 47,
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: moving ? .25 : .55,
            child: Container(
              width: moving ? 15 : 11,
              height: moving ? 7 : 5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxistaMapControl extends StatelessWidget {
  const _TaxistaMapControl({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 5,
        shadowColor: const Color(0x240C274D),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(
              icon,
              color: _pickerBlue,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaxistaSelectedAddress extends StatelessWidget {
  const _TaxistaSelectedAddress({
    required this.address,
    required this.rtl,
    required this.canFavorite,
    required this.isFavorite,
    required this.onFavorite,
    required this.selectingPickup,
  });

  final String address;
  final bool rtl;
  final bool canFavorite;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final bool selectingPickup;

  @override
  Widget build(BuildContext context) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final primary = parts.isEmpty
        ? (rtl ? 'جارٍ تحديد العنوان…' : 'Finding the address…')
        : parts.first;
    final secondary = parts.length > 1 ? parts.skip(1).join('، ') : '';

    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (selectingPickup ? _pickerBlue : _pickerMint)
                  .withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              selectingPickup
                  ? Icons.my_location_rounded
                  : Icons.location_on_rounded,
              color: selectingPickup ? _pickerBlue : _pickerMint,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    color: _pickerInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (secondary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      color: _pickerMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canFavorite) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: rtl ? 'حفظ المكان' : 'Save place',
              onPressed: isFavorite ? null : onFavorite,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                fixedSize: const Size(44, 44),
              ),
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                color: isFavorite ? _pickerMint : _pickerBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
