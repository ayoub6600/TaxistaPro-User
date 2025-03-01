import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/profail/data/model/user_data_responce.dart';
import 'package:taxista/widgets_new/failures.dart';

enum ManagementAddressStatus { initial, submitting, success, error }

enum RemoveAddressStatus { initial, submitting, success, error }

//addAddressStatus
enum AddAddressStatus { initial, submitting, success, error }

enum CurrentLocationStatus { initial, submitting, success, error }

class ManagerAddressState extends Equatable {
  final ManagementAddressStatus managementAddressStatus;
  final RemoveAddressStatus removeAddressStatus;
  final AddAddressStatus addAddressStatus;
  final List<FavouriteLocation> favouriteLocations;
  final String currentFullAddress;

  final Failure? failure;
  final TextEditingController name;
  final TextEditingController completeAddress;
  final TextEditingController landmark;

  final double? latitude; // New field for latitude
  final double? longitude; // New field for longitude

  const ManagerAddressState({
    required this.landmark,
    required this.currentFullAddress,
    required this.completeAddress,
    required this.name,
    this.managementAddressStatus = ManagementAddressStatus.initial,
    this.removeAddressStatus = RemoveAddressStatus.initial,
    this.addAddressStatus = AddAddressStatus.initial,
    this.favouriteLocations = const [],
    this.failure,
    this.latitude,
    this.longitude,
    //   this.name = TextEditingController(),
  });

  factory ManagerAddressState.initial() {
    return ManagerAddressState(
      managementAddressStatus: ManagementAddressStatus.initial,
      removeAddressStatus: RemoveAddressStatus.initial,
      currentFullAddress: SharedPreferenceUtil.getString(PrefKey.fullAddress),
      addAddressStatus: AddAddressStatus.initial,
      favouriteLocations: [],
      name: TextEditingController(),
      failure: null,
      landmark: TextEditingController(),
      completeAddress: TextEditingController(),
      latitude: null,
      longitude: null,
    );
  }

  ManagerAddressState copyWith({
    ManagementAddressStatus? managementAddressStatus,
    String? currentFullAddress,
    RemoveAddressStatus? removeAddressStatus,
    AddAddressStatus? addAddressStatus,
    List<FavouriteLocation>? favouriteLocations,
    TextEditingController? name,
    TextEditingController? completeAddress,
    TextEditingController? landmark,
    Failure? failure,
    double? latitude,
    double? longitude,
  }) {
    return ManagerAddressState(
        landmark: landmark ?? this.landmark,
        currentFullAddress: currentFullAddress ?? this.currentFullAddress,
        managementAddressStatus:
            managementAddressStatus ?? this.managementAddressStatus,
        removeAddressStatus: removeAddressStatus ?? this.removeAddressStatus,
        addAddressStatus: addAddressStatus ?? this.addAddressStatus,
        favouriteLocations: favouriteLocations ?? this.favouriteLocations,
        name: name ?? this.name,
        completeAddress: completeAddress ?? this.completeAddress,
        failure: failure,
        latitude: latitude,
        longitude: longitude);
  }

  @override
  List<Object?> get props => [
        landmark,
        managementAddressStatus,
        removeAddressStatus,
        addAddressStatus,
        favouriteLocations,
        currentFullAddress,
        completeAddress,
        name,
        failure,
        latitude,
        longitude
      ];
}
