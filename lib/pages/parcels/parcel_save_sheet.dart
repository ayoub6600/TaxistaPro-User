import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart' show IcPlace;
import '../../functions/parcel_saved.dart';
import '../../functions/tr.dart';
import '../intercity/intercity_style.dart';

/// After a booking that went through: «نحفظ المستلم للمرات الجاية؟» and «نحفظ مكان الاستلام؟»
/// (owner 2026-11-19), only for what is not saved yet. Nothing is saved unless he taps «احفظ».
class ParcelSaveSheet extends StatefulWidget {
  const ParcelSaveSheet({super.key, this.name, this.phone, this.pick});

  /// null: already saved, not asked
  final String? name;
  final String? phone;
  final IcPlace? pick;

  static final labels = [tr('البيت', 'Home'), tr('المحل', 'Shop'), tr('الشغل', 'Work')];

  /// asks only when something is new; returns once he answered (or there was nothing to ask)
  static Future<void> maybeShow(BuildContext context, {required String name, required String phone, required IcPlace pick}) async {
    final newReceiver = !await ParcelSaved.hasReceiver(name, phone);
    final newPlace = !await ParcelSaved.hasPlace(pick);
    if ((!newReceiver && !newPlace) || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Directionality(
          textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ParcelSaveSheet(name: newReceiver ? name : null, phone: newReceiver ? phone : null, pick: newPlace ? pick : null),
        ),
      ),
    );
  }

  @override
  State<ParcelSaveSheet> createState() => _ParcelSaveSheetState();
}

class _ParcelSaveSheetState extends State<ParcelSaveSheet> {
  late bool _receiver = widget.name != null;
  String? _label;
  bool _own = false;
  final _ownLabel = TextEditingController();

  @override
  void dispose() {
    _ownLabel.dispose();
    super.dispose();
  }

  String? get _placeLabel => _own ? (_ownLabel.text.trim().isEmpty ? null : _ownLabel.text.trim()) : _label;

  Future<void> _save() async {
    if (_receiver && widget.name != null) await ParcelSaved.saveReceiver(widget.name!, widget.phone!);
    final l = _placeLabel;
    if (widget.pick != null && l != null) await ParcelSaved.savePlace(l, widget.pick!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => IcSheet(children: [
        Text(tr('نحفظوا للمرات الجاية؟', 'Save for next time?'), textAlign: TextAlign.center, style: IcStyle.t(19, w: FontWeight.w900)),
        const SizedBox(height: 10),
        if (widget.name != null) ...[
          Text(tr('نحفظ المستلم للمرات الجاية؟', 'Save the receiver for next time?'), style: IcStyle.t(14.5, w: FontWeight.w900)),
          InkWell(
            key: const ValueKey('parcel-save-receiver'),
            onTap: () => setState(() => _receiver = !_receiver),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Icon(_receiver ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: IcStyle.blue),
                const SizedBox(width: 8),
                Expanded(child: Text('👤 ${widget.name} · \u2066${widget.phone}\u2069', style: IcStyle.t(14, w: FontWeight.w800))),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.pick != null) ...[
          Text(tr('نحفظ مكان الاستلام؟', 'Save the pickup place?'), style: IcStyle.t(14.5, w: FontWeight.w900)),
          if (widget.pick!.address.isNotEmpty)
            Text(widget.pick!.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final l in ParcelSaveSheet.labels)
              IcChip(
                  key: ValueKey('parcel-save-label-$l'),
                  text: l,
                  selected: !_own && _label == l,
                  onTap: () => setState(() {
                        _own = false;
                        _label = _label == l ? null : l;
                      })),
            IcChip(text: tr('اسم ثاني', 'Another name'), selected: _own, onTap: () => setState(() => _own = !_own)),
          ]),
          if (_own) ...[
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('parcel-save-own'),
              controller: _ownLabel,
              maxLength: 24,
              onChanged: (_) => setState(() {}),
              style: IcStyle.t(14, w: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: tr('مثلًا: بيت الوالدة', 'e.g. Mum\'s house'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        IcButton(
            key: const ValueKey('parcel-save'),
            text: tr('احفظ', 'Save'),
            onTap: (_receiver && widget.name != null) || (widget.pick != null && _placeLabel != null) ? _save : null),
        const SizedBox(height: 6),
        IcButton(text: tr('لا، شكرًا', 'No, thanks'), ghost: true, onTap: () => Navigator.of(context).pop()),
      ]);
}
