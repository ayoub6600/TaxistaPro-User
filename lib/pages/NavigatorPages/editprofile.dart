import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:taxista/translations/translation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/v2_sheet.dart';
import '../login/login.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

dynamic profileImageFile;

class _EditProfileState extends State<EditProfile> {
  ImagePicker picker = ImagePicker();
  bool _isLoading = false;
  String _error = '';
  bool _pickImage = false;
  String _permission = '';
  bool showToast = false;
  TextEditingController name = TextEditingController();
  TextEditingController lastname = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController mobilenum = TextEditingController();
  TextEditingController usergender = TextEditingController();
  bool islastname = false;

//get gallery permission
  getGalleryPermission() async {
    dynamic status;
    if (platform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        status = await Permission.storage.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.storage.request();
        }

        /// use [Permissions.storage.status]
      } else {
        // Android 13+: image_picker uses the system photo picker, which needs no
        // media permission (and the app no longer declares READ_MEDIA_IMAGES).
        status = PermissionStatus.granted;
      }
    } else {
      status = await Permission.photos.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.photos.request();
      }
    }
    return status;
  }

  bool isEdit = false;

  showToastFunc() {
    setState(() {
      showToast = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showToast = false;
        });
      }
    });
  }

  navigateLogout() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false);
    });
  }

//get camera permission
  getCameraPermission() async {
    var status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.camera.request();
    }
    return status;
  }

//pick image from gallery
  pickImageFromGallery() async {
    var permission = await getGalleryPermission();
    if (permission == PermissionStatus.granted) {
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      setState(() {
        profileImageFile = pickedFile?.path;
        _pickImage = false;
      });
    } else {
      setState(() {
        _permission = 'noPhotos';
      });
    }
  }

//pick image from camera
  pickImageFromCamera() async {
    var permission = await getCameraPermission();
    if (permission == PermissionStatus.granted) {
      final pickedFile =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      setState(() {
        profileImageFile = pickedFile?.path;
        _pickImage = false;
      });
    } else {
      setState(() {
        _permission = 'noCamera';
      });
    }
  }

  String _initialName = '';
  String _initialEmail = '';
  String _initialGender = '';
  bool _saving = false;

  bool get _rtl => languageDirection == 'rtl';

  bool get _changed =>
      profileImageFile != null ||
      name.text.trim() != _initialName ||
      _cleanEmail(email.text) != _initialEmail ||
      usergender.text != _initialGender;

  @override
  void initState() {
    super.initState();
    _error = '';
    profileImageFile = null;
    // the real values only: an empty field shows its hint (never «غير محدد» typed into it)
    final full = '${userDetails['name'] ?? ''}'.trim();
    name.text = full == 'null' ? '' : full;
    mobilenum.text = '${userDetails['mobile'] ?? ''}';
    final mail = '${userDetails['email'] ?? ''}'.trim();
    email.text = mail == 'null' ? '' : mail;
    final g = '${userDetails['gender'] ?? ''}';
    usergender.text = (g == 'male' || g == 'female') ? g : '';
    _initialName = name.text.trim();
    _initialEmail = _cleanEmail(email.text);
    _initialGender = usergender.text;
    for (final c in [name, email]) {
      c.addListener(() {
        // a message about the old value goes as soon as he edits (e.g. he cleared the email)
        if (mounted) setState(() => _error = '');
      });
    }
  }

  pop() {
    Navigator.pop(context, true);
  }

  static String _cleanEmail(String v) => v.replaceAll(RegExp(r'[\s\u00A0\u200B-\u200F\u202A-\u202E\u2060\uFEFF]'), '');

  static final _emailPattern = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$");

  /// «ahmed@» → gmail.com, yahoo.com… one tap completes the address
  List<String> get _emailSuggestions {
    final t = email.text.trim();
    final at = t.indexOf('@');
    if (at <= 0) return const [];
    final user = t.substring(0, at);
    final typed = t.substring(at + 1).toLowerCase();
    const domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'icloud.com'];
    return [
      for (final d in domains)
        if (d.startsWith(typed) && d != typed) '$user@$d',
    ];
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    // spaces and invisible marks the keyboard can leave (RTL marks, zero-width, no-break space)
    final mail = _cleanEmail(email.text);
    setState(() => _error = '');
    if (name.text.trim().length < 2) {
      setState(() => _error = _rtl ? 'اكتب اسمك (حرفين على الأقل)' : 'Write your name');
      return;
    }
    // the email is optional: empty is fine; only a written one must look like an email
    if (mail.isNotEmpty && !_emailPattern.hasMatch(mail)) {
      setState(() => _error = languages[choosenLanguage]['text_email_validation'] ?? '');
      return;
    }
    setState(() => _saving = true);
    if (mail.isNotEmpty && mail != _initialEmail) {
      final taken = await validateEmail(mail);
      if (!mounted) return;
      if (taken != 'success') {
        setState(() {
          _saving = false;
          _error = '${taken ?? (_rtl ? 'ما قدرناش نتأكد من البريد' : 'Could not check the email')}';
        });
        return;
      }
    }
    // updateProfile reads the global gender
    gender = usergender.text;
    final nav = await updateProfile(name.text.trim(), mail, usergender.text);
    if (!mounted) return;
    if (nav == 'logout') {
      navigateLogout();
      return;
    }
    if (nav != 'success') {
      setState(() {
        _saving = false;
        _error = '${nav ?? (_rtl ? 'ما تمش الحفظ. جرب مرة ثانية.' : 'Not saved. Try again.')}';
      });
      return;
    }
    setState(() {
      _saving = false;
      profileImageFile = null;
      _initialName = name.text.trim();
      _initialEmail = mail;
      _initialGender = usergender.text;
    });
    showToastFunc();
  }

  void _choosePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => V2SheetFrame(
        title: _rtl ? 'صورتك' : 'Your photo',
        subtitle: _rtl ? 'السائق يشوفها باش يعرفك وقت الركوب' : 'Your driver sees it at pickup',
        icon: Icons.photo_camera_outlined,
        child: Column(children: [
          V2OptionRow(
            title: _rtl ? 'التقط صورة' : 'Take a photo',
            icon: Icons.photo_camera_outlined,
            selected: false,
            trailing: Icon(_rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: textColor.withValues(alpha: .4)),
            onTap: () async {
              Navigator.pop(ctx);
              await pickImageFromCamera();
              _permissionHint();
            },
          ),
          V2OptionRow(
            title: _rtl ? 'اختر من الصور' : 'Choose from photos',
            icon: Icons.photo_library_outlined,
            selected: false,
            trailing: Icon(_rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: textColor.withValues(alpha: .4)),
            onTap: () async {
              Navigator.pop(ctx);
              await pickImageFromGallery();
              _permissionHint();
            },
          ),
        ]),
      ),
    );
  }

  void _permissionHint() {
    if (_permission.isEmpty || !mounted) return;
    final camera = _permission == 'noCamera';
    _permission = '';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(camera
          ? (_rtl ? 'اسمح لتاكسيستا بالكاميرا من الإعدادات' : 'Allow the camera in Settings')
          : (_rtl ? 'اسمح لتاكسيستا بالصور من الإعدادات' : 'Allow photos in Settings')),
      action: SnackBarAction(label: _rtl ? 'الإعدادات' : 'Settings', onPressed: openAppSettings),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final picture = '${userDetails['profile_picture'] ?? ''}';
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: page,
        body: Stack(children: [
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: pop,
                    icon: Icon(Icons.arrow_back_rounded, color: textColor),
                    style: IconButton.styleFrom(backgroundColor: textColor.withValues(alpha: .05), fixedSize: const Size(44, 44)),
                  ),
                  const SizedBox(width: 8),
                  Text(_rtl ? 'معلوماتي' : 'My details',
                      style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800)),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
                  // the photo: tap it to change (camera or photos)
                  Center(
                    child: GestureDetector(
                      onTap: _choosePhoto,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xff0873FF).withValues(alpha: .25), width: 3),
                            image: profileImageFile != null
                                ? DecorationImage(image: FileImage(File(profileImageFile)), fit: BoxFit.cover)
                                : (picture.isNotEmpty ? DecorationImage(image: NetworkImage(picture), fit: BoxFit.cover) : null),
                            color: const Color(0xffEAF4FF),
                          ),
                          child: (profileImageFile == null && picture.isEmpty)
                              ? const Icon(Icons.person_rounded, size: 56, color: Color(0xff0873FF))
                              : null,
                        ),
                        PositionedDirectional(
                          bottom: 2,
                          end: 2,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xff0873FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: page, width: 3),
                            ),
                            child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 17),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _choosePhoto,
                      child: Text(picture.isEmpty && profileImageFile == null ? (_rtl ? 'أضف صورتك' : 'Add your photo') : (_rtl ? 'غيّر الصورة' : 'Change photo'),
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: const Color(0xff0873FF))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _field(label: _rtl ? 'الاسم' : 'Name', controller: name, icon: Icons.person_outline_rounded, hint: _rtl ? 'اسمك' : 'Your name'),
                  _field(
                    label: _rtl ? 'رقم الهاتف' : 'Phone',
                    controller: mobilenum,
                    icon: Icons.phone_iphone_rounded,
                    readOnly: true,
                    ltr: true,
                    note: _rtl ? 'الرقم يتغير من الدعم فقط' : 'Changed only through support',
                  ),
                  _field(
                    label: _rtl ? 'البريد الإلكتروني (اختياري)' : 'Email (optional)',
                    controller: email,
                    icon: Icons.alternate_email_rounded,
                    hint: 'name@gmail.com',
                    ltr: true,
                    keyboard: TextInputType.emailAddress,
                  ),
                  if (_emailSuggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final sgt in _emailSuggestions.take(3))
                          ActionChip(
                            label: Text(sgt, textDirection: TextDirection.ltr, style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600)),
                            avatar: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xff0873FF)),
                            backgroundColor: const Color(0xff0873FF).withValues(alpha: .07),
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            onPressed: () {
                              email.text = sgt;
                              email.selection = TextSelection.collapsed(offset: sgt.length);
                            },
                          ),
                      ]),
                    ),
                  Text(_rtl ? 'الجنس (اختياري)' : 'Gender (optional)',
                      style: GoogleFonts.cairo(color: textColor.withValues(alpha: .65), fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(children: [
                    for (final g in const ['male', 'female']) ...[
                      Expanded(
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              languages[choosenLanguage][g == 'male' ? 'text_male' : 'text_female'] ?? g,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: usergender.text == g ? Colors.white : textColor),
                            ),
                          ),
                          selected: usergender.text == g,
                          showCheckmark: false,
                          selectedColor: const Color(0xff0873FF),
                          backgroundColor: textColor.withValues(alpha: .05),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (_) => setState(() {
                            usergender.text = usergender.text == g ? '' : g;
                            _error = '';
                          }),
                        ),
                      ),
                      if (g == 'male') const SizedBox(width: 10),
                    ],
                  ]),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xffE0243A), size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_error, style: GoogleFonts.cairo(color: const Color(0xffE0243A), fontSize: 13, fontWeight: FontWeight.w700))),
                      ]),
                    ),
                ]),
              ),
              // saving: only when something changed
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _changed
                    ? Padding(
                        key: const ValueKey('save'),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff0873FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: _saving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                : Text(_rtl ? 'حفظ التغييرات' : 'Save changes',
                                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('none'), height: 0),
              ),
            ]),
          ),
          if (showToast)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xff14A47B), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(_rtl ? 'انحفظت معلوماتك' : 'Saved', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? note,
    bool readOnly = false,
    bool ltr = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.cairo(color: textColor.withValues(alpha: .65), fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboard,
          textDirection: ltr ? TextDirection.ltr : null,
          textAlign: ltr && _rtl ? TextAlign.right : TextAlign.start,
          style: GoogleFonts.cairo(color: readOnly ? textColor.withValues(alpha: .55) : textColor, fontSize: 15.5, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: textColor.withValues(alpha: .35), fontSize: 14.5),
            prefixIcon: Icon(icon, color: const Color(0xff0873FF), size: 21),
            suffixIcon: readOnly ? Icon(Icons.lock_outline_rounded, size: 18, color: textColor.withValues(alpha: .35)) : null,
            filled: true,
            fillColor: readOnly ? textColor.withValues(alpha: .04) : (isDarkTheme ? const Color(0xff171B22) : Colors.white),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: textColor.withValues(alpha: .1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xff0873FF), width: 1.6)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(note, style: GoogleFonts.cairo(color: textColor.withValues(alpha: .45), fontSize: 11.5)),
          ),
      ]),
    );
  }
}
