import 'package:flutter/material.dart';

/// Kept for existing call sites. It used to carry its own (slower, different)
/// transition; it now builds a plain [MaterialPageRoute] so every screen uses
/// the single app-wide Taxista transition (see taxista_page_transitions.dart).
Route<T> smoothPageRoute<T>({required WidgetBuilder builder}) {
  return MaterialPageRoute<T>(builder: builder);
}
