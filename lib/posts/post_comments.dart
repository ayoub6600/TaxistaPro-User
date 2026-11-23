import 'package:flutter/material.dart';

import '../contests/reactions.dart';
import 'posts_api.dart';
import 'posts_pages.dart' show PostLook;

/// One comment under a video post: the same reactions and «رد» as the contest posts (owner
/// 2026-11-23 «زي الفيسبوك»). A reply in its thread is smaller and names who it answers.
class PostCommentTile extends StatefulWidget {
  const PostCommentTile({super.key, required this.postId, required this.comment, this.onReply, this.inThread = false});
  final int postId;
  final Map<String, dynamic> comment;
  final ValueChanged<Map<String, dynamic>>? onReply;
  final bool inThread;
  @override
  State<PostCommentTile> createState() => _PostCommentTileState();
}

class _PostCommentTileState extends State<PostCommentTile> {
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
    final r = await PostsApi.likeComment(widget.postId, (c['id'] as num).toInt(), kind != null, reaction: kind ?? 'like');
    if (r != null && mounted) {
      setState(() {
        c['likes'] = r['likes'];
        if (r['reactions'] is List) c['reactions'] = r['reactions'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${c['name'] ?? ''}';
    final mine = c['mine'] == true || c['is_mine'] == true;
    final likes = ((c['likes'] ?? 0) as num).toInt();
    final r = c['liked'] == true ? (Reaction.of(c['reaction']) ?? Reaction.all.first) : null;
    final answers = widget.inThread && c['reply_to'] is Map && c['reply_to']['id'] != c['thread_id'] ? '${c['reply_to']['name'] ?? ''} ' : '';
    return Padding(
      padding: EdgeInsets.only(bottom: widget.inThread ? 8 : 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: widget.inThread ? 14 : 17,
          backgroundColor: c['is_captain'] == true ? PostLook.navy : PostLook.brand,
          child: Text(name.isEmpty ? '?' : name.characters.first, style: PostLook.t(widget.inThread ? 12 : 14, w: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(color: mine ? const Color(0xFFFFF8E1) : Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(name, style: PostLook.t(13, w: FontWeight.w800)),
                    if (c['is_captain'] == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: PostLook.navy, borderRadius: BorderRadius.circular(6)),
                        child: Text('كابتن', style: PostLook.t(10.5, w: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ]),
                  Text.rich(
                    TextSpan(children: [
                      if (answers.isNotEmpty) TextSpan(text: answers, style: PostLook.t(14, w: FontWeight.w800, color: PostLook.brand, h: 1.6)),
                      TextSpan(text: '${c['body'] ?? ''}'),
                    ]),
                    style: PostLook.t(14, h: 1.6),
                  ),
                ]),
              ),
              if (likes > 0)
                PositionedDirectional(
                  end: -6,
                  bottom: -9,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(3, 1, 6, 1),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      ReactionFaces(reactions: c['reactions'], total: likes, size: 16),
                      const SizedBox(width: 3),
                      Text('$likes', style: PostLook.t(11, w: FontWeight.w800)),
                    ]),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(PostLook.ago('${c['created_at'] ?? c['at'] ?? ''}'), style: PostLook.t(11.5, color: PostLook.sub)),
                const SizedBox(width: 14),
                ReactionTrigger(
                  key: ValueKey('post-comment-like-${c['id']}'),
                  small: true,
                  current: r?.kind,
                  onPick: _react,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(r == null ? 'أعجبني' : (r.kind == 'like' ? r.label : '${r.emoji} ${r.label}'),
                        style: PostLook.t(11.5, w: FontWeight.w800, color: r?.color ?? PostLook.sub)),
                  ),
                ),
                if (widget.onReply != null) ...[
                  const SizedBox(width: 14),
                  GestureDetector(
                    key: ValueKey('post-reply-${c['id']}'),
                    onTap: () => widget.onReply!(c),
                    child: Text('رد', style: PostLook.t(11.5, w: FontWeight.w800, color: PostLook.sub)),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
