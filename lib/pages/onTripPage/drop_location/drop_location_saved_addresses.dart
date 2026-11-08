part of '../drop_loc_select.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension _DropLocationSections2 on _DropLocationView {
  Widget _dropSavedAddressSheet(Size media) {
    return Positioned(
        top: 0,
        child: Container(
          padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 12, 18, 0),
          width: media.width * 1,
          height: (addAutoFill.isNotEmpty) ? media.width * 1.3 : null,
          color: (addAutoFill.isEmpty) ? Colors.transparent : page,
          child: Column(
            children: [
              Row(
                textDirection: TextDirection.ltr,
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
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF10213F).withValues(alpha: .13),
                                blurRadius: 18,
                                offset: const Offset(0, 7))
                          ],
                          color: Colors.white),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _pickerInk,
                        size: 27,
                      ),
                    ),
                  ),
                  Container(
                    height: 54,
                    width: media.width - 126,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF10213F).withValues(alpha: .13),
                          blurRadius: 22,
                          offset: const Offset(0, 8))
                    ], color: Colors.white, borderRadius: BorderRadius.circular(27)),
                    child: TextField(
                        controller: search,
                        autofocus: false,
                        decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: _pickerBlue,
                              size: 25,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: InputBorder.none,
                            hintText: languages[choosenLanguage]['text_4lettersforautofill'],
                            hintStyle: GoogleFonts.notoSans(fontSize: 14, color: _pickerMuted)),
                        style: GoogleFonts.notoSans(color: _pickerInk, fontSize: 14, fontWeight: FontWeight.w600),
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
                                              onTap: () async {
                                                Map<String, dynamic>? val;

                                                // ✅ في حالة lat/lon فاضية، نجيبها من Google API أو الكاش
                                                if (addAutoFill[i]['lat'] == '') {
                                                  val = await geoCodingForLatLng(
                                                    addAutoFill[i]['place'],
                                                    _sessionToken,
                                                  );
                                                  _sessionToken = null;

                                                  if (val != null) {
                                                    // ✅ نحفظ القيم في العنصر لتقليل التكرار مستقبلاً
                                                    addAutoFill[i]['lat'] = val['lat'].toString();
                                                    addAutoFill[i]['lon'] = val['lng'].toString();
                                                  }
                                                }

                                                setState(() {
                                                  useMyAddress = true;
                                                  _center = LatLng(
                                                    double.parse(addAutoFill[i]['lat'].toString()),
                                                    double.parse(addAutoFill[i]['lon'].toString()),
                                                  );

                                                  dropAddressConfirmation = addAutoFill[i]['description'];

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
                                              //     dropAddressConfirmation =
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
