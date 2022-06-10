import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/model/campaigns.dart';

class BucketingManager extends DecisionManager {
  late Polling polling;

  BucketingManager(Service service) : super(service) {
    // launch the polling process here
    this.polling = Polling(10, () async {
      await _downloadScript();
    });
  }

  @override
  Future<Campaigns> getCampaigns(String envId, String visitorId, Map<String, Object> context) {
    /// the get camapaign should only run the targeting
    ///
    // TODO: implement getCampaigns
    throw UnimplementedError();
  }

  Future<String> _downloadScript() async {
    print("Download script from cdn");
    return "aaaa";
  }
}
