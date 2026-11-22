import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'posts_api.dart';
import 'posts_pages.dart';

/// The newest post on the home map (for its days, set in Taxista Admin): its picture with ▶, the
/// title and «شوف». A sideways swipe closes it for good.
class PostHomeCard extends StatelessWidget {
  const PostHomeCard({super.key, required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final id = (post['id'] as num).toInt();
    final thumb = PostLook.thumb(post);
    final video = post['kind'] == 'video' || post['kind'] == 'youtube';
    final secs = post['video'] is Map ? ((post['video']['duration_s'] ?? 0) as num).toInt() : 0;
    final sub = [
      if (video) 'فيديو',
      if (secs > 0) secs < 60 ? '$secs ثانية' : '${(secs / 60).round()} دقيقة',
      PostLook.audience('${post['audience']}'),
    ].join(' · ');
    return Dismissible(
      key: ValueKey('post-home-$id'),
      onDismissed: (_) => PostsApi.dismissHome(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              PostsApi.event(id, 'view');
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostsFeedPage(openPostId: id)));
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .97),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffDCEBFF)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 48,
                    child: Stack(fit: StackFit.expand, children: [
                      if (thumb != null) CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover, memCacheWidth: 192) else const ColoredBox(color: PostLook.navy),
                      if (video)
                        Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded, size: 18, color: PostLook.brand),
                          ),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('${post['title'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: PostLook.t(14, w: FontWeight.w800)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: PostLook.t(12, color: PostLook.sub)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: PostLook.brand, borderRadius: BorderRadius.circular(20)),
                  child: Text('شوف', style: PostLook.t(14, w: FontWeight.w800, color: Colors.white)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
