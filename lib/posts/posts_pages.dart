import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';

import '../contests/contests_pages.dart';
import '../functions/calls/admin_call_controller.dart' show appNavigatorKey;
import '../functions/functions.dart' show bearerToken, url;
import 'post_video.dart';
import 'posts_api.dart';

/// «منشورات تاكسيستا»: the look (Taxista navy / blue, Cairo) shared by the feed, a post and the home card.
class PostLook {
  static const navy = Color(0xFF102A56);
  static const brand = Color(0xFF0873FF);
  static const ground = Color(0xFFE9EDF3);
  static const ink = Color(0xFF0F1B33);
  static const sub = Color(0xFF5A6A85);
  static TextStyle t(double size, {FontWeight w = FontWeight.w600, Color color = ink, double? h}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: w, color: color, height: h);

  static String ago(String? at) {
    final d = DateTime.tryParse(at ?? '');
    if (d == null) return '';
    final m = DateTime.now().difference(d).inMinutes;
    if (m < 1) return 'توا';
    if (m < 60) return 'قبل $m دقيقة';
    if (m < 60 * 24) return 'قبل ${m ~/ 60} ساعة';
    final days = m ~/ (60 * 24);
    return days == 1 ? 'أمس' : 'قبل $days أيام';
  }

  static String audience(String? a) => a == 'drivers' ? 'للكباتن' : (a == 'riders' ? 'للزبائن' : 'للكل');

  static String? thumb(Map p) {
    final v = p['video'];
    if (v is Map && '${v['poster'] ?? ''}'.startsWith('http')) return '${v['poster']}';
    final y = p['youtube'];
    if (y is Map && '${y['thumb'] ?? ''}'.startsWith('http')) return '${y['thumb']}';
    return null;
  }
}

class PostsFeedPage extends StatefulWidget {
  const PostsFeedPage({super.key, this.openPostId});
  final int? openPostId;

  @override
  State<PostsFeedPage> createState() => _PostsFeedPageState();
}

class _PostsFeedPageState extends State<PostsFeedPage> {
  final List<Map<String, dynamic>> _posts = [];
  int? _next;
  bool _loading = true, _more = false, _failed = false;
  final _scroll = ScrollController();
  final Set<int> _seen = {};

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_next != null && !_more && _scroll.position.extentAfter < 600) _loadMore();
    });
    if (widget.openPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostPage(id: widget.openPostId!)));
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await PostsApi.feed();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = d == null;
      if (d != null) {
        _posts
          ..clear()
          ..addAll(((d['posts'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
        _next = (d['next'] as num?)?.toInt();
      }
    });
  }

  Future<void> _loadMore() async {
    _more = true;
    final d = await PostsApi.feed(before: _next);
    _more = false;
    if (!mounted || d == null) return;
    setState(() {
      _posts.addAll(((d['posts'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
      _next = (d['next'] as num?)?.toInt();
    });
  }

  void _sawIt(Map p) {
    final id = (p['id'] as num).toInt();
    if (_seen.add(id)) PostsApi.event(id, 'view');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: PostLook.ground,
        appBar: AppBar(
          backgroundColor: PostLook.navy,
          foregroundColor: Colors.white,
          title: Text('منشورات تاكسيستا', style: PostLook.t(20, w: FontWeight.w800, color: Colors.white)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                _chip('المنشورات', true, null),
                const SizedBox(width: 8),
                _chip('مسابقات تاكسيستا', false, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContestsFeedPage()))),
              ]),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _posts.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Center(child: Text(_failed ? 'الشبكة ضعيفة. اسحب لتحت وحاول.' : 'ما فيش منشورات توا.', style: PostLook.t(15, color: PostLook.sub))),
                    ])
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        _sawIt(_posts[i]);
                        return PostCard(
                          post: _posts[i],
                          onChanged: (p) => setState(() => _posts[i] = p),
                          onOpen: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostPage(id: (_posts[i]['id'] as num).toInt(), initial: _posts[i]))),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback? tap) => Material(
        color: on ? Colors.white : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: on ? Colors.white : Colors.white54)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: tap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Text(label, style: PostLook.t(13.5, w: FontWeight.w800, color: on ? PostLook.navy : Colors.white)),
          ),
        ),
      );
}

/// One post in the feed (and at the top of its own page).
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onChanged, this.onOpen, this.inPage = false});
  final Map<String, dynamic> post;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback? onOpen;
  final bool inPage;

  int get _id => (post['id'] as num).toInt();
  Map get _counts => post['counts'] is Map ? post['counts'] as Map : const {};

  Future<void> _like() async {
    final on = post['liked'] != true;
    final likes = ((_counts['likes'] ?? 0) as num).toInt() + (on ? 1 : -1);
    onChanged({...post, 'liked': on, 'counts': {..._counts, 'likes': likes < 0 ? 0 : likes}});
    final d = await PostsApi.like(_id, on);
    if (d != null) onChanged({...post, 'liked': d['liked'] == true, 'counts': {..._counts, 'likes': d['likes']}});
  }

  void _share() {
    PostsApi.event(_id, 'share');
    final y = post['youtube'];
    final link = y is Map ? '${y['url']}' : '${url}app';
    unawaited(Share.share('${post['title']}\n$link'));
  }

  @override
  Widget build(BuildContext context) {
    final kind = '${post['kind']}';
    final body = '${post['body'] ?? ''}'.trim();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 0.6,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: const Color(0xFFDCE3EE))),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: Text('T', style: PostLook.t(22, w: FontWeight.w900, color: PostLook.brand, h: 1.1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تاكسيستا', style: PostLook.t(15, w: FontWeight.w800)),
                Text(PostLook.ago('${post['published_at'] ?? ''}'), style: PostLook.t(12, color: PostLook.sub)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: post['audience'] == 'riders' ? const Color(0xFFE5F7EF) : const Color(0xFFE6F0FF), borderRadius: BorderRadius.circular(10)),
              child: Text(PostLook.audience('${post['audience']}'), style: PostLook.t(12, w: FontWeight.w800, color: post['audience'] == 'riders' ? const Color(0xFF0B6B4C) : const Color(0xFF0B4FB3))),
            ),
          ]),
        ),
        InkWell(
          onTap: inPage ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${post['title'] ?? ''}', style: PostLook.t(16, w: FontWeight.w800, h: 1.45)),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(body, maxLines: inPage ? null : 4, overflow: inPage ? null : TextOverflow.ellipsis, style: PostLook.t(14, color: const Color(0xFF26334D), h: 1.7)),
              ],
            ]),
          ),
        ),
        if (kind == 'video') PostVideo(post: post),
        if (kind == 'youtube') _youtube(context),
        if (kind == 'youtube')
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: PostLook.brand, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => _openYoutube(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('شوف الفيديو', style: PostLook.t(15.5, w: FontWeight.w800, color: Colors.white)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Row(children: [
            if (((_counts['likes'] ?? 0) as num) > 0) ...[
              const Icon(Icons.thumb_up_alt_rounded, size: 16, color: PostLook.brand),
              const SizedBox(width: 4),
              Text('${_counts['likes']}', style: PostLook.t(12.5, w: FontWeight.w700, color: PostLook.sub)),
            ],
            const Spacer(),
            if (((_counts['comments'] ?? 0) as num) > 0) Text('${_counts['comments']} تعليق', style: PostLook.t(12.5, w: FontWeight.w700, color: PostLook.sub)),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE6EBF2)),
        Row(children: [
          _action(post['liked'] == true ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined, 'أعجبني', _like, on: post['liked'] == true),
          if (post['comments_enabled'] == true || inPage) _action(Icons.mode_comment_outlined, 'تعليق', inPage ? null : onOpen),
          _action(Icons.share_outlined, 'مشاركة', _share),
        ]),
      ]),
    );
  }

  Widget _youtube(BuildContext context) {
    final thumb = PostLook.thumb(post);
    return GestureDetector(
      onTap: _openYoutube,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(fit: StackFit.expand, children: [
          if (thumb != null) CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover) else const ColoredBox(color: Color(0xFF0B1224)),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, size: 40, color: PostLook.brand),
            ),
          ),
        ]),
      ),
    );
  }

  void _openYoutube() {
    final y = post['youtube'];
    if (y is! Map) return;
    PostsApi.event(_id, 'play');
    unawaited(launchUrl(Uri.parse('${y['url']}'), mode: LaunchMode.externalApplication));
  }

  Widget _action(IconData icon, String label, VoidCallback? tap, {bool on = false}) => Expanded(
        child: InkWell(
          onTap: tap,
          child: SizedBox(
            height: 46,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 20, color: on ? PostLook.brand : const Color(0xFF3D4B66)),
              const SizedBox(width: 6),
              Text(label, style: PostLook.t(14, w: FontWeight.w800, color: on ? PostLook.brand : const Color(0xFF3D4B66))),
            ]),
          ),
        ),
      );
}

/// One post with its comments and the box to write one.
class PostPage extends StatefulWidget {
  const PostPage({super.key, required this.id, this.initial});
  final int id;
  final Map<String, dynamic>? initial;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  Map<String, dynamic>? _post;
  final List<Map<String, dynamic>> _comments = [];
  int? _next;
  bool _gone = false, _sending = false;
  final _box = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.initial;
    _load();
  }

  @override
  void dispose() {
    _box.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await PostsApi.post(widget.id);
    final c = await PostsApi.comments(widget.id);
    if (!mounted) return;
    setState(() {
      if (p != null) _post = p;
      _gone = p == null && _post == null;
      if (c != null) {
        _comments
          ..clear()
          ..addAll(((c['comments'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
        _next = (c['next'] as num?)?.toInt();
      }
    });
    PostsApi.event(widget.id, 'view');
  }

  Future<void> _more() async {
    final c = await PostsApi.comments(widget.id, before: _next);
    if (!mounted || c == null) return;
    setState(() {
      _comments.addAll(((c['comments'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
      _next = (c['next'] as num?)?.toInt();
    });
  }

  Future<void> _send() async {
    final text = _box.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final (c, err) = await PostsApi.comment(widget.id, text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (c != null) {
        _box.clear();
        _comments.insert(0, c);
        final counts = Map<String, dynamic>.from((_post?['counts'] as Map?) ?? {});
        counts['comments'] = ((counts['comments'] ?? 0) as num).toInt() + 1;
        _post = {...?_post, 'counts': counts};
      }
    });
    if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err, style: PostLook.t(14, color: Colors.white))));
  }

  @override
  Widget build(BuildContext context) {
    final p = _post;
    final open = p?['comments_enabled'] == true;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: PostLook.ground,
        appBar: AppBar(backgroundColor: PostLook.navy, foregroundColor: Colors.white, title: Text('منشور', style: PostLook.t(18, w: FontWeight.w800, color: Colors.white))),
        body: p == null
            ? Center(child: _gone ? Text('المنشور مش موجود', style: PostLook.t(15, color: PostLook.sub)) : const CircularProgressIndicator())
            : Column(children: [
                Expanded(
                  child: ListView(padding: const EdgeInsets.fromLTRB(10, 12, 10, 12), children: [
                    PostCard(post: p, inPage: true, onChanged: (n) => setState(() => _post = n)),
                    const SizedBox(height: 12),
                    if (_comments.isEmpty)
                      Padding(padding: const EdgeInsets.all(18), child: Center(child: Text(open ? 'ما فيش تعليقات بعد. كن الأول!' : 'التعليقات مقفولة.', style: PostLook.t(14, color: PostLook.sub)))),
                    for (final c in _comments) _comment(c),
                    if (_next != null) TextButton(onPressed: _more, child: Text('تعليقات أكثر', style: PostLook.t(13.5, w: FontWeight.w800, color: PostLook.sub))),
                  ]),
                ),
                if (open)
                  SafeArea(
                    top: false,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _box,
                            maxLength: 400,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            style: PostLook.t(14.5),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'اكتب تعليق…',
                              hintStyle: PostLook.t(14.5, color: PostLook.sub),
                              filled: true,
                              fillColor: const Color(0xFFF0F2F5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(backgroundColor: PostLook.brand, minimumSize: const Size(46, 46)),
                          icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, color: Colors.white),
                          tooltip: 'إرسال',
                        ),
                      ]),
                    ),
                  ),
              ]),
      ),
    );
  }

  Widget _comment(Map c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 17, backgroundColor: c['is_captain'] == true ? PostLook.navy : PostLook.brand,
              child: Text('${c['name'] ?? '?'}'.characters.first, style: PostLook.t(14, w: FontWeight.w800, color: Colors.white))),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(color: c['mine'] == true ? const Color(0xFFFFF8E1) : Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${c['name'] ?? ''}', style: PostLook.t(13, w: FontWeight.w800)),
                  if (c['is_captain'] == true) ...[
                    const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: PostLook.navy, borderRadius: BorderRadius.circular(6)),
                        child: Text('كابتن', style: PostLook.t(10.5, w: FontWeight.w800, color: Colors.white))),
                  ],
                ]),
                Text('${c['body'] ?? ''}', style: PostLook.t(14, h: 1.6)),
              ]),
            ),
          ),
        ]),
      );
}

/// A «منشور جديد» push: the feed (and the post) open once the home screen is up.
class PostLink {
  static int? _pendingPost;
  static bool _pending = false;

  static bool handles(Map data) => data['push_type']?.toString() == 'media_post';

  static void openPush(Map data) {
    _pendingPost = int.tryParse('${data['post_id'] ?? ''}');
    _pending = true;
    flush();
  }

  static void flush() {
    final nav = appNavigatorKey.currentState;
    if (!_pending || nav == null || bearerToken.isEmpty) return;
    _pending = false;
    final post = _pendingPost;
    _pendingPost = null;
    nav.push(MaterialPageRoute(builder: (_) => PostsFeedPage(openPostId: post)));
  }
}
