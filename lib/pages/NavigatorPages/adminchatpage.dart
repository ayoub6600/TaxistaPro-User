import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/calls/admin_call_controller.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../functions/support_chat_link.dart';
import '../../widgets/support_call_card.dart';
import '../../widgets/voice/voice_bubble.dart';
import '../../widgets/voice/voice_send.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';

class AdminChatPage extends StatefulWidget {
  /// Opened from a notification: the message to bring into view (and briefly highlight).
  final int? focusMessageId;

  const AdminChatPage({super.key, this.focusMessageId});

  /// Whether the chat with the administration is on screen (a tapped notification reuses it).
  static bool get isOpen => adminChatPagesOpen > 0;

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

String adminChatmessage = '';

class _AdminChatPageState extends State<AdminChatPage> {
  TextEditingController adminchatText = TextEditingController();
  ScrollController controller = ScrollController();
  bool _loading = false;
  bool contactus = false;

  /// The call button: a voice call inside the app; when no admin takes calls right now, the
  /// support phone numbers as before.
  Future<void> _callAdministration() async {
    final problem = await AdminCallController.instance.callAdministration();
    if (problem == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem), behavior: SnackBarBehavior.floating));
    setState(() => contactus = true);
  }

  Future<void> _sendVoice() async {
    final sent = await VoiceSend.recordAndSend(context, endpoint: 'send-voice-message',
        fields: {if (chatid != null) 'chat_id': chatid.toString()});
    if (sent == null) return;
    chatid = sent['chat_id'] ?? chatid;
    isnewchat = 0;
    await getadminCurrentMessages();
    if (mounted) setState(() {});
  }
  // the message a notification pointed at: scrolled into view once loaded, outlined for a moment
  final GlobalKey _focusKey = GlobalKey();
  int? _focusId;
  int? _highlightId;
  Timer? _highlightTimer;

  @override
  void initState() {
    adminChatPagesOpen++;
    _focusId = widget.focusMessageId;
    SupportChatLink.focus.addListener(_onFocusRequest);
    //get messages
    _loading = true;
    getmessage();
    super.initState();
  }

  @override
  void dispose() {
    adminChatPagesOpen--;
    SupportChatLink.focus.removeListener(_onFocusRequest);
    _highlightTimer?.cancel();
    super.dispose();
  }

  /// A notification tapped while this page is open: reload and show that message.
  Future<void> _onFocusRequest() async {
    final id = SupportChatLink.focus.value;
    if (id == null) return;
    _focusId = id;
    await getadminCurrentMessages();
    if (mounted) valueNotifierChat.incrementNotifier();
  }

  /// After a build: the focused message into view (once), otherwise the newest at the bottom.
  void _scrollAfterBuild() {
    final target = _focusKey.currentContext;
    if (_focusId != null && target != null) {
      final id = _focusId;
      _focusId = null;
      Scrollable.ensureVisible(target, alignment: 0.4, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      setState(() => _highlightId = id);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _highlightId = null);
      });
      return;
    }
    if (_focusId != null && !_loading) _focusId = null; // not in the history (deleted, or another chat)
    if (controller.hasClients) {
      controller.animateTo(controller.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  Future<void> _callBack() => _callAdministration();

  getmessage() async {
    adminChatList.clear();
    if (chatid != null && unSeenChatCount != '0') {
      adminmessageseen();
    }
    var result = await getadminCurrentMessages();
    if (result == 'success') {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Directionality(
      textDirection: (languageDirection == 'rtl')
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: PopScope(
          canPop: true,
          // ignore: deprecated_member_use
          onPopInvoked: (didPop) {
            unSeenChatCount = '0';
            if (chatid != null) {
              adminmessageseen();
            }
            // Navigator.pop(context, true);
            valueNotifierChat.incrementNotifier();
          },
          child: Material(
            child: Scaffold(
              body: ValueListenableBuilder(
                  valueListenable: valueNotifierChat.value,
                  builder: (context, value, child) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _scrollAfterBuild();
                    });
                    //call for message seen
                    // messageSeen();

                    return Directionality(
                      textDirection: (languageDirection == 'rtl')
                          ? ui.TextDirection.rtl
                          : ui.TextDirection.ltr,
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(
                                media.width * 0.05,
                                MediaQuery.of(context).padding.top +
                                    media.width * 0.05,
                                media.width * 0.05,
                                media.width * 0.05),
                            height: media.height * 1,
                            width: media.width * 1,
                            color: page,
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                        width: media.width * 0.9,
                                        alignment: Alignment.center,
                                        child: Column(
                                          children: [
                                            MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_admin_chat'],
                                              size: media.width * sixteen,
                                              fontweight: FontWeight.bold,
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                          ],
                                        )),
                                    Positioned(
                                      left: media.width * 0.05,
                                      child: InkWell(
                                        onTap: _callAdministration,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.green,
                                          radius: 15.r,
                                          // height: media.width * 0.1,
                                          // width: media.width,
                                          // alignment: Alignment.centerLeft,
                                          child: const Icon(
                                            Icons.call,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      child: InkWell(
                                        onTap: () {
                                          unSeenChatCount = '0';
                                          if (chatid != null &&
                                              unSeenChatCount != '0') {
                                            adminmessageseen();
                                          }
                                          valueNotifierChat.incrementNotifier();
                                          Navigator.pop(context, true);
                                        },
                                        child: Container(
                                          height: media.width * 0.1,
                                          width: media.width * 0.1,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.arrow_back_ios,
                                              color: textColor),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: media.width * 0.05,
                                ),
                                Expanded(
                                    child: SingleChildScrollView(
                                  controller: controller,
                                  child: Column(
                                    children: adminChatList
                                        .asMap()
                                        .map((i, value) {
                                          final messageId = int.tryParse('${adminChatList[i]['id'] ?? ''}');
                                          final focused = messageId != null && (messageId == _focusId || messageId == _highlightId);
                                          // a call with the administration: a card in the middle, with "call again"
                                          final callCard = SupportCallCard.fromMessage(adminChatList[i],
                                              highlighted: messageId != null && messageId == _highlightId, onCallBack: _callBack);
                                          if (callCard != null) {
                                            return MapEntry(i, Container(key: focused ? _focusKey : null, width: media.width * 0.9, alignment: Alignment.center, child: callCard));
                                          }
                                          return MapEntry(
                                              i,
                                              Container(
                                                key: focused ? _focusKey : null,
                                                padding: EdgeInsets.only(
                                                    top: media.width * 0.01),
                                                width: media.width * 0.9,
                                                alignment: (adminChatList[i]
                                                                ['from_id']
                                                            .toString() ==
                                                        userDetails['id']
                                                            .toString())
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      (adminChatList[i][
                                                                      'from_id']
                                                                  .toString() ==
                                                              userDetails['id']
                                                                  .toString())
                                                          ? CrossAxisAlignment
                                                              .end
                                                          : CrossAxisAlignment
                                                              .start,
                                                  children: [
                                                    Card(
                                                      elevation: 5,
                                                      shape: messageId != null && messageId == _highlightId
                                                          ? RoundedRectangleBorder(
                                                              side: const BorderSide(color: Color(0xFFF59E0B), width: 2),
                                                              borderRadius: BorderRadius.circular(media.width * 0.02))
                                                          : null,
                                                      child: Container(
                                                        width: adminChatList[i]['message_type'] == 'voice'
                                                            ? null
                                                            : media.width * 0.5,
                                                        padding: EdgeInsets.all(
                                                            media.width * 0.03),
                                                        decoration:
                                                            BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .only(
                                                                  topLeft: (adminChatList[i]['from_id']
                                                                              .toString() ==
                                                                          userDetails['id']
                                                                              .toString())
                                                                      ? Radius.circular(
                                                                          media.width *
                                                                              0.02)
                                                                      : const Radius
                                                                          .circular(
                                                                          0),
                                                                  topRight: (adminChatList[i]['from_id']
                                                                              .toString() ==
                                                                          userDetails['id']
                                                                              .toString())
                                                                      ? const Radius
                                                                          .circular(
                                                                          0)
                                                                      : Radius.circular(
                                                                          media.width *
                                                                              0.02),
                                                                  bottomRight: Radius
                                                                      .circular(
                                                                          media.width *
                                                                              0.02),
                                                                  bottomLeft: Radius
                                                                      .circular(
                                                                          media.width *
                                                                              0.02),
                                                                ),
                                                                color: (adminChatList[i]['from_id']
                                                                            .toString() ==
                                                                        userDetails['id']
                                                                            .toString())
                                                                    ? buttonColor
                                                                    : const Color(
                                                                        0xffE7EDEF)),
                                                        child: VoiceBubble.fromMessage(adminChatList[i],
                                                                mine: adminChatList[i]['from_id'].toString() == userDetails['id'].toString()) ??
                                                            MyText(
                                                            text:
                                                                adminChatList[i]
                                                                    ['message'],
                                                            size: media.width *
                                                                fourteen,
                                                            color: (isDarkTheme ==
                                                                    true)
                                                                ? Colors.black
                                                                // : textColor,
                                                                : (adminChatList[i]['from_id']
                                                                            .toString() ==
                                                                        userDetails['id']
                                                                            .toString())
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.01,
                                                    ),
                                                    MyText(
                                                      text: adminChatList[i]
                                                          ['user_timezone'],
                                                      size: media.width * ten,
                                                    )
                                                  ],
                                                ),
                                              ));
                                        })
                                        .values
                                        .toList(),
                                  ),
                                )),

                                //text field
                                Container(
                                  margin:
                                      EdgeInsets.only(top: media.width * 0.025),
                                  padding: EdgeInsets.fromLTRB(
                                      media.width * 0.025,
                                      media.width * 0.01,
                                      media.width * 0.025,
                                      media.width * 0.01),
                                  width: media.width * 0.9,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: borderLines, width: 1.2),
                                      color: page),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (adminchatText.text.isEmpty)
                                        Semantics(
                                          button: true,
                                          label: 'تسجيل رسالة صوتية',
                                          child: InkWell(
                                            onTap: _sendVoice,
                                            child: const CircleAvatar(
                                              backgroundColor: Colors.blue,
                                              child: Icon(Icons.mic, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      if (adminchatText.text.isNotEmpty)
                                        InkWell(
                                          onTap: () async {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();

                                            setState(() {
                                              _loading = true;
                                            });
                                            adminchatText.clear();
                                            var val = await sendadminMessage(
                                                adminChatmessage);
                                            if (val == 'success') {
                                              setState(() {
                                                _loading = false;
                                              });
                                            }
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            child: Image.asset(
                                              'assets/images/send.png',
                                              fit: BoxFit.contain,
                                              width: media.width * 0.075,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        width: media.width * 0.7,
                                        child: TextField(
                                          controller: adminchatText,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: languages[choosenLanguage]
                                                ['text_entermessage'],
                                            hintStyle: GoogleFonts.notoSans(
                                              color: textColor.withOpacity(0.4),
                                              fontSize: media.width * twelve,
                                            ),
                                          ),
                                          style: GoogleFonts.notoSans(
                                            color: textColor,
                                          ),
                                          minLines: 1,
                                          maxLines: 4,
                                          onChanged: (val) {
                                            setState(() {
                                              adminChatmessage =
                                                  adminchatText.text;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          (contactus == true)
                              ? Positioned(
                                  right: 10,
                                  top: 110,
                                  child: InkWell(
                                    onTap: () async {},
                                    child: Container(
                                        padding: const EdgeInsets.all(10),
                                        height: media.width * 0.3,
                                        width: media.width * 0.45,
                                        decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 2,
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2)
                                            ],
                                            color: page,
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.02)),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                makingPhoneCall(userDetails[
                                                    'contact_us_mobile1']);
                                              },
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                      flex: 20,
                                                      child: Icon(
                                                        Icons.call,
                                                        color: textColor,
                                                      )),
                                                  Expanded(
                                                      flex: 80,
                                                      child: Text(
                                                        userDetails[
                                                            'contact_us_mobile1'],
                                                        style: GoogleFonts
                                                            .notoSans(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor),
                                                      ))
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                makingPhoneCall(userDetails[
                                                    'contact_us_mobile1']);
                                              },
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                      flex: 20,
                                                      child: Icon(Icons.call,
                                                          color: textColor)),
                                                  Expanded(
                                                      flex: 80,
                                                      child: Text(
                                                        userDetails[
                                                            'contact_us_mobile2'],
                                                        style: GoogleFonts
                                                            .notoSans(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor),
                                                      ))
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                openBrowser(userDetails[
                                                        'contact_us_link']
                                                    .toString());
                                              },
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                      flex: 20,
                                                      child: Icon(
                                                          Icons
                                                              .vpn_lock_rounded,
                                                          color: textColor)),
                                                  Expanded(
                                                      flex: 80,
                                                      child: Text(
                                                        languages[
                                                                choosenLanguage]
                                                            ['text_goto_url'],
                                                        maxLines: 1,
                                                        style: GoogleFonts
                                                            .notoSans(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor),
                                                      ))
                                                ],
                                              ),
                                            )
                                          ],
                                        )),
                                  ),
                                )
                              : Container(),
                          //loader
                          (_loading == true)
                              ? const Positioned(top: 0, child: Loading())
                              : Container()
                        ],
                      ),
                    );
                  }),
            ),
          )),
    );
  }
}
