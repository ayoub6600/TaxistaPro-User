import 'functions.dart' show languageDirection;

/// Arabic or English, by the app's language
String tr(String ar, String en) => languageDirection == 'rtl' ? ar : en;

/// the text direction of the app's language
bool get appRtl => languageDirection == 'rtl';
