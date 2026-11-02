import 'dart:math';

import 'package:flutter/material.dart';

import '../functions/functions.dart';
import '../widgets/chat/chat_kit.dart';
import 'community_api.dart';
import 'community_kit.dart';

/// "مكافآتي": every balance apart (ride credit, the rider's own money, rewards on their way),
/// gold coins and their conversion, campaign progress with their terms, achievements, the last
/// entries, and the choice to receive offers or not.
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  Map<String, dynamic>? _data;
  bool _loaded = false;
  bool _converting = false;
  String? _convertKey;
  final Set<String> _openTerms = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([CommunityApi.rewards(), refreshPromotionCampaigns()]);
    if (!mounted) return;
    setState(() {
      _data = results[0] as Map<String, dynamic>? ?? _data;
      _loaded = true;
    });
  }

  Future<void> _convert() async {
    setState(() => _converting = true);
    // the same key for retries of this tap, so a lost answer never converts twice
    _convertKey ??= '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}';
    final message = await CommunityApi.convertGold(_convertKey!);
    if (!mounted) return;
    setState(() => _converting = false);
    if (message != null) {
      _convertKey = null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر التحويل الآن، حاول مرة أخرى.')));
    }
  }

  Future<void> _setOffers(bool wanted) async {
    final ok = await CommunityApi.setMarketingOptOut(!wanted);
    if (!mounted) return;
    if (ok) {
      setState(() => _data?['marketing_opt_out'] = !wanted);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الحفظ.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.background,
        appBar: communityAppBar(context, 'مكافآتي'),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _data == null
                    ? ListView(children: [
                        const SizedBox(height: 140),
                        Center(child: Text('تعذر التحميل. اسحب للأسفل لإعادة المحاولة.', style: p.text(14, color: p.sub))),
                      ])
                    : _page(p, _data!),
              ),
      ),
    );
  }

  Widget _page(ChatPalette p, Map<String, dynamic> d) {
    final balances = d['balances'] is Map ? d['balances'] as Map : const {};
    final gold = d['gold'] is Map ? d['gold'] as Map : const {};
    final achievements = d['achievements'] is List ? d['achievements'] as List : const [];
    final history = d['history'] is List ? d['history'] as List : const [];
    final campaigns = activePromotionCampaigns.where((c) => c['type'] != 'signup_bonus').toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        _balance(p, 'رصيد مشاوير', balances['ride_credit_lyd'], 'للرحلات فقط', p.mine),
        const SizedBox(width: 8),
        _balance(p, 'أموالك في المحفظة', balances['own_money_lyd'], 'قابلة للتحويل', p.ink),
        const SizedBox(width: 8),
        _balance(p, 'في الطريق', balances['campaign_rewards_on_the_way_lyd'], 'بعد مهلة التسوية', CommunityLook.good),
      ]),
      const SizedBox(height: 12),
      if (gold['enabled'] == true || (gold['coins'] ?? 0) > 0) _goldCard(p, gold),
      if (campaigns.isNotEmpty)
        CommunityCard(
          title: 'حملاتك',
          child: Column(children: [for (final c in campaigns) _campaign(p, c)]),
        ),
      if (achievements.isNotEmpty)
        CommunityCard(
          title: 'إنجازاتك',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in achievements)
              if (a is Map)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: a['reached'] == true ? CommunityLook.goldBackground(p) : p.field,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(a['reached'] == true ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                        size: 16, color: a['reached'] == true ? CommunityLook.gold : p.sub),
                    const SizedBox(width: 6),
                    Text('${a['title']}', style: p.text(12.5, color: a['reached'] == true ? p.ink : p.sub)),
                  ]),
                ),
          ]),
        ),
      if (history.isNotEmpty)
        CommunityCard(
          title: 'آخر الحركات',
          child: Column(children: [
            for (final h in history.take(15))
              if (h is Map)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${h['what']} · ${h['kind']}', style: p.text(13.5)),
                        Text(ChatTime.dayLabel(ChatTime.parse(h['at']) ?? DateTime.now(), true), style: p.text(11.5, color: p.sub)),
                      ]),
                    ),
                    Text(h['unit'] == 'coins' ? '${h['amount']} عملة' : '${h['amount']} د.ل',
                        textDirection: TextDirection.ltr,
                        style: p.text(13.5, weight: FontWeight.w700, color: '${h['amount']}'.startsWith('-') ? p.sub : CommunityLook.good)),
                  ]),
                ),
          ]),
        ),
      CommunityCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أريد عروض تاكسيستا', style: p.text(14.5, weight: FontWeight.w700)),
              Text('عند الإيقاف لا تصلك دعوات الحملات. مكافآتك الحالية تبقى كما هي.', style: p.text(12, color: p.sub)),
            ]),
          ),
          Switch.adaptive(value: d['marketing_opt_out'] != true, activeThumbColor: p.mine, onChanged: _setOffers),
        ]),
      ),
      if ((d['how_it_works'] ?? '').toString().isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          child: Text(d['how_it_works'].toString(), style: p.text(12.5, color: p.sub, height: 1.7)),
        ),
    ]);
  }

  Widget _balance(ChatPalette p, String label, dynamic value, String note, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: p.text(11.5, color: p.sub), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text('${value ?? '0.00'} د.ل', style: p.text(17, weight: FontWeight.w700, color: color)),
            ),
            Text(note, style: p.text(10.5, color: p.sub), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _goldCard(ChatPalette p, Map gold) {
    final coins = (gold['coins'] ?? 0) as num;
    final threshold = (gold['conversion_threshold'] ?? 0) as num;
    final progress = threshold > 0 ? (coins / threshold).clamp(0.0, 1.0).toDouble() : 0.0;
    final goldInk = p.dark ? const Color(0xFFF6D365) : CommunityLook.gold;
    return CommunityCard(
      background: CommunityLook.goldBackground(p),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const GoldCoin(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$coins عملة ذهبية', style: p.text(19, weight: FontWeight.w700, color: goldInk)),
              Text('قيمتها ${gold['value_lyd'] ?? '0.00'} د.ل', style: p.text(12.5, color: p.sub)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: progress, minHeight: 8, color: CommunityLook.gold, backgroundColor: p.line),
        ),
        const SizedBox(height: 6),
        Text(gold['can_convert'] == true ? 'وصلت لحد التحويل.' : 'باقي ${max(0, threshold - coins)} عملة للتحويل إلى رصيد مشاوير.',
            style: p.text(12.5, color: p.sub)),
        if ((gold['pending_coins'] ?? 0) > 0)
          Text('${gold['pending_coins']} عملة تصبح متاحة قريبًا.', style: p.text(12, color: p.sub)),
        if ((gold['expiring_in_30_days'] ?? 0) > 0)
          Text('${gold['expiring_in_30_days']} عملة تنتهي خلال 30 يومًا.', style: p.text(12, color: const Color(0xFFB45309))),
        if (gold['can_convert'] == true) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: CommunityLook.gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _converting ? null : _convert,
              child: _converting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Text('حوّل العملات إلى رصيد مشاوير', style: p.text(14.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _campaign(ChatPalette p, Map<String, dynamic> c) {
    final done = (c['completed_rides'] ?? 0) as num;
    final target = (c['required_rides'] ?? 0) as num;
    final id = '${c['id']}';
    final pending = '${c['pending_amount'] ?? '0.00'}';
    final ends = ChatTime.parse(c['period_ends_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${c['name']}', style: p.text(14.5, weight: FontWeight.w700))),
          Text('${c['reward_amount']} ${c['currency_symbol'] ?? 'د.ل'}', style: p.text(14, weight: FontWeight.w700, color: p.mine)),
        ]),
        Text('${c['reward_label'] ?? ''}', style: p.text(11.5, color: p.sub)),
        if (target > 0 && c['type'] != 'comeback') ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: (done / target).clamp(0.0, 1.0).toDouble(), minHeight: 7, color: p.mine, backgroundColor: p.line),
          ),
          const SizedBox(height: 4),
          Text(c['can_earn_more'] == false ? 'حصلت على مكافأة هذه الحملة.' : '$done من $target رحلة',
              style: p.text(12.5, color: p.sub)),
        ],
        if (c['type'] == 'comeback') Text('أول رحلة مكتملة لك عليها المكافأة.', style: p.text(12.5, color: p.sub)),
        if (ends != null && c['can_earn_more'] != false)
          Text('${c['count_period'] == 'week' ? 'ينتهي هذا الأسبوع' : c['count_period'] == 'month' ? 'ينتهي هذا الشهر' : 'تنتهي الحملة'} ${ChatTime.dayLabel(ends, true)}',
              style: p.text(11.5, color: p.sub)),
        if (pending != '0.00') Text('$pending د.ل في الطريق إليك.', style: p.text(12, color: CommunityLook.good)),
        if (c['budget_paused'] == true) Text('اكتملت ميزانية هذه الحملة، وقد تتأخر المكافأة.', style: p.text(12, color: const Color(0xFFB45309))),
        if ((c['terms'] ?? '').toString().isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() {
              if (!_openTerms.remove(id)) _openTerms.add(id);
            }),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_openTerms.contains(id) ? 'إخفاء الشروط' : 'الشروط', style: p.text(12.5, weight: FontWeight.w700, color: p.mine)),
            ),
          ),
          if (_openTerms.contains(id))
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('${c['terms']}', style: p.text(12, color: p.sub, height: 1.7))),
        ],
      ]),
    );
  }
}
