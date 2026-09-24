part of '../booking_confirmation.dart';

List<LatLng> bookingRequestCameraPoints(
    Map<dynamic, dynamic> request, List<LatLng> fallback) {
  if (request.isEmpty) return fallback;
  final points = <LatLng>[];
  for (final prefix in ['pick', 'drop']) {
    final latitude =
        double.tryParse(request['${prefix}_lat']?.toString() ?? '');
    final longitude =
        double.tryParse(request['${prefix}_lng']?.toString() ?? '');
    if (latitude != null &&
        longitude != null &&
        latitude.abs() <= 90 &&
        longitude.abs() <= 180) {
      points.add(LatLng(latitude, longitude));
    }
  }
  return points.isNotEmpty ? points : fallback;
}

CameraPosition initialBookingCameraForRoute(
    List<LatLng> endpoints, LatLng fallback, bool confirmed) {
  if (endpoints.length < 2) {
    return CameraPosition(
        target: endpoints.isEmpty ? fallback : endpoints.first, zoom: 11);
  }
  final minLat = endpoints.map((point) => point.latitude).reduce(min);
  final maxLat = endpoints.map((point) => point.latitude).reduce(max);
  final minLng = endpoints.map((point) => point.longitude).reduce(min);
  final maxLng = endpoints.map((point) => point.longitude).reduce(max);
  final span = max(maxLat - minLat, maxLng - minLng);
  final zoom = span < 0.003
      ? 15.0
      : span < 0.015
          ? 14.0
          : 11.0;
  return CameraPosition(
    target: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
    zoom: zoom,
  );
}

mixin _BookingConfirmationMapCanvas
    on State<BookingConfirmation>, _BookingConfirmationController {
  Widget buildBookingMapCanvas(BuildContext context, Size media) {
    return Container(
      alignment: Alignment.topCenter,
      height: media.height,
      width: media.width,
      child: mapType == 'google'
          ? StreamBuilder<List<Marker>>(
              stream: mapMarkerStream,
              builder: (context, snapshot) {
                return GoogleMap(
                  padding: EdgeInsets.only(
                    bottom: mapPadding,
                    top:
                        media.height * 0.1 + MediaQuery.of(context).padding.top,
                  ),
                  onMapCreated: _onMapCreated,
                  compassEnabled: false,
                  initialCameraPosition: initialBookingCameraPosition(),
                  markers: Set<Marker>.from(myMarker),
                  polylines: polyline,
                  minMaxZoomPreference: const MinMaxZoomPreference(0.0, 20.0),
                  myLocationButtonEnabled: false,
                  buildingsEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                );
              },
            )
          : StreamBuilder<List<Marker>>(
              stream: mapMarkerStream,
              builder: (context, snapshot) {
                return SizedBox(
                  height: userRequestData.isEmpty
                      ? media.height - media.width * 0.5
                      : (media.height * 1.1) - media.width,
                  child: fm.FlutterMap(
                    mapController: _fmController,
                    options: fm.MapOptions(
                      initialCenter:
                          fmlt.LatLng(_center.latitude, _center.longitude),
                      initialZoom: 13,
                      onTap: (point, latLng) {
                        setState(() {});
                      },
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.Ayoub.Usertaxista',
                      ),
                      const fm.RichAttributionWidget(attributions: []),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
