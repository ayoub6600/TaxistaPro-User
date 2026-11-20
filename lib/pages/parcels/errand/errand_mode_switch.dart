import 'package:flutter/material.dart';

import '../../../functions/tr.dart';
import '../../intercity/intercity_style.dart';

/// «طرد من مكان لمكان» | «مشوار بوقفات»: the two ways the parcels page works. Shown only when the
/// admin turned the errand on.
class ErrandModeSwitch extends StatelessWidget {
  const ErrandModeSwitch({super.key, required this.errand, required this.name, required this.onChanged});

  final bool errand;
  final String name;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: IcStyle.line)),
        child: Row(children: [
          Expanded(child: _segment(false, tr('طرد من مكان لمكان', 'A parcel, A to B'), const ValueKey('mode-parcel'))),
          const SizedBox(width: 4),
          Expanded(child: _segment(true, name, const ValueKey('mode-errand'))),
        ]),
      );

  Widget _segment(bool value, String text, Key key) {
    final on = errand == value;
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        key: key,
        onTap: on ? null : () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: on ? const [BoxShadow(color: Color(0x1F102A56), blurRadius: 6)] : null,
          ),
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: IcStyle.t(13.5, w: FontWeight.w900, c: on ? IcStyle.blue : IcStyle.muted)),
        ),
      ),
    );
  }
}
