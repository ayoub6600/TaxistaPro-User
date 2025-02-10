import 'package:flutter/material.dart';
import 'package:taxista/features/edit_profail.dart/view/widget/edit_profail_view_body.dart';

class EditProfail extends StatelessWidget {
  const EditProfail({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: EditProfailViewBody(),
    );
  }
}
