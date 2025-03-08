import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../login/login.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  @override
  void initState() {
    choosenLanguage = 'ar';
    languageDirection = 'rtl';
    super.initState();
  }

//navigate
  navigate() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
        child: Directionality(
      textDirection:
          (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.fromLTRB(media.width * 0.05, media.width * 0.05,
            media.width * 0.05, media.width * 0.05),
        height: media.height * 1,
        width: media.width * 1,
        color: page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: media.width * 0.11 + MediaQuery.of(context).padding.top,
              width: media.width * 1,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              color: topBar,
              child: Stack(
                children: [
                  Container(
                    height: media.width * 0.11,
                    width: media.width * 1,
                    alignment: Alignment.center,
                    child: MyText(
                      text: (choosenLanguage.isEmpty)
                          ? 'Choose Language'
                          : languages[choosenLanguage]['text_choose_language'],
                      size: media.width * sixteen,
                      fontweight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: media.width * 0.05,
            ),
            SizedBox(
              width: media.width * 0.9,
              height: media.height * 0.4,
              child: Image.asset(
                'assets/images/selectLanguage.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              height: media.width * 0.1,
            ),
            Text(languages[choosenLanguage]['text_choose_language'],
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                )),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: languages
                      .map((i, value) => MapEntry(
                          i,
                          InkWell(
                            onTap: () {
                              setState(() {
                                choosenLanguage = i;
                                if (choosenLanguage == 'ar') {
                                  languageDirection = 'rtl';
                                } else {
                                  languageDirection = 'ltr';
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(media.width * 0.025),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  MyText(
                                    text: languagesCode
                                        .firstWhere(
                                            (e) => e['code'] == i)['name']
                                        .toString(),
                                    size: 16.sp,
                                  ),
                                  Container(
                                    height: media.width * 0.05,
                                    width: media.width * 0.05,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.blue, width: 1.2)),
                                    alignment: Alignment.center,
                                    child: (choosenLanguage == i)
                                        ? Container(
                                            height: media.width * 0.03,
                                            width: media.width * 0.03,
                                            decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blue),
                                          )
                                        : Container(),
                                  )
                                ],
                              ),
                            ),
                          )))
                      .values
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            //button
            (choosenLanguage != '')
                ? Button(
                    onTap: () async {
                      await getlangid();
                      pref.setString('languageDirection', languageDirection);
                      pref.setString('choosenLanguage', choosenLanguage);
                      navigate();
                    },
                    text: languages[choosenLanguage]['text_confirm'])
                : Container(),
          ],
        ),
      ),
    ));
  }
}
