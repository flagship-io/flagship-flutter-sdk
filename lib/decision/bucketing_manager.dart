import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/model/campaigns.dart';

class BucketingManager extends DecisionManager {
  BucketingManager(Service service) : super(service);

  @override
  Future<Campaigns> getCampaigns(String envId, String visitorId, Map<String, Object> context) {
    // TODO: implement getCampaigns
    throw UnimplementedError();
  }
}
