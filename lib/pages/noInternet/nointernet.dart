import 'package:flutter/material.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';

// ignore: must_be_immutable
class NoInternet extends StatefulWidget {
  dynamic onTap;
  // ignore: use_key_in_widget_constructors
  NoInternet({required this.onTap});

  @override
  State<NoInternet> createState() => _NoInternetState();
}

class _NoInternetState extends State<NoInternet> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final selectedLanguage = languages[choosenLanguage];
    final translations =
        selectedLanguage is Map ? selectedLanguage : const <String, dynamic>{};

    String translatedText(String key, String fallback) {
      final value = translations[key];
      return value is String && value.trim().isNotEmpty ? value : fallback;
    }

    return Container(
      height: media.height * 1,
      width: media.width * 1,
      color: topBar,
      padding: EdgeInsets.all(media.width * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              SizedBox(
                width: media.width * 0.6,
                child: Image.asset(
                  'assets/images/noInternet.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(
                height: media.width * 0.05,
              ),
              MyText(
                text: translatedText(
                  'text_nointernet',
                  'No Internet Connection',
                ),
                size: media.width * twentyfour,
                fontweight: FontWeight.w600,
                color: textColor,
              ),
              SizedBox(
                height: media.width * 0.05,
              ),
              MyText(
                text: translatedText(
                  'text_nointernetdesc',
                  'Please check your Internet connection and try again.',
                ),
                size: media.width * fourteen,
                color: hintColor,
              ),
              SizedBox(
                height: media.width * 0.05,
              ),
              Button(
                onTap: widget.onTap,
                text: translatedText('text_back_home', 'Try again'),
              )
            ],
          )
        ],
      ),
    );
  }
}
