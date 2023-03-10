import 'package:flagship/model/campaign.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/model/modification.dart';

abstract class IDecisionManager {
  Future<Campaigns> getCampaigns(String envId, String visitorId,
      String? anonymousId, bool hasConsented, Map<String, Object> context);

  Map<String, Modification> getModifications(List<Campaign> campaigns);
}
