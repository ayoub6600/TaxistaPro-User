import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/constants/app_color.dart';

class AppStyle {
  static TextStyle style10W500Black = TextStyle(
    color: AppColor.primary,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static TextStyle style12W500Black = GoogleFonts.cairo(
    color: AppColor.mainBlack,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
  );

  static TextStyle style16W500Black =
      GoogleFonts.cairo(fontSize: 16, color: Colors.black);
  static TextStyle style18W500Black =
      GoogleFonts.cairo(fontSize: 16, color: Colors.black);
  static TextStyle style14W500Black = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColor.darkGrey,
  );
  static TextStyle style15W500Black = GoogleFonts.cairo(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColor.mainBlack,
  );
  static TextStyle style14W500hepo = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColor.darkGrey,
  );

  static TextStyle style22W500Black = TextStyle(
    color: AppColor.mainBlack,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );
  static TextStyle style24W500Black = TextStyle(
    color: AppColor.mainBlack,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  //Heebo
  static TextStyle style16W500hepo = GoogleFonts.cairo(
    color: AppColor.mainBlack,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  //Inter
  static TextStyle style18W500Inter = GoogleFonts.cairo(
    color: AppColor.mainBlack,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
}
