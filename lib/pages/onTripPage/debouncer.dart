// ignore_for_file: deprecated_member_use, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:flutter/material.dart';

class Debouncer {
  final int milliseconds;
  dynamic action;
  dynamic _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Drop a pending call, e.g. when the screen that scheduled it is closed.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
