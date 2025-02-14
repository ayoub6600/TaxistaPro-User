import 'package:flutter/material.dart';
import 'package:taxista/features/notification/view/widgets/notifaication_view_body.dart';

class NotifactionView extends StatelessWidget {
  const NotifactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: NotificationViewBody(),
    );
  }
}
