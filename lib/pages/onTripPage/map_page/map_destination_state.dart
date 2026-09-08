part of '../map_page.dart';

extension _MapDestinationState on _MapsState {
  bool get hasPickupAndDrop =>
      addressList.any((element) => element.type == 'pickup') &&
      addressList.any((element) => element.type == 'drop');

  void resetDestinationEntry(Size media) {
    addressList.removeWhere((element) => element.type == 'drop');
    dropAddressController.clear();
    addAutoFill.clear();
    infoMessage = '';
    _sessionToken = null;
    rideWithoutDestination = false;
    rentalRide = false;
    _pickaddress = false;
    _dropaddress = true;
    _height = media.height;
    _bottom = 1;
    _isbottom = -1000;
  }

  void navigateWhenRouteReady() {
    if (!hasPickupAndDrop) return;
    polyList.clear();
    navigate();
  }
}
