import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';

import 'package:taxista/features/manager_address/data/repo/manger_address_view.dart';
import 'package:taxista/features/manager_address/manager/manger_address_state.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_success_toast.dart';
import 'package:geocoding/geocoding.dart' as geoCode;

class MangerAddressCubit extends Cubit<ManagerAddressState> {
  final MangerAddressRepo repo;
  MangerAddressCubit(this.repo) : super(ManagerAddressState.initial());

  void getUserData() async {
    emit(state.copyWith(
        managementAddressStatus: ManagementAddressStatus.submitting));
    var result = await repo.getUserData();
    result.fold(
      (failure) {
        emit(state.copyWith(
            managementAddressStatus: ManagementAddressStatus.error,
            failure: failure));
      },
      (model) {
        emit(state.copyWith(
            managementAddressStatus: ManagementAddressStatus.success,
            favouriteLocations: model.data.favouriteLocations));
      },
    );
  }

  void getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Check and request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
        return;
      }
    }

    // Handle the case where permissions are denied forever
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    try {
      // Fetch the current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Print the latitude and longitude
      print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');

      // Update the state with the new latitude and longitude
      emit(state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  void updateLocation(double latitude, double longitude) {
    emit(state.copyWith(latitude: latitude, longitude: longitude));
  }

  void removeAddress({required int addressId}) async {
    emit(state.copyWith(removeAddressStatus: RemoveAddressStatus.submitting));

    var result = await repo.removeAddress(
      id: addressId,
    );
    result.fold((failure) {
      emit(state.copyWith(
        failure: failure,
        removeAddressStatus: RemoveAddressStatus.error,
      ));
      showCustomErrorToast(state.failure?.errMessage ?? "");
    }, (model) {
      emit(state.copyWith(
        removeAddressStatus: RemoveAddressStatus.success,
      ));
      showCustomSuccessToast(model.message ?? "");
      getUserData();
    });
  }

  void storeAddress(
    String lat,
    String long,
  ) async {
    emit(state.copyWith(addAddressStatus: AddAddressStatus.submitting));

    String fullAddress =
        '${state.completeAddress.text} - ${state.landmark.text}';
    var result = await repo.addAddress(
      lat: lat,
      lng: long,
      add: fullAddress,
      name: state.name.text,
    );
    result.fold((failure) {
      emit(state.copyWith(
          failure: failure, addAddressStatus: AddAddressStatus.error));
    }, (model) {
      emit(state.copyWith(
        addAddressStatus: AddAddressStatus.success,
      ));
    });
  }

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
        emit(state.copyWith(
          currentFullAddress: fullAddress,
          // currentShortAddress: shortAddress,
          // currentLocationStatus: CurrentLocationStatus.success,
        ));
      } else {
        throw Exception("No placemarks found for the given coordinates.");
      }
    } catch (e) {
      //emit(state.copyWith(currentLocationStatus: CurrentLocationStatus.error));
      print("Error converting coordinates to address: $e");
    }
  }
}
