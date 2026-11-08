// ignore_for_file: deprecated_member_use

import '../pulse/pickup_change_panel.dart' show PulsePickupPoints;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:taxista/pages/onTripPage/debouncer.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'choosegoods.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'booking_confirmation.dart';
import 'map_page.dart';
import 'widgets/rider_mascot_marker.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
// ignore: depend_on_referenced_packages
import 'package:latlong2/latlong.dart' as fmlt;
part 'pick_location_map_layer.dart';
part 'pick_location_bottom_panel.dart';
part 'pick_location_search.dart';
part 'pick_location_save_address.dart';
part 'pick_location_permission.dart';

// ignore: must_be_immutable
class PickupLocation extends StatefulWidget {
  dynamic from;
  String? favName;
  PickupLocation({super.key, this.from, this.favName});

  @override
  State<PickupLocation> createState() => _PickupLocationState();
}

class _PickupLocationState extends State<PickupLocation> with WidgetsBindingObserver {
  GoogleMapController? _controller;
  final fm.MapController _fmController = fm.MapController();
  late PermissionStatus permission;
  Location location = Location();
  String _state = '';
  bool _isLoading = false;
  dynamic _sessionToken;
  LatLng? _lastRequestedLocation;
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  LatLng _centerLocation = const LatLng(41.4219057, -102.0840772);
  TextEditingController search = TextEditingController();
  String favNameText = '';
  bool _locationDenied = false;
  bool favAddressAdd = false;
  bool _getDropDetails = false;
  TextEditingController buyerName = TextEditingController();
  TextEditingController buyerNumber = TextEditingController();
  TextEditingController instructions = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 1000);
  bool useMyDetails = false;
  bool useMyAddress = false;

  /// True while the map camera is moving under the fixed pickup pin (the
  /// rider is actively dragging the map to choose a spot) - drives the
  /// mascot's speech bubble between "يحدد نقطة اللقاء" and the rider's name.
  bool _isPickingLocation = false;

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
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    dropAddressConfirmation = '';
    useMyDetails = false;

    getLocs();
    super.initState();
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
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;

    super.dispose();
  }

  getLocs() async {
    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied || permission == PermissionStatus.deniedForever) {
      setState(() {
        _state = '3';
        _isLoading = false;
      });
    } else if (permission == PermissionStatus.granted || permission == PermissionStatus.grantedLimited) {
      var locs = await geolocs.Geolocator.getLastKnownPosition();
      if (addressList.length != 2 && widget.from == null) {
        if (locs != null) {
          setState(() {
            _center = LatLng(double.parse(locs.latitude.toString()), double.parse(locs.longitude.toString()));
            _centerLocation = LatLng(double.parse(locs.latitude.toString()), double.parse(locs.longitude.toString()));
          });
        } else {
          var loc = await geolocs.Geolocator.getCurrentPosition(desiredAccuracy: geolocs.LocationAccuracy.low);
          setState(() {
            _center = LatLng(double.parse(loc.latitude.toString()), double.parse(loc.longitude.toString()));
            _centerLocation = LatLng(double.parse(loc.latitude.toString()), double.parse(loc.longitude.toString()));
          });
        }
        if (addressList.isNotEmpty) {
          setState(() {
            _center = addressList[0].latlng;
            pickupAddressConfirmation = addressList[0].address;
          });
        }
      } else if (widget.from != null && widget.from != 'add stop' && widget.from != 'favourite') {
        setState(() {
          buyerName.text = addressList[widget.from].name.toString();
          buyerNumber.text = addressList[widget.from].number.toString();
          instructions.text =
              (addressList[widget.from].instructions != null) ? addressList[widget.from].instructions : '';
          _center = addressList[widget.from].latlng;
          _centerLocation = addressList[widget.from].latlng;
          // dropAddressConfirmation = addressList[widget.from].address;
          pickupAddressConfirmation = addressList[widget.from].address;
        });
      } else if (widget.from != null && widget.from == 'favourite') {
        var loc = await geolocs.Geolocator.getCurrentPosition(desiredAccuracy: geolocs.LocationAccuracy.low);
        setState(() {
          _center = LatLng(double.parse(loc.latitude.toString()), double.parse(loc.longitude.toString()));
          _centerLocation = LatLng(double.parse(loc.latitude.toString()), double.parse(loc.longitude.toString()));
        });
      } else if (widget.from == 'add stop') {
        if (locs != null) {
          setState(() {
            _center = LatLng(double.parse(locs.latitude.toString()), double.parse(locs.longitude.toString()));
            _centerLocation = LatLng(double.parse(locs.latitude.toString()), double.parse(locs.longitude.toString()));
          });
        } else {
          var loc = await geolocs.Geolocator.getCurrentPosition(desiredAccuracy: geolocs.LocationAccuracy.low);
          setState(() {
            _center = LatLng(double.parse(loc.latitude.toString()), double.parse(loc.longitude.toString()));
            _centerLocation = LatLng(double.parse(loc.latitude.toString()), double.parse(loc.longitude.toString()));
          });
        }
        setState(() {
          _center = addressList.firstWhere((e) => e.type == 'pickup').latlng;
          _centerLocation = addressList.firstWhere((e) => e.type == 'pickup').latlng;
          // dropAddressConfirmation
          pickupAddressConfirmation = addressList.firstWhere((element) => element.type == 'pickup').address;

          useMyAddress = true;
        });
      } else {
        setState(() {
          _center = addressList.firstWhere((e) => e.type == 'pickup').latlng;
          _centerLocation = addressList.firstWhere((e) => e.type == 'pickup').latlng;
          // if (addressList.length >= 2) {
          //   dropAddressConfirmation = addressList
          //       .firstWhere((element) => element.type == 'drop')
          //       .address;
          // }
          useMyAddress = true;
        });
      }

      setState(() {
        _state = '3';
        _isLoading = false;
      });
    }
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Login()), (route) => false);
  }

  popFunction() {
    if (_getDropDetails == true) {
      return false;
    } else {
      addressList.removeWhere((element) => element.id == 'pickup');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: popFunction(),
      onPopInvoked: (did) {
        if (_getDropDetails) {
          setState(() {
            _getDropDetails = false;
          });
        }
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              return Directionality(
                textDirection: (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
                child: Container(
                  height: media.height * 1,
                  width: media.width * 1,
                  color: page,
                  child: Stack(
                    children: [
                      _pickMapLayer(media),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 120,
                        left: 16,
                        right: 16,
                        child: PulsePickupPoints(
                          around: () => _centerLocation,
                          onSelect: (point, name) => _controller?.animateCamera(CameraUpdate.newLatLngZoom(point, 18)),
                        ),
                      ),
                      Positioned(
                          child: Container(
                        height: media.height * 1,
                        width: media.width * 1,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(
                              height: (media.height / 2) - riderMascotHeight - riderMascotBubbleAllowance,
                            ),
                            RiderMascotBubble(
                              text: _isPickingLocation
                                  ? (languageDirection == 'rtl' ? 'يحدد نقطة اللقاء' : 'Choosing the meeting point')
                                  : _riderFirstName(),
                            ),
                            const SizedBox(height: 4),
                            Image.asset(
                              riderMascotAsset,
                              width: riderMascotWidth,
                              height: riderMascotHeight,
                              cacheWidth: (riderMascotWidth * MediaQuery.of(context).devicePixelRatio).round(),
                              fit: BoxFit.contain,
                            ),
                            if (userDetails['enable_map_location_icon_drag_and_drop_feature'] == '0')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Button(
                                    width: media.width * 0.5,

                                    onTap: () async {
                                      // ✅ تجاهل لو نفس الإحداثيات
                                      if (_lastRequestedLocation != null &&
                                          _lastRequestedLocation!.latitude == _centerLocation.latitude &&
                                          _lastRequestedLocation!.longitude == _centerLocation.longitude) {
                                        return;
                                      }

                                      _lastRequestedLocation = _centerLocation;

                                      setState(() {
                                        _isLoading = true;
                                      });

                                      if (!useMyAddress) {
                                        String val =
                                            await geoCoding(_centerLocation.latitude, _centerLocation.longitude) ?? '';
                                        setState(() {
                                          _center = _centerLocation;
                                          pickupAddressConfirmation = val;
                                          _isLoading = false;
                                        });
                                      } else {
                                        setState(() {
                                          useMyAddress = false;
                                          _isLoading = false;
                                        });
                                      }
                                    },

                                    // onTap: () async {
                                    //   setState(() {
                                    //     _isLoading = true;
                                    //   });
                                    //   if (useMyAddress == false) {
                                    //     var val = await geoCoding(
                                    //         _centerLocation.latitude,
                                    //         _centerLocation.longitude);
                                    //     setState(() {
                                    //       _center = _centerLocation;
                                    //       pickupAddressConfirmation = val;
                                    //       _isLoading = false;
                                    //     });
                                    //   }
                                    //   if (useMyAddress == true) {
                                    //     setState(() {
                                    //       useMyAddress = false;
                                    //     });
                                    //   }
                                    // },
                                    text: languages[choosenLanguage]['text_confirm'],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )),
                      _pickBottomPanel(media),
                      _pickSearchPanel(media),
                      _pickSaveAddress(media),
                      _pickLocationPermission(media),
                      (_isLoading == true) ? const Positioned(child: Loading()) : Container(),
                      (internet == false)
                          ? Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
                                  });
                                },
                              ))
                          : Container(),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
