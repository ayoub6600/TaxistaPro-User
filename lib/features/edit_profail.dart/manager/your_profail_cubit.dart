import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/edit_profail.dart/data/model/edit_profile_response.dart';
import 'package:taxista/features/edit_profail.dart/data/repo/edit_profail_repo.dart';
import 'package:taxista/features/edit_profail.dart/manager/your_profail_state.dart';

class UdateProfailCubit extends Cubit<UpdateProfileState> {
  final UdateProfailRepo repo;

  UdateProfailCubit(this.repo) : super(UpdateProfileState.initial());

  String? gender;

  void updateProfile({String? profileImageFile}) async {
    emit(state.copyWith(updateProfileStatus: UpdateProfileStatus.submitting));

    var result = await repo.updateProfileMethod(
      name: state.nameController.text,
      email: state.emailController.text,
      // phone: state.phoneController.text,
      gender: gender ?? "male",
      profileImageFile: state.image.path,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          failure: failure,
          updateProfileStatus: UpdateProfileStatus.error,
        ));
        emit(state.copyWith(updateProfileStatus: UpdateProfileStatus.initial));
      },
      (success) {
        emit(state.copyWith(
          updateProfileStatus: UpdateProfileStatus.success,
        ));
        saveData(success);

        emit(state.copyWith(updateProfileStatus: UpdateProfileStatus.initial));
      },
    );
  }

  Future<void> pickImg(String src) async {
    try {
      final image = await ImagePicker().pickImage(
          source: src == "Gallery" ? ImageSource.gallery : ImageSource.camera);
      if (image == null) return;
      final imageTemp = File(image.path);
      imgBase64(imageTemp);
      // this.image = imageTemp;
    } on PlatformException catch (err) {
      debugPrint("Failed to Pick Image $err");
    }
  }

  imgBase64(File imgPath) async {
    Uint8List bytes = await imgPath.readAsBytes();
    String img = imgPath.toString();
    final String ext = p.extension(img);
    String first = "";
    if (ext == ".png'") {
      first += "data:image/png;base64,";
    } else if (ext == '.jpg\'') {
      first += "data:image/jpg;base64,";
    } else {
      first += "data:image/jpeg;base64,";
    }
    String base64String = base64.encode(bytes);

    base64String = first + base64String;
    emit(state.copyWith(image: imgPath));
    //emit(state.copyWith(profileImageFile: base64String));
    //print("base64String $imgPath");
    //  updateProfile(profileImageFile: base64String);
  }

  void updateGender(String newGender) {
    gender = newGender;
    //SharedPreferenceUtil.putString(PrefKey.gender, newGender);
    emit(state.copyWith(gender: newGender)); // Emit state to update UI
  }

  // Show Image source picker for iOS/Android
  Future<void> showImageSource(BuildContext context) async {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                pickImg('Camera');
                Navigator.of(context).pop();
              },
              child: const Text('Camera'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                pickImg('Gallery');
                Navigator.of(context).pop();
              },
              child: const Text('Gallery'),
            ),
          ],
        ),
      );
    } else if (Platform.isAndroid) {
      showModalBottomSheet(
        backgroundColor: Colors.white,
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                pickImg('Camera');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections),
              title: const Text('Gallery'),
              onTap: () {
                pickImg('Gallery');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  saveData(UpdateProfile data) {
    SharedPreferenceUtil.putInt(PrefKey.userId, data.data.id);
    SharedPreferenceUtil.putString(PrefKey.email, data.data.email);
    SharedPreferenceUtil.putString(PrefKey.fullName, data.data.name);
    SharedPreferenceUtil.putString(PrefKey.mobile, data.data.mobile);
    SharedPreferenceUtil.putString(PrefKey.gender, data.data.gender);
    SharedPreferenceUtil.putString(
        PrefKey.profileImage, data.data.profilePicture);
  }
}
