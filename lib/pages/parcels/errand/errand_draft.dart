import 'package:flutter/widgets.dart';

import '../../../functions/errand_api.dart';
import '../../../functions/intercity_api.dart' show IcPlace;
import '../../../functions/tr.dart';

/// One stop being written: where, what the captain takes there, who to ask for, and who pays.
class ErrandStopDraft {
  ErrandStopDraft({this.place});

  IcPlace? place;
  final item = TextEditingController();
  final contactName = TextEditingController();
  final contactPhone = TextEditingController();

  /// 'paid' or 'captain'
  String pays = 'paid';

  ErrandStopData toData() =>
      ErrandStopData(place: place!, item: item.text, contactName: contactName.text, contactPhone: contactPhone.text, pays: pays);

  void dispose() {
    item.dispose();
    contactName.dispose();
    contactPhone.dispose();
  }
}

/// The whole errand as he writes it. The parcels page keeps it, so switching to «طرد» and back
/// loses nothing.
class ErrandDraft {
  ErrandDraft();

  final List<ErrandStopDraft> stops = [];

  /// «لوين يجيبهم»: null means where he is now (the page's pick)
  IcPlace? drop;
  bool rules = false;

  void add() => stops.add(ErrandStopDraft());

  void remove(int i) => stops.removeAt(i).dispose();

  /// up (-1) or down (+1) in the list
  void move(int i, int by) {
    final j = i + by;
    if (j < 0 || j >= stops.length) return;
    final s = stops.removeAt(i);
    stops.insert(j, s);
  }

  List<IcPlace> get places => [for (final s in stops) if (s.place != null) s.place!];

  /// what is still missing before the summary, in the order he fills the page
  String? missing({required bool buyAllowed}) {
    if (stops.isEmpty) return tr('زيد وقفة وحدة على الأقل.', 'Add at least one stop.');
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i], n = i + 1;
      if (s.place == null) return tr('اختار مكان الوقفة $n.', 'Choose the place of stop $n.');
      if (s.item.text.trim().isEmpty) return tr('اكتب شن ياخذ الكابتن من الوقفة $n.', 'Write what the captain takes at stop $n.');
      final digits = s.contactPhone.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty && digits.length < 8) return tr('رقم التواصل في الوقفة $n ناقص.', 'The contact number at stop $n is too short.');
      if (s.pays == 'captain' && !buyAllowed) return tr('الكابتن ما يقدرش يدفع عنك حاليًا.', 'The captain cannot pay for you yet.');
    }
    if (!rules) return tr('أكّد إن الحاجات مش من الممنوعات.', 'Confirm the items are not banned.');
    return null;
  }

  void dispose() {
    for (final s in stops) {
      s.dispose();
    }
    stops.clear();
  }
}
