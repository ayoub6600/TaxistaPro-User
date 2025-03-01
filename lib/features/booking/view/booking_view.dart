import 'package:flutter/material.dart';
import 'package:taxista/features/booking/view/widgets/booking_view_body.dart';

class BookingView extends StatelessWidget {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: BooKingViewBody(),
    );
  }
}
