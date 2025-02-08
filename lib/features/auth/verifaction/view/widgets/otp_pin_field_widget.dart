import 'package:flutter/material.dart';
import 'package:otp_pin_field/otp_pin_field.dart';

class OtpPinFieldWidget extends StatelessWidget {
  final GlobalKey<OtpPinFieldState> otpPinFieldController;
  final void Function(String) onChange;
  final void Function(String) onSubmit;

  const OtpPinFieldWidget(
      {super.key,
      required this.otpPinFieldController,
      required this.onChange,
      required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: OtpPinField(
        onSubmit: onSubmit,
        key: otpPinFieldController,
        onChange: onChange,
        autoFocus: true,
        maxLength: 6,
        otpPinFieldDecoration: OtpPinFieldDecoration.defaultPinBoxDecoration,
        otpPinFieldStyle: OtpPinFieldStyle(
          activeFieldBackgroundColor: Colors.grey[200]!,
          filledFieldBackgroundColor: Colors.grey[200]!,
          defaultFieldBackgroundColor: Colors.grey[200]!,
          activeFieldBorderColor: Colors.grey[200]!,
          defaultFieldBorderColor: Colors.grey[200]!,
        ),
      ),
    );
  }
}
