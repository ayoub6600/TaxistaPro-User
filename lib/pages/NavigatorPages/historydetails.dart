import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../widgets/trip_contact_actions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/translations/translation.dart';

import '../../functions/functions.dart';
import '../../growth/gift_widgets.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/nointernet.dart';
import 'history.dart';
import 'adminchatpage.dart';
import '../../navigation/guarded_navigation.dart';
part 'historydetails_sections.dart';

class HistoryDetails extends StatefulWidget {
  const HistoryDetails({super.key});

  @override
  State<HistoryDetails> createState() => _HistoryDetailsState();
}

String complaintDesc = '';
int complaintType = 0;

class _HistoryDetailsState extends State<HistoryDetails> {
  String _error = '';

  @override
  void initState() {
    makecomplaint = 0;
    makecomplaintbool = false;
    _isLoading = false;
    _tripStops = myHistory[selectedHistory]['requestStops']['data'];
    getData();
    super.initState();
  }

  List _tripStops = [];

  bool _showOptions = false;

  getData() async {
    setState(() {
      complaintType = 0;
      complaintDesc = '';
      generalComplaintList = [];
    });

    await getGeneralComplaint("request");
    setState(() {
      _isLoading = false;
      if (generalComplaintList.isNotEmpty) {
        complaintType = 0;
      }
    });
  }

  bool _cancelRide = false;
  var _cancelId = '';
  int? inti;
  int makecomplaint = 0;

  /// the chat with Taxista support, the ride number (and what he already wrote) in the message box
  void _openSupport(String written) {
    final no = '${myHistory[selectedHistory]['request_number'] ?? ''}';
    final text = written.trim();
    setState(() {
      makecomplaintbool = false;
      makecomplaint = 1;
    });
    guardedPush(
        context,
        MaterialPageRoute(
            builder: (context) => AdminChatPage(
                draft: languageDirection == 'rtl'
                    ? 'عندي شكوى على الرحلة $no${text.isEmpty ? ': ' : ':\n$text'}'
                    : 'I have a complaint about ride $no${text.isEmpty ? ': ' : ':\n$text'}')));
  }

  bool isShow = false;
  bool makecomplaintbool = false;
  bool _isLoading = false;
  TextEditingController complaintText = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            _historyBody(media),
            (_cancelRide == true)
                ? Positioned(
                    child: Container(
                      height: media.height * 1,
                      width: media.width * 1,
                      color: Colors.transparent.withOpacity(0.6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: media.width * 0.9,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                    height: media.height * 0.1,
                                    width: media.width * 0.1,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: page),
                                    child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _cancelRide = false;
                                            _cancelId = '';
                                          });
                                        },
                                        child: Icon(
                                          Icons.cancel_outlined,
                                          color: textColor,
                                        ))),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(media.width * 0.05),
                            width: media.width * 0.9,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: page),
                            child: Column(
                              children: [
                                MyText(
                                  text: languages[choosenLanguage]['text_ridecancel'],
                                  size: media.width * eighteen,
                                ),
                                SizedBox(
                                  height: media.width * 0.05,
                                ),
                                Button(
                                    onTap: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var val = await cancelLaterRequest(_cancelId);
                                      if (val == 'success') {
                                        historyFiltter = '';
                                        await getHistory();
                                        // ignore: use_build_context_synchronously
                                        Navigator.pop(context);
                                      }

                                      setState(() {
                                        _cancelRide = false;
                                        _cancelId = '';
                                      });
                                    },
                                    text: languages[choosenLanguage]['text_cancel_ride'])
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
            _historyOverlay(media),
            (_isLoading == true) ? const Positioned(top: 0, child: Loading()) : Container(),
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        internetTrue();
                      },
                    ))
                : Container(),
          ],
        ),
      ),
    );
  }
}
