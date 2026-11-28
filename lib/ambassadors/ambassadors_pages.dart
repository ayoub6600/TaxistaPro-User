import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../functions/money_label.dart';
import '../functions/share_text.dart';
import '../pages/NavigatorPages/walletpage.dart';
import '../widgets/widgets.dart' show Button;
import 'ambassadors_api.dart';
import 'ambassadors_kit.dart';
import 'ambassadors_sheets.dart';

/// Opens the wallet to top up (any method the rider's market has), then comes back.
typedef AmbOpenWallet = Future<void> Function(BuildContext context);

Future<void> _wallet(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletPage()));

String _bareLink(String link) => link.replaceFirst(RegExp(r'^https?://'), '');

/// «سفراء تاكسيستا» (board Main): before he joins, the rules and «ولّي سفير»; after, his code big,
/// its QR, WhatsApp / copy, what he earned, his friends, and the gold card.
class AmbassadorsPage extends StatefulWidget {
  const AmbassadorsPage({super.key, this.openWallet});

  /// tests replace the wallet page
  final AmbOpenWallet? openWallet;

  @override
  State<AmbassadorsPage> createState() => _AmbassadorsPageState();
}

class _AmbassadorsPageState extends State<AmbassadorsPage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final r = await AmbassadorsApi.me();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.ok ? null : r.error;
    });
  }

  Future<void> _join() async {
    final r = await AmbassadorsApi.join();
    if (!mounted) return;
    if (!r.ok) {
      ambSay(context, r.error ?? AmbassadorsApi.failed);
      return;
    }
    if (r.state!.active) ambSay(context, 'مبروك، ولّيت سفير تاكسيستا ✓ شارك كودك مع صحابك.');
  }

  void _share(BuildContext from, String text, {String copied = 'ما انفتحش المشاركة. نسخنا الرسالة ✓ الصقها في واتساب.'}) {
    unawaited(shareText(from, text).then((opened) {
      if (!opened && mounted) ambSay(context, copied);
    }));
  }

  Future<void> _copy(String text, String said) async {
    await Clipboard.setData(ClipboardData(text: text));
    unawaited(HapticFeedback.selectionClick());
    if (mounted) ambSay(context, said);
  }

  void _openGold() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AmbassadorGoldPage(openWallet: widget.openWallet)));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AmbLook.ground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          foregroundColor: AmbLook.ink,
          titleSpacing: 0,
          title: Text('سفراء تاكسيستا', style: AmbLook.t(19, w: FontWeight.w800)),
          shape: const Border(bottom: BorderSide(color: AmbLook.line)),
        ),
        body: ValueListenableBuilder<AmbassadorState?>(
          valueListenable: AmbassadorsApi.state,
          builder: (context, s, _) {
            if (s == null) return _waiting();
            return RefreshIndicator(
              color: AmbLook.blue,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + MediaQuery.paddingOf(context).bottom),
                children: !s.enabled
                    ? [const AmbNote('سفراء تاكسيستا مش متاحة توا. ارجع بعد شوية.')]
                    : s.active && s.code != null && s.riderLink != null
                        ? _active(s)
                        : _intro(s),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _waiting() {
    if (_loading || _error == null) return const Center(child: CircularProgressIndicator(color: AmbLook.blue));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center, style: AmbLook.t(15, color: AmbLook.sub, h: 1.6)),
          const SizedBox(height: 16),
          Button(onTap: _load, text: 'جرّب مرة ثانية', backgroundcolor: AmbLook.blue, width: 220.0),
        ]),
      ),
    );
  }

  Widget _hero(AmbassadorState s) {
    final share = ambNum(s.sharePct);
    final String line;
    if (!s.active) {
      line = 'كل مشوار يديره صاحبك تاخذ منه $share% من ربح تاكسيستا (يعني ${ambNum(s.rules.pct)}% من سعر المشوار)، لمدة ${ambMonths(s.rules.months)}.';
    } else if (s.gold.active) {
      line = 'كل مشوار يديره صاحبك تاخذ منه $share% من ربح تاكسيستا، وتقدر تسحب أرباحك.';
    } else {
      line = 'كل مشوار يديره صاحبك تاخذ منه $share% من ربح تاكسيستا، لمدة ${ambMonths(s.rules.months)}، تنزل في محفظتك وتستعملها في مشاويرك.';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AmbLook.blue, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('جيب صحابك، واكسب من كل مشوار', style: AmbLook.t(21, w: FontWeight.w800, color: Colors.white, h: 1.4)),
        const SizedBox(height: 6),
        Text(line, style: AmbLook.t(13.5, color: AmbLook.blueSoft, h: 1.6)),
      ]),
    );
  }

  // ------------------------------------------------------------ not yet an ambassador

  List<Widget> _intro(AmbassadorState s) {
    final r = s.rules;
    final share = ambNum(r.shareOfProfit);
    final example = moneyAmount(20 * r.pct / 100);
    Widget tick(String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✓', style: AmbLook.t(15, w: FontWeight.w800, color: AmbLook.blue)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AmbLook.t(14, h: 1.6))),
          ]),
        );
    return [
      _hero(s),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: AmbLook.card(radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('كيف تكسب؟', style: AmbLook.t(15, w: FontWeight.w800)),
          tick('تاخذ كود من 5 أرقام ورابط وباركود، تبعتهم لصحابك.'),
          tick('صاحبك يسجّل بكودك وياخذ خصم ${moneyAmount(r.inviteeLyd)} د.ل على أول مشوار.'),
          tick('من كل مشوار يديره تاخذ $share% من ربح تاكسيستا، يعني ${ambNum(r.pct)}% من سعر المشوار، لمدة ${ambMonths(r.months)}.'),
          tick('الفلوس تنزل في محفظتك كل أسبوع وتستعملها في مشاويرك.'),
          tick('لو جبت كابتن، مشاويره تتحسبلك بنفس الطريقة.'),
          const SizedBox(height: 10),
          Text('مثال: صاحبك دار مشوار بـ20 د.ل ← تاخذ منه $example د.ل.', style: AmbLook.t(12.5, color: AmbLook.mute, h: 1.6)),
        ]),
      ),
      const SizedBox(height: 14),
      if (s.revoked)
        AmbNote(s.joinNote ?? 'حساب السفير متاعك موقوف. لو عندك سؤال كلّم الدعم.')
      else if (s.canJoin)
        Button(key: const ValueKey('amb-join'), onTap: _join, text: 'ولّي سفير', backgroundcolor: AmbLook.blue, width: double.infinity)
      else
        AmbNote(s.joinNote ?? 'تقدر تولّي سفير بعد ما تكمّل أول مشوار مع تاكسيستا.'),
      if (s.active && s.code == null) ...[
        const SizedBox(height: 10),
        const AmbNote('كودك مش جاهز توا. ارجع بعد شوية.'),
      ],
      // gold earnings left (even after a stop): the way to «اسحب أرباحك» stays open
      if (s.withdraw.allowed) ...[
        const SizedBox(height: 12),
        _goldCard(s),
      ],
    ];
  }

  // ------------------------------------------------------------ his code and his friends

  List<Widget> _active(AmbassadorState s) {
    final code = s.code!;
    final link = s.riderLink!;
    final jar = s.jar ?? const AmbassadorJar();
    return [
      _hero(s),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: AmbLook.card(),
        child: Row(children: [
          Semantics(
            button: true,
            label: 'الباركود متاعك، كبّره',
            child: GestureDetector(
              onTap: () => showAmbassadorQrSheet(context, code: code, link: link),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AmbLook.line)),
                child: QrImageView(
                  key: const ValueKey('amb-qr'),
                  data: link,
                  size: 104,
                  padding: const EdgeInsets.all(6),
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AmbLook.ink),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AmbLook.ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('كودك (صاحبك يكتبه وقت يسجّل)', style: AmbLook.t(12.5, color: AmbLook.sub)),
              GestureDetector(
                onTap: () => _copy(code, 'تم نسخ الكود ✓'),
                child: Text(code, textDirection: TextDirection.ltr, style: AmbLook.t(34, w: FontWeight.w800, h: 1.3).copyWith(letterSpacing: 4)),
              ),
              Text(_bareLink(link), textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis, style: AmbLook.t(12, color: AmbLook.sub)),
              if (s.gold.active) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AmbLook.cream, borderRadius: BorderRadius.circular(99), border: Border.all(color: AmbLook.creamLine)),
                  child: Text('سفير ذهبي', style: AmbLook.t(12, w: FontWeight.w800, color: AmbLook.brown)),
                ),
              ],
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Builder(
            builder: (from) => Button(
              key: const ValueKey('amb-whatsapp'),
              onTap: () => _share(from, s.shareText ?? link),
              text: 'شارك في واتساب',
              backgroundcolor: AmbLook.green,
              height: 46.0,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              key: const ValueKey('amb-copy'),
              onPressed: () => _copy(link, 'تم نسخ الرابط ✓'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AmbLook.lineStrong),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('انسخ الرابط', style: AmbLook.t(15, w: FontWeight.w700)),
            ),
          ),
        ),
      ]),
      if (s.captainLink != null)
        Builder(
          builder: (from) => TextButton.icon(
            onPressed: () => _share(from, '🚕 تبي تخدم كابتن مع تاكسيستا؟ سجّل من رابطي:\n${s.captainLink}\nولو طلب منك كود الدعوة: $code'),
            icon: const Icon(Icons.local_taxi_rounded, size: 18, color: AmbLook.blue),
            label: Text('عندك صاحب كابتن؟ ابعتله رابط الكباتن', style: AmbLook.t(13.5, w: FontWeight.w700, color: AmbLook.blue)),
          ),
        )
      else
        const SizedBox(height: 12),
      Row(children: [
        _stat('${jar.friends}', 'جبتهم'),
        const SizedBox(width: 8),
        _stat('${jar.rides}', 'مشاويرهم'),
        const SizedBox(width: 8),
        _stat(moneyAmount(jar.totalLyd), 'د.ل كسبتهم', color: AmbLook.blue),
      ]),
      if (jar.weekLyd > 0) ...[
        const SizedBox(height: 8),
        Text('هذا الأسبوع: +${moneyAmount(jar.weekLyd)} د.ل · تنزل في محفظتك كل أسبوع',
            textAlign: TextAlign.center, style: AmbLook.t(12.5, color: AmbLook.sub)),
      ],
      const SizedBox(height: 12),
      _friends(s.friends),
      if (s.gold.enabled || s.withdraw.allowed) ...[
        const SizedBox(height: 12),
        _goldCard(s),
      ],
      if (!s.withdraw.allowed) ...[
        const SizedBox(height: 12),
        const AmbNote('فلوس السفراء تستعملها في مشاويرك. السحب للسفير الذهبي بس.'),
      ],
    ];
  }

  Widget _stat(String value, String label, {Color color = AmbLook.ink}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: AmbLook.card(radius: 16),
          child: Column(children: [
            Text(value, textDirection: TextDirection.ltr, style: AmbLook.t(22, w: FontWeight.w800, color: color, h: 1.3)),
            Text(label, textAlign: TextAlign.center, style: AmbLook.t(12, color: AmbLook.sub)),
          ]),
        ),
      );

  static const _avatars = [
    (Color(0xFFDBEAFE), Color(0xFF1E3A8A)),
    (Color(0xFFFCE7F3), Color(0xFF9D174D)),
    (Color(0xFFE0F2FE), Color(0xFF075985)),
  ];

  Widget _friends(List<AmbassadorFriend> friends) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: AmbLook.card(radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('صحابك', style: AmbLook.t(15, w: FontWeight.w800)),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('لسه ما جبت حد. شارك كودك، وأول ما يسجّل صاحبك يطلع هنا.', style: AmbLook.t(13, color: AmbLook.sub, h: 1.6)),
            ),
          for (var i = 0; i < friends.length; i++) _friend(friends[i], i),
        ]),
      );

  Widget _friend(AmbassadorFriend f, int i) {
    final (bg, fg) = f.captain ? (const Color(0xFFFEF3C7), const Color(0xFF92400E)) : _avatars[i % _avatars.length];
    final name = f.captain && !f.name.startsWith('كابتن') ? 'كابتن ${f.name}' : f.name;
    final letter = f.name.trim().isEmpty ? '؟' : f.name.trim().characters.first;
    final line = [
      if (f.captain) 'كابتن جبته',
      if (f.rides > 0) ambRides(f.rides),
      if (f.stateText != null) f.stateText!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Text(letter, style: AmbLook.t(15, w: FontWeight.w800, color: fg)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AmbLook.t(14, w: FontWeight.w700)),
            if (line.isNotEmpty) Text(line, style: AmbLook.t(12, color: AmbLook.sub)),
          ]),
        ),
        const SizedBox(width: 8),
        f.earnedLyd > 0
            ? Text('+${moneyAmount(f.earnedLyd)}', textDirection: TextDirection.ltr, style: AmbLook.t(14, w: FontWeight.w800, color: AmbLook.greenText))
            : Text('—', style: AmbLook.t(13, color: AmbLook.mute)),
      ]),
    );
  }

  Widget _goldCard(AmbassadorState s) {
    final g = s.gold;
    final w = s.withdraw;
    final String title;
    final String sub;
    if (g.active) {
      title = 'انت سفير ذهبي ✓';
      sub = '${g.untilLabel != null ? 'لين ${g.untilLabel} · ' : ''}تقدر تسحب أرباحك';
    } else if (w.allowed && w.availableLyd > 0) {
      title = 'السفير الذهبي';
      sub = 'عندك ${moneyAmount(w.availableLyd)} د.ل تقدر تسحبها';
    } else {
      title = 'السفير الذهبي';
      sub = '${ambNum(g.shareOfProfit)}% من ربح تاكسيستا، وتقدر تسحب فلوسك';
    }
    return Material(
      color: AmbLook.cream,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const ValueKey('amb-gold-card'),
        borderRadius: BorderRadius.circular(18),
        onTap: _openGold,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AmbLook.creamLine)),
          child: Row(children: [
            const AmbCrown(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AmbLook.t(14, w: FontWeight.w800)),
                Text(sub, style: AmbLook.t(12.5, color: AmbLook.brown)),
              ]),
            ),
            const Icon(Icons.chevron_left_rounded, color: AmbLook.brown),
          ]),
        ),
      ),
    );
  }
}

/// The QR big, for a friend standing next to him to scan with his phone's camera.
Future<void> showAmbassadorQrSheet(BuildContext context, {required String code, required String link}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmbSheet(children: [
        Text('خلّي صاحبك يصوّر الباركود بكاميرا تليفونه', textAlign: TextAlign.center, style: AmbLook.t(17, w: FontWeight.w800)),
        const SizedBox(height: 14),
        Center(
          child: QrImageView(
            data: link,
            size: 240,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AmbLook.ink),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AmbLook.ink),
          ),
        ),
        const SizedBox(height: 10),
        Text(code, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: AmbLook.t(30, w: FontWeight.w800).copyWith(letterSpacing: 4)),
        Text(_bareLink(link), textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: AmbLook.t(12.5, color: AmbLook.sub)),
      ]),
    );

/// «السفير الذهبي» (board Gold): the two tiers side by side, the conditions, the wallet, and
/// «اشترك» (or «اشحن» when the wallet is short). With gold earnings: what he can withdraw,
/// «اسحب أرباحك» and his requests.
class AmbassadorGoldPage extends StatefulWidget {
  const AmbassadorGoldPage({super.key, this.openWallet});

  final AmbOpenWallet? openWallet;

  @override
  State<AmbassadorGoldPage> createState() => _AmbassadorGoldPageState();
}

class _AmbassadorGoldPageState extends State<AmbassadorGoldPage> {
  @override
  void initState() {
    super.initState();
    unawaited(AmbassadorsApi.me());
  }

  Future<void> _topUp() async {
    await (widget.openWallet ?? _wallet)(context);
    await AmbassadorsApi.me();
  }

  Future<void> _subscribe(AmbassadorState s) async {
    final r = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmbassadorGoldConfirmSheet(state: s),
    );
    if (!mounted) return;
    if (r == AmbassadorGoldConfirmSheet.topUp) {
      await _topUp();
    } else if (r is AmbassadorState && r.gold.active) {
      ambSay(context, 'مبروك! ولّيت سفير ذهبي ✓');
    }
  }

  Future<void> _withdraw(AmbassadorState s) async {
    final r = await showModalBottomSheet<AmbassadorState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmbassadorWithdrawSheet(withdraw: s.withdraw),
    );
    if (r != null && mounted) ambSay(context, 'وصلنا طلب السحب ✓ نحوّلولك الفلوس ويوصلك إشعار.');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AmbLook.night,
        appBar: AppBar(
          backgroundColor: AmbLook.night,
          surfaceTintColor: AmbLook.night,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: AmbLook.goldLight,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: ValueListenableBuilder<AmbassadorState?>(
          valueListenable: AmbassadorsApi.state,
          builder: (context, s, _) {
            if (s == null) return const Center(child: CircularProgressIndicator(color: AmbLook.gold));
            final buy = s.gold.enabled && !s.gold.active && s.active;
            return Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), children: _content(s)),
              ),
              if (buy) _buyBlock(s),
            ]);
          },
        ),
      ),
    );
  }

  List<Widget> _content(AmbassadorState s) {
    final g = s.gold;
    final w = s.withdraw;
    final goldShare = ambNum(g.shareOfProfit);
    Widget tick(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✓', style: AmbLook.t(14, w: FontWeight.w800, color: AmbLook.goldLight)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AmbLook.t(14, color: Colors.white, h: 1.6))),
          ]),
        );
    return [
      const SizedBox(height: 6),
      const Center(child: AmbCrown(size: 72)),
      const SizedBox(height: 8),
      Text(g.active ? 'انت سفير ذهبي ✓' : 'السفير الذهبي', textAlign: TextAlign.center, style: AmbLook.t(26, w: FontWeight.w800, color: AmbLook.goldLight)),
      Text(
        g.active
            ? (g.untilLabel != null ? 'اشتراكك ماشي لين ${g.untilLabel}' : 'اشتراكك ماشي')
            : 'للي يسوّق بجد: ضعف النسبة، والفلوس تقدر تسحبها',
        textAlign: TextAlign.center,
        style: AmbLook.t(14, color: AmbLook.sand, h: 1.6),
      ),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: _tier(
            head: 'العادي · ببلاش',
            pct: '${ambNum(s.rules.shareOfProfit)}%',
            foot: 'من ربح تاكسيستا\nفي مشاويرك بس',
            gold: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tier(
            head: 'الذهبي · ${moneyAmount(g.priceLyd)} د.ل',
            pct: '$goldShare%',
            foot: 'من ربح تاكسيستا\n+ سحب الفلوس',
            gold: true,
          ),
        ),
      ]),
      const SizedBox(height: 14),
      tick('${ambMonths(g.months)} من يوم ما تشترك، وتجدد بسعر يومها'),
      tick('كل الزبائن والكباتن اللي جبتهم يتحسبولك $goldShare% (يعني ${ambNum(g.pct)}% من سعر المشوار)'),
      tick('تسحب أرباحك تحويل على حسابك في المصرف أو LYPay'),
      tick('شارة «سفير ذهبي» في التطبيق'),
      if (w.allowed) ...[
        const SizedBox(height: 4),
        _withdrawBox(s),
      ],
      if (w.requests.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text('طلبات السحب', style: AmbLook.t(15, w: FontWeight.w800, color: AmbLook.goldLight)),
        const SizedBox(height: 6),
        for (final r in w.requests) _request(r),
      ],
      if (!s.active && !w.allowed) ...[
        const SizedBox(height: 4),
        const AmbNote('ولّي سفير الأول من صفحة «سفراء تاكسيستا»، وبعدها تقدر تشترك في الذهبي.', tone: AmbNoteTone.night),
      ],
    ];
  }

  Widget _tier({required String head, required String pct, required String foot, required bool gold}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gold ? AmbLook.nightGold : AmbLook.nightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gold ? AmbLook.gold : AmbLook.nightLine, width: gold ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(head, style: AmbLook.t(13, w: gold ? FontWeight.w800 : FontWeight.w700, color: gold ? AmbLook.goldLight : AmbLook.sandDim)),
          const SizedBox(height: 4),
          Text(pct, textDirection: TextDirection.ltr, style: AmbLook.t(22, w: FontWeight.w800, color: gold ? AmbLook.goldLight : Colors.white)),
          const SizedBox(height: 4),
          Text(foot, style: AmbLook.t(12, color: gold ? const Color(0xFFF5E6C0) : AmbLook.sandDim, h: 1.6)),
        ]),
      );

  Widget _withdrawBox(AmbassadorState s) {
    final w = s.withdraw;
    final String? why = w.canAsk
        ? null
        : (w.note ?? 'أقل سحب ${moneyAmount(w.minLyd)} د.ل، وعندك توا ${moneyAmount(w.availableLyd)} د.ل.');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AmbLook.nightCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AmbLook.nightLine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('أرباحك اللي تقدر تسحبها', style: AmbLook.t(13, color: AmbLook.sand)),
        Text('${moneyAmount(w.availableLyd)} د.ل', style: AmbLook.t(30, w: FontWeight.w800, color: Colors.white, h: 1.4)),
        if (w.minLyd > 0) Text('أقل سحب ${moneyAmount(w.minLyd)} د.ل', style: AmbLook.t(12, color: AmbLook.sandDim)),
        const SizedBox(height: 10),
        Button(
          key: const ValueKey('amb-withdraw'),
          // the sheet does the waiting (its own button spins), not this one behind it
          onTap: w.canAsk ? () => unawaited(_withdraw(s)) : null,
          text: 'اسحب أرباحك',
          backgroundcolor: AmbLook.gold,
          textcolor: AmbLook.night,
          height: 50.0,
          width: double.infinity,
        ),
        if (why != null) ...[
          const SizedBox(height: 8),
          Text(why, style: AmbLook.t(12.5, color: AmbLook.sand, h: 1.6)),
        ],
      ]),
    );
  }

  static String _when(DateTime? at) {
    if (at == null) return '';
    final d = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.day}/${d.month} ${two(d.hour)}:${two(d.minute)}';
  }

  Widget _request(AmbassadorWithdrawRequest r) {
    final (fg, bg, fallback) = switch (r.status) {
      'paid' => (const Color(0xFF86EFAC), const Color(0xFF14361F), 'اتحوّلت ✓'),
      'refused' => (const Color(0xFFFCA5A5), const Color(0xFF3B1414), 'مرفوض'),
      _ => (AmbLook.goldLight, AmbLook.nightGold, 'تحت التحويل'),
    };
    final when = _when(r.at);
    final line = [if (r.bank != null) r.bank!, if (when.isNotEmpty) when].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AmbLook.nightCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AmbLook.nightLine)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${moneyAmount(r.amountLyd)} د.ل', style: AmbLook.t(15, w: FontWeight.w800, color: Colors.white)),
            if (line.isNotEmpty) Text(line, style: AmbLook.t(12, color: AmbLook.sandDim)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
          child: Text(r.statusText ?? fallback, style: AmbLook.t(12, w: FontWeight.w800, color: fg)),
        ),
      ]),
    );
  }

  Widget _buyBlock(AmbassadorState s) {
    final g = s.gold;
    final note = g.short
        ? 'ينخصم من محفظتك. محفظتك فيها ${moneyAmount(g.walletLyd)}، تحتاج تشحن ${moneyAmount(g.shortLyd)} الأول.'
        : 'ينخصم ${moneyAmount(g.priceLyd)} د.ل من محفظتك. محفظتك فيها ${moneyAmount(g.walletLyd)} د.ل.';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            key: const ValueKey('amb-gold-wallet'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AmbLook.nightCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AmbLook.nightLine)),
            child: Text(note, style: AmbLook.t(12.5, color: AmbLook.sand, h: 1.6)),
          ),
          const SizedBox(height: 10),
          g.short
              ? Button(
                  key: const ValueKey('amb-gold-topup'),
                  // the wallet page is a page of its own: no spinner behind it
                  onTap: () => unawaited(_topUp()),
                  text: 'اشحن واشترك في الذهبي',
                  backgroundcolor: AmbLook.gold,
                  textcolor: AmbLook.night,
                  width: double.infinity,
                )
              : Button(
                  key: const ValueKey('amb-gold-subscribe'),
                  onTap: () => unawaited(_subscribe(s)),
                  text: 'اشترك في الذهبي',
                  backgroundcolor: AmbLook.gold,
                  textcolor: AmbLook.night,
                  width: double.infinity,
                ),
        ]),
      ),
    );
  }
}
