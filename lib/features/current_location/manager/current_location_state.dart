import 'package:google_maps_flutter/google_maps_flutter.dart';

enum CurrentLocationStatus { initial, submitting, success, error }

class CurrentLocationState {
  final CurrentLocationStatus currentLocationStatus;
  final String? currentFullAddress; // Made nullable
  final String? currentShortAddress; // Made nullable
  final Marker? currentMarker;
  final LatLng? currentPosition;

  CurrentLocationState({
    this.currentLocationStatus = CurrentLocationStatus.initial,
    this.currentFullAddress,
    this.currentShortAddress,
    this.currentMarker,
    this.currentPosition,
  });

  CurrentLocationState copyWith({
    CurrentLocationStatus? currentLocationStatus,
    String? currentFullAddress,
    String? currentShortAddress,
    Marker? currentMarker,
    LatLng? currentPosition,
  }) {
    return CurrentLocationState(
      currentLocationStatus:
          currentLocationStatus ?? this.currentLocationStatus,
      currentFullAddress: currentFullAddress ?? this.currentFullAddress,
      currentShortAddress: currentShortAddress ?? this.currentShortAddress,
      currentMarker: currentMarker ?? this.currentMarker,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CurrentLocationState &&
        other.currentLocationStatus == currentLocationStatus &&
        other.currentFullAddress == currentFullAddress &&
        other.currentShortAddress == currentShortAddress &&
        other.currentMarker == currentMarker &&
        other.currentPosition == currentPosition;
  }

  @override
  int get hashCode {
    return currentLocationStatus.hashCode ^
        currentFullAddress.hashCode ^
        currentShortAddress.hashCode ^
        currentMarker.hashCode ^
        currentPosition.hashCode;
  }
}
