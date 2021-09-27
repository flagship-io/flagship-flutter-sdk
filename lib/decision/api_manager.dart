import 'dart:convert';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class ApiManager extends DecisionManager {
  @override
  Future<Campaigns> getCampaigns(
      String envId, String visitorId, Map<String, Object> context) async {
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

    // Create data to post
    Object data = json.encode({"visitorId": visitorId, "context": context});
    var response = await Service.sendHttpRequest(
        RequestType.Post, urlString, fsHeaders, data,
        timeoutMs: Flagship.sharedInstance().getConfiguration()?.timeout ?? 2);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        return Campaigns.fromJson(json.decode(response.body));
      default:
        throw Exception('Failed to synchronize');
    }
  }
}
