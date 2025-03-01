import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_cubit.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_state.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';
import 'package:taxista/widgets_new/custom_success_toast.dart';

class ResendOtpWidget extends StatefulWidget {
  const ResendOtpWidget({
    super.key,
    required this.phone,
  });
  final String phone;

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
    return BlocConsumer<VerifyUserCubit, VerifyUserState>(
      listener: (context, state) async {
        switch (state.sendOTPtoMobileState) {
          case SendOTPtoMobileStates.initial:
            break;
          case SendOTPtoMobileStates.submitting:
            customLoadingDialog(context);
            break;
          case SendOTPtoMobileStates.error:
            Navigator.pop(context);

            showCustomErrorToast(state.failure.errMessage);
            break;
          case SendOTPtoMobileStates.success:
            {
              Navigator.pop(context);
              showCustomSuccessToast(state.modelData?.message ?? "");
            }
            break;
        }
      },
      builder: (context, state) {
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
                        : () async {
                            // Resend OTP
                            await context
                                .read<VerifyUserCubit>()
                                .sendOTPtoMobile(
                                    mobile: widget.phone, countryCode: "+218");
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
      },
    );
  }
}
