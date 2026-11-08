part of 'pick_loc_select.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension _PickLocSections2 on _PickupLocationState {
  Widget _pickSearchPanel(Size media) {
    return Positioned(
        top: 0,
        child: Container(
          padding:
              EdgeInsets.fromLTRB(media.width * 0.05, MediaQuery.of(context).padding.top + 12.5, media.width * 0.05, 0),
          width: media.width * 1,
          height: (addAutoFill.isNotEmpty) ? media.width * 1.3 : null,
          color: (addAutoFill.isEmpty) ? Colors.transparent : page,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (_getDropDetails == false || choosenTransportType == 0) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          _getDropDetails = false;
                        });
                      }
                    },
                    child: Container(
                      height: media.width * 0.1,
                      width: media.width * 0.1,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 2)],
                          color: page),
                      alignment: Alignment.center,
                      child: Icon(Icons.arrow_back, color: textColor),
                    ),
                  ),
                  Container(
                    height: media.width * 0.1,
                    width: media.width * 0.75,
                    padding: EdgeInsets.fromLTRB(media.width * 0.05, 0, media.width * 0.05, 0),
                    decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 2)],
                        color: page,
                        borderRadius: BorderRadius.circular(media.width * 0.05)),
                    child: TextField(
                        controller: search,
                        autofocus: (widget.from == 'add stop') ? true : false,
                        decoration: InputDecoration(
                            contentPadding: (languageDirection == 'rtl')
                                ? EdgeInsets.only(bottom: media.width * 0.03)
                                : EdgeInsets.only(bottom: media.width * 0.042),
                            border: InputBorder.none,
                            hintText: languages[choosenLanguage]['text_4lettersforautofill'],
                            hintStyle: GoogleFonts.notoSans(
                                fontSize: media.width * twelve, color: textColor.withOpacity(0.4))),
                        style: GoogleFonts.notoSans(color: textColor),
                        maxLines: 1,
                        onChanged: (val) {
                          if (val.isEmpty) {
                            _sessionToken = null;
                          }
                          _debouncer.run(() {
                            if (val.length >= 4) {
                              if (storedAutoAddress
                                  .where((element) =>
                                      element['description'].toString().toLowerCase().contains(val.toLowerCase()))
                                  .isNotEmpty) {
                                addAutoFill.removeWhere((element) =>
                                    element['description'].toString().toLowerCase().contains(val.toLowerCase()) ==
                                    false);
                                storedAutoAddress
                                    .where((element) =>
                                        element['description'].toString().toLowerCase().contains(val.toLowerCase()))
                                    .forEach((element) {
                                  addAutoFill.add(element);
                                });
                                valueNotifierHome.incrementNotifier();
                              } else {
                                _sessionToken ??= const Uuid().v4();
                                getAutocomplete(val, _sessionToken, _center.latitude, _center.longitude);
                              }
                            } else if (val.isEmpty) {
                              setState(() {
                                addAutoFill.clear();
                              });
                            }
                          });
                        }),
                  )
                ],
              ),
              SizedBox(
                height: media.width * 0.05,
              ),
              (addAutoFill.isNotEmpty)
                  ? Container(
                      height: media.height * 0.45,
                      padding: EdgeInsets.all(media.width * 0.02),
                      width: media.width * 0.9,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(media.width * 0.05), color: page),
                      child: SingleChildScrollView(
                        child: Column(
                          children: addAutoFill
                              .asMap()
                              .map((i, value) {
                                return MapEntry(
                                    i,
                                    (i < 7)
                                        ? Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              // onTap:
                                              //     () async {
                                              //   // ignore: prefer_typing_uninitialized_variables
                                              //   var val;
                                              //   if (addAutoFill[
                                              //               i]
                                              //           [
                                              //           'lat'] ==
                                              //       '') {
                                              //     val = await geoCodingForLatLng(
                                              //         addAutoFill[i]
                                              //             [
                                              //             'place'],
                                              //         _sessionToken);
                                              //     _sessionToken =
                                              //         null;
                                              //   }

                                              //   setState(() {
                                              //     useMyAddress =
                                              //         true;
                                              //     _center = (addAutoFill[i]['lat'] ==
                                              //             '')
                                              //         ? LatLng(
                                              //             double.parse(val['lat']
                                              //                 .toString()),
                                              //             double.parse(val['lng']
                                              //                 .toString()))
                                              //         : LatLng(
                                              //             double.parse(addAutoFill[i]['lat'].toString()),
                                              //             double.parse(addAutoFill[i]['lon'].toString()));
                                              //     pickupAddressConfirmation =
                                              //         addAutoFill[i]
                                              //             [
                                              //             'description'];
                                              //     if (mapType ==
                                              //         'google') {
                                              //       _controller?.moveCamera(CameraUpdate.newLatLngZoom(
                                              //           _center,
                                              //           14.0));
                                              //     } else {
                                              //       _fmController.move(
                                              //           fmlt.LatLng(
                                              //               _center.latitude,
                                              //               _center.longitude),
                                              //           14);
                                              //     }
                                              //   });
                                              //   FocusManager
                                              //       .instance
                                              //       .primaryFocus
                                              //       ?.unfocus();
                                              //   addAutoFill
                                              //       .clear();
                                              //   search.text =
                                              //       '';
                                              // },
                                              onTap: () async {
                                                Map<String, dynamic>? val;

                                                if (addAutoFill[i]['lat'] == '' || addAutoFill[i]['lat'] == null) {
                                                  val = await geoCodingForLatLng(
                                                    addAutoFill[i]['place'],
                                                    _sessionToken,
                                                  );
                                                  _sessionToken = null;

                                                  if (val != null) {
                                                    addAutoFill[i]['lat'] = val['lat'].toString();
                                                    addAutoFill[i]['lon'] = val['lng'].toString();
                                                  }
                                                }

                                                LatLng selectedLatLng = LatLng(
                                                  double.parse(addAutoFill[i]['lat'].toString()),
                                                  double.parse(addAutoFill[i]['lon'].toString()),
                                                );

                                                setState(() {
                                                  useMyAddress = true;
                                                  _center = selectedLatLng;
                                                  pickupAddressConfirmation = addAutoFill[i]['description'];

                                                  if (mapType == 'google') {
                                                    _controller?.moveCamera(CameraUpdate.newLatLngZoom(_center, 14.0));
                                                  } else {
                                                    _fmController.move(
                                                      fmlt.LatLng(_center.latitude, _center.longitude),
                                                      14,
                                                    );
                                                  }
                                                });

                                                FocusManager.instance.primaryFocus?.unfocus();
                                                addAutoFill.clear();
                                                search.text = '';
                                              },
                                              child: Container(
                                                padding:
                                                    EdgeInsets.fromLTRB(0, media.width * 0.04, 0, media.width * 0.04),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.grey[200],
                                                      ),
                                                      child: const Icon(Icons.access_time),
                                                    ),
                                                    Container(
                                                      alignment: Alignment.centerLeft,
                                                      width: media.width * 0.7,
                                                      child: Text(
                                                          (addAutoFill[i]['description'] != null)
                                                              ? addAutoFill[i]['description']
                                                              : addAutoFill[i]['display_name'],
                                                          style: GoogleFonts.notoSans(
                                                            fontSize: media.width * twelve,
                                                            color: textColor,
                                                          ),
                                                          maxLines: 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container());
                              })
                              .values
                              .toList(),
                        ),
                      ),
                    )
                  : Container()
            ],
          ),
        ));
  }
}
