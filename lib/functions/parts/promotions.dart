part of '../functions.dart';

/// Campaigns active for the signed-in rider's market.
List<Map<String, dynamic>> activePromotionCampaigns = <Map<String, dynamic>>[];

Future<void> refreshPromotionCampaigns() async {
  if (bearerToken.isEmpty) return;
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/request/promotions'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return;
    final decoded = jsonDecode(response.body);
    final data = decoded is Map ? decoded['data'] : null;
    final campaigns = data is Map ? data['campaigns'] : null;
    if (campaigns is List) {
      activePromotionCampaigns = campaigns
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
  } catch (_) {
    // Promotions are an optional home-screen enhancement; never block booking.
  }
}
