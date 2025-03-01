import 'package:flutter/material.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/auth/set_new_pass/view/widgets/set_new_pass_view_body.dart';

class SetNewPassView extends StatelessWidget {
  const SetNewPassView({
    super.key,
    required this.phone,
  });
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SetNewPassViewBody(
        phone: phone,
      ),
    );
  }
}
