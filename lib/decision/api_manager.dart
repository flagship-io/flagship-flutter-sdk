import 'dart:convert';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/constants.dart';

class ApiManager extends DecisionManager {
  @override
  Future<Campaigns> getCampaigns(
      String envId, String visitorId, Map<String, Object> context) async {
    print(
        " ############## GET CAMPAIGNS FOR THE DECISION API with env ID: $envId and API Key: ${Flagship.sharedInstance().apiKey} #################### ");

    /// Create url
    String urlString = Endpoints.DECISION_API + envId + Endpoints.CAMPAIGNS;

    // create headers   /// refractor later
    Map<String, String> fsHeaders = {
      "x-api-key": Flagship.sharedInstance().apiKey ?? "",
      "x-sdk-client": "flutter",
      "x-sdk-version": version,
      "Content-type": "application/json"
    };

    /// Create data to post
    Object data = json.encode({"visitorId": visitorId, "context": context});
    var response = await Service.sendHttpRequest(
        RequestType.Post, urlString, fsHeaders, data,
        timeoutMs: Flagship.sharedInstance().getConfiguration().timeout);
    switch (response.statusCode) {
      case 200:
        return Campaigns.fromJson(json.decode(response.body));
      default:
        throw Exception('Failed to synchronize');
    }
  }
}
