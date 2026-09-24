part of '../bookingwidgets.dart';

const _scheduleAccent = Color(0xff0873FF);
const _scheduleNavy = Color(0xff102A56);
const _scheduleMuted = Color(0xff7B8BA8);
const _scheduleBorder = Color(0xffE6ECF6);

/// Scheduling a ride is a distinct decision from booking one now, so this
/// sheet is deliberately its own two-step flow rather than a single wheel
/// picker: step 1 picks a date/time (with quick actions for the common
/// cases so the raw picker is only ever a secondary, tap-to-open surface),
/// step 2 is a plain-language summary the rider confirms. Both steps stay
/// inside the same bottom sheet - no new route, no new page - and the only
/// state this ever writes back is the same `choosenDateTime`/
/// `confirmRideLater` pair the rest of the booking flow already reads, so
/// nothing downstream of this sheet needs to change.
class RideLaterBottomSheet extends StatefulWidget {
  final dynamic type;
  const RideLaterBottomSheet({super.key, this.type});

  @override
  State<RideLaterBottomSheet> createState() => _RideLaterBottomSheetState();
}

class _RideLaterBottomSheetState extends State<RideLaterBottomSheet> {
  late DateTime selectedDateTime;
  bool showSummary = false;

  bool get isRtl => languageDirection == 'rtl';

  int get _minMinutes =>
      int.tryParse(
          (userDetails['user_can_make_a_ride_after_x_miniutes'] ?? '30')
              .toString()) ??
      30;

  DateTime get _minDateTime => DateTime.now().add(Duration(minutes: _minMinutes));
  DateTime get _maxDateTime => DateTime.now().add(const Duration(days: 4));

  @override
  void initState() {
    super.initState();
    final initial = (choosenDateTime is DateTime) ? choosenDateTime : _minDateTime;
    selectedDateTime = initial.isBefore(_minDateTime) ? _minDateTime : initial;
  }

  void _clampAndSet(DateTime value) {
    setState(() {
      if (value.isBefore(_minDateTime)) {
        selectedDateTime = _minDateTime;
      } else if (value.isAfter(_maxDateTime)) {
        selectedDateTime = _maxDateTime;
      } else {
        selectedDateTime = value;
      }
    });
  }

  void _quickInHour() => _clampAndSet(DateTime.now().add(const Duration(hours: 1)));
  void _quickInTwoHours() => _clampAndSet(DateTime.now().add(const Duration(hours: 2)));
  void _quickTomorrowMorning() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _clampAndSet(DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0));
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _InlineWheelPickerSheet(
        mode: CupertinoDatePickerMode.date,
        initial: selectedDateTime,
        minimum: _minDateTime,
        maximum: _maxDateTime,
        isRtl: isRtl,
        title: languages[choosenLanguage]['text_choose_date'],
      ),
    );
    if (picked == null) return;
    _clampAndSet(DateTime(picked.year, picked.month, picked.day,
        selectedDateTime.hour, selectedDateTime.minute));
  }

  Future<void> _pickTime() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _InlineWheelPickerSheet(
        mode: CupertinoDatePickerMode.time,
        initial: selectedDateTime,
        minimum: _minDateTime,
        maximum: _maxDateTime,
        isRtl: isRtl,
        title: languages[choosenLanguage]['text_departure_time'] ??
            (isRtl ? 'وقت الانطلاق' : 'Departure time'),
      ),
    );
    if (picked == null) return;
    _clampAndSet(DateTime(selectedDateTime.year, selectedDateTime.month,
        selectedDateTime.day, picked.hour, picked.minute));
  }

  void _goToSummary() => setState(() => showSummary = true);
  void _backToPicker() => setState(() => showSummary = false);

  void _switchToNow() {
    confirmRideLater = false;
    Navigator.pop(context);
    valueNotifierBook.incrementNotifier();
  }

  void _finalizeSchedule() {
    setState(() {
      choosenDateTime = selectedDateTime;
      confirmRideLater = true;
    });
    Navigator.pop(context);
    valueNotifierBook.incrementNotifier();
  }

  String? get _pickupAddress {
    try {
      return addressList.firstWhere((a) => a.pickup == true).address;
    } catch (_) {
      return null;
    }
  }

  String? get _dropAddress {
    try {
      return addressList.firstWhere((a) => a.id == 'drop').address;
    } catch (_) {
      return null;
    }
  }

  num? get _estimatedFare {
    try {
      final eta = etaDetails[choosenVehicle];
      return scheduledQuotedFare(eta);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          width: media.width,
          constraints: BoxConstraints(maxHeight: media.height * 0.85),
          decoration: BoxDecoration(
            color: page,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(media.width * 0.06),
              topRight: Radius.circular(media.width * 0.06),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  media.width * 0.05, media.width * 0.03, media.width * 0.05,
                  media.width * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: EdgeInsets.only(bottom: media.width * 0.04),
                      decoration: BoxDecoration(
                        color: borderLines,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  showSummary ? _buildSummary(media) : _buildPicker(media),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPicker(Size media) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyText(
          text: languages[choosenLanguage]['text_when_for_ride'] ??
              (isRtl ? 'متى تريد الرحلة؟' : 'When do you want to ride?'),
          size: media.width * eighteen,
          fontweight: FontWeight.w700,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: media.width * 0.05),
        _ModeSelector(isRtl: isRtl, onNowTap: _switchToNow),
        SizedBox(height: media.width * 0.06),
        _SectionLabel(text: languages[choosenLanguage]['text_choose_date']),
        SizedBox(height: media.width * 0.02),
        _TapCard(
          icon: Icons.calendar_today_rounded,
          text: scheduleDateLabel(selectedDateTime, isRtl: isRtl),
          onTap: _pickDate,
        ),
        SizedBox(height: media.width * 0.04),
        _SectionLabel(
            text: languages[choosenLanguage]['text_departure_time'] ??
                (isRtl ? 'وقت الانطلاق' : 'Departure time')),
        SizedBox(height: media.width * 0.02),
        _TapCard(
          icon: Icons.access_time_rounded,
          text: scheduleTimeLabel(selectedDateTime, isRtl: isRtl),
          onTap: _pickTime,
        ),
        SizedBox(height: media.width * 0.045),
        Wrap(
          spacing: media.width * 0.02,
          runSpacing: media.width * 0.02,
          children: [
            _QuickChip(
                text: languages[choosenLanguage]['text_quick_in_hour'] ??
                    (isRtl ? 'بعد ساعة' : 'In an hour'),
                onTap: _quickInHour),
            _QuickChip(
                text: languages[choosenLanguage]['text_quick_in_two_hours'] ??
                    (isRtl ? 'بعد ساعتين' : 'In 2 hours'),
                onTap: _quickInTwoHours),
            _QuickChip(
                text: languages[choosenLanguage]
                        ['text_quick_tomorrow_morning'] ??
                    (isRtl ? 'غدًا صباحًا' : 'Tomorrow morning'),
                onTap: _quickTomorrowMorning),
          ],
        ),
        SizedBox(height: media.width * 0.06),
        Button(
          onTap: _goToSummary,
          text: languages[choosenLanguage]['text_continue'] ??
              (isRtl ? 'متابعة' : 'Continue'),
        ),
      ],
    );
  }

  Widget _buildSummary(Size media) {
    final pickup = _pickupAddress;
    final drop = _dropAddress;
    final fare = _estimatedFare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InkWell(
              onTap: _backToPicker,
              child: Icon(
                isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                size: media.width * 0.045,
                color: textColor,
              ),
            ),
            Expanded(
              child: MyText(
                text: languages[choosenLanguage]['text_scheduled_ride'] ??
                    (isRtl ? 'رحلة مجدولة' : 'Scheduled ride'),
                size: media.width * eighteen,
                fontweight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: media.width * 0.045),
          ],
        ),
        SizedBox(height: media.width * 0.05),
        Container(
          padding: EdgeInsets.all(media.width * 0.04),
          decoration: BoxDecoration(
            color: _scheduleAccent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _scheduleAccent.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 14)),
                  SizedBox(width: media.width * 0.02),
                  MyText(
                    text: languages[choosenLanguage]['text_scheduled_ride'] ??
                        (isRtl ? 'رحلة مجدولة' : 'Scheduled ride'),
                    size: media.width * twelve,
                    fontweight: FontWeight.w700,
                    color: _scheduleAccent,
                  ),
                ],
              ),
              SizedBox(height: media.width * 0.025),
              MyText(
                text: scheduleDateLabel(selectedDateTime, isRtl: isRtl),
                size: media.width * sixteen,
                fontweight: FontWeight.w700,
                color: _scheduleNavy,
              ),
              MyText(
                text: scheduleTimeLabel(selectedDateTime, isRtl: isRtl),
                size: media.width * twentyfour,
                fontweight: FontWeight.w900,
                color: _scheduleNavy,
              ),
              if (pickup != null || drop != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
                  child: const MySeparator(),
                ),
                if (pickup != null)
                  _RoutePoint(color: Colors.green, text: pickup),
                if (pickup != null && drop != null)
                  Padding(
                    padding: EdgeInsets.only(
                        left: media.width * 0.01, top: 2, bottom: 2),
                    child: Icon(Icons.more_vert,
                        size: media.width * 0.04, color: _scheduleMuted),
                  ),
                if (drop != null)
                  _RoutePoint(color: const Color(0xFFFF0000), text: drop),
              ],
              if (fare != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
                  child: const MySeparator(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: languages[choosenLanguage]
                              ['text_estimated_fare'] ??
                          (isRtl ? 'السعر التقديري' : 'Estimated fare'),
                      size: media.width * twelve,
                      color: _scheduleMuted,
                    ),
                    MyText(
                      text: fare.toString(),
                      size: media.width * sixteen,
                      fontweight: FontWeight.w800,
                      color: _scheduleNavy,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: media.width * 0.06),
        Button(
          onTap: _finalizeSchedule,
          text: languages[choosenLanguage]['text_schedule_ride'] ??
              (isRtl ? 'جدولة الرحلة' : 'Schedule ride'),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.isRtl, required this.onNowTap});

  final bool isRtl;
  final VoidCallback onNowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: topBar,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: onNowTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                child: MyText(
                  text: languages[choosenLanguage]['text_ride_now'] ??
                      (isRtl ? 'الآن' : 'Now'),
                  size: 14,
                  fontweight: FontWeight.w600,
                  color: hintColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: page,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: MyText(
                text: languages[choosenLanguage]['text_ride_schedule'] ??
                    (isRtl ? 'جدولة' : 'Schedule'),
                size: 14,
                fontweight: FontWeight.w700,
                color: _scheduleAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return MyText(
      text: text,
      size: 13,
      fontweight: FontWeight.w600,
      color: hintColor,
    );
  }
}

class _TapCard extends StatelessWidget {
  const _TapCard({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: topBar,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _scheduleBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _scheduleAccent),
            const SizedBox(width: 10),
            Expanded(
              child: MyText(
                text: text,
                size: 15,
                fontweight: FontWeight.w700,
                color: _scheduleNavy,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _scheduleAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: MyText(
          text: text,
          size: 12.5,
          fontweight: FontWeight.w700,
          color: _scheduleAccent,
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MyText(
              text: text,
              maxLines: 2,
              size: 13,
              fontweight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The raw CupertinoDatePicker wheel - present, but deliberately only ever
/// reachable as a secondary surface (tap the date/time card to open it),
/// never the sheet's own main visual.
class _InlineWheelPickerSheet extends StatefulWidget {
  const _InlineWheelPickerSheet({
    required this.mode,
    required this.initial,
    required this.minimum,
    required this.maximum,
    required this.isRtl,
    required this.title,
  });

  final CupertinoDatePickerMode mode;
  final DateTime initial;
  final DateTime minimum;
  final DateTime maximum;
  final bool isRtl;
  final String? title;

  @override
  State<_InlineWheelPickerSheet> createState() => _InlineWheelPickerSheetState();
}

class _InlineWheelPickerSheetState extends State<_InlineWheelPickerSheet> {
  late DateTime value;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Directionality(
      textDirection: widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            media.width * 0.05, media.width * 0.04, media.width * 0.05,
            media.width * 0.05),
        decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(media.width * 0.06),
            topRight: Radius.circular(media.width * 0.06),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null) ...[
                MyText(
                  text: widget.title,
                  size: 16,
                  fontweight: FontWeight.w700,
                ),
                SizedBox(height: media.width * 0.03),
              ],
              SizedBox(
                height: media.width * 0.5,
                child: CupertinoDatePicker(
                  mode: widget.mode,
                  minimumDate: widget.minimum,
                  initialDateTime: value,
                  maximumDate: widget.maximum,
                  onDateTimeChanged: (val) => setState(() => value = val),
                ),
              ),
              SizedBox(height: media.width * 0.03),
              Button(
                onTap: () => Navigator.pop(context, value),
                text: languages[choosenLanguage]['text_done'] ??
                    (widget.isRtl ? 'تم' : 'Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
