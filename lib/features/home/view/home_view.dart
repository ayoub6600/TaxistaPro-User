import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/features/auth/login/view/widgets/logo.dart';
import 'package:taxista/routing/routes_keys.dart';

class HomeViewBody extends StatefulWidget {
  const HomeViewBody({Key? key}) : super(key: key);

  @override
  State<HomeViewBody> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeViewBody> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Method to get the user's current location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location permissions are permanently denied.")),
      );
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Image.asset(
                    "assets/images/logo.png",
                    height: 50.h,
                  ),
                ),
              ],
            ),
          ),
          HeightSpace(20.h),
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 200.h,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 14.0,
                    ),
                    mapType: MapType.normal,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _currentLocation!,
                        infoWindow: const InfoWindow(title: "Your Location"),
                      ),
                    },
                  ),
                ),
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push(RoutesKeys.kProfail);
            },
            child: Text('profail'),
          ),
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push(RoutesKeys.kManagerAddressView);
            },
            child: Text('kManagerAddressView'),
          ),
          //kNotifactionView
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push(RoutesKeys.kNotifactionView);
            },
            child: Text('kNotifactionView'),
          ),
          //kComplaintView
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push(RoutesKeys.kComplaintView);
            },
            child: Text('kComplaintView'),
          ),
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push(RoutesKeys.kMyBookingsScreen);
            },
            child: Text('kMyBookingsScreen'),
          ),
        ],
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: HomeViewBody(),
    );
  }
}
