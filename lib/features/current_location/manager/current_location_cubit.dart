import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:geocoding/geocoding.dart' as geoCode;

import 'package:taxista/features/current_location/manager/current_location_state.dart';

class CurrentLocationCubit extends Cubit<CurrentLocationState> {
  CurrentLocationCubit() : super(CurrentLocationState());

  Future<void> initUserLocation() async {
    await getCurrentLocation();
  }

  /// Fetch current location and update the state
  Future<void> getCurrentLocation() async {
    emit(state.copyWith(
        currentLocationStatus: CurrentLocationStatus.submitting));
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      // Get user's current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save the location in shared preferences
      SharedPreferenceUtil.putDouble(PrefKey.latitude, position.latitude);
      SharedPreferenceUtil.putDouble(PrefKey.longitude, position.longitude);

      // Convert to address and update state
      await convertToAddress(position.latitude, position.longitude);
      updateLocationMarker(LatLng(position.latitude, position.longitude));
    } catch (e) {
      emit(state.copyWith(currentLocationStatus: CurrentLocationStatus.error));
      print("Error fetching location: $e");
    }
  }

  /// Convert coordinates to an address
  Future<void> convertToAddress(double latitude, double longitude) async {
    try {
      geoCode.GeocodingPlatform.instance?.setLocaleIdentifier(
        SharedPreferenceUtil.getString(PrefKey.currentLanguageCode),
      );

      List<geoCode.Placemark> placemarks =
          await geoCode.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        String fullAddress =
            "${placemarks.first.administrativeArea} ${placemarks.first.locality} - ${placemarks.first.street}";
        String shortAddress =
            "${placemarks.first.locality}, ${placemarks.first.subAdministrativeArea}";

        SharedPreferenceUtil.putString(PrefKey.fullAddress, fullAddress);

        emit(state.copyWith(
          currentFullAddress: fullAddress,
          currentShortAddress: shortAddress,
          currentLocationStatus: CurrentLocationStatus.success,
        ));
      } else {
        throw Exception("No placemarks found for the given coordinates.");
      }
    } catch (e) {
      emit(state.copyWith(currentLocationStatus: CurrentLocationStatus.error));
      print("Error converting coordinates to address: $e");
    }
  }

  /// Update user's selected location and marker on the map
  void updateCurrentPosition(LatLng newPosition) {
    emit(state.copyWith(currentPosition: newPosition));
  }

  /// Update the marker position on the map
  void updateLocationMarker(LatLng position) {
    Marker marker = Marker(
      markerId: MarkerId("currentLocation"),
      position: position,
    );
    emit(state.copyWith(currentMarker: marker));
  }
}
