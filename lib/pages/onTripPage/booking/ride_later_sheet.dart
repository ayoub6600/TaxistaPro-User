part of '../bookingwidgets.dart';

class RideLaterBottomSheet extends StatefulWidget {
  final dynamic type;
  const RideLaterBottomSheet({super.key, this.type});

  @override
  State<RideLaterBottomSheet> createState() => _RideLaterBottomSheetState();
}

class _RideLaterBottomSheetState extends State<RideLaterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Container(
      height: media.height * 0.5,
      width: media.width * 1,
      padding: EdgeInsets.all(media.width * 0.03),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(media.width * 0.05),
              topRight: Radius.circular(media.width * 0.05))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              MyText(
                text: languages[choosenLanguage]['text_choose_date'],
                size: media.width * eighteen,
                fontweight: FontWeight.w600,
                color: Colors.blue,
              ),
              SizedBox(
                height: 20.h,
              ),
              (confirmRideLater)
                  ? Row(
                      children: [
                        InkWell(
                          onTap: () {
                            confirmRideLater = false;

                            Navigator.pop(context);
                            valueNotifierBook.incrementNotifier();
                          },
                          child: MyText(
                            text: languages[choosenLanguage]['text_reset_now'],
                            size: media.width * fourteen,
                            color: Colors.blue,
                          ),
                        )
                      ],
                    )
                  : Container(),
              Container(
                height: media.width * 0.5,
                width: media.width * 0.9,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), color: topBar),
                child: CupertinoDatePicker(
                  minimumDate: DateTime.now().add(Duration(
                      minutes: int.parse(userDetails[
                          'user_can_make_a_ride_after_x_miniutes']))),
                  initialDateTime: DateTime.now().add(Duration(
                      minutes: int.parse(userDetails[
                          'user_can_make_a_ride_after_x_miniutes']))),
                  maximumDate: DateTime.now().add(const Duration(days: 4)),
                  onDateTimeChanged: (val) {
                    setState(() {
                      choosenDateTime = val;
                      // Format the date to Arabic
                      final DateFormat arabicDateFormat =
                          DateFormat.yMMMMd('ar');
                      String formattedDate =
                          arabicDateFormat.format(choosenDateTime);
                      debugPrint(formattedDate); // Display this in your UI
                    });
                  },
                ),
              ),
            ],
          ),
          Container(
              padding: EdgeInsets.all(media.width * 0.05),
              child: Button(
                  onTap: () async {
                    setState(() {
                      confirmRideLater = true;
                    });
                    Navigator.pop(context);
                    valueNotifierBook.incrementNotifier();
                  },
                  text: languages[choosenLanguage]['text_confirm'])),
          if (!confirmRideLater && !rideLaterSuccess)
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: verifyDeclined,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MyText(
                      textAlign: TextAlign.center,
                      text: languages[choosenLanguage]['text_cancel'],
                      size: media.width * fourteen,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
