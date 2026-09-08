import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation.dart';
import 'package:taxista/pages/onTripPage/choosegoods.dart';
import 'package:taxista/pages/onTripPage/map_page.dart';
import 'package:taxista/styles/styles.dart';
import 'package:taxista/translations/translation.dart';
import 'package:taxista/widgets/widgets.dart';

part 'booking/apply_coupons.dart';
part 'booking/bid_metadata.dart';
part 'booking/create_request_sheet.dart';
part 'booking/create_request_actions.dart';
part 'booking/request_result_handler.dart';
part 'booking/fare_breakup.dart';
part 'booking/payment_method_sheet_legacy.dart';
part 'booking/preferences_sheet.dart';
part 'booking/ride_later_sheet.dart';
part 'booking/success_popup.dart';
part 'booking/vehicle_info_sheet.dart';
