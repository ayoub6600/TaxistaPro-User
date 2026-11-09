part of '../bookingwidgets.dart';

const _repeatLetters = {6: 'س', 0: 'ح', 1: 'ن', 2: 'ث', 3: 'ر', 4: 'خ', 5: 'ج'};
const _repeatMuted = Color(0xff55678A);
const _repeatSoft = Color(0xffEEF1F6);

/// «كرر هذا المشوار» on the scheduling summary: one line until the rider switches it on.
class _RideRepeatPicker extends StatefulWidget {
  const _RideRepeatPicker({required this.at, required this.onChanged});

  final DateTime at;
  final VoidCallback onChanged;

  @override
  State<_RideRepeatPicker> createState() => _RideRepeatPickerState();
}

class _RideRepeatPickerState extends State<_RideRepeatPicker> {
  static const _presets = {'workdays': 'أيام العمل', 'daily': 'كل يوم', 'custom': 'أختار أيام'};

  void _set(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  Widget _toggle(bool on) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _set(() => RepeatChoice.preset = on ? null : 'workdays'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: on ? const Color(0xffEEF5FF) : const Color(0xffF7F9FD), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.repeat_rounded, color: on ? _scheduleAccent : _repeatMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MyText(text: 'كرر هذا المشوار', size: 15.5, fontweight: FontWeight.w800, color: _scheduleNavy),
                MyText(text: on ? 'نحجزه لك في الأيام اللي تختارها' : 'مشوار تعمله كل يوم أو كل أسبوع؟', size: 12.5, color: _repeatMuted),
              ]),
            ),
            IgnorePointer(child: Switch.adaptive(value: on, activeTrackColor: _scheduleAccent, onChanged: (_) {})),
          ]),
        ),
      );

  Widget _presetRow() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: _repeatSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final p in _presets.entries)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => _set(() {
                  if (p.key == 'custom' && RepeatChoice.preset != 'custom') RepeatChoice.days = {...RepeatChoice.selected};
                  RepeatChoice.preset = p.key;
                }),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: RepeatChoice.preset == p.key ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                  child: MyText(text: p.value, size: 13.5, fontweight: FontWeight.w800, color: RepeatChoice.preset == p.key ? _scheduleAccent : _repeatMuted),
                ),
              ),
            ),
        ]),
      );

  Widget _dayRow() {
    final selected = RepeatChoice.selected;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (final d in RepeatChoice.week)
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _set(() => RepeatChoice.toggleDay(d)),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected.contains(d) ? _scheduleAccent : Colors.white,
              border: selected.contains(d) ? null : Border.all(color: const Color(0xffDBE3EF), width: 1.5),
            ),
            child: MyText(text: _repeatLetters[d]!, size: 15, fontweight: FontWeight.w800, color: selected.contains(d) ? Colors.white : _repeatMuted),
          ),
        ),
    ]);
  }

  Widget _summary() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xffF7F9FD), borderRadius: BorderRadius.circular(16)),
        child: RepeatChoice.selected.isEmpty
            ? const MyText(text: 'اختر يومًا واحدًا على الأقل', size: 13.5, fontweight: FontWeight.w800, color: Color(0xffB91C1C))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MyText(text: '${RepeatChoice.daysLine}، الساعة ${RepeatChoice.clock(widget.at)}', size: 14, fontweight: FontWeight.w800, color: _scheduleNavy),
                const SizedBox(height: 2),
                const MyText(text: 'السعر يتحدد لكل يوم. لو زاد كثير، نسألك قبل الحجز.', size: 12.5, color: _repeatMuted),
              ]),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: RepeatChoice.available,
      builder: (_, available, __) {
        if (!available) return const SizedBox.shrink();
        final on = RepeatChoice.preset != null;
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _toggle(on),
            if (on) ...[
              const SizedBox(height: 10),
              _presetRow(),
              const SizedBox(height: 10),
              _dayRow(),
              const SizedBox(height: 10),
              _summary(),
            ],
          ]),
        );
      },
    );
  }
}
