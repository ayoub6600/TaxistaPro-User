import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../styles/styles.dart';
import '../../../widgets/widgets.dart';

class RideDatePickerOverlay extends StatelessWidget {
  const RideDatePickerOverlay({
    super.key,
    required this.minimumDate,
    required this.maximumDate,
    required this.confirmText,
    required this.onChanged,
    required this.onClose,
    required this.onConfirm,
  });

  final DateTime minimumDate;
  final DateTime maximumDate;
  final String confirmText;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(media.width * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filled(
                    onPressed: onClose,
                    style: IconButton.styleFrom(
                      backgroundColor: page,
                      foregroundColor: textColor,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: topBar,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SizedBox(
                      height: media.width * 0.5,
                      width: double.infinity,
                      child: CupertinoDatePicker(
                        minimumDate: minimumDate,
                        initialDateTime: minimumDate,
                        maximumDate: maximumDate,
                        onDateTimeChanged: onChanged,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(media.width * 0.05),
                    child: Button(onTap: onConfirm, text: confirmText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RideScheduleSheet extends StatelessWidget {
  const RideScheduleSheet({
    super.key,
    required this.height,
    required this.isOneWay,
    required this.isSelectingOutbound,
    required this.outboundDate,
    required this.returnDate,
    required this.minimumOutboundDate,
    required this.copy,
    required this.onDismiss,
    required this.onSelectOutbound,
    required this.onSelectReturn,
    required this.onOutboundChanged,
    required this.onReturnChanged,
    required this.onContinue,
  });

  final double height;
  final bool isOneWay;
  final bool isSelectingOutbound;
  final DateTime outboundDate;
  final DateTime? returnDate;
  final DateTime minimumOutboundDate;
  final Map copy;
  final VoidCallback onDismiss;
  final VoidCallback onSelectOutbound;
  final VoidCallback onSelectReturn;
  final ValueChanged<DateTime> onOutboundChanged;
  final ValueChanged<DateTime> onReturnChanged;
  final VoidCallback onContinue;

  String _format(DateTime value) => DateFormat('d MMM, h:mm a').format(value);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final title = isOneWay
        ? copy['text_schedule_trip']
        : copy['text_schedule_round_trip'];
    final dateSummary = isOneWay
        ? '${copy['text_starting']} ${_format(outboundDate)}'
        : '${copy['text_starting']} ${_format(outboundDate)} '
            'to ${returnDate == null ? copy['text_select'] : _format(returnDate!)}';

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.3),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: height,
                constraints: BoxConstraints(maxHeight: media.height * 0.55),
                padding: EdgeInsets.fromLTRB(
                  media.width * 0.05,
                  16,
                  media.width * 0.05,
                  media.width * 0.04,
                ),
                decoration: BoxDecoration(
                  color: page,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: hintColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MyText(text: '$title', size: media.width * eighteen),
                      const SizedBox(height: 8),
                      MyText(
                        text: dateSummary,
                        size: media.width * fourteen,
                        color: hintColor,
                      ),
                      if (!isOneWay) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _DateTab(
                              text: '${copy['text_leave_on']}',
                              selected: isSelectingOutbound,
                              onTap: onSelectOutbound,
                            ),
                            const SizedBox(width: 12),
                            _DateTab(
                              text: '${copy['text_return_by']}',
                              selected: !isSelectingOutbound,
                              onTap: onSelectReturn,
                            ),
                          ],
                        ),
                      ],
                      SizedBox(
                        height: media.width * 0.5,
                        child: CupertinoDatePicker(
                          minimumDate: isSelectingOutbound
                              ? minimumOutboundDate
                              : outboundDate.add(
                                  const Duration(days: 1, minutes: 10),
                                ),
                          initialDateTime: isSelectingOutbound
                              ? outboundDate
                              : returnDate ??
                                  outboundDate.add(
                                    const Duration(days: 1, minutes: 10),
                                  ),
                          maximumDate: isSelectingOutbound
                              ? DateTime.now().add(const Duration(days: 4))
                              : outboundDate.add(const Duration(days: 7)),
                          onDateTimeChanged: isSelectingOutbound
                              ? onOutboundChanged
                              : onReturnChanged,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(media.width * 0.03),
                        child: Button(
                          onTap: onContinue,
                          text: isSelectingOutbound
                              ? copy['text_next']
                              : copy['text_confirm'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTab extends StatelessWidget {
  const _DateTab({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: MyText(
          text: text,
          size: MediaQuery.sizeOf(context).width * fourteen,
          color: selected ? textColor : hintColor,
        ),
      ),
    );
  }
}
