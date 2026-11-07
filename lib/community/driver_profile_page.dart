import '../widgets/v2_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/chat/chat_kit.dart';
import 'community_api.dart';
import 'community_kit.dart';

/// A driver's page as riders see it: rating, rides, the badges riders gave him, approved
/// comments, what his car offers. A limited profile is only shown to riders who rode with him.
class DriverProfilePage extends StatefulWidget {
  final int driverId;
  const DriverProfilePage({super.key, required this.driverId});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loaded = false;
  bool _busy = false;

  // the server's reasons (Moderation::REASONS)
  static const _reportReasons = {
    'offensive': 'محتوى مسيء',
    'false': 'معلومات غير صحيحة',
    'harassment': 'إزعاج أو تحرش',
    'privacy': 'كشف معلومات خاصة',
    'other': 'سبب آخر',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await CommunityApi.driverProfile(widget.driverId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loaded = true;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_profile == null || _busy) return;
    final on = _profile!['is_favorite'] != true;
    setState(() => _busy = true);
    final ok = on ? await CommunityApi.addFavorite(widget.driverId) : await CommunityApi.removeFavorite(widget.driverId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _profile!['is_favorite'] = on;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تقدر تضيفه لمفضلتك بعد رحلة مكتملة معه.')));
    }
  }

  Future<void> _report() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final p = CommunityLook.palette;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: const EdgeInsets.all(16), child: Text('الإبلاغ عن هذه الصفحة', style: p.text(16, weight: FontWeight.w700))),
              for (final e in _reportReasons.entries)
                ListTile(title: Text(e.value, style: p.text(14)), onTap: () => Navigator.pop(context, e.key)),
            ]),
          ),
        );
      },
    );
    if (reason == null) return;
    final ok = await CommunityApi.report('driver_profile', '${widget.driverId}', reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'وصل بلاغك، ستراجعه الإدارة.' : 'تعذر الإرسال.')));
  }

  Future<void> _block() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حظر هذا السائق؟'),
          content: const Text('لن يظهر لك في «سواقيني» ولن تُعرض عليه طلباتك كسائق مفضل، ولن يرى صفحتك.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حظر')),
          ],
        ),
      ),
    );
    if (sure != true) return;
    final ok = await CommunityApi.blockDriver(widget.driverId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الحظر.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    final d = _profile;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.background,
        appBar: communityAppBar(context, 'صفحة السائق', actions: [
          if (d != null && d['is_self'] != true)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'report' ? _report() : _block(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('إبلاغ')),
                PopupMenuItem(value: 'block', child: Text('حظر')),
              ],
            ),
        ]),
        body: !_loaded
            ? const V2Skeleton()
            : d == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('هذه الصفحة غير متاحة.', textAlign: TextAlign.center, style: p.text(14, color: p.sub)),
                    ),
                  )
                : _page(p, d),
      ),
    );
  }

  Widget _page(ChatPalette p, Map<String, dynamic> d) {
    final name = (d['name'] ?? '').toString();
    final badges = d['badges'] is List ? d['badges'] as List : const [];
    final comments = d['comments'] is List ? d['comments'] as List : const [];
    final amenities = d['amenities'] is List ? d['amenities'] as List : const [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      CommunityCard(
        child: Column(children: [
          CommunityAvatar(photo: d['photo']?.toString(), name: name, size: 84),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text(name, style: p.text(20, weight: FontWeight.w700))),
            if (d['verified'] == true) ...[const SizedBox(width: 6), Icon(Icons.verified_rounded, color: p.mine, size: 20)],
          ]),
          if ((d['car'] ?? '').toString().isNotEmpty) Text(d['car'].toString(), style: p.text(13, color: p.sub)),
          if ((d['city'] ?? '').toString().isNotEmpty) Text(d['city'].toString(), style: p.text(12.5, color: p.sub)),
          const SizedBox(height: 14),
          Row(children: [
            _stat(p, d['rating'] != null ? '${d['rating']}' : '—', 'التقييم'),
            _stat(p, '${d['completed_rides'] ?? 0}', 'رحلة'),
            _stat(p, '${d['fans'] ?? 0}', 'معجب'),
            if (d['rides_together'] != null) _stat(p, '${d['rides_together']}', 'معك'),
          ]),
          if (d['is_self'] != true) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CommunityLook.heart),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: d['is_favorite'] == true ? CommunityLook.heart.withValues(alpha: 0.08) : null,
                ),
                onPressed: _busy ? null : _toggleFavorite,
                icon: Icon(d['is_favorite'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: CommunityLook.heart),
                label: Text(d['is_favorite'] == true ? 'في «سواقيني»' : 'أضف إلى «سواقيني»',
                    style: p.text(14, weight: FontWeight.w700, color: CommunityLook.heart)),
              ),
            ),
            if (d['mutual'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('$name أضافك أيضًا إلى ركابه المفضلين', style: p.text(12.5, color: CommunityLook.heart)),
              ),
          ],
        ]),
      ),
      if ((d['bio'] ?? '').toString().isNotEmpty)
        CommunityCard(title: 'عن السائق', child: Text(d['bio'].toString(), style: p.text(14, height: 1.6))),
      if (amenities.isNotEmpty)
        CommunityCard(
          title: 'في السيارة',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in amenities) if (a is Map) CommunityChip(label: '${a['label']}'),
          ]),
        ),
      if (badges.isNotEmpty)
        CommunityCard(
          title: 'أوسمة من الركاب',
          child: Column(children: [
            for (final b in badges)
              if (b is Map)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium_rounded, color: CommunityLook.gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${b['label']}', style: p.text(14))),
                    Text('${b['count']}', style: p.text(14, weight: FontWeight.w700)),
                  ]),
                ),
          ]),
        ),
      CommunityCard(
        title: 'كلمات الركاب',
        child: comments.isEmpty
            ? Text('لا توجد كلمات منشورة بعد.', style: p.text(13, color: p.sub))
            : Column(children: [
                for (final c in comments)
                  if (c is Map)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c['text']}', style: p.text(14, height: 1.5)),
                        const SizedBox(height: 4),
                        Text('راكب موثّق · ${c['month'] ?? ''}', style: p.text(11.5, color: p.sub)),
                      ]),
                    ),
              ]),
      ),
      if (d['share_url'] != null)
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: d['share_url'].toString()));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نسخنا رابط صفحة السائق.')));
          },
          icon: Icon(Icons.share_rounded, color: p.mine),
          label: Text('مشاركة صفحة السائق', style: p.text(14, color: p.mine)),
        ),
    ]);
  }

  Widget _stat(ChatPalette p, String value, String label) => Expanded(
        child: Column(children: [
          Text(value, style: p.text(17, weight: FontWeight.w700)),
          Text(label, style: p.text(12, color: p.sub)),
        ]),
      );
}
