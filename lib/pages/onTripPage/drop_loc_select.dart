// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:latlong2/latlong.dart' as fmlt;
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:taxista/pages/onTripPage/debouncer.dart';
import 'package:uuid/uuid.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/pickcontacts.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'booking_confirmation.dart';
import 'map_page.dart';
import 'widgets/smooth_page_route.dart';

part 'drop_location/drop_location_controller.dart';
part 'drop_location/drop_location_picker_widgets.dart';
part 'drop_location/drop_location_view.dart';

// ignore: must_be_immutable
class DropLocation extends StatefulWidget {
  dynamic from;
  String? favName;
  final bool returnSelectionOnly;
  final bool selectingPickup;
  DropLocation({
    super.key,
    this.from,
    this.favName,
    this.returnSelectionOnly = false,
    this.selectingPickup = false,
  });

  @override
  State<DropLocation> createState() => _DropLocationState();
}

class _DropLocationState extends State<DropLocation>
    with WidgetsBindingObserver, _DropLocationController, _DropLocationView {
  @override
  Widget build(BuildContext context) => buildDropLocation(context);
}
