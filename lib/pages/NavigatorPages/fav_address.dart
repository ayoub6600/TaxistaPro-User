import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/loadingPage/loading.dart';
import 'package:taxista/pages/onTripPage/drop_loc_select.dart';
import 'package:taxista/styles/styles.dart';
import 'package:taxista/translations/translation.dart';
import 'package:taxista/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';

class FavAddressPage extends StatefulWidget {
  const FavAddressPage({super.key});

  @override
  State<FavAddressPage> createState() => _FavAddressPageState();
}

class _FavAddressPageState extends State<FavAddressPage> {
  TextEditingController newAddressController = TextEditingController();
  Location location = Location();
  bool _isLoading = false;

  List home = [];
  List work = [];
  List others = [];

  @override
  void initState() {
    getFavLocations();
    super.initState();
  }

  Future<void> getFavLocations() async {
    home.clear();
    work.clear();
    others.clear();
    for (var e in favAddress) {
      if (e["address_name"] == 'Work') {
        work.add(e);
      } else if (e["address_name"] == 'Home') {
        home.add(e);
      } else {
        others.add(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    return Material(
      color: page,
      child: ValueListenableBuilder(
        valueListenable: valueNotifierBook.value,
        builder: (context, value, child) {
          return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(media.width * 0.05,
                            media.width * 0.05, media.width * 0.05, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(Icons.arrow_back_ios,
                                      color: textColor),
                                ),
                                Expanded(
                                  child: Center(
                                    child: MyText(
                                      text: languages[choosenLanguage]
                                              ['text_fav_address']
                                          .toString()
                                          .toUpperCase(),
                                      size: 16.sp,
                                      fontweight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 25.h,
                            ),
                            (home.isEmpty)
                                ? Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(2, 2, 2, 8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        DropLocation(
                                                            from: 'favourite',
                                                            favName: 'Home')))
                                            .then((_) async {
                                          await getFavLocations();
                                        });
                                      },
                                      child: Container(
                                        height: media.width * 0.15,
                                        decoration: BoxDecoration(
                                          boxShadow: const [
                                            BoxShadow(
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              color: Colors.black12,
                                            )
                                          ],
                                          color: page,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Row(
                                            children: [
                                              const CircleAvatar(
                                                backgroundColor: Colors.blue,
                                                child: Icon(
                                                  Icons.home_filled,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_home'],
                                                    size:
                                                        media.width * fourteen,
                                                    fontweight: FontWeight.w500,
                                                  ),
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage][
                                                        'text_tap_add_address'],
                                                    size: media.width * ten,
                                                    fontweight: FontWeight.w500,
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              InkWell(
                                                onTap: () async {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              DropLocation(
                                                                  from:
                                                                      'favourite',
                                                                  favName:
                                                                      'Home'))).then(
                                                      (_) async {
                                                    await getFavLocations();
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.add_circle_outline,
                                                  color: (isDarkTheme == true)
                                                      ? Colors.white
                                                      : Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(2, 2, 2, 8),
                                    child: InkWell(
                                      onTap: () async {
                                        await location.requestPermission();
                                      },
                                      child: Container(
                                        height: media.width * 0.15,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color:
                                                  borderLines.withOpacity(0.5)),
                                          boxShadow: const [
                                            BoxShadow(
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              color: Colors.black12,
                                            )
                                          ],
                                          color: page,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Row(
                                            children: [
                                              const CircleAvatar(
                                                backgroundColor: Colors.blue,
                                                child: Icon(
                                                  Icons.home_filled,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              SizedBox(
                                                width: media.width * 0.5,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    MyText(
                                                      text: home[0]
                                                          ['address_name'],
                                                      size: media.width *
                                                          fourteen,
                                                      fontweight:
                                                          FontWeight.w500,
                                                    ),
                                                    MyText(
                                                      text: home[0]
                                                          ['pick_address'],
                                                      maxLines: 2,
                                                      size: media.width * ten,
                                                      fontweight:
                                                          FontWeight.w500,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              InkWell(
                                                onTap: () async {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return deleteDialoge(
                                                          context, 0, home);
                                                    },
                                                  );
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.red,
                                                  radius: 8.r,
                                                  child: Icon(Icons.close,
                                                      color: Colors.white,
                                                      size: 16.sp),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            (work.isEmpty)
                                ? Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(2, 2, 2, 8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        DropLocation(
                                                            from: 'favourite',
                                                            favName: 'Work')))
                                            .then((_) async {
                                          await getFavLocations();
                                        });
                                      },
                                      child: Container(
                                        height: media.width * 0.15,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color:
                                                  borderLines.withOpacity(0.5)),
                                          boxShadow: const [
                                            BoxShadow(
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              color: Colors.black12,
                                            )
                                          ],
                                          color: page,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.blue,
                                                child: Icon(
                                                  Icons.home_work_outlined,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_work'],
                                                    size: 14.sp,
                                                    fontweight: FontWeight.w500,
                                                  ),
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage][
                                                        'text_tap_add_address'],
                                                    size: media.width * ten,
                                                    fontweight: FontWeight.w500,
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              InkWell(
                                                onTap: () async {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              DropLocation(
                                                                  from:
                                                                      'favourite',
                                                                  favName:
                                                                      'Work'))).then(
                                                      (_) async {
                                                    await getFavLocations();
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.add_circle_outline,
                                                  color: (isDarkTheme == true)
                                                      ? Colors.white
                                                      : Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(2, 2, 2, 8),
                                    child: InkWell(
                                      onTap: () async {
                                        await location.requestPermission();
                                      },
                                      child: Container(
                                        height: media.width * 0.15,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color:
                                                  borderLines.withOpacity(0.5)),
                                          boxShadow: const [
                                            BoxShadow(
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              color: Colors.black12,
                                            )
                                          ],
                                          color: page,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Row(
                                            children: [
                                              const CircleAvatar(
                                                backgroundColor: Colors.blue,
                                                child: Icon(
                                                  Icons.home_work_outlined,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              SizedBox(
                                                width: media.width * 0.5,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    MyText(
                                                      text: work[0]
                                                          ['address_name'],
                                                      size: media.width *
                                                          fourteen,
                                                      fontweight:
                                                          FontWeight.w500,
                                                    ),
                                                    MyText(
                                                      text: work[0]
                                                          ['pick_address'],
                                                      maxLines: 2,
                                                      size: media.width * ten,
                                                      fontweight:
                                                          FontWeight.w500,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              InkWell(
                                                onTap: () async {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return deleteDialoge(
                                                          context, 0, work);
                                                    },
                                                  );
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.red,
                                                  radius: 8.r,
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16.sp,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            if (others.isNotEmpty)
                              SizedBox(
                                height: media.height * 0.8,
                                child: SingleChildScrollView(
                                  child: ListView.builder(
                                    itemCount: others.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(bottom: 30),
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            2, 2, 2, 8),
                                        child: InkWell(
                                          onTap: () async {
                                            await location.requestPermission();
                                          },
                                          child: Container(
                                            height: media.width * 0.15,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: borderLines
                                                      .withOpacity(0.5)),
                                              boxShadow: const [
                                                BoxShadow(
                                                  spreadRadius: 1,
                                                  blurRadius: 2,
                                                  color: Colors.black12,
                                                )
                                              ],
                                              color: page,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Row(
                                                children: [
                                                  const CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    child: Icon(
                                                      Icons.favorite,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  SizedBox(
                                                    width: media.width * 0.5,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        MyText(
                                                          text: others[index]
                                                              ['address_name'],
                                                          size: media.width *
                                                              fourteen,
                                                          fontweight:
                                                              FontWeight.w500,
                                                        ),
                                                        MyText(
                                                          text: others[index]
                                                              ['pick_address'],
                                                          maxLines: 2,
                                                          size:
                                                              media.width * ten,
                                                          fontweight:
                                                              FontWeight.w500,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  InkWell(
                                                    onTap: () async {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return deleteDialoge(
                                                              context,
                                                              index,
                                                              others);
                                                        },
                                                      );
                                                    },
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.red,
                                                      radius: 8.r,
                                                      child: Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 16.sp,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    (_isLoading == true)
                        ? const Positioned(child: Loading())
                        : Container(),
                    if (others.length < 4)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: Button(
                            onTap: () {
                              setState(() {
                                newAddressController.text = '';
                              });

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return addDialoge(context);
                                },
                              ).then((_) async {
                                await getFavLocations();
                              });
                            },
                            text: languages[choosenLanguage]
                                ['text_add_new_address'],
                          ),
                        ),
                      ),
                  ],
                ),
              ));
        },
      ),
    );
  }

// REMOVE DIALOGE
  AlertDialog deleteDialoge(BuildContext context, int index, List addressList) {
    final media = MediaQuery.of(context).size;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.all(20),
      backgroundColor:
          (isDarkTheme == true) ? borderLines.withOpacity(0.5) : page,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: page,
              ),
              child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.cancel_outlined,
                    color: textColor,
                  ))),
        ],
      ),
      content: MyText(
        text: languages[choosenLanguage]['text_removeFav'],
        size: media.width * sixteen,
        fontweight: FontWeight.w600,
        textAlign: TextAlign.center,
      ),
      actions: [
        Button(
            onTap: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              await removeFavAddress(addressList[index]['id']);
              // addressList.removeAt(index);
              await getFavLocations();
              setState(() {
                _isLoading = false;
              });
            },
            text: languages[choosenLanguage]['text_confirm'])
      ],
    );
  }

// ADD ADDRESS TYPE
  AlertDialog addDialoge(BuildContext context) {
    final media = MediaQuery.of(context).size;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.all(20),
      backgroundColor:
          (isDarkTheme == true) ? borderLines.withOpacity(0.3) : page,
      title: Center(
        child: Text(
          languages[choosenLanguage]['text_add_new_address_fav'],
          style: GoogleFonts.cairo(
              fontSize: media.width * twenty,
              color: textColor,
              fontWeight: FontWeight.bold),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            languages[choosenLanguage]['text_name_enter'],
            style: GoogleFonts.cairo(
                fontSize: 12.sp, color: textColor, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 5.h,
          ),
          TextField(
            controller: newAddressController,
            autofocus: false,
            maxLines: 1,
            textDirection: TextDirection.rtl,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              isCollapsed: true,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: textColor.withOpacity(0.3)),
              ),
              hintText: languages[choosenLanguage]['text_new_type_address'],
              hintStyle: GoogleFonts.cairo(
                fontSize: media.width * twelve,
                color: textColor.withOpacity(0.4),
              ),
            ),
            style: GoogleFonts.cairo(
                fontSize: media.width * fourteen,
                color: (isDarkTheme == true) ? Colors.white : textColor),
            onTap: () {},
          ),
        ],
      ),
      actions: [
        Button(
          onTap: () async {
            Navigator.pop(context);
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DropLocation(
                        from: 'favourite',
                        favName: newAddressController.text)));
            await getFavLocations();
          },
          text: 'Add',
          width: media.width * 0.25,
          height: media.width * 0.1,
        ),
      ],
    );
  }
}
