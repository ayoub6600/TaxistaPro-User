import 'package:flutter/material.dart';

const _taxistaBlue = Color(0xFF0873FF);
const _taxistaInk = Color(0xFF10213F);
const _taxistaMuted = Color(0xFF8593AA);
const _taxistaMint = Color(0xFF22B879);

class TripSelectionPlaceData {
  const TripSelectionPlaceData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}

class TripSelectionOverlay extends StatelessWidget {
  const TripSelectionOverlay({
    super.key,
    required this.rtl,
    required this.pickupAddress,
    required this.pickupSearchController,
    required this.destinationController,
    required this.pickupEditing,
    required this.destinationEditing,
    required this.onBack,
    required this.onPickupTap,
    required this.onPickupChanged,
    required this.onClearPickup,
    required this.onDestinationTap,
    required this.onDestinationChanged,
    required this.onClearDestination,
    required this.onChooseFromMap,
    required this.onContinue,
    required this.canContinue,
    required this.places,
    this.searchResults = const SizedBox.shrink(),
    this.infoMessage = '',
  });

  final bool rtl;
  final String pickupAddress;
  final TextEditingController pickupSearchController;
  final TextEditingController destinationController;
  final bool pickupEditing;
  final bool destinationEditing;
  final VoidCallback onBack;
  final VoidCallback onPickupTap;
  final ValueChanged<String> onPickupChanged;
  final VoidCallback onClearPickup;
  final VoidCallback onDestinationTap;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onClearDestination;
  final VoidCallback onChooseFromMap;
  final VoidCallback onContinue;
  final bool canContinue;
  final List<TripSelectionPlaceData> places;
  final Widget searchResults;
  final String infoMessage;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final panelHeight = (media.height * .70).clamp(500.0, 620.0).toDouble();

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        children: [
          Positioned(
            top: safeTop + 10,
            left: 18,
            right: 18,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -10 * (1 - value)),
                  child: child,
                ),
              ),
              child: _TripSelectionHeader(rtl: rtl, onBack: onBack),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboard,
            height: panelHeight,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 34 * (1 - value)),
                  child: child,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .98),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x240C274D),
                      blurRadius: 34,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5DCE6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AddressCard(
                              rtl: rtl,
                              pickupAddress: pickupAddress,
                              pickupSearchController: pickupSearchController,
                              destinationController: destinationController,
                              pickupEditing: pickupEditing,
                              destinationEditing: destinationEditing,
                              onPickupTap: onPickupTap,
                              onPickupChanged: onPickupChanged,
                              onClearPickup: onClearPickup,
                              onDestinationTap: onDestinationTap,
                              onDestinationChanged: onDestinationChanged,
                              onClearDestination: onClearDestination,
                            ),
                            if (infoMessage.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                infoMessage,
                                style: const TextStyle(
                                  color: _taxistaMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            searchResults,
                            const SizedBox(height: 12),
                            _MapSelectionCard(
                              rtl: rtl,
                              selectingPickup: pickupEditing,
                              onTap: onChooseFromMap,
                            ),
                            const SizedBox(height: 14),
                            _RecentPlacesCard(rtl: rtl, places: places),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: canContinue ? onContinue : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _taxistaBlue,
                            disabledBackgroundColor:
                                _taxistaBlue.withValues(alpha: .35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: canContinue ? 5 : 0,
                            shadowColor: _taxistaBlue.withValues(alpha: .35),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                rtl ? 'متابعة' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                rtl
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripSelectionHeader extends StatelessWidget {
  const _TripSelectionHeader({required this.rtl, required this.onBack});

  final bool rtl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A10213F),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              rtl ? 'تحديد الرحلة' : 'Plan your trip',
              style: const TextStyle(
                color: _taxistaInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Material(
              color: Colors.white,
              elevation: 5,
              shadowColor: const Color(0x2610213F),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _taxistaInk,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.rtl,
    required this.pickupAddress,
    required this.pickupSearchController,
    required this.destinationController,
    required this.pickupEditing,
    required this.destinationEditing,
    required this.onPickupTap,
    required this.onPickupChanged,
    required this.onClearPickup,
    required this.onDestinationTap,
    required this.onDestinationChanged,
    required this.onClearDestination,
  });

  final bool rtl;
  final String pickupAddress;
  final TextEditingController pickupSearchController;
  final TextEditingController destinationController;
  final bool pickupEditing;
  final bool destinationEditing;
  final VoidCallback onPickupTap;
  final ValueChanged<String> onPickupChanged;
  final VoidCallback onClearPickup;
  final VoidCallback onDestinationTap;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onClearDestination;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F10213F),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onPickupTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const _LocationMarker(
                    color: _taxistaBlue,
                    icon: Icons.circle,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rtl ? 'موقع الانطلاق' : 'Pickup location',
                          style: const TextStyle(
                            color: _taxistaMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (pickupEditing)
                          TextField(
                            controller: pickupSearchController,
                            autofocus: true,
                            onTap: onPickupTap,
                            onTapAlwaysCalled: true,
                            onChanged: onPickupChanged,
                            textInputAction: TextInputAction.search,
                            maxLines: 1,
                            style: const TextStyle(
                              color: _taxistaInk,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: rtl
                                  ? 'ابحث عن موقع الانطلاق'
                                  : 'Search for a pickup location',
                              hintStyle: const TextStyle(
                                color: _taxistaMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Text(
                            pickupAddress.isEmpty
                                ? (rtl
                                    ? 'جارٍ تحديد موقعك الحالي'
                                    : 'Finding your current location')
                                : pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _taxistaInk,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (pickupEditing && pickupSearchController.text.isNotEmpty)
                    IconButton(
                      tooltip: rtl ? 'مسح' : 'Clear',
                      onPressed: onClearPickup,
                      icon: const Icon(Icons.close_rounded),
                      color: _taxistaMuted,
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    const _SoftIcon(
                      icon: Icons.near_me_rounded,
                      color: _taxistaBlue,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 58, endIndent: 16),
          InkWell(
            onTap: onDestinationTap,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  const _LocationMarker(
                    color: _taxistaMint,
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: TextField(
                      controller: destinationController,
                      autofocus: destinationEditing,
                      onTap: onDestinationTap,
                      onTapAlwaysCalled: true,
                      onChanged: onDestinationChanged,
                      textInputAction: TextInputAction.search,
                      maxLines: 1,
                      style: const TextStyle(
                        color: _taxistaInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: rtl ? 'أدخل وجهتك' : 'Enter your destination',
                        hintStyle: const TextStyle(
                          color: _taxistaMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (destinationController.text.isNotEmpty)
                    IconButton(
                      tooltip: rtl ? 'مسح' : 'Clear',
                      onPressed: onClearDestination,
                      icon: const Icon(Icons.close_rounded),
                      color: _taxistaMuted,
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    const _SoftIcon(
                      icon: Icons.search_rounded,
                      color: _taxistaBlue,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSelectionCard extends StatelessWidget {
  const _MapSelectionCard({
    required this.rtl,
    required this.selectingPickup,
    required this.onTap,
  });

  final bool rtl;
  final bool selectingPickup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F8FF),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCEEFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDDF1FF), Color(0xFFE8FFF7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: _taxistaBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectingPickup
                          ? (rtl
                              ? 'اختيار موقع الانطلاق من الخريطة'
                              : 'Choose pickup from map')
                          : (rtl
                              ? 'اختيار الوجهة من الخريطة'
                              : 'Choose destination from map'),
                      style: const TextStyle(
                        color: _taxistaInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectingPickup
                          ? (rtl
                              ? 'حدد مكان وصول السائق مباشرة'
                              : 'Pin the driver meeting point directly')
                          : (rtl
                              ? 'حدد موقعًا مباشرة على الخريطة'
                              : 'Pin a location directly on the map'),
                      style: const TextStyle(
                        color: _taxistaMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                rtl
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: _taxistaBlue,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentPlacesCard extends StatelessWidget {
  const _RecentPlacesCard({required this.rtl, required this.places});

  final bool rtl;
  final List<TripSelectionPlaceData> places;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: _taxistaBlue,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Text(
                  rtl ? 'آخر الأماكن' : 'Recent places',
                  style: const TextStyle(
                    color: _taxistaInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < places.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _RecentPlaceRow(place: places[index], rtl: rtl),
          ],
          if (places.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  rtl ? 'لا توجد أماكن سابقة بعد' : 'No recent places yet',
                  style: const TextStyle(
                    color: _taxistaMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentPlaceRow extends StatelessWidget {
  const _RecentPlaceRow({required this.place, required this.rtl});

  final TripSelectionPlaceData place;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: place.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _SoftIcon(icon: place.icon, color: place.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _taxistaInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (place.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        place.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _taxistaMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: _taxistaMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
