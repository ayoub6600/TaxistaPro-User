import 'package:flutter/material.dart';

import '../widgets/chat/chat_kit.dart';
import 'community_kit.dart';

/// One ride campaign in full: the server's count inside a big ring, progress marks (motivation
/// only: the reward comes at the target), what counts, when it ends, what the reward is, and the
/// server's own terms. Nothing here is computed on the phone beyond the ring's fill.
class CampaignPage extends StatelessWidget {
  const CampaignPage({super.key, required this.campaign});
  final Map<String, dynamic> campaign;

  static const _navy = [Color(0xff102A56), Color(0xff1965BF)];

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    final c = campaign;
    final done = ((c['completed_rides'] ?? 0) as num).toInt();
    final target = ((c['required_rides'] ?? 0) as num).toInt();
    final earned = c['can_earn_more'] == false || (target > 0 && done >= target);
    final left = (target - done).clamp(0, target);
    final reward = '${c['reward_amount'] ?? ''} ${c['currency_symbol'] ?? 'د.ل'}';
    final ends = ChatTime.parse(c['period_ends_at']);
    final pending = '${c['pending_amount'] ?? '0.00'}';
    final value = target <= 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    final ringColor = earned ? CommunityLook.gold : const Color(0xff0873FF);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.background,
        body: ListView(padding: EdgeInsets.zero, children: [
          // the campaign's name on the app's navy band
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: _navy),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${c['name'] ?? ''}', style: p.text(19, weight: FontWeight.w800, color: Colors.white)),
                  if ((c['reward_label'] ?? '').toString().isNotEmpty)
                    Text('${c['reward_label']}', style: p.text(12.5, color: Colors.white70)),
                ]),
              ),
              Material(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox.square(dimension: 44, child: Icon(Icons.arrow_back_rounded, color: Colors.white)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => SizedBox.square(
                dimension: 190,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.square(
                    dimension: 190,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: p.line,
                      color: ringColor,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$done', style: p.text(48, weight: FontWeight.w900, height: 1.1)),
                    Text('من $target رحلة', style: p.text(13, color: p.sub)),
                  ]),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(earned ? 'استحققت المكافأة!' : 'باقي $left رحلة على مكافأتك',
                style: p.text(19, weight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Text(
              earned
                  ? (pending != '0.00' ? '$pending د.ل في الطريق إليك بعد مهلة التسوية.' : 'مكافأة هذه الحملة وصلتك.')
                  : 'كل رحلة مكتملة تُحسب، والملغاة ما تُحسبش.',
              textAlign: TextAlign.center,
              style: p.text(12.5, color: p.sub),
            ),
          ),
          if (target >= 4)
            _side(CommunityCard(
              title: 'معالم التقدم',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('للتحفيز فقط، المكافأة عند $target رحلة', style: p.text(11.5, color: p.sub)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  for (final f in const [.25, .5, .75, 1.0])
                    _Mark(at: (target * f).round(), reached: done >= (target * f).round(), last: f == 1.0, reward: reward),
                ]),
              ]),
            )),
          _side(CommunityCard(
            child: Column(children: [
              _Row(icon: Icons.directions_car_outlined, title: 'رحلات محسوبة', note: 'في مدة الحملة الحالية', value: '$done'),
              if (ends != null)
                _Row(icon: Icons.event_outlined, title: 'تنتهي الحملة', note: 'وقد تتوقف إذا انتهت ميزانيتها', value: ChatTime.dayLabel(ends, true)),
              _Row(icon: Icons.account_balance_wallet_outlined, title: 'تُضاف كـ', note: 'للرحلات فقط، لا تُحوّل ولا تُسحب', value: 'رصيد مشاوير'),
              _Row(
                icon: Icons.repeat_rounded,
                title: 'التكرار',
                value: c['count_period'] == 'week' ? 'كل أسبوع' : c['count_period'] == 'month' ? 'كل شهر' : 'مرة واحدة فقط',
                last: true,
              ),
            ]),
          )),
          if (c['budget_paused'] == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('اكتملت ميزانية هذه الحملة، وقد تتأخر المكافأة.', style: p.text(12.5, color: const Color(0xFFB45309))),
            ),
          if ((c['terms'] ?? '').toString().isNotEmpty)
            _side(CommunityCard(
              title: 'الشروط',
              child: Text('${c['terms']}', style: p.text(12.5, color: p.sub, height: 1.8)),
            )),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }
}

Widget _side(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

class _Mark extends StatelessWidget {
  const _Mark({required this.at, required this.reached, required this.last, required this.reward});
  final int at;
  final bool reached;
  final bool last;
  final String reward;

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: reached ? const Color(0xff0873FF) : p.field),
        child: reached
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
            : Text(last ? '$at' : '$at', style: p.text(12, weight: FontWeight.w800, color: p.sub)),
      ),
      const SizedBox(height: 6),
      Text(last ? reward : '$at رحلة', style: p.text(11.5, color: p.sub)),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.value, this.note, this.last = false});
  final IconData icon;
  final String title;
  final String value;
  final String? note;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: p.line))),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: const Color(0xff0873FF).withValues(alpha: .08), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: const Color(0xff0873FF)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: p.text(14, weight: FontWeight.w700)),
            if (note != null) Text(note!, style: p.text(11.5, color: p.sub)),
          ]),
        ),
        Text(value, style: p.text(13.5, weight: FontWeight.w800)),
      ]),
    );
  }
}
