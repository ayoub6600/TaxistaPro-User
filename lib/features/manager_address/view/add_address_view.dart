import 'package:flutter/material.dart';
import 'package:taxista/features/manager_address/view/widgets/add_address_view_body.dart';

class AddAddressView extends StatelessWidget {
  const AddAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: AddAddressViewBody(),
    );
  }
}
