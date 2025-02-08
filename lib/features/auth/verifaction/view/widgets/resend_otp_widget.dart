import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/utils/lang_const.dart';

class ResendOtpWidget extends StatefulWidget {
  // final Map<String, dynamic> data;

  const ResendOtpWidget({
    super.key,
//    required this.data,
  });

  @override
  _ResendOtpWidgetState createState() => _ResendOtpWidgetState();
}

class _ResendOtpWidgetState extends State<ResendOtpWidget> {
  bool _isCooldownActive = false; // Initially not active
  Timer? _cooldownTimer;
  int _remainingTime = 60; // Cooldown period in seconds

  @override
  void initState() {
    super.initState();
    setState(() {
      _isCooldownActive = true; // Activate cooldown
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _stopCooldown();
      }
    });
  }

  void _startCooldown() {
    setState(() {
      _isCooldownActive = true; // Activate cooldown
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _stopCooldown();
      }
    });
  }

  void _stopCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _isCooldownActive = false;
      _remainingTime = 60;
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: RichText(
        textAlign: TextAlign.center,
        maxLines: 2,
        text: TextSpan(
          text: getTranslated(context, LangConst.doNotGetOTP).toString(),
          style: AppStyle.style12W500Black.copyWith(
            color: AppColor.mainBlack,
          ),
          children: [
            TextSpan(
              text:
                  " \n ${getTranslated(context, LangConst.resend).toString()} ",
              style: AppStyle.style12W500Black.copyWith(
                  color: _isCooldownActive ? Colors.grey : AppColor.primary,
                  decoration: TextDecoration.underline,
                  decorationColor:
                      _isCooldownActive ? Colors.grey : AppColor.primary,
                  height: 2),
              recognizer: TapGestureRecognizer()
                ..onTap = _isCooldownActive
                    ? null // Disable tap if cooldown is active
                    : () {
                        // Map<String, dynamic> body = {
                        //   'phone_no': widget.data['phone_no'],
                        //   'type': '2',
                        // };

                        // //  context.read<SendOtpCubit>().callForgot(body);
                        // print(
                        //     "---------------------->${widget.data['phone_no']}");
                        _startCooldown(); // Start cooldown
                      },
            ),
            if (_isCooldownActive)
              TextSpan(
                  text: " (${_remainingTime}s)",
                  style: AppStyle.style12W500Black.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w500,
                  )),
          ],
        ),
      ),
    );
  }
}
