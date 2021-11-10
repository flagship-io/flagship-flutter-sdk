import 'campaign.dart';

class Campaigns {
  String visitorId = "";
  bool panic = false;
  List<Campaign> campaigns = [];

  Campaigns.fromJson(Map<String, dynamic> json) {
    visitorId = (json['visitorId'] ?? "") as String;

    if (json.keys.contains("panic")) {
      panic = json['panic'] as bool;
    }

    var list = (json['campaigns'] ?? []) as List<dynamic>;
    campaigns = list.map((e) {
      return Campaign.fromJson(e);
    }).toList();
  }

  /// get all modification values

  Map<String, dynamic> getAllModification() {
    Map<String, dynamic> result = {};

    for (var item in this.campaigns) {
      result.addAll(item.getAllModificationsValue());
    }

    return result;
  }
}
