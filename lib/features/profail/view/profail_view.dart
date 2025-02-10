import 'package:flutter/material.dart';
import 'package:taxista/features/profail/view/widgets/profail_view_body.dart';

class ProfailView extends StatelessWidget {
  const ProfailView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: ProfailViewBody(),
    );
  }
}
