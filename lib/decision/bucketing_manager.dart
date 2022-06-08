import 'package:flagship/model/campaigns.dart';

import 'decision_manager.dart';

class BucketingManager extends DecisionManager {
  @override
  Future<Campaigns> getCampaigns(
      String envId, String visitorId, Map<String, Object> context) {
    return [];
  }
}
