// ignore_for_file: deprecated_member_use, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:latlong2/latlong.dart' as fmlt;
import 'package:location/location.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:share_plus/share_plus.dart';
import 'package:taxista/pages/onTripPage/bookingwidgets.dart';
import 'package:taxista/pages/onTripPage/call_wats.dart';
import 'package:vector_math/vector_math.dart' as vector;

import '../../functions/functions.dart';
import '../../functions/geohash.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/pickcontacts.dart';
import '../chatPage/chat_page.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'choosegoods.dart';
import 'drop_loc_select.dart';
import 'invoice.dart';
import 'map_page.dart';
import 'widgets/booking_status_sheet.dart';
import 'widgets/cancellation_sheet.dart';
import 'widgets/location_permission_sheet.dart';
import 'widgets/payment_method_sheet.dart';
import 'widgets/ride_schedule_sheet.dart';
import 'widgets/rider_contact_sheet.dart';
import 'widgets/sos_sheet.dart';
import 'widgets/trip_details_sheet.dart';

part 'booking_confirmation/booking_confirmation_controller.dart';
part 'booking_confirmation/booking_confirmation_map_canvas.dart';
part 'booking_confirmation/booking_confirmation_marker_snapshots.dart';
part 'booking_confirmation/booking_confirmation_status_overlays.dart';
part 'booking_confirmation/booking_confirmation_view.dart';
part 'booking_confirmation/booking_confirmation_polyline.dart';

// ignore: must_be_immutable
class BookingConfirmation extends StatefulWidget {
  dynamic type;

  //type = 1 is rental ride and type = null is regular ride
  BookingConfirmation({super.key, this.type});

  @override
  State<BookingConfirmation> createState() => _BookingConfirmationState();
}

bool serviceNotAvailable = false;
String promoCode = '';
dynamic promoStatus;
dynamic choosenVehicle;
int payingVia = 0;
dynamic timing;
dynamic mapPadding = 0.0;
String goodsSize = '';
bool noDriverFound = false;
var driverData = {};
var driversData = [];
dynamic choosenDateTime;
bool lowWalletBalance = false;
bool tripReqError = false;
List rentalOption = [];
int rentalChoosenOption = 0;
Animation<double>? _animation;
bool addCoupon = false;
bool isLoading = false;
List<fmlt.LatLng> fmpoly = [];
dynamic addLuggagePreferences;
dynamic addPetPreferences;

TextEditingController promoKey = TextEditingController();

class _BookingConfirmationState extends State<BookingConfirmation>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        _BookingConfirmationController,
        _BookingConfirmationMapCanvas,
        _BookingConfirmationMarkerSnapshots,
        _BookingConfirmationStatusOverlays,
        _BookingConfirmationView {
  @override
  Widget build(BuildContext context) => buildBookingConfirmation(context);
}
