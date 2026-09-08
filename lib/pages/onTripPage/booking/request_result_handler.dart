part of '../bookingwidgets.dart';

extension _RequestResultHandler on _CreateRequestActions {
  void _handleCreatedRequest({
    required dynamic result,
    required String geoHash,
  }) async {
    if (result == 'success') {
      if (!mounted) return;
      Navigator.pop(context);

      if (isOutStation) {
        rideLaterSuccess = true;
        showModalBottomSheet<void>(
          context: context,
          isDismissible: false,
          builder: (_) => const SuccessPopUp(),
        );
        _updateBidMetadata(
          geoHash: geoHash,
          price: yourAmount.text,
          isOutStationRide: true,
          fromDate: widget.fromDate,
          toDate: widget.toDate,
        );
        userRequestData.clear();
      } else {
        _updateBidMetadata(
          geoHash: geoHash,
          price: userRequestData['offerred_ride_fare'].toString(),
          isOutStationRide: false,
        );
      }
    }

    _finishRequestSubmission();
  }

  Future<void> _updateBidMetadata({
    required String geoHash,
    required String price,
    required bool isOutStationRide,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return FirebaseDatabase.instance
        .ref()
        .child('bid-meta/${userRequestData['id']}')
        .update(
          _buildBidMetadata(
            geoHash: geoHash,
            price: price,
            isOutStationRide: isOutStationRide,
            fromDate: fromDate,
            toDate: toDate,
          ),
        );
  }
}
