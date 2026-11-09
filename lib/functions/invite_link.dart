import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// Who invited this phone, when the server is sure.
class InviteMatch {
  const InviteMatch({required this.code, required this.name, this.reward});

  final String code;
  final String name;
  final String? reward; // "2 دينار", what the new rider gets; null when the admin turned it off

  static InviteMatch? fromJson(Map<String, dynamic>? d) {
    final code = d?['code']?.toString();
    if (d == null || code == null || code.isEmpty) return null;
    return InviteMatch(code: code, name: d['name']?.toString() ?? '', reward: d['reward']?.toString());
  }
}

/// Asked once, right after signing up. Any failure is "nobody" and the old code page appears.
Future<InviteMatch?> findInviter() async {
  try {
    String? referrer;
    if (Platform.isAndroid) {
      referrer = (await AndroidPlayInstallReferrer.installReferrer.timeout(const Duration(seconds: 4))).installReferrer;
    }
    final view = PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    final response = await http
        .post(Uri.parse('${url}api/v1/invite/match'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'platform': Platform.isIOS ? 'ios' : 'android',
              if (referrer != null) 'referrer': referrer,
              'w': size.shortestSide.round(),
              'h': size.longestSide.round(),
            }))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;
    return InviteMatch.fromJson((jsonDecode(response.body) as Map<String, dynamic>)['data'] as Map<String, dynamic>?);
  } catch (_) {
    return null;
  }
}
