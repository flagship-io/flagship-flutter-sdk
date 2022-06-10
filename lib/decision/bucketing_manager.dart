import 'dart:convert';
import 'dart:ffi';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/campaigns.dart';
import '../utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';

class BucketingManager extends DecisionManager {
  late Polling polling;

  late Campaigns campaigns;

  BucketingManager(Service service) : super(service);

  @override
  Future<Campaigns> getCampaigns(String envId, String visitorId, Map<String, Object> context) async {
    /// Here we have to run the targeting
    return campaigns;

    /// to do later
  }

  _downloadScript() async {
    // Create url
    String urlString = Endpoints.BucketingScript.replaceFirst("%s", Flagship.sharedInstance().envId ?? "");

    var response = await this.service.sendHttpRequest(RequestType.Get, urlString, {}, null,
        timeoutMs: Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        Campaigns.fromJson(json.decode(response.body));
        break;
      default:
        Flagship.logger(
          Level.ALL,
          "Failed to download script for bucketing",
        );
        throw Exception('Flagship, Failed on get bucketing script');
    }
  }

  @override
  void startPolling() {
    // launch the polling process here
    this.polling = Polling(10, () async {
      await _downloadScript();
    });
    this.polling.start();
  }

  _saveFile() async {
    final directory = await getApplicationDocumentsDirectory();
  }
}
