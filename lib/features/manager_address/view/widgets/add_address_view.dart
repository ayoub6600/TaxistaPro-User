import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geoCode;
import 'package:location/location.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';

class AddAddressView extends StatefulWidget {
  const AddAddressView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddAddressViewState createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<AddAddressView> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation =
      const LatLng(37.7749, -122.4194); // Default location
  String _address = "";
  Set<Marker> markers = {}; // To store markers on the map
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getMyCurrentLocation();
  }

  Future<void> _getMyCurrentLocation() async {
    final locationController = location.Location();

    // Check if location service is enabled
    if (!await _isLocationServiceEnabled(locationController)) {
      setState(() {
        _isLoading = false; // Set loading to false if unable to fetch location
      });
      return;
    }

    // Check for location permission
    if (!await _hasLocationPermission(locationController)) {
      setState(() {
        _isLoading = false; // Set loading to false if permission is not granted
      });
      return;
    }

    // Get current position and update UI
    await _updateCurrentLocation(locationController);
  }

  // Function to get current location
  // Future<void> _getMyCurrentLocation() async {
  //   final locationController = location.Location();

  //   // Check if location service is enabled
  //   if (!await _isLocationServiceEnabled(locationController)) return;

  //   // Check for location permission
  //   if (!await _hasLocationPermission(locationController)) return;

  //   // Get current position and update UI
  //   await _updateCurrentLocation(locationController);
  // }

  Future<bool> _isLocationServiceEnabled(
      location.Location locationController) async {
    bool _serviceEnabled = await locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await locationController.requestService();
    }
    return _serviceEnabled;
  }

  Future<bool> _hasLocationPermission(
      location.Location locationController) async {
    PermissionStatus _permissionGranted =
        await locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await locationController.requestPermission();
    }
    return _permissionGranted == PermissionStatus.granted;
  }

  // Update current location on the map
  Future<void> _updateCurrentLocation(
      location.Location locationController) async {
    final position = await locationController.getLocation();
    final currentPosition = LatLng(position.latitude!, position.longitude!);

    setState(() {
      _selectedLocation = currentPosition;
      markers.clear();
      markers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: currentPosition,
      ));
      _mapController?.animateCamera(CameraUpdate.newLatLng(currentPosition));
      _isLoading = false;
    });

    // Convert coordinates to address
    _convertToAddress(currentPosition.latitude, currentPosition.longitude);
  }

  // Function to convert latitude and longitude to address
  Future<void> _convertToAddress(double latitude, double longitude) async {
    geoCode.GeocodingPlatform.instance?.setLocaleIdentifier(
        SharedPreferenceUtil.getString(PrefKey.currentLanguageCode));

    final placemarks =
        await geoCode.placemarkFromCoordinates(latitude, longitude);
    final placemark = placemarks.first;

    setState(() {
      _address =
          "${placemark.name}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
    });
  }

  // Function to handle map tap event
  void _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      markers.clear();
      markers.add(Marker(
        markerId: MarkerId(position.toString()),
        position: position,
      ));
    });

    // Get address for the selected position
    _address = await _getAddressFromLatLng(position);
    setState(() {});
  }

  // Convert latLng to address
  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } catch (e) {
      return "Unable to get address";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              showBack: true,
              titleColor: Colors.black,
              appBarTitle: getTranslated(context, LangConst.textTapAddAddress)
                  .toString(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation,
                            zoom: 16.0,
                          ),
                          onMapCreated: (controller) =>
                              _mapController = controller,
                          onTap: _onMapTap,
                          mapType: MapType.hybrid,
                          markers: markers,
                        ),
                        _buildAddressInfo(),
                        _buildCurrentLocationButton(),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildSaveButton(context),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display address information
  Positioned _buildAddressInfo() {
    return Positioned(
      right: 12,
      child: Container(
        width: MediaQuery.of(context).size.width * .8,
        padding: EdgeInsets.symmetric(vertical: 4.dg, horizontal: 8.dg),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _address,
          maxLines: 2,
          style: AppStyle.style15W500Black.copyWith(color: Colors.black),
        ),
      ),
    );
  }

  // Widget to display the "current location" button
  Positioned _buildCurrentLocationButton() {
    return Positioned(
      bottom: 10,
      left: 10,
      child: IconButton(
        icon: Icon(
          Icons.home,
          color: Colors.green,
          size: 30.w,
        ),
        onPressed: _getMyCurrentLocation,
      ),
    );
  }

  // Save the selected address
  ButtonAuth _buildSaveButton(BuildContext context) {
    return ButtonAuth(
      onTap: () {
        if (_address.isEmpty) {
          showCustomErrorToast(
              getTranslated(context, LangConst.textTapAddAddress).toString());
        } else {
          Navigator.pop(
            context,
            {
              'address': _address,
              'latitude': _selectedLocation.latitude,
              'longitude': _selectedLocation.longitude,
            },
          );
        }
      },
      text: 'save ',
    );
  }
}
