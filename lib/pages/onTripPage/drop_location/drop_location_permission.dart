part of '../drop_loc_select.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension _DropLocationSections4 on _DropLocationView {
  Widget _dropLocationPermission(Size media) {
    return (_locationDenied == true)
        ? Positioned(
            child: Container(
            height: media.height * 1,
            width: media.width * 1,
            color: Colors.transparent.withOpacity(0.6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: media.width * 0.9,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _locationDenied = false;
                          });
                        },
                        child: Container(
                          height: media.height * 0.05,
                          width: media.height * 0.05,
                          decoration: BoxDecoration(
                            color: page,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cancel, color: buttonColor),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: media.width * 0.025),
                Container(
                  padding: EdgeInsets.all(media.width * 0.05),
                  width: media.width * 0.9,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: page,
                      boxShadow: [BoxShadow(blurRadius: 2.0, spreadRadius: 2.0, color: Colors.black.withOpacity(0.2))]),
                  child: Column(
                    children: [
                      SizedBox(
                          width: media.width * 0.8,
                          child: Text(
                            languages[choosenLanguage]['text_open_loc_settings'],
                            style: GoogleFonts.notoSans(
                                fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                          )),
                      SizedBox(height: media.width * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                              onTap: () async {
                                await perm.openAppSettings();
                              },
                              child: Text(
                                languages[choosenLanguage]['text_open_settings'],
                                style: GoogleFonts.notoSans(
                                    fontSize: media.width * sixteen, color: buttonColor, fontWeight: FontWeight.w600),
                              )),
                          InkWell(
                              onTap: () async {
                                setState(() {
                                  _locationDenied = false;
                                  _isLoading = true;
                                });

                                getLocs();
                              },
                              child: Text(
                                languages[choosenLanguage]['text_done'],
                                style: GoogleFonts.notoSans(
                                    fontSize: media.width * sixteen, color: buttonColor, fontWeight: FontWeight.w600),
                              ))
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ))
        : Container();
  }
}
