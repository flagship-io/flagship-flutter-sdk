class Endpoints {
  static const String SEP = "/";
  static const String DECISION_API = "https://decision.flagship.io/v2/";
  static const String CAMPAIGNS = "/campaigns/?exposeAllKeys=true";
  static const String ARIANE = "https://ariane.abtasty.com";
  static const String ACTIVATION = "activate";
  static const String EVENTS = "/events";

  // extra sendContext
  static const String DO_NOT_SEND_CONTEXT = "&sendContextEvent=false";

// Bucketing
  static const String BucketingScript = "https://cdn.flagship.io/%s/bucketing.json";
}
