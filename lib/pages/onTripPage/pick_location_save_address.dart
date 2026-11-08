part of 'pick_loc_select.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension _PickLocSections3 on _PickupLocationState {
  Widget _pickSaveAddress(Size media) {
    return (favAddressAdd == true)
        ? Positioned(
            top: 0,
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
                        Container(
                          height: media.width * 0.1,
                          width: media.width * 0.1,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: page),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                favName = '';
                                favAddressAdd = false;
                              });
                            },
                            child: const Icon(Icons.cancel_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  Container(
                    padding: EdgeInsets.all(media.width * 0.05),
                    width: media.width * 0.9,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: page),
                    child: Column(
                      children: [
                        Text(
                          languages[choosenLanguage]['text_saveaddressas'],
                          style: GoogleFonts.notoSans(
                              fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Text(
                          favSelectedAddress,
                          style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: textColor),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() {
                                  favName = 'Home';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(media.width * 0.01),
                                child: Row(
                                  children: [
                                    Container(
                                      height: media.height * 0.05,
                                      width: media.width * 0.05,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.2)),
                                      alignment: Alignment.center,
                                      child: (favName == 'Home')
                                          ? Container(
                                              height: media.width * 0.03,
                                              width: media.width * 0.03,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Container(),
                                    ),
                                    SizedBox(
                                      width: media.width * 0.01,
                                    ),
                                    Text(languages[choosenLanguage]['text_home'])
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() {
                                  favName = 'Work';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(media.width * 0.01),
                                child: Row(
                                  children: [
                                    Container(
                                      height: media.height * 0.05,
                                      width: media.width * 0.05,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.2)),
                                      alignment: Alignment.center,
                                      child: (favName == 'Work')
                                          ? Container(
                                              height: media.width * 0.03,
                                              width: media.width * 0.03,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Container(),
                                    ),
                                    SizedBox(
                                      width: media.width * 0.01,
                                    ),
                                    Text(languages[choosenLanguage]['text_work'])
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() {
                                  favName = 'Others';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(media.width * 0.01),
                                child: Row(
                                  children: [
                                    Container(
                                      height: media.height * 0.05,
                                      width: media.width * 0.05,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.2)),
                                      alignment: Alignment.center,
                                      child: (favName == 'Others')
                                          ? Container(
                                              height: media.width * 0.03,
                                              width: media.width * 0.03,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Container(),
                                    ),
                                    SizedBox(
                                      width: media.width * 0.01,
                                    ),
                                    Text(languages[choosenLanguage]['text_others'])
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        (favName == 'Others')
                            ? Container(
                                padding: EdgeInsets.all(media.width * 0.025),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderLines, width: 1.2)),
                                child: TextField(
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: languages[choosenLanguage]['text_enterfavname'],
                                      hintStyle:
                                          GoogleFonts.notoSans(fontSize: media.width * twelve, color: hintColor)),
                                  maxLines: 1,
                                  onChanged: (val) {
                                    setState(() {
                                      favNameText = val;
                                    });
                                  },
                                ),
                              )
                            : Container(),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Button(
                            onTap: () async {
                              if (favName == 'Others' && favNameText != '') {
                                setState(() {
                                  _isLoading = true;
                                });
                                var val = await addFavLocation(favLat, favLng, favSelectedAddress, favNameText);
                                setState(() {
                                  _isLoading = false;
                                  if (val == true) {
                                    favLat = '';
                                    favLng = '';
                                    favSelectedAddress = '';
                                    favNameText = '';
                                    favName = 'Home';
                                    favAddressAdd = false;
                                  } else if (val == 'logout') {
                                    navigateLogout();
                                  }
                                });
                              } else if (favName == 'Home' || favName == 'Work') {
                                setState(() {
                                  _isLoading = true;
                                });
                                var val = await addFavLocation(favLat, favLng, favSelectedAddress, favName);
                                setState(() {
                                  _isLoading = false;
                                  if (val == true) {
                                    favLat = '';
                                    favLng = '';
                                    favSelectedAddress = '';
                                    favNameText = '';
                                    favName = 'Home';
                                    favAddressAdd = false;
                                  } else if (val == 'logout') {
                                    navigateLogout();
                                  }
                                });
                              }
                            },
                            text: languages[choosenLanguage]['text_confirm'])
                      ],
                    ),
                  )
                ],
              ),
            ))
        : Container();
  }
}
