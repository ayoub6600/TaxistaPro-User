import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/maps/pin_address.dart';

void main() {
  test('points a few metres apart share one cell, like the server (ReverseGeocoder::CELL)', () {
    expect(PinAddress.cacheKey(32.37541, 15.09211, 'ar'), PinAddress.cacheKey(32.37548, 15.09220, 'ar'));
    expect(PinAddress.cacheKey(32.37541, 15.09211, 'ar'), isNot(PinAddress.cacheKey(32.3800, 15.0950, 'ar')));
    expect(PinAddress.cacheKey(32.37541, 15.09211, 'ar'), isNot(PinAddress.cacheKey(32.37541, 15.09211, 'en')));
    // same centre the PHP side computes: (floor(v / 0.0003) + 0.5) * 0.0003, 5 decimals
    expect(PinAddress.cacheKey(32.37541, 15.09211, 'ar'), 'v2:ar:32.37555,15.09225');
  });

  test('the server answer, a capped day and an unreachable server', () async {
    late Uri asked;
    final ok = MockClient((r) async {
      asked = r.url;
      expect(r.headers['Authorization'], 'Bearer tok');
      return http.Response.bytes(utf8.encode(jsonEncode({'success': true, 'address': 'شارع طرابلس', 'source': 'google'})), 200,
          headers: {'content-type': 'application/json'}); // no charset, like Laravel
    });
    final a = await PinAddress.fromServer(baseUrl: 'https://x.test/', token: 'tok', lat: 32.1, lng: 15.2, lang: 'ar', client: ok);
    expect([a.answered, a.address, a.cacheable], [true, 'شارع طرابلس', true]);
    expect(asked.path, '/api/v1/common/reverse-geocode');
    expect(asked.queryParameters['lang'], 'ar');

    final capped = MockClient((_) async => http.Response(jsonEncode({'success': true, 'address': null, 'source': 'cap'}), 200));
    final c = await PinAddress.fromServer(baseUrl: 'https://x.test/', token: 'tok', lat: 32.1, lng: 15.2, lang: 'ar', client: capped);
    expect([c.answered, c.address, c.cacheable], [true, null, false], reason: 'no address, and no going to Google behind the server');

    final old = MockClient((_) async => http.Response('not found', 404));
    final o = await PinAddress.fromServer(baseUrl: 'https://x.test/', token: 'tok', lat: 32.1, lng: 15.2, lang: 'ar', client: old);
    expect(o.answered, false);
    final none = await PinAddress.fromServer(baseUrl: 'https://x.test/', token: null, lat: 32.1, lng: 15.2, lang: 'ar', client: ok);
    expect(none.answered, false);
  });
}
