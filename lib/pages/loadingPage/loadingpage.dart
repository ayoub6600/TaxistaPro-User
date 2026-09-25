import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../functions/functions.dart';
import '../../update/update_checker.dart';
import '../../update/update_gate.dart';
import '../../update/update_policy.dart';
import '../language/languages.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import '../onTripPage/booking_confirmation.dart';
import '../onTripPage/invoice.dart';
import '../onTripPage/map_page.dart';
import 'loading.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

dynamic package;

class _LoadingPageState extends State<LoadingPage> {
  String dot = '.';
  bool _isLoading = false;

  @override
  void initState() {
    getLanguageDone();
    getemailmodule();
    getLandingImages();
    super.initState();
  }

  navigate1() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => BookingConfirmation()));
  }

  naviagteridewithoutdestini() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => BookingConfirmation(
                  type: 2,
                )));
  }

  naviagterental() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => BookingConfirmation(
                  type: 1,
                )));
  }

  //navigate
  navigate() async {
    if (userDetails['rider_active_ride_limit']?.toString() == '2' &&
        (int.tryParse(userDetails['rider_active_ride_count']?.toString() ??
                    '0') ??
                0) >=
            2) {
      // With two bookings there is no unique trip to force-open. Start on
      // the home screen and let the rider select either booking by ID.
      userRequestData.clear();
      requestStreamStart?.cancel();
      requestStreamEnd?.cancel();
      rideStreamStart?.cancel();
      rideStreamUpdate?.cancel();
      requestStreamStart = null;
      requestStreamEnd = null;
      rideStreamStart = null;
      rideStreamUpdate = null;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Maps()),
          (route) => false);
      return;
    }
    if (userRequestData.isNotEmpty && userRequestData['is_completed'] == 1) {
      //invoice page of ride
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Invoice()),
          (route) => false);
    } else if (userDetails['onTripRequest'] != null ||
        userDetails['metaRequest'] != null) {
      addressList.clear();
      userRequestData =
          (userDetails['onTripRequest'] ?? userDetails['metaRequest'])['data'];
      // selectedHistory = i;
      addressList.add(AddressList(
          id: '1',
          type: 'pickup',
          address: userRequestData['pick_address'],
          pickup: true,
          latlng:
              LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']),
          name: userDetails['name'],
          number: userDetails['mobile']));
      if (userRequestData['requestStops']['data'].isNotEmpty) {
        for (var i = 0;
            i < userRequestData['requestStops']['data'].length;
            i++) {
          addressList.add(AddressList(
              id: userRequestData['requestStops']['data'][i]['id'].toString(),
              type: 'drop',
              address: userRequestData['requestStops']['data'][i]['address'],
              latlng: LatLng(
                  userRequestData['requestStops']['data'][i]['latitude'],
                  userRequestData['requestStops']['data'][i]['longitude']),
              name: '',
              number: '',
              instructions: null,
              pickup: false));
        }
      }

      if (userRequestData['drop_address'] != null &&
          userRequestData['requestStops']['data'].isEmpty) {
        addressList.add(AddressList(
            id: '2',
            type: 'drop',
            pickup: false,
            address: userRequestData['drop_address'],
            latlng: LatLng(
                userRequestData['drop_lat'], userRequestData['drop_lng'])));
      }

      ismulitipleride = true;
      var val = await getUserDetails(id: userRequestData['id']);

      //login page
      if (val == true) {
        setState(() {
          _isLoading = false;
        });
        if (userRequestData['is_rental'] == true) {
          naviagterental();
        } else if (userRequestData['is_rental'] == false &&
            userRequestData['drop_address'] == null) {
          naviagteridewithoutdestini();
        } else {
          navigate1();
        }
      }
    } else {
      //home page
      Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) => const Maps(animateColdLaunch: true),
          ),
          (route) => false);
    }
  }

  bool _checkingUpdate = false;
  bool _updateShown = false;

  /// The startup version gate. Every path ends in exactly one state: the app
  /// opens (no update needed, or the check could not be completed in time),
  /// the mandatory update screen, or the optional one whose "Later" resumes
  /// the normal flow. The check itself is bounded (timeout, cache, one retry),
  /// so this can never hang the loading screen.
  Future<void> getLanguageDone() async {
    if (_checkingUpdate) return;
    _checkingUpdate = true;
    try {
      final result = await checkRiderUpdate();
      if (!mounted) return;
      if (result.decision != UpdateDecision.none) {
        _showUpdateScreen(result);
        return;
      }
      await _continueAfterUpdateCheck();
    } finally {
      _checkingUpdate = false;
    }
  }

  void _showUpdateScreen(UpdateCheckResult result) {
    if (_updateShown) return; // never a second update page
    _updateShown = true;
    final mandatory = result.decision == UpdateDecision.mandatory;
    final page = RiderUpdateScreen(
      result: result,
      chosenLanguage: choosenLanguage,
      onLater: mandatory
          ? null
          : () {
              if (!mounted) return;
              _updateShown = false;
              Navigator.of(context).pop();
              _continueAfterUpdateCheck();
            },
    );
    final route = MaterialPageRoute(builder: (_) => page);
    if (mandatory) {
      Navigator.pushAndRemoveUntil(context, route, (_) => false);
    } else {
      Navigator.push(context, route);
    }
  }

  /// Everything that happens once we know no mandatory update is blocking
  /// the app - shared by the normal "no update" path and by dismissing an
  /// optional update's dialog, which must resume the exact same flow rather
  /// than leaving the loading screen stuck with nothing left to do.
  Future<void> _continueAfterUpdateCheck() async {
    await getDetailsOfDevice();
    if (internet == true) {
      var val = await getLocalData();

      if (val == '3') {
        navigate();
      } else if (choosenLanguage.isEmpty) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Languages()));
      } else if (val == '2') {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Login()));
        });
      } else {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Languages()));
        });
      }
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: media.height * 1,
              width: media.width * 1,
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(media.width * 0.01),
                    width: media.width * 0.6,
                    height: media.height * 0.6,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/images/new_logo.jpeg"),
                            fit: BoxFit.contain)),
                  ),
                ],
              ),
            ),

            //loader
            (_isLoading == true && internet == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),

            //no internet
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        setState(() {
                          internetTrue();
                          getLanguageDone();
                        });
                      },
                    ))
                : Container(),
          ],
        ),
      ),
    );
  }
}
