import 'package:flagship/api/endpoints.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/dataUsage/data_report_queue.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/visitor.dart';
import 'package:http/http.dart';
import 'package:murmurhash/murmurhash.dart';

part 'trouble_shooting.g.dart';

// Data usage label
String dataUsageLabel = "DK_CONFIG";

// Allocation threshold for data usage tracking
int dataUsageAllocationThreshold = 10;

class DataUsageTracking {
  factory DataUsageTracking.sharedInstance() {
    return _singleton;
  }

  DataUsageTracking._internal() {
    _hasConsented = false;
    troubleShootingReportAllowed = false;
  }

  // TroubleShooting
  Troubleshooting? _troubleshooting;
  // VisitorId
  String visitorId = "";
  // Is data tracking is allowed
  bool troubleShootingReportAllowed = false;

  bool dataUsageTrackingReportAllowed = true;
  // if the visitor has consented
  bool _hasConsented = false;

  String? visitorSessionId; // relative to session creation

  DataReportQueue? dataReport;

  FlagshipConfig? sdkConfig;

  // Internal Singelton
  static final DataUsageTracking _singleton = DataUsageTracking._internal();

  configureDataUsage(Troubleshooting? troubleshooting, String visitorId,
      bool hasConsented, FlagshipConfig sdkConfig) {
    _singleton.sdkConfig = sdkConfig;
    _singleton._troubleshooting = troubleshooting;
    _singleton.visitorId = visitorId;
    _singleton.dataReport = DataReportQueue();
    _singleton.visitorSessionId = FlagshipTools.generateUuidv4().toString();
    _singleton._hasConsented = hasConsented;
    _singleton.evaluateDataUsageTrackingAllocated();
  }

  configureDataUsageWithVisitor(Troubleshooting? troubleshooting, Visitor v) {
    _singleton.sdkConfig = sdkConfig;
    _singleton._troubleshooting = troubleshooting;
    _singleton.visitorId = v.visitorId;
    _singleton.dataReport = DataReportQueue();
    _singleton.visitorSessionId = FlagshipTools.generateUuidv4().toString();
    _singleton._hasConsented = v.getConsent();
    _singleton.evaluateDataUsageTrackingAllocated();
  }

  void updateTroubleshooting(Troubleshooting? trblShooting) {
    _singleton._troubleshooting = trblShooting;
    // Re evaluate the conditions of datausagetracking
    _singleton.evaluateTroubleShootingConditions();
  }

  void updateConsent(bool newValue) {
    _singleton._hasConsented = newValue;
    _singleton..evaluateTroubleShootingConditions();
  }

  void evaluateTroubleShootingConditions() {
    // To allow the dataUsageTracking we have to check
    _singleton
      ..troubleShootingReportAllowed = isTimeSlotValide() && // TimeSlot

          isBucketTroubleshootingAllocated() && // Bucket Allocation for TR

          isVisitorHasConsented(); // Visitor Consent

    if (_singleton.troubleShootingReportAllowed) {
      print("-------------- Data Usage Allowed ✅✅✅✅✅ ---------------");
    } else {
      print("-------------- Data Usage NOT Allowed ❌❌❌❌❌ --------------");
    }
  }

  bool isTimeSlotValide() {
    // Get the date
    DateTime startDate =
        DateTime.parse(_singleton._troubleshooting?.startDate ?? "");
    DateTime endDate =
        DateTime.parse(_singleton._troubleshooting?.endDate ?? "");
    // Get the actual date
    DateTime actualDate = DateTime.now();
    return actualDate.isAfter(startDate) && actualDate.isBefore(endDate);
  }

  bool isBucketTroubleshootingAllocated() {
    // Calculate the bucket allocation

    if (_singleton._troubleshooting?.endDate != null) {
      String combinedId = this.visitorId + (_troubleshooting?.endDate ?? "");
      int hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);

      print(
          "-------- DEV --- The hash allocation for TR bucket is $hashAlloc ------------");

      int traf = (_troubleshooting?.traffic ?? 0);
      print(
          "-------- DEV --- The range allocation for TR bucket is $traf  ------------");

      return (hashAlloc <= (_troubleshooting?.traffic ?? 0));
    } else {
      return false;
    }
  }

  void evaluateDataUsageTrackingAllocated() {
    // Calculate the bucket allocation
    String combinedId = this.visitorId + DateTime.now().toString();
    int hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);

    print(
        "-------- DEV --- The hash allocation for Datausage tracking  bucket is $hashAlloc ------------");
    bool ret = sdkConfig?.disableDeveloperUsageTracking ?? false;

    _singleton.dataUsageTrackingReportAllowed =
        (hashAlloc <= dataUsageAllocationThreshold) && !ret;
  }

  bool isVisitorHasConsented() {
    return _singleton._hasConsented;
  }

  // Send Hit for tracking TR
  void _sendTroubleShootingReport(TroubleShootingHit trHit) {
    if (_singleton.troubleShootingReportAllowed == true) {
      _singleton.dataReport?.sendReportData(trHit);
    }
  }

  void _sendDataUsageTracking(DataUsageHit duHit) {
    if (_singleton.dataUsageTrackingReportAllowed) {
      _singleton.dataReport?.sendReportData(duHit);
    }
  }

  // Fetch /Authenticate / unAuthenticate
  void processTroubleShooting(String label, Visitor visitor) {
    print("----------------------- $label----------------------------");
    Map<String, dynamic> criticalJson = {};

    if (label == "VISITOR_FETCH_CAMPAIGNS") {
      criticalJson = _createTSVisitorFormat(visitor);
    } else if (label == "VISITOR_AUTHENTICATE") {
      criticalJson = _createTSxpc(visitor);
    } else if (label == "VISITOR_UNAUTHENTICATE") {
      criticalJson = _createTSxpc(visitor); // TODO refract later
    }
    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(visitor).entries);
    _sendTroubleShootingReport(
        TroubleShootingHit(visitorId, label, criticalJson));
  }

  /// HITS and ACTIVATE
  void processTroubleShootingHits(String label, Visitor visitor, BaseHit hit) {
    Map<String, dynamic> criticalJson = {};

    criticalJson = _createTSendHit(visitor, hit);

    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(visitor).entries);
    _sendTroubleShootingReport(
        TroubleShootingHit(visitorId, label, criticalJson));
  }

  /// HTTP request
  void processTroubleShootingHttp(String label, Response resp) {
    // get request
    Map<String, dynamic> criticalJson = {};

    try {
      criticalJson = _createTSHttp(resp.request, resp);
      print(criticalJson);
    } on Exception catch (e) {
      print(e.toString());
      print("processTroubleShootingHttp");
      return; // skip the function
    }

    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(null).entries);
    _sendTroubleShootingReport(
        TroubleShootingHit(visitorId, label, criticalJson));
  }

// Flags
  void proceesTroubleShootingFlag(String label, Flag f, Visitor v) {
    Map<String, dynamic> criticalJson = {};
    criticalJson = createTroubleShooitngFlag(f, v);
    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(v).entries);
    _sendTroubleShootingReport(
        TroubleShootingHit(visitorId, label, criticalJson));
  }

  /// Errors
  void processTroubleShootingException(Visitor? v, Object error) {
    Map<String, dynamic> criticalJson = {};

    if (v != null) {
      // Add context
      criticalJson.addEntries(_createTRContext(v).entries);
    }

    /// Add ids
    criticalJson.addEntries(_createTrioIds(v).entries);
    // Add error message
    criticalJson.addEntries({"error.message": error.toString()}.entries);
    // Send Error
    _sendTroubleShootingReport(TroubleShootingHit(
        visitorId, CriticalPoints.ERROR_CATCHED.name, criticalJson));
  }

  void processDataUsageTracking(Visitor v) {
    Map<String, dynamic> dataUsageJson = {};

    // Add SDK Config infos
    dataUsageJson.addEntries(_createSdkConfig(sdkConfig).entries);
    dataUsageJson.addEntries(_createTrioIds(v).entries);
    // Send Error
    _sendDataUsageTracking(
        DataUsageHit(visitorId, dataUsageLabel, dataUsageJson));
  }

/////////////////////////
  /// Private functions  //
/////////////////////////

  // Create a trio of visitorId / anonymousId / instanceId
  Map<String, dynamic> _createTrioIds(Visitor? v) {
    return {
      "visitor.visitorId": v?.visitorId ?? this.visitorId,
      "visitor.anonymousId": v?.anonymousId.toString(),
      "visitor.instanceId": this.visitorSessionId
    };
  }

  Map<String, dynamic> _createTSVisitorFormat(Visitor visitor) {
    Map<String, dynamic> sdkSettings = {
      "visitor.consent": visitor.getConsent(),
      "visitor.campaigns": visitor.modifications.toString(),
      "visitor.isAuthenticated": "false"
    };
    // Add the sdk config entries
    sdkSettings.addEntries(_createSdkConfig(sdkConfig).entries);
    // Add the Flag entries
    sdkSettings.addEntries(_createTRFlagsInfo(visitor.modifications).entries);
    // Add the context entries
    sdkSettings.addEntries(_createTRContext(visitor).entries);
    // Return the settings
    return sdkSettings;
  }
}

enum CriticalPoints {
  VISITOR_FETCH_CAMPAIGNS,
  VISITOR_AUTHENTICATE,
  VISITOR_UNAUTHENTICATE,
  VISITOR_SEND_HIT,
  VISITIR_SEND_ACTIVATE,
  HTTP_CALL,

  // HTTP CALL

  SDK_BUCKETING_FILE, // It will be triggered when the bucketing route responds with code 200
  SDK_BUCKETING_FILE_ERROR, // It will be triggered when the bucketing route responds with error
  GET_CAMPAIGNS_ROUTE_RESPONSE_ERROR, // It will be triggered when the campaigns route responds with an error
  SEND_BATCH_HIT_ROUTE_RESPONSE_ERROR, // When a batch request failed
  SEND_ACTIVATE_HIT_ROUTE_ERROR, // When a activate request failed

  // Warning flag
  GET_FLAG_VALUE_FLAG_NOT_FOUND, // It will be triggered when the Flag.getValue method is called and no flag is found
  GET_FLAG_VALUE_TYPEWARNING, // It will be triggered when the Flag.getValue method is called and the flag value has a different type with default value
  VISITOR_EXPOSED_FLAG_NO_FOUND, // It will be triggered when the Flag.visitorExposed method is called and no flag is found
  GET_FLAG_VALUE_TYPE_WARNING, // // It will be triggered when the Flag.visitorExposed method is called and the flag value has a different type with default value

  ERROR_CATCHED // It will be trigger when the SDK catches any other error but those listed here.
}
