import 'package:flutter/material.dart';

import '../../../functions/functions.dart';
import '../../../styles/styles.dart';
import '../../../widgets/widgets.dart';

class TripDetailsSheet extends StatelessWidget {
  const TripDetailsSheet({
    super.key,
    required this.addresses,
    required this.copy,
    required this.isRtl,
    required this.canAddStop,
    required this.onAddStop,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
    required this.onConfirm,
  });

  final List<AddressList> addresses;
  final Map copy;
  final bool isRtl;
  final bool canAddStop;
  final VoidCallback onAddStop;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final ReorderCallback onReorder;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final destinations = addresses.skip(1).toList(growable: false);

    return Positioned.fill(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: media.height * 0.68),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: page,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  color: Colors.black.withValues(alpha: 0.14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hintColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${copy['text_confirm_details']}',
                  style: TextStyle(
                    fontSize: media.width * sixteen,
                    color: buttonColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRtl
                      ? 'راجع نقطة لقاء السائق والوجهة قبل طلب الرحلة.'
                      : 'Review the driver meeting point and destination before booking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: media.width * twelve,
                    color: textColor.withValues(alpha: 0.58),
                  ),
                ),
                if (canAddStop) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onAddStop,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text('${copy['text_add_stop']}'),
                  ),
                ],
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (addresses.isNotEmpty) ...[
                          _SectionLabel(text: '${copy['text_start_trip']}'),
                          const SizedBox(height: 6),
                          _LocationTile(
                            address: addresses.first.address,
                            color: const Color(0xFF16A36A),
                            backgroundColor: const Color(0xFFF2FBF7),
                            onTap: () => onEdit(0),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _SectionLabel(text: '${copy['text_end_trip']}'),
                        const SizedBox(height: 6),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: destinations.length,
                          onReorderItem: onReorder,
                          itemBuilder: (context, index) {
                            final address = destinations[index];
                            final realIndex = index + 1;
                            return Padding(
                              key: ValueKey(address.id),
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _LocationTile(
                                      address: address.address,
                                      color: buttonColor,
                                      backgroundColor: const Color(0xFFF3F8FF),
                                      onTap: () => onEdit(realIndex),
                                    ),
                                  ),
                                  if (destinations.length > 1) ...[
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.drag_indicator_rounded,
                                          color: hintColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => onDelete(realIndex),
                                      color: Colors.redAccent,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Button(onTap: onConfirm, text: copy['text_confirm']),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MyText(
      text: text,
      size: MediaQuery.sizeOf(context).width * twelve,
      fontweight: FontWeight.w600,
      color: textColor,
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.address,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final String address;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
