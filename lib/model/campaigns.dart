import 'package:flagship/model/account_settings.dart';

import 'campaign.dart';

class Campaigns {
  String visitorId = "";
  bool panic = false;
  List<Campaign> campaigns = [];
  // Account settings
  AccountSettings? accountSettings;

  Campaigns(this.visitorId, this.panic, this.campaigns, this.accountSettings);

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

    // Init AccountSettings
    try {
      if (json['extras']['accountSettings'] != null) {
        accountSettings =
            AccountSettings.fromJson(json['extras']['accountSettings'] ?? {});
      }
    } catch (e) {
      // In panic mode the extras field in not present
    }
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
