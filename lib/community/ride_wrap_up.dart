import 'package:flutter/material.dart';

import '../functions/functions.dart' show languageDirection;
import '../widgets/chat/chat_kit.dart';
import 'community_api.dart';
import 'community_kit.dart';

/// "ختام الرحلة": after the invoice, one light card slides up over it and walks through small
/// widgets - the stars (and an optional note), then, only when this ride has something to offer,
/// the favourite, what was good, Taxista's gold gift - and ends with a thank-you.
///
/// Nothing is sent before the last step: first the after-ride choices, then the rating. For a
/// driver the rating is what makes him available again, so no request reaches him while the card
/// is open.
class RideWrapUp extends StatefulWidget {
  /// 'rider' rates the driver, 'driver' rates the rider.
  final String role;
  final String requestId;
  final String peerName;
  final String? peerPhoto;

  /// Sends the stars and the note: true when done, 'logout' when the session has ended.
  final Future<dynamic> Function(double stars, String note) sendRating;

  /// Sends the after-ride choices ({favorite, badges, comment, gift, gift_reason}).
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> choices) sendAfterRide;

  /// What this ride offers after it (CommunityApi.afterRide); replaced in tests.
  final Future<Map<String, dynamic>?> Function(String requestId) loadAfterRide;

  /// Back to the map, after the thank-you or after "تخطي".
  final Future<void> Function() onFinished;
  final VoidCallback onLogout;

  /// A rider may skip the stars; a driver rates every rider.
  final bool canSkipRating;

  const RideWrapUp({
    super.key,
    required this.role,
    required this.requestId,
    required this.peerName,
    this.peerPhoto,
    required this.sendRating,
    required this.sendAfterRide,
    this.loadAfterRide = CommunityApi.afterRide,
    required this.onFinished,
    required this.onLogout,
    this.canSkipRating = false,
  });

  /// The route that shows [page] over the invoice: the invoice stays visible behind a dimmed
  /// backdrop, and the card rises from the bottom.
  static Route<T> route<T>(Widget page) => PageRouteBuilder<T>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(curve), child: child),
          );
        },
      );

  @override
  State<RideWrapUp> createState() => _RideWrapUpState();
}

class _RideWrapUpState extends State<RideWrapUp> {
  static const _star = Color(0xFFF59E0B);
  static const _error = Color(0xFFDC2626);

  int _stars = 0;
  final _note = TextEditingController();
  final _praise = TextEditingController();
  bool _noteOpen = false;

  Map<String, dynamic>? _after;
  bool _favorite = false;
  final Set<String> _badges = {};
  bool _gift = false;
  String? _giftReason;

  int _step = 0;
  bool _sending = false;
  bool _done = false;
  String? _problem;
  List<String> _thanks = const [];

  static bool get _ar => languageDirection != 'ltr';
  static String _t(String ar, String en) => _ar ? ar : en;
  bool get _isRider => widget.role == 'rider';

  /// The first name, for the sentences; the header shows the whole name.
  String get _first {
    final n = widget.peerName.trim();
    return n.isEmpty ? n : n.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    // loaded while the stars are being chosen, so the next card is ready
    widget.loadAfterRide(widget.requestId).then((s) {
      if (mounted && s != null && s['completed'] == true) {
        setState(() {
          _after = s;
          _favorite = _favoriteState['is'] == true;
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _note.dispose();
    _praise.dispose();
    super.dispose();
  }

  Map get _favoriteState => _after?['favorite'] is Map ? _after!['favorite'] as Map : const {};
  Map get _badgeState => _after?['badges'] is Map ? _after!['badges'] as Map : const {};
  Map<String, dynamic> get _badgeOptions =>
      _badgeState['options'] is Map ? Map<String, dynamic>.from(_badgeState['options'] as Map) : const {};
  Map? get _giftOffer => _after?['gift'] is Map ? _after!['gift'] as Map : null;
  bool get _commentAllowed => _isRider && _after?['comment_allowed'] == true;

  /// The cards for this ride, in order (the thank-you is not one of them). The heart and the gift
  /// follow a good ride only, as the server's own suggestion does.
  List<String> get _steps => [
        'rate',
        if (_stars >= 4 && _favoriteState['suggest'] == true) 'favorite',
        if (_stars >= 3 && _badgeState['sent'] == null && _badgeOptions.isNotEmpty) 'badges',
        if (_stars >= 4 && _giftOffer != null) 'gift',
      ];

  bool get _onLast => _step >= _steps.length - 1;

  void _back() {
    if (_sending || _done) return;
    if (_step > 0) {
      setState(() {
        _step--;
        _problem = null;
      });
    } else if (widget.canSkipRating) {
      widget.onFinished();
    }
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (!_onLast) {
      setState(() {
        _step++;
        _problem = null;
      });
      return;
    }
    await _send();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _problem = null;
    });
    final thanks = <String>[];
    final name = _first;
    if (_after != null) {
      final steps = _steps;
      final choices = <String, dynamic>{
        if (steps.contains('favorite') && _favorite != (_favoriteState['is'] == true)) 'favorite': _favorite,
        if (steps.contains('badges') && _badges.isNotEmpty) 'badges': _badges.toList(),
        if (steps.contains('badges') && _commentAllowed && _praise.text.trim().isNotEmpty) 'comment': _praise.text.trim(),
        if (steps.contains('gift') && _gift) 'gift': true,
        if (steps.contains('gift') && _gift && _giftReason != null) 'gift_reason': _giftReason,
      };
      if (choices.isNotEmpty) {
        // the extras never hold the rating back: a failure here only changes the thank-you
        Map<String, dynamic>? saved;
        try {
          saved = await widget.sendAfterRide(choices);
        } catch (_) {}
        final r = saved?['results'] is Map ? saved!['results'] as Map : const {};
        if (r['favorite'] == 'ok' && _favorite) {
          thanks.add(_isRider
              ? _t('$name في «سواقيني» الآن.', '$name is in your favourite drivers.')
              : _t('$name في ركابك المفضلين الآن.', '$name is in your favourite riders.'));
        }
        if (r['appreciation'] == 'ok') thanks.add(_t('وصل تقديرك إلى $name.', '$name got your appreciation.'));
        if (r['gift'] == 'ok') thanks.add(_t('وصلت هديتك الذهبية إلى $name.', 'Your gold gift reached $name.'));
        if (r['gift'] == 'unavailable') thanks.add(_t('الهدية غير متاحة لهذه الرحلة الآن.', 'The gift is not available for this ride now.'));
        if (saved?['mutual_appreciation'] == true) thanks.add(_t('$name قدّرك أيضًا.', '$name appreciated you too.'));
      }
    }
    if (_after?['rated'] != true) {
      final rated = await widget.sendRating(_stars.toDouble(), _note.text.trim());
      if (!mounted) return;
      if (rated == 'logout') {
        widget.onLogout();
        return;
      }
      if (rated != true) {
        setState(() {
          _sending = false;
          _problem = _t('لم يُرسل التقييم. تحقّق من الإنترنت واضغط «إرسال» مرة أخرى.',
              'The rating was not sent. Check your connection and tap "Send" again.');
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _done = true;
      _thanks = thanks;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) await widget.onFinished();
  }

  // ------------------------------------------------------------------ the card

  @override
  Widget build(BuildContext context) {
    final p = ChatPalette.current();
    final steps = _steps;
    final step = _done ? 'done' : steps[_step.clamp(0, steps.length - 1)];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Directionality(
        textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
        child: Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.of(context).size.height * 0.86),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 32, offset: const Offset(0, 12))],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          _header(p, steps.length),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            // the old card leaves at once, so two cards never show on top of each other
                            switchOutCurve: const Threshold(0),
                            layoutBuilder: (current, previous) =>
                                Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(begin: Offset(_ar ? -0.08 : 0.08, 0), end: Offset.zero).animate(animation),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(key: ValueKey(step), child: _card(p, step)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ChatPalette p, int count) {
    return Row(children: [
      Stack(clipBehavior: Clip.none, children: [
        CommunityAvatar(photo: widget.peerPhoto, name: widget.peerName, size: 46),
        PositionedDirectional(
          bottom: -2,
          end: -2,
          child: Container(
            decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle),
            padding: const EdgeInsets.all(1.5),
            child: const Icon(Icons.check_circle_rounded, color: CommunityLook.good, size: 17),
          ),
        ),
      ]),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('وصلت بالسلامة', 'Ride complete'), style: p.text(12.5, color: p.sub)),
          Text(widget.peerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(16, weight: FontWeight.w800)),
        ]),
      ),
      if (!_done && count > 1)
        Row(children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: i == _step ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(color: i <= _step ? p.mine : p.line, borderRadius: BorderRadius.circular(4)),
            ),
        ]),
      if (!_done && _step > 0)
        IconButton(
          key: const ValueKey('wrapup-back'),
          visualDensity: VisualDensity.compact,
          onPressed: _sending ? null : _back,
          // arrow_back points right in Arabic by itself
          icon: Icon(Icons.arrow_back_rounded, color: p.sub, size: 20),
        ),
    ]);
  }

  Widget _card(ChatPalette p, String step) {
    switch (step) {
      case 'favorite':
        return _favoriteCard(p);
      case 'badges':
        return _badgesCard(p);
      case 'gift':
        return _giftCard(p);
      case 'done':
        return _doneCard(p);
      default:
        return _rateCard(p);
    }
  }

  Widget _primary(ChatPalette p, {required bool enabled}) {
    final label = _onLast ? _t('إرسال', 'Send') : _t('التالي', 'Next');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_problem != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(_problem!, key: const ValueKey('wrapup-problem'), textAlign: TextAlign.center, style: p.text(13, color: _error)),
        ),
      SizedBox(
        height: 52,
        child: FilledButton(
          key: const ValueKey('wrapup-next'),
          style: FilledButton.styleFrom(
            backgroundColor: p.mine,
            disabledBackgroundColor: p.line,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: enabled && !_sending ? _next : null,
          child: _sending
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(label, style: p.text(16, weight: FontWeight.w800, color: enabled ? Colors.white : p.sub)),
        ),
      ),
    ]);
  }

  static const _starWordsAr = ['', 'سيئة', 'مقبولة', 'جيدة', 'ممتازة', 'رائعة!'];
  static const _starWordsEn = ['', 'Bad', 'Okay', 'Good', 'Great', 'Excellent!'];

  Widget _rateCard(ChatPalette p) {
    final question =
        _isRider ? _t('كيف كانت رحلتك؟', 'How was your ride?') : _t('كيف كان $_first؟', 'How was $_first?');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(question, textAlign: TextAlign.center, style: p.text(19, weight: FontWeight.w800)),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            Semantics(
              button: true,
              label: _t('$i من 5', '$i of 5'),
              child: GestureDetector(
                key: ValueKey('wrapup-star-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: _sending ? null : () => setState(() => _stars = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: AnimatedScale(
                    scale: i <= _stars ? 1.12 : 1,
                    duration: Duration(milliseconds: 160 + i * 40),
                    curve: Curves.easeOutBack,
                    child: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 46, color: i <= _stars ? _star : (p.dark ? const Color(0xFF3B4A63) : const Color(0xFFCBD5E1))),
                  ),
                ),
              ),
            ),
        ],
      ),
      SizedBox(
        height: 24,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text((_ar ? _starWordsAr : _starWordsEn)[_stars],
              key: ValueKey(_stars),
              textAlign: TextAlign.center,
              style: p.text(14, weight: FontWeight.w700, color: const Color(0xFFB45309))),
        ),
      ),
      const SizedBox(height: 4),
      if (!_noteOpen)
        Center(
          child: TextButton.icon(
            key: const ValueKey('wrapup-add-note'),
            onPressed: () => setState(() => _noteOpen = true),
            icon: Icon(Icons.edit_note_rounded, size: 20, color: p.mine),
            label: Text(_t('أضف ملاحظة (اختياري)', 'Add a note (optional)'), style: p.text(13.5, weight: FontWeight.w600, color: p.mine)),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            key: const ValueKey('wrapup-note'),
            controller: _note,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            maxLength: 200,
            style: p.text(14),
            decoration: InputDecoration(
              hintText: _t('ملاحظتك تصل إلى فريق تاكسيستا فقط', 'Only the Taxista team sees your note'),
              hintStyle: p.text(13, color: p.sub),
              counterText: '',
              filled: true,
              fillColor: p.field,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
      _primary(p, enabled: _stars > 0),
      if (widget.canSkipRating)
        TextButton(
          key: const ValueKey('wrapup-skip'),
          onPressed: _sending ? null : () => widget.onFinished(),
          child: Text(_t('تخطي', 'Skip'), style: p.text(13, color: p.sub)),
        ),
    ]);
  }

  Widget _favoriteCard(ChatPalette p) {
    final name = _first;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: Semantics(
          button: true,
          toggled: _favorite,
          child: GestureDetector(
            key: const ValueKey('wrapup-heart'),
            onTap: () => setState(() => _favorite = !_favorite),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              width: 86,
              height: 86,
              decoration: BoxDecoration(color: CommunityLook.heart.withValues(alpha: _favorite ? 0.16 : 0.07), shape: BoxShape.circle),
              child: AnimatedScale(
                scale: _favorite ? 1.15 : 1,
                duration: const Duration(milliseconds: 420),
                curve: Curves.elasticOut,
                child: Icon(_favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: CommunityLook.heart, size: 42),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
          _isRider
              ? _t('أضف $name إلى «سواقيني»؟', 'Add $name to your drivers?')
              : _t('أضف $name إلى ركابك المفضلين؟', 'Add $name to your favourite riders?'),
          textAlign: TextAlign.center,
          style: p.text(17, weight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(
          _isRider
              ? _t('عندما يكون قريبًا ومتاحًا نخبرك وتقدر تطلبه أولًا.', 'When this driver is near and free, we tell you so you can ask first.')
              : _t('نميّز طلباته لك بقلب، ولا يرى هذه القائمة أحد غيرك.', 'Their requests show you a heart; nobody else sees this list.'),
          textAlign: TextAlign.center,
          style: p.text(13, color: p.sub)),
      if (_favoriteState['mutual'] == true)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
              _isRider
                  ? _t('$name أضافك أيضًا إلى ركابه المفضلين.', '$name has you in their favourite riders too.')
                  : _t('$name أضافك أيضًا إلى «سواقيني».', '$name has you in their drivers too.'),
              textAlign: TextAlign.center,
              style: p.text(13, weight: FontWeight.w700, color: CommunityLook.heart)),
        ),
      const SizedBox(height: 18),
      _primary(p, enabled: true),
    ]);
  }

  Widget _badgesCard(ChatPalette p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_t('ما الذي أعجبك؟', 'What did you like?'), textAlign: TextAlign.center, style: p.text(18, weight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(_t('اختر ما يناسب (اختياري)', 'Pick any (optional)'), textAlign: TextAlign.center, style: p.text(13, color: p.sub)),
      const SizedBox(height: 14),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        for (final e in _badgeOptions.entries)
          CommunityChip(
            key: ValueKey('wrapup-badge-${e.key}'),
            label: e.value.toString(),
            selected: _badges.contains(e.key),
            onTap: () => setState(() {
              if (!_badges.remove(e.key) && _badges.length < 5) _badges.add(e.key);
            }),
          ),
      ]),
      if (_commentAllowed) ...[
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('wrapup-praise'),
          controller: _praise,
          minLines: 1,
          maxLines: 3,
          maxLength: 300,
          style: p.text(14),
          decoration: InputDecoration(
            hintText: _t('كلمة لطيفة تظهر في صفحته بعد المراجعة (اختياري)', 'A kind word for the driver\'s page, after review (optional)'),
            hintStyle: p.text(13, color: p.sub),
            counterText: '',
            filled: true,
            fillColor: p.field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
      const SizedBox(height: 18),
      _primary(p, enabled: true),
    ]);
  }

  Widget _giftCard(ChatPalette p) {
    final g = _giftOffer!;
    final reasons = g['reasons'] is Map ? Map<String, dynamic>.from(g['reasons'] as Map) : <String, dynamic>{};
    final gold = p.dark ? const Color(0xFFF6D365) : CommunityLook.gold;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: CommunityLook.goldBackground(p), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const GoldCoin(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_t('أهدِ $_first ${g['coins']} عملة ذهبية', 'Gift $_first ${g['coins']} gold coins'),
                  style: p.text(15.5, weight: FontWeight.w800, color: gold)),
              Text(
                  _t('قيمتها ${g['value_lyd']} د.ل وتدفعها تاكسيستا، لا يُخصم منك شيء.',
                      'Worth ${g['value_lyd']} LYD, paid by Taxista. Nothing is taken from you.'),
                  style: p.text(12.5, color: p.sub)),
            ]),
          ),
          Switch.adaptive(
            key: const ValueKey('wrapup-gift'),
            value: _gift,
            activeThumbColor: CommunityLook.gold,
            onChanged: (v) => setState(() => _gift = v),
          ),
        ]),
      ),
      if (_gift && reasons.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final e in reasons.entries)
            CommunityChip(
              label: e.value.toString(),
              accent: CommunityLook.gold,
              selected: _giftReason == e.key,
              onTap: () => setState(() => _giftReason = _giftReason == e.key ? null : e.key),
            ),
        ]),
      ],
      const SizedBox(height: 18),
      _primary(p, enabled: true),
    ]);
  }

  Widget _doneCard(ChatPalette p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: CommunityLook.good.withValues(alpha: 0.13), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: CommunityLook.good, size: 50),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(_t('شكرًا لك', 'Thank you'),
          key: const ValueKey('wrapup-thanks'), textAlign: TextAlign.center, style: p.text(20, weight: FontWeight.w800)),
      for (final line in _thanks)
        Padding(padding: const EdgeInsets.only(top: 4), child: Text(line, textAlign: TextAlign.center, style: p.text(13.5, color: p.sub))),
      const SizedBox(height: 10),
    ]);
  }
}
