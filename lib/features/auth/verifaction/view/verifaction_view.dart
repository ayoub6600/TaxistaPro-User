import 'package:flutter/material.dart';

import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/auth/verifaction/view/widgets/verifaction_view_body.dart';

class VerifactionView extends StatelessWidget {
  const VerifactionView({
    super.key,
    required this.phone,
  });

  final String phone;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: VerifactionViewBody(
        phone: phone,
      ),
    );
  }
}
