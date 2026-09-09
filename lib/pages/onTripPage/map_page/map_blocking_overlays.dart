part of '../map_page.dart';

extension _MapBlockingOverlays on _MapsState {
  List<Widget> buildMapBlockingOverlays(Size media) {
    return <Widget>[
      (favAddressAdd == true)
          ? Positioned(
              top: 0,
              child: InkWell(
                onTap: () {
                  setState(() {
                    favAddressAdd = false;
                  });
                },
                child: Container(
                  height: media.height * 1,
                  width: media.width * 1,
                  color: Colors.transparent.withOpacity(0.6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            media.width * 0.05,
                            media.width * 0.05,
                            media.width * 0.05,
                            MediaQuery.of(context).viewInsets.bottom +
                                media.width * 0.05),
                        width: media.width * 1,
                        decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                            color: page),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                MyText(
                                  text: languages[choosenLanguage]
                                      ['text_add_address'],
                                  size: media.width * sixteen,
                                  fontweight: FontWeight.w600,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: media.width * 0.025,
                            ),
                            Container(
                              width: media.width * 0.9,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        spreadRadius: 2)
                                  ],
                                  color: topBar),
                              child: Row(
                                children: [
                                  Container(
                                    height: media.width * 0.064,
                                    width: media.width * 0.064,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xffFF0000)
                                            .withOpacity(0.1)),
                                    child: Icon(
                                      Icons.place,
                                      size: media.width * 0.04,
                                      color: const Color(0xffFF0000),
                                    ),
                                  ),
                                  SizedBox(
                                    width: media.width * 0.02,
                                  ),
                                  Expanded(
                                    child: Text(
                                      favSelectedAddress,
                                      style: GoogleFonts.notoSans(
                                          fontSize: media.width * twelve,
                                          fontWeight: FontWeight.w600,
                                          color: (isDarkTheme == true)
                                              ? Colors.black
                                              : textColor),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: media.width * 0.025,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    setState(() {
                                      favName = 'Home';
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                        media.width * 0.05,
                                        media.width * 0.02,
                                        media.width * 0.05,
                                        media.width * 0.02),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: (favName == 'Home')
                                              ? buttonColor
                                              : borderLines,
                                          width: 1.1),
                                      color: (favName == 'Home')
                                          ? buttonColor
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.home_outlined,
                                            size: media.width * 0.05,
                                            color: (favName == 'Home')
                                                ? (isDarkTheme == true)
                                                    ? Colors.black
                                                    : Colors.white
                                                : (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black),
                                        SizedBox(
                                          width: media.width * 0.01,
                                        ),
                                        MyText(
                                            text: languages[choosenLanguage]
                                                ['text_home'],
                                            size: media.width * twelve,
                                            color: (favName == 'Home')
                                                ? (isDarkTheme == true)
                                                    ? Colors.black
                                                    : Colors.white
                                                : (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black)
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    setState(() {
                                      favName = 'Work';
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                        media.width * 0.05,
                                        media.width * 0.02,
                                        media.width * 0.05,
                                        media.width * 0.02),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: (favName == 'Work')
                                              ? buttonColor
                                              : borderLines,
                                          width: 1.1),
                                      color: (favName == 'Work')
                                          ? buttonColor
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.work_outline_outlined,
                                            size: media.width * 0.05,
                                            color: (favName == 'Work')
                                                ? (isDarkTheme == true)
                                                    ? Colors.black
                                                    : Colors.white
                                                : (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black),
                                        SizedBox(
                                          width: media.width * 0.01,
                                        ),
                                        MyText(
                                            text: languages[choosenLanguage]
                                                ['text_work'],
                                            size: media.width * twelve,
                                            color: (favName == 'Work')
                                                ? (isDarkTheme == true)
                                                    ? Colors.black
                                                    : Colors.white
                                                : (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black)
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    setState(() {
                                      favName = 'Others';
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                        media.width * 0.05,
                                        media.width * 0.02,
                                        media.width * 0.05,
                                        media.width * 0.02),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: (favName == 'Others')
                                              ? buttonColor
                                              : borderLines,
                                          width: 1.1),
                                      color: (favName == 'Others')
                                          ? buttonColor
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.bookmark_outline,
                                            size: media.width * 0.05,
                                            color: (favName == 'Others')
                                                ? (isDarkTheme == true)
                                                    ? Colors.black
                                                    : Colors.white
                                                : (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black),
                                        SizedBox(
                                          width: media.width * 0.01,
                                        ),
                                        MyText(
                                            text: 'Create New',
                                            size: media.width * twelve,
                                            color: (favName == 'Others')
                                                ? (isDarkTheme == true)
                                                    ? Colors.black
                                                    : Colors.white
                                                : (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black)
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            (favName == 'Others')
                                ? Container(
                                    margin: EdgeInsets.only(
                                        top: media.width * 0.03),
                                    padding:
                                        EdgeInsets.all(media.width * 0.025),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: borderLines, width: 1.2)),
                                    child: TextField(
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: languages[choosenLanguage]
                                              ['text_enterfavname'],
                                          hintStyle: GoogleFonts.notoSans(
                                              fontSize: media.width * twelve,
                                              color: hintColor)),
                                      maxLines: 1,
                                      onChanged: (val) {
                                        setState(() {
                                          favNameText = val;
                                        });
                                      },
                                    ),
                                  )
                                : const SizedBox(),
                            SizedBox(
                              height: media.width * 0.05,
                            ),
                            Button(
                                onTap: () async {
                                  if (favName == 'Others' &&
                                      favNameText != '') {
                                    setState(() {
                                      _loading = true;
                                    });
                                    var val = await addFavLocation(
                                        favLat,
                                        favLng,
                                        favSelectedAddress,
                                        favNameText);
                                    setState(() {
                                      _loading = false;
                                      if (val == true) {
                                        favLat = '';
                                        favLng = '';
                                        favSelectedAddress = '';
                                        favName = 'Home';
                                        favNameText = '';
                                        favAddressAdd = false;
                                      } else if (val == 'logout') {
                                        navigateLogout();
                                      }
                                    });
                                  } else if (favName == 'Home' ||
                                      favName == 'Work') {
                                    setState(() {
                                      _loading = true;
                                    });
                                    var val = await addFavLocation(favLat,
                                        favLng, favSelectedAddress, favName);
                                    setState(() {
                                      _loading = false;
                                      if (val == true) {
                                        favLat = '';
                                        favLng = '';
                                        favName = 'Home';
                                        favSelectedAddress = '';
                                        favNameText = '';
                                        favAddressAdd = false;
                                      } else if (val == 'logout') {
                                        navigateLogout();
                                      }
                                    });
                                  }
                                },
                                text: languages[choosenLanguage]
                                    ['text_confirm'])
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ))
          : const SizedBox(),
      (requestCancelledByDriver == true)
          ? Positioned(
              top: 0,
              child: Container(
                height: media.height * 1,
                width: media.width * 1,
                color: Colors.transparent.withOpacity(0.6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: media.width * 0.9,
                      padding: EdgeInsets.all(media.width * 0.05),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), color: page),
                      child: Column(
                        children: [
                          Text(
                            languages[choosenLanguage]['text_drivercancelled'],
                            style: GoogleFonts.notoSans(
                                fontSize: media.width * fourteen,
                                fontWeight: FontWeight.w600,
                                color: textColor),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Button(
                              onTap: () {
                                setState(() {
                                  requestCancelledByDriver = false;
                                  userRequestData = {};
                                });
                              },
                              text: languages[choosenLanguage]['text_ok'])
                        ],
                      ),
                    )
                  ],
                ),
              ))
          : const SizedBox(),
      (cancelRequestByUser == true)
          ? Positioned(
              top: 0,
              child: Container(
                height: media.height * 1,
                width: media.width * 1,
                color: Colors.transparent.withOpacity(0.6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: media.width * 0.9,
                      padding: EdgeInsets.all(media.width * 0.05),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), color: page),
                      child: Column(
                        children: [
                          Text(
                            languages[choosenLanguage]['text_cancelsuccess'],
                            style: GoogleFonts.notoSans(
                                fontSize: media.width * fourteen,
                                fontWeight: FontWeight.w600,
                                color: textColor),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Button(
                              onTap: () {
                                setState(() {
                                  cancelRequestByUser = false;
                                  userRequestData = {};
                                });
                              },
                              text: languages[choosenLanguage]['text_ok'])
                        ],
                      ),
                    )
                  ],
                ),
              ))
          : const SizedBox(),
      (deleteAccount == true)
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
                              height: media.height * 0.1,
                              width: media.width * 0.1,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: page),
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      deleteAccount = false;
                                    });
                                  },
                                  child: Icon(Icons.cancel_outlined,
                                      color: textColor))),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(media.width * 0.05),
                      width: media.width * 0.9,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), color: page),
                      child: Column(
                        children: [
                          Text(
                            languages[choosenLanguage]['text_delete_confirm'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSans(
                                fontSize: media.width * sixteen,
                                color: textColor,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Button(
                              onTap: () async {
                                setState(() {
                                  deleteAccount = false;
                                  _loading = true;
                                });
                                var result = await userDelete();
                                if (result == 'success') {
                                  setState(() {
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Login()),
                                        (route) => false);
                                    userDetails.clear();
                                  });
                                } else if (result == 'logout') {
                                  navigateLogout();
                                } else {
                                  setState(() {
                                    _loading = false;
                                    deleteAccount = true;
                                  });
                                }
                                setState(() {
                                  _loading = false;
                                });
                              },
                              text: languages[choosenLanguage]['text_confirm'])
                        ],
                      ),
                    )
                  ],
                ),
              ))
          : const SizedBox(),
      (logout == true)
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
                              height: media.height * 0.1,
                              width: media.width * 0.1,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: borderLines.withOpacity(0.5)),
                                  shape: BoxShape.circle,
                                  color: page),
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      logout = false;
                                    });
                                  },
                                  child: Icon(Icons.cancel_outlined,
                                      color: textColor))),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(media.width * 0.05),
                      width: media.width * 0.9,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: borderLines.withOpacity(0.5)),
                          color: page),
                      child: Column(
                        children: [
                          Text(
                            languages[choosenLanguage]['text_confirmlogout'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSans(
                                fontSize: media.width * sixteen,
                                color: textColor,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Button(
                              onTap: () async {
                                setState(() {
                                  logout = false;
                                  _loading = true;
                                });
                                var result = await userLogout();
                                if (result == 'success' || result == 'logout') {
                                  setState(() {
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Login()),
                                        (route) => false);
                                    userDetails.clear();
                                  });
                                } else {
                                  setState(() {
                                    _loading = false;
                                    logout = true;
                                  });
                                }
                                setState(() {
                                  _loading = false;
                                });
                              },
                              text: languages[choosenLanguage]['text_confirm'])
                        ],
                      ),
                    )
                  ],
                ),
              ))
          : const SizedBox(),
      (_locationDenied == true)
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
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 2.0,
                              spreadRadius: 2.0,
                              color: Colors.black.withOpacity(0.2))
                        ]),
                    child: Column(
                      children: [
                        SizedBox(
                            width: media.width * 0.8,
                            child: Text(
                              languages[choosenLanguage]
                                  ['text_open_loc_settings'],
                              style: GoogleFonts.notoSans(
                                  fontSize: media.width * sixteen,
                                  color: textColor,
                                  fontWeight: FontWeight.w600),
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
                                  languages[choosenLanguage]
                                      ['text_open_settings'],
                                  style: GoogleFonts.notoSans(
                                      fontSize: media.width * sixteen,
                                      color: buttonColor,
                                      fontWeight: FontWeight.w600),
                                )),
                            InkWell(
                                onTap: () async {
                                  setState(() {
                                    _locationDenied = false;
                                    _loading = true;
                                  });

                                  getLocs();
                                },
                                child: Text(
                                  languages[choosenLanguage]['text_done'],
                                  style: GoogleFonts.notoSans(
                                      fontSize: media.width * sixteen,
                                      color: buttonColor,
                                      fontWeight: FontWeight.w600),
                                ))
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ))
          : const SizedBox(),
    ];
  }
}
