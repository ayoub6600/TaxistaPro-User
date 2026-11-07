import '../widgets/v2_skeleton.dart';
import 'package:flutter/material.dart';

import '../widgets/chat/chat_kit.dart';
import 'community_api.dart';
import 'community_kit.dart';
import 'driver_profile_page.dart';

/// "سواقيني": the drivers the rider added after good rides. Tap opens the driver's page; the
/// heart removes him. Only drivers the rider rode with can be here.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await CommunityApi.favorites();
    if (!mounted) return;
    setState(() {
      _items = items ?? _items;
      _failed = items == null;
    });
  }

  Future<void> _remove(Map<String, dynamic> driver) async {
    final id = int.tryParse('${driver['driver_id']}');
    if (id == null) return;
    final before = List<Map<String, dynamic>>.from(_items ?? const []);
    setState(() => _items!.removeWhere((d) => d['driver_id'] == driver['driver_id']));
    if (!await CommunityApi.removeFavorite(id) && mounted) {
      setState(() => _items = before);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الحذف، حاول مرة أخرى.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.background,
        appBar: communityAppBar(context, 'سواقيني', subtitle: 'السواق اللي يعجبوك. نعرضهم عليك أول وقت الطلب لو كانوا قريبين'),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _items == null
              ? (_failed ? _message(p, 'تعذر التحميل. اسحب للأسفل لإعادة المحاولة.') : const V2Skeleton())
              : _items!.isEmpty
                  ? _message(p, 'لا يوجد سائقون في «سواقيني» بعد.\nبعد رحلة جميلة اضغط على القلب لتضيف سائقك.', icon: Icons.favorite_border_rounded)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _tile(p, _items![i]),
                    ),
        ),
      ),
    );
  }

  Widget _tile(ChatPalette p, Map<String, dynamic> d) {
    final name = (d['name'] ?? '').toString();
    final rating = d['rating'];
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DriverProfilePage(driverId: int.parse('${d['driver_id']}'))))
            .then((_) => _load()),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            CommunityAvatar(photo: d['photo']?.toString(), name: name, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: p.text(15.5, weight: FontWeight.w700))),
                  if (d['verified'] == true) ...[const SizedBox(width: 4), Icon(Icons.verified_rounded, size: 16, color: p.mine)],
                ]),
                if ((d['car'] ?? '').toString().isNotEmpty) Text(d['car'].toString(), style: p.text(12.5, color: p.sub)),
                const SizedBox(height: 4),
                Wrap(spacing: 10, children: [
                  if (rating != null) _fact(p, Icons.star_rounded, '$rating', const Color(0xFFF59E0B)),
                  _fact(p, Icons.route_rounded, '${d['rides_together'] ?? 0} رحلة معًا', p.sub),
                  if (d['mutual'] == true) _fact(p, Icons.favorite_rounded, 'يفضّلك أيضًا', CommunityLook.heart),
                ]),
              ]),
            ),
            IconButton(
              tooltip: 'إزالة من سواقيني',
              icon: const Icon(Icons.favorite_rounded, color: CommunityLook.heart),
              onPressed: () => _remove(d),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _fact(ChatPalette p, IconData icon, String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(text, style: p.text(12, color: p.sub)),
      ]);

  Widget _message(ChatPalette p, String text, {IconData icon = Icons.wifi_off_rounded}) => ListView(children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: p.sub),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(text, textAlign: TextAlign.center, style: p.text(14, color: p.sub, height: 1.6)),
        ),
      ]);
}
