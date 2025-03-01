import 'package:flutter/material.dart';
import 'package:taxista/features/current_location/view/widgets/current_location_body.dart';

class CurrentLocationView extends StatelessWidget {
  const CurrentLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: CurrentLocationBody(),
    );
  }
}
