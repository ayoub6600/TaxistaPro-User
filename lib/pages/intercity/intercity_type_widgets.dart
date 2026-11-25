import 'package:flutter/material.dart';

import '../../functions/tr.dart';
import 'intercity_style.dart';

// «كيف تحب تسافر؟» as the approved design drew it: clearer edges, darker inks for the small text
const _edge = Color(0xffD5DEEC);
const _picked = Color(0xffF2F7FF);
const _blueInk = Color(0xff0A55C4);
const _brown = Color(0xff8A4B00);
const _cream = Color(0xffFFF1CF);
const _float = [BoxShadow(color: Color(0x29102A56), blurRadius: 16, offset: Offset(0, 6))];

/// «لـزليتن»، and «للخمس» for a name that starts with «ال»
String icToCity(String city) => city.startsWith('ال') ? 'لل${city.substring(2)}' : 'لـ$city';

/// The page shape of «كيف تحب تسافر؟»: the sheet is only as tall as what it holds (it ends at its
/// button; a short phone scrolls it) and the map takes all the rest.
class IcTypeScaffold extends StatelessWidget {
  const IcTypeScaffold({super.key, required this.title, this.note, required this.map, required this.children, required this.bottom});

  final String title;

  /// the drive, after the title: «≈ 50 دقيقة»
  final String? note;
  final Widget map;
  final List<Widget> children;

  /// stays under the scrolling part: the hint and the button
  final Widget bottom;

  /// the top bar's share of the map, under the status bar
  static const barHeight = 62.0;

  /// the map runs this far under the sheet's round corners
  static const overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // the map keeps a strip of its own however much the sheet holds
    final room = mq.size.height - mq.padding.top - 150;
    return Directionality(
      textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffE6EEF6),
        body: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Stack(clipBehavior: Clip.none, children: [Positioned(top: 0, left: 0, right: 0, bottom: -overlap, child: map)]),
            ),
            ConstrainedBox(constraints: BoxConstraints(maxHeight: room < 300 ? 300 : room), child: _sheet()),
          ]),
          Positioned(top: mq.padding.top + 8, left: 16, right: 16, child: _bar(context)),
        ]),
      ),
    );
  }

  Widget _bar(BuildContext context) => Row(children: [
        Semantics(
          button: true,
          label: tr('رجوع', 'Return'),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: _float),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: const SizedBox(width: 46, height: 46, child: Icon(Icons.arrow_back_rounded, size: 22, color: IcStyle.navy)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), boxShadow: _float),
            // two long names: the line gets a little smaller, the city is never cut
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 1, style: IcStyle.t(15, w: FontWeight.w900)),
                if (note != null) ...[
                  Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 8), color: _edge),
                  const Icon(Icons.schedule_rounded, size: 15, color: IcStyle.blue),
                  const SizedBox(width: 6),
                  Text(note!, maxLines: 1, style: IcStyle.t(13, w: FontWeight.w800, c: _blueInk)),
                ],
              ]),
            ),
          ),
        ),
      ]);

  Widget _sheet() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Color(0x1F102A56), blurRadius: 30, offset: Offset(0, -10))],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 10),
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: _edge, borderRadius: BorderRadius.circular(3)))),
            Flexible(
              child: Stack(children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 11, 18, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
                // more below on a short phone: it fades out, it is not chopped
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 12,
                  child: IgnorePointer(
                    child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00FFFFFF), Colors.white]))),
                  ),
                ),
              ]),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: bottom),
          ]),
        ),
      );
}

/// a city to travel to, with the drive under its name
class IcDestCard extends StatelessWidget {
  const IcDestCard({super.key, required this.city, required this.selected, required this.onTap, this.time});

  final String city;
  final bool selected;
  final VoidCallback onTap;

  /// «≈ 50 د»
  final String? time;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? IcStyle.blue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? IcStyle.blue : _edge, width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(city, maxLines: 1, style: IcStyle.t(15.5, w: FontWeight.w900, c: selected ? Colors.white : IcStyle.navy, h: 1.3))),
              if (time != null)
                FittedBox(fit: BoxFit.scaleDown, child: Text(time!, maxLines: 1, style: IcStyle.t(11.5, c: selected ? Colors.white : IcStyle.muted, h: 1.3))),
            ]),
          ),
        ),
      );
}

/// a way to travel, «سيارة كاملة» or «كرسي في رحلة»: its price from, and what it gives under it
class IcTravelOption extends StatelessWidget {
  const IcTravelOption({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.price,
    this.tags = const [],
    this.warm = false,
    this.compact = false,
    this.child,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final num? price;
  final List<String> tags;

  /// the seat's warm colours in place of the car's blue
  final bool warm;

  /// one short row: the other choice has something to say
  final bool compact;

  /// under the row in place of the tags («ما فيش رحلة توّا»)
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ink = warm ? _brown : _blueInk;
    final tile = compact ? 42.0 : 50.0;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 10 : 12),
          decoration: BoxDecoration(
            color: selected ? _picked : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? IcStyle.blue : _edge, width: selected ? 2 : 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: tile,
                height: tile,
                decoration: BoxDecoration(color: warm ? _cream : IcStyle.blue, borderRadius: BorderRadius.circular(tile * .3)),
                child: Icon(icon, size: tile * .52, color: warm ? _brown : Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: compact
                    ? Text(title, style: IcStyle.t(16, w: FontWeight.w900))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: IcStyle.t(17, w: FontWeight.w900, h: 1.35)),
                        _Snug(subtitle, style: IcStyle.t(12.5, c: IcStyle.muted, h: 1.4)),
                      ]),
              ),
              if (price != null) ...[
                const SizedBox(width: 12),
                compact
                    ? Text('${tr('من', 'from')} ${IcStyle.lyd(price!)}', style: IcStyle.t(14, w: FontWeight.w800, c: ink))
                    : _From(price: price!, ink: ink),
              ],
              const SizedBox(width: 12),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? IcStyle.blue : const Color(0xff8C9BB4), width: selected ? 7 : 2),
                ),
              ),
            ]),
            if (child != null) ...[
              const SizedBox(height: 10),
              child!,
            ] else if (tags.isNotEmpty && !compact) ...[
              const SizedBox(height: 9),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final s in tags) _Tag(s, warm: warm)]),
            ],
          ]),
        ),
      ),
    );
  }
}

/// a line that stays one line when a slightly smaller size is enough (a three-digit price beside it),
/// and wraps as usual on a narrow phone
class _Snug extends StatelessWidget {
  const _Snug(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final scaler = MediaQuery.textScalerOf(context);
        final line = TextPainter(text: TextSpan(text: text, style: style), textDirection: Directionality.of(context), textScaler: scaler, maxLines: 1)..layout();
        final k = c.maxWidth / line.width;
        line.dispose();
        return Text(text, style: k < 1 && k >= .9 ? style.copyWith(fontSize: style.fontSize! * k * .99) : style);
      });
}

/// «من / 80 / د.ل»: the number big, the words small around it
class _From extends StatelessWidget {
  const _From({required this.price, required this.ink});

  final num price;
  final Color ink;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${tr('من', 'from')} ${IcStyle.lyd(price)}',
        child: ExcludeSemantics(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr('من', 'from'), style: IcStyle.t(11, c: IcStyle.muted, h: 1.15)),
            Text(IcStyle.money(price), style: IcStyle.t(24, w: FontWeight.w900, c: ink, h: 1.15)),
            Text(tr('د.ل', 'LYD'), style: IcStyle.t(11, w: FontWeight.w800, c: IcStyle.muted, h: 1.15)),
          ]),
        ),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.warm});

  final String text;
  final bool warm;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: warm ? _cream : const Color(0xffE3EEFF), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: IcStyle.t(11.5, w: FontWeight.w800, c: warm ? const Color(0xff7A4300) : const Color(0xff0A4BAE), h: 1.8)),
      );
}

/// the steps in one line above the button: «تحدد سعرك ← الكباتن يبعثوا عروضهم ← تختار الكابتن»
class IcSteps extends StatelessWidget {
  const IcSteps(this.steps, {super.key});

  final List<String> steps;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < steps.length; i++) ...[
              // it points the way the line is read
              if (i > 0) const Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: Icon(Icons.arrow_forward_rounded, size: 14, color: IcStyle.muted)),
              Text(steps[i], style: IcStyle.t(12, c: IcStyle.muted)),
            ],
          ]),
        ),
      );
}

/// inside «كرسي في رحلة» when no captain has a trip to the city now
class IcNoTripNotice extends StatelessWidget {
  const IcNoTripNotice({super.key, required this.city});

  final String city;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('ic-no-trip'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _edge)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: _brown),
            const SizedBox(width: 8),
            Expanded(child: Text(tr('ما فيش رحلة ${icToCity(city)} توّا', 'No trip to $city right now'), style: IcStyle.t(13.5, w: FontWeight.w800))),
          ]),
          const SizedBox(height: 6),
          Text(
            tr('الكباتن ينزّلوا رحلاتهم بمواعيدها، وأول ما تنزل رحلة تلقاها هنا.', 'Captains post their trips with set times. A new trip shows here as soon as it is posted.'),
            style: IcStyle.t(12.5, c: IcStyle.muted, h: 1.5),
          ),
        ]),
      );
}
