import 'package:flutter/material.dart';

import '../widgets/chat/chat_kit.dart';
import 'community_api.dart';
import 'community_kit.dart';

/// The one screen after a ride (the star rating stays on the review page before it): add the
/// driver to "سواقيني", pick what was good, leave a short word, and - when Taxista offers it -
/// send him a gold gift that Taxista pays for. Every part is optional; "تخطي" leaves.
class AfterRidePage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> state;

  const AfterRidePage({super.key, required this.requestId, required this.state});

  /// Opens the screen when it has something to offer; returns when the rider is done.
  static Future<void> showIfUseful(BuildContext context, String requestId) async {
    final state = await CommunityApi.afterRide(requestId);
    if (state == null || state['completed'] != true || !context.mounted) return;
    final favorite = state['favorite'] is Map ? state['favorite'] as Map : const {};
    final badges = state['badges'] is Map ? state['badges'] as Map : const {};
    final useful = favorite['suggest'] == true || state['gift'] != null || (badges['sent'] == null && badges['options'] is Map);
    if (!useful) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AfterRidePage(requestId: requestId, state: state)));
  }

  @override
  State<AfterRidePage> createState() => _AfterRidePageState();
}

class _AfterRidePageState extends State<AfterRidePage> {
  late Map<String, dynamic> _state = widget.state;
  late bool _favorite = _favoriteState['is'] == true;
  final Set<String> _badges = {};
  final _comment = TextEditingController();
  bool _gift = false;
  String? _giftReason;
  bool _sending = false;
  Map<String, dynamic>? _results;

  Map get _favoriteState => _state['favorite'] is Map ? _state['favorite'] as Map : const {};
  Map get _peer => _state['peer'] is Map ? _state['peer'] as Map : const {};
  String get _name => (_peer['name'] ?? '').toString();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _toggleBadge(String key) {
    setState(() {
      if (!_badges.remove(key) && _badges.length < 5) _badges.add(key);
    });
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final initialFavorite = _favoriteState['is'] == true;
    final result = await CommunityApi.submitAfterRide(
      widget.requestId,
      favorite: _favorite != initialFavorite ? _favorite : null,
      badges: _badges.toList(),
      comment: _state['comment_allowed'] == true ? _comment.text : null,
      gift: _gift,
      giftReason: _giftReason,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (result != null) {
        _results = result['results'] is Map ? Map<String, dynamic>.from(result['results'] as Map) : {};
        _state = result;
      }
    });
    if (result == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر الإرسال، تحقق من الاتصال وحاول مرة أخرى.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.background,
        appBar: communityAppBar(context, 'كيف كانت رحلتك؟', actions: [
          if (_results == null)
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('تخطي', style: p.text(14, color: p.sub))),
        ]),
        body: SafeArea(child: _results == null ? _form(p) : _done(p)),
      ),
    );
  }

  Widget _form(ChatPalette p) {
    final badges = _state['badges'] is Map ? _state['badges'] as Map : const {};
    final options = badges['options'] is Map ? Map<String, dynamic>.from(badges['options'] as Map) : <String, dynamic>{};
    final sentBadges = badges['sent'];
    final gift = _state['gift'] is Map ? _state['gift'] as Map : null;
    final reasons = gift?['reasons'] is Map ? Map<String, dynamic>.from(gift!['reasons'] as Map) : <String, dynamic>{};
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), children: [
          Row(children: [
            CommunityAvatar(photo: _peer['photo']?.toString(), name: _name, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_name, style: p.text(18, weight: FontWeight.w700)),
                if ((_peer['car'] ?? '').toString().isNotEmpty) Text(_peer['car'].toString(), style: p.text(13, color: p.sub)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          CommunityCard(
            child: InkWell(
              onTap: () => setState(() => _favorite = !_favorite),
              borderRadius: BorderRadius.circular(12),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(_favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(_favorite), color: CommunityLook.heart, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_favorite ? '$_name في «سواقيني»' : 'أضف $_name إلى «سواقيني»', style: p.text(15, weight: FontWeight.w700)),
                    Text('عندما يكون قريبًا ومتاحًا نخبرك وتقدر تطلبه أولًا.', style: p.text(12.5, color: p.sub)),
                    if (_favoriteState['mutual'] == true)
                      Text('$_name أضافك أيضًا إلى ركابه المفضلين.', style: p.text(12.5, color: CommunityLook.heart)),
                  ]),
                ),
              ]),
            ),
          ),
          if (options.isNotEmpty)
            CommunityCard(
              title: sentBadges == null ? 'ما الذي أعجبك؟' : 'أرسلت تقديرك',
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in options.entries)
                  CommunityChip(
                    label: e.value.toString(),
                    selected: sentBadges is List ? sentBadges.contains(e.key) : _badges.contains(e.key),
                    onTap: sentBadges != null ? null : () => _toggleBadge(e.key),
                  ),
              ]),
            ),
          if (_state['comment_allowed'] == true)
            CommunityCard(
              title: 'كلمة قصيرة (اختياري)',
              child: TextField(
                controller: _comment,
                maxLength: 300,
                maxLines: 3,
                minLines: 2,
                style: p.text(14),
                decoration: InputDecoration(
                  hintText: 'تظهر في صفحة السائق بعد المراجعة، بدون أرقام هواتف.',
                  hintStyle: p.text(13, color: p.sub),
                  filled: true,
                  fillColor: p.field,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          if (gift != null)
            CommunityCard(
              background: CommunityLook.goldBackground(p),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const GoldCoin(size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('أهدِ $_name ${gift['coins']} عملة ذهبية',
                        style: p.text(15, weight: FontWeight.w700, color: p.dark ? const Color(0xFFF6D365) : CommunityLook.gold)),
                  ),
                  Switch.adaptive(
                    value: _gift,
                    activeThumbColor: CommunityLook.gold,
                    onChanged: (v) => setState(() => _gift = v),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('قيمتها ${gift['value_lyd']} د.ل وتدفعها تاكسيستا بالكامل، لا يُخصم منك شيء.', style: p.text(12.5, color: p.sub)),
                if (_gift && reasons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final e in reasons.entries)
                      CommunityChip(
                        label: e.value.toString(),
                        accent: CommunityLook.gold,
                        selected: _giftReason == e.key,
                        onTap: () => setState(() => _giftReason = _giftReason == e.key ? null : e.key),
                      ),
                  ]),
                ],
              ]),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.mine, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text('إرسال', style: p.text(16, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Widget _done(ChatPalette p) {
    final r = _results ?? {};
    final lines = <String>[
      if (r['favorite'] == 'ok') _favorite ? 'أضفنا $_name إلى «سواقيني».' : 'أزلنا $_name من «سواقيني».',
      if (r['appreciation'] == 'ok') 'وصل تقديرك إلى $_name.',
      if (r['gift'] == 'ok') 'وصلت هديتك الذهبية إلى $_name، شكرًا لك.',
      if (r['gift'] == 'unavailable') 'الهدية غير متاحة لهذه الرحلة الآن.',
      if (_state['mutual_appreciation'] == true) 'أنتما تقدّران بعضكما: $_name قدّرك أيضًا.',
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: CommunityLook.good.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: CommunityLook.good, size: 40),
        ),
        const SizedBox(height: 16),
        Text('شكرًا لك', style: p.text(20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final line in lines.isEmpty ? ['تم.'] : lines)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(line, textAlign: TextAlign.center, style: p.text(14, color: p.sub))),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.mine, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('تم', style: p.text(16, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}
