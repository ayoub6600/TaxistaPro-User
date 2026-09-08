// ignore_for_file: no_leading_underscores_for_local_identifiers, unrelated_type_equality_checks

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/functions/notifications.dart';
import 'package:taxista/translations/translation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/NavigatorPages/editprofile.dart';
import '../pages/NavigatorPages/history.dart';
import '../pages/NavigatorPages/historydetails.dart';
import '../pages/loadingPage/loadingpage.dart';
import '../pages/login/login.dart';
import '../pages/onTripPage/booking_confirmation.dart';
import '../pages/onTripPage/map_page.dart';
import '../pages/onTripPage/review_page.dart';
import '../pages/referralcode/referral_code.dart';
import '../styles/styles.dart';

part 'parts/bootstrap_auth.dart';
part 'parts/user_session.dart';
part 'parts/routing_eta.dart';
part 'parts/ride_requests.dart';
part 'parts/trip_support.dart';
part 'parts/payments_profile.dart';
part 'parts/verification.dart';
