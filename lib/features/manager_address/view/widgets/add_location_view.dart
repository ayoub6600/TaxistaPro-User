import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/current_location/manager/current_location_cubit.dart';
import 'package:taxista/features/current_location/manager/current_location_state.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';

class AddLocationView extends StatefulWidget {
  const AddLocationView({super.key});

  @override
  State<AddLocationView> createState() => _AddLocationViewState();
}

class _AddLocationViewState extends State<AddLocationView> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    context.read<CurrentLocationCubit>().initUserLocation();
  }

  void _onMapTapped(LatLng tappedPosition, BuildContext context) {
    setState(() {
      context
          .read<CurrentLocationCubit>()
          .updateCurrentPosition(tappedPosition);

      context.read<CurrentLocationCubit>().updateLocationMarker(tappedPosition);
      context
          .read<CurrentLocationCubit>()
          .convertToAddress(tappedPosition.latitude, tappedPosition.longitude);
    });
  }

  moveMapCamera(double latitude, double longitude) {
    CameraPosition newPosition = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 16,
    );
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(appBarTitle: 'addAddress'),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  context.read<CurrentLocationCubit>().state.currentPosition ==
                          null
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                              target: context
                                  .read<CurrentLocationCubit>()
                                  .state
                                  .currentPosition!,
                              zoom: 16),
                          mapType: MapType.normal,
                          onTap: (LatLng latLng) {
                            _onMapTapped(latLng, context);
                          },
                          markers: {
                            // context
                            //     .read<CurrentLocationCubit>()
                            //     .state
                            //     .currentMarker
                          },
                        ),

                  /// Address Line
                  Positioned(
                    top: 20.h,
                    right: 0,
                    left: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GooglePlaceAutoCompleteTextField(
                              textEditingController: TextEditingController(),
                              googleAPIKey:
                                  'AIzaSyCLVX-Jnqqo89cZ2xQ6CJflSueG-laba7g',
                              inputDecoration: InputDecoration(
                                  fillColor: AppColor.white,
                                  filled: true,
                                  hintText: "searchYourLocation"),
                              debounceTime: 800,
                              // countries: ["eg", "sa"],
                              isLatLngRequired: true,
                              getPlaceDetailWithLatLng:
                                  (Prediction prediction) {
                                double? lat =
                                    double.tryParse(prediction.lat ?? '');
                                double? lng =
                                    double.tryParse(prediction.lng ?? '');
                                if (lat == null || lng == null) return;
                                moveMapCamera(lat, lng);
                                // print(
                                //     "placeDetails" + prediction.lng.toString());
                              },
                              itemClick: (Prediction prediction) {
                                //  controller.text=prediction.description;
                                // controller.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description.length));
                              },
                              // if we want to make custom list item builder
                              itemBuilder:
                                  (context, index, Prediction prediction) {
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on),
                                      const SizedBox(width: 7),
                                      Expanded(
                                          child: Text(
                                              prediction.description ?? ""))
                                    ],
                                  ),
                                );
                              },
                              // if you want to add seperator between list items
                              seperatedBuilder: const Divider(),
                              // want to show close icon
                              isCrossBtnShown: true,
                              // optional container padding
                              containerHorizontalPadding: 10,
                              // place type
                              placeType: PlaceType.geocode,
                              boxDecoration: const BoxDecoration(),
                              countries: const ['eg'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    right: 0,
                    left: 0,
                    bottom: 75.h,
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: BlocBuilder<CurrentLocationCubit,
                            CurrentLocationState>(
                          builder: (context, state) {
                            return Text(
                              "state.currentFullAddress,",
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            );
                          },
                        )),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: ButtonAuth(
                      onTap: () {
                        // Map<String, dynamic> body = {
                        //   'address': context
                        //       .read<CurrentLocationCubit>()
                        //       .state
                        //       .currentFullAddress,
                        //   'longitude': context
                        //       .read<CurrentLocationCubit>()
                        //       .state
                        //       .currentPosition!
                        //       .longitude,
                        //   'latitude': context
                        //       .read<CurrentLocationCubit>()
                        //       .state
                        //       .currentPosition!
                        //       .latitude,
                        // };
                        // Navigator.pop(context, body);
                      },
                      text: "addAddress",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
