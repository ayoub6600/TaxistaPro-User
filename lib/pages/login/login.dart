import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth/modern_login.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) => const ModernLogin();
}

// Signup/profile state shared with bootstrap_auth.dart and editprofile.dart.
String phnumber = '';
List pages = [1, 2, 3, 4];
List images = [];
int currentPage = 0;

var values = 0;
bool isfromomobile = true;

dynamic proImageFile1;
ImagePicker picker = ImagePicker();
bool pickImage = false;
bool isverifyemail = false;
String email = '';
String password = '';
String name = '';

late StreamController profilepicturecontroller;
StreamSink get profilepicturesink => profilepicturecontroller.sink;
Stream get profilepicturestream => profilepicturecontroller.stream;
