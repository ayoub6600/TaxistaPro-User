part of '../booking_confirmation.dart';

mixin _BookingConfirmationRentalOptions
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationVehicleServices {
  Widget buildRentalPackageSelector(Size media) {
    return Column(
      children: [
        SizedBox(
          height: media.width * 0.025,
        ),
        SizedBox(
          width: media.width * 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(
                    left: media.width * 0.05, right: media.width * 0.05),
                width: media.width * 0.9,
                child: MyText(
                  text: languages[choosenLanguage]['text_availablerides'],
                  size: media.width * fourteen,
                  fontweight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
              width: media.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: uniqueServices(etaDetails)
                      .map((i, value) {
                        return MapEntry(
                            i,
                            Padding(
                              padding: EdgeInsets.only(
                                  top: 10,
                                  left: media.width * 0.05,
                                  right: media.width * 0.05),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (rentalChoosenOption != i) {
                                      setState(() {
                                        rentalOption = etaDetails[i]
                                            ['typesWithPrice']['data'];
                                        rentalChoosenOption = i;
                                        choosenVehicle = null;
                                        payingVia = 0;
                                      });
                                    } else {}
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(media.width * 0.02),
                                    width: media.width * 0.8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          media.width * 0.01),
                                      border: Border.all(
                                          color: (rentalChoosenOption != i)
                                              ? (isDarkTheme == true)
                                                  ? Colors.white
                                                  : hintColor
                                              : Colors.orange),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                etaDetails[i]['package_name']
                                                    .toString(),
                                                style: GoogleFonts.notoSans(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  fontWeight: FontWeight.w600,
                                                  color: (rentalChoosenOption ==
                                                          i)
                                                      ? (isDarkTheme == true)
                                                          ? Colors.white
                                                          : textColor
                                                      : (isDarkTheme == true)
                                                          ? const Color(
                                                              0xff8A8A8A)
                                                          : textColor,
                                                ),
                                              ),
                                              Text(
                                                etaDetails[i]
                                                        ['short_description']
                                                    .toString(),
                                                style: GoogleFonts.notoSans(
                                                    fontSize:
                                                        media.width * fourteen,
                                                    fontWeight: FontWeight.w600,
                                                    color: greyText),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${etaDetails[i]['currency']} ${etaDetails[i]['min_price']} - ${etaDetails[i]['currency']}${etaDetails[i]['max_price']}',
                                          style: GoogleFonts.notoSans(
                                              fontSize: media.width * fourteen,
                                              fontWeight: FontWeight.w600,
                                              color: greyText),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ));
                      })
                      .values
                      .toList(),
                ),
              )),
        ),
        SizedBox(
          height: media.width * 0.025,
        ),
        Button(
            width: media.width * 0.5,
            onTap: () {
              setState(() {
                isRentalRide = false;
                rentalOption =
                    etaDetails[rentalChoosenOption]['typesWithPrice']['data'];
                choosenVehicle = null;
                payingVia = 0;
              });
            },
            text: languages[choosenLanguage]['text_confirm']),
        SizedBox(
          height: media.width * 0.05,
        )
      ],
    );
  }
}
