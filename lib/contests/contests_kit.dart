import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../functions/share_text.dart';

import '../widgets/chat/chat_kit.dart';
import 'contests_api.dart';
import 'reactions.dart';

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

  /// [kind] null takes the reaction back; another kind replaces it (the count stays)
  Future<void> _react(String? kind) async {
    final before = post['liked'] == true ? '${post['reaction'] ?? 'like'}' : null;
    if (before == kind) return;
    final delta = (kind != null ? 1 : 0) - (before != null ? 1 : 0);
    setState(() {
      post['liked'] = kind != null;
      post['reaction'] = kind;
      post['reactions'] = Reaction.adjust(post['reactions'], before, kind);
      post['counts'] = {...counts, 'likes': ((counts['likes'] ?? 0) as num).toInt() + delta};
    });
    final r = await ContestsApi.like((post['id'] as num).toInt(), kind != null, reaction: kind ?? 'like');
    if (r != null && mounted) {
      setState(() {
        post['counts'] = {...counts, 'likes': r['likes']};
        if (r['reactions'] is List) post['reactions'] = r['reactions'];
      });
    }
    widget.onChanged?.call(post);
  }

  /// «مشاركة»: WhatsApp first, then copy, then the phone's own sheet. The link opens the post in
  /// the app (or the page that installs it and then opens it).
  Future<void> _share() async {
    final id = (post['id'] as num).toInt();
    final question = '${post['contest']?['question'] ?? 'منشورات تاكسيستا'}';
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostSheet(question: question, imageUrl: '${post['image_url'] ?? ''}', link: '${post['share_url'] ?? ''}'),
    );
    if (picked == null || !mounted) return;
    final r = await ContestsApi.share(id, picked);
    final link = '${r?['url'] ?? post['share_url'] ?? ''}';
    if (r != null && mounted) setState(() => post['counts'] = {...counts, 'shares': r['shares']});
    widget.onChanged?.call(post);
    if (!mounted) return;
    final text = post['kind'] == 'contest' && post['contest']?['status'] == 'open'
        ? '$question 🤔\nتوقّع معاي في تاكسيستا 👇\n$link'
        : '$question\nشوف المنشور في تاكسيستا 👇\n$link';
    final say = ScaffoldMessenger.of(context);
    void done(String m) => say.showSnackBar(SnackBar(content: Text(m, style: ContestLook.p.text(14, color: Colors.white)), behavior: SnackBarBehavior.floating));
    if (picked == 'whatsapp') {
      final ok = await launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication).catchError((_) => false);
      if (!ok) {
        await Clipboard.setData(ClipboardData(text: text));
        done('ما انفتحش واتساب. نسخنا الرابط ✓ الصقه في أي محادثة.');
      }
    } else if (picked == 'copy') {
      await Clipboard.setData(ClipboardData(text: link));
      done('تم نسخ الرابط ✓');
    } else if (!await shareText(context, text)) {
      done('تم نسخ الرابط ✓');
    }
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
              ReactionFaces(reactions: post['reactions'], total: likes),
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
            _likeAction(p),
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

  /// «أعجبني»: a tap likes (or takes it back), a long press gives the six reactions
  Widget _likeAction(ChatPalette p) {
    final r = post['liked'] == true ? (Reaction.of(post['reaction']) ?? Reaction.all.first) : null;
    return Expanded(
      child: ReactionTrigger(
        key: ValueKey('post-like-${post['id']}'),
        current: r?.kind,
        onPick: _react,
        child: SizedBox(
          height: 42,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (r == null || r.kind == 'like')
              Icon(r == null ? Icons.thumb_up_alt_outlined : Icons.thumb_up_alt_rounded, size: 19, color: r?.color ?? p.sub)
            else
              Text(r.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(r?.label ?? 'أعجبني', style: p.text(13.5, weight: FontWeight.w700, color: r?.color ?? p.sub)),
          ]),
        ),
      ),
    );
  }

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
  const ContestCommentTile({super.key, required this.comment, required this.postId, this.compact = false, this.pinnedText, this.onReply, this.inThread = false});
  final Map<String, dynamic> comment;
  /// a reply shown under its top comment: smaller, and it names who it answers instead of quoting
  final bool inThread;
  /// «رد»: answer this comment (the post page fills the composer); null hides the button
  final ValueChanged<Map<String, dynamic>>? onReply;
  final int postId;
  final bool compact;
  final String? pinnedText;
  @override
  State<ContestCommentTile> createState() => _ContestCommentTileState();
}

class _ContestCommentTileState extends State<ContestCommentTile> {
  Map<String, dynamic> get c => widget.comment;

  Future<void> _react(String? kind) async {
    final before = c['liked'] == true ? '${c['reaction'] ?? 'like'}' : null;
    if (before == kind) return;
    setState(() {
      c['liked'] = kind != null;
      c['reaction'] = kind;
      c['reactions'] = Reaction.adjust(c['reactions'], before, kind);
      c['likes'] = ((c['likes'] ?? 0) as num).toInt() + (kind != null ? 1 : 0) - (before != null ? 1 : 0);
    });
    final r = await ContestsApi.likeComment(widget.postId, (c['id'] as num).toInt(), kind != null, reaction: kind ?? 'like');
    if (r != null && mounted) {
      setState(() {
        c['likes'] = r['likes'];
        if (r['reactions'] is List) c['reactions'] = r['reactions'];
      });
    }
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
                radius: widget.inThread ? 14 : 17,
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
                  if (c['reply_to'] is Map && !widget.inThread) _quote(Map<String, dynamic>.from(c['reply_to'])),
                  Wrap(spacing: 5, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(name, style: p.text(13, weight: FontWeight.w800)),
                    if (pinned) const _Verified(),
                    if (pinned) _tag('مثبّت', ContestLook.brand),
                    if (c['is_captain'] == true) _tag('كابتن', const Color(0xFF1965BF), solid: true),
                    if (mine && pred != null) _tag('توقّعك · نهائي', const Color(0xFFB7791F)),
                  ]),
                  if (body != null && body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text.rich(TextSpan(children: [
                        // a reply to a reply, inside the thread: who it answers, first
                        if (widget.inThread && c['reply_to'] is Map && c['reply_to']['id'] != c['thread_id'])
                          TextSpan(text: '${c['reply_to']['name'] ?? ''} ', style: p.text(13.5, weight: FontWeight.w800, color: ContestLook.brand)),
                        TextSpan(text: body),
                      ]), style: p.text(13.5, height: 1.55)),
                    ),
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
                      ReactionFaces(reactions: c['reactions'], total: likes, size: 16),
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
                  Builder(builder: (_) {
                    final r = c['liked'] == true ? (Reaction.of(c['reaction']) ?? Reaction.all.first) : null;
                    return ReactionTrigger(
                      key: ValueKey('comment-like-${c['id']}'),
                      small: true,
                      current: r?.kind,
                      onPick: _react,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(r == null ? 'أعجبني' : (r.kind == 'like' ? r.label : '${r.emoji} ${r.label}'),
                            style: p.text(11.5, weight: FontWeight.w800, color: r?.color ?? p.sub)),
                      ),
                    );
                  }),
                  if (widget.onReply != null) ...[
                    const SizedBox(width: 14),
                    GestureDetector(
                      key: ValueKey('reply-${c['id']}'),
                      onTap: () => widget.onReply!(c),
                      child: Text('رد', style: p.text(11.5, weight: FontWeight.w800, color: p.sub)),
                    ),
                  ],
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  /// the comment this one answers: its writer and its words, small, above the reply
  Widget _quote(Map<String, dynamic> q) {
    final p = ContestLook.p;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 8, 4),
      decoration: BoxDecoration(
        color: p.dark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(10),
        border: BorderDirectional(start: BorderSide(color: ContestLook.brand.withValues(alpha: .7), width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('↩ ${q['name'] ?? ''}', style: p.text(11.5, weight: FontWeight.w800, color: ContestLook.brand)),
        if ((q['text'] ?? '').toString().isNotEmpty) Text('${q['text']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: p.text(12, color: p.sub)),
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

/// «شارك المنشور»: WhatsApp first (most people here), then copy the link, then the phone's sheet.
/// Pops 'whatsapp' | 'copy' | 'other'.
class SharePostSheet extends StatelessWidget {
  const SharePostSheet({super.key, required this.question, required this.imageUrl, required this.link});
  final String question;
  final String imageUrl;
  final String link;

  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    Widget option(String key, IconData icon, String label) => Expanded(
          child: OutlinedButton.icon(
            key: ValueKey('share-$key'),
            onPressed: () => Navigator.pop(context, key),
            icon: Icon(icon, size: 19, color: p.ink),
            label: Text(label, style: p.text(14, weight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), side: BorderSide(color: p.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(color: p.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 12),
          Text('شارك المنشور', style: p.text(17, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
            child: Row(children: [
              if (imageUrl.startsWith('http'))
                ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: imageUrl, width: 58, height: 58, fit: BoxFit.cover)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(question, maxLines: 2, overflow: TextOverflow.ellipsis, style: p.text(13.5, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(link.replaceFirst(RegExp(r'^https?://'), ''), maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: p.text(12, color: ContestLook.brand)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('share-whatsapp'),
            onPressed: () => Navigator.pop(context, 'whatsapp'),
            icon: const Icon(Icons.chat_rounded, size: 20),
            label: Text('ابعته في واتساب', style: p.text(16, weight: FontWeight.w800, color: Colors.white)),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FAF5A), minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
          const SizedBox(height: 10),
          Row(children: [option('copy', Icons.link_rounded, 'انسخ الرابط'), const SizedBox(width: 10), option('other', Icons.more_horiz_rounded, 'تطبيقات أخرى')]),
          const SizedBox(height: 10),
          Text('صاحبك يضغط الرابط ← يفتحله المنشور على طول، حتى لو ما عندهش التطبيق.', style: p.text(12.5, color: p.sub, height: 1.6)),
        ]),
      ),
    );
  }
}
