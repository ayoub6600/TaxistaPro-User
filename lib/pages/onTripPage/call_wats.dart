import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallWhatsAppButton extends StatelessWidget {
  final String phoneNumber; // لازم يكون الرقم بصيغة دولية بدون +

  const CallWhatsAppButton({super.key, required this.phoneNumber});

  void openWhatsApp(String phone) async {
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phone");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ Can't open WhatsApp for number: $phone");
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return InkWell(
      onTap: () => openWhatsApp(phoneNumber),
      child: Container(
        height: media.width * 0.096,
        width: media.width * 0.096,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff5BDD0A), width: 1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Image.asset(
          "assets/images/mobile2.png", // تقدر تغيرها لأيقونة واتساب لو حابب
          //  color: const Color(0xff5BDD0A),
          height: media.width * 0.05,
          width: media.width * 0.05,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
