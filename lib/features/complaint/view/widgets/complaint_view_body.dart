import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/complaint/manager/complaint_cubit.dart';
import 'package:taxista/features/complaint/manager/complaint_state.dart';
import 'package:taxista/features/complaint/view/widgets/complaint_scima.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custm_text_form_review.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';
import 'package:taxista/widgets_new/delete_account_modal.dart';
import 'package:taxista/widgets_new/error_state_widget.dart';

class ComplaintViewBody extends StatefulWidget {
  const ComplaintViewBody({super.key});

  @override
  State<ComplaintViewBody> createState() => _ComplaintViewBodyState();
}

class _ComplaintViewBodyState extends State<ComplaintViewBody> {
  int? selectedReasonIndex;
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      context.read<ComplaintCubit>().getcomplaint();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          CustomAppBar(
            appBarTitle: getTranslated(context, LangConst.textMakeComplaint),
            showBack: true,
          ),
          const SizedBox(height: 20),
          BlocBuilder<ComplaintCubit, ComplaintState>(
            builder: (context, state) {
              switch (state.status) {
                case ComplaintStatus.initial:
                case ComplaintStatus.loading:
                  return const ComplaintShimmer();
                case ComplaintStatus.loaded:
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            getTranslated(
                                context, LangConst.textChooseComplaint),
                            style: AppStyle.style16W500Black,
                          ),
                          for (var reason in state.complaints)
                            RadioListTile<int>(
                              title: Text(
                                reason.title,
                                style: AppStyle.style16W500Black,
                              ),
                              activeColor: AppColor.primary,
                              hoverColor: AppColor.darkGrey,
                              contentPadding: EdgeInsets.zero,
                              value: state.complaints.indexOf(reason),
                              groupValue: selectedReasonIndex,
                              onChanged: (value) {
                                setState(() {
                                  selectedReasonIndex = value;
                                });
                              },
                            ),
                          Container(
                            color: AppColor.grey,
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            height: 0.5.h,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              getTranslated(
                                  context, LangConst.textdescriptioncomplaint),
                              textAlign: TextAlign.center,
                              style: AppStyle.style12W500Black.copyWith(
                                color: AppColor.mainBlack,
                              ),
                            ),
                          ),
                          Container(
                            color: const Color(0xFFF6F6F6),
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            child: CustomTextFormFieldReview(
                              hint: getTranslated(
                                  context, LangConst.textComplaint),
                              txtController: state.descriptionController,
                              // context.read<CancelCubit>().commentController,
                              maxLines: 6,
                            ),
                          ),
                          BlocConsumer<ComplaintCubit, ComplaintState>(
                            listener: (context, state) {
                              switch (state.sendcomplaintStatus) {
                                case SendcomplaintStatus.initial:
                                  break;
                                case SendcomplaintStatus.loading:
                                  customLoadingDialog(context);
                                  break;
                                case SendcomplaintStatus.error:
                                  Navigator.pop(context);
                                  showCustomErrorToast(state.errorMessage);
                                  break;
                                case SendcomplaintStatus.loaded:
                                  Navigator.pop(context);

                                  GoRouter.of(context).go(RoutesKeys.kHome);
                                  break;
                              }
                            },
                            builder: (context, state) {
                              return ButtonAuth(
                                text:
                                    getTranslated(context, LangConst.textSend),
                                onTap: () {
                                  if (selectedReasonIndex != null) {
                                    showModalBottomSheet(
                                      backgroundColor: Colors.transparent,
                                      context: context,
                                      builder: (context2) => CustmBootomModel(
                                        buttonTextok: getTranslated(
                                            context, LangConst.textConfirm),
                                        title: getTranslated(context,
                                            LangConst.textMakeComplaint),
                                        subTitle: getTranslated(
                                            context,
                                            LangConst
                                                .textAreYouSureYouWantToMakeAComplaint),
                                        onTapOk: () {
                                          Navigator.pop(context);

                                          context
                                              .read<ComplaintCubit>()
                                              .sendComplaint(
                                                id: state
                                                    .complaints[
                                                        selectedReasonIndex!]
                                                    .id,
                                                description: state
                                                    .descriptionController.text,
                                              );
                                        },
                                      ),
                                    );
                                  } else {
                                    showCustomErrorToast('pleaseSelectAReason');
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                case ComplaintStatus.error:
                  showCustomErrorToast(state.errorMessage);
                  return ErrorStateWidget(
                    subTitle: state.errorMessage,
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}
