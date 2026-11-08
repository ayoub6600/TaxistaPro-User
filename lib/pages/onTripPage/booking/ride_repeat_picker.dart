part of '../bookingwidgets.dart';

const _repeatDays = {6: 'س', 0: 'ح', 1: 'ن', 2: 'ث', 3: 'ر', 4: 'خ', 5: 'ج'};

/// «تكرر المشوار؟» on the scheduling summary; one line unless the rider wants it.
class _RideRepeatPicker extends StatefulWidget {
  const _RideRepeatPicker();

  @override
  State<_RideRepeatPicker> createState() => _RideRepeatPickerState();
}

class _RideRepeatPickerState extends State<_RideRepeatPicker> {
  static const _choices = {null: 'مرة واحدة', 'workdays': 'أيام العمل', 'daily': 'كل يوم', 'custom': 'أختار أيام'};

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 6, bottom: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: on ? _scheduleAccent : page, borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? _scheduleAccent : _scheduleBorder)),
            child: MyText(text: label, size: 13, fontweight: FontWeight.w700, color: on ? Colors.white : _scheduleNavy),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: RepeatChoice.available,
      builder: (_, available, __) {
        if (!available) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MyText(text: 'تكرر المشوار؟', size: 15, fontweight: FontWeight.w800, color: _scheduleNavy),
            const SizedBox(height: 8),
            Wrap(children: [
              for (final c in _choices.entries)
                _chip(c.value, RepeatChoice.preset == c.key, () => setState(() => RepeatChoice.preset = c.key)),
            ]),
            if (RepeatChoice.preset == 'custom')
              Wrap(children: [
                for (final d in _repeatDays.entries)
                  _chip(d.value, RepeatChoice.days.contains(d.key), () => setState(() => RepeatChoice.days.contains(d.key) ? RepeatChoice.days.remove(d.key) : RepeatChoice.days.add(d.key))),
              ]),
          ]),
        );
      },
    );
  }
}
