import 'package:flutter/material.dart';

import 'core/game_core.dart';
import 'worlds/city_worlds.dart';
import 'worlds/drive_worlds.dart';
import 'worlds/mind_worlds.dart';
import 'worlds/timing_worlds.dart';

/// Every game shipped in the app. The admin panel can only switch these on/off and
/// reorder them; a brand-new game needs an app update.
class GameCatalog {
  GameCatalog._();

  static const List<TaxistaGame> all = <TaxistaGame>[
    WorldGame(id: 'night', title: 'ليل المدينة', pitch: 'سوق التاكسي في مدينة ليلية مضوية، لقّط الراكب ووصّله قبل ما يخلص وقته.', icon: Icons.nights_stay_rounded, badge: 'سواق الليل', create: NightWorld.new),
    WorldGame(id: 'ring', title: 'الدوار', pitch: 'لف في الدوار واضغط في الوقت الصح للمخرج اللي يبيه الراكب.', icon: Icons.loop_rounded, badge: 'ملك الدوارات', create: RingWorld.new),
    WorldGame(id: 'park', title: 'اصطف', pitch: 'سحبة وحدة تركن التاكسي، والركنة الدقيقة بثلاث نجوم.', icon: Icons.local_parking_rounded, badge: 'ركنة نظيفة', create: ParkWorld.new),
    WorldGame(id: 'light', title: 'الإشارة', pitch: 'اضغط أول ما تولّي خضرا، وانتبه من الصفرا.', icon: Icons.traffic_rounded, badge: 'عين الصقر', create: LightWorld.new),
    WorldGame(id: 'bags', title: 'شنطة فوق شنطة', pitch: 'رصّ شناط الراكب فوق التاكسي قبل ما تطيح.', icon: Icons.luggage_rounded, badge: 'مرتّب الشناط', create: BagsWorld.new),
    WorldGame(id: 'route', title: 'طريق مختصر', pitch: 'ارسم بصبعك أقصر طريق بين العمارات للراكب.', icon: Icons.alt_route_rounded, badge: 'دليل المدينة', create: RouteWorld.new),
    WorldGame(id: 'lane', title: 'حارة وحارة', pitch: 'بدّل الحارة، لقّط الركاب وتفادى القموع.', icon: Icons.add_road_rounded, badge: 'سيد الحارات', create: LaneWorld.new),
    WorldGame(id: 'catch', title: 'لقّط الركاب', pitch: 'حرّك التاكسي يمين ويسار ولقّط الركاب النازلين.', icon: Icons.back_hand_rounded, badge: 'ولا راكب يطيح', create: CatchWorld.new),
    WorldGame(id: 'fuel', title: 'عبّي الخزان', pitch: 'خلّي صبعك يعبّي وفكّه وسط المنطقة الخضرا بالضبط.', icon: Icons.local_gas_station_rounded, badge: 'يد ثابتة', create: FuelWorld.new),
    WorldGame(id: 'blinker', title: 'الغمّاز', pitch: 'اضغط على إيقاع الغمّاز، والسرعة تزيد شوية شوية.', icon: Icons.graphic_eq_rounded, badge: 'على الإيقاع', create: BlinkerWorld.new),
    WorldGame(id: 'bump', title: 'المطبّ', pitch: 'فرامل قبل كل مطب وسرّع بعده، وصّل بسرعة وبراحة.', icon: Icons.speed_rounded, badge: 'سواق رايق', create: BumpWorld.new),
    WorldGame(id: 'stars', title: 'نجوم الكورنيش', pitch: 'اضغط النجوم بالترتيب وارسم سماء الليل.', icon: Icons.auto_awesome_rounded, badge: 'صياد النجوم', create: StarsWorld.new),
    WorldGame(id: 'memory', title: 'ذاكرة الركاب', pitch: 'اقلب المربعات ولقّى أماكن الركاب المتشابهة.', icon: Icons.grid_view_rounded, badge: 'ذاكرة حديد', create: MemoryWorld.new),
    WorldGame(id: 'sort', title: 'فرز الركاب', pitch: 'اسحب كل راكب للتاكسي اللي بلونه قبل ما يزهق.', icon: Icons.call_split_rounded, badge: 'منظّم المحطة', create: SortWorld.new),
    WorldGame(id: 'wash', title: 'غسيل وتلميع', pitch: 'امسح الغبرة على التاكسي لين يلمع قبل ما يخلص الوقت.', icon: Icons.local_car_wash_rounded, badge: 'يلمع يلمع', create: WashWorld.new),
    WorldGame(id: 'count', title: 'عدّ السيارات', pitch: 'ركّز في السيارات اللي تعدّي وجاوب كم وحدة من كل لون.', icon: Icons.pin_rounded, badge: 'عين ما تفوتها', create: CountWorld.new),
  ];

  static TaxistaGame? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }
}
