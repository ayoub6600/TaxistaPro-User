// ignore_for_file: deprecated_member_use, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as fmlt;
import 'package:location/location.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:taxista/pages/onTripPage/debouncer.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart' as vector;

import '../../functions/functions.dart';
import '../../functions/geohash.dart';
import '../../functions/notifications.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/clippers.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/notification.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../navDrawer/nav_drawer.dart';
import '../noInternet/noInternet.dart';
import 'booking_confirmation.dart';
import 'drop_loc_select.dart';
import 'home_quick_actions.dart';
import 'widgets/rider_mascot_marker.dart';
import 'map_page/widgets/map_advertisement_banner.dart';
import 'map_page/widgets/map_floating_menu_button.dart';
import 'map_page/widgets/map_recenter_button.dart';
import 'map_page/widgets/trip_selection_panel.dart';
import 'map_launch/map_launch_coordinator.dart';
import 'map_launch/taxi_launch_overlay.dart';
import 'ongoingrides.dart';
import 'pick_loc_select.dart';
// ignore: depend_on_referenced_packages

part 'map_page/map_animation.dart';
part 'map_page/map_blocking_overlays.dart';
part 'map_page/map_canvas.dart';
part 'map_page/map_collapsed_sheet.dart';
part 'map_page/map_destination_state.dart';
part 'map_page/map_destination_sheet.dart';
part 'map_page/map_expanded_sheet.dart';
part 'map_page/map_home_bottom_sheet.dart';
part 'map_page/map_home_overlays.dart';
part 'map_page/map_home_state.dart';
part 'map_page/map_location_services.dart';
part 'map_page/map_main_content.dart';
part 'map_page/map_mode_sheet.dart';
part 'map_page/map_permission_states.dart';
part 'map_page/map_search_results.dart';
part 'map_page/map_system_overlays.dart';
part 'map_page/map_view.dart';

class Maps extends StatefulWidget {
  const Maps({super.key, this.animateColdLaunch = false});

  final bool animateColdLaunch;

  @override
  State<Maps> createState() => _MapsState();
}

dynamic serviceEnabled;
dynamic currentLocation;
LatLng center = const LatLng(41.4219057, -102.0840772);
String mapStyle = '';
List myMarkers = [];
Set<Marker> markers = {};
String dropAddressConfirmation = '';
String pickupAddressConfirmation = '';
List<AddressList> addressList = <AddressList>[];
dynamic favLat;
dynamic favLng;
String favSelectedAddress = '';
String favName = 'Home';
String favNameText = '';
bool requestCancelledByDriver = false;
bool cancelRequestByUser = false;
bool logout = false;
bool deleteAccount = false;
int choosenTransportType =
    (userDetails['enable_modules_for_applications'] == 'both' ||
            userDetails['enable_modules_for_applications'] == 'taxi')
        ? 0
        : 1;
String transportType = 'Taxi';
bool isOutStation = false;
bool isRentalRide = false;
String infoMessage = '';
bool rideWithoutDestination = false;
bool rentalRide = false;
LatLng? _lastRequestedLocation;

TextEditingController pickupAddressController = TextEditingController();
TextEditingController dropAddressController = TextEditingController();

class _MapsState extends State<Maps>
    with WidgetsBindingObserver, TickerProviderStateMixin {
// dynamic _currentCenter;
  dynamic _lastCenter;
  LatLng _centerLocation = const LatLng(41.4219057, -102.0840772);
  final _debouncer = Debouncer(milliseconds: 1000);

  bool ischanged = false;

  dynamic animationController;
  dynamic _sessionToken;
  final TextEditingController _pickupSearchController = TextEditingController();
  DateTime? _lastPickupFieldTapAt;
  DateTime? _lastDestinationFieldTapAt;
  bool _loading = false;
  bool _pickaddress = false;
  bool _dropaddress = false;
  final bool _dropLocationMap = false;
  bool _locationDenied = false;

  /// True while the home map's camera is moving under the fixed pickup pin
  /// - drives the mascot's speech bubble between "يحدد نقطة اللقاء" and the
  /// rider's name, same as the dedicated pickup-location picker screen.
  bool _isPickingLocation = false;
  int gettingPerm = 0;
  Animation<double>? _animation;

  late geolocs.LocationPermission permission;
  Location location = Location();
  String state = '';
  dynamic _controller;
  final MapLaunchCoordinator _launchCoordinator = MapLaunchCoordinator();
  bool _mapReadyForLaunch = false;
  bool _showLaunchOverlay = false;
  final fm.MapController _fmController = fm.MapController();
  Map myBearings = {};

  dynamic pinLocationIcon;
  dynamic deliveryIcon;
  dynamic bikeIcon;
  dynamic userLocationIcon;
  bool favAddressAdd = false;
  bool contactus = false;
  bool _isDarkTheme = false;
  List gesture = [];
  dynamic start;
  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get carMarkerStream => _mapMarkerSC.stream;

  double _isbottom = -1000;

  /// The rider's own first name for the confirmed-pickup bubble, falling
  /// back to a generic greeting if the profile has no name yet.
  String _riderFirstName() {
    final name = userDetails['name']?.toString().trim();
    if (name == null || name.isEmpty) {
      return languageDirection == 'rtl' ? 'أنت' : 'You';
    }
    return name.split(' ').first;
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
      _mapReadyForLaunch = true;
    });
  }

  void _startColdLaunchCamera() {
    if (!widget.animateColdLaunch || _controller is! GoogleMapController) {
      return;
    }
    unawaited(_launchCoordinator.animateToLocation(
      controller: _controller as GoogleMapController,
      target: currentLocation is LatLng ? currentLocation as LatLng : center,
    ));
  }

  late final AnimationController _animationcontroller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: MyTickerProvider(),
  )..repeat(reverse: true);
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(2.5, 0.0),
  ).animate(CurvedAnimation(
    parent: _animationcontroller,
    curve: Curves.linear,
  ));

  @override
  void initState() {
    super.initState();
    _showLaunchOverlay = widget.animateColdLaunch;
    _isDarkTheme = isDarkTheme;
    WidgetsBinding.instance.addObserver(this);
    choosenTransportType =
        (userDetails['enable_modules_for_applications'] == 'both' ||
                userDetails['enable_modules_for_applications'] == 'taxi')
            ? 0
            : 1;
    addressList.removeWhere((element) => element.type == 'drop');

    getLocs();
    getadminCurrentMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(requestNotificationPermissionIfNeeded());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (isDarkTheme == true) {
      await rootBundle.loadString('assets/dark.json').then((value) {
        mapStyle = value;
      });
    } else {
      await rootBundle.loadString('assets/map_style_black.json').then((value) {
        mapStyle = value;
      });
    }
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
        valueNotifierHome.incrementNotifier();
      }
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  @override
  void dispose() {
    _pickupSearchController.dispose();
    _controller?.dispose();
    _controller = null;
    animationController?.dispose();
    _animationcontroller.dispose();
    super.dispose();
  }

  int _bottom = 0;

  GeoHasher geo = GeoHasher();
  double lat = 0.0144927536231884;
  double lon = 0.0181818181818182;
  double lowerLat = 0.0;
  double lowerLon = 0.0;
  double greaterLat = 0.0;
  double greaterLon = 0.0;
  var lower;
  var higher;
  var fdb;
  @override
  Widget build(BuildContext context) => buildMapPage(context);
}
