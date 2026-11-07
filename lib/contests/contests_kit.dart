import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/chat/chat_kit.dart';
import 'contests_api.dart';

/// The look of «مسابقات تاكسيستا»: a post like a social one (Taxista's page name and picture, the
/// caption, the picture, likes · predictions · shares, three actions) and its comments, where a
/// prediction is a comment. Colours follow the app's palette (light and dark).
class ContestLook {
  static const brand = Color(0xFF0873FF);
  static const navy = [Color(0xFF102A56), Color(0xFF1965BF)];
  static const green = [Color(0xFF0B7A57), Color(0xFF14A47B)];
  static const gold = [Color(0xFFD69E2E), Color(0xFFF6D365)];
  static const icon = 'assets/images/taxista_icon.png';

  static ChatPalette get p => ChatPalette.current();
  static Color feed(ChatPalette p) => p.dark ? const Color(0xFF080D17) : const Color(0xFFE9EDF3);
  static Color bubble(ChatPalette p) => p.dark ? const Color(0xFF1B2537) : const Color(0xFFF0F2F5);
  static Color mineBubble(ChatPalette p) => p.dark ? const Color(0xFF2A2410) : const Color(0xFFFFF8E1);

  static const _avatarColors = [Color(0xFF0873FF), Color(0xFF14A47B), Color(0xFFB7791F), Color(0xFF7C3AED), Color(0xFFE0243A), Color(0xFF1965BF), Color(0xFF0E7490)];
  static Color avatarColor(String name) => _avatarColors[name.hashCode.abs() % _avatarColors.length];

  static String count(num n) {
    if (n >= 1000) {
      final k = (n / 1000);
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.0', '')} ألف';
    }
    return '$n';
  }

  static String ago(String? iso) {
    final t = ChatTime.parse(iso);
    if (t == null) return '';
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 60) return 'الآن';
    if (s < 3600) return 'منذ ${s ~/ 60} د';
    if (s < 86400) return 'منذ ${s ~/ 3600} س';
    if (s < 7 * 86400) return 'منذ ${s ~/ 86400} يوم';
    return '${t.day}/${t.month}';
  }
}

/// Taxista's round page picture (the current icon).
class TaxistaPageAvatar extends StatelessWidget {
  const TaxistaPageAvatar({super.key, this.size = 42});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: ContestLook.p.line)),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: EdgeInsets.all(size * .08), child: Image.asset(ContestLook.icon, fit: BoxFit.contain)),
      );
}

class _Verified extends StatelessWidget {
  const _Verified();
  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: ContestLook.brand),
        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
}

/// «التوقعات تقفل بعد 02:14:36» on the navy band; grey when closed; green after the result.
class ContestStatusStrip extends StatefulWidget {
  const ContestStatusStrip({super.key, required this.contest, required this.kind});
  final Map<String, dynamic> contest;
  final String kind;
  @override
  State<ContestStatusStrip> createState() => _ContestStatusStripState();
}

class _ContestStatusStripState extends State<ContestStatusStrip> {
  Timer? _t;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _end = DateTime.now().add(Duration(seconds: ((widget.contest['seconds_left'] ?? 0) as num).toInt()));
    if (widget.contest['status'] == 'open') _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    final status = '${widget.contest['status']}';
    final left = _end.difference(DateTime.now());
    final open = status == 'open' && !left.isNegative;
    final resolved = status == 'resolved' || status == 'paid';
    final grey = !open && !resolved;
    String two(int n) => n.toString().padLeft(2, '0');
    final text = widget.kind == 'winners'
        ? 'النتيجة: ${widget.contest['correct_text'] ?? ''}'
        : open
            ? 'التوقعات تقفل بعد'
            : resolved
                ? 'النتيجة طلعت · الفائزين في منشور «أصحاب التوقع الصحيح»'
                : 'قفلت التوقعات · النتيجة تنزل قريب';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: grey ? p.field : null,
        gradient: grey ? null : LinearGradient(colors: resolved || widget.kind == 'winners' ? ContestLook.green : ContestLook.navy),
      ),
      child: Row(children: [
        Icon(open ? Icons.schedule_rounded : (resolved ? Icons.check_circle_rounded : Icons.lock_rounded), size: 16, color: grey ? p.sub : Colors.white),
        const SizedBox(width: 6),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(12.5, weight: FontWeight.w700, color: grey ? p.sub : Colors.white))),
        if (open)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              for (final v in [left.inHours, left.inMinutes % 60, left.inSeconds % 60]) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(7)),
                  child: Text(two(v), style: p.text(13, weight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ]),
          ),
      ]),
    );
  }
}

/// One contest post. [full] shows the whole caption (the post page); the feed shows three lines,
/// the first two comments and «عرض كل التوقعات».
class ContestPostCard extends StatefulWidget {
  const ContestPostCard({super.key, required this.post, required this.onOpen, this.full = false, this.onChanged, this.onComment});
  final Map<String, dynamic> post;
  final VoidCallback onOpen;
  final bool full;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onComment;
  @override
  State<ContestPostCard> createState() => _ContestPostCardState();
}

class _ContestPostCardState extends State<ContestPostCard> {
  bool _more = false;
  Map<String, dynamic> get post => widget.post;
  Map<String, dynamic> get counts => Map<String, dynamic>.from(post['counts'] ?? {});

  Future<void> _like() async {
    final on = post['liked'] != true;
    setState(() {
      post['liked'] = on;
      post['counts'] = {...counts, 'likes': ((counts['likes'] ?? 0) as num).toInt() + (on ? 1 : -1)};
    });
    final r = await ContestsApi.like((post['id'] as num).toInt(), on);
    if (r != null && mounted) setState(() => post['counts'] = {...counts, 'likes': r['likes']});
    widget.onChanged?.call(post);
  }

  Future<void> _share() async {
    final id = (post['id'] as num).toInt();
    final r = await ContestsApi.share(id, 'app');
    final link = '${r?['url'] ?? post['share_url'] ?? ''}';
    if (r != null && mounted) setState(() => post['counts'] = {...counts, 'shares': r['shares']});
    widget.onChanged?.call(post);
    await Share.share('${post['contest']?['question'] ?? 'مسابقات تاكسيستا'}\nتوقّع داخل تطبيق تاكسيستا 👇\n$link');
  }

  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    final c = Map<String, dynamic>.from(post['contest'] ?? {});
    final caption = '${post['caption'] ?? ''}';
    final isContest = post['kind'] == 'contest';
    final mine = post['my_entry'] != null;
    final likes = ((counts['likes'] ?? 0) as num).toInt();
    final preview = [for (final x in (post['preview_comments'] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
    return Container(
      color: p.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            const TaxistaPageAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text('تاكسيستا', style: p.text(15, weight: FontWeight.w800)), const SizedBox(width: 4), const _Verified()]),
                Text('${ContestLook.ago('${post['published_at']}')} · ${isContest ? (c['label'] ?? 'مسابقة') : 'أصحاب التوقع الصحيح'}', style: p.text(12, color: p.sub)),
              ]),
            ),
          ]),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: widget.full || _more
                ? Text(caption, style: p.text(14.5, height: 1.7))
                : GestureDetector(
                    onTap: () => setState(() => _more = true),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(caption, maxLines: 3, overflow: TextOverflow.ellipsis, style: p.text(14.5, height: 1.7)),
                      if (caption.length > 110) Text('عرض المزيد', style: p.text(13, weight: FontWeight.w700, color: p.sub)),
                    ]),
                  ),
          ),
        if ((post['image_url'] ?? '').toString().startsWith('http'))
          GestureDetector(
            onTap: widget.full ? null : widget.onOpen,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: CachedNetworkImage(
                imageUrl: '${post['image_url']}',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: ContestLook.navy))),
                errorWidget: (_, __, ___) => Container(color: p.field, child: Icon(Icons.image_not_supported_outlined, color: p.sub)),
              ),
            ),
          ),
        ContestStatusStrip(key: ValueKey('strip-${post['id']}-${c['status']}'), contest: c, kind: '${post['kind']}'),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 6),
          child: Row(children: [
            if (likes > 0) ...[
              _reactions(),
              const SizedBox(width: 5),
              Text(ContestLook.count(likes), style: p.text(13, color: p.sub)),
            ],
            const Spacer(),
            InkWell(
              onTap: widget.onOpen,
              child: Text('${ContestLook.count(((counts['comments'] ?? 0) as num).toInt())} ${isContest ? 'توقّع' : 'تعليق'} · ${ContestLook.count(((counts['shares'] ?? 0) as num).toInt())} مشاركة',
                  style: p.text(13, color: p.sub)),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
          child: Row(children: [
            _action(post['liked'] == true ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined, 'أعجبني', post['liked'] == true ? ContestLook.brand : p.sub, _like),
            _action(Icons.mode_comment_outlined, isContest && post['can_predict'] == true ? 'توقّع' : (mine && isContest ? 'توقّعك' : 'تعليق'),
                isContest && (post['can_predict'] == true || mine) ? ContestLook.brand : p.sub, widget.onComment ?? widget.onOpen),
            _action(Icons.reply_rounded, 'مشاركة', p.sub, _share, flip: true),
          ]),
        ),
        if (!widget.full && preview.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: Column(children: [for (final x in preview) ContestCommentTile(comment: x, postId: (post['id'] as num).toInt(), compact: true)]),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: widget.onOpen, child: Text('عرض كل ${isContest ? 'التوقعات' : 'التعليقات'}', style: p.text(13, weight: FontWeight.w800, color: p.sub))),
          ),
        ] else
          const SizedBox(height: 4),
      ]),
    );
  }

  Widget _reactions() => SizedBox(
        width: 46,
        height: 19,
        child: Stack(children: [
          for (final (i, e) in [('👍', const Color(0xFF0873FF)), ('❤️', const Color(0xFFF33E58)), ('😮', const Color(0xFFF7B125))].indexed)
            PositionedDirectional(
              start: i * 13.0,
              child: Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: e.$2, shape: BoxShape.circle, border: Border.all(color: ContestLook.p.surface, width: 2)),
                child: Text(e.$1, style: const TextStyle(fontSize: 9)),
              ),
            ),
        ]),
      );

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap, {bool flip = false}) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 42,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Transform.flip(flipX: flip, child: Icon(icon, size: 19, color: color)),
              const SizedBox(width: 6),
              Text(label, style: ContestLook.p.text(13.5, weight: FontWeight.w700, color: color)),
            ]),
          ),
        ),
      );
}

/// One comment. A prediction shows as a chip under the words (green with ✓ when right after the
/// result; a lock when answers stay hidden until the contest closes).
class ContestCommentTile extends StatefulWidget {
  const ContestCommentTile({super.key, required this.comment, required this.postId, this.compact = false, this.pinnedText});
  final Map<String, dynamic> comment;
  final int postId;
  final bool compact;
  final String? pinnedText;
  @override
  State<ContestCommentTile> createState() => _ContestCommentTileState();
}

class _ContestCommentTileState extends State<ContestCommentTile> {
  Map<String, dynamic> get c => widget.comment;

  Future<void> _like() async {
    final on = c['liked'] != true;
    setState(() {
      c['liked'] = on;
      c['likes'] = ((c['likes'] ?? 0) as num).toInt() + (on ? 1 : -1);
    });
    final r = await ContestsApi.likeComment(widget.postId, (c['id'] as num).toInt(), on);
    if (r != null && mounted) setState(() => c['likes'] = r['likes']);
  }

  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    final pinned = widget.pinnedText != null;
    final name = pinned ? 'تاكسيستا' : '${c['name'] ?? ''}';
    final mine = c['is_mine'] == true;
    final pred = c['prediction'] is Map ? Map<String, dynamic>.from(c['prediction']) : null;
    final likes = ((c['likes'] ?? 0) as num).toInt();
    final body = pinned ? widget.pinnedText : (c['body_hidden'] == true ? null : c['body']?.toString());
    return Padding(
      padding: EdgeInsets.only(bottom: widget.compact ? 8 : 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        pinned
            ? const TaxistaPageAvatar(size: 34)
            : CircleAvatar(
                radius: 17,
                backgroundColor: ContestLook.avatarColor(name),
                child: Text(name.replaceFirst('الكابتن ', '').trim().isEmpty ? '؟' : name.replaceFirst('الكابتن ', '').trim().characters.first,
                    style: p.text(13, weight: FontWeight.w800, color: Colors.white)),
              ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
                decoration: BoxDecoration(
                  color: pinned ? ContestLook.brand.withValues(alpha: p.dark ? .18 : .09) : (mine ? ContestLook.mineBubble(p) : ContestLook.bubble(p)),
                  borderRadius: BorderRadius.circular(18),
                  border: mine ? Border.all(color: const Color(0xFFB7791F), width: 1.3) : null,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Wrap(spacing: 5, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(name, style: p.text(13, weight: FontWeight.w800)),
                    if (pinned) const _Verified(),
                    if (pinned) _tag('مثبّت', ContestLook.brand),
                    if (c['is_captain'] == true) _tag('كابتن', const Color(0xFF1965BF), solid: true),
                    if (mine && pred != null) _tag('توقّعك · نهائي', const Color(0xFFB7791F)),
                  ]),
                  if (body != null && body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 1), child: Text(body, style: p.text(13.5, height: 1.55))),
                  if (c['body_hidden'] == true) Text('أخفت الإدارة نص التعليق، والتوقّع باقي محسوب', style: p.text(11.5, color: p.sub)),
                  if (pred != null) Padding(padding: const EdgeInsets.only(top: 4), child: _predChip(pred)),
                ]),
              ),
              if (likes > 0 && !pinned)
                PositionedDirectional(
                  end: -6,
                  bottom: -9,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(3, 1, 6, 1),
                    decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(99), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 15, height: 15, decoration: const BoxDecoration(color: ContestLook.brand, shape: BoxShape.circle), child: const Icon(Icons.thumb_up_rounded, size: 9, color: Colors.white)),
                      const SizedBox(width: 3),
                      Text('$likes', style: p.text(11, weight: FontWeight.w800)),
                    ]),
                  ),
                ),
            ]),
            if (!pinned)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(ContestLook.ago('${c['created_at']}'), style: p.text(11.5, color: p.sub)),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: _like,
                    child: Text('أعجبني', style: p.text(11.5, weight: FontWeight.w800, color: c['liked'] == true ? ContestLook.brand : p.sub)),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _tag(String t, Color color, {bool solid = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        decoration: BoxDecoration(color: solid ? color : color.withValues(alpha: .14), borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: ContestLook.p.text(10, weight: FontWeight.w800, color: solid ? Colors.white : color)),
      );

  Widget _predChip(Map<String, dynamic> pred) {
    final p = ContestLook.p;
    final hidden = pred['hidden'] == true;
    final correct = pred['correct'];
    final good = correct == true;
    final color = good ? const Color(0xFF14A47B) : (hidden ? p.sub : ContestLook.brand);
    return Opacity(
      opacity: correct == false ? .6 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 9, 3),
        decoration: BoxDecoration(
          color: good ? const Color(0xFF14A47B).withValues(alpha: .12) : p.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: good ? const Color(0xFF14A47B) : p.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(good ? Icons.check_rounded : (hidden ? Icons.lock_rounded : Icons.sports_soccer_rounded), size: 12, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(hidden ? 'الإجابة مخفية لين تقفل' : '${pred['text'] ?? ''}${good ? ' · صح' : ''}',
                style: p.text(12.5, weight: FontWeight.w800, color: good ? const Color(0xFF0B7A57) : p.ink)),
          ),
        ]),
      ),
    );
  }
}
