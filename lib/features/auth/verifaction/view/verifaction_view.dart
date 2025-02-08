import 'package:flutter/material.dart';

import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/auth/verifaction/view/widgets/verifaction_view_body.dart';

// ignore: must_be_immutable
class VerifactionView extends StatelessWidget {
  VerifactionView({
    super.key,
    required this.phone,
  });
//  final Map<String, dynamic> data;
//  bool? isForgetPass;
  final String phone;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: VerifactionViewBody(
        phone: phone,
        //  data: data,
      ),
    );
  }
}
