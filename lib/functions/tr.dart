import 'functions.dart' show languageDirection;

/// Arabic or English, by the app's language (Arabic until the language is known)
String tr(String ar, String en) => languageDirection == 'ltr' ? en : ar;

/// the text direction of the app's language
bool get appRtl => languageDirection != 'ltr';
