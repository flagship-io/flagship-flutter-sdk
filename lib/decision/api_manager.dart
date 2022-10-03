import 'dart:convert';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class ApiManager extends DecisionManager {
  ApiManager(Service service) : super(service);
  @override
  Future<Campaigns> getCampaigns(
      String envId, String visitorId, String? anonymousId, Map<String, Object> context) async {
    // Create url
    String urlString = Endpoints.DECISION_API + envId + Endpoints.CAMPAIGNS;
    // if the consent is false , we set the sendContext to false
    if (isConsent() == false) {
      urlString = urlString + Endpoints.DO_NOT_SEND_CONTEXT;
    }

    Flagship.logger(Level.INFO, 'GET CAMPAIGNS :' + urlString);

    // create headers
    Map<String, String> fsHeaders = {
      "x-api-key": Flagship.sharedInstance().apiKey ?? "",
      "x-sdk-client": "flutter",
      "x-sdk-version": FlagshipVersion,
      "Content-type": "application/json"
    };

    /// Map to send
    Map<String, Object> params = {"visitorId": visitorId, "context": context, "trigger_hit": false};
    // add xpc inofs if needed
    if (anonymousId != null) {
      params.addEntries({"anonymousId": anonymousId}.entries);
    }
    // Create data to post
    Object data = json.encode(params);
    var response = await service.sendHttpRequest(RequestType.Post, urlString, fsHeaders, data,
        timeoutMs: Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        return Campaigns.fromJson(json.decode(response.body));
      default:
        Flagship.logger(
          Level.ALL,
          "Failed to synchronize",
        );
        throw Exception('Flagship, Failed to synchronize');
    }
  }
}
