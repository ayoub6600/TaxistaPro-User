part of '../booking_confirmation.dart';

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
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 11.0,
                  ),
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
