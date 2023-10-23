import 'dart:convert';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/dataUsage/observer.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class ApiManager extends DecisionManager {
  ApiManager(Service service) : super(service);
  @override
  Future<Campaigns> getCampaigns(
      String envId,
      String visitorId,
      String? anonymousId,
      bool hasConsented,
      Map<String, Object> context) async {
    // Create url
    String urlString = Endpoints.DECISION_API + envId + Endpoints.CAMPAIGNS;

    Flagship.logger(Level.DEBUG, 'GET CAMPAIGNS :' + urlString);

    /// Map to send
    Map<String, Object> params = {
      "visitorId": visitorId,
      "context": context,
      "trigger_hit": false,
      "visitor_consent": hasConsented ? true : false
    };
    // add xpc infos if needed
    if (anonymousId != null) {
      params.addEntries({"anonymousId": anonymousId}.entries);
    }
    // Create data to post
    Object data = json.encode(params);
    var response = await service.sendHttpRequest(RequestType.Post, urlString,
        Endpoints.getFSHeader(Flagship.sharedInstance().apiKey ?? ""), data,
        timeoutMs:
            Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        return Campaigns.fromJson(json.decode(response.body));
      default:
        Flagship.logger(
          Level.ALL,
          "Failed to synchronize : ${response.body}",
        );
        DataUsageTracking.sharedInstance().processTroubleShootingHttp(
            CriticalPoints.GET_CAMPAIGNS_ROUTE_RESPONSE_ERROR.name, response);
        throw Exception(
            'Flagship, Failed to synchronize'); // later will use the message of the body response ...
    }
  }
}
