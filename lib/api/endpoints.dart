import 'package:flagship/flagship_version.dart';

class Endpoints {
  static const String SEP = "/";
  static const String DECISION_API = "https://decision.flagship.io/v2/";
  static const String CAMPAIGNS = "/campaigns/?exposeAllKeys=true";
  static const String ARIANE = "https://ariane.abtasty.com";
  static const String ACTIVATION = "activate";
  static const String EVENTS = "/events";

// Bucketing
  static const String BUCKETING_SCRIPT =
      "https://cdn.flagship.io/%s/bucketing.json";

  // Batch events
  static const String BATCH = "https://events.flagship.io";

// Get the flagship header
  static Map<String, String> getFSHeader(String apiKey) {
    return {
      "x-api-key": apiKey,
      "x-sdk-client": "flutter",
      "x-sdk-version": FlagshipVersion,
      "Content-type": "application/json"
    };
  }
}
