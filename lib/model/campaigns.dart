import 'campaign.dart';

class Campaigns {
  String visitorId = "";
  bool panic = false;
  List<Campaign> campaigns = [];

  Campaigns.fromJson(Map<String, dynamic> json) {
    // Set visitorId
    visitorId = (json['visitorId'] ?? "") as String;
    // Set panic
    if (json.keys.contains("panic")) {
      panic = json['panic'] as bool;
    }

    var list = (json['campaigns'] ?? []) as List<dynamic>;
    campaigns = list.map((e) {
      return Campaign.fromJson(e);
    }).toList();
  }

  // Get all modification values
  Map<String, dynamic> getAllModification() {
    Map<String, dynamic> result = {};

    for (var item in this.campaigns) {
      result.addAll(item.getAllModificationsValue());
    }
    return result;
  }
}
