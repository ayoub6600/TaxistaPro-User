import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/manager_address/manager/manger_address_cubit.dart';
import 'package:taxista/features/manager_address/manager/manger_address_state.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';
import 'package:taxista/widgets_new/custom_success_toast.dart';

class AddAddressViewBody extends StatefulWidget {
  const AddAddressViewBody({super.key});

  @override
  State<AddAddressViewBody> createState() => _AddAddressViewBodyState();
}

class _AddAddressViewBodyState extends State<AddAddressViewBody> {
  late MangerAddressCubit cubit;
  late GoogleMapController mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    cubit = context.read<MangerAddressCubit>();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<MangerAddressCubit, ManagerAddressState>(
        listener: (context, state) {
          switch (state.addAddressStatus) {
            case AddAddressStatus.initial:
              break;
            case AddAddressStatus.submitting:
              customLoadingDialog(context);
              break;
            case AddAddressStatus.error:
              Navigator.pop(context);
              showCustomErrorToast(state.failure?.errMessage ?? "");
              break;
            case AddAddressStatus.success:
              Navigator.pop(context);
              showCustomSuccessToast('addressAddedSuccessfully');
              Navigator.pop(context, true);
              break;
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(
                appBarTitle: getTranslated(context, LangConst.textTapAddAddress)
                    .toString(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeightSpace(20.h),
                        Text(
                          getTranslated(context, LangConst.textName).toString(),
                          style: AppStyle.style16W500Black,
                        ),
                        HeightSpace(10.h),
                        NewCustomTextFormField(
                          hint: getTranslated(context, LangConst.textName),
                          txtController: state.name,
                        ),
                        HeightSpace(20.h),
                        Text(
                          "Select Location on Map",
                          style: AppStyle.style16W500Black,
                        ),
                        HeightSpace(10.h),
                        GestureDetector(
                          onTap: () {
                            print(
                                " ------->${SharedPreferenceUtil.getString(PrefKey.fullAddress)}");
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20.h),
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.locationDot,
                                      color: AppColor.mainBlack,
                                    ),
                                    WidthSpace(10.w),
                                    Text(
                                      state.currentFullAddress,
                                      style: AppStyle.style16W500Black
                                          .copyWith(color: Colors.black),
                                    ),
                                  ],
                                ),
                                HeightSpace(20.h),
                                ButtonAuth(
                                  text: "changeLocation",
                                  onTap: () {
                                    GoRouter.of(context).push(
                                        RoutesKeys.kChangeAddressLocation);
                                    //cubit.getCurrentLocation();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ButtonAuth(
                text: "saveAddress",
                onTap: () {
                  if (state.latitude != null && state.longitude != null) {
                    cubit.storeAddress(
                      state.latitude.toString(),
                      state.longitude.toString(),
                    );
                  } else {
                    showCustomErrorToast("Please select a location");
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChangeAddressLocation extends StatelessWidget {
  const ChangeAddressLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const ChangeAddressLocationBody(),
    );
  }
}

class ChangeAddressLocationBody extends StatefulWidget {
  const ChangeAddressLocationBody({super.key});

  @override
  State<ChangeAddressLocationBody> createState() =>
      _ChangeAddressLocationBodyState();
}

class _ChangeAddressLocationBodyState extends State<ChangeAddressLocationBody> {
  late MangerAddressCubit cubit;
  late GoogleMapController mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    cubit = context.read<MangerAddressCubit>();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void _onMapTapped(LatLng tappedPosition) {
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId("selected"),
          position: tappedPosition,
        ),
      );
      // Update the cubit's current position and location
      // cubit.updateCurrentPosition(tappedPosition);
    });
  }

  void moveMapCamera(double latitude, double longitude) {
    CameraPosition newPosition = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 16,
    );
    mapController.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<MangerAddressCubit, ManagerAddressState>(
        listener: (context, state) {
          // Handle any side effects based on state changes if needed
        },
        builder: (context, state) {
          return Column(
            children: [
              CustomAppBar(
                appBarTitle: getTranslated(context, LangConst.textTapAddAddress)
                    .toString(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: state.latitude != null && state.longitude != null
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target:
                                    LatLng(state.latitude!, state.longitude!),
                                zoom: 15,
                              ),
                              markers: markers,
                              onMapCreated: (GoogleMapController controller) {
                                mapController = controller;
                              },
                              onTap:
                                  _onMapTapped, // Refactored to use the new method
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    Positioned(
                      top: 20.0,
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
                                isLatLngRequired: true,
                                getPlaceDetailWithLatLng:
                                    (Prediction prediction) {
                                  double? lat =
                                      double.tryParse(prediction.lat ?? '');
                                  double? lng =
                                      double.tryParse(prediction.lng ?? '');
                                  if (lat != null && lng != null) {
                                    moveMapCamera(lat, lng);
                                  }
                                },
                                itemClick: (Prediction prediction) {
                                  // Handle item click if needed
                                },
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
                                                prediction.description ?? "")),
                                      ],
                                    ),
                                  );
                                },
                                isCrossBtnShown: true,
                                containerHorizontalPadding: 10,
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
                      bottom: 75.0,
                      right: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          state.currentFullAddress,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: ButtonAuth(
                        onTap: () {
                          // Implement the address saving logic here
                        },
                        text: "addAddress",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
