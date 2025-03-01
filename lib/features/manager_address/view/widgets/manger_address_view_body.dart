import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/features/manager_address/manager/manger_address_cubit.dart';
import 'package:taxista/features/manager_address/manager/manger_address_state.dart';
import 'package:taxista/features/manager_address/view/widgets/address_item.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';

class MangerAddressViewBody extends StatefulWidget {
  const MangerAddressViewBody({super.key});

  @override
  State<MangerAddressViewBody> createState() => _MangerAddressViewBodyState();
}

class _MangerAddressViewBodyState extends State<MangerAddressViewBody> {
  @override
  void initState() {
    context.read<MangerAddressCubit>().getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          CustomAppBar(
            appBarTitle: getTranslated(context, LangConst.managementAddress),
            showBack: true,
          ),
          Expanded(
            child: BlocBuilder<MangerAddressCubit, ManagerAddressState>(
              builder: (context, state) {
                switch (state.managementAddressStatus) {
                  case ManagementAddressStatus.initial:
                    return const Center(child: Text("No addresses available."));
                  case ManagementAddressStatus.submitting:
                    return const Center(child: CircularProgressIndicator());
                  case ManagementAddressStatus.error:
                    return Center(
                      child: Text(
                        state.failure?.errMessage ?? "An error occurred",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  case ManagementAddressStatus.success:
                    if (state.favouriteLocations.isEmpty) {
                      return const Center(child: Text("No saved addresses."));
                    }
                    return ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: state.favouriteLocations.length,
                      itemBuilder: (context, index) {
                        return AddressItem(
                          addressData: state.favouriteLocations[index],
                          onTap: () {},
                        );
                      },
                    );
                }
              },
            ),
          ),
          ButtonAuth(
            text: getTranslated(context, LangConst.textTapAddAddress),
            onTap: () {
              GoRouter.of(context).push(RoutesKeys.kAddAddress);
            },
          ),
        ],
      ),
    );
  }
}
