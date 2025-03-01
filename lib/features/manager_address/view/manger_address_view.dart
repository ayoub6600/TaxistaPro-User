import 'package:flutter/material.dart';
import 'package:taxista/features/manager_address/view/widgets/manger_address_view_body.dart';

class ManagerAddressView extends StatelessWidget {
  const ManagerAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: MangerAddressViewBody(),
    );
  }
}
