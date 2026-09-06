import 'dart:async';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../functions/functions.dart';
import '../../utils/version.dart';
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
  bool updateAvailable = false;
  dynamic _package;
  dynamic _version;
  bool _error = false;
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
    if (userRequestData.isNotEmpty && userRequestData['is_completed'] == 1) {
      //invoice page of ride
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Invoice()),
          (route) => false);
    } else if (userDetails['metaRequest'] != null) {
      addressList.clear();
      userRequestData = userDetails['metaRequest']['data'];
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
          MaterialPageRoute(builder: (context) => const Maps()),
          (route) => false);
    }
  }

  getData() async {
    for (var i = 0; _error == true; i++) {
      await getLanguageDone();
    }
  }

  Future<void> getLanguageDone() async {
    _package = await PackageInfo.fromPlatform();
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('force_update_user')
          .get();

      _error = false;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        final latestVersion = data['version']?.toString() ?? '';
        final isMandatory = data['is_mandatory'] == true;
        final currentVersion = _package.version;

        setState(() {
          updateAvailable = isVersionOutdated(currentVersion, latestVersion);
        });

        if (updateAvailable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: !isMandatory,
              barrierColor: Colors.black.withOpacity(0.85),
              builder: (_) => WillPopScope(
                onWillPop: () async => !isMandatory,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  title: const Text(
                    'تحديث متوفر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.system_update_rounded,
                          size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        data['release_notes'] ??
                            'يوجد إصدار جديد من التطبيق. يرجى التحديث.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      if (!isMandatory)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'يمكنك متابعة استخدام التطبيق بدون التحديث الآن.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    if (!isMandatory)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('لاحقًا'),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('تحديث الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        final updateUrl = Platform.isAndroid
                            ? data['url'] ?? ''
                            : data['url_ios'] ?? '';
                        try {
                          if (await canLaunchUrl(Uri.parse(updateUrl))) {
                            await launchUrl(Uri.parse(updateUrl),
                                mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          debugPrint('Error launching URL: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'فشل في فتح متجر التطبيقات. حاول لاحقاً.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          });
          return;
        }
      }

      if (!updateAvailable) {
        await getDetailsOfDevice();
        if (internet == true) {
          var val = await getLocalData();

          if (val == '3') {
            navigate();
          } else if (choosenLanguage.isEmpty) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Languages()));
          } else if (val == '2') {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const Login()));
            });
          } else {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const Languages()));
            });
          }
        } else {
          setState(() {});
        }
      }
    } catch (e) {
      if (internet == true && !_error) {
        setState(() => _error = true);
        await getData();
      } else {
        setState(() {});
      }
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
