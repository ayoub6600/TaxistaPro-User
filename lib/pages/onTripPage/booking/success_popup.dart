part of '../bookingwidgets.dart';

class SuccessPopUp extends StatefulWidget {
  const SuccessPopUp({super.key});

  @override
  State<SuccessPopUp> createState() => _SuccessPopUpState();
}

class _SuccessPopUpState extends State<SuccessPopUp> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Container(
        height: media.width * 0.4,
        width: media.width * 1,
        padding: EdgeInsets.all(media.width * 0.05),
        decoration: BoxDecoration(
            color: page,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(media.width * 0.05),
                topRight: Radius.circular(media.width * 0.05))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
                text: languages[choosenLanguage]['text_rideLaterSuccess'],
                size: media.width * sixteen),
            Button(
                onTap: () {
                  addressList.removeWhere((element) => element.type == 'drop');
                  confirmRideLater = false;
                  ismulitipleride = false;
                  etaDetails.clear();
                  userRequestData.clear();
                  isOutStation = false;

                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Maps()),
                      (route) => false);
                },
                text: languages[choosenLanguage]['text_confirm'])
          ],
        ));
  }
}
