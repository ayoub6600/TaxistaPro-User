import 'package:flutter/material.dart';

import '../widgets/chat/chat_kit.dart';
import 'community_api.dart';
import 'community_kit.dart';

/// At booking (ride now): "سائقك المفضل متاح". Shows only favourites the server found free, near
/// and fresh for this vehicle type; choosing one offers the request to him first, and the usual
/// search continues if he does not take it. Shows nothing when there is nobody.
class FavoriteDriverChoice extends StatefulWidget {
  final double pickLat;
  final double pickLng;
  final String? zoneTypeId;

  const FavoriteDriverChoice({super.key, required this.pickLat, required this.pickLng, required this.zoneTypeId});

  @override
  State<FavoriteDriverChoice> createState() => _FavoriteDriverChoiceState();
}

class _FavoriteDriverChoiceState extends State<FavoriteDriverChoice> {
  List<Map<String, dynamic>> _drivers = const [];
  String? _key;
  DateTime? _at;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FavoriteDriverChoice old) {
    super.didUpdateWidget(old);
    _load();
  }

  Future<void> _load() async {
    final zone = widget.zoneTypeId;
    if (zone == null || zone.isEmpty) {
      if (_drivers.isNotEmpty) setState(() => _drivers = const []);
      return;
    }
    final key = '$zone|${widget.pickLat.toStringAsFixed(3)}|${widget.pickLng.toStringAsFixed(3)}';
    // the same place and car type within a minute: nothing new to ask
    if (key == _key && _at != null && DateTime.now().difference(_at!) < const Duration(minutes: 1)) return;
    _key = key;
    _at = DateTime.now();
    final drivers = await CommunityApi.availableFavorites(widget.pickLat, widget.pickLng, zone);
    if (!mounted || key != _key) return;
    setState(() {
      _drivers = drivers;
      chosenFavoriteDriverIds.removeWhere((id) => !drivers.any((d) => '${d['driver_id']}' == '$id'));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_drivers.isEmpty) return const SizedBox.shrink();
    final p = CommunityLook.palette;
    final chosen = chosenFavoriteDriverIds;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: CommunityLook.heart.withValues(alpha: p.dark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CommunityLook.heart.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.favorite_rounded, color: CommunityLook.heart, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(_drivers.length == 1 ? 'سائقك المفضل متاح الآن' : 'من «سواقيني» متاحون الآن',
                style: p.text(13.5, weight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final d in _drivers) ...[
              _driver(p, d, chosen.contains(int.tryParse('${d['driver_id']}'))),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        if (chosen.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('يصلهم طلبك أولًا، وإن لم يقبلوا نكمل البحث عن أقرب سائق.', style: p.text(11.5, color: p.sub)),
          ),
      ]),
    );
  }

  Widget _driver(ChatPalette p, Map<String, dynamic> d, bool selected) {
    final name = '${d['name'] ?? ''}'.split(' ').first;
    return Semantics(
      selected: selected,
      button: true,
      label: 'اطلب $name',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() {
          final id = int.tryParse('${d['driver_id']}');
          if (id == null) return;
          selected ? chosenFavoriteDriverIds.remove(id) : chosenFavoriteDriverIds.add(id);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
          decoration: BoxDecoration(
            color: selected ? CommunityLook.heart : p.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? CommunityLook.heart : p.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CommunityAvatar(photo: d['photo']?.toString(), name: name, size: 30),
            const SizedBox(width: 8),
            Text('$name · ${d['distance_km'] ?? '?'} كم',
                style: p.text(13, weight: FontWeight.w700, color: selected ? Colors.white : p.ink)),
            if (selected) ...[const SizedBox(width: 4), const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)],
          ]),
        ),
      ),
    );
  }
}
