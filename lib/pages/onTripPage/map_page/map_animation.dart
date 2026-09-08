part of '../map_page.dart';

extension _MapAnimationHelpers on _MapsState {
  double getBearing(LatLng begin, LatLng end) {
    final lat = (begin.latitude - end.latitude).abs();
    final lng = (begin.longitude - end.longitude).abs();

    if (lat == 0 && lng == 0) return 0;
    if (lat == 0) return begin.longitude < end.longitude ? 90 : 270;

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return vector.degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return vector.degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 270;
    }

    return 0;
  }

  Future<void> animateCar(
    double fromLat,
    double fromLong,
    double toLat,
    double toLong,
    StreamSink<List<Marker>> mapMarkerSink,
    TickerProvider provider,
    dynamic markerid,
    dynamic markerBearing,
    dynamic icon,
  ) async {
    final bearing =
        getBearing(LatLng(fromLat, fromLong), LatLng(toLat, toLong));
    myBearings[markerBearing.toString()] = bearing;

    var carMarker = Marker(
      markerId: MarkerId(markerid),
      position: LatLng(fromLat, fromLong),
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      draggable: false,
    );

    myMarkers.add(carMarker);
    mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());

    final tween = Tween<double>(begin: 0, end: 1);
    _animation = tween.animate(animationController)
      ..addListener(() {
        myMarkers.removeWhere(
          (element) => element.markerId == MarkerId(markerid),
        );

        final v = _animation!.value;
        final lng = v * toLong + (1 - v) * fromLong;
        final lat = v * toLat + (1 - v) * fromLat;

        carMarker = Marker(
          markerId: MarkerId(markerid),
          position: LatLng(lat, lng),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: bearing,
          draggable: false,
        );

        myMarkers.add(carMarker);
        mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());
      });

    animationController.forward();
  }
}
