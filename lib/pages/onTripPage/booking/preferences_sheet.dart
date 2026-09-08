part of '../bookingwidgets.dart';

class ChoosePreferencesContainer extends StatefulWidget {
  final dynamic type;
  final dynamic onTap;
  const ChoosePreferencesContainer({super.key, this.type, required this.onTap});

  @override
  State<ChoosePreferencesContainer> createState() =>
      _ChoosePreferencesContainerState();
}

class _ChoosePreferencesContainerState
    extends State<ChoosePreferencesContainer> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Container(
      height: media.width * 0.6,
      width: media.width * 1,
      padding: EdgeInsets.all(media.width * 0.05),
      decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(media.width * 0.05),
              topRight: Radius.circular(media.width * 0.05))),
      child: Column(
        children: [
          MyText(
            text: languages[choosenLanguage]['text_choose_preference'],
            size: media.width * sixteen,
            fontweight: FontWeight.w600,
            color: Colors.blue,
          ),
          SizedBox(
            height: media.width * 0.03,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  (userDetails['enable_pet_preference_for_user'] != '1')
                      ? Container()
                      : Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (choosePets == false) {
                                    choosePets = true;
                                  } else {
                                    choosePets = false;
                                  }
                                });
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.pets,
                                        size: media.width * 0.05,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(
                                        width: media.width * 0.025,
                                      ),
                                      MyText(
                                        text: languages[choosenLanguage]
                                            ['text_pets'],
                                        size: 14.sp,
                                        fontweight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: media.width * 0.05,
                                    width: media.width * 0.05,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: theme),
                                        color: (choosePets == true)
                                            ? theme
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(100)),
                                    child: Icon(
                                      Icons.done,
                                      size: media.width * 0.035,
                                      color: (choosePets == true)
                                          ? topBar
                                          : Colors.transparent,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: media.width * 0.05,
                            ),
                          ],
                        ),
                  (userDetails['enable_luggage_preference_for_user'] != '1')
                      ? Container()
                      : Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (chooseLuggages == false) {
                                    chooseLuggages = true;
                                  } else {
                                    chooseLuggages = false;
                                  }
                                });
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: media.width * 0.05,
                                        width: media.width * 0.05,
                                        child: Image.asset(
                                          'assets/images/luggages.png',
                                          color: Colors.blue,
                                        ),
                                      ),
                                      SizedBox(
                                        width: media.width * 0.025,
                                      ),
                                      MyText(
                                        text: languages[choosenLanguage]
                                            ['text_luggages'],
                                        size: 14.sp,
                                        fontweight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: media.width * 0.05,
                                    width: media.width * 0.05,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: theme),
                                        color: (chooseLuggages == true)
                                            ? theme
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(100)),
                                    child: Icon(
                                      Icons.done,
                                      size: media.width * 0.035,
                                      color: (chooseLuggages == true)
                                          ? topBar
                                          : Colors.transparent,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          Button(
              onTap: widget.onTap,
              text: languages[choosenLanguage]['text_confirm'])
        ],
      ),
    );
  }
}
