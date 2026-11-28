import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../functions/functions.dart';

// «سفراء تاكسيستا» (api/v1/ambassadors/*): every rider can bring friends with his 5-digit code, its QR
// and its link, and earns a share of Taxista's profit on each of their rides, paid weekly into his
// wallet as ride credit. Gold (bought from the wallet) doubles it and lets him withdraw.
// Every call answers with the whole page («me»), so the screens just show the newest answer.

double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.trim()) ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}'.trim()) ?? 0;
bool _b(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';
String? _s(dynamic v) {
  final s = v?.toString().trim();
  return s == null || s.isEmpty || s == 'null' ? null : s;
}

Map<String, dynamic> _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};
List<Map<String, dynamic>> _l(dynamic v) => v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

/// 1.0 → «1», 1.5 → «1.5», 10 → «10» (a percent or a count of months, never «1.0»)
String ambNum(num v) {
  if (v == v.roundToDouble()) return '${v.round()}';
  return v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

/// «شهر», «شهرين», «6 شهور», «12 شهر»
String ambMonths(int n) {
  if (n == 1) return 'شهر';
  if (n == 2) return 'شهرين';
  if (n >= 3 && n <= 10) return '$n شهور';
  return '$n شهر';
}

/// «مشوار واحد», «مشوارين», «6 مشاوير», «41 مشوار»
String ambRides(int n) {
  if (n == 1) return 'مشوار واحد';
  if (n == 2) return 'مشوارين';
  if (n >= 3 && n <= 10) return '$n مشاوير';
  return '$n مشوار';
}

/// The free tier's numbers (the admin sets them): [pct] of the fare, which is [shareOfProfit] % of
/// Taxista's profit, for [months]; the friend gets [inviteeLyd] off his first ride.
class AmbassadorRules {
  const AmbassadorRules({this.pct = 1, this.shareOfProfit = 10, this.months = 6, this.inviteeLyd = 2});

  final double pct;
  final double shareOfProfit;
  final int months;
  final double inviteeLyd;

  factory AmbassadorRules.fromJson(Map<String, dynamic> j) => AmbassadorRules(
        pct: j['pct'] == null ? 1 : _d(j['pct']),
        shareOfProfit: j['share_of_profit'] == null ? 10 : _d(j['share_of_profit']),
        months: j['months'] == null ? 6 : _i(j['months']),
        inviteeLyd: j['invitee_lyd'] == null ? 2 : _d(j['invitee_lyd']),
      );
}

/// «السفير الذهبي»: bought from the wallet ([priceLyd]); [shortLyd] > 0 means the wallet must be
/// topped up first.
class AmbassadorGold {
  const AmbassadorGold({
    this.enabled = false,
    this.priceLyd = 0,
    this.pct = 0,
    this.shareOfProfit = 0,
    this.months = 0,
    this.active = false,
    this.untilLabel,
    this.walletLyd = 0,
    this.shortLyd = 0,
  });

  final bool enabled;
  final double priceLyd;
  final double pct;
  final double shareOfProfit;
  final int months;
  final bool active;
  final String? untilLabel;
  final double walletLyd;
  final double shortLyd;

  bool get short => shortLyd > 0.004;

  factory AmbassadorGold.fromJson(Map<String, dynamic> j) => AmbassadorGold(
        enabled: _b(j['enabled']),
        priceLyd: _d(j['price_lyd']),
        pct: _d(j['pct']),
        shareOfProfit: _d(j['share_of_profit']),
        months: _i(j['months']),
        active: _b(j['active']),
        untilLabel: _s(j['until_label']),
        walletLyd: _d(j['wallet_lyd']),
        shortLyd: _d(j['short_lyd']),
      );
}

/// What he earned so far: everything, this week, how many friends, how many of their rides.
class AmbassadorJar {
  const AmbassadorJar({this.totalLyd = 0, this.weekLyd = 0, this.friends = 0, this.rides = 0});

  final double totalLyd;
  final double weekLyd;
  final int friends;
  final int rides;

  factory AmbassadorJar.fromJson(Map<String, dynamic> j) => AmbassadorJar(
        totalLyd: _d(j['total_lyd']),
        weekLyd: _d(j['week_lyd']),
        friends: _i(j['friends']),
        rides: _i(j['rides']),
      );
}

/// One person he brought: a rider or a captain, their rides, what he earned from them, and the
/// server's own words for where they stand («باقي 5 شهور», «سجّلت، تستنى أول مشوار»).
class AmbassadorFriend {
  const AmbassadorFriend({required this.name, required this.kind, this.rides = 0, this.earnedLyd = 0, this.stateText});

  final String name;
  final String kind;
  final int rides;
  final double earnedLyd;
  final String? stateText;

  bool get captain => kind == 'driver';

  factory AmbassadorFriend.fromJson(Map<String, dynamic> j) => AmbassadorFriend(
        name: _s(j['name']) ?? '',
        kind: _s(j['kind']) ?? 'rider',
        rides: _i(j['rides']),
        earnedLyd: _d(j['earned_lyd']),
        stateText: _s(j['state_text']),
      );
}

class AmbassadorWithdrawRequest {
  const AmbassadorWithdrawRequest({required this.id, required this.amountLyd, required this.status, this.statusText, this.at, this.bank});

  final int id;
  final double amountLyd;

  /// pending | paid | refused
  final String status;
  final String? statusText;
  final DateTime? at;
  final String? bank;

  factory AmbassadorWithdrawRequest.fromJson(Map<String, dynamic> j) => AmbassadorWithdrawRequest(
        id: _i(j['id']),
        amountLyd: _d(j['amount_lyd']),
        status: _s(j['status']) ?? 'pending',
        statusText: _s(j['status_text']),
        at: DateTime.tryParse('${j['at'] ?? ''}'),
        bank: _s(j['bank']),
      );
}

/// Withdrawing (gold only): what he can take out now, the smallest amount, and his requests.
class AmbassadorWithdraw {
  const AmbassadorWithdraw({this.allowed = false, this.minLyd = 0, this.availableLyd = 0, this.note, this.requests = const []});

  final bool allowed;
  final double minLyd;
  final double availableLyd;
  final String? note;
  final List<AmbassadorWithdrawRequest> requests;

  /// he may ask now: allowed, and he has at least the smallest amount
  bool get canAsk => allowed && availableLyd > 0 && availableLyd + 0.004 >= minLyd;

  factory AmbassadorWithdraw.fromJson(Map<String, dynamic> j) => AmbassadorWithdraw(
        allowed: _b(j['allowed']),
        minLyd: _d(j['min_lyd']),
        availableLyd: _d(j['available_lyd']),
        note: _s(j['note']),
        requests: [for (final r in _l(j['requests'])) AmbassadorWithdrawRequest.fromJson(r)],
      );
}

/// The home screen card, in the server's words.
class AmbassadorHomeCardData {
  const AmbassadorHomeCardData({this.show = false, this.title = '', this.sub = ''});

  final bool show;
  final String title;
  final String sub;

  factory AmbassadorHomeCardData.fromJson(Map<String, dynamic> j) => AmbassadorHomeCardData(
        show: _b(j['show']) && _s(j['title']) != null,
        title: _s(j['title']) ?? '',
        sub: _s(j['sub']) ?? '',
      );
}

/// GET api/v1/ambassadors/me. [code], [riderLink], [captainLink], [shareText] and [jar] are null and
/// [friends] empty until he is an ambassador ([active]).
class AmbassadorState {
  const AmbassadorState({
    required this.enabled,
    required this.status,
    this.canJoin = false,
    this.joinNote,
    this.rules = const AmbassadorRules(),
    this.gold = const AmbassadorGold(),
    this.code,
    this.riderLink,
    this.captainLink,
    this.shareText,
    this.jar,
    this.friends = const [],
    this.withdraw = const AmbassadorWithdraw(),
    this.homeCard = const AmbassadorHomeCardData(),
  });

  final bool enabled;

  /// none | active | revoked
  final String status;
  final bool canJoin;
  final String? joinNote;
  final AmbassadorRules rules;
  final AmbassadorGold gold;
  final String? code;
  final String? riderLink;
  final String? captainLink;
  final String? shareText;
  final AmbassadorJar? jar;
  final List<AmbassadorFriend> friends;
  final AmbassadorWithdraw withdraw;
  final AmbassadorHomeCardData homeCard;

  bool get active => status == 'active';
  bool get revoked => status == 'revoked';

  /// the share he earns now: gold's when gold is running, else the free tier's
  double get sharePct => gold.active && gold.shareOfProfit > 0 ? gold.shareOfProfit : rules.shareOfProfit;

  static AmbassadorState? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final links = _m(j['links']);
    final jar = j['jar'];
    return AmbassadorState(
      enabled: _b(j['enabled']),
      status: _s(j['status']) ?? 'none',
      canJoin: _b(j['can_join']),
      joinNote: _s(j['join_note']),
      rules: AmbassadorRules.fromJson(_m(j['rules'])),
      gold: AmbassadorGold.fromJson(_m(j['gold'])),
      code: _s(j['code']),
      riderLink: _s(links['rider']),
      captainLink: _s(links['captain']),
      shareText: _s(j['share_text']),
      jar: jar is Map ? AmbassadorJar.fromJson(Map<String, dynamic>.from(jar)) : null,
      friends: [for (final f in _l(j['friends'])) AmbassadorFriend.fromJson(f)],
      withdraw: AmbassadorWithdraw.fromJson(_m(j['withdraw'])),
      homeCard: AmbassadorHomeCardData.fromJson(_m(j['home_card'])),
    );
  }
}

/// One answer: the page, or the server's own words (422 «message», shown as is).
class AmbassadorReply {
  const AmbassadorReply({this.state, this.error, this.status = 200});

  final AmbassadorState? state;
  final String? error;

  /// the HTTP status; 0 when the phone could not reach the server
  final int status;

  bool get ok => state != null;
}

class AmbassadorsApi {
  /// The newest answer, for the side menu (hidden while not [AmbassadorState.enabled]).
  static final ValueNotifier<AmbassadorState?> state = ValueNotifier<AmbassadorState?>(null);

  /// The home card to show now, or null (off, or he closed it on this phone less than 7 days ago).
  static final ValueNotifier<AmbassadorHomeCardData?> homeCard = ValueNotifier<AmbassadorHomeCardData?>(null);

  static const hideKey = 'ambassadors_home_hidden_until';
  static const hideFor = Duration(days: 7);

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static int? _hiddenUntil;
  static bool _hiddenLoaded = false;

  static const offline = 'الشبكة ضعيفة. حاول مرة ثانية.';
  static const failed = 'ما قدرناش نكمّل توا. حاول مرة ثانية.';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Uri _u(String path) => Uri.parse('${url}api/v1/ambassadors/$path');

  static String? _message(dynamic body) {
    if (body is! Map) return null;
    final m = _s(body['message']);
    if (m != null) return m;
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      return _s(first is List && first.isNotEmpty ? first.first : first);
    }
    return null;
  }

  /// the session the shown answer belongs to: another account on this phone never sees it
  static String? _owner;

  static Future<AmbassadorReply> _send(String path, {Map<String, dynamic>? body}) async {
    final token = bearerToken.isEmpty ? null : bearerToken[0].token;
    if (token != _owner && state.value != null) {
      state.value = null;
      homeCard.value = null;
    }
    if (token == null) return const AmbassadorReply(error: failed, status: 401);
    http.Response r;
    try {
      r = await (body == null
              ? http.get(_u(path), headers: _headers)
              : http.post(_u(path), headers: _headers, body: jsonEncode(body)))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return const AmbassadorReply(error: offline, status: 0);
    }
    dynamic json;
    try {
      json = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      json = null;
    }
    if (r.statusCode == 200 && json is Map && json['success'] != false) {
      final s = AmbassadorState.fromJson(json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null);
      if (s != null) {
        _owner = token;
        publish(s);
        return AmbassadorReply(state: s, status: 200);
      }
    }
    // a 422 carries the words to show; anything else gets the plain «try again»
    final said = r.statusCode == 422 || (r.statusCode == 200 && json is Map && json['success'] == false) ? _message(json) : null;
    return AmbassadorReply(error: said ?? failed, status: r.statusCode);
  }

  static Future<AmbassadorReply> me() => _send('me');

  static Future<AmbassadorReply> join() => _send('join', body: const {});

  /// [key]: one per tap on «اشترك» — the same purchase sent twice is paid once
  static Future<AmbassadorReply> buyGold(String key) => _send('gold', body: {'key': key});

  static Future<AmbassadorReply> withdraw({
    required double amount,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String key,
  }) =>
      _send('withdraw', body: {
        'amount': amount == amount.roundToDouble() ? amount.round() : double.parse(amount.toStringAsFixed(2)),
        'bank_name': bankName,
        'account_name': accountName,
        'account_number': accountNumber,
        'key': key,
      });

  /// The home screen asks when it opens and when the app comes back.
  static Future<void> refresh() async {
    await _loadHidden();
    await me();
  }

  /// The newest answer for the menu and the home card.
  static void publish(AmbassadorState s) {
    state.value = s;
    _updateHomeCard();
  }

  static bool get homeCardHiddenNow => _hiddenUntil != null && clock().millisecondsSinceEpoch < _hiddenUntil!;

  /// × on the home card: gone from this phone for 7 days (the server is not told).
  static Future<void> hideHomeCard() async {
    _hiddenUntil = clock().add(hideFor).millisecondsSinceEpoch;
    _hiddenLoaded = true;
    homeCard.value = null;
    try {
      await (await SharedPreferences.getInstance()).setInt(hideKey, _hiddenUntil!);
    } catch (_) {}
  }

  static Future<void> _loadHidden() async {
    if (_hiddenLoaded) return;
    try {
      _hiddenUntil = (await SharedPreferences.getInstance()).getInt(hideKey);
    } catch (_) {}
    _hiddenLoaded = true;
  }

  static void _updateHomeCard() {
    final s = state.value;
    homeCard.value = s != null && s.enabled && s.homeCard.show && !homeCardHiddenNow ? s.homeCard : null;
  }

  /// A key for one purchase or one withdrawal (8-64 of [A-Za-z0-9_-]).
  static String newKey() {
    final r = Random();
    return 'amb${clock().microsecondsSinceEpoch}${List.generate(8, (_) => r.nextInt(36).toRadixString(36)).join()}';
  }

  @visibleForTesting
  static void resetForTest() {
    _owner = null;
    state.value = null;
    homeCard.value = null;
    _hiddenUntil = null;
    _hiddenLoaded = false;
    clock = DateTime.now;
  }

  /// re-read the 7-day pause from the phone (tests restart the "app")
  @visibleForTesting
  static Future<void> reloadHiddenForTest() async {
    _hiddenLoaded = false;
    await _loadHidden();
    _updateHomeCard();
  }
}
