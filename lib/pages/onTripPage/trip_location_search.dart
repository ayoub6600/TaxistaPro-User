import 'dart:async';

import 'package:flutter/material.dart';

import 'trip_place.dart';

/// A self-contained trip editor: selecting a destination never depends on a
/// pickup already existing, and neither search nor map selection navigates
/// until both points have been explicitly reviewed.
class TripLocationSearch extends StatefulWidget {
  const TripLocationSearch({
    super.key,
    required this.rtl,
    required this.initialSelection,
    required this.recentPlaces,
    required this.favoritePlaces,
    required this.searchPlaces,
    required this.resolvePlace,
    required this.pickOnMap,
    required this.onConfirm,
    required this.onClose,
    this.initialRole = TripPointRole.destination,
  });

  final bool rtl;
  final TripSelection initialSelection;
  final TripPointRole initialRole;
  final List<TripPlace> recentPlaces;
  final List<TripPlace> favoritePlaces;
  final Future<List<TripPlace>> Function(String) searchPlaces;
  final Future<TripPlace?> Function(TripPlace) resolvePlace;
  final Future<TripPlace?> Function(TripPointRole, TripPlace?) pickOnMap;
  final ValueChanged<TripSelection> onConfirm;
  final VoidCallback onClose;

  @override
  State<TripLocationSearch> createState() => _TripLocationSearchState();
}

class _TripLocationSearchState extends State<TripLocationSearch> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  late TripSelection _selection = widget.initialSelection;
  late TripPointRole _role = widget.initialRole;
  List<TripPlace> _results = [];
  int _searchGeneration = 0;
  bool _searching = false;
  bool _selecting = false;
  String? _error;

  static const _blue = Color(0xFF0879FA);
  static const _green = Color(0xFF16875A);

  String _copy(String ar, String en) => widget.rtl ? ar : en;
  String _label(TripPointRole role) => role == TripPointRole.pickup
      ? _copy('نقطة مقابلة السائق', 'Driver meeting point')
      : _copy('الوجهة', 'Destination');

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setRole(TripPointRole role, {bool focus = true}) {
    _debounce?.cancel();
    _searchGeneration++;
    setState(() {
      _role = role;
      _query.clear();
      _results = [];
      _error = null;
      _searching = false;
    });
    if (focus) _focus.requestFocus();
  }

  void _search(String input) {
    _debounce?.cancel();
    final generation = ++_searchGeneration;
    setState(() {
      _error = null;
      _results = [];
      _searching = input.trim().length >= 2;
    });
    if (!_searching) return;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await widget.searchPlaces(input.trim());
        if (!mounted || generation != _searchGeneration) return;
        setState(() {
          _results = results;
          _searching = false;
        });
      } catch (_) {
        if (!mounted || generation != _searchGeneration) return;
        setState(() {
          _searching = false;
          _error = _copy('تعذّر البحث الآن. جرّب مجددًا أو حدّد المكان على الخريطة.',
              'Search is unavailable. Retry or choose the point on the map.');
        });
      }
    });
  }

  Future<void> _select(TripPlace place) async {
    if (_selecting) return;
    final role = _role;
    setState(() {
      _selecting = true;
      _error = null;
    });
    try {
      final resolved = place.coordinates != null
          ? place
          : await widget.resolvePlace(place);
      if (!mounted) return;
      if (resolved?.coordinates == null) {
        throw StateError('Unresolved place');
      }
      _applySelection(role, resolved!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = _copy(
          'لم نتمكن من تحديد هذا العنوان. جرّب مرة أخرى أو اختره على الخريطة.',
          'We could not locate this address. Retry or select it on the map.'));
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  void _applySelection(TripPointRole role, TripPlace place) {
    _debounce?.cancel();
    _searchGeneration++;
    setState(() {
      _selection = _selection.select(role, place);
      _query.clear();
      _results = [];
      _error = null;
      _searching = false;
      final other = role == TripPointRole.pickup
          ? TripPointRole.destination
          : TripPointRole.pickup;
      if (_selection.point(other) == null) _role = other;
    });
    if (_selection.isComplete) {
      _focus.unfocus();
    } else {
      _focus.requestFocus();
    }
  }

  Future<void> _pickMap() async {
    if (_selecting) return;
    _focus.unfocus();
    final role = _role;
    setState(() => _selecting = true);
    try {
      final selected = await widget.pickOnMap(role, _selection.point(role));
      if (!mounted || selected == null) return;
      if (selected.coordinates != null) _applySelection(role, selected);
    } catch (_) {
      if (mounted) {
        setState(() => _error = _copy('تعذّر فتح الخريطة. حاول مجددًا.',
            'The map could not open. Please retry.'));
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Widget _pointCard(TripPointRole role) {
    final selected = _selection.point(role);
    final active = _role == role;
    final color = role == TripPointRole.pickup ? _green : _blue;
    return Material(
      color: active ? color.withValues(alpha: .065) : const Color(0xFFF6F8FC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('trip-${role.name}'),
        onTap: _selecting ? null : () => _setRole(role),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: active ? color : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(role == TripPointRole.pickup
                ? Icons.trip_origin_rounded : Icons.location_on_rounded,
                color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(role), style: TextStyle(color: color,
                    fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 3),
                Text(selected?.address ?? _copy('اختر المكان', 'Choose a place'),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
              ])),
            if (selected != null)
              IconButton(
                tooltip: _copy('مسح العنوان', 'Clear address'),
                onPressed: _selecting ? null : () {
                  setState(() => _selection = _selection.select(role, null));
                  _setRole(role);
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
          ]),
        ),
      ),
    );
  }

  Widget _places(List<TripPlace> places, IconData icon) => Column(
        children: places.map((place) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: CircleAvatar(backgroundColor: const Color(0xFFEDF3FA),
              child: Icon(icon, color: _blue, size: 21)),
          title: Text(place.address, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.4)),
          trailing: const Icon(Icons.north_west_rounded, size: 17,
              color: Colors.blueGrey),
          onTap: _selecting ? null : () => _select(place),
        )).toList(),
      );

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.text.trim().isNotEmpty;
    return Directionality(
      textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(children: [
                IconButton(onPressed: widget.onClose,
                    tooltip: _copy('العودة للخريطة', 'Back to map'),
                    icon: const BackButtonIcon()),
                Expanded(child: Text(_copy('خطّط لرحلتك', 'Plan your ride'),
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
              ]),
            ),
            Expanded(child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _pointCard(TripPointRole.pickup),
                const SizedBox(height: 10),
                _pointCard(TripPointRole.destination),
                const SizedBox(height: 18),
                Text(_role == TripPointRole.pickup
                    ? _copy('أين تريد أن يقابلك السائق؟', 'Where should your driver meet you?')
                    : _copy('إلى أين تريد الذهاب؟', 'Where would you like to go?'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('trip-place-search'),
                  controller: _query, focusNode: _focus, autofocus: true,
                  enabled: !_selecting,
                  textInputAction: TextInputAction.search,
                  onChanged: _search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: _copy('ابحث عن مكان أو عنوان', 'Search for a place or address'),
                    prefixIcon: const Icon(Icons.search_rounded, color: _blue),
                    suffixIcon: hasQuery ? IconButton(
                      onPressed: () { _query.clear(); _search(''); },
                      icon: const Icon(Icons.close_rounded),
                    ) : null,
                    filled: true, fillColor: const Color(0xFFF6F8FC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const ValueKey('trip-pick-map'),
                  onPressed: _selecting ? null : _pickMap,
                  icon: Icon(Icons.map_outlined,
                      color: _role == TripPointRole.pickup ? _green : _blue),
                  label: Text(_copy('حدّد المكان على الخريطة', 'Choose on the map')),
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48),
                      foregroundColor: _blue),
                ),
                if (_searching || _selecting) ...[
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(minHeight: 2, color: _blue),
                  const SizedBox(height: 12),
                ],
                if (_error != null)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFB42318),
                        fontSize: 14, height: 1.45))),
                if (hasQuery) ...[
                  _places(_results, Icons.location_on_outlined),
                  if (!_searching && _results.isEmpty && _error == null)
                    Padding(padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(_copy('اكتب اسم المكان، أو حدّده مباشرة على الخريطة.',
                          'Enter a place name, or choose it directly on the map.'),
                          style: const TextStyle(color: Colors.blueGrey, height: 1.5))),
                ] else ...[
                  if (widget.recentPlaces.isNotEmpty) ...[
                    Text(_copy('عمليات البحث الأخيرة', 'Recent searches'),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                    _places(widget.recentPlaces, Icons.history_rounded),
                  ],
                  if (widget.favoritePlaces.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_copy('أماكنك المحفوظة', 'Saved places'),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                    _places(widget.favoritePlaces, Icons.star_outline_rounded),
                  ],
                ],
              ],
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('trip-confirm-points'),
                  onPressed: _selection.isComplete && !_selecting
                      ? () { _focus.unfocus(); widget.onConfirm(_selection); } : null,
                  style: FilledButton.styleFrom(backgroundColor: _blue,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(_selection.isComplete
                      ? _copy('تأكيد نقطة اللقاء والوجهة', 'Confirm pickup and destination')
                      : _selection.pickup == null
                          ? _copy('حدّد نقطة مقابلة السائق', 'Choose a driver meeting point')
                          : _copy('حدّد وجهتك للمتابعة', 'Choose your destination to continue'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                )),
            ),
          ]),
        ),
      ),
    );
  }
}
